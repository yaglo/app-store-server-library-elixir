defmodule AppStoreServerLibrary.JWSSignatureCreatorTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Signature.JWSSignatureCreator

  describe "new/1" do
    test "creates creator with valid PEM" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      assert {:ok, creator} =
               JWSSignatureCreator.new(
                 signing_key: signing_key,
                 key_id: "keyId",
                 issuer_id: "issuerId",
                 bundle_id: "bundleId"
               )

      assert creator.signing_key == signing_key
      assert creator.key_id == "keyId"
      assert creator.issuer_id == "issuerId"
      assert creator.bundle_id == "bundleId"
    end

    test "returns error with invalid PEM" do
      assert {:error, :invalid_pem} =
               JWSSignatureCreator.new(
                 signing_key: "not a valid PEM",
                 key_id: "keyId",
                 issuer_id: "issuerId",
                 bundle_id: "bundleId"
               )
    end

    test "returns error with empty PEM" do
      assert {:error, :invalid_pem} =
               JWSSignatureCreator.new(
                 signing_key: "",
                 key_id: "keyId",
                 issuer_id: "issuerId",
                 bundle_id: "bundleId"
               )
    end
  end

  describe "create_promotional_offer_v2_signature/4" do
    test "creates signature with all parameters" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      signature =
        JWSSignatureCreator.create_promotional_offer_v2_signature(
          creator,
          "productId",
          "offerIdentifier",
          "transactionId"
        )

      assert is_binary(signature)

      # Verify JWT structure
      [header_b64, payload_b64, _signature_b64] = String.split(signature, ".")

      # Decode and verify header
      header = Jason.decode!(Base.url_decode64!(header_b64, padding: false))
      assert header["typ"] == "JWT"
      assert header["alg"] == "ES256"
      assert header["kid"] == "keyId"

      # Decode and verify payload
      payload = Jason.decode!(Base.url_decode64!(payload_b64, padding: false))
      assert payload["iss"] == "issuerId"
      assert is_integer(payload["iat"])
      refute Map.has_key?(payload, "exp")
      assert payload["aud"] == "promotional-offer"
      assert payload["bid"] == "bundleId"
      assert is_binary(payload["nonce"])
      assert payload["productId"] == "productId"
      assert payload["offerIdentifier"] == "offerIdentifier"
      assert payload["transactionId"] == "transactionId"
    end

    test "creates signature without transaction_id" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      signature =
        JWSSignatureCreator.create_promotional_offer_v2_signature(
          creator,
          "productId",
          "offerIdentifier",
          nil
        )

      payload =
        signature
        |> String.split(".")
        |> Enum.at(1)
        |> Base.url_decode64!(padding: false)
        |> Jason.decode!()

      refute Map.has_key?(payload, "transactionId")
    end

    test "raises FunctionClauseError when offer_identifier is not a string" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_promotional_offer_v2_signature(
          creator,
          "productId",
          nil,
          "transactionId"
        )
      end
    end

    test "raises FunctionClauseError when product_id is not a string" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_promotional_offer_v2_signature(
          creator,
          nil,
          "offerIdentifier",
          "transactionId"
        )
      end
    end
  end

  describe "create_introductory_offer_eligibility_signature/4" do
    test "creates signature with all parameters" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      signature =
        JWSSignatureCreator.create_introductory_offer_eligibility_signature(
          creator,
          "productId",
          true,
          "transactionId"
        )

      assert is_binary(signature)

      # Verify JWT structure
      [header_b64, payload_b64, _signature_b64] = String.split(signature, ".")

      # Decode and verify header
      header = Jason.decode!(Base.url_decode64!(header_b64, padding: false))
      assert header["typ"] == "JWT"
      assert header["alg"] == "ES256"
      assert header["kid"] == "keyId"

      # Decode and verify payload
      payload = Jason.decode!(Base.url_decode64!(payload_b64, padding: false))
      assert payload["iss"] == "issuerId"
      assert is_integer(payload["iat"])
      refute Map.has_key?(payload, "exp")
      assert payload["aud"] == "introductory-offer-eligibility"
      assert payload["bid"] == "bundleId"
      assert is_binary(payload["nonce"])
      assert payload["productId"] == "productId"
      assert payload["allowIntroductoryOffer"] == true
      assert payload["transactionId"] == "transactionId"
    end

    test "raises FunctionClauseError when transaction_id is not a string" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_introductory_offer_eligibility_signature(
          creator,
          "productId",
          true,
          nil
        )
      end
    end

    test "raises FunctionClauseError when allow_introductory_offer is not a boolean" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_introductory_offer_eligibility_signature(
          creator,
          "productId",
          nil,
          "transactionId"
        )
      end
    end

    test "raises FunctionClauseError when product_id is not a string" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_introductory_offer_eligibility_signature(
          creator,
          nil,
          true,
          "transactionId"
        )
      end
    end
  end

  describe "create_advanced_commerce_signature/2" do
    test "creates signature from map" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      request_map = %{"test_value" => "testValue"}

      signature = JWSSignatureCreator.create_advanced_commerce_signature(creator, request_map)

      assert is_binary(signature)

      # Verify JWT structure
      [header_b64, payload_b64, _signature_b64] = String.split(signature, ".")

      # Decode and verify header
      header = Jason.decode!(Base.url_decode64!(header_b64, padding: false))
      assert header["typ"] == "JWT"
      assert header["alg"] == "ES256"
      assert header["kid"] == "keyId"

      # Decode and verify payload
      payload = Jason.decode!(Base.url_decode64!(payload_b64, padding: false))
      assert payload["iss"] == "issuerId"
      assert is_integer(payload["iat"])
      refute Map.has_key?(payload, "exp")
      assert payload["aud"] == "advanced-commerce-api"
      assert payload["bid"] == "bundleId"
      assert is_binary(payload["nonce"])

      # Verify request is properly encoded
      assert Map.has_key?(payload, "request")
      request_data = Base.decode64!(payload["request"]) |> Jason.decode!()
      assert request_data["test_value"] == "testValue"
    end

    test "raises FunctionClauseError when request is not a map" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      {:ok, creator} =
        JWSSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise FunctionClauseError, fn ->
        JWSSignatureCreator.create_advanced_commerce_signature(creator, nil)
      end
    end
  end
end
