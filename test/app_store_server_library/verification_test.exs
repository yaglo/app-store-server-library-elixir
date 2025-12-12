defmodule AppStoreServerLibrary.VerificationTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Verification.SignedDataVerifier

  describe "SignedDataVerifier" do
    test "creates verifier with valid parameters" do
      verifier = %SignedDataVerifier{
        root_certificates: ["cert1", "cert2"],
        bundle_id: "com.test.app",
        environment: :sandbox,
        app_apple_id: "123456789"
      }

      assert verifier.root_certificates == ["cert1", "cert2"]
      assert verifier.bundle_id == "com.test.app"
      assert verifier.environment == :sandbox
      assert verifier.app_apple_id == "123456789"
    end

    test "verifies environment correctly" do
      verifier = %SignedDataVerifier{
        root_certificates: [],
        bundle_id: "com.test.app",
        environment: :sandbox,
        app_apple_id: "123456789"
      }

      # Test environment verification
      assert :ok = SignedDataVerifier.verify_environment(verifier, :sandbox)

      assert {:error, {:invalid_environment, _}} =
               SignedDataVerifier.verify_environment(verifier, :production)
    end

    test "verifies bundle ID correctly" do
      verifier = %SignedDataVerifier{
        root_certificates: [],
        bundle_id: "com.test.app",
        environment: :sandbox,
        app_apple_id: "123456789"
      }

      # Test bundle ID verification
      assert :ok = SignedDataVerifier.verify_bundle_id(verifier, "com.test.app")

      assert {:error, {:invalid_app_identifier, _}} =
               SignedDataVerifier.verify_bundle_id(verifier, "com.other.app")
    end
  end
end
