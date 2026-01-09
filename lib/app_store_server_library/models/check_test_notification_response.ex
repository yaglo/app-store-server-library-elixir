defmodule AppStoreServerLibrary.Models.CheckTestNotificationResponse do
  @moduledoc """
  Represents the response for checking test notification status.

  Deprecated fields from Apple's docs are included for compatibility:
  - `first_send_attempt_result` (deprecated, use the first `send_attempts` entry instead)
  """

  alias AppStoreServerLibrary.Models.{SendAttemptItem, SendAttemptResult}

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{send_attempts: {:list, SendAttemptItem}}
  end

  @type t :: %__MODULE__{
          signed_payload: String.t() | nil,
          send_attempts: [SendAttemptItem.t()] | nil,
          first_send_attempt_result: SendAttemptResult.t() | String.t() | nil,
          raw_first_send_attempt_result: String.t() | nil
        }

  defstruct [
    :signed_payload,
    :send_attempts,
    :first_send_attempt_result,
    :raw_first_send_attempt_result
  ]
end
