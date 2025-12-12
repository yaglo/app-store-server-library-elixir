# App Store Server Library for Elixir

[![Hex.pm](https://img.shields.io/hexpm/v/app_store_server_library.svg)](https://hex.pm/packages/app_store_server_library)
[![Hexdocs.pm](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/app_store_server_library)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An Elixir client library for the [Apple App Store Server API](https://developer.apple.com/documentation/appstoreserverapi), [App Store Server Notifications](https://developer.apple.com/documentation/appstoreservernotifications), and [Retention Messaging API](https://developer.apple.com/documentation/retentionmessaging).

This library tracks Apple's official server implementation for Python to provide the same surface area and behaviors in Elixir.

## Features

- **App Store Server API Client** - Complete REST API client with JWT authentication for all endpoints
- **Signed Data Verification** - JWS signature verification with X.509 certificate chain validation
- **Signature Creation** - Generate promotional offer signatures (V1 and V2), introductory offer eligibility, and Advanced Commerce API signatures
- **Receipt Parsing** - Extract transaction IDs from app receipts and transaction receipts
- **Retention Messaging** - Full support for image and message management
- **OCSP Verification** - Online certificate status checking with caching
- **Public Key Caching** - 15-minute TTL cache for verified certificate public keys
- **Multiple Environments** - API client supports Production, Sandbox, and Local Testing; signature verification also supports Xcode (verification is skipped in Xcode/Local Testing)
- **Retryable Errors** - Distinguishes between permanent and retryable API/verification errors
- **Strict Validation** - Enum domains, integer ranges, string lists, and environment values are validated to match Apple's schemas

## Requirements

- Elixir ~> 1.18
- Erlang/OTP 26+

## Installation

Add `app_store_server_library` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:app_store_server_library, "~> 1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

You'll need the following from [App Store Connect](https://appstoreconnect.apple.com/).

1. **Private Key** (.p8 file) - Download from App Store Connect > Users and Access > Integrations > In-App Purchase. See [Creating API keys to authorize API requests](https://developer.apple.com/documentation/appstoreserverapi/creating-api-keys-to-authorize-api-requests) for instructions.
2. **Key ID** - The identifier for your private key
3. **Issuer ID** - Your issuer ID from App Store Connect for In-App Purchases
4. **Bundle ID** - Your app's bundle identifier
5. **App Apple ID** - Your app's Apple ID (required for production environment).

## Application & Caching

The OTP application starts automatically and runs the built-in caches:
- Certificate cache: 32 entries with a 15-minute TTL for verified public keys (used when `enable_online_checks` is true)
- Token cache: 4-minute TTL for API JWTs (JWTs expire after 5 minutes)

You normally do not need to configure anything, but you can override the defaults in `config.exs`:

```elixir
config :app_store_server_library,
  certificate_cache_max_size: 32,
  certificate_cache_ttl_seconds: 900,
  token_cache_ttl_seconds: 240
```

## Quick Start

### API Client

```elixir
alias AppStoreServerLibrary.API.AppStoreServerAPIClient
alias AppStoreServerLibrary.Models.TransactionHistoryRequest

# Read your private key
signing_key = File.read!("path/to/AuthKey_XXXXXXXXXX.p8")

# Create the client with keyword options
client = AppStoreServerAPIClient.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.yourapp",
  environment: :sandbox  # or :production / :local_testing
)

# Get transaction history
{:ok, response} = AppStoreServerAPIClient.get_transaction_history(
  client,
  "original_transaction_id",
  nil,  # revision (nil for first page)
  %TransactionHistoryRequest{}
)

# Get transaction info
{:ok, transaction} = AppStoreServerAPIClient.get_transaction_info(
  client,
  "transaction_id"
)
```

### Verifying Signed Data

```elixir
alias AppStoreServerLibrary.Verification.SignedDataVerifier

# Load Apple root certificates (DER format)
root_cert = File.read!("AppleRootCA-G3.cer")

# Create verifier with keyword options
verifier = SignedDataVerifier.new(
  root_certificates: [root_cert],
  enable_online_checks: true,  # OCSP verification
  environment: :sandbox,
  bundle_id: "com.example.yourapp"
  # app_apple_id: 123456789  # required for :production
)

# Verify a signed transaction
case SignedDataVerifier.verify_and_decode_signed_transaction(verifier, signed_transaction) do
  {:ok, transaction} ->
    IO.inspect(transaction.transaction_id)

  {:error, {:retryable_verification_failure, message}} ->
    # Network error during OCSP check - safe to retry
    IO.puts("Retryable error: #{message}")

  {:error, {status, message}} ->
    IO.puts("Verification failed: #{status} - #{message}")
end

# Verify an App Store Server Notification
case SignedDataVerifier.verify_and_decode_notification(verifier, notification_payload) do
  {:ok, notification} ->
    IO.inspect(notification.notification_type)

  {:error, {status, message}} ->
    IO.puts("Verification failed: #{status} - #{message}")
end
```

### Creating Promotional Offer Signatures

#### V2 Format (Recommended)

```elixir
alias AppStoreServerLibrary.Signature.PromotionalOfferV2SignatureCreator

signing_key = File.read!("path/to/AuthKey.p8")

creator = PromotionalOfferV2SignatureCreator.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.yourapp"
)

{:ok, signature} = PromotionalOfferV2SignatureCreator.create_signature(
  creator,
  "product_id",
  "offer_identifier",
  "original_transaction_id"  # optional
)
```

#### V1 Format (Legacy)

```elixir
alias AppStoreServerLibrary.Signature.PromotionalOfferSignatureCreator

creator = PromotionalOfferSignatureCreator.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  bundle_id: "com.example.yourapp"
)

{:ok, signature} = PromotionalOfferSignatureCreator.create_signature(
  creator,
  "product_id",
  "offer_id",
  "app_account_token",  # optional
  UUID.uuid4(),
  System.system_time(:millisecond)
)
```

### Creating Introductory Offer Eligibility Signatures

```elixir
alias AppStoreServerLibrary.Signature.IntroductoryOfferEligibilitySignatureCreator

creator = IntroductoryOfferEligibilitySignatureCreator.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.yourapp"
)

{:ok, signature} = IntroductoryOfferEligibilitySignatureCreator.create_signature(
  creator,
  "product_id",
  true,  # allow_introductory_offer
  "transaction_id"
)
```

### Creating Advanced Commerce API Signatures

```elixir
alias AppStoreServerLibrary.Signature.AdvancedCommerceAPIInAppSignatureCreator

creator = AdvancedCommerceAPIInAppSignatureCreator.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.yourapp"
)

request = %{
  "productId" => "com.example.product",
  "period" => "P1M",
  "price" => 999
}

{:ok, signature} = AdvancedCommerceAPIInAppSignatureCreator.create_signature(creator, request)
```

### Extracting Transaction IDs from Receipts

```elixir
alias AppStoreServerLibrary.Utility.ReceiptUtility

# From an app receipt
{:ok, transaction_id} = ReceiptUtility.extract_transaction_id_from_app_receipt(app_receipt_base64)

# From a transaction receipt
{:ok, transaction_id} = ReceiptUtility.extract_transaction_id_from_transaction_receipt(transaction_receipt_base64)
```

## Convenience Aliases

For cleaner imports, you can use the top-level convenience modules:

```elixir
# Instead of AppStoreServerLibrary.API.AppStoreServerAPIClient
alias AppStoreServerLibrary.Client

client = Client.new(
  signing_key: signing_key,
  key_id: "YOUR_KEY_ID",
  issuer_id: "YOUR_ISSUER_ID",
  bundle_id: "com.example.yourapp",
  environment: :sandbox
)

{:ok, transaction} = Client.get_transaction_info(client, "transaction_id")

# Instead of AppStoreServerLibrary.Verification.SignedDataVerifier
alias AppStoreServerLibrary.Verifier

verifier = Verifier.new(
  root_certificates: [root_cert],
  environment: :sandbox,
  bundle_id: "com.example.yourapp"
)

{:ok, transaction} = Verifier.verify_and_decode_signed_transaction(verifier, signed_data)
```

## API Reference

### AppStoreServerAPIClient

The main client for interacting with the App Store Server API.

#### Creating a Client

```elixir
AppStoreServerAPIClient.new(
  signing_key: String.t(),      # Private key content (PEM format)
  key_id: String.t(),           # Key ID from App Store Connect
  issuer_id: String.t(),        # Issuer ID from App Store Connect
  bundle_id: String.t(),        # Your app's bundle identifier
  environment: atom()           # :sandbox, :production, or :local_testing
)
```

#### Subscription Management

```elixir
# Extend subscription renewal date for a single subscription
extend_subscription_renewal_date(client, original_transaction_id, request)

# Extend renewal date for all active subscribers of a product
extend_renewal_date_for_all_active_subscribers(client, request)

# Check status of mass extension request
get_status_of_subscription_renewal_date_extensions(client, request_identifier, product_id)

# Get subscription statuses
get_all_subscription_statuses(client, transaction_id, status \\ nil)
```

#### Transaction & Purchase Info

```elixir
# Get transaction info
get_transaction_info(client, transaction_id)

# Get transaction history (uses the v2 endpoint)
get_transaction_history(client, transaction_id, revision \\ nil, request)

# Get app transaction info
get_app_transaction_info(client, transaction_id)

# Look up order
look_up_order_id(client, order_id)

# Get refund history
get_refund_history(client, transaction_id, revision \\ nil)
```

#### Notifications

```elixir
# Request a test notification
request_test_notification(client)

# Get test notification status
get_test_notification_status(client, test_notification_token)

# Get notification history
get_notification_history(client, pagination_token \\ nil, request)
```

#### Consumption & Account

```elixir
# Send consumption data
send_consumption_data(client, transaction_id, request)

# Set app account token
set_app_account_token(client, original_transaction_id, request)
```

#### Retention Messaging

```elixir
# Images
upload_image(client, image_identifier, image_binary)
delete_image(client, image_identifier)
get_image_list(client)

# Messages
upload_message(client, message_identifier, request)
delete_message(client, message_identifier)
get_message_list(client)

# Default configuration
configure_default_message(client, product_id, locale, request)
delete_default_message(client, product_id, locale)
```

### SignedDataVerifier

Verify and decode App Store signed data.

#### Creating a Verifier

```elixir
SignedDataVerifier.new(
  root_certificates: [binary()],    # Apple root certificates (DER format)
  environment: atom(),              # :sandbox, :production, :xcode, or :local_testing
  bundle_id: String.t(),            # Your app's bundle identifier
  enable_online_checks: boolean(),  # Optional, default false
  app_apple_id: integer() | nil     # Required for :production
)
```

#### Verification Functions

```elixir
verify_and_decode_signed_transaction(verifier, signed_transaction)
verify_and_decode_renewal_info(verifier, signed_renewal_info)
verify_and_decode_notification(verifier, signed_payload)
verify_and_decode_app_transaction(verifier, signed_app_transaction)
verify_and_decode_realtime_request(verifier, signed_payload)
verify_and_decode_summary(verifier, signed_payload)
```

#### Verification Status Types

```elixir
:ok                              # Success
:verification_failure            # Signature or certificate verification failed
:invalid_app_identifier          # Bundle ID or App Apple ID mismatch
:invalid_certificate             # Certificate parsing failed
:invalid_chain_length            # Certificate chain not 3 certificates
:invalid_chain                   # Certificate chain validation failed
:invalid_environment             # Environment mismatch
:retryable_verification_failure  # Network error during OCSP (safe to retry)
```

### Error Handling

The library returns `{:error, %APIException{}}` on API failures. `APIException` is a proper Elixir exception that can be pattern matched or raised:

```elixir
alias AppStoreServerLibrary.API.{APIError, APIException}

case AppStoreServerAPIClient.get_transaction_info(client, "invalid_id") do
  {:ok, transaction} ->
    # Handle success
    IO.inspect(transaction)

  {:error, %APIException{api_error: :rate_limit_exceeded}} ->
    # Handle specific error
    Process.sleep(1000)
    retry()

  {:error, %APIException{} = exception} ->
    # Check if retryable
    if APIException.retryable?(exception) do
      retry()
    else
      # Permanent error - get description and documentation link
      IO.puts(APIException.message(exception))
      IO.puts(APIException.doc_url(exception))
    end
end
```

#### Bang Functions

For convenience, bang functions are available that raise on error:

```elixir
# These raise APIException on error
transaction = AppStoreServerAPIClient.get_transaction_info!(client, "txn_id")
history = AppStoreServerAPIClient.get_transaction_history!(client, "txn_id", nil, request)
statuses = AppStoreServerAPIClient.get_all_subscription_statuses!(client, "txn_id")
```

#### APIException Fields

```elixir
%APIException{
  http_status_code: 404,           # HTTP status code
  raw_api_error: 4040010,          # Raw error code from Apple
  api_error: :transaction_id_not_found,  # Parsed atom (or nil if unknown)
  error_message: "Transaction id not found."  # Error message from Apple
}
```

#### APIError Functions

`APIError` is a catalog of error codes with helper functions:

```elixir
# Get error description
APIError.description(4000006)
# => "An error that indicates an invalid transaction identifier."

# Get Apple documentation URL
APIError.doc_url(4000006)
# => "https://developer.apple.com/documentation/appstoreserverapi/invalidtransactioniderror"

# Check if retryable
APIError.retryable?(4040002)
# => true

# Convert to atom
APIError.to_atom(4000006)
# => :invalid_transaction_id
```

#### Retryable Error Codes

The following API errors are safe to retry:
- `account_not_found_retryable` (4040002)
- `app_not_found_retryable` (4040004)
- `original_transaction_id_not_found_retryable` (4040006)
- `general_internal_retryable` (5000001)

## Environments

| Environment | Description |
|-------------|-------------|
| `:production` | Production App Store environment |
| `:sandbox` | Sandbox testing environment |
| `:xcode` | Local Xcode testing (signatures not verified) |
| `:local_testing` | Local testing (signatures not verified) |

- The REST client (`AppStoreServerAPIClient`) accepts `:production`, `:sandbox`, and `:local_testing`. Passing `:xcode` will raise because the App Store Server API does not support that environment.
- `SignedDataVerifier` skips signature verification for `:xcode` and `:local_testing` payloads to mirror Apple's tooling behavior.

## Performance Features

### Public Key Caching

When online checks are enabled, verified certificate public keys are cached for 15 minutes to avoid repeated OCSP verification. The cache:
- Maximum size: 32 entries
- TTL: 15 minutes
- Automatically cleans expired entries when full

### Retryable Verification Failures

Network errors during OCSP verification return `:retryable_verification_failure` instead of permanent failure, allowing your application to implement retry logic.

## Telemetry

The library emits [telemetry](https://hex.pm/packages/telemetry) events for observability. You can attach handlers to monitor performance, track errors, and integrate with your existing observability stack.

### Events

#### API Events

| Event | Description |
|-------|-------------|
| `[:app_store_server_library, :api, :request, :start]` | API request started |
| `[:app_store_server_library, :api, :request, :stop]` | API request completed |
| `[:app_store_server_library, :api, :request, :exception]` | API request raised an exception |

**Measurements:**
- `:start` - `%{system_time: integer}` (monotonic time)
- `:stop` / `:exception` - `%{duration: integer}` (native time units)

**Metadata:** `%{method: atom, path: String.t}`

#### JWT Events

| Event | Description |
|-------|-------------|
| `[:app_store_server_library, :jwt, :generate, :start]` | JWT generation started |
| `[:app_store_server_library, :jwt, :generate, :stop]` | JWT generation completed |
| `[:app_store_server_library, :jwt, :generate, :exception]` | JWT generation raised an exception |

**Measurements:** Same as API events

**Metadata:** `%{}`

#### Verification Events

| Event | Description |
|-------|-------------|
| `[:app_store_server_library, :verification, :chain, :start]` | Certificate chain verification started |
| `[:app_store_server_library, :verification, :chain, :stop]` | Certificate chain verification completed |
| `[:app_store_server_library, :verification, :chain, :exception]` | Certificate chain verification raised an exception |
| `[:app_store_server_library, :verification, :signature, :start]` | Signature verification started |
| `[:app_store_server_library, :verification, :signature, :stop]` | Signature verification completed |
| `[:app_store_server_library, :verification, :signature, :exception]` | Signature verification raised an exception |

**Chain verification metadata:** `%{cert_count: integer, online_checks: boolean}`

**Signature verification metadata:** `%{type: atom}` where type is one of `:notification`, `:renewal_info`, `:transaction`, `:app_transaction`, `:realtime_request`, or `:summary`

### Example Handler

```elixir
defmodule MyApp.TelemetryHandler do
  require Logger

  def attach do
    events = [
      [:app_store_server_library, :api, :request, :stop],
      [:app_store_server_library, :api, :request, :exception],
      [:app_store_server_library, :verification, :signature, :stop]
    ]

    :telemetry.attach_many(
      "my-app-store-handler",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:app_store_server_library, :api, :request, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.info("App Store API #{metadata.method} #{metadata.path} completed in #{duration_ms}ms")
  end

  def handle_event([:app_store_server_library, :api, :request, :exception], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.error("App Store API #{metadata.method} #{metadata.path} failed after #{duration_ms}ms: #{inspect(metadata.reason)}")
  end

  def handle_event([:app_store_server_library, :verification, :signature, :stop], measurements, metadata, _config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    Logger.debug("Signature verification (#{metadata.type}) completed in #{duration_ms}ms")
  end
end
```

Add to your application startup:

```elixir
# In your application.ex
def start(_type, _args) do
  MyApp.TelemetryHandler.attach()
  # ...
end
```

## Models

The library includes comprehensive data models for all App Store Server API types:

- **Requests**: `TransactionHistoryRequest`, `NotificationHistoryRequest`, `ConsumptionRequest`, etc.
- **Responses**: `HistoryResponse`, `TransactionInfoResponse`, `StatusResponse`, etc.
- **Decoded Payloads**: `JWSTransactionDecodedPayload`, `JWSRenewalInfoDecodedPayload`, `ResponseBodyV2DecodedPayload`, etc.
- **Enums**: `Environment`, `NotificationTypeV2`, `Status`, `OfferType`, etc.

## Security Considerations

1. **Private Key Storage**: Store your private key securely and never commit it to version control
2. **Certificate Verification**: Always enable online checks (OCSP) in production
3. **Environment Validation**: The library validates environment, bundle ID, and app Apple ID to prevent cross-environment attacks

## Testing

```bash
mix test
```

## Documentation

Generate documentation locally:

```bash
mix docs
open doc/index.html
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Related Resources

- [Apple App Store Server API Documentation](https://developer.apple.com/documentation/appstoreserverapi)
- [App Store Server Notifications Documentation](https://developer.apple.com/documentation/appstoreservernotifications)
- [Retention Messaging API Documentation](https://developer.apple.com/documentation/retentionmessaging)
- [Apple's Swift Reference Implementation](https://github.com/apple/app-store-server-library-swift)
