defmodule AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator do
  @moduledoc """
  Creates signatures for promotional offer requests (V1).

  This module implements the original promotional offer signature format
  as documented in:
  https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/subscriptions_and_offers/generating_a_signature_for_promotional_offers

  The signature is created by concatenating specific fields with Unicode
  separator characters (\u2063) and signing the resulting string with ECDSA.
  """

  @enforce_keys [:signing_key, :key_id, :bundle_id]
  defstruct [:signing_key, :key_id, :bundle_id]

  @type t :: %__MODULE__{
          signing_key: String.t(),
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
  @spec new(options()) :: t()
  def new(opts) when is_list(opts) do
    %__MODULE__{
      signing_key: Keyword.fetch!(opts, :signing_key),
      key_id: Keyword.fetch!(opts, :key_id),
      bundle_id: Keyword.fetch!(opts, :bundle_id)
    }
  end

  @doc """
  Create a promotional offer signature.

  Returns the Base64 encoded signature.

  ## Parameters
  - product_identifier: The subscription product identifier
  - subscription_offer_id: The subscription discount identifier
  - application_username: An optional string value that you define; may be an empty string
  - nonce: A one-time UUID value that your server generates. Generate a new nonce for every signature.
  - timestamp: A timestamp your server generates in UNIX time format, in milliseconds. The timestamp keeps the offer active for 24 hours.

  ## Returns

    * `{:ok, signature}` on success
    * `{:error, reason}` on failure
  """
  @spec create_signature(t(), String.t(), String.t(), String.t(), String.t(), integer()) ::
          {:ok, String.t()} | {:error, term()}
  def create_signature(
        creator,
        product_identifier,
        subscription_offer_id,
        application_username,
        nonce,
        timestamp
      ) do
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

    private_key = load_private_key(creator.signing_key)
    payload_binary = :unicode.characters_to_binary(payload)

    signature = :public_key.sign(payload_binary, :sha256, private_key)

    {:ok, Base.encode64(signature)}
  rescue
    e in ArgumentError -> {:error, {:invalid_key, e.message}}
    e in ErlangError -> {:error, {:signing_error, inspect(e)}}
  end

  defp load_private_key(pem) do
    [entry | _] = :public_key.pem_decode(pem)
    :public_key.pem_entry_decode(entry)
  end
end
