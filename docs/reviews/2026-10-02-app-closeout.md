# App closeout — 2026-10-02

## Plan

1. Preserve the original tracked edits and non-ignored untracked assets in local recovery ref `refs/codex-backups/app-closeout-20261002` (`5647449c68fe482239f02b725519dfe3bb5ed130`), leaving the shared index and working tree intact.
2. Fix the current CI failures on released main: enforce Dart formatting, align Linux build prerequisites with the successful release job, and keep product builds separate from core and stateful validation.
3. Classify the original work against released commit `69cb83c`, integrate only genuine unfinished work, and preserve user design/generated assets.
4. Run local validation and remote CI, then reconcile the primary checkout to the verified main while preserving remaining work.
5. Read current store build availability and identify device-dependent commerce acceptance gaps. Do not represent builds or test adapters as completed store purchases.

## Recovery

The local recovery ref above contains the pre-closeout working tree as a Git tree. Ignored build outputs and credentials remain in their existing locations. Published release tag `v2.7.2+260928006` remains immutable.

## Integrated work

- Treat the welcome flow, agreement summary, ReaderIndent font and released reader/source-login repairs as already shipped; do not duplicate or roll them back.
- Integrate the unfinished generic HTML/Legado rule contract as a single batch, retaining the released transport/session fixes.
- Complete discovery filter visibility/persistence and native Apple sign-in routing, preserving native Google identity guards. Restore the already-committed My-page title ownership fix omitted from released main.
- Preserve local design previews, marketing images and old release notes as local assets; do not publish them in the code closeout commit.

## Validation

- Source compatibility: 21 isolated Flutter files, 257 tests passed; two original-source offline contract probes passed. Changed-source analysis: 35 files, zero issues.
- Account/commerce: six isolated Flutter suites passed; account page: 20 tests passed. Discovery/settings: three isolated test invocations passed; tablet home/settings: two tests passed.
- Store tools: 16 iOS packaging tests, 30 macOS packaging tests, 21 App Store Connect tool tests passed. Changelog/Python tests: 14 passed.
- Full Dart format gate: 991 files, zero changes. Full analyzer: zero errors/warnings, eight existing style infos in untouched files.
- Remote CI: pending.

## Store state read back on 2026-10-02

- Apple API: iOS 2.7.2 is PREPARE_FOR_SUBMISSION; latest uploaded build 260927002 is VALID. Earlier 260927001 is VALID and its recorded internal/external TestFlight distribution remains separate from production submission. Old premium lifetime IAP is APPROVED; new reader/trial/premium-v2/explorer products are READY_TO_SUBMIT.
- Logged-in Chrome Play Console: no unpublished changes; Alpha 2.7.2 (260927002), release 6, is Available to selected testers across 178 countries/regions. Internal testing overview serves 2.7.2 (260928001), Native Google sign-in. These current observations supersede older Changes in review / AAB not uploaded notes.
- No Android device is attached; the paired iPhone is available. No real purchase, refund or cross-device restore was performed by this closeout. Store availability is not payment acceptance.

## CI repair

- Align Linux smoke build runner, WebKitGTK/libsoup/libunwind prerequisites and cookie expiry API with the successful release workflow; make the cached-source patch repeatable.
- Run Core Flutter validation, Stateful widget tests and Product build as independent jobs. Keep isolated stateful cases and locked dependency installation.
- Complete the isolated-case manifest so excluding a suite from Core does not silently drop assertions.
- Existing Dependabot upgrade branch failures concern inconsistent pubspec/lock changes; do not relax the lockfile gate.


## Fresh online source readback — 2026-10-02

- Guangyu: search currently fails before detail/catalog/content with `TypeError: undefined is not an object (evaluating books_data.length)`; reproduced with two queries. The earlier successful single-book result is historical evidence, not current service availability. Further upstream response diagnosis is recorded separately.
- Wenku: search request reaches the upstream and returns HTTP 403. Offline contract coverage does not demonstrate current online reading.
