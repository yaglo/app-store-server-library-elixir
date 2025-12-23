defmodule AppStoreServerLibrary.API.AppStoreServerAPIClient do
  @moduledoc """
  Client for interacting with the Apple App Store Server API.

  This module provides functions for all App Store Server API endpoints including:
  - Transaction history and lookup
  - Subscription management and renewal
  - Notification handling and history
  - Refund and consumption tracking
  - App purchase transactions
  - Order lookup functionality
  - Retention messaging (images and messages)
  """

  require Logger

  # Use Application.spec to get version at runtime, avoiding Mix dependency in releases
  defp library_version do
    case Application.spec(:app_store_server_library, :vsn) do
      nil -> "0.0.0"
      vsn -> to_string(vsn)
    end
  end

  defp user_agent, do: "app-store-server-library/elixir/#{library_version()}"

  alias AppStoreServerLibrary.Models.{
    AppTransactionInfoResponse,
    CheckTestNotificationResponse,
    ConsumptionRequest,
    DefaultConfigurationRequest,
    Environment,
    ExtendRenewalDateRequest,
    ExtendRenewalDateResponse,
    GetImageListResponse,
    GetImageListResponseItem,
    GetMessageListResponse,
    GetMessageListResponseItem,
    HistoryResponse,
    ImageState,
    InAppOwnershipType,
    MassExtendRenewalDateRequest,
    MassExtendRenewalDateResponse,
    MassExtendRenewalDateStatusResponse,
    MessageState,
    NotificationHistoryRequest,
    NotificationHistoryResponse,
    NotificationHistoryResponseItem,
    Order,
    OrderLookupResponse,
    OrderLookupStatus,
    ProductType,
    RefundHistoryResponse,
    SendAttemptItem,
    SendAttemptResult,
    SendTestNotificationResponse,
    Status,
    StatusResponse,
    TransactionHistoryRequest,
    TransactionInfoResponse,
    UpdateAppAccountTokenRequest,
    UploadMessageRequestBody
  }

  alias AppStoreServerLibrary.API.APIException
  alias AppStoreServerLibrary.Cache.TokenCache
  alias AppStoreServerLibrary.Telemetry
  alias AppStoreServerLibrary.Utility.JSON

  # Default HTTP timeouts in milliseconds
  @default_connect_timeout 30_000
  @default_receive_timeout 60_000

  @enforce_keys [:signing_key, :key_id, :issuer_id, :bundle_id, :environment]
  defstruct [
    :base_url,
    :signing_key,
    :key_id,
    :issuer_id,
    :bundle_id,
    :environment,
    jwt_expiration: 300,
    connect_timeout: @default_connect_timeout,
    receive_timeout: @default_receive_timeout
  ]

  @type t :: %__MODULE__{
          base_url: String.t(),
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t(),
          environment: Environment.t(),
          jwt_expiration: integer(),
          connect_timeout: pos_integer(),
          receive_timeout: pos_integer()
        }

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t(),
          environment: Environment.t(),
          jwt_expiration: integer(),
          connect_timeout: pos_integer(),
          receive_timeout: pos_integer()
        ]

  @doc """
  Create a new App Store Server API client.

  ## Options

    * `:signing_key` - Private key content as string (PEM format) - **required**
    * `:key_id` - Key ID from App Store Connect - **required**
    * `:issuer_id` - Issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle identifier - **required**
    * `:environment` - `:sandbox`, `:production`, or `:local_testing` - **required**
    * `:jwt_expiration` - JWT expiration time in seconds (default: 300)
    * `:connect_timeout` - HTTP connect timeout in milliseconds (default: 30,000)
    * `:receive_timeout` - HTTP receive timeout in milliseconds (default: 60,000)

  ## Examples

      client = AppStoreServerAPIClient.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app",
        environment: :sandbox
      )

  """
  @spec new(options()) ::
          {:ok, t()}
          | {:error,
             :invalid_environment
             | :xcode_not_supported
             | {:missing_option, atom()}}
  def new(opts) when is_list(opts) do
    with {:ok, signing_key} <- fetch_required(opts, :signing_key),
         {:ok, key_id} <- fetch_required(opts, :key_id),
         {:ok, issuer_id} <- fetch_required(opts, :issuer_id),
         {:ok, bundle_id} <- fetch_required(opts, :bundle_id),
         {:ok, environment} <- fetch_required(opts, :environment),
         {:ok, base_url} <- get_base_url(environment) do
      jwt_expiration = Keyword.get(opts, :jwt_expiration, 300)
      connect_timeout = Keyword.get(opts, :connect_timeout, @default_connect_timeout)
      receive_timeout = Keyword.get(opts, :receive_timeout, @default_receive_timeout)

      client = %__MODULE__{
        base_url: base_url,
        signing_key: signing_key,
        key_id: key_id,
        issuer_id: issuer_id,
        bundle_id: bundle_id,
        environment: environment,
        jwt_expiration: jwt_expiration,
        connect_timeout: connect_timeout,
        receive_timeout: receive_timeout
      }

      {:ok, client}
    end
  end

  defp fetch_required(opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_option, key}}
    end
  end

  # API Endpoint Functions

  @doc """
  Extends the renewal date of a customer's active subscription using the original transaction identifier.
  """
  @spec extend_subscription_renewal_date(t(), String.t(), ExtendRenewalDateRequest.t()) ::
          {:ok, ExtendRenewalDateResponse.t()} | {:error, APIException.t()}
  def extend_subscription_renewal_date(client, original_transaction_id, request) do
    path = "/inApps/v1/subscriptions/extend/#{original_transaction_id}"
    make_request(client, :put, path, %{}, request, ExtendRenewalDateResponse)
  end

  @doc """
  Get information about a single transaction for your app.
  """
  @spec get_transaction_info(t(), String.t()) ::
          {:ok, TransactionInfoResponse.t()} | {:error, APIException.t()}
  def get_transaction_info(client, transaction_id) do
    path = "/inApps/v1/transactions/#{transaction_id}"
    make_request(client, :get, path, %{}, nil, TransactionInfoResponse)
  end

  @doc """
  Get a customer's in-app purchase transaction history for your app.

  See: https://developer.apple.com/documentation/appstoreserverapi/get_transaction_history
  """
  @spec get_transaction_history(
          t(),
          String.t(),
          String.t() | nil,
          TransactionHistoryRequest.t()
        ) ::
          {:ok, HistoryResponse.t()} | {:error, APIException.t()}
  def get_transaction_history(client, transaction_id, revision \\ nil, request) do
    path = "/inApps/v2/history/#{transaction_id}"
    params = build_history_params(revision, request)
    make_request(client, :get, path, params, nil, HistoryResponse)
  end

  @doc """
  Get the statuses for all of a customer's auto-renewable subscriptions in your app.
  """
  @spec get_all_subscription_statuses(t(), String.t(), [Status.t()] | nil) ::
          {:ok, StatusResponse.t()} | {:error, APIException.t()}
  def get_all_subscription_statuses(client, transaction_id, status \\ nil) do
    path = "/inApps/v1/subscriptions/#{transaction_id}"

    params =
      if status,
        do: %{
          "status" => Enum.map(status, &Status.to_integer/1)
        },
        else: %{}

    make_request(client, :get, path, params, nil, StatusResponse)
  end

  @doc """
  Uses a subscription's product identifier to extend the renewal date for all of its eligible active subscribers.
  """
  @spec extend_renewal_date_for_all_active_subscribers(t(), MassExtendRenewalDateRequest.t()) ::
          {:ok, MassExtendRenewalDateResponse.t()} | {:error, APIException.t()}
  def extend_renewal_date_for_all_active_subscribers(client, request) do
    path = "/inApps/v1/subscriptions/extend/mass"
    make_request(client, :post, path, %{}, request, MassExtendRenewalDateResponse)
  end

  @doc """
  Checks whether a renewal date extension request completed, and provides the final count of successful or failed extensions.
  """
  @spec get_status_of_subscription_renewal_date_extensions(t(), String.t(), String.t()) ::
          {:ok, MassExtendRenewalDateStatusResponse.t()} | {:error, APIException.t()}
  def get_status_of_subscription_renewal_date_extensions(client, request_identifier, product_id) do
    path = "/inApps/v1/subscriptions/extend/mass/#{product_id}/#{request_identifier}"
    make_request(client, :get, path, %{}, nil, MassExtendRenewalDateStatusResponse)
  end

  @doc """
  Get a paginated list of all of a customer's refunded in-app purchases for your app.
  """
  @spec get_refund_history(t(), String.t(), String.t() | nil) ::
          {:ok, RefundHistoryResponse.t()} | {:error, APIException.t()}
  def get_refund_history(client, transaction_id, revision \\ nil) do
    path = "/inApps/v2/refund/lookup/#{transaction_id}"
    params = if revision, do: %{"revision" => revision}, else: %{}
    make_request(client, :get, path, params, nil, RefundHistoryResponse)
  end

  @doc """
  Get a customer's in-app purchases from a receipt using the order ID.
  """
  @spec look_up_order_id(t(), String.t()) ::
          {:ok, OrderLookupResponse.t()} | {:error, APIException.t()}
  def look_up_order_id(client, order_id) do
    path = "/inApps/v1/lookup/#{order_id}"
    make_request(client, :get, path, %{}, nil, OrderLookupResponse)
  end

  @doc """
  Ask App Store Server Notifications to send a test notification to your server.
  """
  @spec request_test_notification(t()) ::
          {:ok, SendTestNotificationResponse.t()} | {:error, APIException.t()}
  def request_test_notification(client) do
    path = "/inApps/v1/notifications/test"
    make_request(client, :post, path, %{}, nil, SendTestNotificationResponse)
  end

  @doc """
  Check the status of the test App Store server notification sent to your server.
  """
  @spec get_test_notification_status(t(), String.t()) ::
          {:ok, CheckTestNotificationResponse.t()} | {:error, APIException.t()}
  def get_test_notification_status(client, test_notification_token) do
    path = "/inApps/v1/notifications/test/#{test_notification_token}"
    make_request(client, :get, path, %{}, nil, CheckTestNotificationResponse)
  end

  @doc """
  Get a list of notifications that the App Store server attempted to send to your server.
  """
  @spec get_notification_history(t(), String.t() | nil, NotificationHistoryRequest.t()) ::
          {:ok, NotificationHistoryResponse.t()} | {:error, APIException.t()}
  def get_notification_history(client, pagination_token \\ nil, request) do
    path = "/inApps/v1/notifications/history"
    params = if pagination_token, do: %{"paginationToken" => pagination_token}, else: %{}
    make_request(client, :post, path, params, request, NotificationHistoryResponse)
  end

  @doc """
  Send consumption information about an In-App Purchase to the App Store after your server receives a consumption request notification.
  """
  @spec send_consumption_information(t(), String.t(), ConsumptionRequest.t()) ::
          :ok | {:error, APIException.t()}
  def send_consumption_information(client, transaction_id, request) do
    path = "/inApps/v2/transactions/consumption/#{transaction_id}"
    make_request(client, :put, path, %{}, request, nil)
  end

  @doc """
  Sets the app account token value for a purchase the customer makes outside your app.
  """
  @spec set_app_account_token(t(), String.t(), UpdateAppAccountTokenRequest.t()) ::
          :ok | {:error, APIException.t()}
  def set_app_account_token(client, original_transaction_id, request) do
    path = "/inApps/v1/transactions/#{original_transaction_id}/appAccountToken"
    make_request(client, :put, path, %{}, request, nil)
  end

  @doc """
  Get a customer's app transaction information for your app.
  """
  @spec get_app_transaction_info(t(), String.t()) ::
          {:ok, AppTransactionInfoResponse.t()} | {:error, APIException.t()}
  def get_app_transaction_info(client, transaction_id) do
    path = "/inApps/v1/transactions/appTransactions/#{transaction_id}"
    make_request(client, :get, path, %{}, nil, AppTransactionInfoResponse)
  end

  # Retention Messaging Functions

  # PNG magic bytes: 0x89 P N G \r \n 0x1A \n
  @png_magic_bytes <<137, 80, 78, 71, 13, 10, 26, 10>>

  @doc """
  Upload an image to use for retention messaging.

  The image must be a valid PNG file (verified by checking magic bytes).
  """
  @spec upload_image(t(), String.t(), binary()) ::
          :ok | {:error, APIException.t() | :invalid_png}
  def upload_image(client, image_identifier, image) do
    if valid_png?(image) do
      path = "/inApps/v1/messaging/image/#{image_identifier}"
      make_request(client, :put, path, %{}, image, nil, "image/png")
    else
      {:error, :invalid_png}
    end
  end

  defp valid_png?(<<@png_magic_bytes, _rest::binary>>), do: true
  defp valid_png?(_), do: false

  @doc """
  Delete a previously uploaded image.
  """
  @spec delete_image(t(), String.t()) :: :ok | {:error, APIException.t()}
  def delete_image(client, image_identifier) do
    path = "/inApps/v1/messaging/image/#{image_identifier}"
    make_request(client, :delete, path, %{}, nil, nil)
  end

  @doc """
  Get the image identifier and state for all uploaded images.
  """
  @spec get_image_list(t()) ::
          {:ok, GetImageListResponse.t()} | {:error, APIException.t()}
  def get_image_list(client) do
    path = "/inApps/v1/messaging/image/list"
    make_request(client, :get, path, %{}, nil, GetImageListResponse)
  end

  @doc """
  Upload a message to use for retention messaging.
  """
  @spec upload_message(t(), String.t(), UploadMessageRequestBody.t()) ::
          :ok | {:error, APIException.t()}
  def upload_message(client, message_identifier, request) do
    path = "/inApps/v1/messaging/message/#{message_identifier}"
    make_request(client, :put, path, %{}, request, nil)
  end

  @doc """
  Delete a previously uploaded message.
  """
  @spec delete_message(t(), String.t()) :: :ok | {:error, APIException.t()}
  def delete_message(client, message_identifier) do
    path = "/inApps/v1/messaging/message/#{message_identifier}"
    make_request(client, :delete, path, %{}, nil, nil)
  end

  @doc """
  Get the message identifier and state of all uploaded messages.
  """
  @spec get_message_list(t()) ::
          {:ok, GetMessageListResponse.t()} | {:error, APIException.t()}
  def get_message_list(client) do
    path = "/inApps/v1/messaging/message/list"
    make_request(client, :get, path, %{}, nil, GetMessageListResponse)
  end

  @doc """
  Configure a default message for a specific product in a specific locale.
  """
  @spec configure_default_message(t(), String.t(), String.t(), DefaultConfigurationRequest.t()) ::
          :ok | {:error, APIException.t()}
  def configure_default_message(client, product_id, locale, request) do
    path = "/inApps/v1/messaging/default/#{product_id}/#{locale}"
    make_request(client, :put, path, %{}, request, nil)
  end

  @doc """
  Delete a default message for a product in a locale.
  """
  @spec delete_default_message(t(), String.t(), String.t()) :: :ok | {:error, APIException.t()}
  def delete_default_message(client, product_id, locale) do
    path = "/inApps/v1/messaging/default/#{product_id}/#{locale}"
    make_request(client, :delete, path, %{}, nil, nil)
  end

  # Bang functions (raise on error)

  @doc """
  Same as `get_transaction_info/2` but raises `APIException` on error.
  """
  @spec get_transaction_info!(t(), String.t()) :: TransactionInfoResponse.t()
  def get_transaction_info!(client, transaction_id) do
    get_transaction_info(client, transaction_id) |> handle_bang_result()
  end

  @doc """
  Same as `get_transaction_history/4` but raises `APIException` on error.
  """
  @spec get_transaction_history!(t(), String.t(), String.t() | nil, TransactionHistoryRequest.t()) ::
          HistoryResponse.t()
  def get_transaction_history!(client, transaction_id, revision \\ nil, request) do
    get_transaction_history(client, transaction_id, revision, request) |> handle_bang_result()
  end

  @doc """
  Same as `get_all_subscription_statuses/3` but raises `APIException` on error.
  """
  @spec get_all_subscription_statuses!(t(), String.t(), [Status.t()] | nil) :: StatusResponse.t()
  def get_all_subscription_statuses!(client, transaction_id, status \\ nil) do
    get_all_subscription_statuses(client, transaction_id, status) |> handle_bang_result()
  end

  @doc """
  Same as `get_refund_history/3` but raises `APIException` on error.
  """
  @spec get_refund_history!(t(), String.t(), String.t() | nil) :: RefundHistoryResponse.t()
  def get_refund_history!(client, transaction_id, revision \\ nil) do
    get_refund_history(client, transaction_id, revision) |> handle_bang_result()
  end

  @doc """
  Same as `look_up_order_id/2` but raises `APIException` on error.
  """
  @spec look_up_order_id!(t(), String.t()) :: OrderLookupResponse.t()
  def look_up_order_id!(client, order_id) do
    look_up_order_id(client, order_id) |> handle_bang_result()
  end

  @doc """
  Same as `request_test_notification/1` but raises `APIException` on error.
  """
  @spec request_test_notification!(t()) :: SendTestNotificationResponse.t()
  def request_test_notification!(client) do
    request_test_notification(client) |> handle_bang_result()
  end

  @doc """
  Same as `get_notification_history/3` but raises `APIException` on error.
  """
  @spec get_notification_history!(t(), String.t() | nil, NotificationHistoryRequest.t()) ::
          NotificationHistoryResponse.t()
  def get_notification_history!(client, pagination_token \\ nil, request) do
    get_notification_history(client, pagination_token, request) |> handle_bang_result()
  end

  @doc """
  Same as `get_app_transaction_info/2` but raises `APIException` on error.
  """
  @spec get_app_transaction_info!(t(), String.t()) :: AppTransactionInfoResponse.t()
  def get_app_transaction_info!(client, transaction_id) do
    get_app_transaction_info(client, transaction_id) |> handle_bang_result()
  end

  @doc """
  Same as `extend_subscription_renewal_date/3` but raises `APIException` on error.
  """
  @spec extend_subscription_renewal_date!(t(), String.t(), ExtendRenewalDateRequest.t()) ::
          ExtendRenewalDateResponse.t()
  def extend_subscription_renewal_date!(client, original_transaction_id, request) do
    extend_subscription_renewal_date(client, original_transaction_id, request)
    |> handle_bang_result()
  end

  @doc """
  Same as `extend_renewal_date_for_all_active_subscribers/2` but raises `APIException` on error.
  """
  @spec extend_renewal_date_for_all_active_subscribers!(t(), MassExtendRenewalDateRequest.t()) ::
          MassExtendRenewalDateResponse.t()
  def extend_renewal_date_for_all_active_subscribers!(client, request) do
    extend_renewal_date_for_all_active_subscribers(client, request) |> handle_bang_result()
  end

  @doc """
  Same as `get_status_of_subscription_renewal_date_extensions/3` but raises `APIException` on error.
  """
  @spec get_status_of_subscription_renewal_date_extensions!(t(), String.t(), String.t()) ::
          MassExtendRenewalDateStatusResponse.t()
  def get_status_of_subscription_renewal_date_extensions!(
        client,
        request_identifier,
        product_id
      ) do
    get_status_of_subscription_renewal_date_extensions(client, request_identifier, product_id)
    |> handle_bang_result()
  end

  @doc """
  Same as `get_test_notification_status/2` but raises `APIException` on error.
  """
  @spec get_test_notification_status!(t(), String.t()) :: CheckTestNotificationResponse.t()
  def get_test_notification_status!(client, test_notification_token) do
    get_test_notification_status(client, test_notification_token) |> handle_bang_result()
  end

  @doc """
  Same as `send_consumption_information/3` but raises `APIException` on error.
  """
  @spec send_consumption_information!(t(), String.t(), ConsumptionRequest.t()) :: :ok
  def send_consumption_information!(client, transaction_id, request) do
    send_consumption_information(client, transaction_id, request) |> handle_bang_result()
  end

  @doc """
  Same as `set_app_account_token/3` but raises `APIException` on error.
  """
  @spec set_app_account_token!(t(), String.t(), UpdateAppAccountTokenRequest.t()) :: :ok
  def set_app_account_token!(client, original_transaction_id, request) do
    set_app_account_token(client, original_transaction_id, request) |> handle_bang_result()
  end

  # Retention Messaging Bang Functions

  @doc """
  Same as `upload_image/3` but raises `APIException` on error.

  Raises `ArgumentError` if the image is not a valid PNG.
  """
  @spec upload_image!(t(), String.t(), binary()) :: :ok
  def upload_image!(client, image_identifier, image) do
    case upload_image(client, image_identifier, image) do
      :ok -> :ok
      {:error, :invalid_png} -> raise ArgumentError, "image must be a valid PNG file"
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `delete_image/2` but raises `APIException` on error.
  """
  @spec delete_image!(t(), String.t()) :: :ok
  def delete_image!(client, image_identifier) do
    delete_image(client, image_identifier) |> handle_bang_result()
  end

  @doc """
  Same as `get_image_list/1` but raises `APIException` on error.
  """
  @spec get_image_list!(t()) :: GetImageListResponse.t()
  def get_image_list!(client) do
    get_image_list(client) |> handle_bang_result()
  end

  @doc """
  Same as `upload_message/3` but raises `APIException` on error.
  """
  @spec upload_message!(t(), String.t(), UploadMessageRequestBody.t()) :: :ok
  def upload_message!(client, message_identifier, request) do
    upload_message(client, message_identifier, request) |> handle_bang_result()
  end

  @doc """
  Same as `delete_message/2` but raises `APIException` on error.
  """
  @spec delete_message!(t(), String.t()) :: :ok
  def delete_message!(client, message_identifier) do
    delete_message(client, message_identifier) |> handle_bang_result()
  end

  @doc """
  Same as `get_message_list/1` but raises `APIException` on error.
  """
  @spec get_message_list!(t()) :: GetMessageListResponse.t()
  def get_message_list!(client) do
    get_message_list(client) |> handle_bang_result()
  end

  @doc """
  Same as `configure_default_message/4` but raises `APIException` on error.
  """
  @spec configure_default_message!(t(), String.t(), String.t(), DefaultConfigurationRequest.t()) ::
          :ok
  def configure_default_message!(client, product_id, locale, request) do
    configure_default_message(client, product_id, locale, request) |> handle_bang_result()
  end

  @doc """
  Same as `delete_default_message/3` but raises `APIException` on error.
  """
  @spec delete_default_message!(t(), String.t(), String.t()) :: :ok
  def delete_default_message!(client, product_id, locale) do
    delete_default_message(client, product_id, locale) |> handle_bang_result()
  end

  # Private helper functions

  defp handle_bang_result({:ok, response}), do: response
  defp handle_bang_result(:ok), do: :ok
  defp handle_bang_result({:error, exception}), do: raise(exception)

  defp get_base_url(:production), do: {:ok, "https://api.storekit.itunes.apple.com"}
  defp get_base_url(:sandbox), do: {:ok, "https://api.storekit-sandbox.itunes.apple.com"}
  defp get_base_url(:local_testing), do: {:ok, "https://local-testing-base-url"}

  defp get_base_url(:xcode) do
    {:error, :xcode_not_supported}
  end

  defp get_base_url(_), do: {:error, :invalid_environment}

  defp build_history_params(revision, request) do
    %{}
    |> maybe_put("revision", revision, & &1)
    |> maybe_put("startDate", request.start_date, &to_string/1)
    |> maybe_put("endDate", request.end_date, &to_string/1)
    |> maybe_put("productId", request.product_ids, & &1)
    |> maybe_put("productType", request.product_types, fn list ->
      Enum.map(list, &ProductType.to_string/1)
    end)
    |> maybe_put("sort", request.sort, &Order.to_string/1)
    |> maybe_put("subscriptionGroupIdentifier", request.subscription_group_identifiers, & &1)
    |> maybe_put(
      "inAppOwnershipType",
      request.in_app_ownership_type,
      &InAppOwnershipType.to_string/1
    )
    |> maybe_put("revoked", request.revoked, &to_string/1)
  end

  defp maybe_put(params, _key, nil, _transform), do: params
  defp maybe_put(params, key, value, transform), do: Map.put(params, key, transform.(value))

  defp make_request(
         client,
         method,
         path,
         params,
         body,
         response_module,
         content_type \\ "application/json"
       ) do
    metadata = %{method: method, path: path}

    Telemetry.span([:app_store_server_library, :api, :request], metadata, fn ->
      url = client.base_url <> path
      headers = get_headers(client) |> Map.put("Content-Type", content_type)

      case make_http_request(client, method, url, params, headers, body) do
        {:ok, status_code, response_body} when status_code in 200..299 ->
          handle_success_response(response_body, response_module, status_code)

        {:ok, status_code, error_body} ->
          handle_error_response(status_code, error_body)

        {:error, status_code, error_body} when is_integer(status_code) ->
          handle_error_response(status_code, error_body)

        {:error, %APIException{} = exception} ->
          {:error, exception}

        {:error, reason} ->
          {:error, APIException.new(0, nil, "Network error: #{inspect(reason)}")}
      end
    end)
  end

  defp get_headers(client) do
    token = get_or_generate_token(client)

    %{
      "User-Agent" => user_agent(),
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end

  defp get_or_generate_token(client) do
    # Use cache key based on client identity
    client_key = {client.key_id, client.issuer_id, client.bundle_id}

    TokenCache.get_or_generate(client_key, fn ->
      generate_jwt_token(client)
    end)
  end

  defp generate_jwt_token(client) do
    Telemetry.span([:app_store_server_library, :jwt, :generate], %{}, fn ->
      now = System.system_time(:second)
      exp = now + client.jwt_expiration

      claims = %{
        "iss" => client.issuer_id,
        "iat" => now,
        "exp" => exp,
        "aud" => "appstoreconnect-v1",
        "bid" => client.bundle_id
      }

      # Create JWK from private key
      jwk = JOSE.JWK.from_pem(client.signing_key)

      # Create JWS fields with alg and kid
      jws_fields = %{"alg" => "ES256", "kid" => client.key_id}

      # Sign JWT
      signed = JOSE.JWT.sign(jwk, jws_fields, claims)
      {_, jwt} = JOSE.JWS.compact(signed)
      jwt
    end)
  end

  defp make_http_request(client, method, url, params, headers, body) do
    req_headers = normalize_headers(headers)
    url_with_params = append_query_params(url, params)

    req_options = [
      headers: req_headers,
      connect_options: [timeout: client.connect_timeout],
      receive_timeout: client.receive_timeout
    ]

    body_options = body_options(body, req_options)

    method
    |> dispatch_request(url_with_params, req_options, body_options)
    |> normalize_response()
  end

  defp append_query_params(url, params) when map_size(params) == 0, do: url

  defp append_query_params(url, params) do
    query_string =
      params
      |> Enum.flat_map(fn
        {key, values} when is_list(values) ->
          Enum.map(values, fn value -> {key, value} end)

        {key, value} ->
          [{key, value}]
      end)
      |> URI.encode_query()

    "#{url}?#{query_string}"
  end

  defp normalize_headers(headers) do
    # Convert headers map to lowercase keys for Req compatibility
    headers
    |> Enum.into(%{}, fn {key, value} -> {String.downcase(key), value} end)
  end

  defp body_options(body, req_options) when is_binary(body),
    do: Keyword.put(req_options, :body, body)

  defp body_options(nil, req_options), do: req_options

  defp body_options(body, req_options), do: Keyword.put(req_options, :json, body)

  defp dispatch_request(:get, url, req_options, _body_options), do: Req.get(url, req_options)

  defp dispatch_request(:delete, url, req_options, _body_options),
    do: Req.delete(url, req_options)

  defp dispatch_request(:post, url, _req_options, body_options), do: Req.post(url, body_options)
  defp dispatch_request(:put, url, _req_options, body_options), do: Req.put(url, body_options)

  defp normalize_response({:ok, %{status: status, body: response_body}})
       when status in 200..299 do
    {:ok, status, response_body}
  end

  defp normalize_response({:ok, %{status: status, body: response_body}}) do
    {:error, status, response_body}
  end

  defp normalize_response({:error, reason}), do: {:error, reason}

  defp handle_success_response(_response_body, nil, _status_code), do: :ok

  defp handle_success_response(response_body, response_module, status_code) do
    # Check if response_body is already a map (from Req) or a JSON string
    data =
      if is_map(response_body) do
        {:ok, response_body}
      else
        Jason.decode(response_body)
      end

    case data do
      {:ok, decoded} ->
        # Convert camelCase string keys to snake_case atom keys for struct creation
        atom_data =
          decoded
          |> reduce_to_atom_map(response_module)
          |> add_raw_environment_field(decoded)
          |> add_raw_status_field(decoded)
          |> add_raw_first_send_attempt_result(decoded)

        {:ok, struct(response_module, atom_data)}

      {:error, reason} ->
        {:error,
         APIException.new(
           status_code,
           nil,
           "Failed to decode API response body: #{inspect(reason)}"
         )}
    end
  end

  # Add raw_environment field when environment is present
  defp add_raw_environment_field(atom_data, original_data) do
    if Map.has_key?(original_data, "environment") and is_binary(original_data["environment"]) do
      Map.put(atom_data, :raw_environment, original_data["environment"])
    else
      atom_data
    end
  end

  # Add raw_status field when status is present
  defp add_raw_status_field(atom_data, original_data) do
    if Map.has_key?(original_data, "status") and is_integer(original_data["status"]) do
      Map.put(atom_data, :raw_status, original_data["status"])
    else
      atom_data
    end
  end

  defp add_raw_first_send_attempt_result(atom_data, original_data) do
    if Map.has_key?(original_data, "firstSendAttemptResult") and
         is_binary(original_data["firstSendAttemptResult"]) do
      Map.put(atom_data, :raw_first_send_attempt_result, original_data["firstSendAttemptResult"])
    else
      atom_data
    end
  end

  # Convert field values based on field name
  defp convert_field_value(:environment, value) when is_binary(value) do
    Environment.from_string(value)
  end

  defp convert_field_value(:image_state, value) when is_binary(value) do
    ImageState.from_string(value)
  end

  defp convert_field_value(:message_state, value) when is_binary(value) do
    MessageState.from_string(value)
  end

  defp convert_field_value(:image_identifiers, value) when is_list(value) do
    Enum.map(value, fn item ->
      convert_nested_response(item, GetImageListResponseItem)
    end)
  end

  defp convert_field_value(:message_identifiers, value) when is_list(value) do
    Enum.map(value, fn item ->
      convert_nested_response(item, GetMessageListResponseItem)
    end)
  end

  defp convert_field_value(:notification_history, value) when is_list(value) do
    Enum.map(value, fn item ->
      convert_nested_response(item, NotificationHistoryResponseItem)
    end)
  end

  defp convert_field_value(:status, value) when is_integer(value) do
    OrderLookupStatus.from_integer(value)
  end

  defp convert_field_value(:send_attempts, value) when is_list(value) do
    Enum.map(value, fn item -> convert_nested_response(item, SendAttemptItem) end)
  end

  defp convert_field_value(:send_attempt_result, value) when is_binary(value) do
    SendAttemptResult.from_string(value)
  end

  defp convert_field_value(:first_send_attempt_result, value) when is_binary(value) do
    SendAttemptResult.from_string(value)
  end

  defp convert_field_value(_field_name, value), do: value

  defp reduce_to_atom_map(data, _module) do
    Enum.reduce(data, %{}, fn {k, v}, acc ->
      atom_key = JSON.camel_to_snake_atom(k)
      Map.put(acc, atom_key, convert_field_value(atom_key, v))
    end)
  end

  # Convert nested response objects to structs
  defp convert_nested_response(data, module) when is_map(data) do
    _ = Code.ensure_loaded(module)

    atom_data =
      data
      |> reduce_to_atom_map(module)
      |> maybe_add_raw_send_attempt_result(module, data)
      |> maybe_add_raw_first_send_attempt_result(module, data)

    struct(module, atom_data)
  end

  defp convert_nested_response(value, _module), do: value

  defp maybe_add_raw_send_attempt_result(atom_data, SendAttemptItem, original_data) do
    if Map.has_key?(original_data, "sendAttemptResult") and
         is_binary(original_data["sendAttemptResult"]) do
      Map.put(atom_data, :raw_send_attempt_result, original_data["sendAttemptResult"])
    else
      atom_data
    end
  end

  defp maybe_add_raw_send_attempt_result(atom_data, _module, _original_data), do: atom_data

  defp maybe_add_raw_first_send_attempt_result(
         atom_data,
         NotificationHistoryResponseItem,
         original_data
       ) do
    if Map.has_key?(original_data, "firstSendAttemptResult") and
         is_binary(original_data["firstSendAttemptResult"]) do
      Map.put(atom_data, :raw_first_send_attempt_result, original_data["firstSendAttemptResult"])
    else
      atom_data
    end
  end

  defp maybe_add_raw_first_send_attempt_result(atom_data, _module, _original_data), do: atom_data

  defp handle_error_response(status_code, %{"errorCode" => error_code} = error_body) do
    {:error, APIException.new(status_code, error_code, Map.get(error_body, "errorMessage"))}
  end

  defp handle_error_response(status_code, error_body) when is_map(error_body) do
    message =
      Map.get(error_body, "errorMessage") ||
        Map.get(error_body, "message") ||
        Map.get(error_body, "error") ||
        "Unknown error"

    {:error, APIException.new(status_code, nil, message)}
  end

  defp handle_error_response(status_code, error_body) when is_binary(error_body) do
    case Jason.decode(error_body) do
      {:ok, decoded} -> handle_error_response(status_code, decoded)
      {:error, _} -> {:error, APIException.new(status_code, nil, "Unknown error")}
    end
  end

  defp handle_error_response(status_code, error_body) do
    {:error, APIException.new(status_code, nil, "Unknown error: #{inspect(error_body)}")}
  end
end
