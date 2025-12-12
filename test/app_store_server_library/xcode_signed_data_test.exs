defmodule AppStoreServerLibrary.XcodeSignedDataTest do
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Verification.SignedDataVerifier

  @xcode_bundle_id "com.example.naturelab.backyardbirds.example"

  defp read_xcode_file(filename) do
    Path.join(["test", "resources", "xcode", filename])
    |> File.read!()
    |> String.trim()
  end

  defp get_xcode_verifier(environment, bundle_id, app_apple_id \\ nil) do
    # For Xcode environment, root certificates aren't needed since verification is skipped
    opts = [
      root_certificates: [],
      enable_online_checks: false,
      environment: environment,
      bundle_id: bundle_id
    ]

    opts = if app_apple_id, do: Keyword.put(opts, :app_apple_id, app_apple_id), else: opts
    SignedDataVerifier.new(opts)
  end

  describe "Xcode signed app transaction" do
    test "decodes app transaction correctly" do
      verifier = get_xcode_verifier(:xcode, @xcode_bundle_id)
      encoded_app_transaction = read_xcode_file("xcode-signed-app-transaction")

      result =
        SignedDataVerifier.verify_and_decode_app_transaction(verifier, encoded_app_transaction)

      assert {:ok, app_transaction} = result
      assert app_transaction.bundle_id == @xcode_bundle_id
      assert app_transaction.application_version == "1"
      assert app_transaction.original_application_version == "1"

      assert app_transaction.device_verification ==
               "cYUsXc53EbYc0pOeXG5d6/31LGHeVGf84sqSN0OrJi5u/j2H89WWKgS8N0hMsMlf"

      assert app_transaction.device_verification_nonce == "48c8b92d-ce0d-4229-bedf-e61b4f9cfc92"
      assert app_transaction.receipt_type == :xcode
    end

    test "fails with production environment" do
      verifier = get_xcode_verifier(:production, @xcode_bundle_id, 1234)
      encoded_app_transaction = read_xcode_file("xcode-signed-app-transaction")

      result =
        SignedDataVerifier.verify_and_decode_app_transaction(verifier, encoded_app_transaction)

      assert {:error, _reason} = result
    end
  end

  describe "Xcode signed transaction" do
    test "decodes transaction correctly" do
      verifier = get_xcode_verifier(:xcode, @xcode_bundle_id)
      encoded_transaction = read_xcode_file("xcode-signed-transaction")

      result =
        SignedDataVerifier.verify_and_decode_signed_transaction(verifier, encoded_transaction)

      assert {:ok, transaction} = result
      assert transaction.original_transaction_id == "0"
      assert transaction.transaction_id == "0"
      assert transaction.bundle_id == @xcode_bundle_id
      assert transaction.product_id == "pass.premium"
      assert transaction.subscription_group_identifier == "6F3A93AB"
      assert transaction.quantity == 1
      assert transaction.environment == :xcode
    end
  end

  describe "Xcode signed renewal info" do
    test "decodes renewal info correctly" do
      verifier = get_xcode_verifier(:xcode, @xcode_bundle_id)
      encoded_renewal_info = read_xcode_file("xcode-signed-renewal-info")

      result = SignedDataVerifier.verify_and_decode_renewal_info(verifier, encoded_renewal_info)

      assert {:ok, renewal_info} = result
      assert renewal_info.original_transaction_id == "0"
      assert renewal_info.auto_renew_product_id == "pass.premium"
      assert renewal_info.product_id == "pass.premium"
      assert renewal_info.environment == :xcode
    end
  end

  describe "local_testing environment" do
    test "decodes transaction without certificate verification" do
      verifier = get_xcode_verifier(:local_testing, @xcode_bundle_id)
      encoded_transaction = read_xcode_file("xcode-signed-transaction")

      # local_testing should also skip verification like xcode
      # but environment check will fail since the signed data is for xcode environment
      result =
        SignedDataVerifier.verify_and_decode_signed_transaction(verifier, encoded_transaction)

      # Environment mismatch expected
      assert {:error, {:invalid_environment, _}} = result
    end
  end
end
