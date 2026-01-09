defmodule AppStoreServerLibrary.Models.NotificationHistoryResponse do
  @moduledoc """
  Response for notification history requests.
  """

  alias AppStoreServerLibrary.Models.NotificationHistoryResponseItem

  @doc false
  @spec __nested_fields__() :: %{atom() => {:list | :single, module()}}
  def __nested_fields__ do
    %{notification_history: {:list, NotificationHistoryResponseItem}}
  end

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
