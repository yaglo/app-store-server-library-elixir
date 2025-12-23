defmodule AppStoreServerLibrary.Models.ProductType do
  @moduledoc """
  Product types for App Store transactions.
  """

  use AppStoreServerLibrary.Models.Enum

  defenum do
    value(:auto_renewable, "AUTO_RENEWABLE")
    value(:non_renewable, "NON_RENEWABLE")
    value(:consumable, "CONSUMABLE")
    value(:non_consumable, "NON_CONSUMABLE")
  end

  @doc "Auto-renewable subscription product."
  @spec auto_renewable() :: t()
  def auto_renewable, do: :auto_renewable

  @doc "Non-renewable subscription product."
  @spec non_renewable() :: t()
  def non_renewable, do: :non_renewable

  @doc "Consumable product."
  @spec consumable() :: t()
  def consumable, do: :consumable

  @doc "Non-consumable product."
  @spec non_consumable() :: t()
  def non_consumable, do: :non_consumable
end
