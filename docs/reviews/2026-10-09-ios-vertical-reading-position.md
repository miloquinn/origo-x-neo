# iOS vertical reading position validation — 2026-10-09

Historical local validation for this repair. The current contract is in
[Reading cache](../reading-cache.md#vertical-reading-position-across-lifecycle-and-layout-changes).
This record does not establish reproduction on the reported book/source or
physical-device UI acceptance.

## Observation and repair

The user reported returning from another app with body chapter 185 while the
catalog still selected chapter 179. Controlled online regression reproduced
canonical body drift from offset 2677 to 95 after hidden viewport changes.
An additional distant TOC interruption reproduced duplicate GlobalKey cells
from the old two-list scroll animation.

Both readers now freeze their accepted chapter/source anchor while hidden,
restore it after active viewport/chrome layout, and reject obsolete frame
callbacks. Geometry includes safe-area chrome. Pending native navigation
keeps its cancellation predicate and completion across reflow; suspended
restores restart on resume. Online TOC/bookmark/narration jumps use the shared
canonical restore instead of a second animation and equal-height page estimate.
Narration cancellation releases the restore gate, and a page-mode change
replaces the old vertical owner.

Changed production modules: native page, scaffold, continuous layout and
vertical paging; book-source page, shell, vertical paging, chapter loading and
settings under `lib/pages/reader/`. Tests: native TXT title/position, online
reader page and aloud navigation guard. Current guide and pending 261009003
release notes were updated without changing stored progress/schema/cache
budgets or introducing dependencies.

## Verification

48 Flutter tests passed, including four configurations inside the new native
lifecycle test:

| Coverage | Passed tests |
| --- | ---: |
| Online background/layout anchors, title policies, TOC, saved reopen and auto scrolling | 15 |
| Online chapter recovery, retries and superseded requests | 17 |
| Aloud reveal cancellation and latest-intent behavior | 5 |
| Existing native TXT TOC alignment (each fresh process) | 4 |
| New native iOS lifecycle test (four title/scope configurations, changed and unchanged metrics) | 1 |
| Existing EPUB background/exit canonical offsets (each fresh process) | 6 |

Scoped Flutter analysis: no issues. Dart format and `git diff --check` passed.
Tests retain their body offset, geometry, title-start and catalog assertions.
Some native cases timed out only when combined after the first test; each
required case passed in a fresh process. This is recorded as test-state
isolation rather than a product build failure. Logs are saved under ignored
`build/reader-vertical-20261009/` and the native test executor's receipts.

## Delivery boundary

The shared checkout build is `2.7.3+261009003`. The keep-screen-on chat owns the
combined SloanePro local development-signed Release build/install and uses
`build/device-ios/coordination.json`; this repair must be included in its source
manifest before the in-place update. At creation of this record, combined build,
installation and launch are pending. Actual repeated app switches on the
reported book/source remain unverified even after a successful installation.
No GitHub public release, TestFlight or App Store publication is implied.

The current host is `sloane.local`. Windows synchronization is unavailable:
`milo-pc.local` did not resolve and `knbook` (100.106.191.32:22) timed out.
No remote worktree was reset or overwritten.
