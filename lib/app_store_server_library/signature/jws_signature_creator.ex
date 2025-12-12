defmodule AppStoreServerLibrary.Signature.JWSSignatureCreator do
  @moduledoc """
  Base module for creating JWS signatures for App Store requests.

  This module provides functionality to create signed JSON Web Tokens (JWS)
  for various App Store API operations including promotional offers and
  introductory offer eligibility checks.
  """

  @enforce_keys [:audience, :signing_key, :key_id, :issuer_id, :bundle_id]
  defstruct [:audience, :signing_key, :key_id, :issuer_id, :bundle_id]

  @type t :: %__MODULE__{
          audience: String.t(),
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        }

  @doc false
  @spec new(String.t(), String.t(), String.t(), String.t(), String.t()) :: t()
  def new(audience, signing_key, key_id, issuer_id, bundle_id) do
    %__MODULE__{
      audience: audience,
      signing_key: signing_key,
      key_id: key_id,
      issuer_id: issuer_id,
      bundle_id: bundle_id
    }
  end

  @doc """
  Create a signature with feature-specific claims.
  """
  @spec create_signature(t(), map()) :: {:ok, String.t()} | {:error, term()}
  def create_signature(creator, feature_specific_claims) do
    claims =
      Map.merge(feature_specific_claims, %{
        "bid" => creator.bundle_id,
        "iss" => creator.issuer_id,
        "aud" => creator.audience,
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "nonce" => UUID.uuid4()
      })

    # Create JWK from private key
    jwk = JOSE.JWK.from_pem(creator.signing_key)

    # Create JWS fields with alg and kid
    jws_fields = %{"alg" => "ES256", "kid" => creator.key_id}

    # Sign the JWT
    signed = JOSE.JWT.sign(jwk, jws_fields, claims)
    {_, signed_jwt} = JOSE.JWS.compact(signed)

    {:ok, signed_jwt}
  end
end

defmodule AppStoreServerLibrary.Signature.PromotionalOfferV2SignatureCreator do
  @moduledoc """
  Creates signatures for promotional offer V2 requests.

  https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """

  alias AppStoreServerLibrary.Signature.JWSSignatureCreator

  defstruct [:creator]

  @type t :: %__MODULE__{creator: JWSSignatureCreator.t()}

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        ]

  @doc """
  Create a new PromotionalOfferV2SignatureCreator.

  ## Options

    * `:signing_key` - Your private key from App Store Connect (PEM format) - **required**
    * `:key_id` - Your private key ID from App Store Connect - **required**
    * `:issuer_id` - Your issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle ID - **required**

  ## Examples

      creator = PromotionalOfferV2SignatureCreator.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app"
      )

  """
  @spec new(options()) :: t()
  def new(opts) when is_list(opts) do
    signing_key = Keyword.fetch!(opts, :signing_key)
    key_id = Keyword.fetch!(opts, :key_id)
    issuer_id = Keyword.fetch!(opts, :issuer_id)
    bundle_id = Keyword.fetch!(opts, :bundle_id)

    creator =
      JWSSignatureCreator.new("promotional-offer", signing_key, key_id, issuer_id, bundle_id)

    %__MODULE__{creator: creator}
  end

  @doc """
  Create a promotional offer V2 signature.

  ## Parameters

    * `product_id` - The unique identifier of product
    * `offer_identifier` - The promotional offer identifier from App Store Connect
    * `transaction_id` - The unique identifier of any transaction that belongs to customer (optional)

  ## Returns

    * `{:ok, signature}` on success
    * `{:error, reason}` on failure

  """
  @spec create_signature(t(), String.t(), String.t(), String.t() | nil) ::
          {:ok, String.t()} | {:error, term()}
  def create_signature(creator, product_id, offer_identifier, transaction_id \\ nil) do
    if is_nil(product_id), do: raise(ArgumentError, "product_id cannot be nil")
    if is_nil(offer_identifier), do: raise(ArgumentError, "offer_identifier cannot be nil")

    feature_claims =
      %{"productId" => product_id, "offerIdentifier" => offer_identifier}
      |> then(fn claims ->
        if transaction_id, do: Map.put(claims, "transactionId", transaction_id), else: claims
      end)

    JWSSignatureCreator.create_signature(creator.creator, feature_claims)
  end
end

defmodule AppStoreServerLibrary.Signature.IntroductoryOfferEligibilitySignatureCreator do
  @moduledoc """
  Creates signatures for introductory offer eligibility requests.

  https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """

  alias AppStoreServerLibrary.Signature.JWSSignatureCreator

  defstruct [:creator]

  @type t :: %__MODULE__{creator: JWSSignatureCreator.t()}

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        ]

  @doc """
  Create a new IntroductoryOfferEligibilitySignatureCreator.

  ## Options

    * `:signing_key` - Your private key from App Store Connect (PEM format) - **required**
    * `:key_id` - Your private key ID from App Store Connect - **required**
    * `:issuer_id` - Your issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle ID - **required**

  """
  @spec new(options()) :: t()
  def new(opts) when is_list(opts) do
    signing_key = Keyword.fetch!(opts, :signing_key)
    key_id = Keyword.fetch!(opts, :key_id)
    issuer_id = Keyword.fetch!(opts, :issuer_id)
    bundle_id = Keyword.fetch!(opts, :bundle_id)

    creator =
      JWSSignatureCreator.new(
        "introductory-offer-eligibility",
        signing_key,
        key_id,
        issuer_id,
        bundle_id
      )

    %__MODULE__{creator: creator}
  end

  @doc """
  Create an introductory offer eligibility signature.

  ## Parameters

    * `product_id` - The unique identifier of product
    * `allow_introductory_offer` - Whether customer is eligible for an introductory offer
    * `transaction_id` - The unique identifier of any transaction that belongs to customer

  ## Returns

    * `{:ok, signature}` on success
    * `{:error, reason}` on failure

  """
  @spec create_signature(t(), String.t(), boolean(), String.t()) ::
          {:ok, String.t()} | {:error, term()}
  def create_signature(creator, product_id, allow_introductory_offer, transaction_id) do
    if is_nil(product_id), do: raise(ArgumentError, "product_id cannot be nil")

    if is_nil(allow_introductory_offer),
      do: raise(ArgumentError, "allow_introductory_offer cannot be nil")

    if is_nil(transaction_id), do: raise(ArgumentError, "transaction_id cannot be nil")

    feature_claims = %{
      "productId" => product_id,
      "allowIntroductoryOffer" => allow_introductory_offer,
      "transactionId" => transaction_id
    }

    JWSSignatureCreator.create_signature(creator.creator, feature_claims)
  end
end

defmodule AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppSignatureCreator do
  @moduledoc """
  Creates signatures for Advanced Commerce API in-app requests.

  https://developer.apple.com/documentation/storekit/generating-jws-to-sign-app-store-requests
  """

  alias AppStoreServerLibrary.Signature.JWSSignatureCreator

  defstruct [:creator]

  @type t :: %__MODULE__{creator: JWSSignatureCreator.t()}

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t()
        ]

  @doc """
  Create a new AdvancedCommerceAPIInAppSignatureCreator.

  ## Options

    * `:signing_key` - Your private key from App Store Connect (PEM format) - **required**
    * `:key_id` - Your private key ID from App Store Connect - **required**
    * `:issuer_id` - Your issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle ID - **required**

  """
  @spec new(options()) :: t()
  def new(opts) when is_list(opts) do
    signing_key = Keyword.fetch!(opts, :signing_key)
    key_id = Keyword.fetch!(opts, :key_id)
    issuer_id = Keyword.fetch!(opts, :issuer_id)
    bundle_id = Keyword.fetch!(opts, :bundle_id)

    creator =
      JWSSignatureCreator.new("advanced-commerce-api", signing_key, key_id, issuer_id, bundle_id)

    %__MODULE__{creator: creator}
  end

  @doc """
  Create an Advanced Commerce in-app signed request.

  ## Parameters

    * `advanced_commerce_in_app_request` - The request to be signed

  ## Returns

    * `{:ok, signature}` on success
    * `{:error, reason}` on failure

  """
  @spec create_signature(t(), map()) :: {:ok, String.t()} | {:error, term()}
  def create_signature(creator, advanced_commerce_in_app_request) do
    if is_nil(advanced_commerce_in_app_request) do
      raise ArgumentError, "advanced_commerce_in_app_request cannot be nil"
    end

    # Convert request to JSON and base64 encode
    request_map =
      try do
        advanced_commerce_in_app_request.__struct__.to_map(advanced_commerce_in_app_request)
      rescue
        UndefinedFunctionError -> advanced_commerce_in_app_request
      end

    request_json = Jason.encode!(request_map)
    encoded_request = Base.encode64(request_json)

    feature_claims = %{"request" => encoded_request}

    JWSSignatureCreator.create_signature(creator.creator, feature_claims)
  end
end
