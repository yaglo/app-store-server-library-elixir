defmodule AppStoreServerLibrary.Models.ExpirationIntent do
  @moduledoc """
  The reason an auto-renewable subscription expired.

  https://developer.apple.com/documentation/appstoreserverapi/expirationintent
  """

  @type t ::
          :customer_cancelled
          | :billing_error
          | :customer_did_not_consent_to_price_increase
          | :product_not_available
          | :other

  @doc """
  Expiration intent values
  """
  def customer_cancelled, do: :customer_cancelled
  def billing_error, do: :billing_error
  def customer_did_not_consent_to_price_increase, do: :customer_did_not_consent_to_price_increase
  def product_not_available, do: :product_not_available
  def other, do: :other

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_expiration_intent}
  def from_integer(1), do: {:ok, :customer_cancelled}
  def from_integer(2), do: {:ok, :billing_error}
  def from_integer(3), do: {:ok, :customer_did_not_consent_to_price_increase}
  def from_integer(4), do: {:ok, :product_not_available}
  def from_integer(5), do: {:ok, :other}
  def from_integer(_), do: {:error, :invalid_expiration_intent}

  @doc """
  Convert atom to integer representation
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:customer_cancelled), do: 1
  def to_integer(:billing_error), do: 2
  def to_integer(:customer_did_not_consent_to_price_increase), do: 3
  def to_integer(:product_not_available), do: 4
  def to_integer(:other), do: 5
end
