defmodule AppStoreServerLibrary.Models.AdvancedCommercePriceIncreaseInfo do
  @moduledoc """
  Information about a price increase for an Advanced Commerce subscription.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercepriceincreaseinfo
  """

  alias AppStoreServerLibrary.Models.AdvancedCommercePriceIncreaseInfoStatus
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          dependent_skus: [String.t()] | nil,
          price: integer() | nil,
          status: AdvancedCommercePriceIncreaseInfoStatus.t() | nil,
          raw_status: String.t() | nil
        }

  defstruct [
    :dependent_skus,
    :price,
    :status,
    :raw_status
  ]

  @doc """
  Creates a new AdvancedCommercePriceIncreaseInfo struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"dependent_skus", :list},
             {"price", :integer},
             {"status", :atom_or_string},
             {"raw_status", :string}
           ]),
         :ok <- Validator.optional_string_list(map, "dependent_skus") do
      # Parse status enum, preserving raw string when provided
      {status, raw_status} = parse_status(Map.get(map, :status))

      {:ok,
       struct(__MODULE__, %{
         dependent_skus: Map.get(map, :dependent_skus),
         price: Map.get(map, :price),
         status: status,
         raw_status: raw_status
       })}
    end
  end

  defp parse_status(nil), do: {nil, nil}

  defp parse_status(status_str) when is_binary(status_str) do
    status_atom = AdvancedCommercePriceIncreaseInfoStatus.from_string(status_str)
    parsed_status = if is_atom(status_atom), do: status_atom, else: nil
    {parsed_status, status_str}
  end

  defp parse_status(status_atom) when is_atom(status_atom), do: {status_atom, nil}

  defp normalize_keys(map) do
    if map |> Map.keys() |> List.first() |> is_binary() do
      JSON.keys_to_atoms(map)
    else
      map
    end
  end
end
