defmodule AppStoreServerLibrary.Models.NotificationTypeV2 do
  @moduledoc """
  The type that describes the in-app purchase or external purchase event for which the App Store sends the version 2 notification.

  https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:consumption_request, "CONSUMPTION_REQUEST")
    value(:did_change_renewal_pref, "DID_CHANGE_RENEWAL_PREF")
    value(:did_change_renewal_status, "DID_CHANGE_RENEWAL_STATUS")
    value(:did_fail_to_renew, "DID_FAIL_TO_RENEW")
    value(:did_renew, "DID_RENEW")
    value(:expired, "EXPIRED")
    value(:external_purchase_token, "EXTERNAL_PURCHASE_TOKEN")
    value(:grace_period_expired, "GRACE_PERIOD_EXPIRED")
    value(:metadata_update, "METADATA_UPDATE")
    value(:migration, "MIGRATION")
    value(:offer_redeemed, "OFFER_REDEEMED")
    value(:one_time_charge, "ONE_TIME_CHARGE")
    value(:price_change, "PRICE_CHANGE")
    value(:price_increase, "PRICE_INCREASE")
    value(:refund, "REFUND")
    value(:refund_declined, "REFUND_DECLINED")
    value(:refund_reversed, "REFUND_REVERSED")
    value(:renewal_extended, "RENEWAL_EXTENDED")
    value(:renewal_extension, "RENEWAL_EXTENSION")
    value(:rescind_consent, "RESCIND_CONSENT")
    value(:revoke, "REVOKE")
    value(:subscribed, "SUBSCRIBED")
    value(:test, "TEST")
  end
end
