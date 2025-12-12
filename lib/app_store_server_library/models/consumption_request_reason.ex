defmodule AppStoreServerLibrary.Models.ConsumptionRequestReason do
  @moduledoc """
  The customer-provided reason for a refund request.

  https://developer.apple.com/documentation/appstoreservernotifications/consumptionrequestreason
  """

  @type t() ::
          :unintended_purchase
          | :fulfillment_issue
          | :unsatisfied_with_purchase
          | :legal
          | :other

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_reason}
  def from_string("UNINTENDED_PURCHASE"), do: {:ok, :unintended_purchase}
  def from_string("FULFILLMENT_ISSUE"), do: {:ok, :fulfillment_issue}
  def from_string("UNSATISFIED_WITH_PURCHASE"), do: {:ok, :unsatisfied_with_purchase}
  def from_string("LEGAL"), do: {:ok, :legal}
  def from_string("OTHER"), do: {:ok, :other}
  def from_string(_), do: {:error, :invalid_reason}

  @doc """
  Convert atom to string
  """
  @spec to_string(t()) :: String.t()
  def to_string(:unintended_purchase), do: "UNINTENDED_PURCHASE"
  def to_string(:fulfillment_issue), do: "FULFILLMENT_ISSUE"
  def to_string(:unsatisfied_with_purchase), do: "UNSATISFIED_WITH_PURCHASE"
  def to_string(:legal), do: "LEGAL"
  def to_string(:other), do: "OTHER"
end
