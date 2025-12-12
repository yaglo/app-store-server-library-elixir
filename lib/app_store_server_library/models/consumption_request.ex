defmodule AppStoreServerLibrary.Models.ConsumptionRequest do
  @moduledoc """
  The request body containing consumption information.

  https://developer.apple.com/documentation/appstoreserverapi/consumptionrequest
  """

  alias AppStoreServerLibrary.Models.{
    AccountTenure,
    ConsumptionStatus,
    DeliveryStatus,
    LifetimeDollarsPurchased,
    LifetimeDollarsRefunded,
    Platform,
    PlayTime,
    RefundPreference,
    UserStatus
  }

  @derive Jason.Encoder

  @type t :: %__MODULE__{
          customer_consented: boolean() | nil,
          consumption_status: ConsumptionStatus.t() | nil,
          raw_consumption_status: integer() | nil,
          platform: Platform.t() | nil,
          raw_platform: integer() | nil,
          sample_content_provided: boolean() | nil,
          delivery_status: DeliveryStatus.t() | nil,
          raw_delivery_status: integer() | nil,
          app_account_token: String.t() | nil,
          account_tenure: AccountTenure.t() | nil,
          raw_account_tenure: integer() | nil,
          play_time: PlayTime.t() | nil,
          raw_play_time: integer() | nil,
          lifetime_dollars_refunded: LifetimeDollarsRefunded.t() | nil,
          raw_lifetime_dollars_refunded: integer() | nil,
          lifetime_dollars_purchased: LifetimeDollarsPurchased.t() | nil,
          raw_lifetime_dollars_purchased: integer() | nil,
          user_status: UserStatus.t() | nil,
          raw_user_status: integer() | nil,
          refund_preference: RefundPreference.t() | nil,
          raw_refund_preference: integer() | nil
        }

  defstruct [
    :customer_consented,
    :consumption_status,
    :raw_consumption_status,
    :platform,
    :raw_platform,
    :sample_content_provided,
    :delivery_status,
    :raw_delivery_status,
    :app_account_token,
    :account_tenure,
    :raw_account_tenure,
    :play_time,
    :raw_play_time,
    :lifetime_dollars_refunded,
    :raw_lifetime_dollars_refunded,
    :lifetime_dollars_purchased,
    :raw_lifetime_dollars_purchased,
    :user_status,
    :raw_user_status,
    :refund_preference,
    :raw_refund_preference
  ]
end
