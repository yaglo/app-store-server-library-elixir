defmodule AppStoreServerLibrary.Models.DefaultConfigurationRequest do
  @moduledoc """
  The request body that contains the default configuration information.

  https://developer.apple.com/documentation/retentionmessaging/defaultconfigurationrequest
  """

  alias AppStoreServerLibrary.Utility.JSON

  @enforce_keys [:message_identifier]
  @type t :: %__MODULE__{
          message_identifier: String.t()
        }

  defstruct [:message_identifier]

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
