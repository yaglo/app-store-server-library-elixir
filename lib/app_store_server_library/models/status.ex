defmodule AppStoreServerLibrary.Models.Status do
  @moduledoc """
  The status of an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/status
  """

  @type t :: 1 | 2 | 3 | 4 | 5

  @doc """
  Status values for auto-renewable subscriptions
  """
  def active, do: 1
  def expired, do: 2
  def billing_retry, do: 3
  def billing_grace_period, do: 4
  def revoked, do: 5

  @doc """
  Convert status to string representation
  """
  @spec to_string(t()) :: String.t()
  def to_string(1), do: "ACTIVE"
  def to_string(2), do: "EXPIRED"
  def to_string(3), do: "BILLING_RETRY"
  def to_string(4), do: "BILLING_GRACE_PERIOD"
  def to_string(5), do: "REVOKED"

  @doc """
  Convert status atom to integer representation
  """
  @spec to_integer(atom()) :: t()
  def to_integer(:active), do: 1
  def to_integer(:expired), do: 2
  def to_integer(:billing_retry), do: 3
  def to_integer(:billing_grace_period), do: 4
  def to_integer(:revoked), do: 5
end
