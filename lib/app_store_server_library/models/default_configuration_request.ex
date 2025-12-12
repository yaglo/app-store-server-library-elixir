defmodule AppStoreServerLibrary.Models.DefaultConfigurationRequest do
  @moduledoc """
  The request body that contains the default configuration information.

  https://developer.apple.com/documentation/retentionmessaging/defaultconfigurationrequest
  """

  @derive Jason.Encoder
  @type t :: %__MODULE__{
          message_identifier: String.t() | nil
        }

  defstruct [:message_identifier]
end
