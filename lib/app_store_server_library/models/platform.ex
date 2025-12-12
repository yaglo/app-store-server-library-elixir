defmodule AppStoreServerLibrary.Models.Platform do
  @moduledoc """
  The platform on which the customer consumed the in-app purchase.

  https://developer.apple.com/documentation/appstoreserverapi/platform
  """

  @type t :: :undeclared | :apple | :non_apple

  @doc """
  Convert integer to platform atom
  """
  @spec from_integer(integer()) :: t()
  def from_integer(0), do: :undeclared
  def from_integer(1), do: :apple
  def from_integer(2), do: :non_apple

  @doc """
  Convert platform atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:undeclared), do: 0
  def to_integer(:apple), do: 1
  def to_integer(:non_apple), do: 2
end
