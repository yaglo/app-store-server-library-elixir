defmodule AppStoreServerLibrary do
  @moduledoc """
  Elixir client library for Apple App Store Server API.

  This library provides full feature parity with Apple's official Python implementation
  for interacting with the App Store Server API, verifying signed data, creating
  promotional offer signatures, and parsing receipts.

  ## Quick Start

      # Create API client
      client = AppStoreServerLibrary.Client.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app",
        environment: :sandbox
      )

      # Get transaction info
      {:ok, transaction} = AppStoreServerLibrary.Client.get_transaction_info(client, "transaction_id")

      # Create a signed data verifier
      root_cert = File.read!("AppleRootCA-G3.cer")

      verifier = AppStoreServerLibrary.Verifier.new(
        root_certificates: [root_cert],
        environment: :sandbox,
        bundle_id: "com.example.app"
      )

      # Verify and decode a signed transaction
      {:ok, decoded} = AppStoreServerLibrary.Verifier.verify_and_decode_signed_transaction(verifier, signed_transaction)

  ## Main Modules

  For convenience, you can use these shorter aliases:

    * `AppStoreServerLibrary.Client` - REST API client
    * `AppStoreServerLibrary.Verifier` - JWS signature verification

  Full module paths:

    * `AppStoreServerLibrary.API.AppStoreServerAPIClient` - REST API client
    * `AppStoreServerLibrary.Verification.SignedDataVerifier` - JWS signature verification
    * `AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator` - V1 promotional offers
    * `AppStoreServerLibrary.Signature.PromotionalOfferV2SignatureCreator` - V2 promotional offers
    * `AppStoreServerLibrary.Signature.IntroductoryOfferEligibilitySignatureCreator` - Intro offer eligibility
    * `AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppSignatureCreator` - Advanced Commerce API
    * `AppStoreServerLibrary.Utility.ReceiptUtility` - Receipt parsing

  ## Environments

  The library supports four environments:

    * `:production` - Production App Store
    * `:sandbox` - Sandbox testing
    * `:xcode` - Local Xcode testing
    * `:local_testing` - Local testing

  ## Error Handling

  API errors are returned as maps with `:status_code`, `:error_code`, and `:error_message` keys.
  Use `AppStoreServerLibrary.API.APIError` to look up error descriptions and check if errors
  are retryable.
  """

  @doc """
  Returns the library version.
  """
  @spec version() :: String.t()
  def version, do: Application.spec(:app_store_server_library, :vsn) |> to_string()
end

# Convenience aliases for cleaner API
defmodule AppStoreServerLibrary.Client do
  @moduledoc """
  Convenience alias for `AppStoreServerLibrary.API.AppStoreServerAPIClient`.

  ## Example

      client = AppStoreServerLibrary.Client.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app",
        environment: :sandbox
      )

      {:ok, transaction} = AppStoreServerLibrary.Client.get_transaction_info(client, "txn_id")

  """
  defdelegate new(opts), to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_transaction_info(client, transaction_id),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_transaction_history(client, transaction_id, revision \\ nil, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_all_subscription_statuses(client, transaction_id, status \\ nil),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate extend_subscription_renewal_date(client, original_transaction_id, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate extend_renewal_date_for_all_active_subscribers(client, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_status_of_subscription_renewal_date_extensions(
                client,
                request_identifier,
                product_id
              ),
              to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_refund_history(client, transaction_id, revision \\ nil),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate look_up_order_id(client, order_id),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate request_test_notification(client),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_test_notification_status(client, test_notification_token),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_notification_history(client, pagination_token \\ nil, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate send_consumption_data(client, transaction_id, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate set_app_account_token(client, original_transaction_id, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_app_transaction_info(client, transaction_id),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  # Retention Messaging

  defdelegate upload_image(client, image_identifier, image),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate delete_image(client, image_identifier),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_image_list(client),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate upload_message(client, message_identifier, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate delete_message(client, message_identifier),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate get_message_list(client),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate configure_default_message(client, product_id, locale, request),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient

  defdelegate delete_default_message(client, product_id, locale),
    to: AppStoreServerLibrary.API.AppStoreServerAPIClient
end

defmodule AppStoreServerLibrary.Verifier do
  @moduledoc """
  Convenience alias for `AppStoreServerLibrary.Verification.SignedDataVerifier`.

  ## Example

      root_cert = File.read!("AppleRootCA-G3.cer")

      verifier = AppStoreServerLibrary.Verifier.new(
        root_certificates: [root_cert],
        environment: :sandbox,
        bundle_id: "com.example.app"
      )

      {:ok, transaction} = AppStoreServerLibrary.Verifier.verify_and_decode_signed_transaction(
        verifier,
        signed_transaction
      )

  """
  defdelegate new(opts), to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_renewal_info(verifier, signed_renewal_info),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_signed_transaction(verifier, signed_transaction),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_notification(verifier, signed_payload),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_app_transaction(verifier, signed_app_transaction),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_realtime_request(verifier, signed_payload),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier

  defdelegate verify_and_decode_summary(verifier, signed_payload),
    to: AppStoreServerLibrary.Verification.SignedDataVerifier
end
