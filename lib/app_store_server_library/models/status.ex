defmodule AppStoreServerLibrary.Models.Status do
  @moduledoc """
  The status of an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/status
  """

  @type t :: :active | :expired | :billing_retry | :billing_grace_period | :revoked

  @doc """
  Convert integer to atom.
  Returns the original integer if the value is not recognized (forward compatibility).
  """
  @spec from_integer(integer()) :: t() | integer()
  def from_integer(1), do: :active
  def from_integer(2), do: :expired
  def from_integer(3), do: :billing_retry
  def from_integer(4), do: :billing_grace_period
  def from_integer(5), do: :revoked
  def from_integer(unknown) when is_integer(unknown), do: unknown

  @doc """
  Convert atom to integer representation.
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:active), do: 1
  def to_integer(:expired), do: 2
  def to_integer(:billing_retry), do: 3
  def to_integer(:billing_grace_period), do: 4
  def to_integer(:revoked), do: 5

  @doc """
  Convert status atom to string representation.
  """
  @spec to_string(t()) :: String.t()
  def to_string(:active), do: "ACTIVE"
  def to_string(:expired), do: "EXPIRED"
  def to_string(:billing_retry), do: "BILLING_RETRY"
  def to_string(:billing_grace_period), do: "BILLING_GRACE_PERIOD"
  def to_string(:revoked), do: "REVOKED"
end
