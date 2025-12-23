defmodule AppStoreServerLibrary.Models.MassExtendRenewalDateStatusResponse do
  @moduledoc """
  A response that indicates the current status of a request to extend the subscription
  renewal date to all eligible subscribers.

  https://developer.apple.com/documentation/appstoreserverapi/massextendrenewaldatestatusresponse
  """

  defstruct [
    :request_identifier,
    :complete,
    :complete_date,
    :succeeded_count,
    :failed_count
  ]

  @type t :: %__MODULE__{
          request_identifier: String.t() | nil,
          complete: boolean() | nil,
          complete_date: integer() | nil,
          succeeded_count: integer() | nil,
          failed_count: integer() | nil
        }
end
