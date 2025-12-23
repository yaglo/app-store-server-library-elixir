defmodule AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator do
  @moduledoc """
  Creates signatures for promotional offer requests (V1).

  This module implements the original promotional offer signature format
  as documented in:
  https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/subscriptions_and_offers/generating_a_signature_for_promotional_offers

  The signature is created by concatenating specific fields with Unicode
  separator characters (\\u2063) and signing the resulting string with ECDSA.
  """

  @enforce_keys [:decoded_key, :key_id, :bundle_id]
  defstruct [:decoded_key, :key_id, :bundle_id]

  @type t :: %__MODULE__{
          decoded_key: any(),
          key_id: String.t(),
          bundle_id: String.t()
        }

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          bundle_id: String.t()
        ]

  @doc """
  Create a new PromotionalOfferSignatureCreator.

  ## Options

    * `:signing_key` - Your private key from App Store Connect (PEM format) - **required**
    * `:key_id` - Your private key ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle ID - **required**

  ## Examples

      creator = PromotionalOfferSignatureCreator.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        bundle_id: "com.example.app"
      )

  """
  @spec new(options()) :: {:ok, t()} | {:error, :invalid_pem}
  def new(opts) when is_list(opts) do
    with {:ok, decoded_key} <- load_private_key(Keyword.fetch!(opts, :signing_key)) do
      {:ok,
       %__MODULE__{
         decoded_key: decoded_key,
         key_id: Keyword.fetch!(opts, :key_id),
         bundle_id: Keyword.fetch!(opts, :bundle_id)
       }}
    end
  end

  @doc """
  Create a promotional offer signature.

  ## Parameters

    * `creator` - The PromotionalOfferSignatureCreator struct
    * `product_identifier` - The subscription product identifier
    * `subscription_offer_id` - The subscription discount identifier
    * `application_username` - An optional string value that you define; may be an empty string
    * `nonce` - A one-time UUID value that your server generates
    * `timestamp` - A timestamp in UNIX time format, in milliseconds (must be positive)

  ## Returns

    * `{:ok, signature}` - The Base64 encoded signature string
    * `{:error, {:invalid_timestamp, message}}` - If timestamp is not a positive integer

  """
  @spec create_signature(t(), String.t(), String.t(), String.t(), String.t(), integer()) ::
          {:ok, String.t()} | {:error, {:invalid_timestamp, String.t()}}
  def create_signature(
        %__MODULE__{} = creator,
        product_identifier,
        subscription_offer_id,
        application_username,
        nonce,
        timestamp
      )
      when is_binary(product_identifier) and is_binary(subscription_offer_id) and
             is_binary(application_username) and is_binary(nonce) and is_integer(timestamp) and
             timestamp > 0 do
    # Build the payload with Unicode separator \u2063
    payload =
      creator.bundle_id <>
        "\u2063" <>
        creator.key_id <>
        "\u2063" <>
        product_identifier <>
        "\u2063" <>
        subscription_offer_id <>
        "\u2063" <>
        String.downcase(application_username) <>
        "\u2063" <>
        String.downcase(nonce) <>
        "\u2063" <>
        to_string(timestamp)

    payload_binary = :unicode.characters_to_binary(payload)

    signature = :public_key.sign(payload_binary, :sha256, creator.decoded_key)

    {:ok, Base.encode64(signature)}
  end

  def create_signature(
        %__MODULE__{},
        product_identifier,
        subscription_offer_id,
        application_username,
        nonce,
        timestamp
      )
      when is_binary(product_identifier) and is_binary(subscription_offer_id) and
             is_binary(application_username) and is_binary(nonce) and is_integer(timestamp) do
    {:error, {:invalid_timestamp, "Timestamp must be a positive integer"}}
  end

  defp load_private_key(pem) do
    [entry | _] = :public_key.pem_decode(pem)
    {:ok, :public_key.pem_entry_decode(entry)}
  rescue
    MatchError -> {:error, :invalid_pem}
    ArgumentError -> {:error, :invalid_pem}
  end
end
