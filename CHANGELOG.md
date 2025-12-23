# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
