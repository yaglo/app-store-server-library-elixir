defmodule AppStoreServerLibrary.Models.PriceIncreaseStatus do
  @moduledoc """
  The status that indicates whether an auto-renewable subscription is subject to a price increase.

  https://developer.apple.com/documentation/appstoreserverapi/priceincreasestatus
  """

  @type t ::
          :customer_has_not_responded
          | :customer_consented_or_was_notified_without_needing_consent

  @doc """
  Price increase status values
  """
  def customer_has_not_responded, do: :customer_has_not_responded

  def customer_consented_or_was_notified_without_needing_consent,
    do: :customer_consented_or_was_notified_without_needing_consent

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_price_increase_status}
  def from_integer(0), do: {:ok, :customer_has_not_responded}
  def from_integer(1), do: {:ok, :customer_consented_or_was_notified_without_needing_consent}
  def from_integer(_), do: {:error, :invalid_price_increase_status}

  @doc """
  Convert atom to integer representation
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:customer_has_not_responded), do: 0
  def to_integer(:customer_consented_or_was_notified_without_needing_consent), do: 1
end
