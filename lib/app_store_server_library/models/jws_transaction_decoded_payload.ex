# credo:disable-for-this-file Credo.Check.Warning.StructFieldAmount
defmodule AppStoreServerLibrary.Models.JWSTransactionDecodedPayload do
  @moduledoc """
  A decoded payload containing transaction information.

  https://developer.apple.com/documentation/appstoreserverapi/jwstransactiondecodedpayload
  """

  alias AppStoreServerLibrary.Models.{
    AdvancedCommerceTransactionInfo,
    Environment,
    InAppOwnershipType,
    OfferDiscountType,
    OfferType,
    RevocationReason,
    RevocationType,
    TransactionReason,
    Type
  }

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          original_transaction_id: String.t() | nil,
          transaction_id: String.t() | nil,
          web_order_line_item_id: String.t() | nil,
          bundle_id: String.t() | nil,
          product_id: String.t() | nil,
          subscription_group_identifier: String.t() | nil,
          purchase_date: integer() | nil,
          original_purchase_date: integer() | nil,
          expires_date: integer() | nil,
          quantity: integer() | nil,
          type: Type.t() | nil,
          raw_type: String.t() | nil,
          app_account_token: String.t() | nil,
          in_app_ownership_type: InAppOwnershipType.t() | nil,
          raw_in_app_ownership_type: String.t() | nil,
          signed_date: integer() | nil,
          revocation_reason: RevocationReason.t() | nil,
          raw_revocation_reason: integer() | nil,
          revocation_date: integer() | nil,
          revocation_type: RevocationType.t() | nil,
          raw_revocation_type: String.t() | nil,
          revocation_percentage: integer() | nil,
          is_upgraded: boolean() | nil,
          offer_type: OfferType.t() | nil,
          raw_offer_type: integer() | nil,
          offer_identifier: String.t() | nil,
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          storefront: String.t() | nil,
          storefront_id: String.t() | nil,
          transaction_reason: TransactionReason.t() | nil,
          raw_transaction_reason: String.t() | nil,
          currency: String.t() | nil,
          price: integer() | nil,
          offer_discount_type: OfferDiscountType.t() | nil,
          raw_offer_discount_type: String.t() | nil,
          app_transaction_id: String.t() | nil,
          offer_period: String.t() | nil,
          advanced_commerce_info: AdvancedCommerceTransactionInfo.t() | nil,
          previous_original_transaction_id: String.t() | nil
        }

  defstruct [
    :original_transaction_id,
    :transaction_id,
    :web_order_line_item_id,
    :bundle_id,
    :product_id,
    :subscription_group_identifier,
    :purchase_date,
    :original_purchase_date,
    :expires_date,
    :quantity,
    :type,
    :raw_type,
    :app_account_token,
    :in_app_ownership_type,
    :raw_in_app_ownership_type,
    :signed_date,
    :revocation_reason,
    :raw_revocation_reason,
    :revocation_date,
    :revocation_type,
    :raw_revocation_type,
    :revocation_percentage,
    :is_upgraded,
    :offer_type,
    :raw_offer_type,
    :offer_identifier,
    :environment,
    :raw_environment,
    :storefront,
    :storefront_id,
    :transaction_reason,
    :raw_transaction_reason,
    :currency,
    :price,
    :offer_discount_type,
    :raw_offer_discount_type,
    :app_transaction_id,
    :offer_period,
    :advanced_commerce_info,
    :previous_original_transaction_id
  ]

  @type_allowed [
    :auto_renewable_subscription,
    :non_consumable,
    :consumable,
    :non_renewing_subscription,
    "Auto-Renewable Subscription",
    "Non-Consumable",
    "Consumable",
    "Non-Renewing Subscription"
  ]

  @in_app_ownership_allowed [:family_shared, :purchased, "FAMILY_SHARED", "PURCHASED"]

  @transaction_reason_allowed [:purchase, :renewal, "PURCHASE", "RENEWAL"]

  @offer_discount_allowed [
    :free_trial,
    :pay_as_you_go,
    :pay_up_front,
    :one_time,
    "FREE_TRIAL",
    "PAY_AS_YOU_GO",
    "PAY_UP_FRONT",
    "ONE_TIME"
  ]

  @revocation_type_allowed [
    :refund_full,
    :refund_prorated,
    :family_revoke,
    "REFUND_FULL",
    "REFUND_PRORATED",
    "FAMILY_REVOKE"
  ]

  @revocation_allowed_ints [0, 1]
  @offer_type_allowed_ints [1, 2, 3, 4]

  @doc """
  Builds a transaction payload from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"original_transaction_id", :string},
             {"transaction_id", :string},
             {"web_order_line_item_id", :string},
             {"bundle_id", :string},
             {"product_id", :string},
             {"subscription_group_identifier", :string},
             {"purchase_date", :number},
             {"original_purchase_date", :number},
             {"expires_date", :number},
             {"quantity", :number},
             {"type", :atom_or_string},
             {"raw_type", :string},
             {"app_account_token", :string},
             {"in_app_ownership_type", :atom_or_string},
             {"raw_in_app_ownership_type", :string},
             {"signed_date", :number},
             {"revocation_reason", :integer},
             {"raw_revocation_reason", :integer},
             {"revocation_date", :number},
             {"revocation_type", :atom_or_string},
             {"raw_revocation_type", :string},
             {"revocation_percentage", :number},
             {"is_upgraded", :boolean},
             {"offer_type", :integer},
             {"raw_offer_type", :integer},
             {"offer_identifier", :string},
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"storefront", :string},
             {"storefront_id", :string},
             {"transaction_reason", :atom_or_string},
             {"raw_transaction_reason", :string},
             {"currency", :string},
             {"price", :number},
             {"offer_discount_type", :atom_or_string},
             {"raw_offer_discount_type", :string},
             {"app_transaction_id", :string},
             {"offer_period", :string},
             {"previous_original_transaction_id", :string}
           ]),
         :ok <- Validator.optional_enum(map, "type", @type_allowed),
         :ok <- Validator.optional_enum(map, "in_app_ownership_type", @in_app_ownership_allowed),
         :ok <- Validator.optional_enum(map, "transaction_reason", @transaction_reason_allowed),
         :ok <- Validator.optional_enum(map, "offer_discount_type", @offer_discount_allowed),
         :ok <- Validator.optional_enum(map, "environment", Environment.allowed_values()),
         :ok <- Validator.optional_enum(map, "revocation_type", @revocation_type_allowed),
         :ok <-
           Validator.optional_integer_domain(
             map,
             "raw_revocation_reason",
             @revocation_allowed_ints
           ),
         {:ok, map} <-
           Validator.optional_integer_enum(
             map,
             "revocation_reason",
             @revocation_allowed_ints,
             RevocationReason
           ),
         :ok <-
           Validator.optional_integer_domain(map, "raw_offer_type", @offer_type_allowed_ints),
         {:ok, map} <-
           Validator.optional_integer_enum(
             map,
             "offer_type",
             @offer_type_allowed_ints,
             OfferType
           ),
         {:ok, map_with_parsed_fields} <- parse_advanced_commerce_info(map) do
      {:ok, struct(__MODULE__, map_with_parsed_fields)}
    end
  end

  defp parse_advanced_commerce_info(map) do
    case Map.get(map, :advanced_commerce_info) do
      nil ->
        {:ok, map}

      info when is_map(info) ->
        case AdvancedCommerceTransactionInfo.new(info) do
          {:ok, parsed} -> {:ok, Map.put(map, :advanced_commerce_info, parsed)}
          {:error, _} = error -> error
        end

      _other ->
        {:error, {:verification_failure, "advanced_commerce_info must be a map"}}
    end
  end
end
