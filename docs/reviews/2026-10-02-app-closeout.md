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
- Remote CI: [PR checks](https://github.com/miloquinn/origo-x-neo/actions/workflows/pr-checks.yml) and [platform smoke builds](https://github.com/miloquinn/origo-x-neo/actions/workflows/platform-smoke.yml). Match each run to the current main SHA before interpreting its result.

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

- Guangyu: search currently fails before detail/catalog/content with `TypeError: undefined is not an object (evaluating books_data.length)`; reproduced with two queries. The earlier successful single-book result is historical evidence, not current service availability. Direct readback of all seven search lines returned HTTP 502, text/plain and 16 bytes each, while HTML/JSON configuration endpoints returned HTTP 200. The source catches each failed request and then dereferences missing data; no engine change is appropriate.
- Wenku: search request reaches the upstream and returns HTTP 403. Offline contract coverage does not demonstrate current online reading.

## Primary checkout reconciliation

The original working tree was rehashed using an isolated Git index and matched the recovery snapshot exactly before reconciliation. Primary main now follows the closeout commit. Fourteen local status entries remain: DESIGN.md and design/preview/marketing assets; application and CI edits are committed. Ignored build outputs and private files were preserved.

The first remote run passed all platform product builds: Android debug APK, Web release, Linux release, Windows release, macOS release and unsigned iOS release, plus response codec validation. Its newly restored acknowledgement case exposed a stale Origo-vs-Origo-X English substring; the test now reads the current localized contract and retains disabled-before-consent/enabled-after-consent assertions.

## Core follow-up repair plan

The complete first Core run exposed missing test platform initialization, reader/account timing fixtures and eight production file responsibility-budget violations. Reproduce failed cases alone before changing code. Initialize platform-dependent source fixtures explicitly and retain session behavior; repair deterministic reader/account fixtures; split oversized files at cohesive existing responsibility boundaries, retaining public APIs and all architecture assertions. Run each affected regression suite and the full format/analyzer gates before repeating remote CI.

## Follow-up repairs and evidence

- Keep secure session defaults; initialize six platform-dependent source fixtures explicitly. Source lifecycle now closes idempotently and rejects new operations after closure. Seven affected source suites: 60 tests passed in isolated processes.
- Reject stale authorization-poll errors after cancellation or a newer authentication intent. Account cancellation, account service and account page: 96 tests passed.
- Use the production SQLite progress schema/store through a per-test database in source reader fixtures; keep legacy progress migration and real persistence assertions. Reading modes: 16 tests passed; pagination persistence: one test passed.
- Retry previous-chapter pagination after the viewport becomes available and rebase the leading slide pages while keeping the current page. Both adjacent-preview regressions passed; await rendered pagination instead of treating request initiation as completed preparation.
- Keep comic scroll anchors stable across multiple visible image-extent changes. Repair touch-slop geometry and assert the actual retained chapter window, while preserving visible-position and reverse-navigation assertions. Comic reader: all 21 tests passed, including both original failures run alone.
- Split eight oversized source files into ten cohesive parts. All original architecture assertions remain active; all files stay below the 800-line responsibility budget. Architecture: 4 tests passed; affected service/controller/script suites: 94 tests passed; three independent UI representative cases passed.
- Native continuous auto-scroll tests explicitly configure visible chapter fractions and read rendered footer text. The original failing chapter-boundary case passed in its own process.
- Full analyzer after the repairs: zero errors/warnings, eight existing style infos. Python/changelog/isolated-manifest verification: 14 tests passed and every isolated case remains covered. The definitive remote result must be read against the final main SHA.


## Definitive remote follow-up at 769105d

- [PR checks 36980980397](https://github.com/miloquinn/origo-x-neo/actions/runs/36980980397): Core Flutter validation passed, including formatting, analysis, QuickJS compatibility and coverage (2,444 tests passed; nine existing opt-in cases skipped). Response codec, Android debug and Web release jobs passed independently.
- [Platform builds 36980980369](https://github.com/miloquinn/origo-x-neo/actions/runs/36980980369): Linux, Windows, macOS release and unsigned iOS release all passed.
- The remaining failure was the isolated oversized-TXT restore test's teardown: an unawaited reader-disposal cloud checkpoint left a sqflite lock timer pending. The offset assertions themselves passed. Finish the test's real database writes before leaving fakeAsync; retain production recording and the pending-timer invariant.
- The remaining source-reader cases must all use their test-owned SQLite progress store, including saved-progress setup and the deliberately blocking-save subclass. Keep real progress reads and all tablet/cross-chapter assertions.

The final follow-up changes are test-only: a real database write barrier and explicit teardown for native reader cloud checkpoints, plus consistent progress-store injection in source-reader setup and blocking-save fixtures. The oversized-TXT regression deliberately records a nonzero real session and checks that a cloud event is persisted; it does not rely on parsing speed. All existing offset, page, consent and pending-timer assertions remain enabled. Changed test files passed formatting and targeted analysis; Python/changelog/isolated-manifest checks passed. Product code, dependency locks, app version and published tags are unchanged by this final fixture repair.

Final isolated verification: source reader's seven original failures and twelve dynamic page-mode/exit cases passed; all thirteen native progress cases passed; discovery/pagination passed all thirty-eight cases after replacing the obsolete reveal-component type assertion. The replacement checks the exact source row, advances beyond its configured stagger, and asserts that the reveal animation is in progress while preserving directory/header/scroll restoration assertions. One local native-assets build race was rerun alone successfully; it did not enter product assertions.
