defmodule AppStoreServerLibrary.ModelsTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.{
    AutoRenewStatus,
    Environment,
    ExpirationIntent,
    InAppOwnershipType,
    NotificationTypeV2,
    OfferDiscountType,
    OfferType,
    PriceIncreaseStatus,
    RevocationReason,
    Status,
    SubtypeV2,
    TransactionReason
  }

  describe "Environment" do
    test "from_string converts known environments" do
      assert Environment.from_string("Sandbox") == :sandbox
      assert Environment.from_string("Production") == :production
      assert Environment.from_string("Xcode") == :xcode
      assert Environment.from_string("LocalTesting") == :local_testing
    end

    test "from_string returns original for unknown" do
      assert Environment.from_string("Unknown") == "Unknown"
    end

    test "to_string converts atoms to strings" do
      assert Environment.to_string(:sandbox) == "Sandbox"
      assert Environment.to_string(:production) == "Production"
      assert Environment.to_string(:xcode) == "Xcode"
      assert Environment.to_string(:local_testing) == "LocalTesting"
    end

    test "to_string passes through unknown strings" do
      assert Environment.to_string("Unknown") == "Unknown"
    end
  end

  describe "NotificationTypeV2" do
    test "from_string converts known types" do
      assert NotificationTypeV2.from_string("CONSUMPTION_REQUEST") == :consumption_request
      assert NotificationTypeV2.from_string("DID_CHANGE_RENEWAL_PREF") == :did_change_renewal_pref

      assert NotificationTypeV2.from_string("DID_CHANGE_RENEWAL_STATUS") ==
               :did_change_renewal_status

      assert NotificationTypeV2.from_string("DID_FAIL_TO_RENEW") == :did_fail_to_renew
      assert NotificationTypeV2.from_string("DID_RENEW") == :did_renew
      assert NotificationTypeV2.from_string("EXPIRED") == :expired
      assert NotificationTypeV2.from_string("EXTERNAL_PURCHASE_TOKEN") == :external_purchase_token
      assert NotificationTypeV2.from_string("GRACE_PERIOD_EXPIRED") == :grace_period_expired
      assert NotificationTypeV2.from_string("METADATA_UPDATE") == :metadata_update
      assert NotificationTypeV2.from_string("MIGRATION") == :migration
      assert NotificationTypeV2.from_string("OFFER_REDEEMED") == :offer_redeemed
      assert NotificationTypeV2.from_string("ONE_TIME_CHARGE") == :one_time_charge
      assert NotificationTypeV2.from_string("PRICE_CHANGE") == :price_change
      assert NotificationTypeV2.from_string("PRICE_INCREASE") == :price_increase
      assert NotificationTypeV2.from_string("REFUND") == :refund
      assert NotificationTypeV2.from_string("REFUND_DECLINED") == :refund_declined
      assert NotificationTypeV2.from_string("REFUND_REVERSED") == :refund_reversed
      assert NotificationTypeV2.from_string("RENEWAL_EXTENDED") == :renewal_extended
      assert NotificationTypeV2.from_string("RENEWAL_EXTENSION") == :renewal_extension
      assert NotificationTypeV2.from_string("RESCIND_CONSENT") == :rescind_consent
      assert NotificationTypeV2.from_string("REVOKE") == :revoke
      assert NotificationTypeV2.from_string("SUBSCRIBED") == :subscribed
      assert NotificationTypeV2.from_string("TEST") == :test
    end

    test "from_string returns original for unknown" do
      assert NotificationTypeV2.from_string("UNKNOWN_TYPE") == "UNKNOWN_TYPE"
    end

    test "to_string converts atoms" do
      assert NotificationTypeV2.to_string(:consumption_request) == "CONSUMPTION_REQUEST"

      assert NotificationTypeV2.to_string(:did_change_renewal_pref) ==
               "DID_CHANGE_RENEWAL_PREF"

      assert NotificationTypeV2.to_string(:did_change_renewal_status) ==
               "DID_CHANGE_RENEWAL_STATUS"

      assert NotificationTypeV2.to_string(:did_fail_to_renew) == "DID_FAIL_TO_RENEW"
      assert NotificationTypeV2.to_string(:did_renew) == "DID_RENEW"
      assert NotificationTypeV2.to_string(:expired) == "EXPIRED"

      assert NotificationTypeV2.to_string(:external_purchase_token) ==
               "EXTERNAL_PURCHASE_TOKEN"

      assert NotificationTypeV2.to_string(:grace_period_expired) == "GRACE_PERIOD_EXPIRED"
      assert NotificationTypeV2.to_string(:metadata_update) == "METADATA_UPDATE"
      assert NotificationTypeV2.to_string(:migration) == "MIGRATION"
      assert NotificationTypeV2.to_string(:offer_redeemed) == "OFFER_REDEEMED"
      assert NotificationTypeV2.to_string(:one_time_charge) == "ONE_TIME_CHARGE"
      assert NotificationTypeV2.to_string(:price_change) == "PRICE_CHANGE"
      assert NotificationTypeV2.to_string(:price_increase) == "PRICE_INCREASE"
      assert NotificationTypeV2.to_string(:refund) == "REFUND"
      assert NotificationTypeV2.to_string(:refund_declined) == "REFUND_DECLINED"
      assert NotificationTypeV2.to_string(:refund_reversed) == "REFUND_REVERSED"
      assert NotificationTypeV2.to_string(:renewal_extended) == "RENEWAL_EXTENDED"
      assert NotificationTypeV2.to_string(:renewal_extension) == "RENEWAL_EXTENSION"
      assert NotificationTypeV2.to_string(:rescind_consent) == "RESCIND_CONSENT"
      assert NotificationTypeV2.to_string(:revoke) == "REVOKE"
      assert NotificationTypeV2.to_string(:subscribed) == "SUBSCRIBED"
      assert NotificationTypeV2.to_string(:test) == "TEST"
    end
  end

  describe "SubtypeV2" do
    test "from_string converts known subtypes" do
      assert SubtypeV2.from_string("ACCEPTED") == :accepted
      assert SubtypeV2.from_string("ACTIVE_TOKEN_REMINDER") == :active_token_reminder
      assert SubtypeV2.from_string("AUTO_RENEW_DISABLED") == :auto_renew_disabled
      assert SubtypeV2.from_string("AUTO_RENEW_ENABLED") == :auto_renew_enabled
      assert SubtypeV2.from_string("BILLING_RECOVERY") == :billing_recovery
      assert SubtypeV2.from_string("BILLING_RETRY") == :billing_retry
      assert SubtypeV2.from_string("CREATED") == :created
      assert SubtypeV2.from_string("DOWNGRADE") == :downgrade
      assert SubtypeV2.from_string("FAILURE") == :failure
      assert SubtypeV2.from_string("GRACE_PERIOD") == :grace_period
      assert SubtypeV2.from_string("INITIAL_BUY") == :initial_buy
      assert SubtypeV2.from_string("PENDING") == :pending
      assert SubtypeV2.from_string("PRICE_INCREASE") == :price_increase
      assert SubtypeV2.from_string("PRODUCT_NOT_FOR_SALE") == :product_not_for_sale
      assert SubtypeV2.from_string("RESUBSCRIBE") == :resubscribe
      assert SubtypeV2.from_string("SUMMARY") == :summary
      assert SubtypeV2.from_string("UPGRADE") == :upgrade
      assert SubtypeV2.from_string("UNREPORTED") == :unreported
      assert SubtypeV2.from_string("VOLUNTARY") == :voluntary
    end

    test "from_string returns original for unknown" do
      assert SubtypeV2.from_string("UNKNOWN") == "UNKNOWN"
    end

    test "to_string converts atoms" do
      assert SubtypeV2.to_string(:accepted) == "ACCEPTED"
      assert SubtypeV2.to_string(:active_token_reminder) == "ACTIVE_TOKEN_REMINDER"
      assert SubtypeV2.to_string(:auto_renew_disabled) == "AUTO_RENEW_DISABLED"
      assert SubtypeV2.to_string(:auto_renew_enabled) == "AUTO_RENEW_ENABLED"
      assert SubtypeV2.to_string(:billing_recovery) == "BILLING_RECOVERY"
      assert SubtypeV2.to_string(:billing_retry) == "BILLING_RETRY"
      assert SubtypeV2.to_string(:created) == "CREATED"
      assert SubtypeV2.to_string(:downgrade) == "DOWNGRADE"
      assert SubtypeV2.to_string(:failure) == "FAILURE"
      assert SubtypeV2.to_string(:grace_period) == "GRACE_PERIOD"
      assert SubtypeV2.to_string(:initial_buy) == "INITIAL_BUY"
      assert SubtypeV2.to_string(:pending) == "PENDING"
      assert SubtypeV2.to_string(:price_increase) == "PRICE_INCREASE"
      assert SubtypeV2.to_string(:product_not_for_sale) == "PRODUCT_NOT_FOR_SALE"
      assert SubtypeV2.to_string(:resubscribe) == "RESUBSCRIBE"
      assert SubtypeV2.to_string(:summary) == "SUMMARY"
      assert SubtypeV2.to_string(:upgrade) == "UPGRADE"
      assert SubtypeV2.to_string(:unreported) == "UNREPORTED"
      assert SubtypeV2.to_string(:voluntary) == "VOLUNTARY"
    end
  end

  describe "Status" do
    test "from_integer converts known statuses" do
      assert Status.from_integer(1) == :active
      assert Status.from_integer(2) == :expired
      assert Status.from_integer(3) == :billing_retry
      assert Status.from_integer(4) == :billing_grace_period
      assert Status.from_integer(5) == :revoked
    end

    test "from_integer returns original for unknown" do
      assert Status.from_integer(99) == 99
    end

    test "to_integer converts atoms" do
      assert Status.to_integer(:active) == 1
      assert Status.to_integer(:expired) == 2
      assert Status.to_integer(:billing_retry) == 3
      assert Status.to_integer(:billing_grace_period) == 4
      assert Status.to_integer(:revoked) == 5
    end

    test "to_string converts atoms" do
      assert Status.to_string(:active) == "ACTIVE"
      assert Status.to_string(:expired) == "EXPIRED"
      assert Status.to_string(:billing_retry) == "BILLING_RETRY"
      assert Status.to_string(:billing_grace_period) == "BILLING_GRACE_PERIOD"
      assert Status.to_string(:revoked) == "REVOKED"
    end
  end

  describe "AutoRenewStatus" do
    test "from_integer converts known statuses" do
      assert AutoRenewStatus.from_integer(0) == :off
      assert AutoRenewStatus.from_integer(1) == :on
    end

    test "from_integer returns original for unknown" do
      assert AutoRenewStatus.from_integer(99) == 99
    end

    test "to_integer converts atoms" do
      assert AutoRenewStatus.to_integer(:off) == 0
      assert AutoRenewStatus.to_integer(:on) == 1
    end
  end

  describe "ExpirationIntent" do
    test "from_integer converts known intents" do
      assert ExpirationIntent.from_integer(1) == :customer_cancelled
      assert ExpirationIntent.from_integer(2) == :billing_error
      assert ExpirationIntent.from_integer(3) == :customer_did_not_consent_to_price_increase
      assert ExpirationIntent.from_integer(4) == :product_not_available
      assert ExpirationIntent.from_integer(5) == :other
    end

    test "from_integer returns original for unknown" do
      assert ExpirationIntent.from_integer(99) == 99
    end
  end

  describe "OfferType" do
    test "from_integer converts known types" do
      assert OfferType.from_integer(1) == :introductory_offer
      assert OfferType.from_integer(2) == :promotional_offer
      assert OfferType.from_integer(3) == :offer_code
      assert OfferType.from_integer(4) == :win_back_offer
    end

    test "from_integer returns original for unknown" do
      assert OfferType.from_integer(99) == 99
    end

    test "to_integer converts atoms" do
      assert OfferType.to_integer(:introductory_offer) == 1
      assert OfferType.to_integer(:promotional_offer) == 2
      assert OfferType.to_integer(:offer_code) == 3
      assert OfferType.to_integer(:win_back_offer) == 4
    end
  end

  describe "OfferDiscountType" do
    test "from_string converts known types" do
      assert OfferDiscountType.from_string("FREE_TRIAL") == :free_trial
      assert OfferDiscountType.from_string("PAY_AS_YOU_GO") == :pay_as_you_go
      assert OfferDiscountType.from_string("PAY_UP_FRONT") == :pay_up_front
      assert OfferDiscountType.from_string("ONE_TIME") == :one_time
    end

    test "from_string returns original for unknown" do
      assert OfferDiscountType.from_string("UNKNOWN") == "UNKNOWN"
    end

    test "to_string converts atoms" do
      assert OfferDiscountType.to_string(:free_trial) == "FREE_TRIAL"
      assert OfferDiscountType.to_string(:pay_as_you_go) == "PAY_AS_YOU_GO"
      assert OfferDiscountType.to_string(:pay_up_front) == "PAY_UP_FRONT"
      assert OfferDiscountType.to_string(:one_time) == "ONE_TIME"
    end
  end

  describe "PriceIncreaseStatus" do
    test "from_integer converts known statuses" do
      assert PriceIncreaseStatus.from_integer(0) == :customer_has_not_responded

      assert PriceIncreaseStatus.from_integer(1) ==
               :customer_consented_or_was_notified_without_needing_consent
    end

    test "from_integer returns original for unknown" do
      assert PriceIncreaseStatus.from_integer(99) == 99
    end

    test "to_integer converts atoms" do
      assert PriceIncreaseStatus.to_integer(:customer_has_not_responded) == 0

      assert PriceIncreaseStatus.to_integer(
               :customer_consented_or_was_notified_without_needing_consent
             ) == 1
    end
  end

  describe "InAppOwnershipType" do
    test "from_string converts known types" do
      assert InAppOwnershipType.from_string("FAMILY_SHARED") == :family_shared
      assert InAppOwnershipType.from_string("PURCHASED") == :purchased
    end

    test "from_string returns original for unknown" do
      assert InAppOwnershipType.from_string("UNKNOWN") == "UNKNOWN"
    end

    test "to_string converts atoms" do
      assert InAppOwnershipType.to_string(:family_shared) == "FAMILY_SHARED"
      assert InAppOwnershipType.to_string(:purchased) == "PURCHASED"
    end
  end

  describe "TransactionReason" do
    test "from_string converts known reasons" do
      assert TransactionReason.from_string("PURCHASE") == :purchase
      assert TransactionReason.from_string("RENEWAL") == :renewal
    end

    test "from_string returns original for unknown" do
      assert TransactionReason.from_string("UNKNOWN") == "UNKNOWN"
    end

    test "to_string converts atoms" do
      assert TransactionReason.to_string(:purchase) == "PURCHASE"
      assert TransactionReason.to_string(:renewal) == "RENEWAL"
    end
  end

  describe "RevocationReason" do
    test "from_integer converts known reasons" do
      assert RevocationReason.from_integer(0) == :refunded_for_other_reason
      assert RevocationReason.from_integer(1) == :refunded_due_to_issue
    end

    test "from_integer returns original for unknown" do
      assert RevocationReason.from_integer(99) == 99
    end

    test "to_integer converts atoms" do
      assert RevocationReason.to_integer(:refunded_for_other_reason) == 0
      assert RevocationReason.to_integer(:refunded_due_to_issue) == 1
    end
  end
end
