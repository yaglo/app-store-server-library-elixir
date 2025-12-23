defmodule AppStoreServerLibrary.Models.ExternalPurchaseToken do
  @moduledoc """
  The payload data that contains an external purchase token.

  https://developer.apple.com/documentation/appstoreservernotifications/externalpurchasetoken
  """

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          external_purchase_id: String.t() | nil,
          token_creation_date: integer() | nil,
          app_apple_id: integer() | nil,
          bundle_id: String.t() | nil,
          token_type: atom() | String.t() | nil,
          raw_token_type: String.t() | nil,
          token_expiration_date: integer() | nil
        }

  defstruct [
    :external_purchase_id,
    :token_creation_date,
    :app_apple_id,
    :bundle_id,
    :token_type,
    :raw_token_type,
    :token_expiration_date
  ]

  @doc """
  Builds an external purchase token from a map with snake_case keys, validating fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"external_purchase_id", :string},
             {"token_creation_date", :number},
             {"app_apple_id", :number},
             {"bundle_id", :string},
             {"token_type", :atom_or_string},
             {"raw_token_type", :string},
             {"token_expiration_date", :number}
           ]) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
