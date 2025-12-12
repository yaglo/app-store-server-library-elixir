defmodule AppStoreServerLibrary.Models.AlternateProduct do
  @moduledoc """
  A switch-plan message and product ID you provide in a real-time response to your Get Retention Message endpoint.

  https://developer.apple.com/documentation/retentionmessaging/alternateproduct
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          message_identifier: String.t() | nil,
          product_id: String.t() | nil
        }

  defstruct [:message_identifier, :product_id]

  @doc """
  Creates a new AlternateProduct struct.

  Accepts a map or keyword list with camelCase or snake_case keys and returns
  `{:ok, t()} | {:error, {atom(), String.t()}}` after validation.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <-
           Validator.optional_fields(map, [
             {"message_identifier", :string},
             {"product_id", :string}
           ]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = product) do
    %{}
    |> maybe_put("messageIdentifier", product.message_identifier)
    |> maybe_put("productId", product.product_id)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @doc """
  Creates a struct from a map with camelCase keys.
  """
  @spec from_json_map(map()) :: t()
  def from_json_map(map) do
    map
    |> JSON.keys_to_atoms()
    |> new()
    |> case do
      {:ok, struct} -> struct
      {:error, {_type, msg}} -> raise ArgumentError, msg
    end
  end
end
