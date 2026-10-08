# Shared pill inputs validation — 2026-10-08

Dated verification evidence. Current component/ownership guidance is [DESIGN.md](../../DESIGN.md#共享药丸搜索框2026-10-08).

## Scope and independence

18 actual search/filter inputs in sources (12), settings/backup (3), Library and reader (3) now use `PillSearchField`. The global AI page and reader AI panel also reuse the new `PillInputSurface` glass shell while preserving their native multiline editing, book picking and sending. Ordinary forms and debugging parameters retain their existing roles. Shared chrome uses the existing glass surface and full-height rounded superellipse; native editing owns its gestures. The component has a 52px minimum height that grows with text scaling, minimum 44px clear targets and explicit reader palette overrides.

Removed repeated wrappers/decorations across all callers, both old AI blur shells, the private AI size reporter and the now-unused Library panel decoration. Added the shared component, focused regressions and a production-widget GPU capture harness. No dependencies or search backends changed.

Unrelated shelf v28, online cache, settings-return and reader chapter-spacing work remains in the shared directory. Bounded source is projected onto `7f71282e` in a managed validation checkout. Library imports, search function, unused decoration removal and new clear regression are the only projected Library hunks. The shared main directory is used for phone delivery.

## Automated validation

166 affected widget regressions passed in separate Flutter processes: shared field 7; Library 7; reader catalog 13; reader full-text 6; source search 19; management 14; list/reveal 7; source organization 4; maintenance 19; cleanup 13; source change 14; replace rules 10; backup selection 12; TTS choices 10; reader AI 5; tablet/global AI 6. Source/organization/maintenance/cleanup/change migrations also received independent executor verification.

AI regressions cover configured/unconfigured sending, Markdown replies, seeded selections, tablet history/book picking and keyboard layout. New checks verify multiline growth and keyboard send in frosted/liquid/solid dark-reader modes at 320px/2x type, plus centered global composer actions above the keyboard. The reader test explicitly uses Chinese locale; the native decorator otherwise reserves the longer English hint height.

The shared field verifies native submission, default/custom clearing, controller-listener ownership, programmatic edits, replacement/unmount of borrowed nodes, disabled state, RTL/large type and explicit dark-reader colors across glass/solid modes. Library covers clearing before the pending 120ms debounce.

Before migration, source discovery cases timed out when run together; a failing case passed alone. All 19 assertions pass when each case receives its own process. No assertions were skipped. Management's rights-metadata case also failed before migration: it tapped after 500ms during the menu's 750ms transition. The test now waits for settling and every metadata assertion passes. Application menu behavior is unchanged.

Root and bounded validation checkout have no analyzer errors or warnings; three pre-existing info diagnostics remain in source chapter state, cookie rethrow and offline-reader-license test import. Bounded Library suite also passes against the baseline without the shelf WIP. Logs are under `build/validation/pill-search-fields-20261008/`.

An independent read-only search review approved controller/focus ownership, native interaction, all 18 adapters, clear/cancellation semantics and palette/layout contracts. The subsequent AI review identified fixed reader list clearance. New long-answer regressions reproduced both this reader obstruction and global AI measurement missing native-editor layout changes. Both AI overlays now reuse `MeasuredSize` from actual layout changes, reserve measured clearance and preserve bottom pinning. The dated before/final logs retain the evidence; no failing assertion was weakened. A follow-up independent review approved the layout callback lifecycle, whole-overlay measurement and preserved scroll ownership with no remaining findings.

## GPU and physical delivery

18 actual Impeller captures passed manual inspection on the iPhone 18 Pro Max iOS 27 simulator (shader filter supported): liquid light/dark at opacity 0/.5/1; frosted light/dark; glass off; 320px with 2x type; RTL; dark-reader palette inside a light app. 12 search captures contain the production shared field in empty, filled, count and resubmit roles alongside the production floating navigation. Six additional captures mount the actual production AI page/panel: empty/filled light and dark liquid, frosted, 320px/2x multiline, and dark-reader palette inside a light app with glass on/off. Multiline fields keep actions centered and grow the same full-round shell. PNGs and the capture manifest are under `docs/previews/pill-search-fields-20261008/`.

The first capture revealed inherited app colors on injected counters/actions and tight counter spacing at large type. Shared trailing defaults now follow the explicit palette and reserve an 8px gap. A second capture verifies the fix; palette regressions assert the displayed text and icon colors. Shared-field tests and all 12 other affected suites plus five source query/scope/clear cases were repeated successfully after this refinement.

The combined normal `lib/main.dart` iOS Release build succeeded with direct distribution and build number `261008004`. The package identity is `com.niki.xxread / 2.7.3 / 261008004`, its signature passes deep/strict verification and the liquid shader is packaged. Legal, shelf motion, update badge, reader gap and settings-return owner fingerprints match their readiness records. All 748 runtime/native source and asset fingerprints match before/after build: `67d291dde3a6dc9b139b5bcefd94247a818d6bda186f35c456145becdb99cf02`. The bundled legal catalog also matches the verified live content hash.

The immutable signed package and receipts are in `build/device-ios/pill-search-fields-20261008/`: `Runner.app`, `signed-build.json`, `source-before.json`, `source-after.json`, `readiness-checks.json` and `build-command.json`. AOT SHA256: `d0f63900ff1c67464d68299b8a0d34bf4804bfe6526bf80ca44a612bbdf7032b`. This is a local developer-signed Release, separate from TestFlight/App Store publication.

An in-place installation was attempted and failed with CoreDeviceError 4016 because SloanePro has no trusted device connectivity. `install.json`/`install.log` retain the failure; device name/UDID were checked. The app was not uninstalled or cleared, and this package has not yet been installed or launched. Delivery remains pending reconnection. Automated widget tests and simulator captures do not prove physical keyboard or personal visual acceptance.
