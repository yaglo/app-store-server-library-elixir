defmodule AppStoreServerLibrary.Signature.JWSSignatureCreator do
  @moduledoc """
  Creates JWS signatures for App Store requests.

  This module provides functionality to create signed JSON Web Tokens (JWS)
  for various App Store API operations including promotional offers,
  introductory offer eligibility, and Advanced Commerce API requests.

  ## Usage

      {:ok, creator} = JWSSignatureCreator.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app"
      )

      # Create promotional offer V2 signature
      signature = JWSSignatureCreator.create_promotional_offer_v2_signature(
        creator,
        "product_id",
        "offer_identifier",
        "transaction_id"
      )

      # Create introductory offer eligibility signature
      signature = JWSSignatureCreator.create_introductory_offer_eligibility_signature(
        creator,
        "product_id",
        true,
        "transaction_id"
      )

  """

  @enforce_keys [:signing_key, :key_id, :issuer_id, :bundle_id]
  defstruct [:signing_key, :key_id, :issuer_id, :bundle_id]

  @type t :: %__MODULE__{
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        }

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        ]

  @doc """
  Create a new JWSSignatureCreator.

  ## Options

    * `:signing_key` - Your private key from App Store Connect (PEM format) - **required**
    * `:key_id` - Your private key ID from App Store Connect - **required**
    * `:issuer_id` - Your issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle ID - **required**

  ## Returns

    * `{:ok, t()}` on success
    * `{:error, :invalid_pem}` if the signing key is not a valid PEM

  """
  @spec new(options()) :: {:ok, t()} | {:error, :invalid_pem}
  def new(opts) when is_list(opts) do
    signing_key = Keyword.fetch!(opts, :signing_key)

    with :ok <- validate_pem(signing_key) do
      {:ok,
       %__MODULE__{
         signing_key: signing_key,
         key_id: Keyword.fetch!(opts, :key_id),
         issuer_id: Keyword.fetch!(opts, :issuer_id),
         bundle_id: Keyword.fetch!(opts, :bundle_id)
       }}
    end
  end

  @doc """
  Create a promotional offer V2 signature.

  ## Parameters

    * `creator` - The JWSSignatureCreator struct
    * `product_id` - The unique identifier of product
    * `offer_identifier` - The promotional offer identifier from App Store Connect
    * `transaction_id` - The unique identifier of any transaction that belongs to customer (optional)

  ## Returns

  The signed JWT string.

  See: https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """
  @spec create_promotional_offer_v2_signature(t(), String.t(), String.t(), String.t() | nil) ::
          String.t()
  def create_promotional_offer_v2_signature(
        %__MODULE__{} = creator,
        product_id,
        offer_identifier,
        transaction_id \\ nil
      )
      when is_binary(product_id) and is_binary(offer_identifier) do
    claims = %{
      "productId" => product_id,
      "offerIdentifier" => offer_identifier
    }

    claims =
      if transaction_id do
        Map.put(claims, "transactionId", transaction_id)
      else
        claims
      end

    create_signature(creator, "promotional-offer", claims)
  end

  @doc """
  Create an introductory offer eligibility signature.

  ## Parameters

    * `creator` - The JWSSignatureCreator struct
    * `product_id` - The unique identifier of product
    * `allow_introductory_offer` - Whether customer is eligible for an introductory offer
    * `transaction_id` - The unique identifier of any transaction that belongs to customer

  ## Returns

  The signed JWT string.

  See: https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """
  @spec create_introductory_offer_eligibility_signature(t(), String.t(), boolean(), String.t()) ::
          String.t()
  def create_introductory_offer_eligibility_signature(
        %__MODULE__{} = creator,
        product_id,
        allow_introductory_offer,
        transaction_id
      )
      when is_binary(product_id) and is_boolean(allow_introductory_offer) and
             is_binary(transaction_id) do
    claims = %{
      "productId" => product_id,
      "allowIntroductoryOffer" => allow_introductory_offer,
      "transactionId" => transaction_id
    }

    create_signature(creator, "introductory-offer-eligibility", claims)
  end

  @doc """
  Create an Advanced Commerce API in-app signed request.

  ## Parameters

    * `creator` - The JWSSignatureCreator struct
    * `request_map` - A map representing the request

  ## Returns

  The signed JWT string.

  See: https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """
  @spec create_advanced_commerce_signature(t(), map()) :: String.t()
  def create_advanced_commerce_signature(%__MODULE__{} = creator, request_map)
      when is_map(request_map) do
    request_json = Jason.encode!(request_map)
    encoded_request = Base.encode64(request_json)

    claims = %{"request" => encoded_request}

    create_signature(creator, "advanced-commerce-api", claims)
  end

  # Private: validates that the PEM can be decoded
  defp validate_pem(pem) do
    case :public_key.pem_decode(pem) do
      [_ | _] -> :ok
      [] -> {:error, :invalid_pem}
    end
  catch
    _, _ -> {:error, :invalid_pem}
  end

  # Private: creates a signed JWT with the given audience and claims
  defp create_signature(creator, audience, feature_claims) do
    # UUID.uuid4() generates a cryptographically secure random UUID v4.
    # This provides 122 bits of randomness from :crypto.strong_rand_bytes/1,
    # which is sufficient for nonce uniqueness and replay attack prevention.
    claims =
      Map.merge(feature_claims, %{
        "bid" => creator.bundle_id,
        "iss" => creator.issuer_id,
        "aud" => audience,
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "nonce" => UUID.uuid4()
      })

    jwk = JOSE.JWK.from_pem(creator.signing_key)
    jws_fields = %{"alg" => "ES256", "kid" => creator.key_id}

    signed = JOSE.JWT.sign(jwk, jws_fields, claims)
    {_, signed_jwt} = JOSE.JWS.compact(signed)

    signed_jwt
  end
end
