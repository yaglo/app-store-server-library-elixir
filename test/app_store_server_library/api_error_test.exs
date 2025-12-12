defmodule AppStoreServerLibrary.API.APIErrorTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.API.APIError

  describe "error code accessors" do
    test "returns correct error codes for general errors" do
      assert APIError.general_bad_request() == 4_000_000
      assert APIError.invalid_app_identifier() == 4_000_002
      assert APIError.invalid_transaction_id() == 4_000_006
      assert APIError.invalid_original_transaction_id() == 4_000_008
      assert APIError.invalid_pagination_token() == 4_000_014
      assert APIError.rate_limit_exceeded() == 4_290_000
    end

    test "returns correct error codes for not found errors" do
      assert APIError.account_not_found() == 4_040_001
      assert APIError.account_not_found_retryable() == 4_040_002
      assert APIError.app_not_found() == 4_040_003
      assert APIError.app_not_found_retryable() == 4_040_004
      assert APIError.transaction_id_not_found() == 4_040_010
    end

    test "returns correct error codes for internal errors" do
      assert APIError.general_internal() == 5_000_000
      assert APIError.general_internal_retryable() == 5_000_001
    end

    test "returns correct error codes for retention messaging" do
      assert APIError.invalid_image() == 4_000_161
      assert APIError.header_too_long() == 4_000_162
      assert APIError.body_too_long() == 4_000_163
      assert APIError.image_not_found() == 4_040_014
      assert APIError.message_not_found() == 4_040_015
    end
  end

  describe "to_atom/1" do
    test "converts known error codes to atoms" do
      assert APIError.to_atom(4_000_000) == :general_bad_request
      assert APIError.to_atom(4_000_006) == :invalid_transaction_id
      assert APIError.to_atom(4_040_010) == :transaction_id_not_found
      assert APIError.to_atom(4_290_000) == :rate_limit_exceeded
      assert APIError.to_atom(5_000_001) == :general_internal_retryable
    end

    test "converts retryable error codes to atoms" do
      assert APIError.to_atom(4_040_002) == :account_not_found_retryable
      assert APIError.to_atom(4_040_004) == :app_not_found_retryable
      assert APIError.to_atom(4_040_006) == :original_transaction_id_not_found_retryable
    end

    test "returns :unknown for unknown error codes" do
      assert APIError.to_atom(9_999_999) == :unknown
      assert APIError.to_atom(0) == :unknown
      assert APIError.to_atom(-1) == :unknown
    end

    test "converts all retention messaging errors" do
      assert APIError.to_atom(4_000_161) == :invalid_image
      assert APIError.to_atom(4_000_162) == :header_too_long
      assert APIError.to_atom(4_000_163) == :body_too_long
      assert APIError.to_atom(4_000_164) == :invalid_locale
      assert APIError.to_atom(4_030_014) == :maximum_number_of_images_reached
      assert APIError.to_atom(4_030_016) == :maximum_number_of_messages_reached
    end

    test "converts subscription extension errors" do
      assert APIError.to_atom(4_030_004) == :subscription_extension_ineligible
      assert APIError.to_atom(4_030_005) == :subscription_max_extension
      assert APIError.to_atom(4_030_007) == :family_shared_subscription_extension_ineligible
    end

    test "converts conflict errors" do
      assert APIError.to_atom(4_090_000) == :image_already_exists
      assert APIError.to_atom(4_090_001) == :message_already_exists
    end
  end

  describe "retryable?/1" do
    test "returns true for retryable errors" do
      assert APIError.retryable?(4_040_002) == true
      assert APIError.retryable?(4_040_004) == true
      assert APIError.retryable?(4_040_006) == true
      assert APIError.retryable?(5_000_001) == true
    end

    test "returns false for non-retryable errors" do
      assert APIError.retryable?(4_000_000) == false
      assert APIError.retryable?(4_040_001) == false
      assert APIError.retryable?(4_040_003) == false
      assert APIError.retryable?(4_040_010) == false
      assert APIError.retryable?(4_290_000) == false
      assert APIError.retryable?(5_000_000) == false
    end

    test "returns false for unknown error codes" do
      assert APIError.retryable?(9_999_999) == false
      assert APIError.retryable?(0) == false
    end
  end

  describe "description/1" do
    test "returns description for general errors" do
      assert APIError.description(4_000_000) == "An error that indicates an invalid request."
      assert APIError.description(4_000_006) =~ "invalid transaction identifier"
    end

    test "returns description for not found errors" do
      assert APIError.description(4_040_001) =~ "App Store account wasn't found"
      assert APIError.description(4_040_002) =~ "you can try again"
      assert APIError.description(4_040_010) =~ "transaction identifier wasn't found"
    end

    test "returns description for rate limit error" do
      assert APIError.description(4_290_000) =~ "rate limit"
    end

    test "returns description for internal errors" do
      assert APIError.description(5_000_000) =~ "general internal error"
      assert APIError.description(5_000_001) =~ "you can try again"
    end

    test "returns generic description for unknown errors" do
      assert APIError.description(9_999_999) == "Unknown error code."
    end

    test "returns description for retention messaging errors" do
      assert APIError.description(4_000_161) =~ "image"
      assert APIError.description(4_000_162) =~ "header"
      assert APIError.description(4_000_163) =~ "body"
    end
  end

  describe "doc_url/1" do
    test "returns Apple documentation URL for known errors" do
      assert APIError.doc_url(4_000_000) ==
               "https://developer.apple.com/documentation/appstoreserverapi/generalbadrequesterror"

      assert APIError.doc_url(4_000_006) ==
               "https://developer.apple.com/documentation/appstoreserverapi/invalidtransactioniderror"

      assert APIError.doc_url(4_040_010) ==
               "https://developer.apple.com/documentation/appstoreserverapi/transactionidnotfounderror"

      assert APIError.doc_url(4_290_000) ==
               "https://developer.apple.com/documentation/appstoreserverapi/ratelimitexceedederror"
    end

    test "returns generic error codes URL for unknown errors" do
      assert APIError.doc_url(9_999_999) ==
               "https://developer.apple.com/documentation/appstoreserverapi/error_codes"
    end

    test "returns correct URLs for retryable errors" do
      assert APIError.doc_url(4_040_002) =~ "accountnotfoundretryableerror"
      assert APIError.doc_url(4_040_004) =~ "appnotfoundretryableerror"
      assert APIError.doc_url(5_000_001) =~ "generalinternalretryableerror"
    end
  end
end
