defmodule AppStoreServerLibrary.DecodedPayloadsTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.{
    AutoRenewStatus,
    Environment,
    ExpirationIntent,
    InAppOwnershipType,
    OfferDiscountType,
    OfferType,
    PriceIncreaseStatus,
    SubtypeV2,
    TransactionReason
  }

  # These tests verify that JSON fixture files used for testing have the expected structure.
  # They do NOT test library functionality - see payload_verification_test.exs for that.
  describe "JSON fixture file structure" do
    test "appTransaction.json has expected fields" do
      json_content = File.read!("test/resources/models/appTransaction.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "receiptType")
      assert Map.has_key?(data, "appAppleId")
      assert Map.has_key?(data, "bundleId")
      assert Map.has_key?(data, "applicationVersion")
      assert Map.has_key?(data, "deviceVerification")
      assert Map.has_key?(data, "appTransactionId")
    end

    test "signedTransaction.json has expected fields" do
      json_content = File.read!("test/resources/models/signedTransaction.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "originalTransactionId")
      assert Map.has_key?(data, "transactionId")
      assert Map.has_key?(data, "bundleId")
      assert Map.has_key?(data, "productId")
      assert Map.has_key?(data, "type")
      assert Map.has_key?(data, "inAppOwnershipType")
      assert Map.has_key?(data, "environment")
    end

    test "signedRenewalInfo.json has expected fields" do
      json_content = File.read!("test/resources/models/signedRenewalInfo.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "expirationIntent")
      assert Map.has_key?(data, "originalTransactionId")
      assert Map.has_key?(data, "autoRenewProductId")
      assert Map.has_key?(data, "autoRenewStatus")
      assert Map.has_key?(data, "environment")
    end

    test "signedNotification.json has expected fields" do
      json_content = File.read!("test/resources/models/signedNotification.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "notificationType")
      assert Map.has_key?(data, "subtype")
      assert Map.has_key?(data, "notificationUUID")
      assert Map.has_key?(data, "signedDate")
      assert Map.has_key?(data, "data")
    end

    test "signedConsumptionRequestNotification.json has expected fields" do
      json_content = File.read!("test/resources/models/signedConsumptionRequestNotification.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "notificationType")
      assert Map.has_key?(data, "notificationUUID")
      assert Map.has_key?(data, "signedDate")
      assert Map.has_key?(data, "data")
    end

    test "signedSummaryNotification.json has expected fields" do
      json_content = File.read!("test/resources/models/signedSummaryNotification.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "notificationType")
      assert Map.has_key?(data, "subtype")
      assert Map.has_key?(data, "notificationUUID")
      assert Map.has_key?(data, "signedDate")
      assert Map.has_key?(data, "summary")
    end

    test "signedExternalPurchaseTokenNotification.json has expected fields" do
      json_content =
        File.read!("test/resources/models/signedExternalPurchaseTokenNotification.json")

      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "notificationType")
      assert Map.has_key?(data, "subtype")
      assert Map.has_key?(data, "notificationUUID")
      assert Map.has_key?(data, "signedDate")
      assert Map.has_key?(data, "externalPurchaseToken")
    end

    test "signedExternalPurchaseTokenSandboxNotification.json has expected fields" do
      json_content =
        File.read!("test/resources/models/signedExternalPurchaseTokenSandboxNotification.json")

      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "notificationType")
      assert Map.has_key?(data, "subtype")
      assert Map.has_key?(data, "notificationUUID")
      assert Map.has_key?(data, "signedDate")
      assert Map.has_key?(data, "externalPurchaseToken")
    end

    test "decodedRealtimeRequest.json has expected fields" do
      json_content = File.read!("test/resources/models/decodedRealtimeRequest.json")
      data = Jason.decode!(json_content)

      assert Map.has_key?(data, "originalTransactionId")
      assert Map.has_key?(data, "appAppleId")
      assert Map.has_key?(data, "productId")
      assert Map.has_key?(data, "userLocale")
      assert Map.has_key?(data, "requestIdentifier")
      assert Map.has_key?(data, "environment")
    end
  end

  describe "enum conversions" do
    test "converts environment strings correctly" do
      assert Environment.from_string("LocalTesting") == :local_testing
      assert Environment.from_string("Sandbox") == :sandbox
      assert Environment.from_string("Production") == :production
      assert Environment.to_string(:local_testing) == "LocalTesting"
      assert Environment.to_string(:sandbox) == "Sandbox"
      assert Environment.to_string(:production) == "Production"
    end

    test "converts auto renew status integers correctly" do
      assert AutoRenewStatus.from_integer(1) == :on
      assert AutoRenewStatus.from_integer(0) == :off
      assert AutoRenewStatus.from_integer(99) == 99
      assert AutoRenewStatus.to_integer(:off) == 0
      assert AutoRenewStatus.to_integer(:on) == 1
    end

    test "converts expiration intent integers correctly" do
      assert ExpirationIntent.from_integer(1) == :customer_cancelled
      assert ExpirationIntent.from_integer(2) == :billing_error
      assert ExpirationIntent.from_integer(3) == :customer_did_not_consent_to_price_increase
      assert ExpirationIntent.from_integer(4) == :product_not_available
      assert ExpirationIntent.from_integer(5) == :other
      assert ExpirationIntent.from_integer(99) == 99
    end

    test "converts in-app ownership type strings correctly" do
      assert InAppOwnershipType.from_string("PURCHASED") == :purchased
      assert InAppOwnershipType.from_string("FAMILY_SHARED") == :family_shared
      assert InAppOwnershipType.from_string("UNKNOWN") == "UNKNOWN"
      assert InAppOwnershipType.to_string(:purchased) == "PURCHASED"
      assert InAppOwnershipType.to_string(:family_shared) == "FAMILY_SHARED"
    end

    test "converts offer type integers correctly" do
      assert OfferType.from_integer(1) == :introductory_offer
      assert OfferType.from_integer(2) == :promotional_offer
      assert OfferType.from_integer(3) == :offer_code
      assert OfferType.from_integer(99) == 99
      assert OfferType.to_integer(:introductory_offer) == 1
      assert OfferType.to_integer(:promotional_offer) == 2
      assert OfferType.to_integer(:offer_code) == 3
    end

    test "converts transaction reason strings correctly" do
      assert TransactionReason.from_string("PURCHASE") == :purchase
      assert TransactionReason.from_string("RENEWAL") == :renewal
      assert TransactionReason.from_string("UNKNOWN") == "UNKNOWN"
      assert TransactionReason.to_string(:purchase) == "PURCHASE"
      assert TransactionReason.to_string(:renewal) == "RENEWAL"
    end

    test "converts offer discount type strings correctly" do
      assert OfferDiscountType.from_string("FREE_TRIAL") == :free_trial
      assert OfferDiscountType.from_string("PAY_AS_YOU_GO") == :pay_as_you_go
      assert OfferDiscountType.from_string("PAY_UP_FRONT") == :pay_up_front
      assert OfferDiscountType.from_string("UNKNOWN") == "UNKNOWN"
      assert OfferDiscountType.to_string(:free_trial) == "FREE_TRIAL"
      assert OfferDiscountType.to_string(:pay_as_you_go) == "PAY_AS_YOU_GO"
      assert OfferDiscountType.to_string(:pay_up_front) == "PAY_UP_FRONT"
    end

    test "converts price increase status integers correctly" do
      assert PriceIncreaseStatus.from_integer(0) == :customer_has_not_responded

      assert PriceIncreaseStatus.from_integer(1) ==
               :customer_consented_or_was_notified_without_needing_consent

      assert PriceIncreaseStatus.from_integer(99) == 99
      assert PriceIncreaseStatus.to_integer(:customer_has_not_responded) == 0

      assert PriceIncreaseStatus.to_integer(
               :customer_consented_or_was_notified_without_needing_consent
             ) == 1
    end

    test "converts subtype strings correctly" do
      # from_string
      assert SubtypeV2.from_string("ACCEPTED") == :accepted
      assert SubtypeV2.from_string("AUTO_RENEW_DISABLED") == :auto_renew_disabled
      assert SubtypeV2.from_string("AUTO_RENEW_ENABLED") == :auto_renew_enabled
      assert SubtypeV2.from_string("BILLING_RECOVERY") == :billing_recovery
      assert SubtypeV2.from_string("BILLING_RETRY") == :billing_retry
      assert SubtypeV2.from_string("DOWNGRADE") == :downgrade
      assert SubtypeV2.from_string("GRACE_PERIOD") == :grace_period
      assert SubtypeV2.from_string("INITIAL_BUY") == :initial_buy
      assert SubtypeV2.from_string("PENDING") == :pending
      assert SubtypeV2.from_string("PRICE_INCREASE") == :price_increase
      assert SubtypeV2.from_string("RESUBSCRIBE") == :resubscribe
      assert SubtypeV2.from_string("SUMMARY") == :summary
      assert SubtypeV2.from_string("UPGRADE") == :upgrade
      assert SubtypeV2.from_string("VOLUNTARY") == :voluntary
      assert SubtypeV2.from_string("UNKNOWN") == "UNKNOWN"

      # to_string
      assert SubtypeV2.to_string(:accepted) == "ACCEPTED"
      assert SubtypeV2.to_string(:auto_renew_disabled) == "AUTO_RENEW_DISABLED"
      assert SubtypeV2.to_string(:billing_recovery) == "BILLING_RECOVERY"
      assert SubtypeV2.to_string(:downgrade) == "DOWNGRADE"
      assert SubtypeV2.to_string(:initial_buy) == "INITIAL_BUY"
      assert SubtypeV2.to_string(:pending) == "PENDING"
      assert SubtypeV2.to_string(:summary) == "SUMMARY"
      assert SubtypeV2.to_string(:upgrade) == "UPGRADE"
    end
  end
end
