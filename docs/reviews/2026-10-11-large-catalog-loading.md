# Large HTML catalog loading validation — 2026-10-11

Historical validation of this change. The current contract and maintenance
entry points are in [Reading cache](../reading-cache.md).

## Problem and change

The user reported slow first opening of an online book with roughly 7000
chapters. The exact reported book/source is not available yet. A controlled HTML
catalog reproduced sharply increasing parsing cost: each chapter's title and
URL rule called `sourceHtmlMatches`, which queried the entire parent subtree
before testing membership. Ordinary `a@text` / `a@href` rules consequently
repeated work across the complete catalog.

`lib/book_sources/source_engine/rules/source_rule_html.dart` now queries a
read-only single-element fragment view through the existing html package's
public DOM API. The view exposes the real element without appending, cloning or
reparenting it, so ancestor/sibling/positional selectors still use the original
DOM. There is no matching cache, new dependency, source-name branch, chapter
limit or change to request ownership. Detached-root compatibility is preserved.
The content-cache rule revision stays 7.

Invalid CSS and unsupported CSS that is actually evaluated still propagate to
the existing protocol error boundary. One intentional narrow difference is
covered: a directly matching selector-group branch no longer fails because
unsupported CSS was evaluated on an unrelated earlier sibling.

## Controlled timings

Same machine, same isolated Flutter test fixture and rules, one measurement per
size, zero-latency transport with exactly one catalog request. Each complete
runtime measurement verifies all chapter IDs/order and unique IDs, plus
first/middle/last next-chapter boundaries before closing the runtime.

| Chapters | Complete runtime before | Complete runtime after |
| --- | ---: | ---: |
| 500 | 472.847 ms | 254.696 ms |
| 2000 | 2961.148 ms | 277.493 ms |
| 7000 | 24145.051 ms | 614.516 ms |

A final repeat after the adapter's field-override lint repair measured 180.850,
233.659 and 529.619 ms respectively. Both after-change runs are retained;
the 7000-row result was approximately 0.53–0.61 seconds.

The separate field-extraction diagnostic after the change measured 337.313 ms
for 7000 rows and 872.883 ms for 14000 rows. These are desktop parser/runtime
measurements, not physical-phone opening or first-paint timings. Network,
source scripts, WebView challenges and rendering can still dominate other
books. Complex positional/sibling selectors retain their required traversal.

Reproduction and raw logs are local ignored validation artifacts under
`build/validation/large-catalog-20261010/`: `runtime/catalog_benchmark_test.dart`,
`runtime/catalog_runtime_verified.log`, and
`tests/catalog_benchmark_test-after.log` and `tests/catalog-benchmark-final.log`.
The directory date records the start
of the investigation; implementation validation completed after midnight.

## Behavior and verification

The original matching behavior was locked before production edits. Expanded
baseline: ten cases passed, while the parent-scan guard and unrelated unsupported
sibling case failed as expected. All twelve matching cases pass after the
change. Coverage includes tag/class/attribute/group selectors, ancestors,
children, adjacent/general siblings, first/last/nth-child, `:not`, live attribute
mutations, root inclusion/order, detached and Document roots, CSS error
translation, JSoup marker cleanup on success/error, and unchanged node topology.

The 7000-row runtime regression checks every title, ID, order and next-chapter
boundary, including the final empty boundary. Existing cooperative cancellation
and request-ownership assertions remain active.

Twenty-one suites/diagnostics ran in separate Flutter processes and passed,
covering 221 test cases: all `source_rule_*_test.dart` files, runtime catalog
cancellation, complete source runtime, cached catalog boundaries, chapter cache,
reader recovery, aloud chapter transitions, reader request cancellation and
online startup, plus the controlled benchmark. The first complete runtime
attempt suffered a `flutter_tester` segmentation fault at its first case; that
case passed alone and all 37 cases passed on a fresh full-suite retry. Both
attempt logs are retained. Assertions were not removed or skipped.

The production matcher also compiled and passed a twelve-selector/topology
probe with locked html 0.15.6 and with a separate package configuration pointing
to html 0.15.7. The application dependency files were not modified.

Formatting, document links and `git diff --check` pass. Scoped Flutter analysis
of all three changed Dart files reports no issues. Full-project analysis reports
six info-level findings outside this change (source chapter state, cookie utils,
vertical reader async context usage and an offline-license test import), with no
errors or warnings. They remain visible in the logs and were not changed as part
of the parser repair. The final getter-based adapter, matching suite and 7000-row
regression were rechecked after fixing its own field-override lint.

A cold production-client probe using a source from the user's book-resource
directory fetched 七猫小说《都市古仙医》: 5761 chapters, complete unique IDs/order,
1061 ms catalog loading (484 ms network), and a readable first chapter of 2422
characters in 175 ms. This source's catalog is JSON, so the probe establishes
continued real-source functionality, not an HTML optimization speedup. It used
an isolated temporary cache and in-memory login store, without installed account
data. The local snapshot is `live-results-after.json` in the validation directory.

## Delivery and limits

Only the HTML matching helper, its new regression file, the large catalog
regression and the current/detailed documentation belong to this change.
Unrelated theme, discovery, book-detail and reader work remains owned by other
active chats. This is a bounded repeated-traversal repair; no general cleanup
or additional architecture layer was introduced. UI/design checks are not
applicable to the parser change.

Device delivery uses the existing sole combined-build owner in
`build/device-ios/coordination.json`, with this source registered as
`largeCatalogLoading`. It must build the combined latest checkout for SloanePro
(iPhone 16 Pro, UDID `00008140-001979421E93001C`) and install in place with the
`direct` acceptance channel. No separate older snapshot may replace that build.
Installation, launch and physical opening-speed acceptance are pending while
the other source owners finalize their shared changes.

Windows synchronization was attempted via `milo-pc`, `milo-pc.local`, `knbook`
and `knbook-lan`; the hosts were unresolved or unreachable. No Windows files
were changed. Product builds and physical UI acceptance remain separate from
the parser/regression evidence above.
