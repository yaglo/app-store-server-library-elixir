defmodule AppStoreServerLibrary.JWSSignatureCreatorTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Signature.{
    AdvancedCommerceAPIInAppSignatureCreator,
    IntroductoryOfferEligibilitySignatureCreator,
    PromotionalOfferV2SignatureCreator
  }

  alias AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppRequest

  defmodule TestInAppRequest do
    @moduledoc false
    defstruct [:test_value]

    @behaviour AdvancedCommerceAPIInAppRequest

    @impl true
    def to_map(%__MODULE__{test_value: value}) do
      %{"test_value" => value}
    end
  end

  describe "PromotionalOfferV2SignatureCreator" do
    test "creates signature with all parameters" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        PromotionalOfferV2SignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      {:ok, signature} =
        PromotionalOfferV2SignatureCreator.create_signature(
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

      creator =
        PromotionalOfferV2SignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      {:ok, signature} =
        PromotionalOfferV2SignatureCreator.create_signature(
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

    test "raises error when offer_identifier is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        PromotionalOfferV2SignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        PromotionalOfferV2SignatureCreator.create_signature(
          creator,
          "productId",
          nil,
          "transactionId"
        )
      end
    end

    test "raises error when product_id is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        PromotionalOfferV2SignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        PromotionalOfferV2SignatureCreator.create_signature(
          creator,
          nil,
          "offerIdentifier",
          "transactionId"
        )
      end
    end
  end

  describe "IntroductoryOfferEligibilitySignatureCreator" do
    test "creates signature with all parameters" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        IntroductoryOfferEligibilitySignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      {:ok, signature} =
        IntroductoryOfferEligibilitySignatureCreator.create_signature(
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

    test "raises error when transaction_id is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        IntroductoryOfferEligibilitySignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        IntroductoryOfferEligibilitySignatureCreator.create_signature(
          creator,
          "productId",
          true,
          nil
        )
      end
    end

    test "raises error when allow_introductory_offer is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        IntroductoryOfferEligibilitySignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        IntroductoryOfferEligibilitySignatureCreator.create_signature(
          creator,
          "productId",
          nil,
          "transactionId"
        )
      end
    end

    test "raises error when product_id is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        IntroductoryOfferEligibilitySignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        IntroductoryOfferEligibilitySignatureCreator.create_signature(
          creator,
          nil,
          true,
          "transactionId"
        )
      end
    end
  end

  describe "AdvancedCommerceAPIInAppSignatureCreator" do
    test "creates signature with request" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        AdvancedCommerceAPIInAppSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      request = %TestInAppRequest{test_value: "testValue"}

      {:ok, signature} =
        AdvancedCommerceAPIInAppSignatureCreator.create_signature(creator, request)

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
      request_data = Base.url_decode64!(payload["request"], padding: false) |> Jason.decode!()
      assert request_data["test_value"] == "testValue"
    end

    test "raises error when request is missing" do
      signing_key = File.read!("test/resources/certs/testSigningKey.p8")

      creator =
        AdvancedCommerceAPIInAppSignatureCreator.new(
          signing_key: signing_key,
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "bundleId"
        )

      assert_raise ArgumentError, fn ->
        AdvancedCommerceAPIInAppSignatureCreator.create_signature(creator, nil)
      end
    end
  end
end
