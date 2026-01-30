defmodule AppStoreServerLibrary.IntegerEnumConversionTest do
  @moduledoc """
  Tests that integer enum fields are properly converted to atoms via
  Validator.optional_integer_enum/4 in all three model structs.
  """
  use ExUnit.Case, async: true

  alias AppStoreServerLibrary.Models.JWSTransactionDecodedPayload
  alias AppStoreServerLibrary.Models.JWSRenewalInfoDecodedPayload
  alias AppStoreServerLibrary.Models.Data
  alias AppStoreServerLibrary.Verification.Validator

  # ---------------------------------------------------------------------------
  # Validator.optional_integer_enum/4 unit tests
  # ---------------------------------------------------------------------------
  describe "Validator.optional_integer_enum/4" do
    test "returns {:ok, map} when field is nil" do
      assert {:ok, %{}} = Validator.optional_integer_enum(%{}, "foo", [1, 2], SomeModule)
    end

    test "converts integer to atom via enum module (atom-keyed map)" do
      map = %{offer_type: 1, raw_offer_type: nil}

      {:ok, updated} =
        Validator.optional_integer_enum(
          map,
          "offer_type",
          [1, 2, 3, 4],
          AppStoreServerLibrary.Models.OfferType
        )

      assert updated.offer_type == :introductory_offer
      # raw_offer_type was already present (nil), so put_new does NOT overwrite
      assert updated.raw_offer_type == nil
    end

    test "sets raw_ field when not already present (atom-keyed map)" do
      map = %{offer_type: 2}

      {:ok, updated} =
        Validator.optional_integer_enum(
          map,
          "offer_type",
          [1, 2, 3, 4],
          AppStoreServerLibrary.Models.OfferType
        )

      assert updated.offer_type == :promotional_offer
      assert updated.raw_offer_type == 2
    end

    test "rejects out-of-range integer" do
      map = %{offer_type: 99}

      assert {:error, {:verification_failure, _}} =
               Validator.optional_integer_enum(
                 map,
                 "offer_type",
                 [1, 2, 3, 4],
                 AppStoreServerLibrary.Models.OfferType
               )
    end

    test "converts integer in string-keyed map" do
      map = %{"status" => 1}

      {:ok, updated} =
        Validator.optional_integer_enum(
          map,
          "status",
          [1, 2, 3, 4, 5],
          AppStoreServerLibrary.Models.Status
        )

      assert updated["status"] == :active
      assert updated["raw_status"] == 1
    end
  end

  # ---------------------------------------------------------------------------
  # JWSTransactionDecodedPayload
  # ---------------------------------------------------------------------------
  describe "JWSTransactionDecodedPayload offer_type conversion" do
    test "converts offer_type integer 1 to :introductory_offer" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{offer_type: 1})
      assert payload.offer_type == :introductory_offer
      assert payload.raw_offer_type == 1
    end

    test "converts offer_type integer 2 to :promotional_offer" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{offer_type: 2})
      assert payload.offer_type == :promotional_offer
      assert payload.raw_offer_type == 2
    end

    test "converts offer_type integer 3 to :offer_code" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{offer_type: 3})
      assert payload.offer_type == :offer_code
      assert payload.raw_offer_type == 3
    end

    test "converts offer_type integer 4 to :win_back_offer" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{offer_type: 4})
      assert payload.offer_type == :win_back_offer
      assert payload.raw_offer_type == 4
    end

    test "rejects invalid offer_type integer" do
      assert {:error, {:verification_failure, _}} =
               JWSTransactionDecodedPayload.new(%{offer_type: 99})
    end

    test "handles nil offer_type" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{})
      assert payload.offer_type == nil
      assert payload.raw_offer_type == nil
    end

    test "does not overwrite explicit raw_offer_type" do
      {:ok, payload} =
        JWSTransactionDecodedPayload.new(%{offer_type: 1, raw_offer_type: 1})

      assert payload.offer_type == :introductory_offer
      assert payload.raw_offer_type == 1
    end

    test "full transaction payload converts offer_type from fixture" do
      json = File.read!("test/resources/models/signedTransaction.json")
      map = Jason.decode!(json) |> AppStoreServerLibrary.Utility.JSON.keys_to_atoms()
      {:ok, payload} = JWSTransactionDecodedPayload.new(map)

      assert payload.offer_type == :introductory_offer
      assert payload.raw_offer_type == 1
    end
  end

  describe "JWSTransactionDecodedPayload revocation_reason conversion" do
    test "converts revocation_reason 0 to :refunded_for_other_reason" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{revocation_reason: 0})
      assert payload.revocation_reason == :refunded_for_other_reason
      assert payload.raw_revocation_reason == 0
    end

    test "converts revocation_reason 1 to :refunded_due_to_issue" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{revocation_reason: 1})
      assert payload.revocation_reason == :refunded_due_to_issue
      assert payload.raw_revocation_reason == 1
    end

    test "rejects invalid revocation_reason" do
      assert {:error, {:verification_failure, _}} =
               JWSTransactionDecodedPayload.new(%{revocation_reason: 99})
    end

    test "handles nil revocation_reason" do
      {:ok, payload} = JWSTransactionDecodedPayload.new(%{})
      assert payload.revocation_reason == nil
    end

    test "does not overwrite explicit raw_revocation_reason" do
      {:ok, payload} =
        JWSTransactionDecodedPayload.new(%{revocation_reason: 0, raw_revocation_reason: 0})

      assert payload.revocation_reason == :refunded_for_other_reason
      assert payload.raw_revocation_reason == 0
    end
  end

  # ---------------------------------------------------------------------------
  # JWSRenewalInfoDecodedPayload
  # ---------------------------------------------------------------------------
  describe "JWSRenewalInfoDecodedPayload offer_type conversion" do
    test "converts offer_type integer 1 to :introductory_offer" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{offer_type: 1})
      assert payload.offer_type == :introductory_offer
      assert payload.raw_offer_type == 1
    end

    test "converts offer_type integer 2 to :promotional_offer" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{offer_type: 2})
      assert payload.offer_type == :promotional_offer
      assert payload.raw_offer_type == 2
    end

    test "converts offer_type integer 3 to :offer_code" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{offer_type: 3})
      assert payload.offer_type == :offer_code
      assert payload.raw_offer_type == 3
    end

    test "converts offer_type integer 4 to :win_back_offer" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{offer_type: 4})
      assert payload.offer_type == :win_back_offer
      assert payload.raw_offer_type == 4
    end

    test "rejects invalid offer_type integer" do
      assert {:error, {:verification_failure, _}} =
               JWSRenewalInfoDecodedPayload.new(%{offer_type: 99})
    end

    test "handles nil offer_type" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{})
      assert payload.offer_type == nil
    end

    test "does not overwrite explicit raw_offer_type" do
      {:ok, payload} =
        JWSRenewalInfoDecodedPayload.new(%{offer_type: 2, raw_offer_type: 2})

      assert payload.offer_type == :promotional_offer
      assert payload.raw_offer_type == 2
    end

    test "full renewal info payload converts offer_type from fixture" do
      json = File.read!("test/resources/models/signedRenewalInfo.json")
      map = Jason.decode!(json) |> AppStoreServerLibrary.Utility.JSON.keys_to_atoms()
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(map)

      assert payload.offer_type == :promotional_offer
      assert payload.raw_offer_type == 2
    end
  end

  describe "JWSRenewalInfoDecodedPayload expiration_intent conversion" do
    for {int, atom} <- [
          {1, :customer_cancelled},
          {2, :billing_error},
          {3, :customer_did_not_consent_to_price_increase},
          {4, :product_not_available},
          {5, :other}
        ] do
      test "converts expiration_intent #{int} to #{inspect(atom)}" do
        {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{expiration_intent: unquote(int)})
        assert payload.expiration_intent == unquote(atom)
        assert payload.raw_expiration_intent == unquote(int)
      end
    end

    test "rejects invalid expiration_intent" do
      assert {:error, {:verification_failure, _}} =
               JWSRenewalInfoDecodedPayload.new(%{expiration_intent: 99})
    end

    test "handles nil expiration_intent" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{})
      assert payload.expiration_intent == nil
    end
  end

  describe "JWSRenewalInfoDecodedPayload auto_renew_status conversion" do
    test "converts auto_renew_status 0 to :off" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{auto_renew_status: 0})
      assert payload.auto_renew_status == :off
      assert payload.raw_auto_renew_status == 0
    end

    test "converts auto_renew_status 1 to :on" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{auto_renew_status: 1})
      assert payload.auto_renew_status == :on
      assert payload.raw_auto_renew_status == 1
    end

    test "rejects invalid auto_renew_status" do
      assert {:error, {:verification_failure, _}} =
               JWSRenewalInfoDecodedPayload.new(%{auto_renew_status: 99})
    end
  end

  describe "JWSRenewalInfoDecodedPayload price_increase_status conversion" do
    test "converts price_increase_status 0 to :customer_has_not_responded" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{price_increase_status: 0})
      assert payload.price_increase_status == :customer_has_not_responded
      assert payload.raw_price_increase_status == 0
    end

    test "converts price_increase_status 1 to :customer_consented_or_was_notified_without_needing_consent" do
      {:ok, payload} = JWSRenewalInfoDecodedPayload.new(%{price_increase_status: 1})
      assert payload.price_increase_status == :customer_consented_or_was_notified_without_needing_consent
      assert payload.raw_price_increase_status == 1
    end

    test "rejects invalid price_increase_status" do
      assert {:error, {:verification_failure, _}} =
               JWSRenewalInfoDecodedPayload.new(%{price_increase_status: 99})
    end
  end

  # ---------------------------------------------------------------------------
  # Data
  # ---------------------------------------------------------------------------
  describe "Data status conversion" do
    for {int, atom} <- [
          {1, :active},
          {2, :expired},
          {3, :billing_retry},
          {4, :billing_grace_period},
          {5, :revoked}
        ] do
      test "converts status #{int} to #{inspect(atom)}" do
        {:ok, data} = Data.new(%{status: unquote(int)})
        assert data.status == unquote(atom)
        assert data.raw_status == unquote(int)
      end
    end

    test "rejects invalid status" do
      assert {:error, {:verification_failure, _}} = Data.new(%{status: 99})
    end

    test "handles nil status" do
      {:ok, data} = Data.new(%{})
      assert data.status == nil
    end

    test "does not overwrite explicit raw_status" do
      {:ok, data} = Data.new(%{status: 1, raw_status: 1})
      assert data.status == :active
      assert data.raw_status == 1
    end
  end
end
