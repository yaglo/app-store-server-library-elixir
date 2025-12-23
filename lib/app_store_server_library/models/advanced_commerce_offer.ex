defmodule AppStoreServerLibrary.Models.AdvancedCommerceOffer do
  @moduledoc """
  An offer for an Advanced Commerce subscription item.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommerceoffer
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          period: String.t() | nil,
          period_count: integer() | nil,
          price: integer() | nil,
          reason: String.t() | nil
        }

  defstruct [
    :period,
    :period_count,
    :price,
    :reason
  ]

  @doc """
  Creates a new AdvancedCommerceOffer struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"period", :string},
             {"period_count", :integer},
             {"price", :integer},
             {"reason", :string}
           ]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  defp normalize_keys(map) do
    if map |> Map.keys() |> List.first() |> is_binary() do
      JSON.keys_to_atoms(map)
    else
      map
    end
  end
end
