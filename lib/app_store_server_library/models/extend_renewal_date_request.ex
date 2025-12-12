defmodule AppStoreServerLibrary.Models.ExtendRenewalDateRequest do
  @moduledoc """
  The request body that contains subscription-renewal-extension data for an individual subscription.

  https://developer.apple.com/documentation/appstoreserverapi/extendrenewaldaterequest
  """

  alias AppStoreServerLibrary.Models.ExtendReasonCode

  @derive Jason.Encoder

  @type t :: %__MODULE__{
          extend_by_days: integer() | nil,
          extend_reason_code: ExtendReasonCode.t() | nil,
          request_identifier: String.t() | nil
        }

  defstruct [
    :extend_by_days,
    :extend_reason_code,
    :request_identifier
  ]
end
