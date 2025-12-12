defmodule AppStoreServerLibrary.Models.ConsumptionStatus do
  @moduledoc """
  A value that indicates the extent to which the customer consumed the in-app purchase.

  https://developer.apple.com/documentation/appstoreserverapi/consumptionstatus
  """

  @type t :: :undeclared | :not_consumed | :partially_consumed | :fully_consumed

  @doc """
  Convert integer to consumption status atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :not_consumed
  def from_integer(2), do: :partially_consumed
  def from_integer(3), do: :fully_consumed

  @doc """
  Convert consumption status atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:not_consumed), do: 1
  def to_integer(:partially_consumed), do: 2
  def to_integer(:fully_consumed), do: 3
end
