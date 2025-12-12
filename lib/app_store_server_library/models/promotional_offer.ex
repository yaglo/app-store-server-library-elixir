defmodule AppStoreServerLibrary.Models.PromotionalOffer do
  @moduledoc """
  A promotional offer and message you provide in a real-time response to your Get Retention Message endpoint.

  https://developer.apple.com/documentation/retentionmessaging/promotionaloffer
  """

  alias AppStoreServerLibrary.Models.PromotionalOfferSignatureV1
  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          message_identifier: String.t() | nil,
          promotional_offer_signature_v2: String.t() | nil,
          promotional_offer_signature_v1: PromotionalOfferSignatureV1.t() | nil
        }

  defstruct [
    :message_identifier,
    :promotional_offer_signature_v2,
    :promotional_offer_signature_v1
  ]

  @doc """
  Creates a new PromotionalOffer struct from a map or keyword list with camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    map =
      Map.update(map, :promotional_offer_signature_v1, nil, fn
        nil -> nil
        value when is_map(value) -> PromotionalOfferSignatureV1.from_json_map(value)
        value -> value
      end)

    with :ok <-
           Validator.optional_fields(map, [
             {"message_identifier", :string},
             {"promotional_offer_signature_v2", :string},
             {"promotional_offer_signature_v1", :map}
           ]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = offer) do
    %{}
    |> maybe_put("messageIdentifier", offer.message_identifier)
    |> maybe_put("promotionalOfferSignatureV2", offer.promotional_offer_signature_v2)
    |> maybe_put_nested(
      "promotionalOfferSignatureV1",
      offer.promotional_offer_signature_v1,
      &PromotionalOfferSignatureV1.to_json_map/1
    )
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_nested(map, _key, nil, _converter), do: map

  defp maybe_put_nested(map, key, value, converter),
    do: Map.put(map, key, converter.(value))

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
