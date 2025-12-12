defmodule AppStoreServerLibrary.Models.ResponseBodyV2DecodedPayload do
  @moduledoc """
  A decoded payload containing the version 2 notification data.

  https://developer.apple.com/documentation/appstoreservernotifications/responsebodyv2decodedpayload
  """

  alias AppStoreServerLibrary.Models.{
    Data,
    ExternalPurchaseToken,
    NotificationTypeV2,
    Subtype,
    Summary
  }

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          notification_type: NotificationTypeV2.t() | nil,
          raw_notification_type: String.t() | nil,
          subtype: Subtype.t() | nil,
          raw_subtype: String.t() | nil,
          notification_uuid: String.t() | nil,
          data: Data.t() | nil,
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
    :version,
    :signed_date,
    :summary,
    :external_purchase_token
  ]

  @notification_types [
    :subscribed,
    :did_change_renewal_pref,
    :did_change_renewal_status,
    :offer_redeemed,
    :did_renew,
    :expired,
    :did_fail_to_renew,
    :grace_period_expired,
    :price_increase,
    :refund,
    :refund_declined,
    :consumption_request,
    :renewal_extended,
    :revoke,
    :test,
    :renewal_extension,
    :refund_reversed,
    :external_purchase_token,
    :one_time_charge,
    "SUBSCRIBED",
    "DID_CHANGE_RENEWAL_PREF",
    "DID_CHANGE_RENEWAL_STATUS",
    "OFFER_REDEEMED",
    "DID_RENEW",
    "EXPIRED",
    "DID_FAIL_TO_RENEW",
    "GRACE_PERIOD_EXPIRED",
    "PRICE_INCREASE",
    "REFUND",
    "REFUND_DECLINED",
    "CONSUMPTION_REQUEST",
    "RENEWAL_EXTENDED",
    "REVOKE",
    "TEST",
    "RENEWAL_EXTENSION",
    "REFUND_REVERSED",
    "EXTERNAL_PURCHASE_TOKEN",
    "ONE_TIME_CHARGE"
  ]

  @subtypes [
    :subscribed,
    :did_not_renew,
    :expired,
    :in_grace_period,
    :price_increase,
    :grace_period_expired,
    :pending,
    :accepted,
    :revoked,
    :subscription_extended,
    :summary,
    :unreported,
    :initial_buy,
    "SUBSCRIBED",
    "DID_NOT_RENEW",
    "EXPIRED",
    "IN_GRACE_PERIOD",
    "PRICE_INCREASE",
    "GRACE_PERIOD_EXPIRED",
    "PENDING",
    "ACCEPTED",
    "REVOKED",
    "SUBSCRIPTION_EXTENDED",
    "SUMMARY",
    "UNREPORTED",
    "INITIAL_BUY"
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
             {"version", :string},
             {"signed_date", :number},
             {"summary", :map},
             {"external_purchase_token", :map}
           ]),
         :ok <- Validator.optional_enum(map, "notification_type", @notification_types),
         :ok <- Validator.optional_enum(map, "subtype", @subtypes) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
