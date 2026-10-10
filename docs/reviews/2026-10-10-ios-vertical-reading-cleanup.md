# iOS vertical reading follow-up audit — 2026-10-10

Historical validation and cleanup record. The current contract is in
[Reading cache](../reading-cache.md#vertical-reading-position-across-lifecycle-and-layout-changes).
The user accepted testing several available real-source books instead of
requiring the original unidentified book/source.

## Findings and bounded changes

The previous lifecycle repair remains in place. This follow-up inspected its
changed modules for stale state ownership, duplicate work, nested callbacks,
unused alternate paths and compatibility behavior before editing. The cleanup
plan and before/after logs are in ignored
`build/reader-vertical-audit-20261010/`.

1. **Reproduced stale navigation offset.** A normal catalog jump could inherit
   a pending narration offset. The reproduction selected the new chapter but
   placed its body at pixel `3522.6875` instead of its beginning. `_loadChapter`
   now owns an explicit nullable offset plus the target's fractional progress.
   Normal navigation clears the old anchor; bookmark/narration calls pass their
   own offset. Error-page retry and retained-exit recovery explicitly retain
   the same pending target. The retry regression uses fractional progress `0`
   with exact offset `1800`, independently checking exact-anchor priority.
2. **Flattened online restoration.** The three nested post-frame callbacks are
   sequential `endOfFrame` stages with the existing generation, load serial,
   restore serial and cancellation checks after each layout stage. Completion has one
   publication point. `endOfFrame` also schedules an idle frame. The idle case
   passed before this cleanup as well; no pre-fix idle hang was reproduced.
3. **Removed duplicate lifecycle snapshots.** Online and native readers take
   their initial foreground state from the binding and snapshot only the first
   foreground-to-background transition. Repeated inactive/hidden/paused events
   no longer repeat persistence or restart restore ownership.

Production changes are limited to six files under `lib/pages/reader/`:

- `book_source/book_source_reader_chapter_loading.dart`: request-owned anchor.
- `book_source/book_source_reader_navigation.dart`: explicit bookmark and retry anchors.
- `book_source/book_source_reader_shell.dart`: same-target error retry.
- `book_source/book_source_reader_vertical_paging.dart`: sequential restoration.
- `book_source/book_source_reader_page.dart`: lifecycle edge ownership.
- `native/native_reader_page.dart`: lifecycle edge ownership.

The native two-frame layout barrier remains: it has a separate layout-readiness
purpose and is covered by four title/scope configurations. Existing zero-offset
title alignment, cancellation guards, viewport readiness and bounded chapter
windows are grounded compatibility paths. They were retained with their
assertions. No dependency, new product abstraction, persisted schema, source-name
branch, cache budget or second restore implementation was added. This audit
covers vertical navigation; it is not a whole-application performance audit.

## Regression verification

53 relevant Flutter tests passed. Stateful native compatibility cases run in
fresh processes rather than sharing singleton state:

| Coverage | Passed tests |
| --- | ---: |
| Online vertical layout, lifecycle, hidden loads, TOC and saved anchors | 18 |
| Online recovery and exact-anchor retry | 18 |
| Narration cancellation and superseded/normal navigation | 6 |
| Native TXT TOC alignment, isolated processes | 4 |
| Native iOS lifecycle, four title/scope configurations | 1 |
| Native EPUB background/exit offsets, isolated processes | 6 |

New behavior locks are in `test/book_source_reader_page_test.dart`,
`test/book_source_reader_recovery_test.dart`,
`test/reader_aloud_navigation_guard_test.dart` and
`test/native_reader_txt_title_page_test.dart`. An independent read-only review
of the cleanup and same-target retry entry points found no remaining product
defect in this scope.

One concurrent Flutter invocation briefly removed the native-assets manifest
needed by a compatibility test. The same test passed in a fresh process without
application changes; this was test infrastructure interference. No assertion
was skipped. Exact-anchor priority was additionally rerun after strengthening
its fractional-position fixture.

## Real-source samples

`tool/reader_vertical_live_fetch_test.dart` uses the production `BookSourceClient`
to search, resolve detail, load the catalog and retrieve actual chapter text.
The opt-in diagnostic passed against the existing enabled 七猫 source
(`api-bc.wtzw.com`) without modifying installed preferences or login state.

| Book | Catalog chapters | First four chapters, characters |
| --- | ---: | ---: |
| 三国演义 | 123 | 16,121 |
| 封神演义 | 100 | 21,620 |
| 隋唐演义 | 101 | 19,914 |

The ignored sanitized snapshot is `live-books.json` in the audit directory,
SHA-256 `d736583b36497d39d5b0c79a4e5bb1763a3232168f52bf515d501a8c7636c8ae`.
It contains no source configuration, request headers, cookies, tokens or login
state. The fetch diagnostic explicitly injects an in-memory login-session store.
A second isolated-session fetch returned identical `samples` (canonical SHA-256
`5cf0f80afb90c62f6bff80f56a227dd70565bf1a3202d54eba877be8e448ec47`),
saved separately as `live-books-session-isolated.json`.

`tool/reader_vertical_live_books_test.dart` consumes those actual texts through
the production online reader with an isolated progress database and cache.
All 12 independent-process cases passed: three books × title-page on/off ×
chapter-only/whole-book scrolling. Each case drags into a body anchor, performs
three inactive/hidden/paused/resumed cycles including safe-area reflow, checks
the body chapter and canonical offset, reads persisted SQLite progress, checks
the selected catalog chapter, and jumps to another actual chapter. The target
scroll position must be `0 ± 1` pixel. All recorded final body and saved offsets
equaled their initial anchors: maximum observed difference `0` characters.
The 36 controlled lifecycle cycles are summarized in `live-widget-summary.json`.

The completed validation has 66 unique passing tests: 53 targeted regressions,
one production live-fetch diagnostic and 12 actual-text reader cases. Both
opt-in tools passed analysis. Scoped production/test analysis found no issues;
Dart format and diff whitespace checks passed. No live test is added to the
offline CI suite.

## Delivery boundary

The six reader product files are finalized and their hashes are published in
`build/device-ios/coordination.json`. Its intermediate reader-adjustment build
`261010004` was cancelled before installation because shared theme/AI work was
still changing. The theme chat now owns one final combined latest-checkout
build/install; this reader chat independently verifies those six hashes and
the installed application identity. This record's follow-up delivery receipt
will be added once available.

The current SloanePro identity was verified as iPhone 16 Pro,
UDID `00008140-001979421E93001C`. iPhone Mirroring reported the phone in use and
could not connect, so physical gestures and app switching were not observed.
Network-chain success, controlled reader regressions and physical-device UI
acceptance remain separate evidence boundaries. No TestFlight, App Store or
public GitHub release publication is implied by this follow-up.

The current host is `sloane.local`; Git synchronization on that machine uses
this checkout. Windows SSH synchronization remains unavailable: both `knbook`
and `milo-pc.local` timed out on port 22. No remote worktree was changed.
