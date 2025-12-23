defmodule AppStoreServerLibrary.Models.SendAttemptItem do
  @moduledoc """
  The success or error information and the date the App Store server records when it attempts to send a server notification to your server.

  https://developer.apple.com/documentation/appstoreserverapi/sendattemptitem
  """

  alias AppStoreServerLibrary.Models.SendAttemptResult

  @type t :: %__MODULE__{
          attempt_date: integer() | nil,
          send_attempt_result: SendAttemptResult.t() | String.t() | nil,
          raw_send_attempt_result: String.t() | nil
        }

  defstruct [
    :attempt_date,
    :send_attempt_result,
    :raw_send_attempt_result
  ]
end
