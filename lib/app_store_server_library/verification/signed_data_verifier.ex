defmodule AppStoreServerLibrary.Verification.SignedDataVerifier do
  @moduledoc """
  A module providing utility functions for verifying and decoding App Store signed data.

  This module handles verification of:
  - Signed transactions
  - Signed renewal info
  - App Store Server Notifications
  - App transactions
  - Real-time requests for retention messaging

  It performs certificate chain verification using the x5c header from JWS tokens
  and validates that the data matches the expected environment and bundle ID.
  """

  alias AppStoreServerLibrary.Models.{
    AppTransaction,
    DecodedRealtimeRequestBody,
    Environment,
    ExternalPurchaseToken,
    JWSRenewalInfoDecodedPayload,
    JWSTransactionDecodedPayload,
    ResponseBodyV2DecodedPayload,
    Summary
  }

  alias AppStoreServerLibrary.Telemetry
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.ChainVerifier

  @enforce_keys [:root_certificates, :environment, :bundle_id]
  defstruct [
    :root_certificates,
    :enable_online_checks,
    :environment,
    :bundle_id,
    :app_apple_id,
    :chain_verifier
  ]

  @type t :: %__MODULE__{
          root_certificates: [binary()],
          enable_online_checks: boolean(),
          environment: Environment.t(),
          bundle_id: String.t(),
          app_apple_id: integer() | nil,
          chain_verifier: ChainVerifier.t()
        }

  @type verification_status ::
          :ok
          | :verification_failure
          | :invalid_app_identifier
          | :invalid_certificate
          | :invalid_chain_length
          | :invalid_chain
          | :invalid_environment
          | :retryable_verification_failure

  @type options :: [
          root_certificates: [binary()],
          enable_online_checks: boolean(),
          environment: Environment.t(),
          bundle_id: String.t(),
          app_apple_id: integer() | nil
        ]

  @doc """
  Create a new SignedDataVerifier.

  ## Options

    * `:root_certificates` - List of Apple root certificates (DER format binary) - **required**
    * `:environment` - `:sandbox`, `:production`, `:xcode`, or `:local_testing` - **required**
    * `:bundle_id` - Your app's bundle identifier - **required**
    * `:enable_online_checks` - Whether to perform online OCSP verification (default: `false`)
    * `:app_apple_id` - Your app's Apple ID (**required** for `:production` environment)

  ## Examples

      root_cert = File.read!("AppleRootCA-G3.cer")

      verifier = SignedDataVerifier.new(
        root_certificates: [root_cert],
        environment: :sandbox,
        bundle_id: "com.example.app"
      )

      # For production, app_apple_id is required:
      verifier = SignedDataVerifier.new(
        root_certificates: [root_cert],
        environment: :production,
        bundle_id: "com.example.app",
        app_apple_id: 123456789
      )

  """
  @spec new(options()) :: {:ok, t()} | {:error, {:invalid_app_identifier, String.t()}}
  def new(opts) when is_list(opts) do
    root_certificates = Keyword.fetch!(opts, :root_certificates)
    environment = Keyword.fetch!(opts, :environment)
    bundle_id = Keyword.fetch!(opts, :bundle_id)
    enable_online_checks = Keyword.get(opts, :enable_online_checks, false)
    app_apple_id = Keyword.get(opts, :app_apple_id)

    if environment == :production and app_apple_id == nil do
      {:error, {:invalid_app_identifier, "app_apple_id is required for production environment"}}
    else
      chain_verifier = ChainVerifier.new(root_certificates)

      verifier = %__MODULE__{
        root_certificates: root_certificates,
        enable_online_checks: enable_online_checks,
        environment: environment,
        bundle_id: bundle_id,
        app_apple_id: app_apple_id,
        chain_verifier: chain_verifier
      }

      {:ok, verifier}
    end
  end

  @doc """
  Verifies and decodes a signedRenewalInfo obtained from the App Store Server API,
  an App Store Server Notification, or from a device.

  https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfo
  """
  @spec verify_and_decode_renewal_info(t(), String.t()) ::
          {:ok, JWSRenewalInfoDecodedPayload.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_renewal_info(verifier, signed_renewal_info) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :renewal_info},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_renewal_info),
             {:ok, renewal_info} <- to_renewal_info_struct(decoded_payload),
             :ok <- verify_environment(verifier, renewal_info.environment) do
          {:ok, renewal_info}
        end
      end
    )
  end

  @doc """
  Verifies and decodes a signedTransaction obtained from the App Store Server API,
  an App Store Server Notification, or from a device.

  https://developer.apple.com/documentation/appstoreserverapi/jwstransaction
  """
  @spec verify_and_decode_signed_transaction(t(), String.t()) ::
          {:ok, JWSTransactionDecodedPayload.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_signed_transaction(verifier, signed_transaction) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :transaction},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_transaction),
             {:ok, transaction_info} <- to_transaction_struct(decoded_payload),
             :ok <- verify_bundle_id(verifier, transaction_info.bundle_id),
             :ok <- verify_environment(verifier, transaction_info.environment) do
          {:ok, transaction_info}
        end
      end
    )
  end

  @doc """
  Verifies and decodes an App Store Server Notification signedPayload.

  https://developer.apple.com/documentation/appstoreservernotifications/signedpayload
  """
  @spec verify_and_decode_notification(t(), String.t()) ::
          {:ok, ResponseBodyV2DecodedPayload.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_notification(verifier, signed_payload) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :notification},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_payload),
             {:ok, notification} <- to_notification_struct(decoded_payload),
             {:ok, {bundle_id, app_apple_id, environment}} <-
               extract_notification_data(notification),
             :ok <- verify_notification_data(verifier, bundle_id, app_apple_id, environment) do
          {:ok, notification}
        end
      end
    )
  end

  @doc """
  Verifies and decodes a signed AppTransaction.

  https://developer.apple.com/documentation/storekit/apptransaction
  """
  @spec verify_and_decode_app_transaction(t(), String.t()) ::
          {:ok, AppTransaction.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_app_transaction(verifier, signed_app_transaction) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :app_transaction},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_app_transaction),
             {:ok, app_transaction} <- to_app_transaction_struct(decoded_payload),
             environment <- app_transaction.receipt_type,
             :ok <-
               verify_app_transaction_bundle_id(
                 verifier,
                 app_transaction.bundle_id,
                 app_transaction.app_apple_id
               ),
             :ok <- verify_environment(verifier, environment) do
          {:ok, app_transaction}
        end
      end
    )
  end

  @doc """
  Verifies and decodes a Retention Messaging API signedPayload.

  https://developer.apple.com/documentation/retentionmessaging/signedpayload
  """
  @spec verify_and_decode_realtime_request(t(), String.t()) ::
          {:ok, DecodedRealtimeRequestBody.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_realtime_request(verifier, signed_payload) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :realtime_request},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_payload),
             {:ok, realtime_request} <- to_realtime_request_struct(decoded_payload),
             :ok <- verify_realtime_app_apple_id(verifier, realtime_request.app_apple_id),
             :ok <- verify_environment(verifier, realtime_request.environment) do
          {:ok, realtime_request}
        end
      end
    )
  end

  @doc """
  Verifies and decodes a summary from a notification.
  """
  @spec verify_and_decode_summary(t(), String.t()) ::
          {:ok, Summary.t()} | {:error, {verification_status(), String.t()}}
  def verify_and_decode_summary(verifier, signed_payload) do
    Telemetry.span(
      [:app_store_server_library, :verification, :signature],
      %{type: :summary},
      fn ->
        with {:ok, decoded_payload} <- decode_signed_object(verifier, signed_payload),
             {:ok, summary} <- to_summary_struct(decoded_payload),
             :ok <- verify_bundle_id(verifier, summary.bundle_id),
             :ok <- verify_environment(verifier, summary.environment) do
          {:ok, summary}
        end
      end
    )
  end

  # Private helper functions

  defp decode_signed_object(verifier, signed_obj) do
    # Use JOSE to safely peek at JWS contents without verification
    with {:ok, header} <- peek_header(signed_obj),
         {:ok, payload} <- peek_payload(signed_obj) do
      # Check if this is Xcode or LocalTesting environment - skip verification
      if verifier.environment in [:xcode, :local_testing] do
        {:ok, payload}
      else
        # Verify the certificate chain using x5c header
        x5c_header = Map.get(header, "x5c", [])
        algorithm = Map.get(header, "alg")

        with :ok <- validate_jwt_headers(algorithm, x5c_header),
             {:ok, effective_date} <- get_effective_date(payload, verifier.enable_online_checks),
             {:ok, public_key_pem, _updated_verifier} <-
               ChainVerifier.verify_chain(
                 verifier.chain_verifier,
                 x5c_header,
                 verifier.enable_online_checks,
                 effective_date
               ),
             :ok <- verify_signature(signed_obj, public_key_pem) do
          {:ok, payload}
        end
      end
    end
  end

  defp peek_header(signed_obj) do
    header_json = JOSE.JWS.peek_protected(signed_obj)
    Jason.decode(header_json)
  rescue
    ArgumentError ->
      {:error, {:verification_failure, "Failed to decode signed object: invalid format"}}

    ErlangError ->
      {:error, {:verification_failure, "Failed to decode signed object: invalid format"}}
  end

  defp peek_payload(signed_obj) do
    payload_json = JOSE.JWS.peek_payload(signed_obj)
    Jason.decode(payload_json)
  rescue
    ArgumentError ->
      {:error, {:verification_failure, "Failed to decode signed object: invalid format"}}

    ErlangError ->
      {:error, {:verification_failure, "Failed to decode signed object: invalid format"}}
  end

  @expected_algorithm "ES256"
  @expected_chain_length 3

  # Validate algorithm and x5c header together, matching Swift's approach
  defp validate_jwt_headers(algorithm, x5c_header)
       when algorithm == @expected_algorithm and length(x5c_header) == @expected_chain_length,
       do: :ok

  defp validate_jwt_headers(algorithm, _x5c_header) when algorithm != @expected_algorithm,
    do: {:error, {:verification_failure, "Algorithm was not ES256"}}

  defp validate_jwt_headers(_algorithm, x5c_header) when x5c_header in [nil, []],
    do: {:error, {:verification_failure, "x5c claim was empty"}}

  defp validate_jwt_headers(_algorithm, _x5c_header),
    do: {:error, {:invalid_chain_length, "x5c chain has unexpected length"}}

  defp get_effective_date(payload, enable_online_checks) do
    signed_date = Map.get(payload, "signedDate") || Map.get(payload, "receiptCreationDate")

    cond do
      enable_online_checks or signed_date == nil ->
        {:ok, System.system_time(:second)}

      is_number(signed_date) ->
        # signed_date is in milliseconds, convert to seconds
        # Use trunc/1 to handle floats (Xcode payloads can have fractional milliseconds)
        {:ok, trunc(signed_date / 1000)}

      true ->
        {:error, {:verification_failure, "Invalid signedDate format: expected a number"}}
    end
  end

  defp verify_signature(signed_obj, public_key_pem) do
    jwk = JOSE.JWK.from_pem(public_key_pem)

    case JOSE.JWS.verify(jwk, signed_obj) do
      {true, _payload, _jws} -> :ok
      {false, _, _} -> {:error, {:verification_failure, "Signature verification failed"}}
    end
  rescue
    ArgumentError ->
      {:error, {:verification_failure, "Signature verification failed: invalid key"}}

    ErlangError ->
      {:error, {:verification_failure, "Signature verification failed"}}
  end

  @doc false
  def verify_environment(verifier, environment) do
    if environment == verifier.environment do
      :ok
    else
      {:error, {:invalid_environment, "Environment mismatch"}}
    end
  end

  @doc false
  def verify_bundle_id(verifier, bundle_id) do
    if bundle_id == verifier.bundle_id do
      :ok
    else
      {:error, {:invalid_app_identifier, "Bundle ID mismatch"}}
    end
  end

  defp verify_app_transaction_bundle_id(verifier, bundle_id, app_apple_id) do
    cond do
      bundle_id != verifier.bundle_id ->
        {:error, {:invalid_app_identifier, "Bundle ID mismatch"}}

      verifier.environment == :production and app_apple_id != verifier.app_apple_id ->
        {:error, {:invalid_app_identifier, "App Apple ID mismatch"}}

      true ->
        :ok
    end
  end

  defp verify_notification_data(verifier, bundle_id, app_apple_id, environment) do
    cond do
      bundle_id != verifier.bundle_id or
          (verifier.environment == :production and app_apple_id != verifier.app_apple_id) ->
        {:error, {:invalid_app_identifier, "App identifier mismatch"}}

      environment != verifier.environment ->
        {:error, {:invalid_environment, "Environment mismatch"}}

      true ->
        :ok
    end
  end

  defp verify_realtime_app_apple_id(verifier, app_apple_id) do
    if verifier.environment == :production and app_apple_id != verifier.app_apple_id do
      {:error, {:invalid_app_identifier, "App Apple ID mismatch"}}
    else
      :ok
    end
  end

  defp extract_notification_data(%{data: %{} = data}) do
    {:ok,
     {get_field(data, :bundle_id), get_field(data, :app_apple_id), get_field(data, :environment)}}
  end

  defp extract_notification_data(%{summary: %{} = summary}) do
    {:ok,
     {get_field(summary, :bundle_id), get_field(summary, :app_apple_id),
      get_field(summary, :environment)}}
  end

  defp extract_notification_data(%{external_purchase_token: %{} = token}) do
    external_purchase_id = get_field(token, :external_purchase_id)

    environment =
      if external_purchase_id && String.starts_with?(external_purchase_id, "SANDBOX") do
        :sandbox
      else
        :production
      end

    {:ok, {get_field(token, :bundle_id), get_field(token, :app_apple_id), environment}}
  end

  defp extract_notification_data(_notification) do
    {:error,
     {:verification_failure,
      "Notification does not contain data, summary, or external_purchase_token"}}
  end

  # Helper to safely get field from struct or map
  defp get_field(data, key) when is_map(data), do: Map.get(data, key)

  # Struct conversion helpers with snake_case field mapping

  defp to_renewal_info_struct(payload) do
    payload
    |> JSON.keys_to_atoms()
    |> JWSRenewalInfoDecodedPayload.new()
  end

  defp to_transaction_struct(payload) do
    payload
    |> JSON.keys_to_atoms()
    |> JWSTransactionDecodedPayload.new()
  end

  defp to_notification_struct(payload) do
    payload = JSON.keys_to_atoms(payload)

    with {:ok, base} <- ResponseBodyV2DecodedPayload.new(payload),
         {:ok, data} <-
           maybe_build_struct(Map.get(base, :data), AppStoreServerLibrary.Models.Data),
         {:ok, summary} <- maybe_build_struct(Map.get(base, :summary), Summary),
         {:ok, external_purchase_token} <-
           maybe_build_struct(Map.get(base, :external_purchase_token), ExternalPurchaseToken) do
      case {data, summary, external_purchase_token} do
        {nil, nil, nil} ->
          {:error, {:verification_failure, "Invalid notification payload"}}

        _ ->
          {:ok,
           %{
             base
             | data: data,
               summary: summary,
               external_purchase_token: external_purchase_token
           }}
      end
    end
  end

  defp to_app_transaction_struct(payload) do
    payload
    |> JSON.keys_to_atoms()
    |> AppTransaction.new()
  end

  defp to_realtime_request_struct(payload) do
    payload
    |> JSON.keys_to_atoms()
    |> DecodedRealtimeRequestBody.new()
  end

  defp to_summary_struct(payload) do
    payload
    |> JSON.keys_to_atoms()
    |> Summary.new()
  end

  defp maybe_build_struct(nil, _module), do: {:ok, nil}
  defp maybe_build_struct(%{} = data, module), do: data |> JSON.keys_to_atoms() |> module.new()

  defp maybe_build_struct(_, _module),
    do: {:error, {:verification_failure, "Invalid notification payload"}}
end
