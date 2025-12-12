defmodule AppStoreServerLibrary.Models.MassExtendRenewalDateResponse do
  @moduledoc """
  A response that indicates the status of a mass renewal-date extension request.

  https://developer.apple.com/documentation/appstoreserverapi/massextendrenewaldateresponse
  """

  @type t :: %__MODULE__{
          request_identifier: String.t() | nil
        }

  defstruct [
    :request_identifier
  ]

  defimpl Jason.Encoder do
    def encode(%{request_identifier: request_identifier}, opts) do
      Jason.Encode.map(%{"requestIdentifier" => request_identifier}, opts)
    end
  end
end
