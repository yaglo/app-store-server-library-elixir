defmodule AppStoreServerLibrary.Models.TransactionHistoryRequest do
  @moduledoc """
  Request parameters for getting transaction history.
  """

  @derive Jason.Encoder
  defstruct [
    :start_date,
    :end_date,
    :product_ids,
    :product_types,
    :sort,
    :subscription_group_identifiers,
    :in_app_ownership_type,
    :revoked
  ]

  @type t :: %__MODULE__{
          start_date: integer() | nil,
          end_date: integer() | nil,
          product_ids: [String.t()] | nil,
          product_types: [product_type()] | nil,
          sort: order() | nil,
          subscription_group_identifiers: [String.t()] | nil,
          in_app_ownership_type: in_app_ownership_type() | nil,
          revoked: boolean() | nil
        }

  @type product_type :: :auto_renewable | :non_renewable | :consumable | :non_consumable
  @type order :: :ascending | :descending
  @type in_app_ownership_type :: :family_shared | :purchased

  @doc """
  Convert product type atom to string
  """
  @spec product_type_to_string(product_type()) :: String.t()
  def product_type_to_string(:auto_renewable), do: "AUTO_RENEWABLE"
  def product_type_to_string(:non_renewable), do: "NON_RENEWABLE"
  def product_type_to_string(:consumable), do: "CONSUMABLE"
  def product_type_to_string(:non_consumable), do: "NON_CONSUMABLE"

  @doc """
  Convert order atom to string
  """
  @spec order_to_string(order()) :: String.t()
  def order_to_string(:ascending), do: "ASCENDING"
  def order_to_string(:descending), do: "DESCENDING"

  @doc """
  Convert in-app ownership type atom to string
  """
  @spec in_app_ownership_type_to_string(in_app_ownership_type()) :: String.t()
  def in_app_ownership_type_to_string(:family_shared), do: "FAMILY_SHARED"
  def in_app_ownership_type_to_string(:purchased), do: "PURCHASED"
end
