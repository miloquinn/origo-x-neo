# Android native Google sign-in device validation — 260928001

- User clarified that Android is the validation target; iOS is outside this follow-up.
- Version remains 2.7.2. Source commit: `f898a7a821fe982976e78fffa648dc666b6cb173`.
- AAB SHA-256: `da1246b16b08ba6472b1a2cf61c6d7254aa895e0787f40e4744868f33ce52fce`.
- Connected device: OPPO PKT110. Before update it has Play-installed `2.7.2 (260926005)`, installer `com.android.vending`.
- Pulled installed base APK to verify its signer, SHA-1 `01:65:9D:E1:6F:96:D5:69:4E:E9:01:C2:60:5E:09:81:85:1A:C9:52`. This matches the registered Android Play OAuth client.
- Initial plan: preserve installed data and update through Play internal testing. The later user-selected direct APK reinstall is recorded below; installer identity and automatic protection were not modified.
- Internal track: `4700753799072472809`; release `7` is **Available to internal testers**, September 28 at 00:37 local time. On-device update and login acceptance remain pending.
- Test steps: Play update; verify installed build; Google native account chooser; cancel/retry; finish sign-in; verify existing Origo identity and entitlements. Never record ID tokens or session credentials in the report.

- [Internal release](https://play.google.com/console/u/0/developers/5190330618916125493/app/4975621739577175897/tracks/4700753799072472809/releases/7/details). Existing tester lists and other tracks unchanged. Nine-language release notes included.

## User-selected direct APK test

The user chose the website/GitHub direct APK and explicitly accepted reinstalling the app. The existing Play app may therefore be uninstalled after a correctly signed direct APK is ready. This preserves account-backed purchases but clears installation-local app data. The Play remote-install attempt stopped at account reauthentication; no remote install was confirmed.

Direct distribution grants local reading access only. It does not grant the account a Read badge, cross-platform paid entitlement, or paid-Read upgrade eligibility. Explore/advanced source access still requires account entitlement. Static review confirms these boundaries; no implementation change was needed for this clarification.

### Direct build 260928001 installed

The user-approved reinstall completed successfully. Installed version: `2.7.2 (260928001)`, installer `com.android.packageinstaller`, direct signing SHA-1 `B9:C2:1F:74:0D:14:5A:45:F5:37:DB:A0:76:CE:F9:17:63:B2:1B:58`. APK SHA-256: `11a8f21c9e14ad259be573c5fd00f1437c70526de9c0b13f101a35b8c6942b40`.

Direct entitlement regressions passed in isolated processes: store account entry 14, reader account 24, advanced source settings 2. Actual native Google sign-in on the phone remains unconfirmed: the user first reported the missing welcome update.

### Welcome omission and repair

The approved welcome work was still uncommitted in the primary checkout, while the testing APK was built from the billing worktree. It was omitted from 260928001. The welcome files and only their added localization keys were ported without copying unrelated source-engine work or reverting the newer account/billing implementation. The current agreement service and version are unchanged.

Build `2.7.2 (260928002)` includes the welcome journey and a read-only replay under My → About & support → Welcome guide, because the user already accepted the old welcome flow. Updating this direct package must retain app data (`adb install -r`), with no further uninstall or consent reset.

Validation for 260928002: 48 tests passed across welcome component (7), disclosures (2), production consent flow (13), preview navigation (2), settings/replay (19), and changelog service (5), each suite in a separate Flutter process. Actual Flutter capture passed and the rendered welcome/agreement screens were inspected. Targeted Flutter analysis has no issues. Release metadata/generator Python tests: 15 passed. Independent read-only review confirmed unchanged consent storage and preservation of existing localized account text.

Installed update: `adb install -r` succeeded on OPPO PKT110, preserving existing app data. Device package metadata confirms version `2.7.2`, build `260928002`, last update `2026-09-28 00:56:13`; installer field is null after the ADB update. APK SHA-256: `5e6ab99bc68e2373a3c8817b7460f5184e057ba94a403d658c5d11d35568151d`; direct signing certificate verified unchanged. Artifact: `build/verification-store/origo-x-direct-2.7.2+260928002-arm64.apk`. This build has not been uploaded to Play, TestFlight, or a GitHub Release. Physical welcome replay and native Google sign-in remain for the user to verify; do not equate installation success with login success.
