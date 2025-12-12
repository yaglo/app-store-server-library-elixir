defmodule AppStoreServerLibrary.API.APIExceptionTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.API.APIException

  describe "new/3" do
    test "creates exception with all fields" do
      exception = APIException.new(400, 4_000_006, "Invalid transaction")

      assert exception.http_status_code == 400
      assert exception.raw_api_error == 4_000_006
      assert exception.api_error == :invalid_transaction_id
      assert exception.error_message == "Invalid transaction"
    end

    test "creates exception with only status code" do
      exception = APIException.new(500)

      assert exception.http_status_code == 500
      assert exception.raw_api_error == nil
      assert exception.api_error == nil
      assert exception.error_message == nil
    end

    test "creates exception with status and error code" do
      exception = APIException.new(404, 4_040_010)

      assert exception.http_status_code == 404
      assert exception.raw_api_error == 4_040_010
      assert exception.api_error == :transaction_id_not_found
      assert exception.error_message == nil
    end

    test "sets api_error to nil for unknown error codes" do
      exception = APIException.new(400, 9_999_999, "Unknown error")

      assert exception.http_status_code == 400
      assert exception.raw_api_error == 9_999_999
      assert exception.api_error == nil
      assert exception.error_message == "Unknown error"
    end
  end

  describe "message/1" do
    test "formats message with all fields" do
      exception = APIException.new(400, 4_000_006, "Invalid transaction identifier")
      message = APIException.message(exception)

      assert message =~ "HTTP 400"
      assert message =~ "invalid_transaction_id"
      assert message =~ "Invalid transaction identifier"
    end

    test "formats message with only status code" do
      exception = APIException.new(500)
      message = APIException.message(exception)

      assert message == "App Store Server API error (HTTP 500)"
    end

    test "formats message with error but no message" do
      exception = APIException.new(404, 4_040_010)
      message = APIException.message(exception)

      assert message =~ "HTTP 404"
      assert message =~ "transaction_id_not_found"
    end

    test "formats message with message but no error" do
      exception = %APIException{
        http_status_code: 500,
        api_error: nil,
        raw_api_error: nil,
        error_message: "Internal server error"
      }

      message = APIException.message(exception)

      assert message =~ "HTTP 500"
      assert message =~ "Internal server error"
    end
  end

  describe "retryable?/1" do
    test "returns true for retryable errors" do
      assert APIException.retryable?(APIException.new(404, 4_040_002)) == true
      assert APIException.retryable?(APIException.new(404, 4_040_004)) == true
      assert APIException.retryable?(APIException.new(404, 4_040_006)) == true
      assert APIException.retryable?(APIException.new(500, 5_000_001)) == true
    end

    test "returns false for non-retryable errors" do
      assert APIException.retryable?(APIException.new(400, 4_000_000)) == false
      assert APIException.retryable?(APIException.new(404, 4_040_001)) == false
      assert APIException.retryable?(APIException.new(429, 4_290_000)) == false
      assert APIException.retryable?(APIException.new(500, 5_000_000)) == false
    end

    test "returns false when no error code" do
      assert APIException.retryable?(APIException.new(500)) == false
    end
  end

  describe "error_description/1" do
    test "returns description when error code present" do
      exception = APIException.new(400, 4_000_006)
      description = APIException.error_description(exception)

      assert description =~ "invalid transaction identifier"
    end

    test "returns nil when no error code" do
      exception = APIException.new(500)
      assert APIException.error_description(exception) == nil
    end

    test "returns generic description for unknown error code" do
      exception = APIException.new(400, 9_999_999)
      assert APIException.error_description(exception) == "Unknown error code."
    end
  end

  describe "doc_url/1" do
    test "returns Apple documentation URL when error code present" do
      exception = APIException.new(400, 4_000_006)
      url = APIException.doc_url(exception)

      assert url ==
               "https://developer.apple.com/documentation/appstoreserverapi/invalidtransactioniderror"
    end

    test "returns nil when no error code" do
      exception = APIException.new(500)
      assert APIException.doc_url(exception) == nil
    end

    test "returns generic URL for unknown error code" do
      exception = APIException.new(400, 9_999_999)

      assert APIException.doc_url(exception) ==
               "https://developer.apple.com/documentation/appstoreserverapi/error_codes"
    end
  end

  describe "from_error_map/1" do
    test "creates exception from full error map" do
      exception =
        APIException.from_error_map(%{
          status_code: 400,
          error_code: 4_000_006,
          error_message: "Invalid transaction"
        })

      assert exception.http_status_code == 400
      assert exception.raw_api_error == 4_000_006
      assert exception.api_error == :invalid_transaction_id
      assert exception.error_message == "Invalid transaction"
    end

    test "creates exception from map without error code" do
      exception =
        APIException.from_error_map(%{
          status_code: 500,
          error_message: "Internal error"
        })

      assert exception.http_status_code == 500
      assert exception.raw_api_error == nil
      assert exception.error_message == "Internal error"
    end

    test "creates exception from map with only status code" do
      exception = APIException.from_error_map(%{status_code: 500})

      assert exception.http_status_code == 500
      assert exception.raw_api_error == nil
      assert exception.error_message == nil
    end
  end

  describe "exception behavior" do
    test "can be raised" do
      exception = APIException.new(400, 4_000_006, "Invalid transaction")

      assert_raise APIException, fn ->
        raise exception
      end
    end

    test "raised exception has correct message" do
      exception = APIException.new(400, 4_000_006, "Invalid transaction")

      error =
        assert_raise APIException, fn ->
          raise exception
        end

      assert error.http_status_code == 400
      assert Exception.message(error) =~ "invalid_transaction_id"
    end
  end
end
