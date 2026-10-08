import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/book_source_chapter_cache.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';

void main() {
  setUp(BookSourceChapterCache.clearMemory);

  for (final catalog in [false, true]) {
    final kind = catalog ? 'catalog' : 'chapter';

    test('concurrent cold $kind requests share one disk read', () async {
      final gate = Completer<void>();
      addTearDown(() => _release(gate));
      var reads = 0;
      var loads = 0;
      final cache = BookSourceChapterCache(
        beforeDiskRead: () {
          reads++;
          return gate.future;
        },
        beforeDiskWrite: _noDisk,
      );
      Future<Object> request() => _request(cache, catalog, () async {
        loads++;
      });

      final first = request();
      final second = request();
      await Future<void>.delayed(Duration.zero);
      final concurrentReads = reads;
      _release(gate);
      await Future.wait([first, second]);

      expect(concurrentReads, 1);
      expect(loads, 1);
    });

    test('a pending $kind load is joined before another disk read', () async {
      final started = Completer<void>();
      final gate = Completer<void>();
      addTearDown(() => _release(gate));
      var reads = 0;
      var loads = 0;
      final cache = BookSourceChapterCache(
        beforeDiskRead: () async {
          reads++;
          throw const FileSystemException('memory-only test');
        },
        beforeDiskWrite: _noDisk,
      );
      Future<Object> request() => _request(cache, catalog, () async {
        loads++;
        _release(started);
        await gate.future;
      });

      final first = request();
      await started.future;
      final second = request();
      await Future<void>.delayed(Duration.zero);
      final pendingReads = reads;
      _release(gate);
      await Future.wait([first, second]);

      expect(pendingReads, 1);
      expect(loads, 1);
    });

    test('cache clear separates active $kind disk reads by epoch', () async {
      final gate = Completer<void>();
      addTearDown(() => _release(gate));
      var reads = 0;
      var loads = 0;
      final cache = BookSourceChapterCache(
        beforeDiskRead: () async {
          reads++;
          if (reads == 1) await gate.future;
          throw const FileSystemException('memory-only test');
        },
        beforeDiskWrite: _noDisk,
      );
      Future<Object> request() => _request(cache, catalog, () async {
        loads++;
      });

      final old = request();
      await Future<void>.delayed(Duration.zero);
      BookSourceChapterCache.clearMemory();
      await request();
      expect(reads, 2);
      expect(loads, 1);
      _release(gate);
      await old;
      await request();
      expect(loads, 2, reason: 'the old epoch must not replace fresh memory');
    });

    test(
      'failed pending $kind refresh recovers disk without retrying',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          '$kind-offline-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final gate = Completer<void>();
        final started = Completer<void>();
        addTearDown(() => _release(gate));
        var missDisk = false;
        final cache = BookSourceChapterCache(
          cacheDirectory: directory,
          beforeDiskRead: () async {
            if (missDisk) await _noDisk();
          },
        );
        await _request(cache, catalog, () async {});
        await _waitForCacheFile(directory);
        BookSourceChapterCache.releaseMemory();
        missDisk = true;
        final error = StateError('source offline');
        final refresh = _request(
          cache,
          catalog,
          () async {
            _release(started);
            await gate.future;
            throw error;
          },
          refreshAfter: Duration.zero,
          staleWhileRevalidate: false,
        );
        final failure = expectLater(refresh, throwsA(same(error)));
        await started.future;
        missDisk = false;
        var retries = 0;
        final reader = _request(cache, catalog, () async {
          retries++;
          throw StateError('must not retry a joined failing request');
        }, refreshAfter: Duration.zero);
        await Future<void>.delayed(Duration.zero);
        _release(gate);
        await failure;

        final result = await reader;
        expect(
          catalog
              ? (result as List<BookSourceChapter>).single.title
              : (result as BookSourceChapterContent).content,
          catalog ? 'title' : 'body',
        );
        expect(retries, 0);
      },
    );
  }

  for (final catalog in [false, true]) {
    final kind = catalog ? 'catalog' : 'chapter';
    test(
      'SWR $kind disk hits do not wait for a pending background refresh',
      () async {
        final directory = await Directory.systemTemp.createTemp('$kind-swr-');
        addTearDown(() => directory.delete(recursive: true));
        final started = Completer<void>();
        final gate = Completer<void>();
        final finished = Completer<void>();
        addTearDown(() => _release(gate));
        final cache = BookSourceChapterCache(cacheDirectory: directory);
        await _request(cache, catalog, () async {});
        await _waitForCacheFile(directory);
        await _request(cache, catalog, () async {
          _release(started);
          await gate.future;
          _release(finished);
        }, refreshAfter: Duration.zero);
        await started.future;
        BookSourceChapterCache.releaseMemory();
        try {
          await _request(cache, catalog, () async {
            throw StateError('must reuse cache or the pending refresh');
          }).timeout(const Duration(seconds: 2));
          expect(gate.isCompleted, isFalse);
        } finally {
          _release(gate);
          await finished.future;
        }
      },
    );

    test('shared $kind disk reads keep each caller freshness policy', () async {
      final directory = await Directory.systemTemp.createTemp(
        '$kind-freshness-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final readGate = Completer<void>();
      final refreshGate = Completer<void>();
      addTearDown(() {
        _release(readGate);
        _release(refreshGate);
      });
      var holdReads = false;
      var reads = 0;
      var refreshes = 0;
      final cache = BookSourceChapterCache(
        cacheDirectory: directory,
        beforeDiskRead: () async {
          if (!holdReads) return;
          reads++;
          await readGate.future;
        },
        beforeDiskWrite: () async {
          if (holdReads) await _noDisk();
        },
      );
      await _request(cache, catalog, () async {});
      await _waitForCacheFile(directory);
      BookSourceChapterCache.releaseMemory();
      holdReads = true;
      final reader = _request(cache, catalog, () async {
        throw StateError('a fresh disk entry should not trigger a load');
      });
      final forced = _request(
        cache,
        catalog,
        () async {
          refreshes++;
          await refreshGate.future;
        },
        refreshAfter: Duration.zero,
        staleWhileRevalidate: false,
      );
      await Future<void>.delayed(Duration.zero);
      _release(readGate);
      await reader;
      await Future<void>.delayed(Duration.zero);
      expect(reads, 1);
      expect(refreshes, 1);
      _release(refreshGate);
      await forced;
    });

    test(
      'failed pending $kind load preserves its error without disk',
      () async {
        final gate = Completer<void>();
        final started = Completer<void>();
        addTearDown(() => _release(gate));
        final cache = BookSourceChapterCache(
          beforeDiskRead: _noDisk,
          beforeDiskWrite: _noDisk,
        );
        final error = StateError('original source failure');
        final first = _request(cache, catalog, () async {
          _release(started);
          await gate.future;
          throw error;
        });
        final failure = expectLater(first, throwsA(same(error)));
        await started.future;
        var retries = 0;
        final reader = _request(cache, catalog, () async {
          retries++;
          throw StateError('must not retry');
        });
        final readerFailure = expectLater(reader, throwsA(same(error)));
        await Future<void>.delayed(Duration.zero);
        _release(gate);
        await Future.wait([failure, readerFailure]);
        expect(retries, 0);
      },
    );
  }

  for (final acceptsError in [true, false]) {
    test(
      'joined catalog failure respects staleErrorTest=$acceptsError',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'catalog-error-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final gate = Completer<void>();
        final started = Completer<void>();
        addTearDown(() => _release(gate));
        final cache = BookSourceChapterCache(cacheDirectory: directory);
        await _request(cache, true, () async {});
        await _waitForCacheFile(directory);
        final error = StateError('cancelled or expired authentication');
        final refresh = _request(
          cache,
          true,
          () async {
            _release(started);
            await gate.future;
            throw error;
          },
          refreshAfter: Duration.zero,
          staleWhileRevalidate: false,
        );
        final failure = expectLater(refresh, throwsA(same(error)));
        await started.future;
        BookSourceChapterCache.releaseMemory();
        var retries = 0;
        final reader = cache.getChapterCatalogOrLoad(
          sourceId: 'source',
          bookId: 'book',
          refreshAfter: Duration.zero,
          staleWhileRevalidate: false,
          staleErrorTest: (received) {
            expect(received, same(error));
            return acceptsError;
          },
          loader: () async {
            retries++;
            throw StateError('must not retry');
          },
        );
        final readerFailure = acceptsError
            ? null
            : expectLater(reader, throwsA(same(error)));
        await Future<void>.delayed(Duration.zero);
        _release(gate);
        await failure;
        if (acceptsError) {
          expect((await reader).single.title, 'title');
        } else {
          await readerFailure;
        }
        expect(retries, 0);
      },
    );
  }

  test(
    'catalog scopes retain independent loaders after a shared disk read',
    () async {
      final gate = Completer<void>();
      addTearDown(() => _release(gate));
      var reads = 0;
      final cache = BookSourceChapterCache(
        beforeDiskRead: () async {
          reads++;
          await gate.future;
          throw const FileSystemException('memory-only test');
        },
        beforeDiskWrite: _noDisk,
      );
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      addTearDown(() {
        _release(firstGate);
        _release(secondGate);
      });
      var loads = 0;
      Future<List<BookSourceChapter>> request(
        Object scope,
        Completer<void> finish,
      ) => cache.getChapterCatalogOrLoad(
        sourceId: 'source',
        bookId: 'book',
        requestScope: scope,
        loader: () async {
          loads++;
          await finish.future;
          return _catalog('$scope');
        },
      );

      final first = request(#reader, firstGate);
      final second = request(#download, secondGate);
      await Future<void>.delayed(Duration.zero);
      _release(gate);
      await Future<void>.delayed(Duration.zero);
      final independentLoads = loads;
      _release(secondGate);
      final secondResult = await second;
      _release(firstGate);
      final firstResult = await first;
      final cached = await cache.getChapterCatalogOrLoad(
        sourceId: 'source',
        bookId: 'book',
        loader: () => throw StateError('latest catalog should remain cached'),
      );

      expect(reads, 1);
      expect(independentLoads, 2);
      expect(firstResult.single.title, 'Symbol("reader")');
      expect(secondResult.single.title, 'Symbol("download")');
      expect(cached.single.title, secondResult.single.title);
    },
  );

  test('a delayed catalog disk read cannot replace newer memory', () async {
    final directory = await Directory.systemTemp.createTemp('catalog-race-');
    addTearDown(() => directory.delete(recursive: true));
    final diskStarted = Completer<void>();
    final allowDisk = Completer<void>();
    final refreshStarted = Completer<void>();
    final allowRefresh = Completer<void>();
    addTearDown(() {
      _release(allowDisk);
      _release(allowRefresh);
    });
    var blockReads = false;
    var blockWrites = false;
    final cache = BookSourceChapterCache(
      cacheDirectory: directory,
      beforeDiskRead: () async {
        if (!blockReads) return;
        _release(diskStarted);
        await allowDisk.future;
      },
      beforeDiskWrite: () async {
        if (blockWrites) await _noDisk();
      },
    );
    await cache.getChapterCatalogOrLoad(
      sourceId: 'source',
      bookId: 'book',
      loader: () async => _catalog('old'),
    );
    await _waitForCacheFile(directory);
    blockWrites = true;
    final refresh = cache.getChapterCatalogOrLoad(
      sourceId: 'source',
      bookId: 'book',
      refreshAfter: Duration.zero,
      staleWhileRevalidate: false,
      requestScope: #refresh,
      loader: () async {
        _release(refreshStarted);
        await allowRefresh.future;
        return _catalog('new');
      },
    );
    await refreshStarted.future;
    BookSourceChapterCache.releaseMemory();
    blockReads = true;
    final reader = cache.getChapterCatalogOrLoad(
      sourceId: 'source',
      bookId: 'book',
      loader: () => throw StateError('fresh memory should be reused'),
    );
    await diskStarted.future;
    _release(allowRefresh);
    expect((await refresh).single.title, 'new');
    _release(allowDisk);

    expect((await reader).single.title, 'new');
    final cached = await cache.getChapterCatalogOrLoad(
      sourceId: 'source',
      bookId: 'book',
      loader: () => throw StateError('new memory should remain cached'),
    );
    expect(cached.single.title, 'new');
  });

  test(
    'different cache roots keep chapter disk reads and memory isolated',
    () async {
      final directory = await Directory.systemTemp.createTemp('chapter-race-');
      final otherRoot = await Directory.systemTemp.createTemp('chapter-other-');
      addTearDown(() => directory.delete(recursive: true));
      addTearDown(() => otherRoot.delete(recursive: true));
      await BookSourceChapterCache(cacheDirectory: directory).getOrLoad(
        sourceId: 'source',
        bookId: 'book',
        chapterId: 'chapter',
        loader: () async => _chapter('old'),
      );
      await _waitForCacheFile(directory);
      BookSourceChapterCache.releaseMemory();
      final diskStarted = Completer<void>();
      final allowDisk = Completer<void>();
      addTearDown(() => _release(allowDisk));
      final cache = BookSourceChapterCache(
        cacheDirectory: directory,
        beforeDiskRead: () {
          _release(diskStarted);
          return allowDisk.future;
        },
        beforeDiskWrite: _noDisk,
      );
      final reader = cache.getOrLoad(
        sourceId: 'source',
        bookId: 'book',
        chapterId: 'chapter',
        loader: () =>
            throw StateError('the original root has a cached chapter'),
      );
      await diskStarted.future;
      final refreshed =
          await BookSourceChapterCache(
            cacheDirectory: otherRoot,
            beforeDiskWrite: _noDisk,
          ).getOrLoad(
            sourceId: 'source',
            bookId: 'book',
            chapterId: 'chapter',
            loader: () async => _chapter('new'),
          );
      expect(refreshed.content, 'new');
      _release(allowDisk);
      expect((await reader).content, 'old');
    },
  );

  test(
    'chapter request scopes isolate work and newest load owns cache',
    () async {
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      final releaseSecond = Completer<void>();
      addTearDown(() {
        _release(releaseFirst);
        _release(releaseSecond);
      });
      final cache = BookSourceChapterCache(
        beforeDiskRead: () async {
          throw const FileSystemException('memory-only test');
        },
        beforeDiskWrite: _noDisk,
      );

      final first = cache.getOrLoad(
        sourceId: 'source',
        bookId: 'book',
        chapterId: 'chapter',
        requestScope: #reader,
        loader: () async {
          _release(firstStarted);
          await releaseFirst.future;
          return _chapter('older');
        },
      );
      await firstStarted.future;
      final second = cache.getOrLoad(
        sourceId: 'source',
        bookId: 'book',
        chapterId: 'chapter',
        requestScope: #download,
        loader: () async {
          _release(secondStarted);
          await releaseSecond.future;
          return _chapter('newer');
        },
      );
      await secondStarted.future;

      _release(releaseSecond);
      expect((await second).content, 'newer');
      _release(releaseFirst);
      expect((await first).content, 'older');

      final cached = await cache.getOrLoad(
        sourceId: 'source',
        bookId: 'book',
        chapterId: 'chapter',
        loader: () => throw StateError('newest result should remain cached'),
      );
      expect(cached.content, 'newer');
    },
  );
}

BookSourceChapterContent _chapter(String body) => BookSourceChapterContent(
  bookId: 'book',
  chapterId: 'chapter',
  title: 'title',
  content: body,
  contentType: 'text/plain',
);

Future<void> _waitForCacheFile(Directory directory) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (directory
        .listSync(recursive: true)
        .any((entry) => entry.path.endsWith('.json'))) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('cache write did not complete');
}

Future<void> _noDisk() async =>
    throw const FileSystemException('memory-only test');

void _release(Completer<void> gate) {
  if (!gate.isCompleted) gate.complete();
}

Future<Object> _request(
  BookSourceChapterCache cache,
  bool catalog,
  Future<void> Function() onLoad, {
  Duration? refreshAfter,
  bool staleWhileRevalidate = true,
}) {
  if (catalog) {
    return cache.getChapterCatalogOrLoad(
      sourceId: 'source',
      bookId: 'book',
      refreshAfter: refreshAfter ?? BookSourceChapterCache.catalogRefreshAfter,
      staleWhileRevalidate: staleWhileRevalidate,
      loader: () async {
        await onLoad();
        return _catalog('title');
      },
    );
  }
  return cache.getOrLoad(
    sourceId: 'source',
    bookId: 'book',
    chapterId: 'chapter',
    refreshAfter: refreshAfter ?? BookSourceChapterCache.chapterRefreshAfter,
    staleWhileRevalidate: staleWhileRevalidate,
    loader: () async {
      await onLoad();
      return const BookSourceChapterContent(
        bookId: 'book',
        chapterId: 'chapter',
        title: 'title',
        content: 'body',
        contentType: 'text/plain',
      );
    },
  );
}

List<BookSourceChapter> _catalog(String title) => [
  BookSourceChapter(id: 'chapter', title: title, order: 0),
];
