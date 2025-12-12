defmodule AppStoreServerLibrary.Models.TransactionInfoResponse do
  @moduledoc """
  A response that contains signed transaction information for a single transaction.

  https://developer.apple.com/documentation/appstoreserverapi/transactioninforesponse
  """

  @type t :: %__MODULE__{
          signed_transaction_info: String.t() | nil
        }

  defstruct [
    :signed_transaction_info
  ]
end
