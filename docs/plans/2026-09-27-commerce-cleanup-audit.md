# Account commerce cleanup and verification

## Preserved behavior

- New Read / Explore purchase, restore and trial require a signed-in Origo account.
- Production purchases belong to the immutable Origo account across Apple/Google. Direct builds stay locally free without granting a paid account right.
- Explore includes Read. Read upgrade eligibility must remain independently owned; sandbox transactions must never mint production rights.
- Trial is server-controlled, account-bound and time-limited. TestFlight's intentional test access is not proof of production expiry.
- Keep the accepted separate offer / owned identity card UI, current membership names and accents.

## Behavior lock before changes

Run isolated Flutter account, purchase, account-reader, API, trial/gate and current settings tests. Add targeted delayed-account-switch reproductions before fixing purchase initiation. Backend: run targeted store/account tests against an isolated local test database only; never consume real purchases/trials for test fixtures.

## Scope / ordered passes

1. Repair reader purchase / Apple trial / restore account-switch races to match the existing Premium owner guards; prevent store calls after the initiating account changes.
2. Verify and repair sandbox upgrade eligibility using verified same-account sandbox reader ownership in the same verification environment, without admitting test orders to production rights.
3. Remove obsolete gold-card implementation and unused style constants now that production uses AccountIdentityCard. Keep avatar cache and navigation behavior; route existing widget tests through the actual production card contract.
4. Align misleading old comments and operation state tests. Record Google OAuth runtime route and current public billing/trial configuration separately from unperformed payment acceptance.
5. Repeat targeted tests, static analysis, backend required checks where applicable. Document exactly what needs physical store acceptance; do not claim stubbed purchases are live-store validation.

## Fallback inventory

- OAuth native-callback absence / browser polling: grounded platform compatibility; retain polling and cancellation-generation tests.
- Legacy anonymous reader receipts: grounded migration boundary; retain explicit legacy SKU handling and anti-claim protections.
- HTTPS-issued offline access cache: grounded offline fail-safe, bounded by owner, installation, channel and expiry; no permissive default access.
- TestFlight full-access exception: explicit product policy, not trial validation; retain and label in verification notes.
- Old alternative gold account-card branch: obsolete UI, only tests instantiate its default constructor; remove after baseline tests.
- Purchase product-load errors: inspect for lost error states; retain only where controller surfaces the failure. Never add success-on-error behavior.

## Isolation / verification limits

Use the existing clean app release checkout. Backend main has unrelated in-flight work: do not stage or revert it; limit any correction to initially clean membership files and new dedicated tests, with before/after diffs. Existing user deployment direction is Aliyun for billing, but inspect current runtime before any deployment because another task is migrating services.

## Independent review corrections / executable acceptance

- Google restore: expected purchase IDs must be filtered to requested productIds. Mixed known+unknown SKU inventory must restore known purchases successfully; unknown-only inventory reports nothing-to-restore without waiting for a missing transaction. Preserve explicitly configured legacy SKUs.
- Owner guards: cover purchaseReaderLifetime, Apple startReaderTrial, restoreReaderPurchases and restoreStorePremiumPurchases. Switch account during product configuration; assert account-changed error and zero buyNonConsumable/restorePurchases calls.
- Sandbox qualification: keep existing valid Production Read / manual permanent grants qualifying (including cross-platform). For a verified Sandbox/test upgrade only, additionally accept an active, non-refunded Sandbox reader order belonging to the same user_id AND owner_account_id, same store channel and Sandbox environment. Test purchases never qualify a Production upgrade and never create Production entitlements. Keeping existing Production-to-Sandbox qualification avoids breaking legitimate paying testers; the isolation boundary is test-to-production, not withholding a paid user's ability to test.
- Sandbox regressions for both stores: same-account/same-store success; other account/store, revoked reader and Production upgrade rejected when only a Sandbox reader exists; production entitlements remain absent; established Production qualification remains intact.
- Trial evidence: signed-out rejection; server starts exactly 14 days; duplicate/cross-platform start preserves deadline; controller notifies when time crosses the deadline and gate denies reading; account switches cannot reuse licenses. Validate live config separately. TestFlight free access is explicitly excluded from expiry evidence.
- Google login evidence: current external browser / Apple authentication-session implementation, deep-link + polling + cancellation tests, live provider enabled flag. Do not label OAuth or purchases physically completed without a real device end-to-end result.

## User-added scope: signed-in email change

- New email is the only address receiving / requiring a verification code. Do not require old-email OTP or current password.
- Preserve fully authenticated API session, web CSRF, MFA-complete requirement, code TTL / one-time use / request rate limits, uniqueness check, atomic session revocation + rotation. Bind the new challenge hash to the initiating account UUID so switching accounts cannot reuse it.
- Keep optional old-proof payload fields accepted for older clients, but do not request or validate them. Other security flows (password, MFA, account deletion) keep their own verification requirements.
- Align app and website forms and ten-language app copy. Add failed/mismatched/expired/replayed code, cross-account, signed-out and pending-MFA tests; preserve old-session invalidation.
- Snapshot pre-existing backend WIP before edits; never stage unrelated migration/mail changes wholesale. Verify the running Aliyun source before considering a narrow deployment.
