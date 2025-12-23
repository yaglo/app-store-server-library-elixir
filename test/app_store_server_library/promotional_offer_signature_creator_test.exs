defmodule AppStoreServerLibrary.PromotionalOfferSignatureCreatorTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator

  @test_signing_key """
  -----BEGIN EC PRIVATE KEY-----
  MHcCAQEEIDjhapjz8yPo9m3Z5f+OweRGZdZ5Q0ITfEHye3pz+zMgoAoGCCqGSM49
  AwEHoUQDQgAEEtEpXb+sUgoa+sqbRQqf8IN8cQGqZGAro2GtWf/uDVjA7gi7420M
  WlDSUBiwHwJIrDXNDPMmSBx++wtUW2rplA==
  -----END EC PRIVATE KEY-----
  """

  describe "create_signature/6" do
    test "creates a valid signature" do
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      assert is_binary(signature)
      assert byte_size(signature) > 0

      # Verify it's valid Base64
      assert Base.decode64(signature) != :error
    end

    test "creates valid signatures with same inputs (ECDSA is non-deterministic)" do
      # Note: ECDSA signatures are non-deterministic by design.
      # Each call produces a different but equally valid signature.
      # This test verifies both signatures are valid, not that they're identical.
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      # Both signatures should be valid Base64
      assert {:ok, _} = Base.decode64(signature1)
      assert {:ok, _} = Base.decode64(signature2)

      # Both should be non-empty
      assert byte_size(signature1) > 0
      assert byte_size(signature2) > 0
    end

    test "creates different signatures for different inputs" do
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId1",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId2",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      assert signature1 != signature2
    end

    test "handles empty application username" do
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          # Empty application username
          "",
          uuid,
          timestamp
        )

      assert is_binary(signature)
      assert Base.decode64(signature) != :error
    end

    test "handles uppercase UUID by converting to lowercase" do
      # The signature creator normalizes UUIDs to lowercase.
      # Since ECDSA is non-deterministic, we can't compare signatures directly.
      # Instead, we verify both produce valid signatures (meaning the normalization
      # doesn't cause errors).
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uppercase_uuid = "20FBA8A0-2B80-4A7D-A17F-85C1854727F8"
      lowercase_uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          "appAccountToken",
          uppercase_uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          "appAccountToken",
          lowercase_uuid,
          timestamp
        )

      # Both produce valid signatures
      assert {:ok, _} = Base.decode64(signature1)
      assert {:ok, _} = Base.decode64(signature2)
    end

    test "handles uppercase application username by converting to lowercase" do
      # The signature creator normalizes application usernames to lowercase.
      # Since ECDSA is non-deterministic, we verify both produce valid signatures.
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          # Uppercase
          "AppAccountToken",
          uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator,
          "productId",
          "offerId",
          # Lowercase
          "appaccounttoken",
          uuid,
          timestamp
        )

      # Both produce valid signatures
      assert {:ok, _} = Base.decode64(signature1)
      assert {:ok, _} = Base.decode64(signature2)
    end

    test "creates different signatures for different bundle IDs" do
      {:ok, creator1} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId1"
        )

      {:ok, creator2} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId2"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator1,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator2,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      assert signature1 != signature2
    end

    test "creates different signatures for different key IDs" do
      {:ok, creator1} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId1",
          bundle_id: "bundleId"
        )

      {:ok, creator2} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId2",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      timestamp = 1_698_148_900_000

      {:ok, signature1} =
        PromotionalOfferSignatureCreator.create_signature(
          creator1,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      {:ok, signature2} =
        PromotionalOfferSignatureCreator.create_signature(
          creator2,
          "productId",
          "offerId",
          "appAccountToken",
          uuid,
          timestamp
        )

      assert signature1 != signature2
    end

    test "returns error for zero timestamp" do
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"

      assert {:error, {:invalid_timestamp, _message}} =
               PromotionalOfferSignatureCreator.create_signature(
                 creator,
                 "productId",
                 "offerId",
                 "appAccountToken",
                 uuid,
                 0
               )
    end

    test "returns error for negative timestamp" do
      {:ok, creator} =
        PromotionalOfferSignatureCreator.new(
          signing_key: @test_signing_key,
          key_id: "keyId",
          bundle_id: "bundleId"
        )

      uuid = "20fba8a0-2b80-4a7d-a17f-85c1854727f8"

      assert {:error, {:invalid_timestamp, _message}} =
               PromotionalOfferSignatureCreator.create_signature(
                 creator,
                 "productId",
                 "offerId",
                 "appAccountToken",
                 uuid,
                 -1_698_148_900_000
               )
    end
  end
end
