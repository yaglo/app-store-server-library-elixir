defmodule AppStoreServerLibrary do
  @moduledoc """
  Elixir client library for Apple App Store Server API.

  This library provides full feature parity with Apple's official Python implementation
  for interacting with the App Store Server API, verifying signed data, creating
  promotional offer signatures, and parsing receipts.

  ## Quick Start

      # Create API client
      {:ok, client} = AppStoreServerLibrary.Client.new(
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

      {:ok, client} =
        AppStoreServerLibrary.Client.new(
          signing_key: File.read!("private_key.p8"),
          key_id: "YOUR_KEY_ID",
          issuer_id: "YOUR_ISSUER_ID",
          bundle_id: "com.example.app",
          environment: :sandbox
        )

      {:ok, transaction} = AppStoreServerLibrary.Client.get_transaction_info(client, "txn_id")

  """
  alias AppStoreServerLibrary.API.APIException
  alias AppStoreServerLibrary.API.AppStoreServerAPIClient

  alias AppStoreServerLibrary.Models.{
    AppTransactionInfoResponse,
    CheckTestNotificationResponse,
    ConsumptionRequest,
    DefaultConfigurationRequest,
    ExtendRenewalDateRequest,
    ExtendRenewalDateResponse,
    GetImageListResponse,
    GetMessageListResponse,
    HistoryResponse,
    MassExtendRenewalDateRequest,
    MassExtendRenewalDateResponse,
    MassExtendRenewalDateStatusResponse,
    NotificationHistoryRequest,
    NotificationHistoryResponse,
    OrderLookupResponse,
    RefundHistoryResponse,
    SendTestNotificationResponse,
    Status,
    StatusResponse,
    TransactionHistoryRequest,
    TransactionInfoResponse,
    UpdateAppAccountTokenRequest,
    UploadMessageRequestBody
  }

  @spec new(AppStoreServerAPIClient.options()) ::
          {:ok, AppStoreServerAPIClient.t()}
          | {:error, :invalid_environment | :xcode_not_supported | {:missing_option, atom()}}
  def new(opts), do: AppStoreServerAPIClient.new(opts)

  @spec new!(AppStoreServerAPIClient.options()) :: AppStoreServerAPIClient.t()
  def new!(opts) do
    case new(opts) do
      {:ok, client} -> client
      {:error, reason} -> raise ArgumentError, "invalid client options: #{inspect(reason)}"
    end
  end

  @spec get_transaction_info(AppStoreServerAPIClient.t(), String.t()) ::
          {:ok, TransactionInfoResponse.t()} | {:error, APIException.t()}
  defdelegate get_transaction_info(client, transaction_id), to: AppStoreServerAPIClient

  @spec get_transaction_history(
          AppStoreServerAPIClient.t(),
          String.t(),
          String.t() | nil,
          TransactionHistoryRequest.t()
        ) :: {:ok, HistoryResponse.t()} | {:error, APIException.t()}
  defdelegate get_transaction_history(client, transaction_id, revision \\ nil, request),
    to: AppStoreServerAPIClient

  @spec get_all_subscription_statuses(AppStoreServerAPIClient.t(), String.t(), [Status.t()] | nil) ::
          {:ok, StatusResponse.t()} | {:error, APIException.t()}
  defdelegate get_all_subscription_statuses(client, transaction_id, status \\ nil),
    to: AppStoreServerAPIClient

  @spec extend_subscription_renewal_date(
          AppStoreServerAPIClient.t(),
          String.t(),
          ExtendRenewalDateRequest.t()
        ) :: {:ok, ExtendRenewalDateResponse.t()} | {:error, APIException.t()}
  defdelegate extend_subscription_renewal_date(client, original_transaction_id, request),
    to: AppStoreServerAPIClient

  @spec extend_renewal_date_for_all_active_subscribers(
          AppStoreServerAPIClient.t(),
          MassExtendRenewalDateRequest.t()
        ) :: {:ok, MassExtendRenewalDateResponse.t()} | {:error, APIException.t()}
  defdelegate extend_renewal_date_for_all_active_subscribers(client, request),
    to: AppStoreServerAPIClient

  @spec get_status_of_subscription_renewal_date_extensions(
          AppStoreServerAPIClient.t(),
          String.t(),
          String.t()
        ) :: {:ok, MassExtendRenewalDateStatusResponse.t()} | {:error, APIException.t()}
  defdelegate get_status_of_subscription_renewal_date_extensions(
                client,
                request_identifier,
                product_id
              ),
              to: AppStoreServerAPIClient

  @spec get_refund_history(AppStoreServerAPIClient.t(), String.t(), String.t() | nil) ::
          {:ok, RefundHistoryResponse.t()} | {:error, APIException.t()}
  defdelegate get_refund_history(client, transaction_id, revision \\ nil),
    to: AppStoreServerAPIClient

  @spec look_up_order_id(AppStoreServerAPIClient.t(), String.t()) ::
          {:ok, OrderLookupResponse.t()} | {:error, APIException.t()}
  defdelegate look_up_order_id(client, order_id), to: AppStoreServerAPIClient

  @spec request_test_notification(AppStoreServerAPIClient.t()) ::
          {:ok, SendTestNotificationResponse.t()} | {:error, APIException.t()}
  defdelegate request_test_notification(client), to: AppStoreServerAPIClient

  @spec get_test_notification_status(AppStoreServerAPIClient.t(), String.t()) ::
          {:ok, CheckTestNotificationResponse.t()} | {:error, APIException.t()}
  defdelegate get_test_notification_status(client, test_notification_token),
    to: AppStoreServerAPIClient

  @spec get_notification_history(
          AppStoreServerAPIClient.t(),
          String.t() | nil,
          NotificationHistoryRequest.t()
        ) :: {:ok, NotificationHistoryResponse.t()} | {:error, APIException.t()}
  defdelegate get_notification_history(client, pagination_token \\ nil, request),
    to: AppStoreServerAPIClient

  @spec send_consumption_information(
          AppStoreServerAPIClient.t(),
          String.t(),
          ConsumptionRequest.t()
        ) ::
          :ok | {:error, APIException.t()}
  defdelegate send_consumption_information(client, transaction_id, request),
    to: AppStoreServerAPIClient

  @spec send_consumption_information!(
          AppStoreServerAPIClient.t(),
          String.t(),
          ConsumptionRequest.t()
        ) :: :ok
  defdelegate send_consumption_information!(client, transaction_id, request),
    to: AppStoreServerAPIClient

  @spec set_app_account_token(
          AppStoreServerAPIClient.t(),
          String.t(),
          UpdateAppAccountTokenRequest.t()
        ) :: :ok | {:error, APIException.t()}
  defdelegate set_app_account_token(client, original_transaction_id, request),
    to: AppStoreServerAPIClient

  @spec get_app_transaction_info(AppStoreServerAPIClient.t(), String.t()) ::
          {:ok, AppTransactionInfoResponse.t()} | {:error, APIException.t()}
  defdelegate get_app_transaction_info(client, transaction_id), to: AppStoreServerAPIClient

  # Retention Messaging

  @spec upload_image(AppStoreServerAPIClient.t(), String.t(), binary()) ::
          :ok | {:error, APIException.t()}
  defdelegate upload_image(client, image_identifier, image), to: AppStoreServerAPIClient

  @spec delete_image(AppStoreServerAPIClient.t(), String.t()) :: :ok | {:error, APIException.t()}
  defdelegate delete_image(client, image_identifier), to: AppStoreServerAPIClient

  @spec get_image_list(AppStoreServerAPIClient.t()) ::
          {:ok, GetImageListResponse.t()} | {:error, APIException.t()}
  defdelegate get_image_list(client), to: AppStoreServerAPIClient

  @spec upload_message(AppStoreServerAPIClient.t(), String.t(), UploadMessageRequestBody.t()) ::
          :ok | {:error, APIException.t()}
  defdelegate upload_message(client, message_identifier, request), to: AppStoreServerAPIClient

  @spec delete_message(AppStoreServerAPIClient.t(), String.t()) ::
          :ok | {:error, APIException.t()}
  defdelegate delete_message(client, message_identifier), to: AppStoreServerAPIClient

  @spec get_message_list(AppStoreServerAPIClient.t()) ::
          {:ok, GetMessageListResponse.t()} | {:error, APIException.t()}
  defdelegate get_message_list(client), to: AppStoreServerAPIClient

  @spec configure_default_message(
          AppStoreServerAPIClient.t(),
          String.t(),
          String.t(),
          DefaultConfigurationRequest.t()
        ) :: :ok | {:error, APIException.t()}
  defdelegate configure_default_message(client, product_id, locale, request),
    to: AppStoreServerAPIClient

  @spec delete_default_message(AppStoreServerAPIClient.t(), String.t(), String.t()) ::
          :ok | {:error, APIException.t()}
  defdelegate delete_default_message(client, product_id, locale), to: AppStoreServerAPIClient
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
  alias AppStoreServerLibrary.Verification.SignedDataVerifier

  alias AppStoreServerLibrary.Models.{
    AppTransaction,
    DecodedRealtimeRequestBody,
    JWSRenewalInfoDecodedPayload,
    JWSTransactionDecodedPayload,
    ResponseBodyV2DecodedPayload,
    Summary
  }

  @spec new(SignedDataVerifier.options()) ::
          {:ok, SignedDataVerifier.t()} | {:error, :app_apple_id_required}
  defdelegate new(opts), to: SignedDataVerifier

  @spec verify_and_decode_renewal_info(SignedDataVerifier.t(), String.t()) ::
          {:ok, JWSRenewalInfoDecodedPayload.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_renewal_info(verifier, signed_renewal_info),
    to: SignedDataVerifier

  @spec verify_and_decode_signed_transaction(SignedDataVerifier.t(), String.t()) ::
          {:ok, JWSTransactionDecodedPayload.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_signed_transaction(verifier, signed_transaction),
    to: SignedDataVerifier

  @spec verify_and_decode_notification(SignedDataVerifier.t(), String.t()) ::
          {:ok, ResponseBodyV2DecodedPayload.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_notification(verifier, signed_payload), to: SignedDataVerifier

  @spec verify_and_decode_app_transaction(SignedDataVerifier.t(), String.t()) ::
          {:ok, AppTransaction.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_app_transaction(verifier, signed_app_transaction),
    to: SignedDataVerifier

  @spec verify_and_decode_realtime_request(SignedDataVerifier.t(), String.t()) ::
          {:ok, DecodedRealtimeRequestBody.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_realtime_request(verifier, signed_payload), to: SignedDataVerifier

  @spec verify_and_decode_summary(SignedDataVerifier.t(), String.t()) ::
          {:ok, Summary.t()}
          | {:error, {SignedDataVerifier.verification_status(), String.t()}}
  defdelegate verify_and_decode_summary(verifier, signed_payload), to: SignedDataVerifier
end
