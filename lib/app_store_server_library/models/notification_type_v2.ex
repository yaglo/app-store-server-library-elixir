defmodule AppStoreServerLibrary.Models.NotificationTypeV2 do
  @moduledoc """
  The type that describes the in-app purchase or external purchase event for which the App Store sends the version 2 notification.

  https://developer.apple.com/documentation/appstoreservernotifications/notificationtype
  """

  @type t ::
          :subscribed
          | :did_change_renewal_pref
          | :did_change_renewal_status
          | :offer_redeemed
          | :did_renew
          | :expired
          | :did_fail_to_renew
          | :grace_period_expired
          | :price_increase
          | :refund
          | :refund_declined
          | :consumption_request
          | :renewal_extended
          | :revoke
          | :test
          | :renewal_extension
          | :refund_reversed
          | :external_purchase_token
          | :one_time_charge

  @doc """
  Convert string to notification type atom
  """
  @spec from_string(String.t()) :: t() | String.t()
  def from_string("SUBSCRIBED"), do: :subscribed
  def from_string("DID_CHANGE_RENEWAL_PREF"), do: :did_change_renewal_pref
  def from_string("DID_CHANGE_RENEWAL_STATUS"), do: :did_change_renewal_status
  def from_string("OFFER_REDEEMED"), do: :offer_redeemed
  def from_string("DID_RENEW"), do: :did_renew
  def from_string("EXPIRED"), do: :expired
  def from_string("DID_FAIL_TO_RENEW"), do: :did_fail_to_renew
  def from_string("GRACE_PERIOD_EXPIRED"), do: :grace_period_expired
  def from_string("PRICE_INCREASE"), do: :price_increase
  def from_string("REFUND"), do: :refund
  def from_string("REFUND_DECLINED"), do: :refund_declined
  def from_string("CONSUMPTION_REQUEST"), do: :consumption_request
  def from_string("RENEWAL_EXTENDED"), do: :renewal_extended
  def from_string("REVOKE"), do: :revoke
  def from_string("TEST"), do: :test
  def from_string("RENEWAL_EXTENSION"), do: :renewal_extension
  def from_string("REFUND_REVERSED"), do: :refund_reversed
  def from_string("EXTERNAL_PURCHASE_TOKEN"), do: :external_purchase_token
  def from_string("ONE_TIME_CHARGE"), do: :one_time_charge
  def from_string(unknown) when is_binary(unknown), do: unknown

  @doc """
  Convert notification type atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:subscribed), do: "SUBSCRIBED"
  def to_string(:did_change_renewal_pref), do: "DID_CHANGE_RENEWAL_PREF"
  def to_string(:did_change_renewal_status), do: "DID_CHANGE_RENEWAL_STATUS"
  def to_string(:offer_redeemed), do: "OFFER_REDEEMED"
  def to_string(:did_renew), do: "DID_RENEW"
  def to_string(:expired), do: "EXPIRED"
  def to_string(:did_fail_to_renew), do: "DID_FAIL_TO_RENEW"
  def to_string(:grace_period_expired), do: "GRACE_PERIOD_EXPIRED"
  def to_string(:price_increase), do: "PRICE_INCREASE"
  def to_string(:refund), do: "REFUND"
  def to_string(:refund_declined), do: "REFUND_DECLINED"
  def to_string(:consumption_request), do: "CONSUMPTION_REQUEST"
  def to_string(:renewal_extended), do: "RENEWAL_EXTENDED"
  def to_string(:revoke), do: "REVOKE"
  def to_string(:test), do: "TEST"
  def to_string(:renewal_extension), do: "RENEWAL_EXTENSION"
  def to_string(:refund_reversed), do: "REFUND_REVERSED"
  def to_string(:external_purchase_token), do: "EXTERNAL_PURCHASE_TOKEN"
  def to_string(:one_time_charge), do: "ONE_TIME_CHARGE"
  def to_string(unknown) when is_binary(unknown), do: unknown
end
