defmodule AppStoreServerLibrary.Models.RefundHistoryResponse do
  @moduledoc """
  A response that contains an array of signed JSON Web Signature (JWS) refunded transactions, and paging information.

  https://developer.apple.com/documentation/appstoreserverapi/refundhistoryresponse
  """

  @type t :: %__MODULE__{
          signed_transactions: [String.t()] | nil,
          revision: String.t() | nil,
          has_more: boolean() | nil
        }

  defstruct [
    :signed_transactions,
    :revision,
    :has_more
  ]
end
