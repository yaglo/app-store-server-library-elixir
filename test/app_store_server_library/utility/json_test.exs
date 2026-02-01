defmodule AppStoreServerLibrary.Utility.JSONTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Utility.JSON

  describe "camel_to_snake/1" do
    test "collapses consecutive uppercase segments" do
      assert JSON.camel_to_snake("notificationUUID") == "notification_uuid"
      assert JSON.camel_to_snake("URLSessionTask") == "url_session_task"
    end

    test "handles deprecated firstSendAttemptResult field" do
      assert JSON.camel_to_snake_atom("firstSendAttemptResult") == :first_send_attempt_result
      assert JSON.camel_to_snake("firstSendAttemptResult") == "first_send_attempt_result"
    end
  end

  describe "keys_to_atoms/1" do
    test "converts notificationUUID to known atom" do
      assert JSON.keys_to_atoms(%{"notificationUUID" => "abc"}) == %{notification_uuid: "abc"}
    end

    test "converts deprecated firstSendAttemptResult to atom" do
      assert JSON.keys_to_atoms(%{"firstSendAttemptResult" => "SUCCESS"}) == %{
               first_send_attempt_result: "SUCCESS"
             }
    end

    test "only converts keys, not values" do
      result = JSON.keys_to_atoms(%{"environment" => "Production", "notificationType" => "TEST"})
      # keys_to_atoms is a pure key converter — values are preserved as-is
      assert result == %{environment: "Production", notification_type: "TEST"}
    end

    test "recursively converts nested maps without touching values" do
      result =
        JSON.keys_to_atoms(%{
          "data" => %{"environment" => "Sandbox", "status" => 1},
          "notificationType" => "SUBSCRIBED"
        })

      assert result.notification_type == "SUBSCRIBED"
      assert result.data.environment == "Sandbox"
      assert result.data.status == 1
    end

    test "converts values in lists without touching non-map elements" do
      result =
        JSON.keys_to_atoms(%{
          "storefrontCountryCodes" => ["USA", "CAN"],
          "items" => [%{"bundleId" => "com.example"}]
        })

      assert result.storefront_country_codes == ["USA", "CAN"]
      assert result.items == [%{bundle_id: "com.example"}]
    end
  end
end
