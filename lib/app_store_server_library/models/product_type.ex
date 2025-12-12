defmodule AppStoreServerLibrary.Models.ProductType do
  @moduledoc """
  Product types for App Store transactions.
  """

  @type t :: :auto_renewable | :non_renewable | :consumable | :non_consumable

  @auto_renewable :auto_renewable
  @non_renewable :non_renewable
  @consumable :consumable
  @non_consumable :non_consumable

  def auto_renewable, do: @auto_renewable
  def non_renewable, do: @non_renewable
  def consumable, do: @consumable
  def non_consumable, do: @non_consumable
end
