import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/book_source_chapter_cache.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/networking/book_source_network_policy.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';

void main() {
  setUp(BookSourceChapterCache.clearMemory);

  BookSourceClient clientFor(
    _SourceServer server, {
    BookSourceChapterCache? cache,
  }) {
    final dio = Dio()..httpClientAdapter = server;
    final client = BookSourceClient(
      dio: dio,
      chapterCache:
          cache ??
          BookSourceChapterCache(
            beforeDiskRead: () async =>
                throw const FileSystemException('no disk'),
            beforeDiskWrite: () async =>
                throw const FileSystemException('no disk'),
          ),
      networkPolicy: BookSourceNetworkPolicy(
        lookup: (_) async => [InternetAddress('93.184.216.34')],
      ),
    );
    addTearDown(client.close);
    return client;
  }

  test('hot reopen reuses a fresh catalog without a network request', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.events.clear();

    final chapters = await client.getChapters(_source, 'book');

    expect(chapters.single.id, 'old');
    expect(server.events, isEmpty);
  });

  test('forced recovery refreshes changed chapter IDs', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.chapterId = 'new';
    server.events.clear();

    final cached = await client.getChapters(_source, 'book');
    await expectLater(
      client.getChapterContent(
        _source,
        bookId: 'book',
        chapterId: cached.single.id,
      ),
      throwsA(
        isA<BookSourceProtocolException>().having(
          (error) => error.isMissingChapter,
          'missing chapter',
          isTrue,
        ),
      ),
    );
    final chapters = await client.getChaptersForDownload(_source, 'book');
    await client.getChapterContent(
      _source,
      bookId: 'book',
      chapterId: chapters.single.id,
    );

    expect(server.events, ['content:old', 'catalog', 'content:new']);
    expect(server.missingContentRequests, 1);
  });

  test('retains a cached catalog when the source connection fails', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    await client.getChapterContent(_source, bookId: 'book', chapterId: 'old');
    server.offline = true;
    server.events.clear();

    final chapters = await client.getChapters(_source, 'book');
    final content = await client.getChapterContent(
      _source,
      bookId: 'book',
      chapterId: chapters.single.id,
    );

    expect(chapters.single.id, 'old');
    expect(content.content, 'Body');
    expect(server.events, isEmpty);
  });

  test(
    'cold reopen reuses a fresh persisted catalog without network',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'orsp-fresh-disk-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final server = _SourceServer();
      final client = clientFor(
        server,
        cache: BookSourceChapterCache(cacheDirectory: directory),
      );
      await client.getChaptersForDownload(_source, 'book');
      await _waitForCatalogFile(directory, 'old');
      BookSourceChapterCache.clearMemory();
      server.events.clear();
      final chapters = await client.getChapters(_source, 'book');
      expect(chapters.single.id, 'old');
      expect(server.events, isEmpty);
    },
  );

  test(
    'stale disk catalog opens before its background refresh completes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'orsp-stale-disk-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final server = _SourceServer();
      final client = clientFor(
        server,
        cache: BookSourceChapterCache(cacheDirectory: directory),
      );
      await client.getChaptersForDownload(_source, 'book');
      await _waitForCatalogFile(directory, 'old');
      final catalogFile = await _catalogFile(directory);
      await catalogFile.setLastModified(
        DateTime.now().subtract(const Duration(minutes: 31)),
      );
      BookSourceChapterCache.releaseMemory();
      server.chapterId = 'new';
      server.catalogGate = Completer<void>();
      server.events.clear();

      final chapters = await client.getChapters(_source, 'book');
      await _waitForEvent(server, 'catalog');

      expect(chapters.single.id, 'old');
      expect(server.events, ['catalog']);
      expect(server.catalogGate!.isCompleted, isFalse);
      server.catalogGate!.complete();
      await _waitForCatalogFile(directory, 'new');
    },
  );

  for (final failure in const [
    (name: 'HTTP 401', status: 401, malformed: false),
    (name: 'HTTP 404', status: 404, malformed: false),
    (name: 'malformed response', status: 200, malformed: true),
  ]) {
    test(
      'stale interactive catalog survives ${failure.name}; forced refresh reports it',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'orsp-stale-error-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final server = _SourceServer();
        final client = clientFor(
          server,
          cache: BookSourceChapterCache(cacheDirectory: directory),
        );
        await client.getChaptersForDownload(_source, 'book');
        await _waitForCatalogFile(directory, 'old');
        await (await _catalogFile(directory)).setLastModified(
          DateTime.now().subtract(const Duration(minutes: 31)),
        );
        BookSourceChapterCache.releaseMemory();
        server.catalogStatus = failure.status;
        server.malformed = failure.malformed;
        server.events.clear();

        final cached = await client.getChapters(_source, 'book');
        await _waitForEvent(server, 'catalog');

        expect(cached.single.id, 'old');
        await expectLater(
          client.getChaptersForDownload(_source, 'book'),
          throwsA(isA<BookSourceProtocolException>()),
        );
      },
    );
  }

  test('offline unread chapter still surfaces the source failure', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.offline = true;
    expect((await client.getChapters(_source, 'book')).single.id, 'old');
    await expectLater(
      client.getChapterContent(
        _source,
        bookId: 'book',
        chapterId: 'not-cached',
      ),
      throwsA(isA<BookSourceProtocolException>()),
    );
  });

  for (final failure in [
    DioExceptionType.cancel,
    DioExceptionType.badCertificate,
  ]) {
    test('forced refresh surfaces $failure', () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.failure = failure;
      await expectLater(
        client.getChaptersForDownload(_source, 'book'),
        throwsA(isA<BookSourceProtocolException>()),
      );
    });
  }

  for (final status in [401, 404]) {
    test('forced refresh surfaces catalog HTTP $status', () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.catalogStatus = status;

      await expectLater(
        client.getChaptersForDownload(_source, 'book'),
        throwsA(
          isA<BookSourceProtocolException>().having(
            (error) => error.statusCode,
            'status',
            status,
          ),
        ),
      );
    });
  }

  test('forced refresh surfaces an invalid catalog', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.malformed = true;

    await expectLater(
      client.getChaptersForDownload(_source, 'book'),
      throwsA(isA<BookSourceProtocolException>()),
    );
  });

  test('forced download catalog never falls back to stale data', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.offline = true;

    await expectLater(
      client.getChaptersForDownload(_source, 'book'),
      throwsA(isA<BookSourceProtocolException>()),
    );
  });
}

final _source = RegisteredBookSource(
  id: 'catalog.freshness.test',
  name: 'Catalog freshness test',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

class _SourceServer implements HttpClientAdapter {
  String chapterId = 'old';
  bool offline = false;
  bool malformed = false;
  DioExceptionType? failure;
  int catalogStatus = 200;
  int missingContentRequests = 0;
  Completer<void>? catalogGate;
  final events = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final catalog = options.uri.path.endsWith('/chapters');
    if (catalog) {
      events.add('catalog');
      await catalogGate?.future;
      if (failure case final type?) {
        throw DioException(requestOptions: options, type: type);
      }
      if (offline) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('Offline'),
        );
      }
      if (catalogStatus != 200) {
        return _json(
          '{"error":{"code":"${catalogStatus == 401
              ? 'LOGIN_REQUIRED'
              : catalogStatus >= 500
              ? 'UNAVAILABLE'
              : 'BOOK_NOT_FOUND'}","message":"catalog unavailable"}}',
          catalogStatus,
        );
      }
      if (malformed) return _json('{"items":"invalid"}');
      return _json(
        '{"items":[{"id":"$chapterId","title":"Chapter","order":1}],'
        '"page":1,"pageSize":100,"hasMore":false}',
      );
    }
    final requestedId = options.uri.pathSegments.last;
    events.add('content:$requestedId');
    if (requestedId != chapterId) {
      missingContentRequests++;
      return _json(
        '{"error":{"code":"CHAPTER_NOT_FOUND","message":"chapter not found"}}',
        404,
      );
    }
    return _json(
      '{"bookId":"book","chapterId":"$chapterId","title":"Chapter",'
      '"contentType":"text/plain","content":"Body"}',
    );
  }

  ResponseBody _json(String body, [int status = 200]) =>
      ResponseBody.fromString(
        body,
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}

Future<void> _waitForCatalogFile(Directory directory, String id) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final files = await directory
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    for (final file in files) {
      if ((await file.readAsString()).contains('"id":"$id"')) return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Catalog was not persisted');
}

Future<File> _catalogFile(Directory directory) async {
  final files = await directory
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.json'))
      .cast<File>()
      .toList();
  return files.singleWhere((file) => file.parent.path.endsWith('catalogs'));
}

Future<void> _waitForEvent(_SourceServer server, String event) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (server.events.contains(event)) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Expected source event: $event');
}
