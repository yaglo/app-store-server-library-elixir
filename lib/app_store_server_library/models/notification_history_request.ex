defmodule AppStoreServerLibrary.Models.NotificationHistoryRequest do
  @moduledoc """
  The request body for notification history.

  https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryrequest
  """

  @derive Jason.Encoder
  defstruct [
    :start_date,
    :end_date,
    :notification_type,
    :notification_subtype,
    :transaction_id,
    :only_failures
  ]

  @type t :: %__MODULE__{
          start_date: integer() | nil,
          end_date: integer() | nil,
          notification_type: AppStoreServerLibrary.Models.NotificationTypeV2.t() | nil,
          notification_subtype: AppStoreServerLibrary.Models.Subtype.t() | nil,
          transaction_id: String.t() | nil,
          only_failures: boolean() | nil
        }
end
