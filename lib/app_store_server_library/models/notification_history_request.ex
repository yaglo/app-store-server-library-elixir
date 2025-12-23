defmodule AppStoreServerLibrary.Models.NotificationHistoryRequest do
  @moduledoc """
  The request body for notification history.

  https://developer.apple.com/documentation/appstoreserverapi/notificationhistoryrequest
  """

  alias AppStoreServerLibrary.Models.{NotificationTypeV2, SubtypeV2}
  alias AppStoreServerLibrary.Utility.JSON

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
          notification_type: NotificationTypeV2.t() | nil,
          notification_subtype: SubtypeV2.t() | nil,
          transaction_id: String.t() | nil,
          only_failures: boolean() | nil
        }

  defimpl Jason.Encoder do
    def encode(request, opts) do
      request
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {k, convert_value(k, v)} end)
      |> Map.new()
      |> JSON.keys_to_camel()
      |> Jason.Encode.map(opts)
    end

    defp convert_value(:notification_type, v), do: NotificationTypeV2.to_string(v)
    defp convert_value(:notification_subtype, v), do: SubtypeV2.to_string(v)
    defp convert_value(_k, v), do: v
  end
end
