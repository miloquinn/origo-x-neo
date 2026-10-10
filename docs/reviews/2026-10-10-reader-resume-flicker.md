# 2026-10-10 iOS vertical reader resume flicker

Historical diagnosis and validation for this change. The current contract is
[reading-cache.md](../reading-cache.md#vertical-reading-position-across-lifecycle-and-layout-changes).

## Cause and change

The reported mode was vertical scrolling. Both text readers treated every
foreground-to-background transition as a request to relocate an already
positioned canonical anchor, even when the viewport and text layout were
unchanged. The native reader then covered its retained text with
`native-reader-positioning-placeholder`; the source reader painted the
chapter/part-start jumps between the layout barriers before centering the caret.
Final-position-only tests passed despite these intermediate frames.

`native_reader_page.dart` now suspends only an unfinished restore.
`book_source_reader_page.dart` requests resume restoration only when a restore
is pending or in flight. Completed views retain their text and scroll position.
The existing geometry-change, navigation-cancellation, hidden-loading and
progress-save paths remain authoritative. No settings, book data, cache schema
or dependencies changed.

## Regression evidence

- Before the fix, all four source frame tests failed; one retained caret moved
  from y=278 to y=5444.6875 during an intermediate resume frame.
- The native frame regression failed on resumed frame 1 because the positioning
  placeholder was present. Its previous settled-anchor test had passed.
- After the fix, native and source checks retain exact painted paragraph/caret
  positions across background and the first eight resume frames, with both
  title policies and both chapter-scoped/whole-book scrolling. Source cases
  also repeat the complete switch twice.
- The complete source reader suite passes 81 tests, including genuine hidden
  geometry changes, interrupted TOC targets, hidden chapter loads, navigation,
  reopening and horizontal modes. Shared vertical helpers pass 10 tests,
  keep-screen-on passes 12, and aloud navigation ownership passes 6.
- Scoped Flutter analysis, Dart formatting and `git diff --check` pass.
- Eight EPUB background/exit cases, the split-TXT case and all 22 remaining
  native TXT cases pass in independent processes, bringing the unique passing
  test count to 141. The native lifecycle test contains four title/scoping
  configurations.

The full native TXT and initial-progress files exhibited state contamination
when cases were combined in one process: later readers timed out mounting, and
initial-progress cache disposal failed. The affected split-TXT case passes
alone, as do all native TXT cases. Native lifecycle and EPUB background/exit
regressions run in separate processes with all assertions active. Combined-run
failures are test infrastructure evidence, not platform build failures.

Logs and delivery receipts are under the ignored
`build/reader-resume-flicker-20261010/` directory, with source baseline/full-suite
logs at `build/reader-resume-source-before.log` and
`build/reader-resume-source-full.log`.

Source fix commit: `82c3657e`, pushed to `origin/main`. Local Sloane and Windows
`F:\code\origo-x` were independently verified against the live remote at that
commit. The Windows update used a checksum-verified Git bundle and a fast-forward
merge; its existing `closed-testing-emails.csv` was retained with unchanged hash.

## Delivery boundary

The isolated clean checkout at `db1fbbb1`, containing the fix at `82c3657e`,
successfully built the iOS Release product (`lib/main.dart`, direct channel,
`2.7.3+261010006`) without signing. Both modified reader source hashes matched
the shared checkout. Its build log, binary hashes and unsigned app archive were
retained before archiving the validation worktree. This is compilation evidence;
the isolated snapshot is not used for device delivery.

The device update uses the combined latest shared checkout and the existing
`direct` acceptance channel, with an in-place development-signed Release
installation on SloanePro (`00008140-001979421E93001C`). Build, installation,
launch and repeated physical app-switch UI acceptance are separate evidence
states. The reporting user's book/device scenario remains unverified until
physical acceptance. This task does not publish TestFlight or App Store builds.

At this report's update, the device still has build `261010005`. Other chats
have active, unfinalized product changes. The sole installation owner is this
reader-resume task; its one-shot delivery pipeline waits for all active source
owners, builds the combined committed product, compares source/generated-input
and signed binary hashes again before installation, then verifies installed
identity and launch. Its status and blocker receipts are under
`build/reader-resume-flicker-20261010/device-261010006/` and
`build/device-ios/coordination.json`. A queued pipeline is not installation or
physical UI acceptance evidence.
