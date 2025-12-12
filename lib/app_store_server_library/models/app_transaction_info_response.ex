defmodule AppStoreServerLibrary.Models.AppTransactionInfoResponse do
  @moduledoc """
  A response that contains signed app transaction information for a customer.

  https://developer.apple.com/documentation/appstoreserverapi/apptransactioninforesponse
  """

  @type t :: %__MODULE__{
          signed_app_transaction_info: String.t() | nil
        }

  defstruct [
    :signed_app_transaction_info
  ]
end
