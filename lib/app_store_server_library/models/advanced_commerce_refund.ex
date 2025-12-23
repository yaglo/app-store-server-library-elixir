defmodule AppStoreServerLibrary.Models.AdvancedCommerceRefund do
  @moduledoc """
  A refund for an Advanced Commerce subscription item.

  https://developer.apple.com/documentation/appstoreserverapi/advancedcommercerefund
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          refund_amount: integer() | nil,
          refund_date: integer() | nil,
          refund_reason: String.t() | nil,
          refund_type: String.t() | nil
        }

  defstruct [
    :refund_amount,
    :refund_date,
    :refund_reason,
    :refund_type
  ]

  @doc """
  Creates a new AdvancedCommerceRefund struct from a map.

  Accepts a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    map = normalize_keys(map)

    with :ok <-
           Validator.optional_fields(map, [
             {"refund_amount", :integer},
             {"refund_date", :integer},
             {"refund_reason", :string},
             {"refund_type", :string}
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
