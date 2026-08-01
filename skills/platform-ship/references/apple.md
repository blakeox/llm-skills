# Apple release checks

Use for iOS, macOS, TestFlight, App Store, signing, entitlement, privacy, purchase, or background-behavior changes.

## Verify

- Exact archive/build identity, signing certificate, provisioning profile, bundle ID, version, and target channel
- Entitlements and permission declarations match runtime behavior
- Privacy manifest, usage descriptions, tracking, account deletion, subscription, and payment behavior satisfy current applicable requirements
- Startup, upgrade, permission denial, offline, interrupted, and existing-user paths
- Server-side kill switches and phased release controls

## Recovery reality

App rollback is slower than server rollback. Separate server-disableable behavior from code that requires a new review and release. Treat missing signing, review, upgrade, or crash evidence as `INDETERMINATE`.
