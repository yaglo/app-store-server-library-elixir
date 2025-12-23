defmodule AppStoreServerLibrary.Models.AppTransaction do
  @moduledoc """
  Information that represents customer's purchase of app, cryptographically signed by App Store.

  https://developer.apple.com/documentation/storekit/apptransaction
  """

  alias AppStoreServerLibrary.Models.Environment
  alias AppStoreServerLibrary.Models.PurchasePlatform
  alias AppStoreServerLibrary.Verification.Validator

  @type t :: %__MODULE__{
          receipt_type: Environment.t() | nil,
          raw_receipt_type: String.t() | nil,
          app_apple_id: integer() | nil,
          bundle_id: String.t() | nil,
          application_version: String.t() | nil,
          version_external_identifier: integer() | nil,
          receipt_creation_date: integer() | nil,
          original_purchase_date: integer() | nil,
          original_application_version: String.t() | nil,
          device_verification: String.t() | nil,
          device_verification_nonce: String.t() | nil,
          preorder_date: integer() | nil,
          app_transaction_id: String.t() | nil,
          original_platform: PurchasePlatform.t() | nil,
          raw_original_platform: String.t() | nil
        }

  defstruct [
    :receipt_type,
    :raw_receipt_type,
    :app_apple_id,
    :bundle_id,
    :application_version,
    :version_external_identifier,
    :receipt_creation_date,
    :original_purchase_date,
    :original_application_version,
    :device_verification,
    :device_verification_nonce,
    :preorder_date,
    :app_transaction_id,
    :original_platform,
    :raw_original_platform
  ]

  @purchase_platform_allowed [
    :ios,
    :mac_os,
    :tv_os,
    :vision_os,
    "iOS",
    "macOS",
    "tvOS",
    "visionOS"
  ]

  @environment_allowed Environment.allowed_values()

  @doc """
  Builds an app transaction payload from a map with snake_case keys, validating key required fields.
  """
  @spec new(map()) :: {:ok, t()} | {:error, {atom(), String.t()}}
  def new(map) when is_map(map) do
    with :ok <-
           Validator.optional_fields(map, [
             {"receipt_type", :atom_or_string},
             {"raw_receipt_type", :string},
             {"app_apple_id", :number},
             {"bundle_id", :string},
             {"application_version", :string},
             {"version_external_identifier", :number},
             {"receipt_creation_date", :number},
             {"original_purchase_date", :number},
             {"original_application_version", :string},
             {"device_verification", :string},
             {"device_verification_nonce", :string},
             {"preorder_date", :number},
             {"app_transaction_id", :string},
             {"original_platform", :atom_or_string},
             {"raw_original_platform", :string}
           ]),
         :ok <- Validator.optional_enum(map, "original_platform", @purchase_platform_allowed),
         :ok <- Validator.optional_enum(map, "receipt_type", @environment_allowed) do
      {:ok, struct(__MODULE__, map)}
    end
  end
end
