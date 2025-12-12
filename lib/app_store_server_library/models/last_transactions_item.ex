defmodule AppStoreServerLibrary.Models.LastTransactionsItem do
  @moduledoc """
  The most recent App Store-signed transaction information and App Store-signed renewal information for an auto-renewable subscription.

  https://developer.apple.com/documentation/appstoreserverapi/lasttransactionsitem
  """

  alias AppStoreServerLibrary.Models.Status

  @type t :: %__MODULE__{
          status: Status.t() | nil,
          raw_status: integer() | nil,
          original_transaction_id: String.t() | nil,
          signed_transaction_info: String.t() | nil,
          signed_renewal_info: String.t() | nil
        }

  defstruct [
    :status,
    :raw_status,
    :original_transaction_id,
    :signed_transaction_info,
    :signed_renewal_info
  ]
end
