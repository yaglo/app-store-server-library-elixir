defmodule AppStoreServerLibrary.ReceiptUtilityTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Utility.ReceiptUtility

  # Constants matching Python test
  @app_receipt_expected_transaction_id "0"
  @transaction_receipt_expected_transaction_id "33993399"

  describe "extract_transaction_id_from_app_receipt/1" do
    test "xcode app receipt extraction with no transactions" do
      receipt = File.read!("test/resources/xcode/xcode-app-receipt-empty")

      extracted_transaction_id = ReceiptUtility.extract_transaction_id_from_app_receipt(receipt)

      assert extracted_transaction_id == {:ok, nil}
    end

    test "xcode app receipt extraction with transactions" do
      receipt = File.read!("test/resources/xcode/xcode-app-receipt-with-transaction")

      extracted_transaction_id = ReceiptUtility.extract_transaction_id_from_app_receipt(receipt)

      assert extracted_transaction_id == {:ok, @app_receipt_expected_transaction_id}
    end

    test "returns error for invalid base64" do
      result = ReceiptUtility.extract_transaction_id_from_app_receipt("not-valid-base64!!!")

      assert {:error, :invalid_base64} = result
    end

    # Note: These tests use catch_exit because :asn1rt_nif.decode_ber_tlv exits on invalid data
    # rather than raising exceptions that can be rescued
    test "returns error or exits for empty string" do
      result =
        try do
          ReceiptUtility.extract_transaction_id_from_app_receipt("")
        catch
          :exit, _ -> {:error, :asn1_exit}
        end

      assert {:error, _reason} = result
    end

    test "returns error or exits for random binary data" do
      # Valid base64 but not a valid receipt
      random_data = Base.encode64(:crypto.strong_rand_bytes(100))

      result =
        try do
          ReceiptUtility.extract_transaction_id_from_app_receipt(random_data)
        catch
          :exit, _ -> {:error, :asn1_exit}
        end

      assert {:error, _reason} = result
    end

    test "returns error or exits for simple base64 text" do
      # Valid base64 of simple text, not ASN.1
      simple_text = Base.encode64("Hello, World!")

      result =
        try do
          ReceiptUtility.extract_transaction_id_from_app_receipt(simple_text)
        catch
          :exit, _ -> {:error, :asn1_exit}
        end

      assert {:error, _reason} = result
    end

    test "returns same transaction ID on repeated calls" do
      receipt = File.read!("test/resources/xcode/xcode-app-receipt-with-transaction")

      result1 = ReceiptUtility.extract_transaction_id_from_app_receipt(receipt)
      result2 = ReceiptUtility.extract_transaction_id_from_app_receipt(receipt)

      assert result1 == result2
      assert {:ok, @app_receipt_expected_transaction_id} = result1
    end
  end

  describe "extract_transaction_id_from_transaction_receipt/1" do
    test "transaction receipt extraction" do
      receipt = File.read!("test/resources/mock_signed_data/legacyTransaction")

      extracted_transaction_id =
        ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert extracted_transaction_id == {:ok, @transaction_receipt_expected_transaction_id}
    end

    test "returns nil for receipt without purchase-info" do
      # Valid base64 but no purchase-info field
      no_purchase_info = Base.encode64("some-random-data-without-purchase-info")
      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(no_purchase_info)

      assert {:ok, nil} = result
    end

    test "returns nil for receipt with purchase-info but no transaction-id" do
      # Has purchase-info but the inner content has no transaction-id
      inner_content = Base.encode64("inner-content-no-transaction")
      receipt_content = ~s("purchase-info" = "#{inner_content}")
      encoded_receipt = Base.encode64(receipt_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(encoded_receipt)

      assert {:ok, nil} = result
    end

    test "returns error for invalid base64" do
      result =
        ReceiptUtility.extract_transaction_id_from_transaction_receipt("not-valid-base64!!!")

      assert {:error, :invalid_base64} = result
    end

    test "extracts transaction-id from properly formatted receipt" do
      # Build a properly formatted transaction receipt
      inner_content = ~s("transaction-id" = "12345678")
      inner_b64 = Base.encode64(inner_content)
      outer_content = ~s("purchase-info" = "#{inner_b64}")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert {:ok, "12345678"} = result
    end

    test "handles whitespace variations in purchase-info format" do
      # With extra spaces
      inner_content = ~s("transaction-id" = "98765432")
      inner_b64 = Base.encode64(inner_content)
      outer_content = ~s("purchase-info"   =   "#{inner_b64}")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert {:ok, "98765432"} = result
    end

    test "handles whitespace variations in transaction-id format" do
      inner_content = ~s("transaction-id"   =   "11112222")
      inner_b64 = Base.encode64(inner_content)
      outer_content = ~s("purchase-info" = "#{inner_b64}")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert {:ok, "11112222"} = result
    end

    test "returns nil for non-matching purchase-info format" do
      # purchase-info value contains invalid characters that don't match the regex
      # The regex only matches [a-zA-Z0-9+\/=]+ so "!!!" won't match
      outer_content = ~s("purchase-info" = "not-valid-base64!!!")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      # Returns nil because the regex doesn't match (not an error)
      assert {:ok, nil} = result
    end

    test "returns nil for empty purchase-info content" do
      # Empty inner content
      inner_content = ""
      inner_b64 = Base.encode64(inner_content)
      outer_content = ~s("purchase-info" = "#{inner_b64}")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert {:ok, nil} = result
    end

    test "extracts alphanumeric transaction IDs" do
      inner_content = ~s("transaction-id" = "ABC123XYZ")
      inner_b64 = Base.encode64(inner_content)
      outer_content = ~s("purchase-info" = "#{inner_b64}")
      receipt = Base.encode64(outer_content)

      result = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert {:ok, "ABC123XYZ"} = result
    end

    test "returns same transaction ID on repeated calls" do
      receipt = File.read!("test/resources/mock_signed_data/legacyTransaction")

      result1 = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)
      result2 = ReceiptUtility.extract_transaction_id_from_transaction_receipt(receipt)

      assert result1 == result2
      assert {:ok, @transaction_receipt_expected_transaction_id} = result1
    end
  end
end
