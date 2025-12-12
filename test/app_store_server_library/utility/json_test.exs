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
  end
end
