# Android login layout — 2.7.2 (260928003)

## Confirmed device result

The user confirmed native Google login succeeds on OPPO PKT110 with the direct APK `2.7.2 (260928002)`. This verifies the website signing certificate/native OAuth path for that device. It does not establish Play-signed or iOS login acceptance.

## Layout correction

The previous external-login progress indicator was inserted before the entire form, directly above the left-aligned app icon, moving the form when loading began. The entry brand icon, heading and supporting text are now centered below the shared back header. Progress occupies a fixed 24 px region below the description, above the email field. The external login bar is 3 px tall and follows the theme. The disabled email button keeps its normal label instead of displaying a second unrelated spinner during Google login.

Authentication callbacks, account binding, cancellation and membership rules are unchanged. Password and registration tasks retain their focused form headings and existing submit progress.

## Verification

- Account page: 19 tests passed, including a pending Google chooser with exact idle/loading/canceled geometry, alignment and no duplicate spinner; existing small-keyboard flow remains covered.
- Native Google adapter: 4 tests passed.
- Production Flutter render capture: light/dark, idle/loading/canceled; inspected. Evidence is in `build/verification-store/account-login-layout/`.
- Targeted analysis: no issues. Python release metadata checks: 15 passed.
- Initial new fixture leaked the test platform override until teardown; fixed its lifetime before framework invariant checks and reran both alone and in the full account-page process. No app change was made to hide that infrastructure failure.

## Delivery

Android direct build only, version stays 2.7.2 and build advances to 260928003. Update with the existing direct signer using `adb install -r` to preserve device data. No store release is part of this UI adjustment.

Signed ARM64 APK built successfully and updated on PKT110 with `adb install -r`. Device package metadata confirms `2.7.2 (260928003)`, updated at `2026-09-28 01:07:18`. APK SHA-256: `93a81de133073058283505cd3df71b90c8421ae46399660ee1ddcc3cdf342cbf`. Direct signing SHA-1 unchanged: `B9:C2:1F:74:0D:14:5A:45:F5:37:DB:A0:76:CE:F9:17:63:B2:1B:58`. No uninstall, data clearing or logout performed.

The new layout was verified by production Flutter render capture and geometry tests; appearance on the physical phone awaits user inspection. Native login success was user-confirmed on preceding build 260928002 and auth code has not changed.
