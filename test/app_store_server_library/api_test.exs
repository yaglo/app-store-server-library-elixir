defmodule AppStoreServerLibrary.APITest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.API.{APIException, AppStoreServerAPIClient}
  alias AppStoreServerLibrary.Client

  alias AppStoreServerLibrary.Models.{
    ConsumptionRequest,
    DefaultConfigurationRequest,
    ExtendRenewalDateRequest,
    MassExtendRenewalDateRequest,
    Order,
    ProductType,
    TransactionHistoryRequest,
    UpdateAppAccountTokenRequest
  }

  describe "AppStoreServerAPIClient" do
    test "Client.new returns tuple and Client.new! returns struct" do
      {:ok, client} =
        Client.new(
          signing_key: "test-key",
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "com.example",
          environment: :sandbox
        )

      assert %AppStoreServerAPIClient{} = client

      assert Client.new!(
               signing_key: "test-key",
               key_id: "keyId",
               issuer_id: "issuerId",
               bundle_id: "com.example",
               environment: :sandbox
             )
    end

    test "creates client with valid parameters" do
      {:ok, client} =
        AppStoreServerAPIClient.new(
          signing_key: "test-key",
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "com.example",
          environment: :sandbox
        )

      assert client.signing_key == "test-key"
      assert client.key_id == "keyId"
      assert client.issuer_id == "issuerId"
      assert client.bundle_id == "com.example"
      assert client.environment == :sandbox
      assert client.base_url == "https://api.storekit-sandbox.itunes.apple.com"
    end

    test "creates client with production environment" do
      {:ok, client} =
        AppStoreServerAPIClient.new(
          signing_key: "test-key",
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "com.example",
          environment: :production
        )

      assert client.environment == :production
      assert client.base_url == "https://api.storekit.itunes.apple.com"
    end

    test "creates client with local testing environment" do
      {:ok, client} =
        AppStoreServerAPIClient.new(
          signing_key: "test-key",
          key_id: "keyId",
          issuer_id: "issuerId",
          bundle_id: "com.example",
          environment: :local_testing
        )

      assert client.environment == :local_testing
      assert client.base_url == "https://local-testing-base-url"
    end

    test "extend_renewal_date_for_all_active_subscribers" do
      bypass = Bypass.open()

      client = %AppStoreServerAPIClient{
        signing_key: File.read!("test/resources/certs/testSigningKey.p8"),
        key_id: "keyId",
        issuer_id: "issuerId",
        bundle_id: "com.example",
        environment: :sandbox,
        base_url: "http://localhost:#{bypass.port}"
      }

      request = %MassExtendRenewalDateRequest{
        extend_by_days: 45,
        extend_reason_code: :customer_satisfaction,
        request_identifier: "fdf964a4-233b-486c-aac1-97d8d52688ac",
        storefront_country_codes: ["USA", "MEX"],
        product_id: "com.example.productId"
      }

      # Mock the HTTP request
      Bypass.expect(bypass, "POST", "/inApps/v1/subscriptions/extend/mass", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        assert {"content-type", "application/json"} =
                 List.keyfind(conn.req_headers, "content-type", 0)

        # Return mock response
        response_body =
          File.read!(
            "test/resources/models/extendRenewalDateForAllActiveSubscribersResponse.json"
          )

        Plug.Conn.resp(conn, 200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.extend_renewal_date_for_all_active_subscribers(client, request)

      assert response.request_identifier == "758883e8-151b-47b7-abd0-60c4d804c2f5"
    end

    test "extend_subscription_renewal_date" do
      bypass = Bypass.open()

      client = %AppStoreServerAPIClient{
        signing_key: File.read!("test/resources/certs/testSigningKey.p8"),
        key_id: "keyId",
        issuer_id: "issuerId",
        bundle_id: "com.example",
        environment: :sandbox,
        base_url: "http://localhost:#{bypass.port}"
      }

      request = %ExtendRenewalDateRequest{
        extend_by_days: 45,
        extend_reason_code: :customer_satisfaction,
        request_identifier: "fdf964a4-233b-486c-aac1-97d8d52688ac"
      }

      # Mock the HTTP request
      Bypass.expect(bypass, "PUT", "/inApps/v1/subscriptions/extend/4124214", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        assert {"content-type", "application/json"} =
                 List.keyfind(conn.req_headers, "content-type", 0)

        # Return mock response
        response_body =
          File.read!("test/resources/models/extendSubscriptionRenewalDateResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.extend_subscription_renewal_date(client, "4124214", request)

      assert response.original_transaction_id == "2312412"
      assert response.web_order_line_item_id == "9993"
      assert response.success == true
      assert response.effective_date == 1_698_148_900_000
    end

    test "get_all_subscription_statuses" do
      bypass = Bypass.open()

      key_content = File.read!("test/resources/certs/testSigningKey.p8")

      client = %AppStoreServerAPIClient{
        signing_key: key_content,
        key_id: "keyId",
        issuer_id: "issuerId",
        bundle_id: "com.example",
        environment: :sandbox,
        base_url: "http://localhost:#{bypass.port}"
      }

      # Mock the HTTP request
      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/4321", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        # Verify query parameters - status values are repeated keys per Apple's API spec
        query_string = conn.query_string
        assert query_string =~ "status=2"
        assert query_string =~ "status=1"

        # Return mock response
        response_body =
          File.read!("test/resources/models/getAllSubscriptionStatusesResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.get_all_subscription_statuses(client, "4321", [
          :expired,
          :active
        ])

      assert response.environment == :local_testing
      assert response.raw_environment == "LocalTesting"
      assert response.bundle_id == "com.example"
      assert response.app_apple_id == 5_454_545
    end

    test "get_refund_history" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      # Mock the HTTP request
      Bypass.expect(bypass, "GET", "/inApps/v2/refund/lookup/555555", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        # Verify query parameters
        query_string = conn.query_string
        assert query_string =~ "revision=revision_input"

        # Return mock response
        response_body =
          File.read!("test/resources/models/getRefundHistoryResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.get_refund_history(client, "555555", "revision_input")

      assert response.signed_transactions == [
               "signed_transaction_one",
               "signed_transaction_two"
             ]
    end

    test "get_status_of_subscription_renewal_date_extensions" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v1/subscriptions/extend/mass/20fba8a0-2b80-4a7d-a17f-85c1854727f8/com.example.product",
          %{},
          nil,
          "test/resources/models/getStatusOfSubscriptionRenewalDateExtensionsResponse.json"
        )

      {:ok, response} =
        AppStoreServerAPIClient.get_status_of_subscription_renewal_date_extensions(
          client,
          "com.example.product",
          "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
        )

      assert response.request_identifier == "20fba8a0-2b80-4a7d-a17f-85c1854727f8"
      assert response.complete == true
      assert response.complete_date == 1_698_148_900_000
      assert response.succeeded_count == 30
      assert response.failed_count == 2
    end

    test "get_test_notification_status" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v1/notifications/test/8cd2974c-f905-492a-bf9a-b2f47c791d19",
          %{},
          nil,
          "test/resources/models/getTestNotificationStatusResponse.json"
        )

      {:ok, response} =
        AppStoreServerAPIClient.get_test_notification_status(
          client,
          "8cd2974c-f905-492a-bf9a-b2f47c791d19"
        )

      assert response.signed_payload == "signed_payload"
      assert length(response.send_attempts) == 2
    end

    test "get_notification_history" do
      client = create_test_client()

      params = %{"paginationToken" => ["a036bc0e-52b8-4bee-82fc-8c24cb6715d6"]}

      request = %{
        start_date: 1_698_148_900_000,
        end_date: 1_698_148_950_000,
        notification_type: :subscribed,
        notification_subtype: :initial_buy,
        transaction_id: "999733843",
        only_failures: true
      }

      client =
        expect_http_request(
          client,
          :post,
          "/inApps/v1/notifications/history",
          params,
          request,
          "test/resources/models/getNotificationHistoryResponse.json"
        )

      {:ok, response} =
        AppStoreServerAPIClient.get_notification_history(
          client,
          "a036bc0e-52b8-4bee-82fc-8c24cb6715d6",
          request
        )

      assert response.pagination_token == "57715481-805a-4283-8499-1c19b5d6b20a"
      assert response.has_more == true
    end

    test "get_transaction_history" do
      client = create_test_client()

      request = %TransactionHistoryRequest{
        sort: Order.ascending(),
        product_types: [ProductType.consumable(), ProductType.auto_renewable()],
        end_date: 123_456,
        start_date: 123_455,
        revoked: false,
        in_app_ownership_type: :family_shared,
        product_ids: ["com.example.1", "com.example.2"],
        subscription_group_identifiers: ["sub_group_id", "sub_group_id_2"]
      }

      params = %{
        "revision" => ["revision_input"],
        "startDate" => ["123455"],
        "endDate" => ["123456"],
        "productId" => ["com.example.1", "com.example.2"],
        "productType" => ["CONSUMABLE", "AUTO_RENEWABLE"],
        "sort" => ["ASCENDING"],
        "subscriptionGroupIdentifier" => ["sub_group_id", "sub_group_id_2"],
        "inAppOwnershipType" => ["FAMILY_SHARED"],
        "revoked" => ["False"]
      }

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v2/history/1234",
          params,
          nil,
          "test/resources/models/transactionHistoryResponse.json"
        )

      {:ok, response} =
        AppStoreServerAPIClient.get_transaction_history(
          client,
          "1234",
          "revision_input",
          request
        )

      assert response.revision == "revision_output"
      assert response.has_more == true
      assert response.bundle_id == "com.example"
      assert response.app_apple_id == 323_232
    end

    test "get_transaction_info" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      # Mock the HTTP request
      Bypass.expect(bypass, "GET", "/inApps/v1/transactions/1234", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        # Return mock response
        response_body =
          File.read!("test/resources/models/transactionInfoResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_transaction_info(client, "1234")

      assert response.signed_transaction_info == "signed_transaction_info_value"
    end

    test "look_up_order_id" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v1/lookup/W002182",
          %{},
          nil,
          "test/resources/models/lookupOrderIdResponse.json"
        )

      {:ok, response} = AppStoreServerAPIClient.look_up_order_id(client, "W002182")

      assert response.status == :invalid
      assert response.raw_status == 1
      assert response.signed_transactions == ["signed_transaction_one", "signed_transaction_two"]
    end

    test "request_test_notification" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :post,
          "/inApps/v1/notifications/test",
          %{},
          nil,
          "test/resources/models/requestTestNotificationResponse.json"
        )

      {:ok, response} = AppStoreServerAPIClient.request_test_notification(client)

      assert response.test_notification_token == "ce3af791-365e-4c60-841b-1674b43c1609"
    end

    test "send_consumption_information" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      request = %ConsumptionRequest{
        customer_consented: true,
        delivery_status: :delivered,
        sample_content_provided: false,
        consumption_percentage: 50_000,
        refund_preference: :decline
      }

      Bypass.expect(bypass, "PUT", "/inApps/v2/transactions/consumption/49571273", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        parsed_body = Jason.decode!(body)

        # Verify the request body is correctly serialized with camelCase keys and string values
        assert parsed_body["customerConsented"] == true
        assert parsed_body["deliveryStatus"] == "DELIVERED"
        assert parsed_body["sampleContentProvided"] == false
        assert parsed_body["consumptionPercentage"] == 50_000
        assert parsed_body["refundPreference"] == "DECLINE"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(202, "")
      end)

      result = AppStoreServerAPIClient.send_consumption_information(client, "49571273", request)
      assert result == :ok
    end

    test "send_consumption_information_minimal" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      # Test with only required fields
      request = %ConsumptionRequest{
        customer_consented: true,
        delivery_status: :undelivered_server_outage,
        sample_content_provided: true
      }

      Bypass.expect(bypass, "PUT", "/inApps/v2/transactions/consumption/12345", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        parsed_body = Jason.decode!(body)

        # Verify only required fields are present
        assert parsed_body["customerConsented"] == true
        assert parsed_body["deliveryStatus"] == "UNDELIVERED_SERVER_OUTAGE"
        assert parsed_body["sampleContentProvided"] == true
        refute Map.has_key?(parsed_body, "consumptionPercentage")
        refute Map.has_key?(parsed_body, "refundPreference")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(202, "")
      end)

      result = AppStoreServerAPIClient.send_consumption_information(client, "12345", request)
      assert result == :ok
    end

    test "set_app_account_token" do
      client = create_test_client()

      request = %UpdateAppAccountTokenRequest{
        app_account_token: "7389a31a-fb6d-4569-a2a6-db7d85d84813"
      }

      client =
        expect_http_request(
          client,
          :put,
          "/inApps/v1/transactions/49571273/appAccountToken",
          %{},
          request,
          nil
        )

      result = AppStoreServerAPIClient.set_app_account_token(client, "49571273", request)
      assert result == :ok
    end

    test "get_app_transaction_info" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      # Mock the HTTP request
      Bypass.expect(bypass, "GET", "/inApps/v1/transactions/appTransactions/1234", fn conn ->
        assert {"authorization", "Bearer " <> _token} =
                 List.keyfind(conn.req_headers, "authorization", 0)

        # Return mock response
        response_body =
          File.read!("test/resources/models/appTransactionInfoResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_app_transaction_info(client, "1234")

      assert response.signed_app_transaction_info == "signed_app_transaction_info_value"
    end

    # PNG magic bytes for test data
    @png_magic_bytes <<137, 80, 78, 71, 13, 10, 26, 10>>

    test "upload_image with valid PNG" do
      client = create_test_client()
      # Valid PNG: magic bytes followed by some data
      valid_png = @png_magic_bytes <> <<1, 2, 3>>

      client =
        expect_binary_request(
          client,
          :put,
          "/inApps/v1/messaging/image/a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          valid_png,
          "image/png"
        )

      result =
        AppStoreServerAPIClient.upload_image(
          client,
          "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          valid_png
        )

      assert result == :ok
    end

    test "upload_image rejects invalid PNG" do
      client = create_test_client()
      # Invalid data - not a PNG
      invalid_data = <<1, 2, 3>>

      result =
        AppStoreServerAPIClient.upload_image(
          client,
          "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          invalid_data
        )

      assert result == {:error, :invalid_png}
    end

    test "delete_image" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :delete,
          "/inApps/v1/messaging/image/a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          %{},
          nil,
          nil
        )

      result =
        AppStoreServerAPIClient.delete_image(client, "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890")

      assert result == :ok
    end

    test "get_image_list" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v1/messaging/image/list",
          %{},
          nil,
          "test/resources/models/getImageListResponse.json"
        )

      {:ok, response} = AppStoreServerAPIClient.get_image_list(client)

      assert length(response.image_identifiers) == 1

      assert hd(response.image_identifiers).image_identifier ==
               "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
    end

    test "upload_message" do
      client = create_test_client()

      request = %{
        header: "Header text",
        body: "Body text"
      }

      client =
        expect_http_request(
          client,
          :put,
          "/inApps/v1/messaging/message/a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          %{},
          request,
          nil
        )

      result =
        AppStoreServerAPIClient.upload_message(
          client,
          "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          request
        )

      assert result == :ok
    end

    test "delete_message" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :delete,
          "/inApps/v1/messaging/message/a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890",
          %{},
          nil,
          nil
        )

      result =
        AppStoreServerAPIClient.delete_message(client, "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890")

      assert result == :ok
    end

    test "get_message_list" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :get,
          "/inApps/v1/messaging/message/list",
          %{},
          nil,
          "test/resources/models/getMessageListResponse.json"
        )

      {:ok, response} = AppStoreServerAPIClient.get_message_list(client)

      assert length(response.message_identifiers) == 1

      assert hd(response.message_identifiers).message_identifier ==
               "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
    end

    test "configure_default_message" do
      client = create_test_client()

      request = %DefaultConfigurationRequest{
        message_identifier: "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
      }

      client =
        expect_http_request(
          client,
          :put,
          "/inApps/v1/messaging/default/com.example.product/en-US",
          %{},
          request,
          nil
        )

      result =
        AppStoreServerAPIClient.configure_default_message(
          client,
          "com.example.product",
          "en-US",
          request
        )

      assert result == :ok
    end

    test "delete_default_message" do
      client = create_test_client()

      client =
        expect_http_request(
          client,
          :delete,
          "/inApps/v1/messaging/default/com.example.product/en-US",
          %{},
          nil,
          nil
        )

      result =
        AppStoreServerAPIClient.delete_default_message(client, "com.example.product", "en-US")

      assert result == :ok
    end

    test "api_error_handling" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :post,
          "/inApps/v1/notifications/test",
          %{},
          nil,
          500,
          "apiException.json"
        )

      result = AppStoreServerAPIClient.request_test_notification(client)

      assert {:error,
              %APIException{
                http_status_code: 500,
                raw_api_error: 5_000_000,
                error_message: "An unknown error occurred."
              }} =
               result
    end

    test "api_too_many_requests_error" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :post,
          "/inApps/v1/notifications/test",
          %{},
          nil,
          429,
          "apiTooManyRequestsException.json"
        )

      result = AppStoreServerAPIClient.request_test_notification(client)

      assert {:error,
              %APIException{
                http_status_code: 429,
                raw_api_error: 4_290_000,
                error_message: "Rate limit exceeded."
              }} =
               result
    end

    test "unknown_error_handling" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :post,
          "/inApps/v1/notifications/test",
          %{},
          nil,
          400,
          "apiUnknownError.json"
        )

      result = AppStoreServerAPIClient.request_test_notification(client)

      assert {:error,
              %APIException{
                http_status_code: 400,
                raw_api_error: 9_990_000,
                error_message: "Testing error."
              }} =
               result
    end

    test "xcode_not_supported_error" do
      # Xcode environment should not be allowed for API client
      assert {:error, :xcode_not_supported} =
               AppStoreServerAPIClient.new(
                 signing_key: File.read!("test/resources/certs/testSigningKey.p8"),
                 key_id: "keyId",
                 issuer_id: "issuerId",
                 bundle_id: "com.example",
                 environment: :xcode
               )
    end

    test "invalid_app_account_token_error" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :put,
          "/inApps/v1/transactions/49571273/appAccountToken",
          %{},
          nil,
          400,
          "invalidAppAccountTokenUUIDError.json"
        )

      request = %UpdateAppAccountTokenRequest{
        app_account_token: "invalid-token"
      }

      result = AppStoreServerAPIClient.set_app_account_token(client, "49571273", request)

      assert {:error,
              %APIException{
                http_status_code: 400,
                raw_api_error: 4_000_183,
                error_message:
                  "Invalid request. The app account token field must be a valid UUID."
              }} = result
    end

    test "family_transaction_not_supported_error" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :put,
          "/inApps/v1/transactions/1234/appAccountToken",
          %{},
          nil,
          400,
          "familyTransactionNotSupportedError.json"
        )

      request = %UpdateAppAccountTokenRequest{
        app_account_token: "7389a31a-fb6d-4569-a2a6-db7d85d84813"
      }

      result = AppStoreServerAPIClient.set_app_account_token(client, "1234", request)

      assert {:error,
              %APIException{
                http_status_code: 400,
                raw_api_error: 4_000_185,
                error_message:
                  "Invalid request. Family Sharing transactions aren't supported by this endpoint."
              }} = result
    end

    test "transaction_id_not_original_transaction_id_error" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :put,
          "/inApps/v1/transactions/1234/appAccountToken",
          %{},
          nil,
          400,
          "transactionIdNotOriginalTransactionId.json"
        )

      request = %UpdateAppAccountTokenRequest{
        app_account_token: "7389a31a-fb6d-4569-a2a6-db7d85d84813"
      }

      result = AppStoreServerAPIClient.set_app_account_token(client, "1234", request)

      assert {:error,
              %APIException{
                http_status_code: 400,
                raw_api_error: 4_000_187,
                error_message:
                  "Invalid request. The transaction ID provided is not an original transaction ID."
              }} = result
    end

    test "get_app_transaction_info_invalid_transaction_id" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :get,
          "/inApps/v1/transactions/appTransactions/invalid_id",
          %{},
          nil,
          400,
          "invalidTransactionIdError.json"
        )

      result = AppStoreServerAPIClient.get_app_transaction_info(client, "invalid_id")

      assert {:error,
              %APIException{
                http_status_code: 400,
                raw_api_error: 4_000_006,
                error_message: "Invalid transaction id."
              }} = result
    end

    test "get_app_transaction_info_app_transaction_does_not_exist" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :get,
          "/inApps/v1/transactions/appTransactions/nonexistent_id",
          %{},
          nil,
          404,
          "appTransactionDoesNotExistError.json"
        )

      result = AppStoreServerAPIClient.get_app_transaction_info(client, "nonexistent_id")

      assert {:error,
              %APIException{
                http_status_code: 404,
                raw_api_error: 4_040_019,
                error_message: "No AppTransaction exists for the customer."
              }} = result
    end

    test "get_app_transaction_info_transaction_id_not_found" do
      client = create_test_client()

      client =
        expect_http_request_error(
          client,
          :get,
          "/inApps/v1/transactions/appTransactions/not_found_id",
          %{},
          nil,
          404,
          "transactionIdNotFoundError.json"
        )

      result = AppStoreServerAPIClient.get_app_transaction_info(client, "not_found_id")

      assert {:error,
              %APIException{
                http_status_code: 404,
                raw_api_error: 4_040_010,
                error_message: "Transaction id not found."
              }} = result
    end
  end

  # Helper functions

  defp create_test_client do
    signing_key = File.read!("test/resources/certs/testSigningKey.p8")

    {:ok, client} =
      AppStoreServerAPIClient.new(
        signing_key: signing_key,
        key_id: "keyId",
        issuer_id: "issuerId",
        bundle_id: "com.example",
        environment: :local_testing
      )

    client
  end

  defp create_bypass_client(bypass) do
    %AppStoreServerAPIClient{
      signing_key: File.read!("test/resources/certs/testSigningKey.p8"),
      key_id: "keyId",
      issuer_id: "issuerId",
      bundle_id: "com.example",
      environment: :sandbox,
      base_url: "http://localhost:#{bypass.port}"
    }
  end

  defp expect_http_request(_client, method, path, _expected_params, _expected_body, response_file) do
    bypass = Bypass.open()

    test_client = %AppStoreServerAPIClient{
      signing_key: File.read!("test/resources/certs/testSigningKey.p8"),
      key_id: "keyId",
      issuer_id: "issuerId",
      bundle_id: "com.example",
      environment: :sandbox,
      base_url: "http://localhost:#{bypass.port}"
    }

    response_body = if response_file, do: File.read!(response_file), else: ""

    Bypass.expect(bypass, fn conn ->
      # Verify the request method and path match what we expect
      assert conn.method == String.upcase(Atom.to_string(method))
      assert conn.request_path == path

      assert {"authorization", "Bearer " <> _token} =
               List.keyfind(conn.req_headers, "authorization", 0)

      Plug.Conn.resp(conn, 200, response_body)
    end)

    test_client
  end

  defp expect_binary_request(client, method, path, _expected_binary_data, content_type) do
    bypass = Bypass.open()

    # Create new client with bypass URL
    test_client = %AppStoreServerAPIClient{
      signing_key: client.signing_key,
      key_id: client.key_id,
      issuer_id: client.issuer_id,
      bundle_id: client.bundle_id,
      environment: client.environment,
      base_url: "http://localhost:#{bypass.port}"
    }

    Bypass.expect(bypass, fn conn ->
      # Verify request method and path match what we expect
      assert conn.method == String.upcase(Atom.to_string(method))
      assert conn.request_path == path

      # Verify content type
      assert {"content-type", ^content_type} =
               List.keyfind(conn.req_headers, "content-type", 0)

      Plug.Conn.resp(conn, 200, "")
    end)

    test_client
  end

  defp expect_http_request_error(
         client,
         method,
         path,
         _expected_params,
         _expected_body,
         status_code,
         error_file
       ) do
    bypass = Bypass.open()

    # Create new client with bypass URL
    test_client = %AppStoreServerAPIClient{
      signing_key: client.signing_key,
      key_id: client.key_id,
      issuer_id: client.issuer_id,
      bundle_id: client.bundle_id,
      environment: client.environment,
      base_url: "http://localhost:#{bypass.port}"
    }

    error_body =
      if error_file do
        File.read!("test/resources/models/#{error_file}")
      else
        # Default error response for nil error_file
        "{\"error\": \"Unknown error\"}"
      end

    Bypass.expect(bypass, fn conn ->
      # Verify request method and path match what we expect
      assert conn.method == String.upcase(Atom.to_string(method))
      assert conn.request_path == path

      Plug.Conn.resp(conn, status_code, error_body)
    end)

    test_client
  end
end
