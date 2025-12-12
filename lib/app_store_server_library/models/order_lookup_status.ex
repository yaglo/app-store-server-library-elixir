defmodule AppStoreServerLibrary.Models.OrderLookupStatus do
  @moduledoc """
  A value that indicates whether the order ID in the request is valid for your app.

  https://developer.apple.com/documentation/appstoreserverapi/orderlookupstatus
  """

  @type t() :: :valid | :invalid

  @doc """
  Convert integer to atom
  """
  @spec from_integer(integer()) :: {:ok, t()} | {:error, :invalid_status}
  def from_integer(0), do: {:ok, :valid}
  def from_integer(1), do: {:ok, :invalid}
  def from_integer(_), do: {:error, :invalid_status}

  @doc """
  Convert atom to integer
  """
  @spec to_integer(t()) :: integer()
  def to_integer(:valid), do: 0
  def to_integer(:invalid), do: 1
end
