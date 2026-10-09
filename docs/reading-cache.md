# Reading cache

Current maintenance guide; online startup/cache contracts checked against code
on 2026-10-08. Start at [the maintenance index](README.md) for related modules.
Update this guide with behavior changes; dated validation records prove only
their recorded snapshot and are not another implementation specification.

Local and online readers share bounded cache storage policies and the same SQLite pagination boundary store. File decoding and network fetching keep their existing adapters; source responses, parsed content, layout boundaries, and image bytes remain separate cache types.

## Read path

- Local TXT: reopen memory when appropriate → parsed JSON or streaming index/data → source file.
- Local EPUB: active chapter window → per-book chapter/resource files → source archive. Closing a reader releases its resource lease; reopen uses the disk index and saved pagination.
- Online text: reader chapter window → shared chapter/catalog memory → disk → source backend. Concurrent equivalent loads share work. Fresh downloaded content uses this same cache with background refresh disabled.
- Text pagination: memory → compact SQLite boundaries → line measurement. Online storage contains offsets only, never a second copy of chapter text.
- Images: decoded/image-byte memory → owned disk files → local extraction or network. Existing visible-first network scheduling stays in use.

Cold online chapter/catalog callers share the same disk read, scoped by cache
root, content identity, and clear epoch. Freshness stays a caller decision.
ORSP and ReadingSource chapter/catalog network flights use separate interactive,
download and cancellation-token scopes. Different owners share persisted data
without sharing cancellation ownership.
Pending cold source loads can be joined immediately. A background refresh never
blocks a stale-while-revalidate disk hit after OS memory release, and a delayed
disk result cannot replace newer memory. If an early joined request fails,
acceptable cached data may recover the read without starting a second request;
otherwise the original source error is preserved.

Online text reader startup loads the catalog, saved position, settings,
replacement rules, and shelf identity concurrently. An existing persisted shelf
record is passed through the online reader factory, and other entry points
resolve it once during opening. Purification waits for both rules and shelf
identity so per-book settings remain correct. Bookmarks and annotations load
asynchronously. A later book-settings refresh remains authoritative when the
reader reloads its catalog.

## Identity and invalidation

Local identities combine the book identity, actual file modification time and size, encoding, and edit revision. Online content retains existing source configuration, variables, and authentication revision isolation. Online pagination additionally hashes source/book/chapter identity and the resulting readable text. Layout fingerprints include engine version, font profile, viewport, spacing, direction, replacement rules, and the shared chapter-title preference. Online headings also participate in layout identity because an inline heading changes the first body page height.

Changing text invalidates its derived pagination. Changing layout preserves parsed content. The DAO uses global clear epochs and per-identity revision tokens so delayed writes cannot revive cleared entries or supersede a newer revision. Compatible v22 local pagination rows migrate into the local namespace; incompatible derived cache formats are rebuilt.

## Default budgets

Budgets are ceilings, not reserved allocations. Constructors permit smaller limits in tests or future configuration.

| Cache | Memory | Persistent data |
| --- | --- | --- |
| Online chapters and catalogs | Shared 24 MiB serialized-size budget; also 24 chapters / 12 catalogs | 256 MiB; 30-day expiry |
| Source covers | 24 MiB | 96 MiB; 7-day expiry |
| Source image pages | 64 MiB | 512 MiB; 30-day expiry |
| Local parsed resources | Existing chapter/window limits | 512 MiB per native resource root |
| Shared pagination | Existing reader windows; at most 128 stored payloads per identity | 32 MiB / 4096 entries globally; 128 per identity |
| Public source responses | Existing 4 MiB / 48 entries | Existing 16 MiB / 160 entries |

The shared disk budget groups streaming TXT index/data siblings and all files in one EPUB book directory. It evicts cold groups together, skips active resources, throttles directory scans, and checks cumulative online write growth against the byte budget. Native directory maintenance runs outside the critical opening path. Protected active books can temporarily exceed their quota; closing readers and completing their pending I/O triggers another maintenance pass.

## Clearing and ownership

`AppCacheManager` includes source image-page files, chapter/catalog memory estimates, native derived directories, and SQLite pagination payloads. Reading-cache clearing invalidates live pagination holders and releases native reopen memory. Active lazy resources are retained until the final reader or I/O operation releases them, including output files that did not exist when clearing began.

Imported books, saved downloads, saved covers, progress, annotations, credentials, and source configuration are not cache eviction candidates. Legacy directory cleanup remains for upgrades. Corrupt-cache recomputation and stale content during network failure remain intentional recovery paths.

Usage combines owned file bytes and available serialized/memory byte counters, not a precise Dart heap measurement. SQLite payload bytes become reusable database space after clearing; the shared application database file need not shrink immediately.

## Regression coverage

Tests cover byte limits, grouped eviction, protected/late-created resources, hot-read scan throttling, rapid write growth, clear/write races, version races, migration, corrupt payloads, local and online reopen hits, layout/content/source separation, external TXT edits with unchanged database metadata, and download reuse. Stateful reader tests use isolated filesystem roots and drain asynchronous cache work before the next case; they retain all rendering and navigation assertions.

## Shared chapter-title layout

`ReaderSettings.chapterTitlePageEnabled` controls local and online flowing-text readers in every page mode. `ReaderSettingsSheet` requires the preference and callback, preventing an entry point from silently omitting the switch. The historical preferences key `native_reader_txt_chapter_title_page_enabled` and WebDAV record `txt_chapter_title_page` remain unchanged so upgrades and older sync peers retain the selected value.

`paginateReaderText` owns dedicated title pages and inline title metadata/first-page height accounting. `ReaderAnnotatedTextPage` renders inline headings outside the selectable body, preserving canonical source offsets for annotations, search, narration and reading positions. The pagination codec persists the same title metadata for both entry points. Continuous scrolling uses an entire viewport for dedicated titles and an unpaginated inline heading when disabled.

With dedicated title pages disabled, whole-book continuous scrolling separates adjacent chapters by 1.5 body line heights. `readerContinuousChapterSpacing` in `lib/core/reader/reader_vertical_paging.dart` owns the shared font-size/line-height calculation; the local and online vertical chapter containers append it as trailing space outside the text cells. This preserves chapter-start alignment and canonical text offsets without inserting content or changing persisted pagination. The final chapter and chapter-only scrolling receive no separator; dedicated title pages keep their viewport-sized layout. The body-scaled gap tests in `test/native_reader_txt_title_page_test.dart` and `test/book_source_reader_page_test.dart` cover both entry points at normal and enlarged body sizes; the existing vertical TOC and saved-anchor cases cover navigation and reopening with both title policies.

File parsing, EPUB images/styles and network loading remain source adapters. The title option lays out titles that the adapter has separated from body text; embedded EPUB/HTML headings remain document content and are not duplicated. TXT continuation segments do not repeat chapter headings.

Regression coverage includes online toggle persistence in all five page modes, body offset preservation, title-policy cache invalidation/reopening, local title pages, inline annotation offsets, invalid cache flags and old settings/sync identifiers.

## Vertical reading position across lifecycle and layout changes

Local and online continuous readers keep a chapter and canonical source offset
as their reading position. A positioned-list item index and its accumulated
pixel distance are layout details; they must not become a new reading position
when iOS changes viewport or safe-area metrics during an app switch.

On leaving the foreground, the reader persists its last accepted position and
keeps a restore pending. Hidden position callbacks cannot change the chapter or
progress. On resume, the current viewport and chrome are laid out before the
canonical anchor is restored. Chapter starts retain their opening title/inline
heading alignment; body anchors return to screen center. Geometry changes use
the same restore even without a lifecycle transition. Native reflow preserves
an existing navigation cancellation predicate and completion rather than
creating a competing intent; suspended post-frame restores are rescheduled on
resume. Online callbacks also validate a restore serial and the pending narration
cancellation predicate so old geometry or highlight work cannot complete a
newer restore. Explicit page-mode changes release the previous vertical owner.

Online TOC, bookmark and narration jumps load the target and use the shared
vertical restore. They do not animate two overlapping positioned lists, which
can mount the same keyed chapter cells twice. The pending target offset remains
authoritative if navigation is interrupted by backgrounding.

Implementation: `native_reader_page.dart`, `native_reader_scaffold.dart`,
`native_reader_continuous_layout.dart`, `native_reader_vertical_paging.dart`,
`book_source_reader_page.dart`, `book_source_reader_shell.dart`,
`book_source_reader_vertical_paging.dart` and
`book_source_reader_chapter_loading.dart` and `book_source_reader_settings.dart`
under `lib/pages/reader/`.
Run the lifecycle cases in `test/native_reader_txt_title_page_test.dart` and
`test/book_source_reader_page_test.dart` separately from other stateful suites,
then the vertical TOC/saved-anchor cases, native EPUB initial-position cases,
online chapter recovery and aloud navigation guard suites. Controlled widget
metrics are regression evidence; the reported book/source and repeated app
switches still require physical-device UI acceptance. Source fetching and cache
budgets are unchanged by this restore contract.

Historical validation: [2026-10-09 iOS vertical reading position](reviews/2026-10-09-ios-vertical-reading-position.md).

## Online chapter preparation

The next chapter's content request starts while the current chapter is being read, ahead of farther look-ahead requests. Adjacent page previews read prepared layouts only. They never measure a whole chapter from a widget build.

Synchronous current-page layout and asynchronous chapter preparation share `NativeTextPaginator.paginatePages` and the same text projection. Preparation yields between pages, waits for active pointer gestures and animation frames to finish, and reuses one pending layout per chapter. On-demand chapter navigation awaits that same preparation; it does not start another synchronous layout. Content, layout settings, viewport, and cache-epoch changes discard obsolete results before publication. Disposing the reader cancels its pending yield timer and releases its waiters.

Horizontal chapter handoff explicitly requests the frame needed to commit after scrolling settles. Cover turns retain their participating snapshots and callbacks until completion, so a newly prepared adjacent page cannot cancel an in-progress gesture. A delayed source response finishes the pending chapter turn without requiring a second swipe.

## Maintenance source map

| Boundary | Implementation |
| --- | --- |
| Online reader composition and persisted shelf identity | [online_reader_factory.dart](../lib/pages/reader/book_source/online_reader_factory.dart) |
| Parallel startup, purification gates, shelf lookup and annotations | [book_source_reader_catalog_loading.dart](../lib/pages/reader/book_source/book_source_reader_catalog_loading.dart) |
| Chapter window, foreground loading and prefetch | [book_source_reader_chapter_loading.dart](../lib/pages/reader/book_source/book_source_reader_chapter_loading.dart) |
| Chapter/catalog memory, disk reads, flights and clear generation | [book_source_chapter_cache.dart](../lib/book_sources/caching/book_source_chapter_cache.dart) |
| Reading-source cache revision and required runtime catalog state | [reading_source_backend.dart](../lib/book_sources/protocol/reading_source/reading_source_backend.dart) |
| Shared pagination identity, byte/entry budgets and revision guards | [pagination_cache_dao.dart](../lib/services/books/pagination_cache_dao.dart) |
| Shared page-boundary encoding | [reader_pagination_cache_codec.dart](../lib/core/reader/reader_pagination_cache_codec.dart) |
| Owned cache clearing and usage | [cache_management_service.dart](../lib/services/core/cache_management_service.dart) |
| Disk expiry, quotas and maintenance | [cache_disk_budget.dart](../lib/services/core/cache_disk_budget.dart) |
| Local derived resources and leases | [native_reader_cache_store.dart](../lib/services/books/native_reader_cache_store.dart) |

### Contracts to preserve

1. `BookSourceClient` remains the application facade. Change shared adapters and
   cache contracts rather than adding source-name branches or a second cache.
2. Rules and resolved shelf identity must finish before title/body purification.
   Start independent startup work together; bookmarks and annotations do not
   block first content. Only a shelf record with a persisted id skips lookup;
   failed/null lookups are not cached forever. Later settings updates win.
3. Disk reads share root, kind, content identity and clear generation. Network
   catalog flights additionally include request scope in their key. ORSP passes
   separate interactive/download scopes, as does ReadingSource. A page/download
   cancellation token supplies its own scope for both chapter and catalog
   flights. Freshness and acceptable error fallback remain caller decisions.
4. Keep cold flights and refresh flights distinct. After `releaseMemory()`, a
   caller allowing stale content can read disk while refresh is pending. Store
   only the flight future and refresh marker, not a retained decoded payload.
5. `clearMemory()` advances the generation; OS memory release does not. An old
   read/write cannot repopulate cleared memory, a late disk result cannot replace
   newer memory, and latest-started catalog loads retain winner semantics.
6. A failed early network join may recover acceptable disk data once. It must
   not launch a duplicate retry or replace the original error when no acceptable
   cached entry exists. Preserve legacy-image rejection and catalog error policy.
7. Cached chapter models do not establish runtime script state. Before an
   **uncached** reading-source chapter, retain `_ensureRuntimeCatalog` and its
   state checks for book/rule variables and the next chapter boundary. Cached
   chapter content remains readable offline without forcing this initialization.
8. Cache identity includes source rules, relevant variables and login revision.
   If parsing semantics change, inspect revision invalidation and boundary tests;
   never reuse old incompatible chapter content merely to make loading faster.
9. Pagination stores boundaries, not duplicate text. Layout changes invalidate
   derived pagination; user books, downloads, progress, notes and credentials are
   outside cache eviction. Preserve active-resource leases during clear/eviction.

### Troubleshooting slow or inconsistent opening

| Observation | Inspect first |
| --- | --- |
| Every reopen fetches again | Source/login/variable revision, expiry, explicit clear and which cache root is used. Different identities are intentional misses. Never log credentials or full authenticated requests. |
| Cached catalog opens quickly, but first uncached chapter waits | Required runtime catalog/script initialization, then source response, WebView challenge and parsing. Do not remove chapter-boundary restoration to hide the wait. |
| Equivalent callers each read disk | Shared disk-read key and generation; cold flight joining before another disk wait. |
| Reopen waits after OS memory pressure | Refresh marker versus cold flight; stale disk data must remain usable during background refresh. |
| Old catalog/body appears after a newer result | Catalog load token, clear epoch, newer-memory preference and reader load serial. |
| Download cancellation affects reading | Backend request scopes, runtime initialization waiters and owned/borrowed client lifecycle. ORSP has distinct catalog scopes; inspect the ReadingSource limitation below. |

Count disk reads/source calls with controlled test gates before changing the
network engine. For real-source timings, distinguish cache hits, cold fetch,
runtime initialization, parsing and pagination. Record source revision and
conditions without sensitive data. File-download benchmarks and controlled
concurrency tests do not establish book-opening speedup percentages.

### Request lifetime and cooperative source processing

[ORSP catalog loading](../lib/book_sources/protocol/orsp/orsp_book_source_backend.dart)
and [ReadingSource catalog loading](../lib/book_sources/protocol/reading_source/reading_source_backend.dart)
pass distinct owner scopes to the shared cache. Chapter network flights follow
the same rule. Within one scope equivalent loads still coalesce; cross-scope
requests share disk/memory entries and preserve the latest-started write winner.
ReadingSource's required runtime catalog initializer counts its waiters: one
cancelled waiter leaves the other active, and the last departing waiter cancels
the internal runtime request before further script processing.

`BookSourceReaderPage` owns one token for its catalog, foreground chapters,
adjacent prefetch and narration requests. Confirmed exit cancels that token
before awaiting progress persistence; actual pop and disposal also cancel it.
Cancelling the exit dialog keeps the page usable. Failed persistence or a route
that remains mounted restores a token and retries unfinished loading. A reader
never closes a borrowed client to cancel its own requests, and late responses
cannot publish page content or layout state.

Compatible catalog extraction checks cancellation between fields and chapters,
and yields to the event loop after a bounded batch or elapsed processing budget.
The final chapter-context loop follows the same rule; only completed catalogs
publish their parsed identity. This makes cancellation and input events reachable
even for large catalogs whose rules do not invoke asynchronous JavaScript.
Individual synchronous selector/native operations remain atomic.

`SourceScriptBootstrap` caches only source-invariant shared-library preparation,
keyed by the complete original `jsLib` content and limited to 16 LRU entries.
Changing a library immediately uses a fresh preparation. Book/chapter data,
variables, current scripts and login/session payloads are encoded per invocation.
The catch guard reads the original source position without repeatedly copying
the accumulated output. This cache does not alter content cache identity;
dynamic login/session payloads never enter its key or value.

### Regression entry points

| Changed responsibility | Run in separate Flutter processes |
| --- | --- |
| Shared reads, flights, clear and memory pressure | [book_source_cache_concurrency_test.dart](../test/book_source_cache_concurrency_test.dart), [book_source_chapter_cache_test.dart](../test/book_source_chapter_cache_test.dart) |
| Startup, shelf identity and purification gates | [online_reader_startup_test.dart](../test/online_reader_startup_test.dart); relevant named cases in [book_source_reader_page_test.dart](../test/book_source_reader_page_test.dart) |
| Runtime chapter boundaries, source/login identity and cancellation | [reading_source_cached_catalog_boundary_test.dart](../test/reading_source_cached_catalog_boundary_test.dart), [reading_source_chapter_cache_test.dart](../test/reading_source_chapter_cache_test.dart), [orsp_catalog_request_isolation_test.dart](../test/orsp_catalog_request_isolation_test.dart) |
| Pagination storage, encoding and reopen | [pagination_cache_dao_test.dart](../test/pagination_cache_dao_test.dart), [reader_pagination_cache_codec_test.dart](../test/reader_pagination_cache_codec_test.dart), [book_source_pagination_persistence_test.dart](../test/book_source_pagination_persistence_test.dart) |
| Budgets, clearing and local resource leases | [cache_disk_budget_test.dart](../test/cache_disk_budget_test.dart), [cache_management_service_test.dart](../test/cache_management_service_test.dart) |

For online startup/shared-cache changes, the first checks are:

```sh
flutter test --no-pub test/book_source_cache_concurrency_test.dart
flutter test --no-pub test/online_reader_startup_test.dart
flutter test --no-pub test/reading_source_cached_catalog_boundary_test.dart
flutter test --no-pub test/book_source_reader_request_cancellation_test.dart
flutter test --no-pub test/source_runtime_catalog_cancellation_test.dart
flutter test --no-pub test/source_script_bootstrap_preparation_test.dart
```

Then select the tests for affected boundaries, analyze the changed Dart files
with the project Flutter SDK, and run `git diff --check`. Do not combine stateful
reader suites when process-global state can leak. Documentation-only maintenance
checks links and source/test paths; it does not rebuild or reinstall the app.

## Dated evidence and retired plans

Initial local/online storage unification was integrated on 2026-09-05; its
completed task list has been removed. Keep the implemented budgets, migration,
identity and resource-ownership contracts above as the maintenance reference.

- [2026-10-07 reliability validation](reviews/2026-10-07-reader-reliability-validation.md)
  records retry, runtime catalog state and cancellation fixes for that snapshot.
- [2026-10-08 loading validation](reviews/2026-10-08-online-book-loading-validation.md)
  records startup/cache concurrency tests and the coordinated device package.
- [2026-10-08 source-exit ANR investigation](reviews/2026-10-08-source-exit-anr-validation.md)
  records the Android trace, request lifetime repairs and attribution limits.

Superseded local-only pagination, ownership and cache/startup task lists have
been removed after their useful contracts were consolidated into this guide and
the [book-source architecture](../lib/book_sources/README.md). Their old schemas,
worktree instructions and unchecked steps are not current implementation work.
Original plans remain recoverable from Git or the saved worktree snapshot;
validation records retain unique failures, limits and delivery evidence.
