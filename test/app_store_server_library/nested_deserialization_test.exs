defmodule AppStoreServerLibrary.NestedDeserializationTest do
  @moduledoc """
  Tests for nested struct deserialization with automatic camelCase to snake_case conversion.

  These tests verify that nested objects in API responses are properly converted from
  camelCase JSON keys to snake_case Elixir struct fields at all nesting levels.
  """
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.API.AppStoreServerAPIClient

  alias AppStoreServerLibrary.Models.{
    CheckTestNotificationResponse,
    GetImageListResponse,
    GetImageListResponseItem,
    GetMessageListResponse,
    GetMessageListResponseItem,
    LastTransactionsItem,
    NotificationHistoryResponse,
    NotificationHistoryResponseItem,
    SendAttemptItem,
    StatusResponse,
    SubscriptionGroupIdentifierItem
  }

  describe "StatusResponse nested deserialization" do
    test "deserializes nested SubscriptionGroupIdentifierItem structs with snake_case keys" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/4321", fn conn ->
        response_body =
          File.read!("test/resources/models/getAllSubscriptionStatusesResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_all_subscription_statuses(client, "4321")

      # Verify top-level fields
      assert %StatusResponse{} = response
      assert response.environment == :local_testing
      assert response.bundle_id == "com.example"
      assert response.app_apple_id == 5_454_545

      # Verify nested data is properly deserialized as structs with snake_case keys
      assert is_list(response.data)
      assert length(response.data) == 2

      # First subscription group
      [first_group, second_group] = response.data

      assert %SubscriptionGroupIdentifierItem{} = first_group
      assert first_group.subscription_group_identifier == "sub_group_one"
      assert is_list(first_group.last_transactions)
      assert length(first_group.last_transactions) == 2

      # Verify LastTransactionsItem structs (third level of nesting)
      [first_tx, second_tx] = first_group.last_transactions

      assert %LastTransactionsItem{} = first_tx
      assert first_tx.original_transaction_id == "3749183"
      assert first_tx.signed_transaction_info == "signed_transaction_one"
      assert first_tx.signed_renewal_info == "signed_renewal_one"
      # Verify enum conversion for status
      assert first_tx.status == :active
      assert first_tx.raw_status == 1

      assert %LastTransactionsItem{} = second_tx
      assert second_tx.original_transaction_id == "5314314134"
      assert second_tx.signed_transaction_info == "signed_transaction_two"
      assert second_tx.signed_renewal_info == "signed_renewal_two"
      # Status 5 is :revoked
      assert second_tx.status == :revoked
      assert second_tx.raw_status == 5

      # Second subscription group
      assert %SubscriptionGroupIdentifierItem{} = second_group
      assert second_group.subscription_group_identifier == "sub_group_two"
      assert length(second_group.last_transactions) == 1

      [third_tx] = second_group.last_transactions
      assert %LastTransactionsItem{} = third_tx
      assert third_tx.original_transaction_id == "3413453"
      # Status 2 is :expired
      assert third_tx.status == :expired
      assert third_tx.raw_status == 2
    end

    test "handles empty data array" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/empty", fn conn ->
        response_body = ~s({
          "environment": "Sandbox",
          "bundleId": "com.example",
          "appAppleId": 12345,
          "data": []
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_all_subscription_statuses(client, "empty")

      assert %StatusResponse{} = response
      assert response.data == []
    end

    test "handles subscription group with empty last_transactions" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/empty_tx", fn conn ->
        response_body = ~s({
          "environment": "Sandbox",
          "bundleId": "com.example",
          "appAppleId": 12345,
          "data": [
            {
              "subscriptionGroupIdentifier": "group_1",
              "lastTransactions": []
            }
          ]
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.get_all_subscription_statuses(client, "empty_tx")

      assert %StatusResponse{} = response
      assert length(response.data) == 1
      [group] = response.data
      assert %SubscriptionGroupIdentifierItem{} = group
      assert group.last_transactions == []
    end
  end

  describe "NotificationHistoryResponse nested deserialization" do
    test "deserializes nested NotificationHistoryResponseItem and SendAttemptItem structs" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "POST", "/inApps/v1/notifications/history", fn conn ->
        response_body =
          File.read!("test/resources/models/getNotificationHistoryResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      request = %{start_date: 1_698_148_900_000, end_date: 1_698_148_950_000}
      {:ok, response} = AppStoreServerAPIClient.get_notification_history(client, nil, request)

      # Verify top-level fields
      assert %NotificationHistoryResponse{} = response
      assert response.pagination_token == "57715481-805a-4283-8499-1c19b5d6b20a"
      assert response.has_more == true

      # Verify nested notification_history items
      assert is_list(response.notification_history)
      assert length(response.notification_history) == 2

      [first_item, second_item] = response.notification_history

      # First notification history item
      assert %NotificationHistoryResponseItem{} = first_item
      assert first_item.signed_payload == "signed_payload_one"
      assert is_list(first_item.send_attempts)
      assert length(first_item.send_attempts) == 2

      # Verify SendAttemptItem structs (third level of nesting)
      [first_attempt, second_attempt] = first_item.send_attempts

      assert %SendAttemptItem{} = first_attempt
      assert first_attempt.attempt_date == 1_698_148_900_000
      assert first_attempt.send_attempt_result == :no_response
      assert first_attempt.raw_send_attempt_result == "NO_RESPONSE"

      assert %SendAttemptItem{} = second_attempt
      assert second_attempt.attempt_date == 1_698_148_950_000
      assert second_attempt.send_attempt_result == :success
      assert second_attempt.raw_send_attempt_result == "SUCCESS"

      # Second notification history item
      assert %NotificationHistoryResponseItem{} = second_item
      assert second_item.signed_payload == "signed_payload_two"
      assert length(second_item.send_attempts) == 1

      [third_attempt] = second_item.send_attempts
      assert %SendAttemptItem{} = third_attempt
      assert third_attempt.send_attempt_result == :circular_redirect
    end
  end

  describe "CheckTestNotificationResponse nested deserialization" do
    test "deserializes nested SendAttemptItem structs" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(
        bypass,
        "GET",
        "/inApps/v1/notifications/test/8cd2974c-f905-492a-bf9a-b2f47c791d19",
        fn conn ->
          response_body =
            File.read!("test/resources/models/getTestNotificationStatusResponse.json")

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, response_body)
        end
      )

      {:ok, response} =
        AppStoreServerAPIClient.get_test_notification_status(
          client,
          "8cd2974c-f905-492a-bf9a-b2f47c791d19"
        )

      assert %CheckTestNotificationResponse{} = response
      assert response.signed_payload == "signed_payload"
      assert is_list(response.send_attempts)
      assert length(response.send_attempts) == 2

      [first_attempt, second_attempt] = response.send_attempts

      assert %SendAttemptItem{} = first_attempt
      assert first_attempt.attempt_date == 1_698_148_900_000
      assert first_attempt.send_attempt_result == :no_response
      assert first_attempt.raw_send_attempt_result == "NO_RESPONSE"

      assert %SendAttemptItem{} = second_attempt
      assert second_attempt.attempt_date == 1_698_148_950_000
      assert second_attempt.send_attempt_result == :success
      assert second_attempt.raw_send_attempt_result == "SUCCESS"
    end
  end

  describe "GetImageListResponse nested deserialization" do
    test "deserializes nested GetImageListResponseItem structs with enum conversion" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/messaging/image/list", fn conn ->
        response_body = File.read!("test/resources/models/getImageListResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_image_list(client)

      assert %GetImageListResponse{} = response
      assert is_list(response.image_identifiers)
      assert length(response.image_identifiers) == 1

      [item] = response.image_identifiers
      assert %GetImageListResponseItem{} = item
      assert item.image_identifier == "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
      # Verify enum was converted
      assert item.image_state == :approved
    end

    test "handles multiple image items" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/messaging/image/list", fn conn ->
        response_body = ~s({
          "imageIdentifiers": [
            {"imageIdentifier": "id-1", "imageState": "APPROVED"},
            {"imageIdentifier": "id-2", "imageState": "REJECTED"},
            {"imageIdentifier": "id-3", "imageState": "PENDING"}
          ]
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_image_list(client)

      assert length(response.image_identifiers) == 3

      [first, second, third] = response.image_identifiers

      assert %GetImageListResponseItem{} = first
      assert first.image_identifier == "id-1"
      assert first.image_state == :approved

      assert %GetImageListResponseItem{} = second
      assert second.image_identifier == "id-2"
      assert second.image_state == :rejected

      assert %GetImageListResponseItem{} = third
      assert third.image_identifier == "id-3"
      assert third.image_state == :pending
    end
  end

  describe "GetMessageListResponse nested deserialization" do
    test "deserializes nested GetMessageListResponseItem structs with enum conversion" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/messaging/message/list", fn conn ->
        response_body = File.read!("test/resources/models/getMessageListResponse.json")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_message_list(client)

      assert %GetMessageListResponse{} = response
      assert is_list(response.message_identifiers)
      assert length(response.message_identifiers) == 1

      [item] = response.message_identifiers
      assert %GetMessageListResponseItem{} = item
      assert item.message_identifier == "a1b2c3d4-e5f6-7890-a1b2-c3d4e5f67890"
      # Verify enum was converted
      assert item.message_state == :approved
    end

    test "handles multiple message items" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/messaging/message/list", fn conn ->
        response_body = ~s({
          "messageIdentifiers": [
            {"messageIdentifier": "msg-1", "messageState": "APPROVED"},
            {"messageIdentifier": "msg-2", "messageState": "REJECTED"}
          ]
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} = AppStoreServerAPIClient.get_message_list(client)

      assert length(response.message_identifiers) == 2

      [first, second] = response.message_identifiers

      assert %GetMessageListResponseItem{} = first
      assert first.message_identifier == "msg-1"
      assert first.message_state == :approved

      assert %GetMessageListResponseItem{} = second
      assert second.message_identifier == "msg-2"
      assert second.message_state == :rejected
    end
  end

  describe "__nested_fields__/0 function" do
    test "StatusResponse declares nested fields" do
      assert function_exported?(StatusResponse, :__nested_fields__, 0)
      fields = StatusResponse.__nested_fields__()
      assert fields == %{data: {:list, SubscriptionGroupIdentifierItem}}
    end

    test "SubscriptionGroupIdentifierItem declares nested fields" do
      assert function_exported?(SubscriptionGroupIdentifierItem, :__nested_fields__, 0)
      fields = SubscriptionGroupIdentifierItem.__nested_fields__()
      assert fields == %{last_transactions: {:list, LastTransactionsItem}}
    end

    test "NotificationHistoryResponse declares nested fields" do
      assert function_exported?(NotificationHistoryResponse, :__nested_fields__, 0)
      fields = NotificationHistoryResponse.__nested_fields__()
      assert fields == %{notification_history: {:list, NotificationHistoryResponseItem}}
    end

    test "NotificationHistoryResponseItem declares nested fields" do
      assert function_exported?(NotificationHistoryResponseItem, :__nested_fields__, 0)
      fields = NotificationHistoryResponseItem.__nested_fields__()
      assert fields == %{send_attempts: {:list, SendAttemptItem}}
    end

    test "CheckTestNotificationResponse declares nested fields" do
      assert function_exported?(CheckTestNotificationResponse, :__nested_fields__, 0)
      fields = CheckTestNotificationResponse.__nested_fields__()
      assert fields == %{send_attempts: {:list, SendAttemptItem}}
    end

    test "GetImageListResponse declares nested fields" do
      assert function_exported?(GetImageListResponse, :__nested_fields__, 0)
      fields = GetImageListResponse.__nested_fields__()
      assert fields == %{image_identifiers: {:list, GetImageListResponseItem}}
    end

    test "GetMessageListResponse declares nested fields" do
      assert function_exported?(GetMessageListResponse, :__nested_fields__, 0)
      fields = GetMessageListResponse.__nested_fields__()
      assert fields == %{message_identifiers: {:list, GetMessageListResponseItem}}
    end

    test "structs without nested fields don't export __nested_fields__/0" do
      # LastTransactionsItem has no nested struct fields (status is an enum, not a struct)
      refute function_exported?(LastTransactionsItem, :__nested_fields__, 0)

      # SendAttemptItem has no nested struct fields
      refute function_exported?(SendAttemptItem, :__nested_fields__, 0)
    end
  end

  describe "enum conversion in nested structs" do
    test "LastTransactionsItem.status is converted from integer to atom" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/test_enum", fn conn ->
        # Test all status values
        response_body = ~s({
          "environment": "Sandbox",
          "bundleId": "com.example",
          "appAppleId": 12345,
          "data": [
            {
              "subscriptionGroupIdentifier": "group_1",
              "lastTransactions": [
                {"status": 1, "originalTransactionId": "tx1"},
                {"status": 2, "originalTransactionId": "tx2"},
                {"status": 3, "originalTransactionId": "tx3"},
                {"status": 4, "originalTransactionId": "tx4"},
                {"status": 5, "originalTransactionId": "tx5"}
              ]
            }
          ]
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.get_all_subscription_statuses(client, "test_enum")

      [group] = response.data
      transactions = group.last_transactions

      assert Enum.at(transactions, 0).status == :active
      assert Enum.at(transactions, 0).raw_status == 1

      assert Enum.at(transactions, 1).status == :expired
      assert Enum.at(transactions, 1).raw_status == 2

      assert Enum.at(transactions, 2).status == :billing_retry
      assert Enum.at(transactions, 2).raw_status == 3

      assert Enum.at(transactions, 3).status == :billing_grace_period
      assert Enum.at(transactions, 3).raw_status == 4

      assert Enum.at(transactions, 4).status == :revoked
      assert Enum.at(transactions, 4).raw_status == 5
    end

    test "unknown status values are passed through" do
      bypass = Bypass.open()
      client = create_bypass_client(bypass)

      Bypass.expect(bypass, "GET", "/inApps/v1/subscriptions/unknown_status", fn conn ->
        response_body = ~s({
          "environment": "Sandbox",
          "bundleId": "com.example",
          "appAppleId": 12345,
          "data": [
            {
              "subscriptionGroupIdentifier": "group_1",
              "lastTransactions": [
                {"status": 999, "originalTransactionId": "tx1"}
              ]
            }
          ]
        })

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, response_body)
      end)

      {:ok, response} =
        AppStoreServerAPIClient.get_all_subscription_statuses(client, "unknown_status")

      [group] = response.data
      [tx] = group.last_transactions

      # Unknown status should be passed through as integer
      assert tx.status == 999
      assert tx.raw_status == 999
    end
  end

  # Helper functions

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
end
