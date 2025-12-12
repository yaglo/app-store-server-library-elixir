defmodule AppStoreServerLibrary.Models.OfferType do
  @moduledoc """
  The type of offer.

  https://developer.apple.com/documentation/appstoreserverapi/offertype
  """

  @type t :: :introductory_offer | :promotional_offer | :offer_code | :win_back_offer

  @doc """
  Offer type values
  """
  def introductory_offer, do: :introductory_offer
  def promotional_offer, do: :promotional_offer
  def offer_code, do: :offer_code
  def win_back_offer, do: :win_back_offer

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_offer_type}
  def from_integer(1), do: {:ok, :introductory_offer}
  def from_integer(2), do: {:ok, :promotional_offer}
  def from_integer(3), do: {:ok, :offer_code}
  def from_integer(4), do: {:ok, :win_back_offer}
  def from_integer(_), do: {:error, :invalid_offer_type}

  @doc """
  Convert atom to integer representation
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:introductory_offer), do: 1
  def to_integer(:promotional_offer), do: 2
  def to_integer(:offer_code), do: 3
  def to_integer(:win_back_offer), do: 4
end
