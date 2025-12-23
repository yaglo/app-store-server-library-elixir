defmodule AppStoreServerLibrary.Models.AdvancedCommerceRenewalInfo do
  @moduledoc """
  Renewal information for an Advanced Commerce subscription.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalinfo
  """

  alias AppStoreServerLibrary.Models.{
    AdvancedCommerceDescriptors,
    AdvancedCommerceRenewalItem
  }

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          consistency_token: String.t() | nil,
          descriptors: AdvancedCommerceDescriptors.t() | nil,
          items: [AdvancedCommerceRenewalItem.t()] | nil,
          period: String.t() | nil,
          request_reference_id: String.t() | nil,
          tax_code: String.t() | nil
        }

  defstruct [
    :consistency_token,
    :descriptors,
    :items,
    :period,
    :request_reference_id,
    :tax_code
  ]

  @doc """
  Creates a new AdvancedCommerceRenewalInfo struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"consistency_token", :string},
             {"descriptors", :map},
             {"items", :list},
             {"period", :string},
             {"request_reference_id", :string},
             {"tax_code", :string}
           ]),
         {:ok, descriptors} <- build_descriptors(Map.get(map, :descriptors)),
         {:ok, items} <- build_items(Map.get(map, :items)) do
      {:ok,
       struct(__MODULE__, %{
         consistency_token: Map.get(map, :consistency_token),
         descriptors: descriptors,
         items: items,
         period: Map.get(map, :period),
         request_reference_id: Map.get(map, :request_reference_id),
         tax_code: Map.get(map, :tax_code)
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
      case AdvancedCommerceRenewalItem.new(item_map) do
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
