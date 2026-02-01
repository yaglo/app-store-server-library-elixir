defmodule AppStoreServerLibrary.Models.Data do
  @moduledoc """
  The app metadata and the signed renewal and transaction information.

  https://developer.apple.com/documentation/appstoreservernotifications/data
  """

  alias AppStoreServerLibrary.Models.{
    ConsumptionRequestReason,
    Environment,
    Status
  }

  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          environment: Environment.t() | nil,
          raw_environment: String.t() | nil,
          app_apple_id: integer() | nil,
          bundle_id: String.t() | nil,
          bundle_version: String.t() | nil,
          signed_transaction_info: String.t() | nil,
          signed_renewal_info: String.t() | nil,
          status: Status.t() | nil,
          raw_status: integer() | nil,
          consumption_request_reason: ConsumptionRequestReason.t() | nil,
          raw_consumption_request_reason: String.t() | nil
        }

  defstruct [
    :environment,
    :raw_environment,
    :app_apple_id,
    :bundle_id,
    :bundle_version,
    :signed_transaction_info,
    :signed_renewal_info,
    :status,
    :raw_status,
    :consumption_request_reason,
    :raw_consumption_request_reason
  ]

  @status_allowed [1, 2, 3, 4, 5]

  @consumption_reason_allowed [
    :unintended_purchase,
    :fulfillment_issue,
    :unsatisfied_with_purchase,
    :legal,
    :other,
    "UNINTENDED_PURCHASE",
    "FULFILLMENT_ISSUE",
    "UNSATISFIED_WITH_PURCHASE",
    "LEGAL",
    "OTHER"
  ]

  @doc """
  Builds notification data from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"environment", :atom_or_string},
             {"raw_environment", :string},
             {"app_apple_id", :number},
             {"bundle_id", :string},
             {"bundle_version", :string},
             {"signed_transaction_info", :string},
             {"signed_renewal_info", :string},
             {"status", :integer},
             {"raw_status", :integer},
             {"consumption_request_reason", :atom_or_string},
             {"raw_consumption_request_reason", :string}
           ]),
         :ok <- Validator.optional_integer_domain(map, "raw_status", @status_allowed),
         {:ok, map} <-
           Validator.optional_integer_enum(map, "status", @status_allowed, Status),
         {:ok, map} <-
           Validator.optional_string_enum(map, "consumption_request_reason", @consumption_reason_allowed, ConsumptionRequestReason),
         {:ok, map} <-
           Validator.optional_string_enum(map, "environment", Environment.allowed_values(), Environment) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
