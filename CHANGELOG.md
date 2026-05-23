# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- `ChainVerifier.build_ocsp_request/2` no longer crashes on OTP 28. The previous implementation called `apply(:"OTP-PUB-KEY", :encode, [:OCSPRequest, ocsp_request])`, but OTP 28 split the public-key ASN.1 modules and removed `:"OTP-PUB-KEY"`. The encoder now goes through `:public_key.der_encode(:OCSPRequest, ocsp_request)`, which dispatches correctly on OTP 27 and OTP 28. Only the online OCSP path (`perform_online_checks: true`) was affected; chains verified without online checks were unaffected.
- Corrected the rationale comment on `verify_certificate_chain/3`: the manual chain walker exists because `:public_key.pkix_path_validation/3` validates against wall-clock time and has no option to supply a custom timestamp. In offline mode (`enable_online_checks: false`), `SignedDataVerifier.get_effective_date/2` uses the payload's `signedDate` so historical receipts can still be processed after their signing certs expire — that path needs a custom timestamp. The previous comment incorrectly attributed the workaround to `:invalid_key_usage` reports on leaf certificates.

## [2.2.0] - 2026-02-01

### Fixed
- String enum fields (`notification_type`, `subtype`, `environment`, `type`, `in_app_ownership_type`, `transaction_reason`, `offer_discount_type`, `revocation_type`, `consumption_request_reason`, `receipt_type`, `original_platform`) in JWS-decoded payloads are now converted from raw strings to atoms via their enum modules. Previously these fields remained as raw strings (e.g., `"TEST"` instead of `:test`) despite their type specs declaring atom types.
- `raw_` fields for string enums (`raw_notification_type`, `raw_subtype`, `raw_environment`, etc.) are now populated with the original string value in JWS-decoded payloads. Previously these were always `nil`.
- `keys_to_atoms/1` no longer performs value conversion for `environment` and `receipt_type` fields. Value conversion is now handled consistently by model `new/1` functions via `Validator.optional_string_enum/4`.

### Added
- `Validator.optional_string_enum/4` for validating and converting string enum fields in a single step, mirroring the existing `optional_integer_enum/4` for integer enums.

## [2.1.1] - 2026-01-30

### Fixed
- Integer enum fields (`offer_type`, `revocation_reason`, `expiration_intent`, `auto_renew_status`, `price_increase_status`, `status`) are now converted from raw integers to atoms via their enum modules. Previously these fields remained as raw integers despite their type specs declaring atom types.

### Added
- `Validator.optional_integer_enum/4` for validating and converting integer enum fields in a single step.

## [2.1.0] - 2026-01-09

### Fixed
- Nested structs in API responses now correctly deserialize with snake_case keys. Previously, only top-level fields were converted from camelCase, leaving nested objects like `StatusResponse.data`, `SubscriptionGroupIdentifierItem.last_transactions`, and `NotificationHistoryResponseItem.send_attempts` with unconverted camelCase string keys.
- `LastTransactionsItem.status` now correctly converts to `Status.t()` atoms (`:active`, `:expired`, etc.) instead of incorrectly using `OrderLookupStatus`.
- Fixed compile-time warning for `:"OTP-PUB-KEY".encode/2` in chain verifier.

### Added
- `__nested_fields__/0` callback on response structs for declaring nested type information, enabling automatic recursive deserialization.

## [2.0.0] - 2025-12-23

### Added
- Full support for App Store Server API 1.19 and App Store Server Notifications 2.0.
- New notification types: `metadata_update`, `migration`, `price_change`, `rescind_consent`.
- Advanced Commerce models for subscription management.
- `AppData` model for `RESCIND_CONSENT` notifications.
- Configurable JWT expiration via `jwt_expiration` option in `AppStoreServerAPIClient.new/1`.
- PNG validation for `upload_image/3`.
- OCSP requester hook (`config :app_store_server_library, :ocsp_requester`).

### Changed
- **Breaking:** `AppStoreServerAPIClient.new/1` and `SignedDataVerifier.new/1` now return `{:ok, client | verifier} | {:error, reason}` tuples instead of raising.
- **Breaking:** `send_consumption_data/3` renamed to `send_consumption_information/3` (uses V2 API).
- **Breaking:** `ConsumptionRequest` simplified—now requires `customer_consented`, `delivery_status`, `sample_content_provided`.
- **Breaking:** `Subtype` renamed to `SubtypeV2`.
- Enums use new `defenum` macro with forward compatibility for unknown values.

### Removed
- Deprecated consumption models: `AccountTenure`, `ConsumptionStatus`, `LifetimeDollarsPurchased`, `LifetimeDollarsRefunded`, `Platform`, `PlayTime`, `UserStatus`.

## [1.0.0] - 2025-12-12

Initial release.
