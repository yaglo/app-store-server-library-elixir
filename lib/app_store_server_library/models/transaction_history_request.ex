defmodule AppStoreServerLibrary.Models.TransactionHistoryRequest do
  @moduledoc """
  Request parameters for getting transaction history.

  All fields are optional. When omitted, the App Store Server API will use its
  default behavior for that parameter.

  ## Fields

    * `:start_date` - Filter transactions created on or after this Unix timestamp (milliseconds)
    * `:end_date` - Filter transactions created before this Unix timestamp (milliseconds)
    * `:product_ids` - Filter by specific product identifiers
    * `:product_types` - Filter by product type (`:consumable`, `:auto_renewable`, etc.)
    * `:sort` - Sort order (`:ascending` or `:descending` by purchase date)
    * `:subscription_group_identifiers` - Filter by subscription group identifiers
    * `:in_app_ownership_type` - Filter by ownership type (`:purchased` or `:family_shared`)
    * `:revoked` - When `true`, include only revoked transactions; when `false`, exclude them

  ## Example

      request = %TransactionHistoryRequest{
        start_date: 1_609_459_200_000,
        product_types: [:auto_renewable],
        sort: :descending
      }

  https://developer.apple.com/documentation/appstoreserverapi/transactionhistoryrequest
  """

  alias AppStoreServerLibrary.Utility.JSON

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

  alias AppStoreServerLibrary.Models.{
    InAppOwnershipType,
    Order,
    ProductType
  }

  @type t :: %__MODULE__{
          start_date: integer() | nil,
          end_date: integer() | nil,
          product_ids: [String.t()] | nil,
          product_types: [ProductType.t()] | nil,
          sort: Order.t() | nil,
          subscription_group_identifiers: [String.t()] | nil,
          in_app_ownership_type: InAppOwnershipType.t() | nil,
          revoked: boolean() | nil
        }

  defimpl Jason.Encoder do
    def encode(request, opts) do
      alias AppStoreServerLibrary.Models.{InAppOwnershipType, Order, ProductType}

      request
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {k, convert_value(k, v)} end)
      |> Map.new()
      |> JSON.keys_to_camel()
      |> Jason.Encode.map(opts)
    end

    defp convert_value(:product_types, types) do
      Enum.map(types, &ProductType.to_string/1)
    end

    defp convert_value(:sort, v) do
      Order.to_string(v)
    end

    defp convert_value(:in_app_ownership_type, v) do
      InAppOwnershipType.to_string(v)
    end

    defp convert_value(_k, v), do: v
  end
end
