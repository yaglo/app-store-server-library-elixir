defmodule AppStoreServerLibrary.X509VerificationTest do
  use ExUnit.Case, async: false

  alias AppStoreServerLibrary.Cache.CertificateCache
  alias AppStoreServerLibrary.Verification.ChainVerifier

  # Test certificates from Python test suite
  @root_ca_base64 "MIIBgjCCASmgAwIBAgIJALUc5ALiH5pbMAoGCCqGSM49BAMDMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlDdXBlcnRpbm8wHhcNMjMwMTA1MjEzMDIyWhcNMzMwMTAyMjEzMDIyWjA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEc+/Bl+gospo6tf9Z7io5tdKdrlN1YdVnqEhEDXDShzdAJPQijamXIMHf8xWWTa1zgoYTxOKpbuJtDplz1XriTaMgMB4wDAYDVR0TBAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwMDRwAwRAIgemWQXnMAdTad2JDJWng9U4uBBL5mA7WI05H7oH7c6iQCIHiRqMjNfzUAyiu9h6rOU/K+iTR0I/3Y/NSWsXHX+acc"
  @intermediate_ca_base64 "MIIBnzCCAUWgAwIBAgIBCzAKBggqhkjOPQQDAzA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMB4XDTIzMDEwNTIxMzEwNVoXDTMzMDEwMTIxMzEwNVowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xFTATBgNVBAoMDEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBUN5V9rKjfRiMAIojEA0Av5Mp0oF+O0cL4gzrTF178inUHugj7Et46NrkQ7hKgMVnjogq45Q1rMs+cMHVNILWqjNTAzMA8GA1UdEwQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgEEAgUAMAoGCCqGSM49BAMDA0gAMEUCIQCmsIKYs41ullssHX4rVveUT0Z7Is5/hLK1lFPTtun3hAIgc2+2RG5+gNcFVcs+XJeEl4GZ+ojl3ROOmll+ye7dynQ="
  @leaf_cert_base64 "MIIBoDCCAUagAwIBAgIBDDAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzEzNFoXDTMzMDEwMTIxMzEzNFowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNIADBFAiBX4c+T0Fp5nJ5QRClRfu5PSByRvNPtuaTsk0vPB3WAIAIhANgaauAj/YP9s0AkEhyJhxQO/6Q2zouZ+H1CIOehnMzQ"

  @intermediate_ca_invalid_oid_base64 "MIIBnjCCAUWgAwIBAgIBDTAKBggqhkjOPQQDAzA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMB4XDTIzMDEwNTIxMzYxNFoXDTMzMDEwMTIxMzYxNFowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xFTATBgNVBAoMDEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBUN5V9rKjfRiMAIojEA0Av5Mp0oF+O0cL4gzrTF178inUHugj7Et46NrkQ7hKgMVnjogq45Q1rMs+cMHVNILWqjNTAzMA8GA1UdEwQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgIEAgUAMAoGCCqGSM49BAMDA0cAMEQCIFROtTE+RQpKxNXETFsf7Mc0h+5IAsxxo/X6oCC/c33qAiAmC5rn5yCOOEjTY4R1H1QcQVh+eUwCl13NbQxWCuwxxA=="
  @leaf_cert_for_intermediate_ca_invalid_oid_base64 "MIIBnzCCAUagAwIBAgIBDjAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzY1OFoXDTMzMDEwMTIxMzY1OFowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNHADBEAiAUAs+gzYOsEXDwQquvHYbcVymyNqDtGw9BnUFp2YLuuAIgXxQ3Ie9YU0cMqkeaFd+lyo0asv9eyzk6stwjeIeOtTU="
  @leaf_cert_invalid_oid_base64 "MIIBoDCCAUagAwIBAgIBDzAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzczMVoXDTMzMDEwMTIxMzczMVowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsCBAIFADAKBggqhkjOPQQDAwNIADBFAiAb+7S3i//bSGy7skJY9+D4VgcQLKFeYfIMSrUCmdrFqwIhAIMVwzD1RrxPRtJyiOCXLyibIvwcY+VS73HYfk0O9lgz"

  @real_apple_root_base64 "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA=="

  @effective_date 1_761_962_975

  describe "ChainVerifier" do
    test "invalid chain length - too short" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:invalid_chain_length, _message}} = result
    end

    test "invalid chain length - too long" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @leaf_cert_base64,
            @intermediate_ca_base64,
            @root_ca_base64,
            @root_ca_base64
          ],
          false,
          @effective_date
        )

      assert {:error, {:invalid_chain_length, _message}} = result
    end

    test "invalid base64 in certificate list" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          ["not-valid-base64!!!", @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:invalid_certificate, _message}} = result
    end

    test "invalid data in certificate list returns error" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      # Valid base64 but not a valid certificate
      invalid_cert = Base.encode64("abc")

      result =
        ChainVerifier.verify_chain(
          verifier,
          [invalid_cert, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {error_type, _message}} = result
      assert error_type in [:invalid_certificate, :verification_failure]
    end

    test "empty root certificates" do
      verifier = ChainVerifier.new([], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:invalid_certificate, _message}} = result
    end

    test "chain verification with mismatched root returns error" do
      # Use real Apple root but test certificates signed by different root
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      # Use enable_strict_checks: true to actually verify the chain
      verifier = ChainVerifier.new([real_apple_root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should fail because chain doesn't match root
      assert {:error, _reason} = result
    end

    test "verifier creation with valid parameters" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      assert verifier.root_certificates == [root_der]
      assert verifier.enable_strict_checks == true
    end

    test "verifier creation with default strict checks" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der])

      assert verifier.enable_strict_checks == true
    end

    test "invalid intermediate OID returns verification failure" do
      root_der = Base.decode64!(@root_ca_base64)
      # Use enable_strict_checks: true to enable OID checking
      verifier = ChainVerifier.new([root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @leaf_cert_for_intermediate_ca_invalid_oid_base64,
            @intermediate_ca_invalid_oid_base64,
            @root_ca_base64
          ],
          false,
          @effective_date
        )

      assert {:error, _reason} = result
    end

    test "invalid leaf OID returns verification failure" do
      root_der = Base.decode64!(@root_ca_base64)
      # Use enable_strict_checks: true to enable OID checking
      verifier = ChainVerifier.new([root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_invalid_oid_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, _reason} = result
    end

    test "successful verification without strict checks returns public key" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, public_key_pem, _updated_verifier} = result
      assert public_key_pem =~ "-----BEGIN PUBLIC KEY-----"
      assert public_key_pem =~ "-----END PUBLIC KEY-----"
    end
  end

  describe "ChainVerifier caching with CertificateCache GenServer" do
    setup do
      # Clear cache before each test
      CertificateCache.clear()
      :ok
    end

    test "caches public key when online checks enabled" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      # Cache should be empty initially
      assert CertificateCache.stats().size == 0

      # First verification should update the cache
      {:ok, public_key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      # Cache should have one entry
      assert CertificateCache.stats().size == 1

      # Second verification should use cache and return same key
      {:ok, cached_key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      assert public_key == cached_key
      # Cache size should remain the same
      assert CertificateCache.stats().size == 1
    end

    test "does not cache when online checks disabled" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      {:ok, _public_key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, false, @effective_date)

      # Cache should be empty when online checks are disabled
      assert CertificateCache.stats().size == 0
    end

    test "cache hit returns cached public key" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      # Populate cache
      {:ok, original_key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      # Verify cache hit returns same key
      {:ok, cached_key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      assert original_key == cached_key
    end

    test "cache can be cleared" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      # Populate cache
      {:ok, _key, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      assert CertificateCache.stats().size == 1

      # Clear cache
      CertificateCache.clear()
      assert CertificateCache.stats().size == 0
    end

    test "verifier struct is returned unchanged" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      {:ok, _key, updated_verifier} =
        ChainVerifier.verify_chain(verifier, certs, true, @effective_date)

      assert updated_verifier == verifier
    end
  end

  describe "ChainVerifier public key extraction" do
    test "extracts valid PEM formatted public key" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      {:ok, public_key_pem, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, false, @effective_date)

      # Verify PEM format
      assert String.starts_with?(public_key_pem, "-----BEGIN PUBLIC KEY-----")
      assert String.ends_with?(public_key_pem, "-----END PUBLIC KEY-----\n")

      # Verify base64 content is properly wrapped (64 chars per line)
      lines = String.split(public_key_pem, "\n")
      # Skip header and footer, check content lines
      content_lines = Enum.slice(lines, 1..-3//1)

      Enum.each(content_lines, fn line ->
        assert String.length(line) <= 64
      end)
    end

    test "public key can be parsed by JOSE" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)
      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      {:ok, public_key_pem, _verifier} =
        ChainVerifier.verify_chain(verifier, certs, false, @effective_date)

      # Verify the PEM can be parsed by JOSE
      jwk = JOSE.JWK.from_pem(public_key_pem)
      assert jwk != nil
    end
  end

  describe "ChainVerifier strict vs non-strict mode" do
    test "non-strict mode skips certificate chain verification" do
      # Different root than what signed the certs - would fail in strict mode
      different_root = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([different_root], false)

      certs = [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64]

      # Should succeed because strict checks are disabled
      result = ChainVerifier.verify_chain(verifier, certs, false, @effective_date)
      assert {:ok, _public_key, _verifier} = result
    end

    test "non-strict mode skips OID verification" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      # Use certificates with invalid OIDs
      certs = [
        @leaf_cert_invalid_oid_base64,
        @intermediate_ca_base64,
        @root_ca_base64
      ]

      # Should succeed because strict checks are disabled
      result = ChainVerifier.verify_chain(verifier, certs, false, @effective_date)
      assert {:ok, _public_key, _verifier} = result
    end
  end
end
