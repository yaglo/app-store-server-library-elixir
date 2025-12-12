defmodule AppStoreServerLibrary.Models.Order do
  @moduledoc """
  Order types for sorting transaction history.
  """

  @type t :: :ascending | :descending

  @ascending :ascending
  @descending :descending

  def ascending, do: @ascending
  def descending, do: @descending
end
