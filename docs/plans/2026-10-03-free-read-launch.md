# Free Read launch

The launch policy is basic reading without login, trial, or a Read entitlement.
Read remains an optional store purchase that belongs to the signed-in Origo
account. Free use must not grant a Read badge or discounted Explore upgrade.
Explore advanced-source compatibility continues to require verified rights.
Apple sandbox environment detection alone must not unlock Explore or suppress
purchase/restore. Sandbox purchases remain verifiable but grant no access,
account identity, trial, or discounted upgrade eligibility.

Implementation:

1. Set the existing reader-license switch to false by default and in signed
   Apple, Mac App Store, and Google Play release commands. Keep billing channels.
2. Preserve paid entitlement verification, restore, refund, ownership, and
   Explore eligibility. Suppress new reader trial offers while reading is free.
3. Explain free reading and optional account ownership on the Read purchase
   page, retain purchase/restore, and remove expired-trial pressure in free mode.
4. Update the current product and release documentation; keep historical notes.

Verification: default store routing without an account; free access without
owned Read, Explore, or upgrade eligibility; signed-in purchase/restore; existing
gated-mode regressions; store packaging policy checks; isolated affected widget
tests and Flutter static analysis. Store upload and physical purchase/refund
acceptance remain separate release work.

Changed files:

- `lib/services/core/app_distribution.dart`: free Read default.
- `lib/services/account/member_account_controller.dart`: separate free use from
  real ownership; remove sandbox permission state and suppress unnecessary trials.
- `lib/services/account/store_purchase_service.dart`: preserve diagnostic
  test-verification status on purchase and restore, including existing paid users.
- `lib/pages/account/store_reader_unlock_page.dart`,
  `lib/pages/account/premium_membership_page.dart`,
  `lib/widgets/settings_account_card.dart`, and localized strings: honest free
  reading/optional purchase copy and visible TestFlight purchase/restore actions.
- `tool/app_store/build_ipa.py`, `tool/macos/build_app_store.py`,
  `tool/macos/distribution.py`, `.github/workflows/release.yml`: keep native billing
  channels while shipping the free reader gate setting.
- Corresponding tests and product/release runbooks were updated.

Simplification: the existing distribution switch remains the single reader gate.
Removed transient sandbox permission fields and their expiry/cache bookkeeping;
no new entitlement abstraction or dependency was added. Existing signed
Production account rights remain authoritative across TestFlight and App Store.

Verification:

- 126 affected Flutter tests passed in isolated file processes. Six optional
  environment/screenshot or release-define cases were skipped by existing rules.
- 53 Apple/macOS/release script tests passed.
- Changed Dart files pass static analysis. Full-repository analysis also records
  eight pre-existing style-level info findings outside this change, with no
  warnings or errors.
- Final unsigned iOS Release built successfully (57.3 MB); generated build
  settings confirm `appleStore` billing and `readerLicenseRequired=false`.
- Native purchase, restore and refund handling retain account binding. Regression
  coverage proves free guests cannot gain Read identity/Explore/upgrade discounts;
  Sandbox verification grants no rights, does not consume a trial, and cannot
  replace or clear independent Production membership.

Release limits: changes are local code and packaging policy, not an App Store
publication. Physical-device sandbox interaction and actual Production purchase,
refund and cross-device restoration are still separate acceptance work.
