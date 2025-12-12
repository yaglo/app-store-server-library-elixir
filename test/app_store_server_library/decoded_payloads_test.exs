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
    Subtype,
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

    test "converts auto renew status strings correctly" do
      assert AutoRenewStatus.from_integer(1) == {:ok, :on}
      assert AutoRenewStatus.from_integer(0) == {:ok, :off}
      assert AutoRenewStatus.to_integer(:off) == 0
      assert AutoRenewStatus.to_integer(:on) == 1
    end

    test "converts expiration intent strings correctly" do
      assert ExpirationIntent.from_integer(1) == {:ok, :customer_cancelled}
      assert ExpirationIntent.from_integer(2) == {:ok, :billing_error}

      assert ExpirationIntent.from_integer(3) ==
               {:ok, :customer_did_not_consent_to_price_increase}

      assert ExpirationIntent.from_integer(4) == {:ok, :product_not_available}
      assert ExpirationIntent.from_integer(5) == {:ok, :other}
    end

    test "converts in-app ownership type strings correctly" do
      assert InAppOwnershipType.from_string("PURCHASED") == {:ok, :purchased}
      assert InAppOwnershipType.from_string("FAMILY_SHARED") == {:ok, :family_shared}
      assert InAppOwnershipType.to_string(:purchased) == "PURCHASED"
      assert InAppOwnershipType.to_string(:family_shared) == "FAMILY_SHARED"
    end

    test "converts offer type strings correctly" do
      assert OfferType.from_integer(1) == {:ok, :introductory_offer}
      assert OfferType.from_integer(2) == {:ok, :promotional_offer}
      assert OfferType.from_integer(3) == {:ok, :offer_code}
      assert OfferType.to_integer(:introductory_offer) == 1
      assert OfferType.to_integer(:promotional_offer) == 2
      assert OfferType.to_integer(:offer_code) == 3
    end

    test "converts transaction reason strings correctly" do
      assert TransactionReason.from_string("PURCHASE") == {:ok, :purchase}
      assert TransactionReason.from_string("RENEWAL") == {:ok, :renewal}
      assert TransactionReason.from_string("EXPIRED") == {:error, :invalid_transaction_reason}
      assert TransactionReason.to_string(:purchase) == "PURCHASE"
      assert TransactionReason.to_string(:renewal) == "RENEWAL"
    end

    test "converts offer discount type strings correctly" do
      assert OfferDiscountType.from_string("FREE_TRIAL") == {:ok, :free_trial}
      assert OfferDiscountType.from_string("PAY_AS_YOU_GO") == {:ok, :pay_as_you_go}
      assert OfferDiscountType.from_string("PAY_UP_FRONT") == {:ok, :pay_up_front}
      assert OfferDiscountType.to_string(:free_trial) == "FREE_TRIAL"
      assert OfferDiscountType.to_string(:pay_as_you_go) == "PAY_AS_YOU_GO"
      assert OfferDiscountType.to_string(:pay_up_front) == "PAY_UP_FRONT"
    end

    test "converts price increase status strings correctly" do
      assert PriceIncreaseStatus.from_integer(0) == {:ok, :customer_has_not_responded}

      assert PriceIncreaseStatus.from_integer(1) ==
               {:ok, :customer_consented_or_was_notified_without_needing_consent}

      assert PriceIncreaseStatus.to_integer(:customer_has_not_responded) == 0

      assert PriceIncreaseStatus.to_integer(
               :customer_consented_or_was_notified_without_needing_consent
             ) == 1
    end

    test "converts subtype strings correctly" do
      assert Subtype.from_string("SUBSCRIBED") == :subscribed
      assert Subtype.from_string("DID_NOT_RENEW") == :did_not_renew
      assert Subtype.from_string("EXPIRED") == :expired
      assert Subtype.from_string("IN_GRACE_PERIOD") == :in_grace_period
      assert Subtype.from_string("PRICE_INCREASE") == :price_increase
      assert Subtype.from_string("GRACE_PERIOD_EXPIRED") == :grace_period_expired
      assert Subtype.from_string("PENDING") == :pending
      assert Subtype.from_string("ACCEPTED") == :accepted
      assert Subtype.from_string("REVOKED") == :revoked
      assert Subtype.from_string("SUBSCRIPTION_EXTENDED") == :subscription_extended
      assert Subtype.from_string("SUMMARY") == :summary
      assert Subtype.from_string("UNREPORTED") == :unreported
      assert Subtype.from_string("INITIAL_BUY") == :initial_buy
      assert Subtype.to_string(:subscribed) == "SUBSCRIBED"
      assert Subtype.to_string(:did_not_renew) == "DID_NOT_RENEW"
      assert Subtype.to_string(:expired) == "EXPIRED"
      assert Subtype.to_string(:in_grace_period) == "IN_GRACE_PERIOD"
      assert Subtype.to_string(:price_increase) == "PRICE_INCREASE"
      assert Subtype.to_string(:grace_period_expired) == "GRACE_PERIOD_EXPIRED"
      assert Subtype.to_string(:pending) == "PENDING"
      assert Subtype.to_string(:accepted) == "ACCEPTED"
      assert Subtype.to_string(:revoked) == "REVOKED"
      assert Subtype.to_string(:subscription_extended) == "SUBSCRIPTION_EXTENDED"
      assert Subtype.to_string(:summary) == "SUMMARY"
      assert Subtype.to_string(:unreported) == "UNREPORTED"
      assert Subtype.to_string(:initial_buy) == "INITIAL_BUY"
    end
  end
end
