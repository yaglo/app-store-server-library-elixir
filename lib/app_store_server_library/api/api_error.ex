defmodule AppStoreServerLibrary.API.APIError do
  @moduledoc """
  Error codes returned by the App Store Server API.

  Each error code represents a specific type of error that can occur when making
  API requests to Apple's App Store Server API.

  https://developer.apple.com/documentation/appstoreserverapi/error_codes
  """

  @type t :: integer()

  @base_url "https://developer.apple.com/documentation/appstoreserverapi"

  # All error codes with their metadata
  @errors %{
    # General errors (4000xxx)
    4_000_000 => {:general_bad_request, false, "An error that indicates an invalid request."},
    4_000_002 =>
      {:invalid_app_identifier, false, "An error that indicates an invalid app identifier."},
    4_000_005 =>
      {:invalid_request_revision, false, "An error that indicates an invalid request revision."},
    4_000_006 =>
      {:invalid_transaction_id, false,
       "An error that indicates an invalid transaction identifier."},
    4_000_008 =>
      {:invalid_original_transaction_id, false,
       "An error that indicates an invalid original transaction identifier."},
    4_000_009 =>
      {:invalid_extend_by_days, false, "An error that indicates an invalid extend-by-days value."},
    4_000_010 =>
      {:invalid_extend_reason_code, false, "An error that indicates an invalid reason code."},
    4_000_011 =>
      {:invalid_request_identifier, false,
       "An error that indicates an invalid request identifier."},
    4_000_012 =>
      {:start_date_too_far_in_past, false,
       "An error that indicates that the start date is earlier than the earliest allowed date."},
    4_000_013 =>
      {:start_date_after_end_date, false,
       "An error that indicates that the end date precedes the start date, or the two dates are equal."},
    4_000_014 =>
      {:invalid_pagination_token, false,
       "An error that indicates the pagination token is invalid."},
    4_000_015 =>
      {:invalid_start_date, false, "An error that indicates the start date is invalid."},
    4_000_016 => {:invalid_end_date, false, "An error that indicates the end date is invalid."},
    4_000_017 =>
      {:pagination_token_expired, false, "An error that indicates the pagination token expired."},
    4_000_018 =>
      {:invalid_notification_type, false,
       "An error that indicates the notification type or subtype is invalid."},
    4_000_019 =>
      {:multiple_filters_supplied, false,
       "An error that indicates the request is invalid because it has too many constraints applied."},
    4_000_020 =>
      {:invalid_test_notification_token, false,
       "An error that indicates the test notification token is invalid."},
    4_000_021 => {:invalid_sort, false, "An error that indicates an invalid sort parameter."},
    4_000_022 =>
      {:invalid_product_type, false, "An error that indicates an invalid product type parameter."},
    4_000_023 =>
      {:invalid_product_id, false, "An error that indicates the product ID parameter is invalid."},
    4_000_024 =>
      {:invalid_subscription_group_identifier, false,
       "An error that indicates an invalid subscription group identifier."},
    4_000_026 =>
      {:invalid_in_app_ownership_type, false,
       "An error that indicates an invalid in-app ownership type parameter."},
    4_000_027 =>
      {:invalid_empty_storefront_country_code_list, false,
       "An error that indicates a required storefront country code is empty."},
    4_000_028 =>
      {:invalid_storefront_country_code, false,
       "An error that indicates a storefront code is invalid."},
    4_000_030 =>
      {:invalid_revoked, false,
       "An error that indicates the revoked parameter contains an invalid value."},
    4_000_031 =>
      {:invalid_status, false, "An error that indicates the status parameter is invalid."},
    4_000_032 =>
      {:invalid_account_tenure, false,
       "An error that indicates the value of the account tenure field is invalid."},
    4_000_033 =>
      {:invalid_app_account_token, false,
       "An error that indicates the value of the app account token field is invalid."},
    4_000_034 =>
      {:invalid_consumption_status, false,
       "An error that indicates the value of the consumption status field is invalid."},
    4_000_035 =>
      {:invalid_customer_consented, false,
       "An error that indicates the customer consented field is invalid or doesn't indicate that the customer consented."},
    4_000_036 =>
      {:invalid_delivery_status, false,
       "An error that indicates the value in the delivery status field is invalid."},
    4_000_037 =>
      {:invalid_lifetime_dollars_purchased, false,
       "An error that indicates the value in the lifetime dollars purchased field is invalid."},
    4_000_038 =>
      {:invalid_lifetime_dollars_refunded, false,
       "An error that indicates the value in the lifetime dollars refunded field is invalid."},
    4_000_039 =>
      {:invalid_platform, false,
       "An error that indicates the value in the platform field is invalid."},
    4_000_040 =>
      {:invalid_play_time, false,
       "An error that indicates the value in the playtime field is invalid."},
    4_000_041 =>
      {:invalid_sample_content_provided, false,
       "An error that indicates the value in the sample content provided field is invalid."},
    4_000_042 =>
      {:invalid_user_status, false,
       "An error that indicates the value in the user status field is invalid."},
    4_000_047 =>
      {:invalid_transaction_type_not_supported, false,
       "An error that indicates the transaction identifier represents an unsupported in-app purchase type."},
    4_000_048 =>
      {:app_transaction_id_not_supported_error, false,
       "An error that indicates the endpoint doesn't support an app transaction ID."},

    # Retention messaging errors
    4_000_161 =>
      {:invalid_image, false, "An error that indicates the image that's uploading is invalid."},
    4_000_162 =>
      {:header_too_long, false, "An error that indicates the header text is too long."},
    4_000_163 => {:body_too_long, false, "An error that indicates the body text is too long."},
    4_000_164 => {:invalid_locale, false, "An error that indicates the locale is invalid."},
    4_000_175 =>
      {:alt_text_too_long, false,
       "An error that indicates the alternative text for an image is too long."},

    # App account token errors
    4_000_183 =>
      {:invalid_app_account_token_uuid_error, false,
       "An error that indicates the app account token value is not a valid UUID."},
    4_000_185 =>
      {:family_transaction_not_supported_error, false,
       "An error that indicates the transaction is for a product the customer obtains through Family Sharing, which the endpoint doesn't support."},
    4_000_187 =>
      {:transaction_id_is_not_original_transaction_id_error, false,
       "An error that indicates the endpoint expects an original transaction identifier."},

    # Subscription extension errors (403xxxx)
    4_030_004 =>
      {:subscription_extension_ineligible, false,
       "An error that indicates the subscription doesn't qualify for a renewal-date extension due to its subscription state."},
    4_030_005 =>
      {:subscription_max_extension, false,
       "An error that indicates the subscription doesn't qualify for a renewal-date extension because it has already received the maximum extensions."},
    4_030_007 =>
      {:family_shared_subscription_extension_ineligible, false,
       "An error that indicates a subscription isn't directly eligible for a renewal date extension because the user obtained it through Family Sharing."},

    # Retention messaging limits
    4_030_014 =>
      {:maximum_number_of_images_reached, false,
       "An error that indicates when you reach the maximum number of uploaded images."},
    4_030_016 =>
      {:maximum_number_of_messages_reached, false,
       "An error that indicates when you reach the maximum number of uploaded messages."},
    4_030_017 =>
      {:message_not_approved, false,
       "An error that indicates the message isn't in the approved state, so you can't configure it as a default message."},
    4_030_018 =>
      {:image_not_approved, false,
       "An error that indicates the image isn't in the approved state, so you can't configure it as part of a default message."},
    4_030_019 =>
      {:image_in_use, false,
       "An error that indicates the image is currently in use as part of a message, so you can't delete it."},

    # Not found errors (404xxxx)
    4_040_001 =>
      {:account_not_found, false, "An error that indicates the App Store account wasn't found."},
    4_040_002 =>
      {:account_not_found_retryable, true,
       "An error response that indicates the App Store account wasn't found, but you can try again."},
    4_040_003 => {:app_not_found, false, "An error that indicates the app wasn't found."},
    4_040_004 =>
      {:app_not_found_retryable, true,
       "An error response that indicates the app wasn't found, but you can try again."},
    4_040_005 =>
      {:original_transaction_id_not_found, false,
       "An error that indicates an original transaction identifier wasn't found."},
    4_040_006 =>
      {:original_transaction_id_not_found_retryable, true,
       "An error response that indicates the original transaction identifier wasn't found, but you can try again."},
    4_040_007 =>
      {:server_notification_url_not_found, false,
       "An error that indicates that the App Store server couldn't find a notifications URL for your app in this environment."},
    4_040_008 =>
      {:test_notification_not_found, false,
       "An error that indicates that the test notification token is expired or the test notification status isn't available."},
    4_040_009 =>
      {:status_request_not_found, false,
       "An error that indicates the server didn't find a subscription-renewal-date extension request for the request identifier and product identifier you provided."},
    4_040_010 =>
      {:transaction_id_not_found, false,
       "An error that indicates a transaction identifier wasn't found."},
    4_040_014 =>
      {:image_not_found, false,
       "An error that indicates the system can't find the image identifier."},
    4_040_015 =>
      {:message_not_found, false,
       "An error that indicates the system can't find the message identifier."},
    4_040_019 =>
      {:app_transaction_does_not_exist_error, false,
       "An error response that indicates an app transaction doesn't exist for the specified customer."},

    # Conflict errors (409xxxx)
    4_090_000 =>
      {:image_already_exists, false,
       "An error that indicates the image identifier already exists."},
    4_090_001 =>
      {:message_already_exists, false,
       "An error that indicates the message identifier already exists."},

    # Rate limit errors (429xxxx)
    4_290_000 =>
      {:rate_limit_exceeded, false,
       "An error that indicates that the request exceeded the rate limit."},

    # Internal errors (500xxxx)
    5_000_000 => {:general_internal, false, "An error that indicates a general internal error."},
    5_000_001 =>
      {:general_internal_retryable, true,
       "An error response that indicates an unknown error occurred, but you can try again."}
  }

  # Generate accessor functions at compile time
  for {code, {name, _retryable, _desc}} <- @errors do
    def unquote(name)(), do: unquote(code)
  end

  @doc """
  Converts an error code to its name as an atom.
  """
  @spec to_atom(t()) :: atom()
  def to_atom(code) do
    case Map.get(@errors, code) do
      {name, _, _} -> name
      nil -> :unknown
    end
  end

  @doc """
  Checks if the error is retryable.
  """
  @spec retryable?(t()) :: boolean()
  def retryable?(code) do
    case Map.get(@errors, code) do
      {_, retryable, _} -> retryable
      nil -> false
    end
  end

  @doc """
  Returns a description of the error code.
  """
  @spec description(t()) :: String.t()
  def description(code) do
    case Map.get(@errors, code) do
      {_, _, desc} -> desc
      nil -> "Unknown error code."
    end
  end

  @doc """
  Returns the Apple documentation URL for the error code.
  """
  @spec doc_url(t()) :: String.t()
  def doc_url(code) do
    case Map.get(@errors, code) do
      {name, _, _} ->
        error_name = name |> Atom.to_string() |> String.replace("_", "") |> Kernel.<>("error")
        "#{@base_url}/#{error_name}"

      nil ->
        "#{@base_url}/error_codes"
    end
  end
end
