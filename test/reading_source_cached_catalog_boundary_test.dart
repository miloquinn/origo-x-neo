import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/caching/book_source_chapter_cache.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/protocol/reading_source/reading_source_backend.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_request.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_runtime_state.dart';

const _bookId = 'https://books.test/book/1';
const _firstId = 'https://books.test/chapter/1';
const _secondId = 'https://books.test/chapter/2';

final _source = ReadingSourceConfig.fromJson({
  'bookSourceName': 'Cached catalog boundary test',
  'bookSourceUrl': 'https://books.test',
  'ruleBookInfo': {'name': 'h1@text'},
  'ruleToc': {
    'chapterList': '#chapters@li',
    'chapterName': 'a@text',
    'chapterUrl': 'a@href',
  },
  'ruleContent': {'content': 'main@html', 'nextContentUrl': 'a.next@href'},
}).toRegisteredSource(enabled: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BookSourceChapterCache.clearMemory();
  });

  test(
    'cached catalog restores chapter boundaries before uncached content',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final transport = _ProbeTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);

      expect(await backend.getChapters(_source, _bookId), hasLength(3));
      expect(transport.events, isEmpty);

      final content = await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );

      expect(content.content, '<main>BODY_ONE</main>');
      expect(transport.events, ['/book/1', '/chapter/1']);
    },
  );

  test(
    'cached catalog does not follow the next chapter into a failing tail',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final transport = _ProbeTransport(brokenTail: true);
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);

      final content = await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
      );

      expect(content.content, '<main>BODY_TWO</main>');
      expect(transport.events, ['/book/1', '/chapter/2']);
    },
  );

  test(
    'catalog initialization restores script state, not only chapter URLs',
    () async {
      final scriptedSource = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Cached catalog state test',
        'bookSourceUrl': 'https://books.test',
        'ruleToc': {
          'chapterList': '#single@li',
          'chapterName': 'a@text@put:{token:a@text}',
          'chapterUrl': 'a@href',
        },
        'ruleContent': {
          'content': 'main@html',
          'nextContentUrl':
              "<js>java.get('token') === 'chapter-token' ? '/page/2' : ''</js>",
        },
      }).toRegisteredSource(enabled: true);
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(scriptedSource, _bookId);
      firstRuntime.close();

      final transport = _ProbeTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(scriptedSource, _bookId);

      final content = await backend.getChapterContent(
        scriptedSource,
        bookId: _bookId,
        chapterId: _firstId,
      );

      expect(content.content, contains('BODY_ONE'));
      expect(content.content, contains('PAGE_TWO'));
      expect(transport.events, ['/book/1', '/chapter/1', '/page/2']);
    },
  );

  test(
    'concurrent uncached chapters share one catalog initialization',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final catalogRelease = Completer<void>();
      final transport = _ProbeTransport(catalogRelease: catalogRelease.future);
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);

      final first = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );
      final second = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
      );
      await _waitFor(
        () => transport.events.where((event) => event == '/book/1').isNotEmpty,
      );
      catalogRelease.complete();
      await Future.wait([first, second]);

      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(1),
      );
    },
  );

  test(
    'adjacent reader chapter variables share one catalog identity',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(
        _source,
        _bookId,
        sourceVariables: const {'token': 'stable'},
      );
      firstRuntime.close();

      final transport = _ProbeTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(
        _source,
        _bookId,
        sourceVariables: const {'token': 'stable'},
      );

      await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
        sourceVariables: const {
          'token': 'stable',
          'chapterIndex': '0',
          'chapterTitle': 'One',
          'bookName': 'Book',
          'bookAuthor': 'Author',
          'bookType': '0',
        },
      );
      await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
        sourceVariables: const {
          'token': 'stable',
          'chapterIndex': '1',
          'chapterTitle': 'Two',
          'bookName': 'Book',
          'bookAuthor': 'Author',
          'bookType': '0',
        },
      );

      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(1),
      );
    },
  );

  test(
    'custom source variables keep catalog runtime identities isolated',
    () async {
      final transport = _ProbeTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);

      await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
        sourceVariables: const {
          'token': 'one',
          'chapterIndex': '0',
          'chapterTitle': 'One',
        },
      );
      await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
        sourceVariables: const {
          'token': 'two',
          'chapterIndex': '0',
          'chapterTitle': 'One',
        },
      );
      await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
        sourceVariables: const {
          'token': 'one',
          'chapterIndex': '1',
          'chapterTitle': 'Two',
        },
      );

      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(3),
      );
    },
  );

  test(
    'failed catalog initialization is retried once by the next request',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final transport = _ProbeTransport(catalogFailures: 1);
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);

      await expectLater(
        backend.getChapterContent(
          _source,
          bookId: _bookId,
          chapterId: _firstId,
        ),
        throwsA(
          isA<BookSourceProtocolException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.isMissingChapter,
                'isMissingChapter',
                isFalse,
              ),
        ),
      );
      final content = await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );

      expect(content.content, '<main>BODY_ONE</main>');
      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(2),
      );
    },
  );

  test(
    'cancelling the download that starts initialization does not cancel a reader',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final catalogRelease = Completer<void>();
      final transport = _ProbeTransport(catalogRelease: catalogRelease.future);
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);
      final cancellation = BookDownloadCancellation();
      final cancelledLoad = backend.getChapterContentForDownload(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
        cancellation: cancellation,
      );
      await _waitFor(
        () => transport.events.where((event) => event == '/book/1').isNotEmpty,
      );
      final readerLoad = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
      );
      cancellation.cancel();
      await expectLater(
        cancelledLoad,
        throwsA(isA<BookDownloadCancelledException>()),
      );

      catalogRelease.complete();
      final content = await readerLoad;

      expect(content.content, '<main>BODY_TWO</main>');
      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(1),
      );
    },
  );

  test(
    'a cancelled follower stops waiting without cancelling the shared reader flight',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final catalogRelease = Completer<void>();
      final transport = _ProbeTransport(catalogRelease: catalogRelease.future);
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);
      final readerLoad = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );
      await _waitFor(
        () => transport.events.where((event) => event == '/book/1').isNotEmpty,
      );
      final cancellation = BookDownloadCancellation();
      final cancelledFollower = backend.getChapterContentForDownload(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
        cancellation: cancellation,
      );
      cancellation.cancel();
      await expectLater(
        cancelledFollower.timeout(const Duration(milliseconds: 200)),
        throwsA(isA<BookDownloadCancelledException>()),
      );

      catalogRelease.complete();
      final content = await readerLoad;

      expect(content.content, '<main>BODY_ONE</main>');
      expect(
        transport.events.where((event) => event == '/book/1'),
        hasLength(1),
      );
    },
  );

  test(
    'force refresh waits for cold initialization and wins final state',
    () async {
      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await _backend(firstRuntime).getChapters(_source, _bookId);
      firstRuntime.close();

      final transport = _OrderedCatalogTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = _backend(runtime);
      await backend.getChapters(_source, _bookId);

      final coldContent = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );
      await transport.firstCatalogStarted.future;
      final refresh = backend.getChaptersForDownload(_source, _bookId);
      final contentDuringRefresh = backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(transport.catalogRequests, 1);

      transport.releaseFirstCatalog.complete();
      await coldContent;
      await transport.secondCatalogStarted.future;
      expect(transport.events, isNot(contains('/chapter/2')));
      transport.releaseSecondCatalog.complete();
      final refreshed = await refresh;
      await contentDuringRefresh;
      expect(refreshed[1].id, 'https://books.test/chapter/new-next');

      transport.events.clear();
      final finalContent = await runtime.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );
      expect(finalContent.content, '<main>BODY_ONE</main>');
      expect(transport.events, ['/chapter/1']);
    },
  );

  test('runtime preserves a structured 404 from custom transports', () async {
    final runtime = SourceRuntime(transport: _ProbeTransport());
    addTearDown(runtime.close);

    await expectLater(
      runtime.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: 'https://books.test/chapter/4',
      ),
      throwsA(
        isA<BookSourceProtocolException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having(
              (error) => error.isMissingChapter,
              'isMissingChapter',
              isTrue,
            ),
      ),
    );
  });

  test(
    'persisted catalog restores boundaries after a process-like reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'reading-source-boundary-',
      );
      addTearDown(() => directory.delete(recursive: true));
      var allowDiskWrite = true;
      ReadingSourceBackend diskBackend(SourceRuntime runtime) =>
          ReadingSourceBackend(
            () => runtime,
            chapterCache: BookSourceChapterCache(
              cacheDirectory: directory,
              beforeDiskWrite: () async {
                if (!allowDiskWrite) {
                  throw const FileSystemException('catalog only');
                }
              },
            ),
            additionalProtocolsEnabled: () async => true,
          );

      final firstRuntime = SourceRuntime(transport: _ProbeTransport());
      await diskBackend(firstRuntime).getChapters(_source, _bookId);
      await _waitFor(
        () => directory
            .listSync(recursive: true)
            .whereType<File>()
            .any((file) => file.path.endsWith('.json')),
      );
      allowDiskWrite = false;
      firstRuntime.close();
      BookSourceChapterCache.clearMemory();

      final transport = _ProbeTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final backend = diskBackend(runtime);
      expect(await backend.getChapters(_source, _bookId), hasLength(3));
      expect(transport.events, isEmpty);

      final content = await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _secondId,
        sourceVariables: const {
          'chapterIndex': '1',
          'chapterTitle': 'Two',
          'bookName': 'Book',
          'bookAuthor': '',
          'bookType': '0',
        },
      );

      expect(content.content, '<main>BODY_TWO</main>');
      expect(transport.events, ['/book/1', '/chapter/2']);
    },
  );

  test(
    'evicted runtime catalog state is initialized again before content',
    () async {
      final transport = _ProbeTransport();
      final runtime = SourceRuntime(
        transport: transport,
        state: SourceRuntimeState(maxRememberedBookStates: 1, maxChapters: 3),
      );
      addTearDown(runtime.close);
      final backend = _backend(runtime);

      await backend.getChapters(_source, _bookId);
      await backend.getChapters(_source, 'https://books.test/book/2');
      transport.events.clear();

      final content = await backend.getChapterContent(
        _source,
        bookId: _bookId,
        chapterId: _firstId,
      );

      expect(content.content, '<main>BODY_ONE</main>');
      expect(transport.events, ['/book/1', '/chapter/1']);
    },
  );
}

ReadingSourceBackend _backend(SourceRuntime runtime) => ReadingSourceBackend(
  () => runtime,
  chapterCache: BookSourceChapterCache(
    beforeDiskRead: () async => throw const FileSystemException('no disk'),
    beforeDiskWrite: () async => throw const FileSystemException('no disk'),
  ),
  additionalProtocolsEnabled: () async => true,
);

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for condition.');
}

class _ProbeTransport implements SourceTransport {
  _ProbeTransport({
    this.brokenTail = false,
    this.catalogFailures = 0,
    this.catalogRelease,
  });

  final bool brokenTail;
  int catalogFailures;
  final Future<void>? catalogRelease;
  final events = <String>[];

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    events.add(request.url.path);
    if (request.url.path == '/book/1') {
      if (catalogRelease != null) {
        await Future.any<void>([
          catalogRelease!,
          if (cancellation != null) cancellation.whenCancelled,
        ]);
        cancellation?.throwIfCancelled();
      }
      if (catalogFailures > 0) {
        catalogFailures--;
        return SourceResponse(
          body: 'forbidden',
          finalUri: request.url,
          statusCode: 403,
        );
      }
    }
    final body = switch (request.url.path) {
      '/book/1' =>
        '''
        <h1>Book</h1>
        <ul id="chapters">
          <li><a href="/chapter/1">One</a></li>
          <li><a href="/chapter/2">Two</a></li>
          <li><a href="/chapter/3">Three</a></li>
        </ul>
        <ul id="single"><li><a href="/chapter/1">chapter-token</a></li></ul>
      ''',
      '/book/2' =>
        '''
        <ul id="chapters">
          <li><a href="/chapter/book-2">Book Two</a></li>
        </ul>
      ''',
      '/chapter/1' =>
        '<main>BODY_ONE</main><a class="next" href="/chapter/2">next</a>',
      '/chapter/2' =>
        '<main>BODY_TWO</main><a class="next" href="/chapter/3">next</a>',
      '/chapter/3' =>
        '<main>BODY_THREE</main>${brokenTail ? '<a class="next" href="/chapter/4">next</a>' : ''}',
      '/page/2' => '<main>PAGE_TWO</main>',
      _ => 'not found',
    };
    return SourceResponse(
      body: body,
      finalUri: request.url,
      statusCode: request.url.path == '/chapter/4' ? 404 : 200,
    );
  }
}

class _OrderedCatalogTransport implements SourceTransport {
  final firstCatalogStarted = Completer<void>();
  final secondCatalogStarted = Completer<void>();
  final releaseFirstCatalog = Completer<void>();
  final releaseSecondCatalog = Completer<void>();
  final events = <String>[];
  int catalogRequests = 0;

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    events.add(request.url.path);
    if (request.url.path == '/book/1') {
      catalogRequests++;
      final current = catalogRequests;
      if (current == 1) {
        firstCatalogStarted.complete();
        await releaseFirstCatalog.future;
      } else if (current == 2) {
        secondCatalogStarted.complete();
        await releaseSecondCatalog.future;
      } else {
        throw StateError('Unexpected catalog request $current.');
      }
      final next = current == 1 ? 'old-next' : 'new-next';
      return SourceResponse(
        body:
            '''
          <ul id="chapters">
            <li><a href="/chapter/1">One</a></li>
            <li><a href="/chapter/$next">Next</a></li>
          </ul>
        ''',
        finalUri: request.url,
      );
    }
    final body = switch (request.url.path) {
      '/chapter/1' =>
        '<main>BODY_ONE</main><a class="next" href="/chapter/new-next">next</a>',
      '/chapter/new-next' => '<main>WRONG_FOLLOWED_NEW_NEXT</main>',
      _ => '<main>OTHER</main>',
    };
    return SourceResponse(body: body, finalUri: request.url);
  }
}
