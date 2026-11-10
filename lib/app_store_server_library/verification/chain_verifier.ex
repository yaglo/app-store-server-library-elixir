defmodule AppStoreServerLibrary.Verification.ChainVerifier do
  @moduledoc """
  X.509 certificate chain verification for App Store signed data.

  This module provides functionality to:
  - Verify certificate chains from JWS x5c headers
  - Check OID extensions in certificates
  - Perform OCSP status checks (when enabled)
  - Cache verified certificate public keys (via CertificateCache GenServer)

  ## Configuration

      config :app_store_server_library,
        ocsp_timeout: 30_000  # OCSP request timeout in milliseconds (default: 30 seconds)

  ## Testing seams

  Two optional settings exist so test suites can run without network access.
  Neither belongs in production configuration.

    * `:ocsp_requester` - a module whose `send_ocsp_request/2` replaces the HTTP
      call to the OCSP responder. It must return `{:ok, der_binary}` or an error
      tuple; the returned response is still fully validated.
    * `:ocsp_checker` - a module whose `check_ocsp_status/2` replaces the whole
      revocation check. Setting it disables revocation checking.
  """

  alias AppStoreServerLibrary.Cache.CertificateCache
  alias AppStoreServerLibrary.Telemetry

  # Apple OIDs for App Store certificates
  @apple_leaf_cert_oid {1, 2, 840, 113_635, 100, 6, 11, 1}
  @apple_intermediate_cert_oid {1, 2, 840, 113_635, 100, 6, 2, 1}
  @skew_seconds 60

  @type t :: %__MODULE__{
          root_certificates: [binary()],
          enable_strict_checks: boolean()
        }

  defstruct [:root_certificates, :enable_strict_checks]

  @doc """
  Creates a new ChainVerifier.

  ## Parameters
  - root_certificates: List of Apple root certificates (DER format)
  - enable_strict_checks: Whether to enable strict X.509 verification
  """
  @spec new([binary()], boolean()) :: t()
  def new(root_certificates, enable_strict_checks \\ true) do
    %__MODULE__{
      root_certificates: root_certificates,
      enable_strict_checks: enable_strict_checks
    }
  end

  @doc """
  Verifies a certificate chain and returns the public key from the leaf certificate.

  ## Parameters
  - verifier: The ChainVerifier struct
  - certificates: List of base64-encoded certificates from x5c header
  - perform_online_checks: Whether to perform OCSP checks
  - effective_date: The date to use for validation (Unix timestamp)

  ## Returns

    * `{:ok, public_key_pem, verifier}` on success
    * `{:error, reason}` on failure

  ## Caching

  When `perform_online_checks` is `true`, verified public keys are cached
  in the shared `CertificateCache` GenServer to avoid repeated OCSP checks.
  """
  @spec verify_chain(t(), [String.t()], boolean(), integer()) ::
          {:ok, String.t(), t()} | {:error, {atom(), String.t()}}
  def verify_chain(verifier, certificates, perform_online_checks, effective_date) do
    cert_count = if is_list(certificates), do: length(certificates), else: 0
    metadata = %{cert_count: cert_count, online_checks: perform_online_checks}

    Telemetry.span([:app_store_server_library, :verification, :chain], metadata, fn ->
      maybe_use_cached_key(verifier, certificates, perform_online_checks, effective_date)
    end)
  end

  defp maybe_use_cached_key(verifier, certificates, false = _online_checks, effective_date) do
    do_verify_chain(verifier, certificates, false, effective_date)
  end

  defp maybe_use_cached_key(verifier, certificates, true = _online_checks, effective_date) do
    # Use shared CertificateCache GenServer
    case CertificateCache.get(cache_key(verifier, certificates)) do
      {:ok, public_key} ->
        {:ok, public_key, verifier}

      :miss ->
        do_verify_chain(verifier, certificates, true, effective_date)
    end
  end

  defp do_verify_chain(verifier, certificates, perform_online_checks, effective_date) do
    with :ok <- validate_root_certificates(verifier),
         :ok <- validate_chain_length(certificates),
         {:ok, decoded_certs} <- decode_certificates(certificates),
         {:ok, _verified_chain} <-
           maybe_verify_certificate_chain(verifier, decoded_certs, effective_date),
         :ok <- maybe_check_apple_oids(verifier, decoded_certs),
         :ok <- maybe_check_ocsp(decoded_certs, perform_online_checks),
         {:ok, public_key_pem} <- extract_public_key(decoded_certs) do
      # Cache the verified public key when online checks are enabled
      if perform_online_checks do
        CertificateCache.put(cache_key(verifier, certificates), public_key_pem)
      end

      {:ok, public_key_pem, verifier}
    end
  end

  # A cached key is only valid for the trust configuration that verified it.
  # Binding the key to the root set and strictness keeps a chain accepted by
  # one verifier from being served to another verifier with different roots.
  defp cache_key(verifier, certificates) do
    {:chain, verifier.root_certificates, verifier.enable_strict_checks, certificates}
  end

  defp validate_root_certificates(%{root_certificates: []}),
    do: {:error, {:invalid_certificate, "No root certificates configured"}}

  defp validate_root_certificates(_), do: :ok

  defp validate_chain_length(certificates)
       when is_list(certificates) and length(certificates) == 3,
       do: :ok

  defp validate_chain_length(_),
    do: {:error, {:invalid_chain_length, "Certificate chain must contain exactly 3 certificates"}}

  defp decode_certificates(certificates) do
    results =
      Enum.map(certificates, fn
        cert_b64 when is_binary(cert_b64) -> Base.decode64(cert_b64)
        _ -> :error
      end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      {:ok, Enum.map(results, fn {:ok, der} -> der end)}
    else
      {:error, {:invalid_certificate, "Failed to decode certificate from Base64"}}
    end
  end

  # Skip certificate chain verification when strict checks are disabled (for test certificates)
  defp maybe_verify_certificate_chain(
         %{enable_strict_checks: false},
         decoded_certs,
         _effective_date
       ) do
    {:ok, decoded_certs}
  end

  defp maybe_verify_certificate_chain(verifier, decoded_certs, effective_date) do
    verify_certificate_chain(verifier, decoded_certs, effective_date)
  end

  defp verify_certificate_chain(
         verifier,
         [leaf_der, intermediate_der, chain_root_der],
         effective_date
       ) do
    # Verify the chain manually. `:public_key.pkix_path_validation/3` validates
    # certificate validity against the wall clock (`erlang:universaltime/0`)
    # and has no option to supply a custom timestamp. In offline mode
    # (`enable_online_checks: false`) we validate against the payload's
    # `signedDate` so historical receipts can still be processed after their
    # signing certs expire — see `SignedDataVerifier.get_effective_date/2`.
    # Walking the chain by hand also keeps the online and offline paths on a
    # single code path.

    with :ok <- verify_chain_root_is_trusted(verifier.root_certificates, chain_root_der),
         :ok <- verify_signature(intermediate_der, chain_root_der),
         :ok <- verify_signature(leaf_der, intermediate_der),
         :ok <- verify_validity_period(chain_root_der, effective_date),
         :ok <- verify_validity_period(intermediate_der, effective_date),
         :ok <- verify_validity_period(leaf_der, effective_date),
         :ok <- verify_issuer_relationship(intermediate_der, chain_root_der),
         :ok <- verify_issuer_relationship(leaf_der, intermediate_der),
         :ok <- verify_basic_constraints(intermediate_der, :ca),
         :ok <- verify_basic_constraints(leaf_der, :end_entity),
         :ok <- verify_extension_policy(intermediate_der, :keyCertSign),
         :ok <- verify_extension_policy(leaf_der, :digitalSignature) do
      leaf_cert = :public_key.pkix_decode_cert(leaf_der, :otp)
      intermediate_cert = :public_key.pkix_decode_cert(intermediate_der, :otp)
      root_cert = :public_key.pkix_decode_cert(chain_root_der, :otp)
      {:ok, [leaf_cert, intermediate_cert, root_cert]}
    end
  rescue
    e ->
      {:error, {:invalid_chain, "Certificate chain validation exception: #{inspect(e)}"}}
  end

  defp verify_chain_root_is_trusted(root_certificates, chain_root_der) do
    if Enum.any?(root_certificates, fn trusted_der -> trusted_der == chain_root_der end) do
      :ok
    else
      {:error, {:invalid_chain, "Chain root certificate is not in trusted roots"}}
    end
  end

  defp verify_signature(cert_der, issuer_der) do
    issuer_pub_key = extract_public_key_for_verify(issuer_der)

    if :public_key.pkix_verify(cert_der, issuer_pub_key) do
      :ok
    else
      {:error, {:invalid_chain, "Certificate signature verification failed"}}
    end
  end

  defp extract_public_key_for_verify(cert_der) do
    plain = :public_key.pkix_decode_cert(cert_der, :plain)
    {:Certificate, {:TBSCertificate, _, _, _, _, _, _, spki, _, _, _}, _, _} = plain
    spki_der = :public_key.der_encode(:SubjectPublicKeyInfo, spki)

    pem =
      "-----BEGIN PUBLIC KEY-----\n" <> Base.encode64(spki_der) <> "\n-----END PUBLIC KEY-----"

    [entry] = :public_key.pem_decode(pem)
    :public_key.pem_entry_decode(entry)
  end

  defp verify_validity_period(cert_der, effective_date) do
    cert = :public_key.pkix_decode_cert(cert_der, :otp)
    {:OTPCertificate, tbs, _, _} = cert
    {:OTPTBSCertificate, _, _, _, _, validity, _, _, _, _, _} = tbs
    {:Validity, not_before, not_after} = validity

    not_before_unix = parse_validity_time(not_before)
    not_after_unix = parse_validity_time(not_after)

    cond do
      effective_date < not_before_unix - @skew_seconds ->
        {:error, {:verification_failure, "Certificate not yet valid"}}

      effective_date > not_after_unix + @skew_seconds ->
        {:error, {:verification_failure, "Certificate has expired"}}

      true ->
        :ok
    end
  end

  defp parse_validity_time({:utcTime, time_chars}) do
    time_str = to_string(time_chars)
    # Format: YYMMDDHHMMSSZ
    <<yy::binary-size(2), rest::binary>> = time_str
    year = String.to_integer(yy)
    # UTCTime: years 00-49 are 2000-2049, 50-99 are 1950-1999
    full_year = if year >= 50, do: 1900 + year, else: 2000 + year
    parse_datetime_components(full_year, rest)
  end

  defp parse_validity_time({:generalTime, time_chars}) do
    time_str = to_string(time_chars)
    # Format: YYYYMMDDHHMMSSZ
    <<yyyy::binary-size(4), rest::binary>> = time_str
    parse_datetime_components(String.to_integer(yyyy), rest)
  end

  defp parse_datetime_components(year, <<
         mm::binary-size(2),
         dd::binary-size(2),
         hh::binary-size(2),
         mi::binary-size(2),
         ss::binary-size(2),
         _rest::binary
       >>) do
    {:ok, datetime} =
      NaiveDateTime.new(
        year,
        String.to_integer(mm),
        String.to_integer(dd),
        String.to_integer(hh),
        String.to_integer(mi),
        String.to_integer(ss)
      )

    DateTime.from_naive!(datetime, "Etc/UTC") |> DateTime.to_unix()
  end

  defp verify_issuer_relationship(cert_der, issuer_der) do
    cert = :public_key.pkix_decode_cert(cert_der, :otp)
    issuer = :public_key.pkix_decode_cert(issuer_der, :otp)

    if :public_key.pkix_is_issuer(cert, issuer) do
      :ok
    else
      {:error, {:invalid_chain, "Certificate issuer mismatch"}}
    end
  end

  defp verify_basic_constraints(cert_der, expected_type) do
    cert = :public_key.pkix_decode_cert(cert_der, :otp)
    {:OTPCertificate, tbs, _, _} = cert
    # OTPTBSCertificate has 11 elements, extensions is the last one (index 10)
    extensions = elem(tbs, 10)

    basic_constraints =
      case extensions do
        :asn1_NOVALUE ->
          nil

        exts when is_list(exts) ->
          Enum.find_value(exts, fn
            {:Extension, {2, 5, 29, 19}, _, value} -> value
            _ -> nil
          end)
      end

    case {expected_type, basic_constraints} do
      {:ca, {:BasicConstraints, true, _}} ->
        :ok

      {:ca, _} ->
        {:error,
         {:invalid_chain, "Expected CA certificate but basicConstraints missing or false"}}

      {:end_entity, {:BasicConstraints, true, _}} ->
        {:error, {:invalid_chain, "End entity certificate should not be a CA"}}

      {:end_entity, _} ->
        :ok
    end
  end

  @key_usage_oid {2, 5, 29, 15}
  @apple_extension_arc [1, 2, 840, 113_635, 100, 6]
  @basic_constraints_oid {2, 5, 29, 19}

  # Decodes the certificate once and applies both extension rules to it.
  defp verify_extension_policy(cert_der, required_usage) do
    extensions = extensions(cert_der)

    with :ok <- verify_key_usage(extensions, required_usage) do
      verify_critical_extensions(extensions)
    end
  end

  # When a certificate carries keyUsage, it must permit the way the chain uses
  # the key: signing certificates for the intermediate, signing data for the leaf.
  defp verify_key_usage(extensions, required_usage) do
    case List.keyfind(extensions, @key_usage_oid, 1) do
      nil ->
        :ok

      {:Extension, _, _, usages} ->
        if required_usage in decode_key_usage(usages) do
          :ok
        else
          {:error, {:invalid_chain, "Certificate keyUsage does not permit #{required_usage}"}}
        end
    end
  end

  defp decode_key_usage(usages) when is_list(usages), do: usages

  defp decode_key_usage(usages) when is_binary(usages),
    do: :public_key.der_decode(:KeyUsage, usages)

  # RFC 5280 section 4.2: a certificate with a critical extension the verifier
  # does not process must be rejected. The extensions processed here are
  # basicConstraints, keyUsage, and Apple's marker extensions.
  defp verify_critical_extensions(extensions) do
    unknown =
      Enum.find(extensions, fn
        {:Extension, oid, true, _} -> not processed_extension?(oid)
        _ -> false
      end)

    case unknown do
      nil ->
        :ok

      {:Extension, oid, _, _} ->
        {:error, {:invalid_chain, "Unrecognized critical extension: #{inspect(oid)}"}}
    end
  end

  defp processed_extension?(@key_usage_oid), do: true
  defp processed_extension?(@basic_constraints_oid), do: true

  defp processed_extension?(oid) when is_tuple(oid),
    do: List.starts_with?(Tuple.to_list(oid), @apple_extension_arc)

  defp processed_extension?(_), do: false

  defp extensions(cert_der) do
    {:OTPCertificate, tbs, _, _} = :public_key.pkix_decode_cert(cert_der, :otp)

    case elem(tbs, 10) do
      :asn1_NOVALUE -> []
      exts when is_list(exts) -> exts
    end
  end

  # Skip Apple OID checks when strict checks are disabled (for test certificates)
  defp maybe_check_apple_oids(%{enable_strict_checks: false}, _decoded_certs), do: :ok

  defp maybe_check_apple_oids(_verifier, decoded_certs) do
    check_apple_oids(decoded_certs)
  end

  defp check_apple_oids([leaf_der, intermediate_der | _]) do
    with :ok <- check_oid(leaf_der, @apple_leaf_cert_oid) do
      check_oid(intermediate_der, @apple_intermediate_cert_oid)
    end
  end

  defp check_oid(cert_der, oid) do
    cert = :public_key.pkix_decode_cert(cert_der, :otp)
    {:OTPCertificate, tbs_cert, _, _} = cert
    # OTPTBSCertificate has 11 elements, extensions is the last one (index 10)
    extensions = elem(tbs_cert, 10)

    has_oid =
      case extensions do
        :asn1_NOVALUE ->
          false

        exts when is_list(exts) ->
          Enum.any?(exts, fn
            {:Extension, ext_oid, _, _} -> ext_oid == oid
            _ -> false
          end)
      end

    if has_oid do
      :ok
    else
      {:error, {:verification_failure, "Missing required OID: #{inspect(oid)}"}}
    end
  rescue
    e -> {:error, {:verification_failure, "Failed to check OID: #{inspect(e)}"}}
  end

  defp maybe_check_ocsp(_decoded_certs, false), do: :ok

  defp maybe_check_ocsp([leaf_der, intermediate_der, root_der], true) do
    # Perform OCSP checks for intermediate and leaf certificates
    with :ok <- run_ocsp_check(intermediate_der, root_der, root_der) do
      run_ocsp_check(leaf_der, intermediate_der, root_der)
    end
  end

  # `:ocsp_checker` replaces the whole revocation check. It exists so test
  # suites can run the online code path without network access; it must never
  # be configured in production.
  defp run_ocsp_check(cert_der, issuer_der, root_der) do
    case Application.get_env(:app_store_server_library, :ocsp_checker) do
      nil -> check_ocsp_status(cert_der, issuer_der, root_der)
      checker when is_atom(checker) -> checker.check_ocsp_status(cert_der, issuer_der)
    end
  end

  @doc """
  Performs an OCSP status check for a certificate.

  Fails closed: a certificate without an OCSP responder URL, or whose
  extensions cannot be read, is reported as a verification failure rather
  than treated as not revoked.
  """
  @spec check_ocsp_status(binary(), binary(), binary()) :: :ok | {:error, {atom(), String.t()}}
  def check_ocsp_status(cert_der, issuer_der, _root_der) do
    cert = :public_key.pkix_decode_cert(cert_der, :otp)

    with {:ok, ocsp_url} <- get_ocsp_url(cert),
         {:ok, ocsp_request_der} <- build_ocsp_request(cert_der, issuer_der),
         {:ok, ocsp_response_der} <- send_ocsp_request(ocsp_url, ocsp_request_der) do
      validate_ocsp_response(ocsp_response_der, cert_der, issuer_der)
    end
  rescue
    _ -> {:error, {:retryable_verification_failure, "OCSP check failed"}}
  end

  @aia_oid {1, 3, 6, 1, 5, 5, 7, 1, 1}
  @ocsp_oid {1, 3, 6, 1, 5, 5, 7, 48, 1}

  defp get_ocsp_url(cert) do
    {:OTPCertificate, tbs_cert, _, _} = cert
    {:OTPTBSCertificate, _, _, _, _, _, _, _, _, _, extensions} = tbs_cert

    extensions = if is_list(extensions), do: extensions, else: []

    case find_ocsp_url_in_extensions(extensions) do
      nil ->
        {:error,
         {:verification_failure, "Certificate has no OCSP responder URL; cannot check revocation"}}

      url ->
        {:ok, url}
    end
  rescue
    _ ->
      {:error, {:verification_failure, "Failed to read OCSP responder URL from certificate"}}
  end

  defp find_ocsp_url_in_extensions(extensions) do
    Enum.find_value(extensions, fn
      {:Extension, @aia_oid, _, aia_value} ->
        aia_value
        |> decode_access_descriptions()
        |> find_ocsp_url_in_descriptions()

      _ ->
        nil
    end)
  end

  defp decode_access_descriptions(list) when is_list(list), do: list

  defp decode_access_descriptions(binary) when is_binary(binary) do
    case :public_key.der_decode(:AuthorityInfoAccessSyntax, binary) do
      decoded when is_list(decoded) -> decoded
      _ -> []
    end
  end

  defp decode_access_descriptions(_), do: []

  defp find_ocsp_url_in_descriptions(descriptions) do
    Enum.find_value(descriptions, fn
      {:AccessDescription, @ocsp_oid, {:uniformResourceIdentifier, url}} -> to_string(url)
      _ -> nil
    end)
  end

  # SHA-1 Algorithm Identifier OID for OCSP (RFC 6960 requires SHA-1 for CertID)
  @sha1_algorithm_id {:AlgorithmIdentifier, {1, 3, 14, 3, 2, 26}, :asn1_NOVALUE}

  @doc false
  def build_ocsp_request(cert_der, issuer_der) do
    # Parse certificates
    cert = :public_key.pkix_decode_cert(cert_der, :plain)
    issuer = :public_key.pkix_decode_cert(issuer_der, :plain)

    {:Certificate, tbs_cert, _, _} = cert
    {:TBSCertificate, _, serial_number, _, _, _, _, _, _, _, _} = tbs_cert

    {:Certificate, issuer_tbs, _, _} = issuer
    {:TBSCertificate, _, _, _, _, _, issuer_subject, issuer_spki, _, _, _} = issuer_tbs

    # OCSP issuerNameHash is the SHA-1 hash of the issuer certificate's DER-encoded subject.
    issuer_name_der = :public_key.der_encode(:Name, issuer_subject)
    issuer_name_hash = :crypto.hash(:sha, issuer_name_der)

    # Hash issuer public key (just the BIT STRING value, not the whole SPKI)
    {:SubjectPublicKeyInfo, _, issuer_public_key_bitstring} = issuer_spki
    issuer_key_hash = :crypto.hash(:sha, issuer_public_key_bitstring)

    # Build CertID record
    cert_id =
      {:CertID, @sha1_algorithm_id, issuer_name_hash, issuer_key_hash, serial_number}

    # Build Request record (no extensions)
    request = {:Request, cert_id, :asn1_NOVALUE}

    # Build TBSRequest record
    tbs_request = {:TBSRequest, :asn1_DEFAULT, :asn1_NOVALUE, [request], :asn1_NOVALUE}

    # Build OCSPRequest record (unsigned)
    ocsp_request = {:OCSPRequest, tbs_request, :asn1_NOVALUE}

    # Encode to DER. `:public_key.der_encode/2` dispatches to the right ASN.1
    # module across OTP versions — OTP 28 removed the `:"OTP-PUB-KEY"` module
    # that previous releases exposed directly.
    {:ok, :public_key.der_encode(:OCSPRequest, ocsp_request)}
  rescue
    e -> {:error, {:verification_failure, "Failed to build OCSP request: #{inspect(e)}"}}
  end

  defp ocsp_timeout do
    Application.get_env(:app_store_server_library, :ocsp_timeout, 30_000)
  end

  defp send_ocsp_request(ocsp_url, ocsp_request_der) do
    case ocsp_requester() do
      nil ->
        do_send_ocsp_request(ocsp_url, ocsp_request_der)

      # credo:disable-for-next-line Credo.Check.Refactor.Apply
      {mod, fun} when is_atom(mod) and is_atom(fun) ->
        apply(mod, fun, [ocsp_url, ocsp_request_der])

      mod when is_atom(mod) ->
        mod.send_ocsp_request(ocsp_url, ocsp_request_der)
    end
  end

  # OCSP travels over plain HTTP, so the response is attacker-influenceable
  # until its signature is validated: do not follow redirects, and do not let
  # Req decompress or decode the body.
  defp do_send_ocsp_request(ocsp_url, ocsp_request_der) do
    headers = [{"content-type", "application/ocsp-request"}]

    case Req.post(ocsp_url,
           body: ocsp_request_der,
           headers: headers,
           receive_timeout: ocsp_timeout(),
           redirect: false,
           retry: false,
           compressed: false,
           decode_body: false
         ) do
      {:ok, %Req.Response{status: 200, body: response_body}} ->
        {:ok, response_body}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:retryable_verification_failure, "OCSP HTTP error: #{status}"}}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, {:retryable_verification_failure, "OCSP network error: #{inspect(reason)}"}}

      {:error, reason} ->
        {:error, {:retryable_verification_failure, "OCSP error: #{inspect(reason)}"}}
    end
  end

  defp validate_ocsp_response(ocsp_response_der, _cert_der, _issuer_der)
       when not is_binary(ocsp_response_der) do
    {:error, {:retryable_verification_failure, "OCSP responder returned a non-binary response"}}
  end

  defp validate_ocsp_response(ocsp_response_der, cert_der, issuer_der) do
    # Use OTP's built-in OCSP validation
    # pkix_ocsp_validate/5 validates the response according to RFC 6960
    case :public_key.pkix_ocsp_validate(cert_der, issuer_der, ocsp_response_der, :undefined, []) do
      {:ok, _details} ->
        :ok

      {:error, {:bad_cert, {:revoked, reason}}} ->
        {:error, {:verification_failure, "Certificate has been revoked: #{inspect(reason)}"}}

      {:error, {:bad_cert, {:revocation_status_undetermined, _}}} ->
        {:error, {:retryable_verification_failure, "Certificate revocation status undetermined"}}

      {:error, {:bad_cert, reason}} ->
        {:error, {:verification_failure, "OCSP validation failed: #{inspect(reason)}"}}
    end
  rescue
    e -> {:error, {:retryable_verification_failure, "OCSP validation exception: #{inspect(e)}"}}
  end

  defp ocsp_requester do
    Application.get_env(:app_store_server_library, :ocsp_requester)
  end

  defp extract_public_key([leaf_der | _]) do
    # Parse the certificate in plain format to get the raw SubjectPublicKeyInfo
    cert = :public_key.pkix_decode_cert(leaf_der, :plain)
    {:Certificate, tbs_cert, _, _} = cert
    {:TBSCertificate, _, _, _, _, _, _, subject_public_key_info, _, _, _} = tbs_cert

    # Encode the SubjectPublicKeyInfo back to DER, then to PEM
    spki_der = :public_key.der_encode(:SubjectPublicKeyInfo, subject_public_key_info)

    # Create PEM format manually
    b64_encoded = Base.encode64(spki_der)
    pem = "-----BEGIN PUBLIC KEY-----\n#{wrap_base64(b64_encoded)}\n-----END PUBLIC KEY-----\n"

    {:ok, pem}
  rescue
    e -> {:error, {:verification_failure, "Failed to extract public key: #{inspect(e)}"}}
  end

  defp wrap_base64(b64) do
    b64
    |> String.codepoints()
    |> Enum.chunk_every(64)
    |> Enum.map_join("\n", &Enum.join/1)
  end
end
