defmodule AppStoreServerLibrary.Models.NotificationHistoryResponseItem do
  @moduledoc """
  The App Store server notification history record, including the signed notification payload and the result of the server's first send attempt.

  https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryresponseitem

  Deprecated fields from Apple's docs are included for compatibility:
  - `first_send_attempt_result` (deprecated, use the first `send_attempts` entry instead)
  """

  alias AppStoreServerLibrary.Models.SendAttemptItem

  @type t() :: %__MODULE__{
          signed_payload: String.t() | nil,
          send_attempts: [SendAttemptItem.t()] | nil,
          first_send_attempt_result: atom() | String.t() | nil,
          raw_first_send_attempt_result: String.t() | nil
        }

  defstruct [
    :signed_payload,
    :send_attempts,
    :first_send_attempt_result,
    :raw_first_send_attempt_result
  ]
end
