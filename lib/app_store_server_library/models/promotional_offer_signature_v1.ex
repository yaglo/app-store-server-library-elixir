defmodule AppStoreServerLibrary.Models.PromotionalOfferSignatureV1 do
  @moduledoc """
  The promotional offer signature you generate using an earlier signature version.

  https://developer.apple.com/documentation/retentionmessaging/promotionaloffersignaturev1
  """

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          encoded_signature: String.t(),
          product_id: String.t(),
          nonce: String.t(),
          timestamp: integer(),
          key_id: String.t(),
          offer_identifier: String.t(),
          app_account_token: String.t() | nil
        }

  defstruct [
    :encoded_signature,
    :product_id,
    :nonce,
    :timestamp,
    :key_id,
    :offer_identifier,
    :app_account_token
  ]

  @doc """
  Creates a new PromotionalOfferSignatureV1 struct from a map or keyword list with
  camelCase or snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) or is_list(map) do
    map = map |> Map.new() |> JSON.keys_to_atoms()

    with :ok <-
           Validator.require_strings(map, [
             "encoded_signature",
             "product_id",
             "nonce",
             "key_id",
             "offer_identifier"
           ]),
         :ok <- Validator.require_integers(map, ["timestamp"]),
         :ok <- Validator.optional_fields(map, [{"app_account_token", :string}]) do
      {:ok, struct(__MODULE__, map)}
    end
  end

  @doc """
  Creates a new PromotionalOfferSignatureV1 struct.

  ## Parameters
  - encoded_signature: The Base64-encoded cryptographic signature
  - product_id: The subscription's product identifier
  - nonce: A one-time-use UUID antireplay value
  - timestamp: The UNIX time in milliseconds when the signature was generated
  - key_id: The private key identifier used to generate the signature
  - offer_identifier: The subscription offer identifier
  - app_account_token: Optional UUID to associate with the transaction
  """
  @spec new(
          String.t(),
          String.t(),
          String.t(),
          integer(),
          String.t(),
          String.t(),
          String.t() | nil
        ) ::
          t()
  def new(
        encoded_signature,
        product_id,
        nonce,
        timestamp,
        key_id,
        offer_identifier,
        app_account_token \\ nil
      ) do
    %__MODULE__{
      encoded_signature: encoded_signature,
      product_id: product_id,
      nonce: nonce,
      timestamp: timestamp,
      key_id: key_id,
      offer_identifier: offer_identifier,
      app_account_token: app_account_token
    }
  end

  @doc """
  Converts the struct to a map for JSON encoding with camelCase keys.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = sig) do
    base = %{
      "encodedSignature" => sig.encoded_signature,
      "productId" => sig.product_id,
      "nonce" => sig.nonce,
      "timestamp" => sig.timestamp,
      "keyId" => sig.key_id,
      "offerIdentifier" => sig.offer_identifier
    }

    if sig.app_account_token do
      Map.put(base, "appAccountToken", sig.app_account_token)
    else
      base
    end
  end

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
