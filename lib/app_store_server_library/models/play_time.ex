defmodule AppStoreServerLibrary.Models.PlayTime do
  @moduledoc """
  A value that indicates the amount of time that the customer used the app.

  https://developer.apple.com/documentation/appstoreserverapi/playtime
  """

  @type t ::
          :undeclared
          | :zero_to_five_minutes
          | :five_to_sixty_minutes
          | :one_to_six_hours
          | :six_hours_to_twenty_four_hours
          | :one_day_to_four_days
          | :four_days_to_sixteen_days
          | :over_sixteen_days

  @doc """
  Convert integer to play time atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :zero_to_five_minutes
  def from_integer(2), do: :five_to_sixty_minutes
  def from_integer(3), do: :one_to_six_hours
  def from_integer(4), do: :six_hours_to_twenty_four_hours
  def from_integer(5), do: :one_day_to_four_days
  def from_integer(6), do: :four_days_to_sixteen_days
  def from_integer(7), do: :over_sixteen_days

  @doc """
  Convert play time atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:zero_to_five_minutes), do: 1
  def to_integer(:five_to_sixty_minutes), do: 2
  def to_integer(:one_to_six_hours), do: 3
  def to_integer(:six_hours_to_twenty_four_hours), do: 4
  def to_integer(:one_day_to_four_days), do: 5
  def to_integer(:four_days_to_sixteen_days), do: 6
  def to_integer(:over_sixteen_days), do: 7
end
