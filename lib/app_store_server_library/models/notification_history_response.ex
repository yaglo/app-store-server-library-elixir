defmodule AppStoreServerLibrary.Models.NotificationHistoryResponse do
  @moduledoc """
  Response for notification history requests.
  """

  defstruct [
    :notification_history,
    :has_more,
    :pagination_token
  ]

  @type t :: %__MODULE__{
          notification_history:
            [AppStoreServerLibrary.Models.NotificationHistoryResponseItem.t()] | nil,
          has_more: boolean() | nil,
          pagination_token: String.t() | nil
        }
end
