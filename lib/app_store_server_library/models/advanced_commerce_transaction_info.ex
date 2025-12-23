defmodule AppStoreServerLibrary.Models.AdvancedCommerceTransactionInfo do
  @moduledoc """
  Transaction information for an Advanced Commerce subscription.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercetransactioninfo
  """

  alias AppStoreServerLibrary.Models.{
    AdvancedCommerceDescriptors,
    AdvancedCommerceTransactionItem
  }

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          descriptors: AdvancedCommerceDescriptors.t() | nil,
          estimated_tax: integer() | nil,
          items: [AdvancedCommerceTransactionItem.t()] | nil,
          period: String.t() | nil,
          request_reference_id: String.t() | nil,
          tax_code: String.t() | nil,
          tax_exclusive_price: integer() | nil,
          tax_rate: String.t() | nil
        }

  defstruct [
    :descriptors,
    :estimated_tax,
    :items,
    :period,
    :request_reference_id,
    :tax_code,
    :tax_exclusive_price,
    :tax_rate
  ]

  @doc """
  Creates a new AdvancedCommerceTransactionInfo struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"descriptors", :map},
             {"estimated_tax", :integer},
             {"items", :list},
             {"period", :string},
             {"request_reference_id", :string},
             {"tax_code", :string},
             {"tax_exclusive_price", :integer},
             {"tax_rate", :string}
           ]),
         {:ok, descriptors} <- build_descriptors(Map.get(map, :descriptors)),
         {:ok, items} <- build_items(Map.get(map, :items)) do
      {:ok,
       struct(__MODULE__, %{
         descriptors: descriptors,
         estimated_tax: Map.get(map, :estimated_tax),
         items: items,
         period: Map.get(map, :period),
         request_reference_id: Map.get(map, :request_reference_id),
         tax_code: Map.get(map, :tax_code),
         tax_exclusive_price: Map.get(map, :tax_exclusive_price),
         tax_rate: Map.get(map, :tax_rate)
       })}
    end
  end

  defp build_descriptors(nil), do: {:ok, nil}

  defp build_descriptors(%{} = descriptors_map) do
    case AdvancedCommerceDescriptors.new(descriptors_map) do
      {:ok, descriptors} -> {:ok, descriptors}
      {:error, _} = err -> err
    end
  end

  defp build_descriptors(_),
    do: {:error, {:verification_failure, "Invalid map field: descriptors"}}

  defp build_items(nil), do: {:ok, nil}

  defp build_items(items_list) when is_list(items_list) do
    items_list
    |> Enum.reduce_while({:ok, []}, fn item_map, {:ok, acc} ->
      case AdvancedCommerceTransactionItem.new(item_map) do
        {:ok, item} -> {:cont, {:ok, [item | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, items} -> {:ok, Enum.reverse(items)}
      error -> error
    end
  end

  defp build_items(_), do: {:error, {:verification_failure, "Invalid list field: items"}}

  defp normalize_keys(map) do
    if map |> Map.keys() |> List.first() |> is_binary() do
      JSON.keys_to_atoms(map)
    else
      map
    end
  end
end
