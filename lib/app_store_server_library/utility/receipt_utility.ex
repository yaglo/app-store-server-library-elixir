defmodule AppStoreServerLibrary.Utility.ReceiptUtility do
  @moduledoc """
  Utility functions for extracting transaction IDs from App Store receipts.

  This module provides functions to extract transaction IDs from:
  - App receipts (PKCS#7 format)
  - Transaction receipts

  **Note**: NO validation is performed on the receipt, and any data returned
  should only be used to call the App Store Server API.
  """

  # ASN.1/PKCS#7 Tag Constants
  # In BER/DER encoding, context-specific constructed tags are encoded as:
  # tag = 0xA0 + tag_number for [0], [1], [2], etc.
  # When parsed by :asn1rt_nif, these become integers.
  # 131_072 = 0x20000 represents a context-specific constructed [0] tag
  # used for the signed content in PKCS#7 SignedData structures.
  @pkcs7_signed_data_tag 131_072

  @doc """
  Extracts a transaction ID from an encoded App receipt.

  ## Parameters

    * `app_receipt` - The unmodified app receipt (base64 encoded)

  ## Returns

    * `{:ok, transaction_id}` if found
    * `{:ok, nil}` if receipt contains no in-app purchases
    * `{:error, reason}` if receipt format is invalid

  """
  @spec extract_transaction_id_from_app_receipt(String.t()) ::
          {:ok, String.t() | nil} | {:error, atom() | tuple()}
  def extract_transaction_id_from_app_receipt(app_receipt) when is_binary(app_receipt) do
    with {:ok, decoded_receipt} <- base64_decode(app_receipt),
         {:ok, receipt_data} <- extract_receipt_data(decoded_receipt),
         {:ok, in_app_purchases} <- parse_receipt_attributes(receipt_data) do
      {:ok, find_first_transaction_id(in_app_purchases)}
    end
  end

  @doc """
  Extracts a transaction ID from an encoded transaction receipt.

  ## Parameters

    * `transaction_receipt` - The unmodified transaction receipt (base64 encoded)

  ## Returns

    * `{:ok, transaction_id}` if found
    * `{:ok, nil}` if no transaction ID is found
    * `{:error, reason}` if receipt format is invalid

  """
  @spec extract_transaction_id_from_transaction_receipt(String.t()) ::
          {:ok, String.t() | nil} | {:error, atom() | tuple()}
  def extract_transaction_id_from_transaction_receipt(transaction_receipt)
      when is_binary(transaction_receipt) do
    with {:ok, decoded_top_level} <- base64_decode(transaction_receipt),
         {:ok, purchase_info_b64} <- extract_purchase_info(decoded_top_level),
         {:ok, decoded_inner_level} <- base64_decode(purchase_info_b64) do
      {:ok, extract_transaction_id_from_inner(decoded_inner_level)}
    else
      {:not_found, nil} -> {:ok, nil}
      {:error, reason} -> {:error, reason}
    end
  end

  # Base64 decoding

  defp base64_decode(data) do
    case Base.decode64(data) do
      {:ok, decoded} -> {:ok, decoded}
      :error -> {:error, :invalid_base64}
    end
  end

  # Transaction receipt helpers

  defp extract_purchase_info(decoded_data) do
    case Regex.run(~r/"purchase-info"\s*=\s*"([a-zA-Z0-9+\/=]+)"/, decoded_data) do
      [_, purchase_info_b64] -> {:ok, purchase_info_b64}
      nil -> {:not_found, nil}
    end
  end

  defp extract_transaction_id_from_inner(decoded_inner_level) do
    case Regex.run(~r/"transaction-id"\s*=\s*"([a-zA-Z0-9+\/=]+)"/, decoded_inner_level) do
      [_, transaction_id] -> transaction_id
      nil -> nil
    end
  end

  # PKCS#7 / ASN.1 receipt parsing
  # Note: :asn1rt_nif.decode_ber_tlv can exit (not raise) on malformed data,
  # so we wrap calls in safe_decode_ber_tlv to handle exits gracefully.

  defp extract_receipt_data(decoded_receipt) do
    case safe_decode_ber_tlv(decoded_receipt) do
      {:ok, {parsed_data, ""}} ->
        extract_content_from_pkcs7(parsed_data)

      {:ok, {_parsed_data, _remainder}} ->
        {:error, :invalid_pkcs7_format}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Safely decode BER TLV, catching exits from :asn1rt_nif
  defp safe_decode_ber_tlv(data) do
    {:ok, :asn1rt_nif.decode_ber_tlv(data)}
  catch
    :exit, _ -> {:error, :asn1_decode_error}
    :error, _ -> {:error, :asn1_decode_error}
  end

  defp extract_content_from_pkcs7({16, content_list}) when is_list(content_list) do
    find_receipt_data_in_content_info(content_list)
  end

  defp extract_content_from_pkcs7({tag, _content}) do
    {:error, {:unexpected_pkcs7_tag, tag}}
  end

  defp find_receipt_data_in_content_info(content_list) do
    case content_list do
      [{6, _content_type}, {@pkcs7_signed_data_tag, signed_data_content}] ->
        extract_receipt_data_from_signed_data(signed_data_content)

      _ ->
        {:error, :signed_data_not_found}
    end
  end

  defp extract_receipt_data_from_signed_data(signed_data_content) do
    case navigate_to_receipt_data(signed_data_content) do
      {:ok, receipt_data} -> {:ok, receipt_data}
      {:error, reason} -> {:error, reason}
    end
  end

  defp navigate_to_receipt_data(signed_data_content) do
    case safe_at(signed_data_content, 0) do
      {:ok, level0} -> find_receipt_in_element(level0)
      {:error, reason} -> {:error, reason}
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

  defp safe_at(list, index) when is_list(list) and index < length(list) do
    {:ok, Enum.at(list, index)}
  end

  defp safe_at(_list, _index), do: {:error, :index_out_of_bounds}

  defp find_nested_octet_string(elements) when is_list(elements) do
    case Enum.find_value(elements, &search_octet_string_element/1) do
      {:ok, _} = result -> result
      nil -> {:error, :receipt_data_not_found}
    end
  end

  defp find_nested_octet_string(_), do: {:error, :receipt_data_not_found}

  defp search_octet_string_element({4, [{4, receipt_data}]}), do: {:ok, receipt_data}

  defp search_octet_string_element({4, receipt_data}) when is_binary(receipt_data),
    do: {:ok, receipt_data}

  defp search_octet_string_element({_tag, content}) when is_list(content),
    do: Enum.find_value(content, &search_octet_string_element/1)

  defp search_octet_string_element({_tag, content}) when is_binary(content),
    do: try_parse_binary_content(content)

  defp search_octet_string_element(_), do: nil

  defp try_parse_binary_content(content) do
    cond do
      starts_with_asn1_sequence?(content) ->
        {:ok, content}

      byte_size(content) > 10 ->
        try_decode_asn1(content)

      true ->
        nil
    end
  end

  defp try_decode_asn1(content) do
    case safe_decode_ber_tlv(content) do
      {:ok, {parsed_data, ""}} ->
        Enum.find_value([parsed_data], &search_octet_string_element/1)

      _ ->
        nil
    end
  end

  # ASN.1 tag 48 = SEQUENCE, tag 49 = SET
  defp starts_with_asn1_sequence?(<<49, _::binary>>), do: true
  defp starts_with_asn1_sequence?(<<48, _::binary>>), do: true
  defp starts_with_asn1_sequence?(_), do: false

  # Receipt attribute parsing

  defp parse_receipt_attributes(receipt_data) do
    case safe_decode_ber_tlv(receipt_data) do
      {:ok, {parsed_attributes, ""}} ->
        parse_receipt_attribute_set(parsed_attributes)

      {:ok, _} ->
        {:error, :invalid_receipt_asn1}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ASN.1 tag 17 = SET OF (universal constructed), 49 = SET (alternative encoding)
  # Apple receipts use SET for the receipt attribute collection
  defp parse_receipt_attribute_set({tag, attributes})
       when tag in [17, 49] and is_list(attributes) do
    case find_attribute_by_type(attributes, 17) do
      {:ok, in_app_data} -> parse_in_app_purchase_array(in_app_data)
      {:error, :attribute_not_found} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_receipt_attribute_set({tag, _content}) do
    {:error, {:unexpected_receipt_tag, tag}}
  end

  defp find_attribute_by_type(attributes, target_type) when is_list(attributes) do
    target_type_binary = encode_attribute_type(target_type)

    Enum.find_value(attributes, {:error, :attribute_not_found}, fn
      {16, [{2, ^target_type_binary}, {2, _version}, {4, value}]} ->
        {:ok, value}

      _ ->
        nil
    end)
  end

  # Apple Receipt Attribute Types (encoded as BER integers)
  # 17 = In-App Purchase Receipt array
  # 1703 = Transaction Identifier (original)
  # 1705 = Transaction Identifier (web order line item)
  defp encode_attribute_type(17), do: <<17>>
  defp encode_attribute_type(1703), do: <<6, 167>>
  defp encode_attribute_type(1705), do: <<6, 169>>

  defp parse_in_app_purchase_array(in_app_data) when is_binary(in_app_data) do
    case safe_decode_ber_tlv(in_app_data) do
      {:ok, {parsed_in_apps, ""}} ->
        extract_transaction_ids_from_in_apps(parsed_in_apps)

      {:ok, _} ->
        {:error, :invalid_in_app_asn1}

      {:error, reason} ->
        {:error, reason}
    end
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

  defp extract_transaction_id_from_purchase({tag, attributes})
       when tag in [16, 49] and is_list(attributes) do
    find_transaction_id_with_fallback(attributes)
  end

  defp extract_transaction_id_from_purchase(_), do: {:error, :unexpected_purchase_format}

  defp find_transaction_id_with_fallback(attributes) do
    case find_transaction_id_in_attributes(attributes, 1703) do
      {:ok, _} = result -> result
      {:error, _} -> find_transaction_id_in_attributes(attributes, 1705)
    end
  end

  defp find_transaction_id_in_attributes(attributes, target_type) do
    target_type_binary = encode_attribute_type(target_type)

    result =
      attributes
      |> find_in_grouped_attributes(target_type_binary)

    case result do
      {:ok, value} when is_binary(value) -> {:ok, decode_asn1_string(value)}
      _ -> {:error, :transaction_id_not_found}
    end
  end

  defp find_in_grouped_attributes(attributes, target_type_binary) do
    do_find_in_groups(attributes, target_type_binary)
  end

  defp do_find_in_groups([], _target), do: {:error, :attribute_not_found}

  defp do_find_in_groups([{2, type_binary}, {2, _version}, {4, value} | rest], target) do
    if type_binary == target do
      {:ok, value}
    else
      do_find_in_groups(rest, target)
    end
  end

  defp do_find_in_groups([_ | rest], target), do: do_find_in_groups(rest, target)

  # ASN.1 string decoding: extract the string content from TLV encoding
  # Tag 12 = UTF8String, Tag 4 = OCTET STRING
  defp decode_asn1_string(<<12, length, data::binary-size(length)>>), do: data
  defp decode_asn1_string(<<4, length, data::binary-size(length)>>), do: data
  defp decode_asn1_string(value), do: value

  defp find_first_transaction_id([]), do: nil
  defp find_first_transaction_id([nil | rest]), do: find_first_transaction_id(rest)
  defp find_first_transaction_id([id | _]) when is_binary(id), do: id
  defp find_first_transaction_id([_ | rest]), do: find_first_transaction_id(rest)
end
