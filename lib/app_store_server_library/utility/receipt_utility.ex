defmodule AppStoreServerLibrary.Utility.ReceiptUtility do
  @moduledoc """
  Utility functions for extracting transaction IDs from App Store receipts.

  This module provides functions to extract transaction IDs from:
  - App receipts (PKCS#7 format)
  - Transaction receipts

  **Note**: NO validation is performed on the receipt, and any data returned
  should only be used to call the App Store Server API.
  """

  @doc """
  Extracts a transaction ID from an encoded App receipt.

  ## Parameters
  - app_receipt: The unmodified app receipt (base64 encoded)

  ## Returns
    * `{:ok, transaction_id}` if found
    * `{:ok, nil}` if receipt contains no in-app purchases
    * `{:error, reason}` if receipt format is invalid

  ## Examples
      iex> ReceiptUtility.extract_transaction_id_from_app_receipt(base64_receipt)
  """
  @spec extract_transaction_id_from_app_receipt(String.t()) ::
          {:ok, String.t() | nil} | {:error, term()}
  def extract_transaction_id_from_app_receipt(app_receipt) do
    # Decode base64 receipt
    decoded_receipt = Base.decode64!(app_receipt)

    # Parse ASN.1 structure to extract transaction ID
    case parse_asn1_receipt(decoded_receipt) do
      {:ok, transaction_id} -> {:ok, transaction_id}
      {:not_found} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :invalid_receipt_format}
  end

  @doc """
  Extracts a transaction ID from an encoded transaction receipt.

  ## Parameters
  - transaction_receipt: The unmodified transaction receipt (base64 encoded)

  ## Returns

    * `{:ok, transaction_id}` if found
    * `{:ok, nil}` if no transaction ID is found
    * `{:error, reason}` if receipt format is invalid
  """
  @spec extract_transaction_id_from_transaction_receipt(String.t()) ::
          {:ok, String.t() | nil} | {:error, term()}
  def extract_transaction_id_from_transaction_receipt(transaction_receipt) do
    # Decode base64 and parse as UTF-8
    decoded_top_level = Base.decode64!(transaction_receipt) |> to_string()

    # Use regex to find purchase-info and transaction-id
    case Regex.run(~r/"purchase-info"\s*=\s*"([a-zA-Z0-9+\/=]+)"/, decoded_top_level) do
      [_, purchase_info_b64] ->
        decoded_inner_level = Base.decode64!(purchase_info_b64) |> to_string()

        case Regex.run(~r/"transaction-id"\s*=\s*"([a-zA-Z0-9+\/=]+)"/, decoded_inner_level) do
          [_, transaction_id] -> {:ok, transaction_id}
          nil -> {:ok, nil}
        end

      nil ->
        {:ok, nil}
    end
  rescue
    _ -> {:error, :invalid_receipt_format}
  end

  # Private helper functions

  defp parse_asn1_receipt(decoded_receipt) do
    with {:ok, receipt_data} <- extract_receipt_data(decoded_receipt),
         {:ok, in_app_purchases} <- parse_receipt_attributes(receipt_data) do
      case find_first_transaction_id(in_app_purchases) do
        nil -> {:not_found}
        transaction_id -> {:ok, transaction_id}
      end
    end
  rescue
    _ -> {:error, :asn1_parse_error}
  end

  defp extract_receipt_data(decoded_receipt) do
    # Use OTP's BER decoder for PKCS#7 containers
    case :asn1rt_nif.decode_ber_tlv(decoded_receipt) do
      {parsed_data, ""} ->
        # Navigate through PKCS#7 structure to find receipt data
        case extract_content_from_pkcs7(parsed_data) do
          {:ok, receipt_data} -> {:ok, receipt_data}
          {:error, reason} -> {:error, reason}
        end

      _ ->
        {:error, :invalid_pkcs7_format}
    end
  rescue
    _ -> {:error, :pkcs7_parse_error}
  end

  # PKCS#7 navigation helpers

  defp extract_content_from_pkcs7({16, content_list}) when is_list(content_list) do
    # Navigate through PKCS#7 ContentInfo structure to find receipt data
    # The structure is: ContentInfo → signedData → contentInfo → content (nested OCTET STRINGs)
    case find_receipt_data_in_content_info(content_list) do
      {:ok, receipt_data} -> {:ok, receipt_data}
      {:error, reason} -> {:error, reason}
    end
  end

  defp extract_content_from_pkcs7({tag, _content}) do
    {:error, {:unexpected_tag, tag}}
  end

  defp find_receipt_data_in_content_info(content_list) do
    # Navigate through PKCS#7 structure following Python implementation path:
    # ContentInfo → signedData → contentInfo → content (nested OCTET STRINGs)
    case content_list do
      [{6, _content_type}, {131_072, signed_data_content}] ->
        # Found signedData, navigate through the structure to find receipt data
        # The receipt data is in the nested OCTET STRING structure
        extract_receipt_data_from_signed_data(signed_data_content)

      _ ->
        {:error, :signed_data_not_found}
    end
  end

  defp extract_receipt_data_from_signed_data(signed_data_content) do
    # Navigate through signedData following Python implementation path exactly:
    # decoder.enter() -> decoder.enter() -> decoder.read() -> decoder.read() -> decoder.enter() -> decoder.read() -> decoder.enter()
    # This corresponds to: signedData -> encapContentInfo -> eContent -> OCTET STRING -> OCTET STRING

    # Based on the structure we saw, the receipt data is in a specific nested pattern
    # Let's navigate to the exact location: element 1 -> element 1 -> element 1 -> element 0 -> element 1 -> element 0
    case navigate_to_receipt_data(signed_data_content) do
      {:ok, receipt_data} -> {:ok, receipt_data}
      _ -> {:error, :receipt_data_not_found}
    end
  end

  defp navigate_to_receipt_data(signed_data_content) do
    # Navigate the complex nested structure to find receipt data
    case safe_at(signed_data_content, 0) do
      {:ok, level0} ->
        # Try to find receipt data in the single element
        find_receipt_in_element(level0)

      {:error, _reason} ->
        {:error, :navigation_failed}
    end
  end

  defp find_receipt_in_element({4, content}) when is_binary(content), do: {:ok, content}

  defp find_receipt_in_element({16, content}) when is_list(content) do
    with {:ok, {16, signed_data_content}} <- safe_at(content, 2),
         {:ok, {131_072, nested_content}} <- safe_at(signed_data_content, 1),
         {:ok, octet_string} <- safe_at(nested_content, 0) do
      extract_receipt_from_octet_string(octet_string)
    else
      _ -> find_nested_octet_string(content)
    end
  end

  defp find_receipt_in_element({_tag, _content}), do: {:error, :unexpected_element_structure}

  defp extract_receipt_from_octet_string({4, [{4, receipt_data}]}), do: {:ok, receipt_data}

  defp extract_receipt_from_octet_string({4, receipt_data}) when is_binary(receipt_data),
    do: {:ok, receipt_data}

  defp extract_receipt_from_octet_string(_), do: {:error, :unexpected_nested_structure}

  defp safe_at(list, index) do
    if index < length(list) do
      {:ok, Enum.at(list, index)}
    else
      {:error, :index_out_of_bounds}
    end
  end

  defp find_nested_octet_string(elements) when is_list(elements) do
    Enum.find_value(elements, &search_octet_string_element/1) || {:error, :receipt_data_not_found}
  end

  defp find_nested_octet_string(_), do: {:error, :receipt_data_not_found}

  defp search_octet_string_element({4, [{4, receipt_data}]}), do: {:ok, receipt_data}
  defp search_octet_string_element({4, receipt_data}), do: {:ok, receipt_data}

  defp search_octet_string_element({_tag, content}) when is_list(content),
    do: find_nested_octet_string(content)

  defp search_octet_string_element({_tag, content}) when is_binary(content),
    do: try_parse_binary_content(content)

  defp search_octet_string_element(_), do: nil

  defp try_parse_binary_content(content) do
    cond do
      starts_with_asn1_sequence?(content) ->
        {:ok, content}

      should_attempt_asn1_parse?(content) ->
        try_decode_asn1(content)

      true ->
        nil
    end
  end

  defp should_attempt_asn1_parse?(content) do
    byte_size(content) > 10 and not looks_like_random_binary?(content)
  end

  defp try_decode_asn1(content) do
    case :asn1rt_nif.decode_ber_tlv(content) do
      {parsed_data, ""} -> find_nested_octet_string([parsed_data])
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp parse_receipt_attributes(receipt_data) do
    # Parse the receipt data as ASN.1 to extract receipt attributes
    case :asn1rt_nif.decode_ber_tlv(receipt_data) do
      {parsed_attributes, ""} ->
        # Parse the receipt attributes to find in-app purchases
        case parse_receipt_attribute_set(parsed_attributes) do
          {:ok, in_app_purchases} -> {:ok, in_app_purchases}
          {:error, reason} -> {:error, reason}
        end

      _error ->
        {:error, :invalid_receipt_asn1}
    end
  rescue
    _error ->
      {:error, :receipt_parse_error}
  end

  defp parse_receipt_attribute_set({17, attributes}) when is_list(attributes) do
    # Parse ASN.1 CONSTRUCTED of receipt attributes
    # Look for attribute type 17 (in-app purchase array)
    case find_attribute_in_list(attributes, 17) do
      {:ok, in_app_data} ->
        # Parse in-app purchase array
        parse_in_app_purchase_array(in_app_data)

      {:error, :attribute_not_found} ->
        # No in-app purchases found
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_receipt_attribute_set({49, attributes}) when is_list(attributes) do
    # Parse ASN.1 SET of receipt attributes (alternative format)
    # Look for attribute type 17 (in-app purchase array)
    case find_attribute_in_list(attributes, 17) do
      {:ok, in_app_data} ->
        # Parse in-app purchase array
        parse_in_app_purchase_array(in_app_data)

      {:error, :attribute_not_found} ->
        # No in-app purchases found
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_receipt_attribute_set({tag, _content}) do
    {:error, {:unexpected_receipt_tag, tag}}
  end

  defp find_transaction_id_in_flat_list(attributes, target_type) when is_list(attributes) do
    # Find transaction ID in a flat list of type-value pairs
    # The list structure is like: [{2, type}, {2, version}, {4, value}, {2, type}, {2, version}, {4, value}, ...]
    target_type_binary =
      case target_type do
        1703 -> <<6, 167>>
        1705 -> <<6, 169>>
        _ -> <<target_type>>
      end

    # Walk through the list in groups of 3: [{2, type}, {2, version}, {4, value}]
    do_find_transaction_id_in_groups(attributes, target_type_binary, [])
  end

  defp do_find_transaction_id_in_groups([], _target_type, _acc) do
    {:error, :attribute_not_found}
  end

  defp do_find_transaction_id_in_groups(
         [{2, type_binary}, {2, _version}, {4, value} | rest],
         target_type_binary,
         _acc
       ) do
    case type_binary do
      ^target_type_binary ->
        # Decode the ASN.1 encoded value if needed
        decoded_value = decode_asn1_value(value)
        {:ok, decoded_value}

      _ ->
        do_find_transaction_id_in_groups(rest, target_type_binary, [])
    end
  end

  defp do_find_transaction_id_in_groups([_ | rest], target_type_binary, acc) do
    # Skip any unexpected elements and continue
    do_find_transaction_id_in_groups(rest, target_type_binary, acc)
  end

  defp find_attribute_in_list(attributes, target_type) when is_list(attributes) do
    # Find an attribute of the given type in the list
    # Attributes are structured as {16, [{2, type}, {2, 1}, {4, value}]}

    # Convert target type to multi-byte format if needed
    target_type_binary =
      case target_type do
        # Single byte for in-app purchases
        17 -> <<17>>
        # Multi-byte for transaction ID (1703 = 0x06A7)
        1703 -> <<6, 167>>
        # Multi-byte for original transaction ID (1705 = 0x06A9)
        1705 -> <<6, 169>>
        # Default to single byte
        _ -> <<target_type>>
      end

    Enum.find_value(attributes, {:error, :attribute_not_found}, fn
      {16, [{2, type_binary}, {2, 1}, {4, value}]} ->
        # Convert binary type to integer for comparison
        case type_binary do
          ^target_type_binary ->
            {:ok, value}

          _ ->
            nil
        end

      {16, [{2, type_binary}, {2, _version}, {4, value}]} when is_binary(value) ->
        # More flexible pattern - version might not always be <<1>>
        case type_binary do
          ^target_type_binary ->
            {:ok, value}

          _ ->
            nil
        end

      _other ->
        nil
    end)
  end

  defp parse_in_app_purchase_array(in_app_data) when is_binary(in_app_data) do
    # Parse the in-app purchase array (should be ASN.1 SET)
    case :asn1rt_nif.decode_ber_tlv(in_app_data) do
      {parsed_in_apps, ""} ->
        # Parse each in-app purchase to extract transaction IDs
        case extract_transaction_ids_from_in_apps(parsed_in_apps) do
          {:ok, transaction_ids} ->
            {:ok, transaction_ids}

          {:error, reason} ->
            {:error, reason}
        end

      {_parsed_in_apps, _remainder} ->
        {:error, :invalid_in_app_asn1}

      _error ->
        {:error, :invalid_in_app_asn1}
    end
  rescue
    _error ->
      {:error, :in_app_parse_error}
  end

  defp extract_transaction_ids_from_in_apps({tag, in_app_list})
       when tag in [17, 49] and is_list(in_app_list) do
    transaction_ids =
      in_app_list
      |> Enum.map(&extract_transaction_id_from_purchase/1)
      |> Enum.flat_map(fn
        {:ok, id} -> [id]
        {:error, _} -> []
      end)

    {:ok, transaction_ids}
  end

  defp extract_transaction_ids_from_in_apps(_), do: {:error, :unexpected_in_app_format}

  defp extract_transaction_id_from_purchase({16, attributes}) when is_list(attributes) do
    find_transaction_id_with_fallback(attributes, &find_transaction_id_in_flat_list/2)
  end

  defp extract_transaction_id_from_purchase({49, attributes}) when is_list(attributes) do
    find_transaction_id_with_fallback(attributes, &find_attribute_in_list/2)
  end

  defp find_transaction_id_with_fallback(attributes, finder_fn) do
    # Try transaction ID (1703), fallback to original transaction ID (1705)
    with {:error, _} <- try_find_binary_attribute(attributes, 1703, finder_fn) do
      try_find_binary_attribute(attributes, 1705, finder_fn)
    end
  end

  defp try_find_binary_attribute(attributes, type, finder_fn) do
    case finder_fn.(attributes, type) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      _ -> {:error, :transaction_id_not_found}
    end
  end

  defp find_first_transaction_id(in_app_purchases) do
    # Find the first non-nil transaction ID from the list of purchases
    # in_app_purchases is a list of transaction ID strings
    Enum.find_value(in_app_purchases, fn transaction_id ->
      case transaction_id do
        nil ->
          false

        transaction_id when is_binary(transaction_id) ->
          # Convert binary to string
          to_string(transaction_id)

        _ ->
          false
      end
    end)
  end

  defp starts_with_asn1_sequence?(content) do
    # Check if content starts with ASN.1 SEQUENCE
    case content do
      # Starts with ASN.1 SEQUENCE for receipt
      <<49, _::binary>> -> true
      # Starts with ASN.1 SEQUENCE
      <<48, _::binary>> -> true
      _ -> false
    end
  end

  defp decode_asn1_value(value) when is_binary(value) do
    # Try to decode ASN.1 encoded values
    case value do
      # UTF8String format: <<12, length, bytes...>>
      <<12, length, data::binary-size(length)>> ->
        data

      # OCTET STRING format: <<4, length, bytes...>>
      <<4, length, data::binary-size(length)>> ->
        data

      # Direct string (no ASN.1 encoding)
      _ when byte_size(value) > 0 ->
        value

      # Empty or invalid
      _ ->
        value
    end
  end

  defp looks_like_random_binary?(content) do
    # Check if content looks like random binary data rather than ASN.1
    # This is a heuristic to avoid trying to parse non-ASN.1 data
    case content do
      # Check for common patterns that suggest non-ASN.1 data
      # Common padding
      <<0, 0, 0, 0, _::binary>> -> true
      # Common padding
      <<255, 255, 255, 255, _::binary>> -> true
      _ -> false
    end
  end
end
