defmodule AppStoreServerLibrary.Models.MassExtendRenewalDateRequest do
  @moduledoc """
  The request body that contains subscription-renewal-extension data to apply for all eligible active subscribers.

  https://developer.apple.com/documentation/appstoreserverapi/massextendrenewaldaterequest
  """

  alias AppStoreServerLibrary.Models.ExtendReasonCode

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          extend_by_days: integer() | nil,
          extend_reason_code: ExtendReasonCode.t() | nil,
          request_identifier: String.t() | nil,
          storefront_country_codes: [String.t()] | nil,
          product_id: String.t() | nil
        }

  defstruct [
    :extend_by_days,
    :extend_reason_code,
    :request_identifier,
    :storefront_country_codes,
    :product_id
  ]
end
