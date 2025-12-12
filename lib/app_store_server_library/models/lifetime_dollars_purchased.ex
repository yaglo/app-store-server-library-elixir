defmodule AppStoreServerLibrary.Models.LifetimeDollarsPurchased do
  @moduledoc """
  A value that indicates the total amount, in USD, of in-app purchases the customer has made in your app, across all platforms.

  https://developer.apple.com/documentation/appstoreserverapi/lifetimedollarspurchased
  """

  @type t ::
          :undeclared
          | :zero_dollars
          | :one_cent_to_forty_nine_dollars_and_ninety_nine_cents
          | :fifty_dollars_to_ninety_nine_dollars_and_ninety_nine_cents
          | :one_hundred_dollars_to_four_hundred_ninety_nine_dollars_and_ninety_nine_cents
          | :five_hundred_dollars_to_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents
          | :one_thousand_dollars_to_one_thousand_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents
          | :two_thousand_dollars_or_greater

  @doc """
  Convert integer to lifetime dollars purchased atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :zero_dollars
  def from_integer(2), do: :one_cent_to_forty_nine_dollars_and_ninety_nine_cents
  def from_integer(3), do: :fifty_dollars_to_ninety_nine_dollars_and_ninety_nine_cents

  def from_integer(4),
    do: :one_hundred_dollars_to_four_hundred_ninety_nine_dollars_and_ninety_nine_cents

  def from_integer(5),
    do: :five_hundred_dollars_to_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents

  def from_integer(6),
    do:
      :one_thousand_dollars_to_one_thousand_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents

  def from_integer(7), do: :two_thousand_dollars_or_greater

  @doc """
  Convert lifetime dollars purchased atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:zero_dollars), do: 1
  def to_integer(:one_cent_to_forty_nine_dollars_and_ninety_nine_cents), do: 2
  def to_integer(:fifty_dollars_to_ninety_nine_dollars_and_ninety_nine_cents), do: 3

  def to_integer(:one_hundred_dollars_to_four_hundred_ninety_nine_dollars_and_ninety_nine_cents),
    do: 4

  def to_integer(:five_hundred_dollars_to_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents),
    do: 5

  def to_integer(
        :one_thousand_dollars_to_one_thousand_nine_hundred_ninety_nine_dollars_and_ninety_nine_cents
      ),
      do: 6

  def to_integer(:two_thousand_dollars_or_greater), do: 7
end
