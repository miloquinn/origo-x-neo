# Online reader cache-first reopen validation (2026-10-11)

This record covers the shared reader path used when an online book is opened
from discovery or from the library. It is dated evidence for the recorded
revision; the current contract remains in [Reading cache](../reading-cache.md).

## Root cause and repair

The device already held both catalog and current-chapter files for two recently
read ORSP books. The interactive ORSP catalog call nevertheless used a zero
freshness window with blocking refresh, so every new reader session waited for
the source before the cached chapter could reach the screen. Both discovery and
library entry points converge on this reader initialization, which explains the
same delay from either route.

The interactive ORSP path now uses the existing `BookSourceChapterCache`
freshness and stale-while-revalidate contract. No source-specific branch,
parallel cache or dependency was added. Fresh catalogs reopen from memory or
disk without a request. Catalogs older than 30 minutes are returned first while
one scoped background refresh runs. Download/update calls remain forced, and a
missing cached chapter ID still triggers the reader's one-shot forced catalog
recovery.

ReadingSource already used this shared cache-first policy. Its cache revision
continues to isolate rule configuration, stable source/book variables and login
changes, and uncached chapters still initialize required runtime catalog state.
No unverified ReadingSource implementation change was made.

## Evidence

- Device inventory: `build/release-verification/261011001/cache-device/orsp-cache-identity-check.json`
  matched the canonical cache-key hashes for two recent ORSP catalogs and their
  saved current chapters. These two device records had valid persisted content,
  while the former interactive contract still forced a blocking catalog
  request. The read-only inventory did not modify or clear app data.
- Before: the production startup regression was also run against the blocking
  backend at commit `5a7cccfe3faaa80266881338cef4000bd20fe0d7`. It failed
  while waiting for cached body text with the catalog request held pending.
  Receipts: `build/release-verification/261011001/online-reader-cache/before-real-startup.log`
  and `before-real-startup.json`. The updated startup suite passes all six
  cases, including the same production-backend regression.
- After: controlled hot and fresh-disk reopen make zero catalog requests.
  A catalog aged beyond 30 minutes returns its disk value before a blocked
  background request completes. A widget regression uses the production ORSP
  backend, persisted catalog/body files and a blocked HTTP adapter, then
  observes cached body text on screen before the real background request is
  released.
- Offline cached catalog/body remains readable. An uncached body still surfaces
  the source failure. A stale interactive catalog also remains readable when
  its background refresh receives 401, 404 or malformed data; the corresponding
  forced refresh surfaces each error. Forced refresh preserves cancellation,
  authentication errors and malformed-response errors, while cache identity
  isolation is unchanged.

## Verification boundary

The regressions cover ORSP hot reopen, disk cold reopen, stale background
refresh, missing-ID recovery, offline cached/uncached behavior and the shared
reader startup gate. Existing ReadingSource tests cover disk reopen without a
runtime request plus login and variable isolation. These controlled results do
not claim a measured speedup for every live source; server challenges, rule
execution and first-time pagination remain separate costs. Physical-device UI
acceptance belongs to the combined release installation.
