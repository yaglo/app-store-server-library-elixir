defmodule AppStoreServerLibrary.Models.ExtendRenewalDateRequest do
  @moduledoc """
  The request body that contains subscription-renewal-extension data for an individual subscription.

  https://developer.apple.com/documentation/appstoreserverapi/extendrenewaldaterequest
  """

  alias AppStoreServerLibrary.Models.ExtendReasonCode
  alias AppStoreServerLibrary.Utility.JSON

  @type t :: %__MODULE__{
          extend_by_days: integer(),
          extend_reason_code: ExtendReasonCode.t(),
          request_identifier: String.t()
        }

  @enforce_keys [:extend_by_days, :extend_reason_code, :request_identifier]
  defstruct [
    :extend_by_days,
    :extend_reason_code,
    :request_identifier
  ]

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

    defp convert_value(:extend_reason_code, v), do: ExtendReasonCode.to_integer(v)
    defp convert_value(_k, v), do: v
  end
end
