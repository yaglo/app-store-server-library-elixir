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

  describe "malformed signed data" do
    setup do
      opts = [root_certificates: [<<1>>], environment: :sandbox, bundle_id: "com.example"]
      {:ok, offline} = SignedDataVerifier.new(opts)
      {:ok, online} = SignedDataVerifier.new([enable_online_checks: true] ++ opts)
      {:ok, verifiers: [offline, online]}
    end

    test "returns an error tuple instead of raising", %{verifiers: verifiers} do
      es256 = ~s({"alg":"ES256","x5c":["AAAA","AAAA","AAAA"]})

      inputs = [
        "garbage",
        "",
        "a.b.c",
        123,
        nil,
        jws("[1]", "{}"),
        jws("not json", "{}"),
        jws(~s("string"), "{}"),
        jws(es256, ~s("string")),
        jws(es256, "[]"),
        jws(es256, "not json"),
        jws(~s({"alg":"ES256","x5c":[1,2,3]}), "{}"),
        jws(~s({"alg":"ES256","x5c":"abc"}), "{}"),
        jws(~s({"alg":"ES256","x5c":{"a":1}}), "{}"),
        jws(~s({"alg":"ES256","x5c":["AAAA",null,"AAAA"]}), "{}"),
        jws(es256, ~s({"signedDate":"soon"}))
      ]

      for verifier <- verifiers, input <- inputs do
        assert {:error, {status, message}} =
                 SignedDataVerifier.verify_and_decode_signed_transaction(verifier, input)

        assert is_atom(status)
        assert is_binary(message)
      end
    end
  end

  defp jws(header, payload) do
    Enum.map_join([header, payload, "signature"], ".", &Base.url_encode64(&1, padding: false))
  end
end
