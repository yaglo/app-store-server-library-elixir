defmodule AppStoreServerLibrary.Models.UpdateAppAccountTokenRequest do
  @moduledoc """
  The request body that contains an app account token value.

  https://developer.apple.com/documentation/appstoreserverapi/updateappaccounttokenrequest
  """

  @derive Jason.Encoder
  defstruct [:app_account_token]

  @type t :: %__MODULE__{
          app_account_token: String.t()
        }
end
