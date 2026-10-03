# Account-owned cross-platform purchases

Status: implementation, updated 2026-10-03. Supersedes the split model where new reader purchases belong only to a store account.

Launch policy (2026-10-03): basic Read capabilities are currently free in every
distribution, without login, purchase, or trial. Store Read purchases remain
optional and create real account ownership. Free reading never grants a paid
Read identity or Explore upgrade eligibility. Explore advanced-source
compatibility continues to require verified access. Trial entry points are
hidden while reader licensing is disabled; existing trial history is retained.

## Product contract

- Origo 开卷 / Origo Read: permanent reader license, currently US$9.99.
- Origo 探元 / Origo Explore: includes Read plus advanced-source compatibility. Full purchase US$18.99; existing account Read owners upgrade for US$8.99 using a separate upgrade SKU.
- Paid/granted rights belong to an Origo account across supported platforms. Store apps retain native billing. Signing into Google/Apple is not proof of the corresponding store payment identity.
- Direct website builds keep free local reading; installation/sign-in does not issue a global paid reader grant.
- Any active Explore/Premium right includes reading for the validity of that right. Refunds remove only the matching purchase source; independent Read rights survive an upgrade refund. New upgrade purchases require a continuing independent permanent account Read license; if Read is refunded, the upgrade remains owned but inactive until Read is restored or repurchased. Historical Premium purchases retain their original full rights. Existing device-only reader purchases require reviewed account claiming before they qualify for account upgrades.
- TestFlight provides free basic reading, never a Production account grant. Explore requires an existing verified account right; test purchases remain visible and verifiable but do not unlock capabilities, trial, account ownership, or upgrade eligibility. The sandbox signal must never grant Production Explore or paid Read ownership. Basic reading is independently free under the current launch policy.
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

iOS 16+ uses verified StoreKit `AppTransaction.shared.environment == sandbox` in memory, probed on each launch. This includes TestFlight and may include App Review; it is not a TestFlight-only identity and does not grant Explore by itself. On iOS 15 only, the compatibility path accepts Apple's `Bundle.main.appStoreReceiptURL` when its filename is `sandboxReceipt` and the receipt file already exists. Apple does not guarantee that receipt is present before the first receipt refresh, so an iOS 15 TestFlight first launch may lack the sandbox environment signal until Apple supplies it; the app does not initiate a receipt refresh during startup. Production, Xcode, missing receipt, unknown/unverified and errors do not grant beta access. There is no persisted beta flag and no production entitlement write. Store builds now default to free basic reading; release scripts explicitly set `ORIGO_STORE_READER_LICENSE_REQUIRED=false`. Enabling the reader gate later requires an explicit, separately reviewed rollout. Real iOS 15 TestFlight first launch and TestFlight -> App Store installation transitions remain device verification requirements.

## Origo code redemption (2026-09-27)

The user explicitly selected self-generated **Origo account codes**, not Apple
or Google promotional codes. Store Explore pages expose “I have a code” after
sign-in, including the Apple test environment. The entry opens a compact
secondary page showing the receiving account. It has no external purchase link,
shop branding or review-specific visibility switch. Existing native purchase
and restore actions remain available independently.

Redemption reuses `POST /api/v1/membership/redeem`, with `expected_user_id` pinned
to the signed-in account. The backend remains authoritative for code validity,
duration and usage; returned membership updates the shared Read/Explore model.
Blank and duplicate submissions are blocked. Account changes clear the input;
failed redemption preserves the code for retry. A failed supplementary referral
refresh cannot turn an already accepted redemption into a failure.

This product decision does not establish store-policy approval. Apple 3.1.1
restricts custom unlocking mechanisms and Google payment rules may apply to
external paid codes. The entry must be described honestly in review notes; do
not hide it during review or replace Origo codes with official store codes.
No backend schema, new dependency or duplicated payment service is introduced.

## Profile card and naming (2026-09-27)

User-facing legacy Premium labels are now Explore / 探元 across the supported
locales. Backend fields and historical entitlement IDs stay compatible. The
profile card uses actual active Premium/Explore rights for its Explore badge
and an integrated “Origo Read included” summary. It does not display an
independent Read purchase tile for those accounts. Temporary store-test access
is not presented as purchased Explore ownership.
