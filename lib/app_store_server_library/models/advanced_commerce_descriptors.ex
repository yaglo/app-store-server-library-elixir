defmodule AppStoreServerLibrary.Models.AdvancedCommerceDescriptors do
  @moduledoc """
  Descriptors for an Advanced Commerce subscription.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercedescriptors
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          description: String.t() | nil,
          display_name: String.t() | nil
        }

  defstruct [
    :description,
    :display_name
  ]

  @doc """
  Creates a new AdvancedCommerceDescriptors struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"description", :string},
             {"display_name", :string}
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
