defmodule AppStoreServerLibrary.Models.AccountTenure do
  @moduledoc """
  The age of the customer's account.

  https://developer.apple.com/documentation/appstoreserverapi/accounttenure
  """

  @type t ::
          :undeclared
          | :zero_to_three_days
          | :three_days_to_ten_days
          | :ten_days_to_thirty_days
          | :thirty_days_to_ninety_days
          | :ninety_days_to_one_hundred_eighty_days
          | :one_hundred_eighty_days_to_three_hundred_sixty_five_days
          | :greater_than_three_hundred_sixty_five_days

  @doc """
  Convert integer to account tenure atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :zero_to_three_days
  def from_integer(2), do: :three_days_to_ten_days
  def from_integer(3), do: :ten_days_to_thirty_days
  def from_integer(4), do: :thirty_days_to_ninety_days
  def from_integer(5), do: :ninety_days_to_one_hundred_eighty_days
  def from_integer(6), do: :one_hundred_eighty_days_to_three_hundred_sixty_five_days
  def from_integer(7), do: :greater_than_three_hundred_sixty_five_days

  @doc """
  Convert account tenure atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:zero_to_three_days), do: 1
  def to_integer(:three_days_to_ten_days), do: 2
  def to_integer(:ten_days_to_thirty_days), do: 3
  def to_integer(:thirty_days_to_ninety_days), do: 4
  def to_integer(:ninety_days_to_one_hundred_eighty_days), do: 5
  def to_integer(:one_hundred_eighty_days_to_three_hundred_sixty_five_days), do: 6
  def to_integer(:greater_than_three_hundred_sixty_five_days), do: 7
end
