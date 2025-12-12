defmodule AppStoreServerLibrary.Models.Subtype do
  @moduledoc """
  Represents the subtype of an App Store Server Notification.

  https://developer.apple.com/documentation/appstoreservernotifications/subtype
  """

  @type t ::
          :subscribed
          | :did_not_renew
          | :expired
          | :in_grace_period
          | :price_increase
          | :grace_period_expired
          | :pending
          | :accepted
          | :revoked
          | :subscription_extended
          | :summary
          | :unreported
          | :initial_buy

  @doc """
  Convert string to Subtype atom.
  Returns the original string if the value is not recognized (forward compatibility).
  """
  @spec from_string(String.t()) :: t() | String.t()
  def from_string("SUBSCRIBED"), do: :subscribed
  def from_string("DID_NOT_RENEW"), do: :did_not_renew
  def from_string("EXPIRED"), do: :expired
  def from_string("IN_GRACE_PERIOD"), do: :in_grace_period
  def from_string("PRICE_INCREASE"), do: :price_increase
  def from_string("GRACE_PERIOD_EXPIRED"), do: :grace_period_expired
  def from_string("PENDING"), do: :pending
  def from_string("ACCEPTED"), do: :accepted
  def from_string("REVOKED"), do: :revoked
  def from_string("SUBSCRIPTION_EXTENDED"), do: :subscription_extended
  def from_string("SUMMARY"), do: :summary
  def from_string("UNREPORTED"), do: :unreported
  def from_string("INITIAL_BUY"), do: :initial_buy
  def from_string(unknown) when is_binary(unknown), do: unknown

  @doc """
  Convert Subtype atom to string.
  """
  @spec to_string(t() | String.t()) :: String.t()
  def to_string(:subscribed), do: "SUBSCRIBED"
  def to_string(:did_not_renew), do: "DID_NOT_RENEW"
  def to_string(:expired), do: "EXPIRED"
  def to_string(:in_grace_period), do: "IN_GRACE_PERIOD"
  def to_string(:price_increase), do: "PRICE_INCREASE"
  def to_string(:grace_period_expired), do: "GRACE_PERIOD_EXPIRED"
  def to_string(:pending), do: "PENDING"
  def to_string(:accepted), do: "ACCEPTED"
  def to_string(:revoked), do: "REVOKED"
  def to_string(:subscription_extended), do: "SUBSCRIPTION_EXTENDED"
  def to_string(:summary), do: "SUMMARY"
  def to_string(:unreported), do: "UNREPORTED"
  def to_string(:initial_buy), do: "INITIAL_BUY"
  def to_string(unknown) when is_binary(unknown), do: unknown
end
