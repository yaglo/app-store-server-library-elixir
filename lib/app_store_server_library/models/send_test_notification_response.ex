defmodule AppStoreServerLibrary.Models.SendTestNotificationResponse do
  @moduledoc """
  Response for sending a test notification.
  """

  defstruct [
    :test_notification_token
  ]

  @type t :: %__MODULE__{
          test_notification_token: String.t() | nil
        }
end
