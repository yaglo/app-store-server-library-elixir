defmodule AppStoreServerLibrary.Models.Type do
  @moduledoc """
  The type of in-app purchase products you can offer in your app.

  https://developer.apple.com/documentation/appstoreserverapi/type
  """

  @type t ::
          :auto_renewable_subscription
          | :non_consumable
          | :consumable
          | :non_renewing_subscription

  @doc """
  Convert string to type atom
  """
  @spec from_string(String.t()) :: t() | String.t()
  def from_string("Auto-Renewable Subscription"), do: :auto_renewable_subscription
  def from_string("Non-Consumable"), do: :non_consumable
  def from_string("Consumable"), do: :consumable
  def from_string("Non-Renewing Subscription"), do: :non_renewing_subscription
  def from_string(unknown) when is_binary(unknown), do: unknown

  @doc """
  Convert type atom to string
  """
  @spec to_string(t() | String.t()) :: String.t()
  def to_string(:auto_renewable_subscription), do: "Auto-Renewable Subscription"
  def to_string(:non_consumable), do: "Non-Consumable"
  def to_string(:consumable), do: "Consumable"
  def to_string(:non_renewing_subscription), do: "Non-Renewing Subscription"
  def to_string(unknown) when is_binary(unknown), do: unknown
end
