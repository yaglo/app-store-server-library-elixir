# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- API client: identifiers interpolated into request paths (transaction IDs, order IDs, product IDs, message and image identifiers, locales, tokens) are now percent-encoded. Previously a value containing `/`, `..`, `?` or `#` could redirect the signed request to a different App Store Server API endpoint.
- The verified-certificate cache is now keyed on the verifier's trusted roots as well as the certificate chain. Previously a chain accepted by one verifier was served from the cache to any other verifier in the same VM, even one configured with different root certificates.
- Online OCSP checks now fail closed. A certificate with no OCSP responder URL, or whose extensions cannot be read, is rejected with `:verification_failure` instead of being treated as not revoked.
- An OCSP requester can no longer disable response validation by returning `{:ok, :skip_validation}`; every response is validated. OCSP requests no longer follow redirects or let the HTTP client decompress or decode the response body.
- Signature verification now uses `JOSE.JWS.verify_strict/3` pinned to ES256.
- Certificate chain verification now checks `keyUsage` (certificate signing on the intermediate, digital signature on the leaf) and rejects certificates carrying an unrecognized critical extension.
- Signing keys are no longer printed when an `AppStoreServerAPIClient`, `JWSSignatureCreator` or `PromotionalOfferSignatureCreator` struct is inspected.
- Raised the minimum `jose` to 1.11.13 and `req` to 0.6.1 to pick up fixes for published advisories (including unvalidated ECDSA signature length in `jose` and a decompression-bomb denial of service in `req`).

### Fixed
- Malformed signed data now returns `{:error, {status, message}}` instead of raising. A header or payload that is valid JSON but not an object raised `BadMapError`, non-string `x5c` entries raised `FunctionClauseError`, and an undecodable header returned a bare `Jason.DecodeError`.

### Changed
- Test suites that returned `{:ok, :skip_validation}` from a custom `:ocsp_requester` should configure the new `:ocsp_checker` setting instead; see the README.
- `req` 0.5.x is no longer supported.

## [2.2.1] - 2026-11-10

### Security
- Online OCSP revocation checks (`enable_online_checks: true`) were silently skipped. `ChainVerifier` read the certificate's `subjectUniqueID` field instead of its extensions when looking for the OCSP responder URL; the resulting error was treated as "no OCSP URL", so `check_ocsp_status/3` returned `:ok` without contacting the responder. A revoked signing certificate would therefore have been accepted. Upgrading is recommended for anyone relying on online checks. Thanks to Evgeny Famiev (@efamiev) for the report and fix ([#2](https://github.com/yaglo/app-store-server-library-elixir/pull/2)).

### Fixed
- `ChainVerifier.build_ocsp_request/2` computed the OCSP `issuerNameHash` from the issuer certificate's issuer name instead of its subject, producing a CertID that did not identify the certificate. This was masked by the URL extraction bug above ([#2](https://github.com/yaglo/app-store-server-library-elixir/pull/2)).
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
