defmodule AppStoreServerLibrary.Models.JWSRenewalInfoDecodedPayload do
  @moduledoc """
  A decoded payload containing subscription renewal information for an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/jwsrenewalinfodecodedpayload
  """

  alias AppStoreServerLibrary.Models.{
    AutoRenewStatus,
    Environment,
    ExpirationIntent,
    OfferDiscountType,
    OfferType,
    PriceIncreaseStatus
  }

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          expiration_intent: ExpirationIntent.t() | nil,
          raw_expiration_intent: integer() | nil,
          original_transaction_id: String.t() | nil,
          auto_renew_product_id: String.t() | nil,
          product_id: String.t() | nil,
          auto_renew_status: AutoRenewStatus.t() | nil,
          raw_auto_renew_status: integer() | nil,
          is_in_billing_retry_period: boolean() | nil,
          price_increase_status: PriceIncreaseStatus.t() | nil,
          raw_price_increase_status: integer() | nil,
          grace_period_expires_date: integer() | nil,
          offer_type: OfferType.t() | nil,
          raw_offer_type: integer() | nil,
          offer_identifier: String.t() | nil,
          signed_date: integer() | nil,
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          recent_subscription_start_date: integer() | nil,
          renewal_date: integer() | nil,
          currency: String.t() | nil,
          renewal_price: integer() | nil,
          offer_discount_type: OfferDiscountType.t() | nil,
          raw_offer_discount_type: String.t() | nil,
          eligible_win_back_offer_ids: [String.t()] | nil,
          app_account_token: String.t() | nil,
          app_transaction_id: String.t() | nil,
          offer_period: String.t() | nil
        }

  defstruct [
    :expiration_intent,
    :raw_expiration_intent,
    :original_transaction_id,
    :auto_renew_product_id,
    :product_id,
    :auto_renew_status,
    :raw_auto_renew_status,
    :is_in_billing_retry_period,
    :price_increase_status,
    :raw_price_increase_status,
    :grace_period_expires_date,
    :offer_type,
    :raw_offer_type,
    :offer_identifier,
    :signed_date,
    :environment,
    :raw_environment,
    :recent_subscription_start_date,
    :renewal_date,
    :currency,
    :renewal_price,
    :offer_discount_type,
    :raw_offer_discount_type,
    :eligible_win_back_offer_ids,
    :app_account_token,
    :app_transaction_id,
    :offer_period
  ]

  @expiration_intent_allowed [1, 2, 3, 4, 5]
  @auto_renew_status_allowed [0, 1]
  @price_increase_status_allowed [0, 1]
  @offer_type_allowed_ints [1, 2, 3, 4]

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

  @doc """
  Builds a renewal info payload from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"expiration_intent", :number},
             {"raw_expiration_intent", :integer},
             {"original_transaction_id", :string},
             {"auto_renew_product_id", :string},
             {"product_id", :string},
             {"auto_renew_status", :number},
             {"raw_auto_renew_status", :integer},
             {"is_in_billing_retry_period", :boolean},
             {"price_increase_status", :number},
             {"raw_price_increase_status", :integer},
             {"grace_period_expires_date", :number},
             {"offer_type", :number},
             {"raw_offer_type", :integer},
             {"offer_identifier", :string},
             {"signed_date", :number},
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"recent_subscription_start_date", :number},
             {"renewal_date", :number},
             {"currency", :string},
             {"renewal_price", :number},
             {"offer_discount_type", :atom_or_string},
             {"raw_offer_discount_type", :string},
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"app_account_token", :string},
             {"app_transaction_id", :string},
             {"offer_period", :string}
           ]),
         :ok <- Validator.optional_string_list(map, "eligible_win_back_offer_ids"),
         :ok <-
           Validator.optional_integer_domain(map, "expiration_intent", @expiration_intent_allowed),
         :ok <-
           Validator.optional_integer_domain(
             map,
             "raw_expiration_intent",
             @expiration_intent_allowed
           ),
         :ok <-
           Validator.optional_integer_domain(map, "auto_renew_status", @auto_renew_status_allowed),
         :ok <-
           Validator.optional_integer_domain(
             map,
             "raw_auto_renew_status",
             @auto_renew_status_allowed
           ),
         :ok <-
           Validator.optional_integer_domain(
             map,
             "price_increase_status",
             @price_increase_status_allowed
           ),
         :ok <-
           Validator.optional_integer_domain(
             map,
             "raw_price_increase_status",
             @price_increase_status_allowed
           ),
         :ok <- Validator.optional_integer_domain(map, "offer_type", @offer_type_allowed_ints),
         :ok <-
           Validator.optional_integer_domain(map, "raw_offer_type", @offer_type_allowed_ints),
         :ok <- Validator.optional_enum(map, "offer_discount_type", @offer_discount_allowed),
         :ok <- Validator.optional_enum(map, "environment", Environment.allowed_values()) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
