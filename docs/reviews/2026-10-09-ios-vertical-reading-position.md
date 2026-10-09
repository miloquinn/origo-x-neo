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

The combined shared-checkout build `2.7.3+261009003` passed, its signature was
verified, and the keep-screen-on installation owner updated SloanePro in place
from build `261009001` to `261009003`. Device receipts identify SloanePro as an
iPhone 16 Pro with UDID `00008140-001979421E93001C`; the installed identity is
`com.niki.xxread`, version `2.7.3`, build `261009003`. Launch succeeded with PID
`21528`. This was a local development-signed Release using the Apple Store
channel configuration, with installed data retained.

The build base was `be472090`, plus finalized reader changes that were still
uncommitted at build time and subsequently committed as `b972ecf3`. All nine
reader file hashes independently match the build-before, build-after and
preinstall manifests, the finalized coordination record, and current sources.
The combined product fingerprint is
`a3eb344b5051b695d093dd64309101f0d2b21abd40ef58d8cb778dcaa183db92`;
the delivered AOT binary SHA-256 is
`e4041db1c57f56da3c4c68a113ba730dd0bbdff843d1feab7fa856351d46deae`.

Delivery receipts are under
`build/device-ios/keep-screen-on-261009003/signed-build.json` and
`device-acceptance/` in that directory. Independent reader verification is in
`build/reader-vertical-20261009/device-verification.json` (ignored build output).
Actual repeated app switches on the reported book/source remain unverified.
No GitHub public release, TestFlight or App Store publication is implied.

The current host is `sloane.local`. Windows synchronization is unavailable:
`milo-pc.local` did not resolve and `knbook` (100.106.191.32:22) timed out.
No remote worktree was reset or overwritten.
