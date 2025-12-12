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
  @library_version Mix.Project.config()[:version]
  @user_agent "app-store-server-library/elixir/#{@library_version}"

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
    MassExtendRenewalDateRequest,
    MassExtendRenewalDateResponse,
    MassExtendRenewalDateStatusResponse,
    NotificationHistoryRequest,
    NotificationHistoryResponse,
    OrderLookupResponse,
    OrderLookupStatus,
    RefundHistoryResponse,
    SendAttemptItem,
    SendAttemptResult,
    NotificationHistoryResponseItem,
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

  @enforce_keys [:signing_key, :key_id, :issuer_id, :bundle_id, :environment]
  defstruct [
    :base_url,
    :signing_key,
    :key_id,
    :issuer_id,
    :bundle_id,
    :environment
  ]

  @type t :: %__MODULE__{
          base_url: String.t(),
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t(),
          environment: Environment.t()
        }

  @type options :: [
          signing_key: String.t(),
          key_id: String.t(),
          issuer_id: String.t(),
          bundle_id: String.t(),
          environment: Environment.t()
        ]

  @doc """
  Create a new App Store Server API client.

  ## Options

    * `:signing_key` - Private key content as string (PEM format) - **required**
    * `:key_id` - Key ID from App Store Connect - **required**
    * `:issuer_id` - Issuer ID from App Store Connect - **required**
    * `:bundle_id` - Your app's bundle identifier - **required**
    * `:environment` - `:sandbox`, `:production`, or `:local_testing` - **required**

  ## Examples

      client = AppStoreServerAPIClient.new(
        signing_key: File.read!("private_key.p8"),
        key_id: "YOUR_KEY_ID",
        issuer_id: "YOUR_ISSUER_ID",
        bundle_id: "com.example.app",
        environment: :sandbox
      )

  """
  @spec new(options()) :: t()
  def new(opts) when is_list(opts) do
    signing_key = Keyword.fetch!(opts, :signing_key)
    key_id = Keyword.fetch!(opts, :key_id)
    issuer_id = Keyword.fetch!(opts, :issuer_id)
    bundle_id = Keyword.fetch!(opts, :bundle_id)
    environment = Keyword.fetch!(opts, :environment)

    base_url = get_base_url(environment)

    %__MODULE__{
      base_url: base_url,
      signing_key: signing_key,
      key_id: key_id,
      issuer_id: issuer_id,
      bundle_id: bundle_id,
      environment: environment
    }
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
  @spec get_all_subscription_statuses(t(), String.t(), [integer()] | nil) ::
          {:ok, StatusResponse.t()} | {:error, APIException.t()}
  def get_all_subscription_statuses(client, transaction_id, status \\ nil) do
    path = "/inApps/v1/subscriptions/#{transaction_id}"

    params =
      if status,
        do: %{
          "status" => Enum.map_join(status, ",", &Status.to_integer/1)
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
  Send consumption information about a consumable in-app purchase to the App Store.
  """
  @spec send_consumption_data(t(), String.t(), ConsumptionRequest.t()) ::
          :ok | {:error, APIException.t()}
  def send_consumption_data(client, transaction_id, request) do
    path = "/inApps/v1/transactions/consumption/#{transaction_id}"
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

  @doc """
  Upload an image to use for retention messaging.
  """
  @spec upload_image(t(), String.t(), binary()) :: :ok | {:error, APIException.t()}
  def upload_image(client, image_identifier, image) do
    path = "/inApps/v1/messaging/image/#{image_identifier}"
    make_binary_request(client, :put, path, image, "image/png")
  end

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
    case get_transaction_info(client, transaction_id) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `get_transaction_history/4` but raises `APIException` on error.
  """
  @spec get_transaction_history!(t(), String.t(), String.t() | nil, TransactionHistoryRequest.t()) ::
          HistoryResponse.t()
  def get_transaction_history!(client, transaction_id, revision \\ nil, request) do
    case get_transaction_history(client, transaction_id, revision, request) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `get_all_subscription_statuses/3` but raises `APIException` on error.
  """
  @spec get_all_subscription_statuses!(t(), String.t(), [integer()] | nil) :: StatusResponse.t()
  def get_all_subscription_statuses!(client, transaction_id, status \\ nil) do
    case get_all_subscription_statuses(client, transaction_id, status) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `get_refund_history/3` but raises `APIException` on error.
  """
  @spec get_refund_history!(t(), String.t(), String.t() | nil) :: RefundHistoryResponse.t()
  def get_refund_history!(client, transaction_id, revision \\ nil) do
    case get_refund_history(client, transaction_id, revision) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `look_up_order_id/2` but raises `APIException` on error.
  """
  @spec look_up_order_id!(t(), String.t()) :: OrderLookupResponse.t()
  def look_up_order_id!(client, order_id) do
    case look_up_order_id(client, order_id) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `request_test_notification/1` but raises `APIException` on error.
  """
  @spec request_test_notification!(t()) :: SendTestNotificationResponse.t()
  def request_test_notification!(client) do
    case request_test_notification(client) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `get_notification_history/3` but raises `APIException` on error.
  """
  @spec get_notification_history!(t(), String.t() | nil, NotificationHistoryRequest.t()) ::
          NotificationHistoryResponse.t()
  def get_notification_history!(client, pagination_token \\ nil, request) do
    case get_notification_history(client, pagination_token, request) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  @doc """
  Same as `get_app_transaction_info/2` but raises `APIException` on error.
  """
  @spec get_app_transaction_info!(t(), String.t()) :: AppTransactionInfoResponse.t()
  def get_app_transaction_info!(client, transaction_id) do
    case get_app_transaction_info(client, transaction_id) do
      {:ok, response} -> response
      {:error, exception} -> raise exception
    end
  end

  # Private helper functions

  defp get_base_url(:production), do: "https://api.storekit.itunes.apple.com"
  defp get_base_url(:sandbox), do: "https://api.storekit-sandbox.itunes.apple.com"
  defp get_base_url(:local_testing), do: "https://local-testing-base-url"

  defp get_base_url(:xcode) do
    raise ArgumentError, "Xcode is not a supported environment for an AppStoreServerAPIClient"
  end

  defp get_base_url(_), do: raise(ArgumentError, "Invalid environment")

  defp build_history_params(revision, request) do
    %{}
    |> maybe_put("revision", revision)
    |> maybe_put("startDate", request.start_date, &to_string/1)
    |> maybe_put("endDate", request.end_date, &to_string/1)
    |> maybe_put("productId", request.product_ids, &Enum.join(&1, ","))
    |> maybe_put(
      "productType",
      request.product_types,
      &Enum.map_join(&1, ",", fn pt -> TransactionHistoryRequest.product_type_to_string(pt) end)
    )
    |> maybe_put("sort", request.sort, &TransactionHistoryRequest.order_to_string/1)
    |> maybe_put(
      "subscriptionGroupIdentifier",
      request.subscription_group_identifiers,
      &Enum.join(&1, ",")
    )
    |> maybe_put(
      "inAppOwnershipType",
      request.in_app_ownership_type,
      &TransactionHistoryRequest.in_app_ownership_type_to_string/1
    )
    |> maybe_put_if_not_nil("revoked", request.revoked, &to_string/1)
  end

  defp maybe_put(params, _key, nil), do: params
  defp maybe_put(params, key, value), do: Map.put(params, key, value)

  defp maybe_put(params, _key, nil, _transform), do: params
  defp maybe_put(params, key, value, transform), do: Map.put(params, key, transform.(value))

  # Separate helper for fields where nil is distinct from unset (like revoked boolean)
  defp maybe_put_if_not_nil(params, _key, nil, _transform), do: params

  defp maybe_put_if_not_nil(params, key, value, transform),
    do: Map.put(params, key, transform.(value))

  defp make_request(client, method, path, params, body, response_module) do
    metadata = %{method: method, path: path}

    Telemetry.span([:app_store_server_library, :api, :request], metadata, fn ->
      url = client.base_url <> path
      headers = get_headers(client)

      case make_http_request(client, method, url, params, headers, body) do
        {:ok, status_code, response_body} when status_code in 200..299 ->
          handle_success_response(response_body, response_module)

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

  defp make_binary_request(client, method, path, binary_data, content_type) do
    url = client.base_url <> path
    headers = get_headers(client) |> Map.put("Content-Type", content_type)

    case make_http_request(client, method, url, %{}, headers, binary_data) do
      {:ok, status_code, _response_body} when status_code in 200..299 ->
        :ok

      {:ok, status_code, error_body} ->
        handle_error_response(status_code, error_body)

      {:error, status_code, error_body} when is_integer(status_code) ->
        handle_error_response(status_code, error_body)

      {:error, %APIException{} = exception} ->
        {:error, exception}

      {:error, reason} ->
        {:error, APIException.new(0, nil, "Network error: #{inspect(reason)}")}
    end
  end

  defp get_headers(client) do
    token = get_or_generate_token(client)

    %{
      "User-Agent" => @user_agent,
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
      # 5 minutes expiration (matching Apple's official libraries)
      exp = now + 300

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

  defp make_http_request(_client, method, url, params, headers, body) do
    req_headers = normalize_headers(headers)
    req_options = [headers: req_headers, params: params]
    body_options = body_options(body, req_options)

    method
    |> dispatch_request(url, req_options, body_options)
    |> normalize_response()
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

  defp handle_success_response(_response_body, nil), do: :ok

  defp handle_success_response(response_body, response_module) do
    # Check if response_body is already a map (from Req) or a JSON string
    data =
      if is_map(response_body) do
        response_body
      else
        case Jason.decode(response_body) do
          {:ok, decoded} -> decoded
          {:error, _} -> %{}
        end
      end

    # Convert camelCase string keys to snake_case atom keys for struct creation
    atom_data =
      data
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        case JSON.camel_to_snake_atom(k) do
          atom_key when is_atom(atom_key) ->
            Map.put(acc, atom_key, convert_field_value(atom_key, v))

          _ ->
            log_unknown_key(k, response_module)
            acc
        end
      end)
      |> add_raw_environment_field(data)
      |> add_raw_status_field(data)
      |> add_raw_first_send_attempt_result(data)

    {:ok, struct(response_module, atom_data)}
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
    case ImageState.from_string(value) do
      {:ok, atom} -> atom
      {:error, _} -> value
    end
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
    case OrderLookupStatus.from_integer(value) do
      {:ok, atom} -> atom
      {:error, _} -> value
    end
  end

  defp convert_field_value(:send_attempts, value) when is_list(value) do
    Enum.map(value, fn item -> convert_nested_response(item, SendAttemptItem) end)
  end

  defp convert_field_value(:send_attempt_result, value) when is_binary(value) do
    case SendAttemptResult.from_string(value) do
      {:ok, atom} -> atom
      {:error, _} -> value
    end
  end

  defp convert_field_value(:first_send_attempt_result, value) when is_binary(value) do
    case SendAttemptResult.from_string(value) do
      {:ok, atom} -> atom
      {:error, _} -> value
    end
  end

  defp convert_field_value(_field_name, value), do: value

  # Convert nested response objects to structs
  defp convert_nested_response(data, module) when is_map(data) do
    _ = Code.ensure_loaded(module)

    atom_data =
      data
      |> Enum.reduce(%{}, fn {k, v}, acc ->
        case JSON.camel_to_snake_atom(k) do
          atom_key when is_atom(atom_key) ->
            Map.put(acc, atom_key, convert_field_value(atom_key, v))

          _ ->
            log_unknown_key(k, module)
            acc
        end
      end)
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

  defp log_unknown_key(key, context_module) do
    Logger.debug(fn ->
      "AppStoreServerLibrary: ignoring unknown response field #{inspect(key)} for #{inspect(context_module)}"
    end)
  end
end
