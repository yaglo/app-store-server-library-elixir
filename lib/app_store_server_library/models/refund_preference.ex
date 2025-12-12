defmodule AppStoreServerLibrary.Models.RefundPreference do
  @moduledoc """
  A value that indicates your preferred outcome for refund request.

  https://developer.apple.com/documentation/appstoreserverapi/refundpreference
  """

  @type t :: :undeclared | :prefer_grant | :prefer_decline | :no_preference

  @doc """
  Convert integer to refund preference atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :prefer_grant
  def from_integer(2), do: :prefer_decline
  def from_integer(3), do: :no_preference

  @doc """
  Convert refund preference atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:prefer_grant), do: 1
  def to_integer(:prefer_decline), do: 2
  def to_integer(:no_preference), do: 3
end
