defmodule AppStoreServerLibrary.Models.ExtendReasonCode do
  @moduledoc """
  The code that represents the reason for the subscription-renewal-date extension.

  https://developer.apple.com/documentation/appstoreserverapi/extendreasoncode
  """

  @type t :: :undeclared | :customer_satisfaction | :other | :service_issue_or_outage

  @doc """
  Convert integer to extend reason code atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :customer_satisfaction
  def from_integer(2), do: :other
  def from_integer(3), do: :service_issue_or_outage

  @doc """
  Convert extend reason code atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:customer_satisfaction), do: 1
  def to_integer(:other), do: 2
  def to_integer(:service_issue_or_outage), do: 3
end
