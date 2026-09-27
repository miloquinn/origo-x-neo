# Native Google sign-in — 2026-09-28

## Contract

Android and iOS use the official Google Sign-In SDK when public auth configuration enables it. Other platforms and older backends keep the existing browser flow. iOS may present Google's system web authentication sheet; Android uses the native account chooser. Cancellation does not produce an error or create an Origo session.

The client exchanges the SDK ID token at `POST /api/v1/auth/google/login`. Server verification fixes RS256 and Google's JWKS, issuer, server Web audience, expiry, issued-at, subject and verified email. Presenter `azp` is constrained to configured IDs; multiple audiences require an allowed presenter. Native authentication does not require a nonce; the existing web OAuth flow still validates its challenge nonce. Account resolution and MFA use the existing Origo identity/session path.

Reuse the existing Google Cloud project and Web client. Android clients are separate per package/signing SHA-1; iOS has its own bundle/team-bound client and reversed-ID callback URL scheme. Signing certificates and public IDs are registered in `/Users/xiaoyuan/certs/origo-x/google-native-login.md`; secrets remain outside Git. Login OAuth is separate from the Play order-verification service account.

## Verification and deployment

- Clean backend candidate based on `ada8a45`, with only config, account routes, email_auth service and native Google regression tests. Unrelated mail/hosting WIP excluded.
- Native Google tests: 15 passed; email authentication: 67 passed; generic authentication: 7 passed. Ruff and Python compilation passed.
- Deployed to the user-authorized existing Aliyun service, `/srv/open-reading/code-releases/20260928-native-google`. No database migration. Existing live GitHub repository fallback preserved.
- Public health: all four checks OK. `/api/v1/auth/config` exposes enabled native configuration. Invalid ID token is rejected with HTTP 400 `googleTokenInvalid`. This is not proof of a completed Google account login.
- Rollback code: `20260927-commerce-email-audit`; rollback configuration: `shared/.env.backup-20260928-native-google`.
- Real provider login, Android Play-installed behavior and iPhone authentication remain device acceptance items until recorded below.

## Mobile validation

- Flutter adapter tests: 4 passed; account service/session tests: 74 passed; account page tests: 18 passed, each suite run in its own process. Targeted analysis: zero issues. Changelog generator: 9 passed.
- Native chooser registration invalidates earlier authentication intents. Results arriving after another sign-in, logout, session invalidation or controller disposal cannot establish a stale session. A native-only Google configuration still shows the button on Android/iOS.
- iOS release built successfully (58.3 MB), using marketing version 2.7.2 / build 260928001. Embedded callback scheme and packaged changelog verified. Installed on the paired iPhone and device inventory confirmed bundleVersion 260928001. Automatic launch was denied because the phone was locked; completed Google sign-in remains user/device verification, not a claimed pass.
- No store release has been published by this task.

- Google Play release AAB built successfully (106.8 MB); upload signer SHA-1 matches the registered direct/upload certificate. SHA-256: `da1246b16b08ba6472b1a2cf61c6d7254aa895e0787f40e4744868f33ce52fce`. Android device was not attached, and the AAB was not uploaded to Play.
- Changelog service tests: 5 passed after numeric build/catalog synchronization.
