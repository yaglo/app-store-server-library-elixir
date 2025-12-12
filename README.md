# App Store Server Library for Elixir

[![Hex.pm](https://img.shields.io/hexpm/v/app_store_server_library.svg)](https://hex.pm/packages/app_store_server_library)
[![Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/app_store_server_library)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Elixir client for Apple's [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi), [Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications), and [Retention Messaging](https://developer.apple.com/documentation/retentionmessaging).

Tracks Apple's official Python implementation—same surface area, idiomatic Elixir.

## Installation
```elixir
def deps do
  [{:app_store_server_library, "~> 1.0"}]
end
```

## Setup

From [App Store Connect](https://appstoreconnect.apple.com/) → Users and Access → Integrations → In-App Purchase:

- Private key (.p8 file)
- Key ID
- Issuer ID
- Bundle ID
- App Apple ID (the numeric one, production only)

See [Creating API keys to authorize API requests](https://developer.apple.com/documentation/appstoreserverapi/creating-api-keys-to-authorize-api-requests) for thorough instructions.

## Making API Calls
```elixir
alias AppStoreServerLibrary.Client

client = Client.new(
  signing_key: File.read!("AuthKey_XXXXXXXXXX.p8"),
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.app",
  environment: :sandbox  # or :production
)

# Transaction history
{:ok, response} = Client.get_transaction_history(client, "original_txn_id", nil, %TransactionHistoryRequest{})

# Subscription status
{:ok, statuses} = Client.get_all_subscription_statuses(client, "txn_id")

# Refund history
{:ok, refunds} = Client.get_refund_history(client, "txn_id")

# Send consumption data
Client.send_consumption_data(client, "txn_id", %ConsumptionRequest{
  customerConsented: true,
  consumptionStatus: :undeclared
})
```

Bang variants raise on error: `Client.get_transaction_info!(client, "txn_id")`

## Verifying Signed Data

Verify transactions and notifications from Apple. You'll need Apple's root certificates in DER format.
```elixir
alias AppStoreServerLibrary.Verifier

verifier = Verifier.new(
  root_certificates: [File.read!("AppleRootCA-G3.cer")],
  enable_online_checks: true,  # OCSP verification
  environment: :sandbox,
  bundle_id: "com.example.app"
  # app_apple_id: 123456789  # required for :production
)

# Verify a signed transaction
case Verifier.verify_and_decode_signed_transaction(verifier, signed_transaction) do
  {:ok, transaction} ->
    transaction.transaction_id

  {:error, {:retryable_verification_failure, _}} ->
    # OCSP network hiccup - retry

  {:error, {status, message}} ->
    Logger.error("Verification failed: #{status}")
end

# Verify App Store Server Notification (v2)
{:ok, notification} = Verifier.verify_and_decode_notification(verifier, payload)
notification.notification_type  # e.g. :subscribed, :did_renew, :refund
```

## Handling Webhooks

Typical notification endpoint:
```elixir
def handle_notification(conn, %{"signedPayload" => signed_payload}) do
  case Verifier.verify_and_decode_notification(verifier(), signed_payload) do
    {:ok, notification} ->
      process_notification(notification)
      send_resp(conn, 200, "")

    {:error, _} ->
      send_resp(conn, 400, "")
  end
end

defp process_notification(%{notification_type: :did_renew} = n) do
  # Handle renewal
end

defp process_notification(%{notification_type: :refund} = n) do
  # Handle refund
end
```

## Creating Promotional Offer Signatures

For StoreKit 2 promotional offers:
```elixir
alias AppStoreServerLibrary.Signature.PromotionalOfferV2SignatureCreator

creator = PromotionalOfferV2SignatureCreator.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.app"
)

{:ok, signature} = PromotionalOfferV2SignatureCreator.create_signature(
  creator,
  "product_id",
  "offer_id",
  "original_transaction_id"  # optional
)
```

Legacy V1 signatures and introductory offer eligibility signatures also supported—see the docs.

## Extracting Transaction IDs from Receipts

For migrating from `verifyReceipt` to App Store Server API:
```elixir
alias AppStoreServerLibrary.Utility.ReceiptUtility

{:ok, txn_id} = ReceiptUtility.extract_transaction_id_from_app_receipt(receipt_base64)
```

## Error Handling
```elixir
alias AppStoreServerLibrary.API.APIException

case Client.get_transaction_info(client, "bad_id") do
  {:ok, txn} ->
    txn

  {:error, %APIException{api_error: :transaction_id_not_found}} ->
    nil

  {:error, %APIException{} = e} ->
    if APIException.retryable?(e) do
      # Safe to retry: rate limits, transient failures
      retry()
    else
      raise e
    end
end
```

## Environments

| Environment | Notes |
|-------------|-------|
| `:production` | Requires `app_apple_id` |
| `:sandbox` | Testing |
| `:xcode` / `:local_testing` | Signature verification skipped |

## Batteries Included

- **Caching** - JWT tokens and verified certificate public keys are cached automatically. Sensible defaults, configurable if needed.
- **Telemetry** - Events emitted for API requests, JWT generation, and signature verification. Wire up your existing handlers.

Details in the [docs](https://hexdocs.pm/app_store_server_library).

## Documentation

Full API reference, all models, telemetry events, caching configuration: [hexdocs.pm/app_store_server_library](https://hexdocs.pm/app_store_server_library)
