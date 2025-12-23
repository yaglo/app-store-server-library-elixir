defmodule AppStoreServerLibrary.Models.AdvancedCommerceRenewalItem do
  @moduledoc """
  An Advanced Commerce renewal item.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerenewalitem
  """

  alias AppStoreServerLibrary.Models.{AdvancedCommerceOffer, AdvancedCommercePriceIncreaseInfo}
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          sku: String.t() | nil,
          description: String.t() | nil,
          display_name: String.t() | nil,
          offer: AdvancedCommerceOffer.t() | nil,
          price: integer() | nil,
          price_increase_info: AdvancedCommercePriceIncreaseInfo.t() | nil
        }

  defstruct [
    :sku,
    :description,
    :display_name,
    :offer,
    :price,
    :price_increase_info
  ]

  @doc """
  Creates a new AdvancedCommerceRenewalItem struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"sku", :string},
             {"description", :string},
             {"display_name", :string},
             {"offer", :map},
             {"price", :integer},
             {"price_increase_info", :map}
           ]),
         {:ok, offer} <- build_offer(Map.get(map, :offer)),
         {:ok, price_increase_info} <-
           build_price_increase_info(Map.get(map, :price_increase_info)) do
      {:ok,
       struct(__MODULE__, %{
         sku: Map.get(map, :sku),
         description: Map.get(map, :description),
         display_name: Map.get(map, :display_name),
         offer: offer,
         price: Map.get(map, :price),
         price_increase_info: price_increase_info
       })}
    end
  end

  defp build_offer(nil), do: {:ok, nil}

  defp build_offer(%{} = offer_map) do
    case AdvancedCommerceOffer.new(offer_map) do
      {:ok, offer} -> {:ok, offer}
      {:error, _} = err -> err
    end
  end

  defp build_offer(_), do: {:error, {:verification_failure, "Invalid map field: offer"}}

  defp build_price_increase_info(nil), do: {:ok, nil}

  defp build_price_increase_info(%{} = info_map) do
    case AdvancedCommercePriceIncreaseInfo.new(info_map) do
      {:ok, info} -> {:ok, info}
      {:error, _} = err -> err
    end
  end

  defp build_price_increase_info(_),
    do: {:error, {:verification_failure, "Invalid map field: price_increase_info"}}

  defp normalize_keys(map) do
    if map |> Map.keys() |> List.first() |> is_binary() do
      JSON.keys_to_atoms(map)
    else
      map
    end
  end
end
