defmodule AppStoreServerLibrary.Models.Summary do
  @moduledoc """
  The payload data for a subscription-renewal-date extension notification.

  https://developer.apple.com/documentation/appstoreservernotifications/summary
  """

  alias AppStoreServerLibrary.Models.Environment
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          app_apple_id: integer() | nil,
          bundle_id: String.t() | nil,
          product_id: String.t() | nil,
          request_identifier: String.t() | nil,
          storefront_country_codes: [String.t()] | nil,
          succeeded_count: integer() | nil,
          failed_count: integer() | nil
        }

  defstruct [
    :environment,
    :raw_environment,
    :app_apple_id,
    :bundle_id,
    :product_id,
    :request_identifier,
    :storefront_country_codes,
    :succeeded_count,
    :failed_count
  ]

  @environment_allowed Environment.allowed_values()

  @doc """
  Builds a summary payload from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"app_apple_id", :number},
             {"bundle_id", :string},
             {"product_id", :string},
             {"request_identifier", :string},
             {"succeeded_count", :number},
             {"failed_count", :number}
           ]),
         :ok <- Validator.optional_string_list(map, "storefront_country_codes"),
         :ok <- Validator.optional_enum(map, "environment", @environment_allowed) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
