defmodule AppStoreServerLibrary.Models.HistoryResponse do
  @moduledoc """
  A response that contains the customer's transaction history for an app.

  https://developer.apple.com/documentation/appstoreserverapi/historyresponse
  """

  alias AppStoreServerLibrary.Models.Environment

  @type t :: %__MODULE__{
          revision: String.t() | nil,
          has_more: boolean() | nil,
          bundle_id: String.t() | nil,
          app_apple_id: integer() | nil,
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          signed_transactions: [String.t()] | nil
        }

  defstruct [
    :revision,
    :has_more,
    :bundle_id,
    :app_apple_id,
    :environment,
    :raw_environment,
    :signed_transactions
  ]
end
