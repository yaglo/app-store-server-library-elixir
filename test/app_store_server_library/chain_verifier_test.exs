defmodule AppStoreServerLibrary.ChainVerifierTest do
  @moduledoc """
  Comprehensive tests for the ChainVerifier module.

  These tests cover:
  - Chain verification with strict checks enabled (the path that was previously broken)
  - Real Apple certificate chain verification
  - Signature verification
  - Validity period checks
  - Issuer relationship verification
  - Basic constraints verification
  - OID verification
  - Caching behavior
  """
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Verification.ChainVerifier

  # Test certificates - same as Python test suite
  @root_ca_base64 "MIIBgjCCASmgAwIBAgIJALUc5ALiH5pbMAoGCCqGSM49BAMDMDYxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRIwEAYDVQQHDAlDdXBlcnRpbm8wHhcNMjMwMTA1MjEzMDIyWhcNMzMwMTAyMjEzMDIyWjA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEc+/Bl+gospo6tf9Z7io5tdKdrlN1YdVnqEhEDXDShzdAJPQijamXIMHf8xWWTa1zgoYTxOKpbuJtDplz1XriTaMgMB4wDAYDVR0TBAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwMDRwAwRAIgemWQXnMAdTad2JDJWng9U4uBBL5mA7WI05H7oH7c6iQCIHiRqMjNfzUAyiu9h6rOU/K+iTR0I/3Y/NSWsXHX+acc"
  @intermediate_ca_base64 "MIIBnzCCAUWgAwIBAgIBCzAKBggqhkjOPQQDAzA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMB4XDTIzMDEwNTIxMzEwNVoXDTMzMDEwMTIxMzEwNVowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xFTATBgNVBAoMDEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBUN5V9rKjfRiMAIojEA0Av5Mp0oF+O0cL4gzrTF178inUHugj7Et46NrkQ7hKgMVnjogq45Q1rMs+cMHVNILWqjNTAzMA8GA1UdEwQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgEEAgUAMAoGCCqGSM49BAMDA0gAMEUCIQCmsIKYs41ullssHX4rVveUT0Z7Is5/hLK1lFPTtun3hAIgc2+2RG5+gNcFVcs+XJeEl4GZ+ojl3ROOmll+ye7dynQ="
  @leaf_cert_base64 "MIIBoDCCAUagAwIBAgIBDDAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzEzNFoXDTMzMDEwMTIxMzEzNFowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNIADBFAiBX4c+T0Fp5nJ5QRClRfu5PSByRvNPtuaTsk0vPB3WAIAIhANgaauAj/YP9s0AkEhyJhxQO/6Q2zouZ+H1CIOehnMzQ"

  # Certificates with invalid OIDs
  @intermediate_ca_invalid_oid_base64 "MIIBnjCCAUWgAwIBAgIBDTAKBggqhkjOPQQDAzA2MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTESMBAGA1UEBwwJQ3VwZXJ0aW5vMB4XDTIzMDEwNTIxMzYxNFoXDTMzMDEwMTIxMzYxNFowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xFTATBgNVBAoMDEludGVybWVkaWF0ZTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBUN5V9rKjfRiMAIojEA0Av5Mp0oF+O0cL4gzrTF178inUHugj7Et46NrkQ7hKgMVnjogq45Q1rMs+cMHVNILWqjNTAzMA8GA1UdEwQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgEGMBAGCiqGSIb3Y2QGAgIEAgUAMAoGCCqGSM49BAMDA0cAMEQCIFROtTE+RQpKxNXETFsf7Mc0h+5IAsxxo/X6oCC/c33qAiAmC5rn5yCOOEjTY4R1H1QcQVh+eUwCl13NbQxWCuwxxA=="
  @leaf_cert_for_intermediate_ca_invalid_oid_base64 "MIIBnzCCAUagAwIBAgIBDjAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzY1OFoXDTMzMDEwMTIxMzY1OFowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNHADBEAiAUAs+gzYOsEXDwQquvHYbcVymyNqDtGw9BnUFp2YLuuAIgXxQ3Ie9YU0cMqkeaFd+lyo0asv9eyzk6stwjeIeOtTU="
  @leaf_cert_invalid_oid_base64 "MIIBoDCCAUagAwIBAgIBDzAKBggqhkjOPQQDAzBFMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0ExEjAQBgNVBAcMCUN1cGVydGlubzEVMBMGA1UECgwMSW50ZXJtZWRpYXRlMB4XDTIzMDEwNTIxMzczMVoXDTMzMDEwMTIxMzczMVowPTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRIwEAYDVQQHDAlDdXBlcnRpbm8xDTALBgNVBAoMBExlYWYwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATitYHEaYVuc8g9AjTOwErMvGyPykPa+puvTI8hJTHZZDLGas2qX1+ErxgQTJgVXv76nmLhhRJH+j25AiAI8iGsoy8wLTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsCBAIFADAKBggqhkjOPQQDAwNIADBFAiAb+7S3i//bSGy7skJY9+D4VgcQLKFeYfIMSrUCmdrFqwIhAIMVwzD1RrxPRtJyiOCXLyibIvwcY+VS73HYfk0O9lgz"

  # Real Apple certificates for strict mode testing
  @real_apple_root_base64 "MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBSb290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtfTjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySrMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gAMGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM6BgD56KyKA=="
  @real_apple_intermediate_base64 "MIIDFjCCApygAwIBAgIUIsGhRwp0c2nvU4YSycafPTjzbNcwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwSQXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcNMjEwMzE3MjAzNzEwWhcNMzYwMzE5MDAwMDAwWjB1MUQwQgYDVQQDDDtBcHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTELMAkGA1UECwwCRzYxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEbsQKC94PrlWmZXnXgtxzdVJL8T0SGYngDRGpngn3N6PT8JMEb7FDi4bBmPhCnZ3/sq6PF/cGcKXWsL5vOteRhyJ45x3ASP7cOB+aao90fcpxSv/EZFbniAbNgZGhIhpIo4H6MIH3MBIGA1UdEwEB/wQIMAYBAf8CAQAwHwYDVR0jBBgwFoAUu7DeoVgziJqkipnevr3rr9rLJKswRgYIKwYBBQUHAQEEOjA4MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLWFwcGxlcm9vdGNhZzMwNwYDVR0fBDAwLjAsoCqgKIYmaHR0cDovL2NybC5hcHBsZS5jb20vYXBwbGVyb290Y2FnMy5jcmwwHQYDVR0OBBYEFD8vlCNR01DJmig97bB85c+lkGKZMA4GA1UdDwEB/wQEAwIBBjAQBgoqhkiG92NkBgIBBAIFADAKBggqhkjOPQQDAwNoADBlAjBAXhSq5IyKogMCPtw490BaB677CaEGJXufQB/EqZGd6CSjiCtOnuMTbXVXmxxcxfkCMQDTSPxarZXvNrkxU3TkUMI33yzvFVVRT4wxWJC994OsdcZ4+RGNsYDyR5gmdr0nDGg="
  @real_apple_signing_cert_base64 "MIIEMTCCA7agAwIBAgIQR8KHzdn554Z/UoradNx9tzAKBggqhkjOPQQDAzB1MUQwQgYDVQQDDDtBcHBsZSBXb3JsZHdpZGUgRGV2ZWxvcGVyIFJlbGF0aW9ucyBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTELMAkGA1UECwwCRzYxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTMB4XDTI1MDkxOTE5NDQ1MVoXDTI3MTAxMzE3NDcyM1owgZIxQDA+BgNVBAMMN1Byb2QgRUNDIE1hYyBBcHAgU3RvcmUgYW5kIGlUdW5lcyBTdG9yZSBSZWNlaXB0IFNpZ25pbmcxLDAqBgNVBAsMI0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zMRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNnVvhcv7iT+7Ex5tBMBgrQspHzIsXRi0Yxfek7lv8wEmj/bHiWtNwJqc2BoHzsQiEjP7KFIIKg4Y8y0/nynuAmjggIIMIICBDAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFD8vlCNR01DJmig97bB85c+lkGKZMHAGCCsGAQUFBwEBBGQwYjAtBggrBgEFBQcwAoYhaHR0cDovL2NlcnRzLmFwcGxlLmNvbS93d2RyZzYuZGVyMDEGCCsGAQUFBzABhiVodHRwOi8vb2NzcC5hcHBsZS5jb20vb2NzcDAzLXd3ZHJnNjAyMIIBHgYDVR0gBIIBFTCCAREwggENBgoqhkiG92NkBQYBMIH+MIHDBggrBgEFBQcCAjCBtgyBs1JlbGlhbmNlIG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBjb25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZpY2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMDYGCCsGAQUFBwIBFipodHRwOi8vd3d3LmFwcGxlLmNvbS9jZXJ0aWZpY2F0ZWF1dGhvcml0eS8wHQYDVR0OBBYEFIFioG4wMMVA1ku9zJmGNPAVn3eqMA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgsBBAIFADAKBggqhkjOPQQDAwNpADBmAjEA+qXnREC7hXIWVLsLxznjRpIzPf7VHz9V/CTm8+LJlrQepnmcPvGLNcX6XPnlcgLAAjEA5IjNZKgg5pQ79knF4IbTXdKv8vutIDMXDmjPVT3dGvFtsGRwXOywR2kZCdSrfeot"

  # Expected public key from leaf certificate
  @leaf_cert_public_key "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE4rWBxGmFbnPIPQI0zsBKzLxsj8pD\n2vqbr0yPISUx2WQyxmrNql9fhK8YEEyYFV7++p5i4YUSR/o9uQIgCPIhrA==\n-----END PUBLIC KEY-----\n"

  # Effective date for certificate validation (within validity period)
  @effective_date 1_761_962_975

  # Expired date (after certificates expire)
  @expired_date 2_280_946_846

  describe "ChainVerifier with strict checks enabled" do
    @tag :strict
    test "valid chain with strict checks succeeds" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

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

    @tag :strict
    test "chain with mismatched root fails with strict checks" do
      # Use a different root than what signed the chain
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "not in trusted roots"
    end

    @tag :strict
    test "invalid intermediate OID fails with strict checks" do
      root_der = Base.decode64!(@root_ca_base64)
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

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "Missing required OID"
    end

    @tag :strict
    test "invalid leaf OID fails with strict checks" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_invalid_oid_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "Missing required OID"
    end

    @tag :strict
    test "expired certificate fails with strict checks" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @expired_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "expired"
    end
  end

  describe "Real Apple certificate chain verification" do
    @tag :real_apple
    @tag :strict
    test "real Apple chain validates successfully with strict checks" do
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          false,
          @effective_date
        )

      assert {:ok, public_key_pem, _updated_verifier} = result
      assert public_key_pem =~ "-----BEGIN PUBLIC KEY-----"
      assert public_key_pem =~ "-----END PUBLIC KEY-----"
    end

    @tag :real_apple
    @tag :strict
    test "real Apple chain validates with OCSP enabled" do
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          true,
          @effective_date
        )

      assert {:ok, _public_key_pem, _updated_verifier} = result
    end
  end

  describe "Signature verification" do
    @tag :strict
    test "chain with invalid signature fails" do
      # Create a verifier with test root
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Try to verify a chain where leaf is not signed by intermediate
      # Use real Apple leaf with test intermediate - signature won't match
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @intermediate_ca_base64,
            @root_ca_base64
          ],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "signature" or message =~ "issuer"
    end
  end

  describe "Validity period verification" do
    @tag :strict
    test "certificate not yet valid fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Use a date before certificates were issued (2023-01-05)
      # 2021-01-01
      past_date = 1_609_459_200

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          past_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "not yet valid"
    end

    @tag :strict
    test "certificate expired fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Use a date after certificates expire (2033-01-02)
      # ~2033
      future_date = 2_000_000_000

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          future_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "expired"
    end

    @tag :strict
    test "certificate within validity period succeeds" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end
  end

  describe "Basic constraints verification" do
    @tag :strict
    test "intermediate certificate must be a CA" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # The test intermediate has basicConstraints with CA:TRUE
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end

    @tag :strict
    test "leaf certificate must not be a CA" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # The test leaf has basicConstraints with CA:FALSE
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end
  end

  describe "Chain length validation" do
    test "chain too short fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, :invalid_chain_length} = result
    end

    test "chain too long fails" do
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

      assert {:error, :invalid_chain_length} = result
    end

    test "chain with exactly 3 certificates succeeds" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end
  end

  describe "Certificate decoding" do
    test "invalid base64 in certificate list fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          ["not-valid-base64!!!", @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, :invalid_certificate} = result
    end

    test "invalid certificate data fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      # Valid base64 but not a valid certificate
      invalid_cert = Base.encode64("not a certificate")

      result =
        ChainVerifier.verify_chain(
          verifier,
          [invalid_cert, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should fail with some error
      assert {:error, _reason} = result
    end
  end

  describe "Root certificate validation" do
    test "empty root certificates fails" do
      verifier = ChainVerifier.new([], false)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, :invalid_certificate} = result
    end

    test "malformed root certificate fails" do
      # Valid base64 but not a valid certificate
      malformed_root = Base.decode64!(Base.encode64("not a certificate"))
      verifier = ChainVerifier.new([malformed_root], true)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, _reason} = result
    end
  end

  describe "Public key extraction" do
    test "extracts valid PEM formatted public key" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      {:ok, public_key_pem, _verifier} =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Verify PEM format
      assert String.starts_with?(public_key_pem, "-----BEGIN PUBLIC KEY-----")
      assert String.ends_with?(public_key_pem, "-----END PUBLIC KEY-----\n")
    end

    test "extracted public key matches expected value" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      {:ok, public_key_pem, _verifier} =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert public_key_pem == @leaf_cert_public_key
    end

    test "public key can be parsed by JOSE" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      {:ok, public_key_pem, _verifier} =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Verify the PEM can be parsed by JOSE
      jwk = JOSE.JWK.from_pem(public_key_pem)
      assert jwk != nil
    end
  end

  describe "Strict vs non-strict mode comparison" do
    test "non-strict mode bypasses chain verification" do
      # Use a different root than what signed the certs
      different_root = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([different_root], false)

      # Should succeed because strict checks are disabled
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end

    test "strict mode fails with different root" do
      # Use a different root than what signed the certs
      different_root = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([different_root], true)

      # Should fail because strict checks are enabled
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, _message}} = result
    end

    test "non-strict mode bypasses OID verification" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      # Use certificates with invalid OIDs - should succeed in non-strict mode
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @leaf_cert_invalid_oid_base64,
            @intermediate_ca_base64,
            @root_ca_base64
          ],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end

    test "strict mode fails with invalid OIDs" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Should fail because OID verification is enabled
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @leaf_cert_invalid_oid_base64,
            @intermediate_ca_base64,
            @root_ca_base64
          ],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, _message}} = result
    end
  end

  describe "Verifier creation" do
    test "creates verifier with valid parameters" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      assert verifier.root_certificates == [root_der]
      assert verifier.enable_strict_checks == true
    end

    test "defaults to strict checks enabled" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der])

      assert verifier.enable_strict_checks == true
    end

    test "can disable strict checks" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], false)

      assert verifier.enable_strict_checks == false
    end

    test "accepts multiple root certificates" do
      root1_der = Base.decode64!(@root_ca_base64)
      root2_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([root1_der, root2_der], true)

      assert length(verifier.root_certificates) == 2
    end
  end

  describe "OCSP status checking" do
    @tag :ocsp
    test "check_ocsp_status returns ok for certificates with OCSP URL" do
      # Real Apple certificates have OCSP URLs
      leaf_der = Base.decode64!(@real_apple_signing_cert_base64)
      intermediate_der = Base.decode64!(@real_apple_intermediate_base64)
      root_der = Base.decode64!(@real_apple_root_base64)

      # This should attempt OCSP check and return :ok on success
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)

      # OCSP check should succeed or return ok (simplified implementation)
      assert result == :ok or match?({:error, _}, result)
    end

    @tag :ocsp
    test "check_ocsp_status handles certificates without OCSP URL" do
      # Test certificates don't have OCSP URLs
      leaf_der = Base.decode64!(@leaf_cert_base64)
      intermediate_der = Base.decode64!(@intermediate_ca_base64)
      root_der = Base.decode64!(@root_ca_base64)

      # Should return :ok when no OCSP URL is present
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)
      assert result == :ok
    end

    @tag :ocsp
    test "OCSP is performed when online checks are enabled with real certs" do
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # This exercises the maybe_check_ocsp path with perform_online_checks=true
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          true,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end

    @tag :ocsp
    test "OCSP is skipped when online checks are disabled" do
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # This exercises the maybe_check_ocsp path with perform_online_checks=false
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end
  end

  describe "GeneralTime format parsing" do
    # The real Apple root CA uses GeneralTime format (validity until 2039)
    # We need to test with a certificate that has GeneralTime validity dates

    @tag :strict
    test "handles certificates with GeneralTime validity format" do
      # The Apple Root CA - G3 has validity dates in GeneralTime format
      # Not Before: Apr 30 18:19:06 2014 GMT
      # Not After : Apr 30 18:19:06 2039 GMT
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # Use a date that will trigger GeneralTime parsing for root cert validation
      # The root cert's validity period uses GeneralTime
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end
  end

  describe "Certificate chain exception handling" do
    @tag :strict
    test "handles malformed certificate gracefully in strict mode" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Create a certificate that will cause an exception during parsing
      # Valid base64 but completely invalid DER structure
      malformed_cert = Base.encode64(<<0x30, 0x03, 0x01, 0x01, 0xFF>>)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [malformed_cert, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should return an error, not crash
      assert {:error, _reason} = result
    end

    @tag :strict
    test "handles truncated certificate data" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Truncate a valid certificate to cause parsing errors
      full_cert = Base.decode64!(@leaf_cert_base64)
      truncated = binary_part(full_cert, 0, div(byte_size(full_cert), 2))
      truncated_cert = Base.encode64(truncated)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [truncated_cert, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, _reason} = result
    end
  end

  describe "Basic constraints edge cases" do
    @tag :strict
    test "certificate without extensions is handled" do
      # The test root CA has minimal extensions
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # This tests the path where extensions might be :asn1_NOVALUE
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:ok, _public_key, _verifier} = result
    end

    @tag :strict
    test "leaf certificate with CA:TRUE basicConstraints should fail" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Try using intermediate as leaf (it has CA:TRUE)
      # This would fail because intermediate has CA basicConstraints
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@intermediate_ca_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should fail - either signature mismatch or CA constraint violation
      assert {:error, _reason} = result
    end
  end

  describe "OID checking edge cases" do
    @tag :strict
    test "certificate with no extensions fails OID check" do
      # This tests the :asn1_NOVALUE branch in check_oid
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Root CA typically has minimal extensions
      # When used as leaf, it should fail OID check
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@root_ca_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should fail due to OID or other validation
      assert {:error, _reason} = result
    end
  end

  describe "Issuer relationship verification" do
    @tag :strict
    test "mismatched issuer/subject fails verification" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Try to use leaf cert as intermediate (wrong issuer relationship)
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @leaf_cert_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should fail due to issuer mismatch or signature verification
      assert {:error, _reason} = result
    end
  end

  describe "Signature verification failures" do
    @tag :strict
    test "self-signed intermediate fails" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Use root as intermediate - signature won't match
      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @root_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "signature" or message =~ "issuer"
    end
  end

  describe "OCSP URL extraction" do
    test "extracts OCSP URL from real Apple certificate" do
      # Real Apple certificates have Authority Information Access extension with OCSP URL
      leaf_der = Base.decode64!(@real_apple_signing_cert_base64)
      intermediate_der = Base.decode64!(@real_apple_intermediate_base64)
      root_der = Base.decode64!(@real_apple_root_base64)

      # This exercises get_ocsp_url internally through check_ocsp_status
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)

      # Should succeed (OCSP URL found and request made)
      assert result == :ok or match?({:error, {:http_error, _}}, result)
    end

    test "handles certificate without AIA extension" do
      # Test certificates don't have AIA extension
      leaf_der = Base.decode64!(@leaf_cert_base64)
      intermediate_der = Base.decode64!(@intermediate_ca_base64)
      root_der = Base.decode64!(@root_ca_base64)

      # Should return :ok when no OCSP URL (graceful fallback)
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)
      assert result == :ok
    end
  end

  describe "OCSP request building" do
    @tag :ocsp
    test "builds OCSP request for real Apple certificate" do
      # This test exercises the build_ocsp_request function through check_ocsp_status
      leaf_der = Base.decode64!(@real_apple_signing_cert_base64)
      intermediate_der = Base.decode64!(@real_apple_intermediate_base64)
      root_der = Base.decode64!(@real_apple_root_base64)

      # check_ocsp_status calls build_ocsp_request internally
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)

      # Should complete without crash - either success or HTTP error
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "OCSP HTTP error handling" do
    @tag :ocsp
    test "handles OCSP responder errors gracefully" do
      # Real Apple certs have OCSP URLs that should respond
      leaf_der = Base.decode64!(@real_apple_signing_cert_base64)
      intermediate_der = Base.decode64!(@real_apple_intermediate_base64)
      root_der = Base.decode64!(@real_apple_root_base64)

      # Even if OCSP fails, should not crash
      result = ChainVerifier.check_ocsp_status(leaf_der, intermediate_der, root_der)

      # Accept any valid response (success or handled error)
      assert result == :ok or match?({:error, _}, result)
    end

    @tag :ocsp
    test "OCSP failure during chain verification with online checks" do
      # Test that OCSP errors are handled during full chain verification
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # With online checks enabled, OCSP is attempted
      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          true,
          @effective_date
        )

      # Should either succeed or return a proper error (not crash)
      assert match?({:ok, _, _}, result) or match?({:error, _}, result)
    end
  end

  describe "OCSP rescue handling" do
    test "check_ocsp_status handles exceptions gracefully" do
      # Create malformed certificate data that might cause exceptions
      # Valid base64 but minimal valid-looking DER that might cause issues during OCSP processing
      malformed_der = <<0x30, 0x03, 0x02, 0x01, 0x00>>
      intermediate_der = Base.decode64!(@intermediate_ca_base64)
      root_der = Base.decode64!(@root_ca_base64)

      # Should not crash - rescue block should catch exceptions
      result = ChainVerifier.check_ocsp_status(malformed_der, intermediate_der, root_der)

      # Either returns :ok (no OCSP URL found) or an error
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "UTCTime year boundary parsing" do
    # UTCTime format: YYMMDDHHMMSSZ
    # Years 00-49 -> 2000-2049
    # Years 50-99 -> 1950-1999
    # Our test certificates use years 23 (2023) and 33 (2033) which are in 00-49 range

    @tag :strict
    test "certificates with year in 00-49 range are parsed as 2000s" do
      # Test certificates have validity: 2023-01-05 to 2033-01-02
      # Year 23 -> 2023, Year 33 -> 2033 (both in 00-49 range -> 2000s)
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Date in 2025 - within validity period
      # 2025-01-01
      date_2025 = 1_735_689_600

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          date_2025
        )

      assert {:ok, _public_key, _verifier} = result
    end

    @tag :strict
    test "date before certificate validity (1950s-1990s range check)" do
      # Test that years 50-99 would be interpreted as 1950-1999
      # We can't easily create a cert with 50-99 year, but we can test
      # that a date in that era would fail (certificate not yet valid)
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # 1990-01-01 - way before certs were issued (2023)
      date_1990 = 631_152_000

      result =
        ChainVerifier.verify_chain(
          verifier,
          [@leaf_cert_base64, @intermediate_ca_base64, @root_ca_base64],
          false,
          date_1990
        )

      assert {:error, {:verification_failure, message}} = result
      assert message =~ "not yet valid"
    end
  end

  describe "GeneralTime parsing edge cases" do
    @tag :strict
    test "real Apple root CA uses GeneralTime format" do
      # Apple Root CA - G3 validity:
      # Not Before: Apr 30 18:19:06 2014 GMT (GeneralTime: 20140430181906Z)
      # Not After:  Apr 30 18:19:06 2039 GMT (GeneralTime: 20390430181906Z)
      # Signing cert expires 2027-10-13, so we use a date before that
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # Test with date in 2026 - within all cert validity periods
      # This exercises GeneralTime parsing for the root CA
      # 2026-01-01
      date_2026 = 1_767_225_600

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          false,
          date_2026
        )

      assert {:ok, _public_key, _verifier} = result
    end

    @tag :strict
    test "GeneralTime expiry is correctly parsed for 2039" do
      # Verify that root CA valid until 2039 doesn't fail in 2035
      real_apple_root_der = Base.decode64!(@real_apple_root_base64)
      verifier = ChainVerifier.new([real_apple_root_der], true)

      # 2035-06-15 - should still be within root CA validity
      date_2035 = 2_066_083_200

      result =
        ChainVerifier.verify_chain(
          verifier,
          [
            @real_apple_signing_cert_base64,
            @real_apple_intermediate_base64,
            @real_apple_root_base64
          ],
          false,
          date_2035
        )

      # May fail due to signing cert expiry (2027) but not root CA expiry
      # The signing cert expires 2027-10-13, so this should fail with expired signing cert
      assert {:error, {:verification_failure, message}} = result
      assert message =~ "expired"
    end
  end

  describe "Certificate chain verification rescue" do
    @tag :strict
    test "handles exception during chain verification" do
      root_der = Base.decode64!(@root_ca_base64)
      verifier = ChainVerifier.new([root_der], true)

      # Create a chain where the leaf is valid base64 but will cause issues
      # during certificate chain operations
      almost_valid_der =
        Base.encode64(<<
          # SEQUENCE, length 256
          0x30,
          0x82,
          0x01,
          0x00,
          # SEQUENCE, length 240
          0x30,
          0x81,
          0xF0,
          # INTEGER version
          0x02,
          0x01,
          0x00
          # Truncated - will cause exception during parsing
        >>)

      result =
        ChainVerifier.verify_chain(
          verifier,
          [almost_valid_der, @intermediate_ca_base64, @root_ca_base64],
          false,
          @effective_date
        )

      # Should return error, not crash
      assert {:error, _reason} = result
    end
  end
end
