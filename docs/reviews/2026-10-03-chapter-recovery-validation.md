# Chapter recovery validation

The development reader now prevents stale ORSP catalog requests by refreshing
the catalog before using its chapter IDs. Cached catalogs remain available on
explicitly transient transport/server failures. It also handles a chapter that
becomes missing during a session by refreshing, matching a stable ID or unique
normalized original title, and retrying once. Absent/ambiguous chapters remain
errors. The reporter's source-specific trigger has not been verified live.

## Changed files and simplifications

- `lib/book_sources/protocol/book_source_protocol.dart` and
  `lib/book_sources/protocol/orsp/orsp_http_pipeline.dart`: retain HTTP status and
  distinguish missing chapters from login, rate limiting, missing books and
  missing API routes without interpreting human-readable messages.
- `lib/pages/reader/book_source/book_source_reader_chapter_loading.dart`: share
  recovery with explicit vertical jumps; retain the failed target for retry;
  reject obsolete content/text/layout work; remove duplicate jump preloading.
- `book_source_reader_catalog_loading.dart` and `book_source_reader_page.dart`
  in the same directory: centralize catalog replacement and invalidate local
  content, pagination and prefetch state using a catalog generation.
- `book_source_reader_vertical_paging.dart`,
  `book_source_reader_pagination_cache.dart`,
  `book_source_reader_auto_page_turning.dart`, and `book_source_reader_shell.dart`
  in the same directory: protect deferred work and scrolling state, use the
  common foreground load for visible failures, and retry the requested chapter.
- `test/orsp_chapter_error_test.dart` and
  `test/book_source_reader_recovery_test.dart`: 24 new regressions covering error
  classification, ID remapping, same-ID recovery, bounded retries, exclusions,
  failed-target retry, catalog insertion, old replies, and continuous navigation.

No dependencies, book-source-specific branches, version changes or public
basic-reader source changes were introduced. Unrelated local work was preserved.

## Verification

- Original reader behavior failed 7 of the first 10 recovery regressions before
  implementation. Continuous scrolling also reproduced an uncaught chapter 404.
- Final reader recovery suite: 13 passed.
- Sequential protocol, HTTP revalidation, chapter cache and reading-source cache
  validation: 57 passed, including 11 new error-contract tests.
- Existing reader navigation, reopening, automatic scrolling, continuous
  scrolling, prefetch, horizontal sliding and tablet curl checks: 7 passed.
- Total distinct targeted tests: 77 passed. No assertions were disabled.
- Formatting and whitespace checks: passed; changed-file static analysis:
  no issues found.
- Final `flutter build apk --debug --no-pub`: passed.

One earlier parallel cache run hit a temporary-directory cleanup race; its
isolated case passed, followed by the full sequential 57-test run above.

## Physical Android validation (2026-10-03)

- Device: PKT110, Android 17, connected and authorized through ADB.
- Built the current fix with `flutter build apk --release --no-pub
  --target-platform android-arm64`: passed (119.5 seconds).
- Compared the installed certificate with the release certificate before
  installation; they match. Installed with `adb install -r`, preserving app
  data. Confirmed version 2.7.2, build 261003002.
- Pulled the installed APK back and confirmed its SHA-256 matches the tested
  release artifact: `b8dbae383924be60600579eb8b299437bc95975b8f127e37894bdf5e99025f24`.
- Existing bookshelf entries and reading records remained accessible. Opened
  an existing local book and used a physical-screen swipe through ADB to move
  from its opening section to chapter 1; content and reader controls rendered.
- Discovery opened and remained responsive, but the phone has no registered
  sources. This does not exercise populated discovery performance.
- Installed a temporary, separate package `com.niki.xxread.chaptervalidation`
  using an ignored Dart entry with the production `BookSourceReaderPage`.
  The client returns controlled chapter errors, with no network access; shelf,
  progress and pagination stores are stubbed and preferences are process-local.
  Separate package storage isolates all remaining reader services from user data.
- ADB touches verified changed-ID and same-ID recovery: one initial content
  failure, exactly one catalog refresh, then the second content request rendered
  the successful chapter body (visible `refresh=1, content=2`).
- Persistent 404: exactly two content requests and one catalog refresh, followed
  by the error surface. No extra request appeared during the following 24
  seconds. Touching Retry initiated one new bounded attempt (content 3/4,
  catalog refresh 2), confirming that the error UI remains interactive.
- Captured probe process logs contained no Flutter unhandled exception, fatal
  exception or ANR marker. This is a bounded smoke check, not a performance
  benchmark or a guarantee for every source.
- Removed the temporary test package and returned to the normal release app.
  The temporary build configuration was restored byte-for-byte. No production
  source changes were needed during this device validation.

Local screenshots, UI hierarchies, probe logs, the temporary entry, and APKs are
under ignored `build/device-chapter-validation/`; they are not public artifacts.

## Remaining validation

The reporter's affected source and exact manual-update action are still unknown.
The physical recovery checks use a local fake client; upstream network behavior,
large populated discovery lists and the reporter's particular source remain
unverified. This fix has been installed locally but not published as a new release.


## Prevention correction / build 261003003

The user's acceptance criterion is prevention of avoidable 404s, rather than
success after an initial 404. Real client/Dio/cache regression fixtures first
reproduced both a changed chapter ID and a missing server catalog state with
`chapter not found (HTTP 404)` before the prevention change. The revised path
synchronously requests the current catalog before content. Both scenarios assert
zero missing-content requests, not merely successful recovery.

The catalog cache shares persisted data while reader and download requests use
separate in-flight scopes. Download cancellation and its longer timeouts must
not control reading. Interactive catalog refresh makes one request attempt per
page, with a six-second receive timeout; downloads retain their existing retry
and timeout policy. Reopening an online book now waits for its current catalog,
so slow or very large sources may take longer to open than an immediate cached
catalog. Chapter content remains cached and there is no per-chapter forced
catalog scan.

Additional coverage locks disk-cache reopening, offline cached content, temporary
503 fallback, cancellation, certificate errors, authentication, missing books,
invalid catalog responses, and forced-download behavior. Ordinary HTTP 404s
remain real errors; cached data must not conceal them.

During regression validation, a concurrently introduced listening selector used
a State context from a layout callback and failed even in an isolated recovery
test. Wrapping the online annotated-page rendering in Builder provides a proper
build context and preserves selector subscriptions. The recovery suite then
passed with all thirteen assertions active. Other listening feature edits were
preserved.

The next release notes are `.github/release-notes/v2.7.2+261003003.md`,
`CHANGELOG.md`, and the generated `assets/changelog/changelog.json`; older public
build notes are unchanged. Version stays 2.7.2 and build number is 261003003.

Local provider investigation found stable URL-derived IDs and content lookup
that requires an exact match in a newly fetched directory. URL token changes or
a temporary incomplete directory could cause a missing chapter; that remains a
hypothesis. The available provider emits `Unknown chapter ID`, which differs
from the screenshot. No unknown third-party backend was modified or deployed.


### Final verification for 261003003

- Sequential core/cache/protocol/changelog validation: 77 passed (including
  11 prevention and 4 request-isolation regressions). Recovery widget tests:
  13 passed. Existing navigation/scroll/prefetch/curl checks: 7 passed. Total:
  97 distinct targeted Flutter checks. No assertions were disabled.
- Final prevention suite rerun after tightening the offline assertion to exactly
  one interactive attempt: all 11 passed.
- Changed-file static analysis, formatting and whitespace checks passed.
- Python changelog generation and release version-policy validation: 17 passed.
  Generated catalog checked against tracked notes plus this new note, preserving
  an unrelated untracked historical note without adding it to this change.
- Signed ARM64 release build: passed (159.5 seconds). APK identity 2.7.2,
  build 261003003; existing release signing certificate retained. Installed via
  `adb install -r` without clearing data. Pulled installed APK hash equals
  `b9cd1e6b76fcce3a069d29f75fafa04c947c2392cc8cfd8ce8861d4958b451e2`.
- Inspected the actual APK embedded changelog: it contains the 261003003 entry
  and the prevention wording recorded in the Markdown release note.
- An independent debug probe build passed (86.6 seconds), with the normal
  production BookSourceClient, Dio pipeline, catalog cache and reader. Only
  the HTTP adapter returns controlled source responses. Probe storage remained
  separate from the installed production app.
- On physical PKT110/Android 17, both changed-ID and lost-server-state scenarios
  rendered successful chapter content. Each log shows one catalog seed, one
  pre-content catalog refresh and exactly one content request; the requested
  chapter is current, server state is ready, and missing-content count is zero.
  No initial content 404 occurred. Captured probe logs contain no Flutter
  exception, fatal exception or ANR marker.
- Removed the probe package, restored the temporary debug configuration, and
  returned to the production app. Phone retains only `com.niki.xxread` from the
  two validation packages, on build 261003003.

The affected user's source remains unavailable. The above proves prevention of
stale catalog requests under controlled responses and physical rendering; it
cannot establish the unknown third-party service's actual cause or promise that
a truly deleted chapter or an upstream failure never returns 404. Changes and
release notes are local and have not been pushed or published in this task.
