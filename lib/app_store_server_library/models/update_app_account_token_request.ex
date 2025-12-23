defmodule AppStoreServerLibrary.Models.UpdateAppAccountTokenRequest do
  @moduledoc """
  The request body that contains an app account token value.

  https://developer.apple.com/documentation/appstoreserverapi/updateappaccounttokenrequest
  """

  alias AppStoreServerLibrary.Utility.JSON

  @type t :: %__MODULE__{
          app_account_token: String.t()
        }

  @enforce_keys [:app_account_token]
  defstruct [:app_account_token]

  defimpl Jason.Encoder do
    def encode(request, opts) do
      request
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> JSON.keys_to_camel()
      |> Jason.Encode.map(opts)
    end
  end
end
