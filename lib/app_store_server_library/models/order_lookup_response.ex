defmodule AppStoreServerLibrary.Models.OrderLookupResponse do
  @moduledoc """
  A response that includes order lookup status and an array of signed transactions for in-app purchases in order.

  https://developer.apple.com/documentation/appstoreserverapi/orderlookupresponse
  """

  alias AppStoreServerLibrary.Models.OrderLookupStatus

  @type t :: %__MODULE__{
          status: OrderLookupStatus.t() | nil,
          raw_status: integer() | nil,
          signed_transactions: [String.t()] | nil
        }

  defstruct [
    :status,
    :raw_status,
    :signed_transactions
  ]
end
