defmodule AppStoreServerLibrary.Models.SubtypeV2 do
  @moduledoc """
  A string that provides details about select notification types in version 2.

  https://developer.apple.com/documentation/appstoreservernotifications/subtype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:accepted, "ACCEPTED")
    value(:active_token_reminder, "ACTIVE_TOKEN_REMINDER")
    value(:auto_renew_disabled, "AUTO_RENEW_DISABLED")
    value(:auto_renew_enabled, "AUTO_RENEW_ENABLED")
    value(:billing_recovery, "BILLING_RECOVERY")
    value(:billing_retry, "BILLING_RETRY")
    value(:created, "CREATED")
    value(:downgrade, "DOWNGRADE")
    value(:failure, "FAILURE")
    value(:grace_period, "GRACE_PERIOD")
    value(:initial_buy, "INITIAL_BUY")
    value(:pending, "PENDING")
    value(:price_increase, "PRICE_INCREASE")
    value(:product_not_for_sale, "PRODUCT_NOT_FOR_SALE")
    value(:resubscribe, "RESUBSCRIBE")
    value(:summary, "SUMMARY")
    value(:upgrade, "UPGRADE")
    value(:unreported, "UNREPORTED")
    value(:voluntary, "VOLUNTARY")
  end
end
