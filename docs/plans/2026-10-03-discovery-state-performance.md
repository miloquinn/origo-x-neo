# Discovery state performance

## Scope

- Keep `BookSourcesState`'s public constructor defensively immutable, including
  nested source and channel lists.
- Make `copyWith` reuse every unchanged frozen collection instead of rebuilding
  large discovery payloads for query, expansion, and loading-state updates.
- When one nested list changes, freeze that replacement while retaining the
  already-frozen lists for untouched map entries.

## Regression coverage

- Lock constructor immutability for every exposed collection and nested list.
- Verify a query-only update preserves collection identity for a synthetic
  2,000-source, 50-channel-per-source state.
- Verify replacing one source's channel list does not copy another source's
  channel list, while the replacement remains defensively frozen.
- Record an opt-in 200-update synthetic benchmark without timing assertions.

## Verification

- Run the new state tests alone before and after the implementation.
- Format and analyze the modified implementation and test.

Completed: regression-first failures for query identity and untouched nested
list identity; all four new tests (including the opt-in diagnostic) and all
28 existing controller tests passed. Changed-file analysis found no issues.

Synthetic 2,000 sources × 50 channels, 200 query-only state updates:
131.711 ms before, 0.879 ms after in the initial comparison; a subsequent warm
run measured 0.181 ms. These are state-update diagnostics, not device frame
timings or whole-page speedups. Identity and immutability assertions protect
the optimization without machine-dependent timing thresholds.
