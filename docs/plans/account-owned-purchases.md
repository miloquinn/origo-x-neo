# Account-owned cross-platform purchases

Status: implementation, 2026-09-27. Supersedes the split model where new reader purchases belong only to a store account.

## Product contract

- Origo 开卷 / Origo Read: permanent reader license, currently US$9.99.
- Origo 探源 / Origo Explore: includes Read plus advanced-source compatibility. Full purchase US$18.99; existing account Read owners upgrade for US$8.99 using a separate upgrade SKU.
- Paid/granted rights belong to an Origo account across supported platforms. Store apps retain native billing. Signing into Google/Apple is not proof of the corresponding store payment identity.
- Direct website builds keep free local reading; installation/sign-in does not issue a global paid reader grant.
- Any active Explore/Premium right includes reading for the validity of that right. Refunds remove only the matching purchase source; independent Read rights survive an upgrade refund. New upgrade purchases require a continuing independent permanent account Read license; if Read is refunded, the upgrade remains owned but inactive until Read is restored or repurchased. Historical Premium purchases retain their original full rights. Existing device-only reader purchases require reviewed account claiming before they qualify for account upgrades.
- TestFlight is a temporary full-feature test experience, never a Production account grant. The same binary must not remain free when distributed through App Store.
- Existing UI follows app accent and brightness. Product names are localized; functional descriptions explain what is included.

## Work sequence and boundaries

1. Add authenticated account-reader API and authoritative multi-source purchase aggregation while preserving existing anonymous grants and refusing new anonymous trials/account orders.
2. Verify store account markers against Origo UUID; atomically own each purchase once, preserve ownership on deletion, and revoke only matching refund sources. Historical unmarked purchases need reviewed migration, not unchecked auto-claim.
3. Reuse one account trial window across stores. Preserve old installation grants for compatibility without upgrading them into global account rights.
4. Update Flutter purchase/restore/trial to require login; bind responses and offline caches to the captured account/session and device. Drop stale in-flight responses after logout/account switch.
5. Revise purchase UI/copy, restore flows and duplicate-purchase guards. Never silently merge accounts by matching emails.
6. Test cross-store access, wrong-account ownership, pending/refund/sandbox boundaries, account switching/offline, legacy compatibility and migrations; preserve unrelated dirty backend work.
7. Deploy only a reviewed, tested coherent artifact; verify public health and do not claim store/device cross-platform proof from local tests.

## Verification limits

Real Google/Apple purchase, cross-device login/restore, production migration and TestFlight environment checks require separate live evidence. No marketing claim of cross-platform purchase availability until rollout is verified. Cross-platform entitlements do not imply automatic reading-data synchronization.

## Offline entitlement boundary

The SharedPreferences membership snapshot is UI history only and never grants Read or Explore. Offline authorization uses the server-issued account reader v2 attestation in secure storage, bound to the current refresh session, Origo account and installation key. `derived_from_premium` may grant Explore only while that attestation is current and no newer live membership response exists. A live non-Premium response wins immediately, and its refreshed v2 attestation replaces the older Premium-derived copy. The server currently bounds permanent account attestations to 30 days; expiry is enforced by the client timer and a later online refresh is required.

## Apple beta runtime

iOS 16+ uses verified StoreKit `AppTransaction.shared.environment == sandbox` in memory, probed on each launch. This includes TestFlight and may include App Review; it is not a TestFlight-only identity. On iOS 15 only, the compatibility path accepts Apple's `Bundle.main.appStoreReceiptURL` when its filename is `sandboxReceipt` and the receipt file already exists. Apple does not guarantee that receipt is present before the first receipt refresh, so an iOS 15 TestFlight first launch may remain locked until Apple supplies it; the app does not initiate a receipt refresh during startup. Production, Xcode, missing receipt, unknown/unverified and errors do not grant beta access. There is no persisted beta flag and no production entitlement write. Store builds now require licensing by default even if a manual build omits the define. Real iOS 15 TestFlight first launch and TestFlight -> App Store installation transitions remain device verification requirements.
