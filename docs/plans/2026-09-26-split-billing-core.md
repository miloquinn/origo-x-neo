# Split billing core implementation plan

## Behavior to preserve

- Existing authentication, redemption, profile, OAuth cancellation, MFA, and legacy store verification remain available.
- Existing store listeners complete transactions only after authoritative server verification.
- Direct/website builds retain built-in reader access and account-bound Premium redemption.

## Core boundary changes

1. Introduce an installation-bound reader credential and signed reader-access cache that do not depend on an Origo session.
2. Model reader access separately from account membership: the 14-day reader trial and the USD 9.99 lifetime reader unlock never imply Premium.
3. Route store products through one transaction listener that can distinguish reader lifetime, Apple reader trial, and account-bound Premium products.
4. Keep Premium account-bound and require both authentication and permanent store reader ownership before starting a store Premium purchase.
5. Use the new reader and Premium endpoints; retain legacy endpoints only for old-client compatibility.
6. Cover anonymous start/restore, login and logout independence, trial expiry, refund/revocation, pending purchases, account switching, and legacy grants with focused tests.

## Verification

- Format and analyze all account service sources.
- Run the focused account-model, API, store-purchase, reader-access, offline-license, and account-controller tests in isolated Flutter test processes when global plugin state is involved.
- Review the final diff for accidental UI, localization, dependency, or unrelated worktree changes.
