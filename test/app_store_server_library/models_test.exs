defmodule AppStoreServerLibrary.ModelsTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.{
    AccountTenure,
    AutoRenewStatus,
    ConsumptionStatus,
    DeliveryStatus,
    Environment,
    ExpirationIntent,
    InAppOwnershipType,
    LifetimeDollarsPurchased,
    LifetimeDollarsRefunded,
    NotificationTypeV2,
    OfferDiscountType,
    OfferType,
    Platform,
    PlayTime,
    PriceIncreaseStatus,
    RevocationReason,
    Status,
    Subtype,
    TransactionReason,
    UserStatus
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
      assert NotificationTypeV2.from_string("SUBSCRIBED") == :subscribed
      assert NotificationTypeV2.from_string("DID_RENEW") == :did_renew
      assert NotificationTypeV2.from_string("EXPIRED") == :expired
      assert NotificationTypeV2.from_string("REFUND") == :refund
      assert NotificationTypeV2.from_string("TEST") == :test
    end

    test "from_string returns original for unknown" do
      assert NotificationTypeV2.from_string("UNKNOWN_TYPE") == "UNKNOWN_TYPE"
    end

    test "to_string converts atoms" do
      assert NotificationTypeV2.to_string(:subscribed) == "SUBSCRIBED"
      assert NotificationTypeV2.to_string(:did_renew) == "DID_RENEW"
      assert NotificationTypeV2.to_string(:refund) == "REFUND"
    end
  end

  describe "Subtype" do
    test "from_string converts known subtypes" do
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
    end

    test "from_string returns original for unknown" do
      assert Subtype.from_string("UNKNOWN") == "UNKNOWN"
    end

    test "to_string converts atoms" do
      assert Subtype.to_string(:subscribed) == "SUBSCRIBED"
      assert Subtype.to_string(:pending) == "PENDING"
      assert Subtype.to_string(:summary) == "SUMMARY"
      assert Subtype.to_string(:initial_buy) == "INITIAL_BUY"
    end
  end

  describe "Status" do
    # Status module has constants and to_integer, but no from_integer
    test "constants return correct values" do
      assert Status.active() == 1
      assert Status.expired() == 2
      assert Status.billing_retry() == 3
      assert Status.billing_grace_period() == 4
      assert Status.revoked() == 5
    end

    test "to_integer converts atoms" do
      assert Status.to_integer(:active) == 1
      assert Status.to_integer(:expired) == 2
      assert Status.to_integer(:billing_retry) == 3
      assert Status.to_integer(:billing_grace_period) == 4
      assert Status.to_integer(:revoked) == 5
    end

    test "to_string converts integers" do
      assert Status.to_string(1) == "ACTIVE"
      assert Status.to_string(2) == "EXPIRED"
      assert Status.to_string(3) == "BILLING_RETRY"
      assert Status.to_string(4) == "BILLING_GRACE_PERIOD"
      assert Status.to_string(5) == "REVOKED"
    end
  end

  describe "AutoRenewStatus" do
    test "from_integer converts known statuses" do
      assert AutoRenewStatus.from_integer(0) == {:ok, :off}
      assert AutoRenewStatus.from_integer(1) == {:ok, :on}
    end

    test "to_integer converts atoms" do
      assert AutoRenewStatus.to_integer(:off) == 0
      assert AutoRenewStatus.to_integer(:on) == 1
    end
  end

  describe "ExpirationIntent" do
    test "from_integer converts known intents" do
      assert ExpirationIntent.from_integer(1) == {:ok, :customer_cancelled}
      assert ExpirationIntent.from_integer(2) == {:ok, :billing_error}

      assert ExpirationIntent.from_integer(3) ==
               {:ok, :customer_did_not_consent_to_price_increase}

      assert ExpirationIntent.from_integer(4) == {:ok, :product_not_available}
      assert ExpirationIntent.from_integer(5) == {:ok, :other}
    end

    test "from_integer returns error for unknown" do
      assert ExpirationIntent.from_integer(99) == {:error, :invalid_expiration_intent}
    end
  end

  describe "OfferType" do
    test "from_integer converts known types" do
      assert OfferType.from_integer(1) == {:ok, :introductory_offer}
      assert OfferType.from_integer(2) == {:ok, :promotional_offer}
      assert OfferType.from_integer(3) == {:ok, :offer_code}
      assert OfferType.from_integer(4) == {:ok, :win_back_offer}
    end

    test "from_integer returns error for unknown" do
      assert OfferType.from_integer(99) == {:error, :invalid_offer_type}
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
      assert OfferDiscountType.from_string("FREE_TRIAL") == {:ok, :free_trial}
      assert OfferDiscountType.from_string("PAY_AS_YOU_GO") == {:ok, :pay_as_you_go}
      assert OfferDiscountType.from_string("PAY_UP_FRONT") == {:ok, :pay_up_front}
    end

    test "to_string converts atoms" do
      assert OfferDiscountType.to_string(:free_trial) == "FREE_TRIAL"
      assert OfferDiscountType.to_string(:pay_as_you_go) == "PAY_AS_YOU_GO"
    end
  end

  describe "PriceIncreaseStatus" do
    test "from_integer converts known statuses" do
      assert PriceIncreaseStatus.from_integer(0) == {:ok, :customer_has_not_responded}

      assert PriceIncreaseStatus.from_integer(1) ==
               {:ok, :customer_consented_or_was_notified_without_needing_consent}
    end

    test "from_integer returns error for unknown" do
      assert PriceIncreaseStatus.from_integer(99) == {:error, :invalid_price_increase_status}
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
      assert InAppOwnershipType.from_string("FAMILY_SHARED") == {:ok, :family_shared}
      assert InAppOwnershipType.from_string("PURCHASED") == {:ok, :purchased}
    end

    test "to_string converts atoms" do
      assert InAppOwnershipType.to_string(:family_shared) == "FAMILY_SHARED"
      assert InAppOwnershipType.to_string(:purchased) == "PURCHASED"
    end
  end

  describe "TransactionReason" do
    test "from_string converts known reasons" do
      assert TransactionReason.from_string("PURCHASE") == {:ok, :purchase}
      assert TransactionReason.from_string("RENEWAL") == {:ok, :renewal}
    end

    test "to_string converts atoms" do
      assert TransactionReason.to_string(:purchase) == "PURCHASE"
      assert TransactionReason.to_string(:renewal) == "RENEWAL"
    end
  end

  describe "RevocationReason" do
    test "from_integer converts known reasons" do
      assert RevocationReason.from_integer(0) == {:ok, :refunded_for_other_reason}
      assert RevocationReason.from_integer(1) == {:ok, :refunded_due_to_issue}
    end

    test "from_integer returns error for unknown" do
      assert RevocationReason.from_integer(99) == {:error, :invalid_reason}
    end

    test "to_integer converts atoms" do
      assert RevocationReason.to_integer(:refunded_for_other_reason) == 0
      assert RevocationReason.to_integer(:refunded_due_to_issue) == 1
    end
  end

  # These modules return atoms directly (not wrapped in {:ok, atom})
  describe "ConsumptionStatus" do
    test "from_integer converts known statuses" do
      assert ConsumptionStatus.from_integer(0) == :undeclared
      assert ConsumptionStatus.from_integer(1) == :not_consumed
      assert ConsumptionStatus.from_integer(2) == :partially_consumed
      assert ConsumptionStatus.from_integer(3) == :fully_consumed
    end

    test "to_integer converts atoms" do
      assert ConsumptionStatus.to_integer(:undeclared) == 0
      assert ConsumptionStatus.to_integer(:fully_consumed) == 3
    end
  end

  describe "DeliveryStatus" do
    test "from_integer converts known statuses" do
      assert DeliveryStatus.from_integer(0) == :delivered_and_working_properly
      assert DeliveryStatus.from_integer(1) == :did_not_deliver_due_to_quality_issue
      assert DeliveryStatus.from_integer(2) == :delivered_wrong_item
      assert DeliveryStatus.from_integer(3) == :did_not_deliver_due_to_server_outage
      assert DeliveryStatus.from_integer(4) == :did_not_deliver_due_to_in_game_currency_change
      assert DeliveryStatus.from_integer(5) == :did_not_deliver_for_other_reason
    end

    test "to_integer converts atoms" do
      assert DeliveryStatus.to_integer(:delivered_and_working_properly) == 0
      assert DeliveryStatus.to_integer(:did_not_deliver_for_other_reason) == 5
    end
  end

  describe "AccountTenure" do
    test "from_integer converts known tenures" do
      assert AccountTenure.from_integer(0) == :undeclared
      assert AccountTenure.from_integer(1) == :zero_to_three_days
      assert AccountTenure.from_integer(2) == :three_days_to_ten_days
      assert AccountTenure.from_integer(3) == :ten_days_to_thirty_days
      assert AccountTenure.from_integer(4) == :thirty_days_to_ninety_days
      assert AccountTenure.from_integer(5) == :ninety_days_to_one_hundred_eighty_days

      assert AccountTenure.from_integer(6) ==
               :one_hundred_eighty_days_to_three_hundred_sixty_five_days

      assert AccountTenure.from_integer(7) == :greater_than_three_hundred_sixty_five_days
    end

    test "to_integer converts atoms" do
      assert AccountTenure.to_integer(:undeclared) == 0
      assert AccountTenure.to_integer(:greater_than_three_hundred_sixty_five_days) == 7
    end
  end

  describe "PlayTime" do
    test "from_integer converts known play times" do
      assert PlayTime.from_integer(0) == :undeclared
      assert PlayTime.from_integer(1) == :zero_to_five_minutes
      assert PlayTime.from_integer(2) == :five_to_sixty_minutes
      assert PlayTime.from_integer(3) == :one_to_six_hours
      assert PlayTime.from_integer(4) == :six_hours_to_twenty_four_hours
      assert PlayTime.from_integer(5) == :one_day_to_four_days
      assert PlayTime.from_integer(6) == :four_days_to_sixteen_days
      assert PlayTime.from_integer(7) == :over_sixteen_days
    end

    test "to_integer converts atoms" do
      assert PlayTime.to_integer(:undeclared) == 0
      assert PlayTime.to_integer(:over_sixteen_days) == 7
    end
  end

  describe "LifetimeDollarsPurchased" do
    test "from_integer converts known values" do
      assert LifetimeDollarsPurchased.from_integer(0) == :undeclared
      assert LifetimeDollarsPurchased.from_integer(1) == :zero_dollars
      assert LifetimeDollarsPurchased.from_integer(7) == :two_thousand_dollars_or_greater
    end

    test "to_integer converts atoms" do
      assert LifetimeDollarsPurchased.to_integer(:undeclared) == 0
      assert LifetimeDollarsPurchased.to_integer(:two_thousand_dollars_or_greater) == 7
    end
  end

  describe "LifetimeDollarsRefunded" do
    test "from_integer converts known values" do
      assert LifetimeDollarsRefunded.from_integer(0) == :undeclared
      assert LifetimeDollarsRefunded.from_integer(1) == :zero_dollars
      assert LifetimeDollarsRefunded.from_integer(7) == :two_thousand_dollars_or_greater
    end

    test "to_integer converts atoms" do
      assert LifetimeDollarsRefunded.to_integer(:undeclared) == 0
      assert LifetimeDollarsRefunded.to_integer(:two_thousand_dollars_or_greater) == 7
    end
  end

  describe "Platform" do
    test "from_integer converts known platforms" do
      assert Platform.from_integer(0) == :undeclared
      assert Platform.from_integer(1) == :apple
      assert Platform.from_integer(2) == :non_apple
    end

    test "to_integer converts atoms" do
      assert Platform.to_integer(:undeclared) == 0
      assert Platform.to_integer(:apple) == 1
      assert Platform.to_integer(:non_apple) == 2
    end
  end

  describe "UserStatus" do
    test "from_integer converts known statuses" do
      assert UserStatus.from_integer(0) == :undeclared
      assert UserStatus.from_integer(1) == :active
      assert UserStatus.from_integer(2) == :suspended
      assert UserStatus.from_integer(3) == :terminated
      assert UserStatus.from_integer(4) == :limited_access
    end

    test "to_integer converts atoms" do
      assert UserStatus.to_integer(:undeclared) == 0
      assert UserStatus.to_integer(:limited_access) == 4
    end
  end
end
