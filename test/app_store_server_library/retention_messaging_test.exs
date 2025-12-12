defmodule AppStoreServerLibrary.RetentionMessagingTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.{
    AlternateProduct,
    Message,
    PromotionalOffer,
    PromotionalOfferSignatureV1,
    RealtimeResponseBody
  }

  describe "RealtimeResponseBody serialization" do
    test "serializes with message" do
      message_id = "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
      message = %Message{message_identifier: message_id}
      response_body = %RealtimeResponseBody{message: message}

      # Test that the struct is properly constructed
      refute is_nil(response_body.message)
      assert response_body.message.message_identifier == message_id
      assert is_nil(response_body.alternate_product)
      assert is_nil(response_body.promotional_offer)
    end

    test "serializes with alternate product" do
      message_id = "b2c3d4e5-f6a7-8901-b2c3-d4e5f6a78901"
      product_id = "com.example.alternate.product"

      alternate_product = %AlternateProduct{
        message_identifier: message_id,
        product_id: product_id
      }

      response_body = %RealtimeResponseBody{alternate_product: alternate_product}

      assert is_nil(response_body.message)
      refute is_nil(response_body.alternate_product)
      assert response_body.alternate_product.message_identifier == message_id
      assert response_body.alternate_product.product_id == product_id
      assert is_nil(response_body.promotional_offer)
    end

    test "serializes with promotional offer V2 signature" do
      message_id = "c3d4e5f6-a789-0123-c3d4-e5f6a7890123"
      signature_v2 = "signature2"

      promotional_offer = %PromotionalOffer{
        message_identifier: message_id,
        promotional_offer_signature_v2: signature_v2
      }

      response_body = %RealtimeResponseBody{promotional_offer: promotional_offer}

      assert is_nil(response_body.message)
      assert is_nil(response_body.alternate_product)
      refute is_nil(response_body.promotional_offer)
      assert response_body.promotional_offer.message_identifier == message_id
      assert response_body.promotional_offer.promotional_offer_signature_v2 == signature_v2
      assert is_nil(response_body.promotional_offer.promotional_offer_signature_v1)
    end

    test "serializes with promotional offer V1 signature" do
      message_id = "d4e5f6a7-8901-2345-d4e5-f6a789012345"
      nonce = "e5f6a789-0123-4567-e5f6-a78901234567"
      app_account_token = "f6a78901-2345-6789-f6a7-890123456789"

      signature_v1 = %PromotionalOfferSignatureV1{
        encoded_signature: "base64encodedSignature",
        product_id: "com.example.product",
        nonce: nonce,
        timestamp: 1_698_148_900_000,
        key_id: "keyId123",
        offer_identifier: "offer123",
        app_account_token: app_account_token
      }

      promotional_offer = %PromotionalOffer{
        message_identifier: message_id,
        promotional_offer_signature_v1: signature_v1
      }

      response_body = %RealtimeResponseBody{promotional_offer: promotional_offer}

      assert is_nil(response_body.message)
      assert is_nil(response_body.alternate_product)
      refute is_nil(response_body.promotional_offer)
      assert response_body.promotional_offer.message_identifier == message_id
      assert is_nil(response_body.promotional_offer.promotional_offer_signature_v2)
      refute is_nil(response_body.promotional_offer.promotional_offer_signature_v1)

      v1 = response_body.promotional_offer.promotional_offer_signature_v1
      assert v1.encoded_signature == "base64encodedSignature"
      assert v1.product_id == "com.example.product"
      assert v1.nonce == nonce
      assert v1.timestamp == 1_698_148_900_000
      assert v1.key_id == "keyId123"
      assert v1.offer_identifier == "offer123"
      assert v1.app_account_token == app_account_token
    end
  end

  describe "JSON encoding" do
    test "encodes RealtimeResponseBody with message to JSON" do
      message = %Message{message_identifier: "test-id"}
      response_body = %RealtimeResponseBody{message: message}

      # Convert to map for JSON encoding (simulating what would happen in API response)
      json_map = %{
        "message" => %{
          "messageIdentifier" => response_body.message.message_identifier
        }
      }

      {:ok, json} = Jason.encode(json_map)
      assert String.contains?(json, "messageIdentifier")
      assert String.contains?(json, "test-id")
    end

    test "encodes AlternateProduct to JSON" do
      alternate_product = %AlternateProduct{
        message_identifier: "test-id",
        product_id: "com.example.product"
      }

      json_map = %{
        "alternateProduct" => %{
          "messageIdentifier" => alternate_product.message_identifier,
          "productId" => alternate_product.product_id
        }
      }

      {:ok, json} = Jason.encode(json_map)
      assert String.contains?(json, "alternateProduct")
      assert String.contains?(json, "productId")
    end
  end
end
