defmodule AppStoreServerLibrary.Models.RealtimeResponseBody do
  @moduledoc """
  A response you provide to choose, in real time, a retention message the system displays to the customer.

  https://developer.apple.com/documentation/retentionmessaging/realtimeresponsebody
  """

  alias AppStoreServerLibrary.Models.{AlternateProduct, Message, PromotionalOffer}
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          message: Message.t() | nil,
          alternate_product: AlternateProduct.t() | nil,
          promotional_offer: PromotionalOffer.t() | nil
        }

  defstruct [:message, :alternate_product, :promotional_offer]

  @doc """
  Creates a new RealtimeResponseBody struct from a map with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    map =
      map
      |> Map.update(:message, nil, fn
        nil -> nil
        value when is_map(value) -> Message.from_json_map(value)
        value -> value
      end)
      |> Map.update(:alternate_product, nil, fn
        nil -> nil
        value when is_map(value) -> AlternateProduct.from_json_map(value)
        value -> value
      end)
      |> Map.update(:promotional_offer, nil, fn
        nil -> nil
        value when is_map(value) -> PromotionalOffer.from_json_map(value)
        value -> value
      end)

    with :ok <-
           Validator.optional_fields(map, [
             {"message", :map},
             {"alternate_product", :map},
             {"promotional_offer", :map}
           ]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = response) do
    %{}
    |> maybe_put_nested("message", response.message, &Message.to_json_map/1)
    |> maybe_put_nested(
      "alternateProduct",
      response.alternate_product,
      &AlternateProduct.to_json_map/1
    )
    |> maybe_put_nested(
      "promotionalOffer",
      response.promotional_offer,
      &PromotionalOffer.to_json_map/1
    )
  end

  defp maybe_put_nested(map, _key, nil, _converter), do: map
  defp maybe_put_nested(map, key, value, converter), do: Map.put(map, key, converter.(value))

  @doc """
  Creates a struct from a map with camelCase keys.
  """
  @spec from_json_map(map()) :: t()
  def from_json_map(map) do
    map
    |> new()
    |> case do
      {:ok, struct} -> struct
      {:error, {_type, msg}} -> raise ArgumentError, msg
    end
  end
end
