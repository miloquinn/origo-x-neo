# In-App Purchase review fix

## Scope

- Expose and verify the Read, Explore upgrade, and Explore full products in Apple's sandbox review flow.
- Keep sandbox grants account-bound and memory-only so they cannot enter Production membership or offline reader caches.
- Restore Read before Explore after a restart, and clear each sandbox grant on its matching revocation, logout, or account switch.
- Preserve free basic reading while continuing to require Explore rights for advanced sources.

## Regression coverage

- Lock the Read, upgrade, full-bundle, revocation, logout, account-switch, and explicit-restore contracts in controller tests.
- Reject malformed sandbox verification results in the purchase service instead of reporting a successful test purchase.
- Run the affected Flutter test files independently, then run static analysis for the modified implementation.
