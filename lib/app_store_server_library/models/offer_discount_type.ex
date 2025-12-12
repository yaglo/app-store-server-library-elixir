defmodule AppStoreServerLibrary.Models.OfferDiscountType do
  @moduledoc """
  The payment mode for a discount offer on an In-App Purchase.

  https://developer.apple.com/documentation/appstoreserverapi/offerdiscounttype
  """

  @type t :: :free_trial | :pay_as_you_go | :pay_up_front | :one_time

  @doc """
  Offer discount type values
  """
  def free_trial, do: :free_trial
  def pay_as_you_go, do: :pay_as_you_go
  def pay_up_front, do: :pay_up_front
  def one_time, do: :one_time

  @doc """
  Convert string to atom
  """
  @spec from_string(String.t()) :: {:ok, t()} | {:error, :invalid_discount_type}
  def from_string("FREE_TRIAL"), do: {:ok, :free_trial}
  def from_string("PAY_AS_YOU_GO"), do: {:ok, :pay_as_you_go}
  def from_string("PAY_UP_FRONT"), do: {:ok, :pay_up_front}
  def from_string("ONE_TIME"), do: {:ok, :one_time}
  def from_string(_), do: {:error, :invalid_discount_type}

  @doc """
  Convert atom to string representation
  """
  @spec to_string(t()) :: String.t()
  def to_string(:free_trial), do: "FREE_TRIAL"
  def to_string(:pay_as_you_go), do: "PAY_AS_YOU_GO"
  def to_string(:pay_up_front), do: "PAY_UP_FRONT"
  def to_string(:one_time), do: "ONE_TIME"
end
