defmodule AppStoreServerLibrary.Models.ResponseBodyV2DecodedPayload do
  @moduledoc """
  A decoded payload containing the version 2 notification data.

  https://developer.apple.com/documentation/appstoreservernotifications/responsebodyv2decodedpayload
  """

  alias AppStoreServerLibrary.Models.{
    AppData,
    Data,
    ExternalPurchaseToken,
    NotificationTypeV2,
    SubtypeV2,
    Summary
  }

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          notification_type: NotificationTypeV2.t() | nil,
          raw_notification_type: String.t() | nil,
          subtype: SubtypeV2.t() | nil,
          raw_subtype: String.t() | nil,
          notification_uuid: String.t() | nil,
          data: Data.t() | nil,
          app_data: AppData.t() | nil,
          version: String.t() | nil,
          signed_date: integer() | nil,
          summary: Summary.t() | nil,
          external_purchase_token: ExternalPurchaseToken.t() | nil
        }

  defstruct [
    :notification_type,
    :raw_notification_type,
    :subtype,
    :raw_subtype,
    :notification_uuid,
    :data,
    :app_data,
    :version,
    :signed_date,
    :summary,
    :external_purchase_token
  ]

  @notification_types [
    :consumption_request,
    :did_change_renewal_pref,
    :did_change_renewal_status,
    :did_fail_to_renew,
    :did_renew,
    :expired,
    :external_purchase_token,
    :grace_period_expired,
    :metadata_update,
    :migration,
    :offer_redeemed,
    :one_time_charge,
    :price_change,
    :price_increase,
    :refund,
    :refund_declined,
    :refund_reversed,
    :renewal_extended,
    :renewal_extension,
    :rescind_consent,
    :revoke,
    :subscribed,
    :test,
    "CONSUMPTION_REQUEST",
    "DID_CHANGE_RENEWAL_PREF",
    "DID_CHANGE_RENEWAL_STATUS",
    "DID_FAIL_TO_RENEW",
    "DID_RENEW",
    "EXPIRED",
    "EXTERNAL_PURCHASE_TOKEN",
    "GRACE_PERIOD_EXPIRED",
    "METADATA_UPDATE",
    "MIGRATION",
    "OFFER_REDEEMED",
    "ONE_TIME_CHARGE",
    "PRICE_CHANGE",
    "PRICE_INCREASE",
    "REFUND",
    "REFUND_DECLINED",
    "REFUND_REVERSED",
    "RENEWAL_EXTENDED",
    "RENEWAL_EXTENSION",
    "RESCIND_CONSENT",
    "REVOKE",
    "SUBSCRIBED",
    "TEST"
  ]

  @subtypes [
    :accepted,
    :active_token_reminder,
    :auto_renew_disabled,
    :auto_renew_enabled,
    :billing_recovery,
    :billing_retry,
    :created,
    :downgrade,
    :failure,
    :grace_period,
    :initial_buy,
    :pending,
    :price_increase,
    :product_not_for_sale,
    :resubscribe,
    :summary,
    :upgrade,
    :unreported,
    :voluntary,
    "ACCEPTED",
    "ACTIVE_TOKEN_REMINDER",
    "AUTO_RENEW_DISABLED",
    "AUTO_RENEW_ENABLED",
    "BILLING_RECOVERY",
    "BILLING_RETRY",
    "CREATED",
    "DOWNGRADE",
    "FAILURE",
    "GRACE_PERIOD",
    "INITIAL_BUY",
    "PENDING",
    "PRICE_INCREASE",
    "PRODUCT_NOT_FOR_SALE",
    "RESUBSCRIBE",
    "SUMMARY",
    "UPGRADE",
    "UNREPORTED",
    "VOLUNTARY"
  ]

  @doc """
  Builds a notification payload from a map with snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"notification_type", :atom_or_string},
             {"raw_notification_type", :string},
             {"subtype", :atom_or_string},
             {"raw_subtype", :string},
             {"notification_uuid", :string},
             {"data", :map},
             {"app_data", :map},
             {"version", :string},
             {"signed_date", :number},
             {"summary", :map},
             {"external_purchase_token", :map}
           ]),
         {:ok, map} <-
           Validator.optional_string_enum(map, "notification_type", @notification_types, NotificationTypeV2),
         {:ok, map} <-
           Validator.optional_string_enum(map, "subtype", @subtypes, SubtypeV2) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
