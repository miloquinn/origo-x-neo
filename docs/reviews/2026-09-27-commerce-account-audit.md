# Account commerce audit — 2026-09-27

## Product contract

- Google Play and Apple production purchases, restores and trial starts require a fully signed-in Origo account. Google sends SHA-256 of the Origo UUID as its obfuscated account ID; Apple sends the UUID as appAccountToken. The backend verifies store evidence and immutable account ownership.
- Read / 开卷 is US$9.99. Explore / 探元 includes Read: US$8.99 for eligible Read owners, US$18.99 for the full plan. Display local store prices; do not hardcode USD in the checkout.
- Purchased account rights are cross-platform. Direct website/GitHub builds include local reading, without issuing a paid global account entitlement. Legacy reader licenses and old advanced memberships retain their compatibility paths.
- Reader trial lasts 14 days from the server-recorded start, once per Origo account, with the same deadline across stores. It does not mean once per person or per Apple/Google identity. Client expiry actively notifies the reader gate; offline licenses cannot extend the trial deadline.
- TestFlight/Apple sandbox is intentionally free and cannot validate production trial lockout. Google test orders do not become permanent production rights. A verified same-account, same-store sandbox Read order can now qualify a sandbox Explore upgrade.

## Fixes and cleanup

- Guard owner identity across product-configuration awaits, email changes, token refresh and session restore. Late responses must not restore a logged-out account or overwrite another account's tokens.
- Google restore inventory first validates restored events and then filters to configured SKUs. Unknown restored SKUs cannot make a restore hang; unrelated live purchase events cannot prematurely complete it.
- Remove unused purchase/trial aliases and the obsolete alternative gold profile-card layout. Keep the accepted identity card and separate offer card, avatar cache, accent colors and navigation.
- Email change requires only the new address's OTP after full login. No old-email OTP or password is requested. Preserve MFA completion, web CSRF, rate limits, challenge expiry/single use, and session rotation. The OTP is bound to the initiating Origo UUID; older in-flight email-change codes must be resent after deployment.
- App copy updated in all ten locales; website change-email form updated in simplified Chinese, traditional Chinese and English.

## Google login

Android currently opens a browser OAuth authorization flow and returns through `xxread://auth/device`, with polling as a callback fallback. iOS/macOS uses the system authentication session. This is not native Google SDK sign-in. Live auth configuration has Google enabled. Automated device-authorization/cancellation tests are not a completed physical Google login.

## Verification and deployment

- Isolated Flutter tests cover account/session races, both purchase flows, restore filtering, trial deadline crossing, account cards, reader gates and distribution rules. 168 targeted tests passed across 11 isolated suites; one existing platform-only test was skipped. Security preview fixtures also ran and the screenshots were visually checked. Run stateful widget suites in separate processes.
- Backend release candidate built from verified live/HEAD sources plus task-only changes: 186 relevant tests passed, including email, both stores, sandbox upgrade persistence and template regression. Ruff passed.
- Whole dirty backend workspace: 540 passed, 5 optional Redis tests skipped, 1 unrelated pre-existing email-template subject expectation failed against another task's mail redesign. That mail redesign was excluded from the deployed candidate.
- Changed-file Flutter analysis: 24 Dart files, no issues. Full-repository analysis reports eight existing style infos in unrelated source/reader modules and an unchanged test import; no new diagnostics in this change.
- Website locale validation (1,762 keys), typecheck and production build passed.
- Deployed backend and website to Aliyun `/srv/open-reading/code-releases/20260927-commerce-email-audit`, cloned from `20260927-ldxp-channel`. No migrations, credentials, prices or store-console changes. Public health reports all four checks OK; unauthenticated email-change requests return 401. Previous release retained for rollback.
- App source changes still require a newly installed build. This audit does not publish a new store build or claim real payment, refund, cross-device restore, or real mailbox delivery acceptance.
