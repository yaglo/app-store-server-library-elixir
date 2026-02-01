defmodule AppStoreServerLibrary.StringEnumConversionTest do
  @moduledoc """
  Tests that string enum fields are properly converted to atoms via
  Validator.optional_string_enum/4 in all model structs that use it.

  This mirrors the integer_enum_conversion_test.exs pattern for string-based enums.
  """
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.{
    AppData,
    AppTransaction,
    Data,
    DecodedRealtimeRequestBody,
    JWSRenewalInfoDecodedPayload,
    JWSTransactionDecodedPayload,
    ResponseBodyV2DecodedPayload,
    Summary
  }

  alias AppStoreServerLibrary.Utility.JSON
  alias AppStoreServerLibrary.Verification.Validator

  # ---------------------------------------------------------------------------
  # Validator.optional_string_enum/4 unit tests
  # ---------------------------------------------------------------------------
  describe "Validator.optional_string_enum/4" do
    test "returns {:ok, map} when field is nil" do
      assert {:ok, %{}} =
               Validator.optional_string_enum(
                 %{},
                 "environment",
                 [:sandbox, :production, "Sandbox", "Production"],
                 AppStoreServerLibrary.Models.Environment
               )
    end

    test "converts string to atom via enum module (atom-keyed map)" do
      map = %{environment: "Sandbox", raw_environment: nil}

      {:ok, updated} =
        Validator.optional_string_enum(
          map,
          "environment",
          AppStoreServerLibrary.Models.Environment.allowed_values(),
          AppStoreServerLibrary.Models.Environment
        )

      assert updated.environment == :sandbox
      # raw_environment was already present (nil), so put_new does NOT overwrite
      assert updated.raw_environment == nil
    end

    test "sets raw_ field when not already present (atom-keyed map)" do
      map = %{environment: "Production"}

      {:ok, updated} =
        Validator.optional_string_enum(
          map,
          "environment",
          AppStoreServerLibrary.Models.Environment.allowed_values(),
          AppStoreServerLibrary.Models.Environment
        )

      assert updated.environment == :production
      assert updated.raw_environment == "Production"
    end

    test "passes through already-converted atom value" do
      map = %{environment: :sandbox}

      {:ok, updated} =
        Validator.optional_string_enum(
          map,
          "environment",
          AppStoreServerLibrary.Models.Environment.allowed_values(),
          AppStoreServerLibrary.Models.Environment
        )

      assert updated.environment == :sandbox
    end

    test "rejects unknown string value" do
      map = %{environment: "InvalidEnvironment"}

      assert {:error, {:verification_failure, _}} =
               Validator.optional_string_enum(
                 map,
                 "environment",
                 [:sandbox, :production, "Sandbox", "Production"],
                 AppStoreServerLibrary.Models.Environment
               )
    end

    test "converts string in string-keyed map" do
      map = %{"notification_type" => "TEST"}

      {:ok, updated} =
        Validator.optional_string_enum(
          map,
          "notification_type",
          [:test, "TEST"],
          AppStoreServerLibrary.Models.NotificationTypeV2
        )

      assert updated["notification_type"] == :test
      assert updated["raw_notification_type"] == "TEST"
    end

    test "does not overwrite explicit raw_ field" do
      map = %{environment: "Sandbox", raw_environment: "AlreadySet"}

      {:ok, updated} =
        Validator.optional_string_enum(
          map,
          "environment",
          AppStoreServerLibrary.Models.Environment.allowed_values(),
          AppStoreServerLibrary.Models.Environment
        )

      assert updated.environment == :sandbox
      assert updated.raw_environment == "AlreadySet"
    end
  end

  # ---------------------------------------------------------------------------
  # keys_to_atoms no longer converts values
  # ---------------------------------------------------------------------------
  describe "keys_to_atoms value preservation" do
    test "does not convert environment values" do
      result = JSON.keys_to_atoms(%{"environment" => "Production"})
      assert result.environment == "Production"
    end

    test "does not convert receiptType values" do
      result = JSON.keys_to_atoms(%{"receiptType" => "Sandbox"})
      assert result.receipt_type == "Sandbox"
    end

    test "does not convert notificationType values" do
      result = JSON.keys_to_atoms(%{"notificationType" => "TEST"})
      assert result.notification_type == "TEST"
    end

    test "preserves nested map values" do
      result =
        JSON.keys_to_atoms(%{
          "data" => %{
            "environment" => "Sandbox",
            "status" => 1
          }
        })

      assert result.data.environment == "Sandbox"
      assert result.data.status == 1
    end
  end

  # ---------------------------------------------------------------------------
  # ResponseBodyV2DecodedPayload - notification_type and subtype
  # ---------------------------------------------------------------------------
  describe "ResponseBodyV2DecodedPayload string enum conversion" do
    test "converts notification_type and sets raw_notification_type" do
      {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{notification_type: "TEST"})
      assert payload.notification_type == :test
      assert payload.raw_notification_type == "TEST"
    end

    test "converts subtype and sets raw_subtype" do
      {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{subtype: "INITIAL_BUY"})
      assert payload.subtype == :initial_buy
      assert payload.raw_subtype == "INITIAL_BUY"
    end

    test "converts all known notification types" do
      types = [
        {"CONSUMPTION_REQUEST", :consumption_request},
        {"DID_CHANGE_RENEWAL_PREF", :did_change_renewal_pref},
        {"DID_CHANGE_RENEWAL_STATUS", :did_change_renewal_status},
        {"DID_FAIL_TO_RENEW", :did_fail_to_renew},
        {"DID_RENEW", :did_renew},
        {"EXPIRED", :expired},
        {"EXTERNAL_PURCHASE_TOKEN", :external_purchase_token},
        {"GRACE_PERIOD_EXPIRED", :grace_period_expired},
        {"OFFER_REDEEMED", :offer_redeemed},
        {"REFUND", :refund},
        {"RENEWAL_EXTENDED", :renewal_extended},
        {"RENEWAL_EXTENSION", :renewal_extension},
        {"REVOKE", :revoke},
        {"SUBSCRIBED", :subscribed},
        {"TEST", :test}
      ]

      for {string, atom} <- types do
        {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{notification_type: string})
        assert payload.notification_type == atom, "Expected #{inspect(atom)} for #{string}"
        assert payload.raw_notification_type == string
      end
    end

    test "converts all known subtypes" do
      subtypes = [
        {"ACCEPTED", :accepted},
        {"AUTO_RENEW_DISABLED", :auto_renew_disabled},
        {"AUTO_RENEW_ENABLED", :auto_renew_enabled},
        {"BILLING_RECOVERY", :billing_recovery},
        {"BILLING_RETRY", :billing_retry},
        {"INITIAL_BUY", :initial_buy},
        {"RESUBSCRIBE", :resubscribe},
        {"SUMMARY", :summary},
        {"UPGRADE", :upgrade},
        {"VOLUNTARY", :voluntary}
      ]

      for {string, atom} <- subtypes do
        {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{subtype: string})
        assert payload.subtype == atom, "Expected #{inspect(atom)} for #{string}"
        assert payload.raw_subtype == string
      end
    end

    test "handles nil notification_type and subtype" do
      {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{})
      assert payload.notification_type == nil
      assert payload.raw_notification_type == nil
      assert payload.subtype == nil
      assert payload.raw_subtype == nil
    end

    test "passes through already-converted atom notification_type" do
      {:ok, payload} = ResponseBodyV2DecodedPayload.new(%{notification_type: :test})
      assert payload.notification_type == :test
    end

    test "full notification payload from fixture converts enums" do
      json = File.read!("test/resources/models/signedNotification.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      {:ok, payload} = ResponseBodyV2DecodedPayload.new(map)

      assert payload.notification_type == :subscribed
      assert payload.raw_notification_type == "SUBSCRIBED"
      assert payload.subtype == :initial_buy
      assert payload.raw_subtype == "INITIAL_BUY"
    end
  end

  # ---------------------------------------------------------------------------
  # Data - environment, status, consumption_request_reason
  # ---------------------------------------------------------------------------
  describe "Data string enum conversion" do
    test "converts environment and sets raw_environment" do
      {:ok, data} = Data.new(%{environment: "Sandbox"})
      assert data.environment == :sandbox
      assert data.raw_environment == "Sandbox"
    end

    test "converts consumption_request_reason and sets raw" do
      {:ok, data} = Data.new(%{consumption_request_reason: "UNINTENDED_PURCHASE"})
      assert data.consumption_request_reason == :unintended_purchase
      assert data.raw_consumption_request_reason == "UNINTENDED_PURCHASE"
    end

    test "converts all known consumption request reasons" do
      reasons = [
        {"UNINTENDED_PURCHASE", :unintended_purchase},
        {"FULFILLMENT_ISSUE", :fulfillment_issue},
        {"UNSATISFIED_WITH_PURCHASE", :unsatisfied_with_purchase},
        {"LEGAL", :legal},
        {"OTHER", :other}
      ]

      for {string, atom} <- reasons do
        {:ok, data} = Data.new(%{consumption_request_reason: string})
        assert data.consumption_request_reason == atom
        assert data.raw_consumption_request_reason == string
      end
    end

    test "full notification data from fixture converts enums" do
      json = File.read!("test/resources/models/signedConsumptionRequestNotification.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      data_map = map.data
      {:ok, data} = Data.new(data_map)

      assert data.environment == :local_testing
      assert data.raw_environment == "LocalTesting"
      assert data.consumption_request_reason == :unintended_purchase
      assert data.raw_consumption_request_reason == "UNINTENDED_PURCHASE"
      assert data.status == :active
      assert data.raw_status == 1
    end
  end

  # ---------------------------------------------------------------------------
  # JWSTransactionDecodedPayload - type, in_app_ownership_type, etc.
  # ---------------------------------------------------------------------------
  describe "JWSTransactionDecodedPayload string enum conversion" do
    test "converts type and sets raw_type" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{type: "Auto-Renewable Subscription"})
      assert payload.type == :auto_renewable_subscription
      assert payload.raw_type == "Auto-Renewable Subscription"
    end

    test "converts in_app_ownership_type and sets raw" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{in_app_ownership_type: "PURCHASED"})
      assert payload.in_app_ownership_type == :purchased
      assert payload.raw_in_app_ownership_type == "PURCHASED"
    end

    test "converts transaction_reason and sets raw" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{transaction_reason: "PURCHASE"})
      assert payload.transaction_reason == :purchase
      assert payload.raw_transaction_reason == "PURCHASE"
    end

    test "converts offer_discount_type and sets raw" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{offer_discount_type: "FREE_TRIAL"})
      assert payload.offer_discount_type == :free_trial
      assert payload.raw_offer_discount_type == "FREE_TRIAL"
    end

    test "converts environment and sets raw" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{environment: "Production"})
      assert payload.environment == :production
      assert payload.raw_environment == "Production"
    end

    test "converts revocation_type and sets raw" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{revocation_type: "REFUND_FULL"})
      assert payload.revocation_type == :refund_full
      assert payload.raw_revocation_type == "REFUND_FULL"
    end

    test "handles nil string enum fields" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{})
      assert payload.type == nil
      assert payload.raw_type == nil
      assert payload.in_app_ownership_type == nil
      assert payload.raw_in_app_ownership_type == nil
      assert payload.transaction_reason == nil
      assert payload.raw_transaction_reason == nil
      assert payload.offer_discount_type == nil
      assert payload.raw_offer_discount_type == nil
      assert payload.environment == nil
      assert payload.raw_environment == nil
      assert payload.revocation_type == nil
      assert payload.raw_revocation_type == nil
    end

    test "full transaction payload from fixture converts all enums" do
      json = File.read!("test/resources/models/signedTransaction.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      {:ok, payload} = JWSTransactionDecodedPayload.new(map)

      assert payload.type == :auto_renewable_subscription
      assert payload.raw_type == "Auto-Renewable Subscription"
      assert payload.in_app_ownership_type == :purchased
      assert payload.raw_in_app_ownership_type == "PURCHASED"
      assert payload.transaction_reason == :purchase
      assert payload.raw_transaction_reason == "PURCHASE"
      assert payload.offer_discount_type == :pay_as_you_go
      assert payload.raw_offer_discount_type == "PAY_AS_YOU_GO"
      assert payload.environment == :local_testing
      assert payload.raw_environment == "LocalTesting"
      # Integer enums should still work
      assert payload.offer_type == :introductory_offer
      assert payload.raw_offer_type == 1
      assert payload.revocation_reason == :refunded_due_to_issue
      assert payload.raw_revocation_reason == 1
    end
  end

  # ---------------------------------------------------------------------------
  # JWSRenewalInfoDecodedPayload - environment, offer_discount_type
  # ---------------------------------------------------------------------------
  describe "JWSRenewalInfoDecodedPayload string enum conversion" do
    test "converts environment and sets raw" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{environment: "Sandbox"})
      assert payload.environment == :sandbox
      assert payload.raw_environment == "Sandbox"
    end

    test "converts offer_discount_type and sets raw" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{offer_discount_type: "PAY_UP_FRONT"})
      assert payload.offer_discount_type == :pay_up_front
      assert payload.raw_offer_discount_type == "PAY_UP_FRONT"
    end

    test "full renewal info from fixture converts all enums" do
      json = File.read!("test/resources/models/signedRenewalInfo.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(map)

      assert payload.environment == :local_testing
      assert payload.raw_environment == "LocalTesting"
      assert payload.offer_discount_type == :pay_as_you_go
      assert payload.raw_offer_discount_type == "PAY_AS_YOU_GO"
      # Integer enums should still work
      assert payload.expiration_intent == :customer_cancelled
      assert payload.raw_expiration_intent == 1
      assert payload.auto_renew_status == :on
      assert payload.raw_auto_renew_status == 1
      assert payload.price_increase_status == :customer_has_not_responded
      assert payload.raw_price_increase_status == 0
      assert payload.offer_type == :promotional_offer
      assert payload.raw_offer_type == 2
    end
  end

  # ---------------------------------------------------------------------------
  # AppTransaction - receipt_type, original_platform
  # ---------------------------------------------------------------------------
  describe "AppTransaction string enum conversion" do
    test "converts receipt_type and sets raw" do
      {:ok, payload} = AppTransaction.new(%{receipt_type: "Production"})
      assert payload.receipt_type == :production
      assert payload.raw_receipt_type == "Production"
    end

    test "converts original_platform and sets raw" do
      {:ok, payload} = AppTransaction.new(%{original_platform: "iOS"})
      assert payload.original_platform == :ios
      assert payload.raw_original_platform == "iOS"
    end

    test "handles nil receipt_type and original_platform" do
      {:ok, payload} = AppTransaction.new(%{})
      assert payload.receipt_type == nil
      assert payload.raw_receipt_type == nil
      assert payload.original_platform == nil
      assert payload.raw_original_platform == nil
    end

    test "full app transaction from fixture converts enums" do
      json = File.read!("test/resources/models/appTransaction.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      {:ok, payload} = AppTransaction.new(map)

      assert payload.receipt_type == :local_testing
      assert payload.raw_receipt_type == "LocalTesting"
      assert payload.original_platform == :ios
      assert payload.raw_original_platform == "iOS"
    end
  end

  # ---------------------------------------------------------------------------
  # AppData - environment
  # ---------------------------------------------------------------------------
  describe "AppData string enum conversion" do
    test "converts environment and sets raw" do
      {:ok, data} = AppData.new(%{environment: "Sandbox"})
      assert data.environment == :sandbox
      assert data.raw_environment == "Sandbox"
    end

    test "handles nil environment" do
      {:ok, data} = AppData.new(%{})
      assert data.environment == nil
      assert data.raw_environment == nil
    end
  end

  # ---------------------------------------------------------------------------
  # Summary - environment
  # ---------------------------------------------------------------------------
  describe "Summary string enum conversion" do
    test "converts environment and sets raw" do
      {:ok, summary} = Summary.new(%{environment: "Production"})
      assert summary.environment == :production
      assert summary.raw_environment == "Production"
    end

    test "handles nil environment" do
      {:ok, summary} = Summary.new(%{})
      assert summary.environment == nil
      assert summary.raw_environment == nil
    end
  end

  # ---------------------------------------------------------------------------
  # DecodedRealtimeRequestBody - environment
  # ---------------------------------------------------------------------------
  describe "DecodedRealtimeRequestBody string enum conversion" do
    test "converts environment and sets raw" do
      {:ok, body} = DecodedRealtimeRequestBody.new(%{environment: "LocalTesting"})
      assert body.environment == :local_testing
      assert body.raw_environment == "LocalTesting"
    end

    test "full realtime request from fixture converts enums" do
      json = File.read!("test/resources/models/decodedRealtimeRequest.json")
      map = Jason.decode!(json) |> JSON.keys_to_atoms()
      {:ok, body} = DecodedRealtimeRequestBody.new(map)

      assert body.environment == :local_testing
      assert body.raw_environment == "LocalTesting"
    end
  end
end
