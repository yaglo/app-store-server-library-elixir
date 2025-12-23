defmodule AppStoreServerLibrary.Models.Order do
  @moduledoc """
  Order types for sorting transaction history.
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:ascending, "ASCENDING")
    value(:descending, "DESCENDING")
  end

  @doc "Ascending sort order."
  @spec ascending() :: t()
  def ascending, do: :ascending

  @doc "Descending sort order."
  @spec descending() :: t()
  def descending, do: :descending
end
