defmodule AppStoreServerLibrary.Models.DecodedRealtimeRequestBody do
  @moduledoc """
  The decoded request body the App Store sends to your server to request a real-time retention message.

  https://developer.apple.com/documentation/retentionmessaging/decodedrealtimerequestbody
  """

  alias AppStoreServerLibrary.Models.Environment
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          original_transaction_id: String.t(),
          app_apple_id: integer(),
          product_id: String.t(),
          user_locale: String.t(),
          request_identifier: String.t(),
          signed_date: integer(),
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil
        }

  defstruct [
    :original_transaction_id,
    :app_apple_id,
    :product_id,
    :user_locale,
    :request_identifier,
    :signed_date,
    :environment,
    :raw_environment
  ]

  @environment_allowed Environment.allowed_values()

  @doc """
  Builds a realtime request payload from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"original_transaction_id", :string},
             {"app_apple_id", :number},
             {"product_id", :string},
             {"user_locale", :string},
             {"request_identifier", :string},
             {"signed_date", :number},
             {"environment", :atom_or_string},
             {"raw_environment", :string}
           ]),
         :ok <- Validator.optional_enum(map, "environment", @environment_allowed) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
