# Split reader unlock and Premium UI

Status: implemented and locally verified; store sandbox/device payment acceptance remains.

## Product contract

- Google Play and Apple builds expose a guest-readable **app permanent unlock** flow. Its store product grants local reader access only and never grants Premium.
- The 14-day reader trial remains separate from permanent unlock. A trial never reveals or unlocks Premium purchasing.
- Store builds reveal the **Premium lifetime** flow only after permanent app ownership is verified. Premium costs US$8.99 in the US, uses the store's localized price, requires an Origo account, and binds the verified purchase to that account.
- Direct website builds include permanent reader access by distribution. Their existing signed-in Premium purchase/redemption flow remains available.
- Reader ownership and Premium are independent entitlements: neither may be inferred from the other. Existing explicit permanent reader migration access remains valid.

## UI implementation

1. Introduce a dedicated store reader-unlock page with product loading, 14-day trial, purchase, restore, and status handling that does not require Origo login.
2. Keep the Premium page focused on account-bound Premium. On store builds, show a reader-ownership prerequisite instead of Premium purchase controls until permanent reader ownership is verified.
3. Route the reader access gate to the reader-unlock page. Keep reader construction lazy while access is unresolved or denied.
4. Update account/settings entry points owned by the main integration lane so app licensing stays reachable while signed out and Premium appears only after permanent reader ownership.

## Verification

- Widget tests: guest app purchase/restore, trial hides Premium, permanent reader shows Premium, Premium alone leaves reader locked, direct website redemption remains.
- Static analysis for modified production and test files.
- Render and inspect phone-size Flutter frames for locked reader, app unlock, and unlocked Premium states.

Completed evidence:

- Guest app unlock, reader trial isolation, permanent ownership, and Premium-without-reader regression tests pass.
- Reader route gate opens the app license page without requiring Origo sign-in and continues to construct reader content lazily.
- Premium page regression suite passes with separate store Premium product state and direct-build redemption preserved.
- Production Flutter widgets rendered at 1290×2796 for the App Store reader and Premium purchase review frames under `docs/previews/account-redesign/implemented/`.
- Static analysis passes for the modified purchase pages, gate, policies, and their UI tests.
