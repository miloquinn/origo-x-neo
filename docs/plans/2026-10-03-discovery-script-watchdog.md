# Discovery script responsiveness

Plan before implementation:
1. Reproduce CPU-bound source execution in an isolated Android probe without
   replacing the user's installed reader. Add cancellation regressions first.
2. Repair the synchronous QuickJS execution boundary with an engine interrupt
   deadline covering evaluation and pending Promise jobs. Dart Future timeouts
   cannot interrupt synchronous FFI. Reuse the existing runtime/host contracts;
   do not add a dependency or change source rules by name.
3. Check cancellation before starting or replaying a source script. Preserve
   network replay, per-source state, nested calls, and runtime recovery.
4. Run isolated script/controller/widget regressions, static analysis, Android
   native watchdog/recovery checks and an Android product build.

Confirmed code defect: Android rules execute synchronously on the UI isolate
with no enforced execution budget. The upstream native timeout initializes a
start field to zero but never arms it at evaluation/pending-job entry.

The reported user's precise trigger remains unknown without their version,
source and ANR trace. No recent matching ANR was retained on the connected phone.

## Implementation

- `lib/book_sources/source_engine/scripting/source_quickjs_runtime.dart` adds
  an Android-only 500 ms native QuickJS interrupt. Nested calls and a complete
  pending-job drain share a monotonic deadline. Timer callbacks use the same
  guard; disposal cancels owned timers and releases native/Dart callback state.
- `lib/book_sources/source_engine/scripting/source_script_engine.dart` shares
  runtime creation/replacement, rebuilds after execution interruption, checks
  cancellation before execution/replay, and yields the event loop between
  asynchronous script attempts.
- `lib/pages/book_sources/controllers/book_sources_state.dart` reuses frozen
  collections during unrelated updates and untouched lists during partial
  replacements. The public constructor retains defensive immutability.
- `test/source_script_cancellation_test.dart` and
  `test/book_sources_state_test.dart` add regressions; both relevant regression
  pairs failed against the old implementations before the fixes.
- `tool/source_script_watchdog_probe.dart` is a reproducible native probe.
  This document and `2026-10-03-discovery-state-performance.md` record the plan
  and validation. No dependency, version, source-specific branch or release
  configuration was added.

## Verification

2026-10-03, connected Android PKT110, separate app id
`com.origo.debug.runtime_probe` (the installed reader was not replaced):

| Probe | Result |
| --- | --- |
| Upstream `QuickJsRuntime2(timeout: 500)`, finite 1.5 s loop | Still ran 1,523 ms; confirms upstream timeout is inert |
| Infinite synchronous loop | Interrupted in 507 ms; normal script recovery passed |
| Infinite Promise callback | Interrupted in 513 ms; recovery passed |
| Infinite chain of tiny microtasks | Interrupted in 511 ms; recovery passed |
| Infinite timer callback | Interrupted in 516 ms; recovery passed |
| Timer scheduled before interrupted runtime replacement | Cancelled; no stale source-state write |
| Global host callback registry after repeated replacements | Stable; no accumulated callbacks |
| Tap after watchdog failures (previous repeated run) | `Touch response 0` advanced to `Touch response 1` |

The native probe uses the repository lockfile and existing Android build
configuration in a temporary harness. Its setup adds a path dependency on
this repository and copies the probe into `lib/main.dart`; build with
`flutter build apk --debug --target-platform android-arm64
--dart-define=ORIGO_PROBE_INFINITE=true`. Use a distinct app id to protect the
installed reader. The finite baseline is intentional; never run the infinite
cases against the unguarded upstream runtime.

The final native execution/recovery rerun passed all cases. Its subsequent UI
lookup observed Google Play in the foreground, so that final tap check could
not run; the earlier touch verification above is the confirmed evidence. The
probe was uninstalled and the reader remained at version 2.7.2+260928006.

Targeted Flutter validation: 155 passed across script compatibility/runtime,
cancellation, discovery controllers/state/batches/architecture and three
discovery widget scenarios. Stateful discovery scenarios ran separately:
fast/slow sources, rapid source/layout changes and large lazy channel lists.
The opt-in state benchmark was enabled, so its diagnostic test also ran.

Changed-file analysis: no issues. Whole-repository analysis reports eight
unrelated existing lint infos in source chapter/cookie and reader files plus
an offline-license test; no analyzer error or warning. Android arm64 Debug
product build passed. No release publication or affected-user reproduction
was performed.

## Limits

- QuickJS interruptions do not preempt synchronous Dart host callbacks (DOM,
  regex or crypto) or other Dart parsing before they return. This repair bounds
  QuickJS loops/jobs; it does not claim all source work is off the UI isolate.
- The adapter uses flutter_js 0.8.7's public but undocumented `runtimeOpaques`
  registry to acquire the native handle. Preserve native Android watchdog tests
  when upgrading the dependency. All four bundled Android ABIs export the
  interrupt symbol; execution was physically tested on arm64 only.
- The 500 ms budget may reject unusually CPU-heavy source scripts. Such sources
  should be inspected rather than restoring unbounded UI-thread execution.

Upstream describes the synchronous FFI execution model in its
[README](https://github.com/abner/flutter_js).
