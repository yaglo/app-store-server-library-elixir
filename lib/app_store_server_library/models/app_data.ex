defmodule AppStoreServerLibrary.Models.AppData do
  @moduledoc """
  The object that contains the app metadata and signed app transaction information.

  This object is present in the payload when the notificationType is RESCIND_CONSENT.

  https://developer.apple.com/documentation/appstoreservernotifications/appdata
  """

  alias AppStoreServerLibrary.Models.Environment
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          app_apple_id: integer() | nil,
          bundle_id: String.t() | nil,
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          signed_app_transaction_info: String.t() | nil
        }

  defstruct [
    :app_apple_id,
    :bundle_id,
    :environment,
    :raw_environment,
    :signed_app_transaction_info
  ]

  @doc """
  Builds an AppData struct from a map with snake_case keys.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"app_apple_id", :number},
             {"bundle_id", :string},
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"signed_app_transaction_info", :string}
           ]),
         {:ok, map} <-
           Validator.optional_string_enum(map, "environment", Environment.allowed_values(), Environment) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
