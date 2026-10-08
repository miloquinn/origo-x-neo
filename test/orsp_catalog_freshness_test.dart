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

  test(
    'refreshes old chapter IDs before sending any content request',
    () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.chapterId = 'new';
      server.events.clear();

      final chapters = await client.getChapters(_source, 'book');
      final content = await client.getChapterContent(
        _source,
        bookId: 'book',
        chapterId: chapters.single.id,
      );

      expect(content.content, 'Body');
      expect(server.events, ['catalog', 'content:new']);
      expect(server.missingContentRequests, 0);
    },
  );

  test('refreshes the server catalog state before using a stable ID', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.catalogReady = false;
    server.events.clear();

    final chapters = await client.getChapters(_source, 'book');
    await client.getChapterContent(
      _source,
      bookId: 'book',
      chapterId: chapters.single.id,
    );

    expect(server.events, ['catalog', 'content:old']);
    expect(server.missingContentRequests, 0);
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
    expect(server.events, ['catalog']);
  });

  test('refreshes persisted catalogs after memory is released', () async {
    final directory = await Directory.systemTemp.createTemp('orsp-fresh-disk-');
    addTearDown(() => directory.delete(recursive: true));
    final server = _SourceServer();
    final client = clientFor(
      server,
      cache: BookSourceChapterCache(cacheDirectory: directory),
    );
    await client.getChaptersForDownload(_source, 'book');
    await _waitForCatalogFile(directory, 'old');
    BookSourceChapterCache.clearMemory();
    server.chapterId = 'new';
    server.events.clear();
    final chapters = await client.getChapters(_source, 'book');
    expect(chapters.single.id, 'new');
    expect(server.events, ['catalog']);
    await _waitForCatalogFile(directory, 'new');
  });

  test('temporary server failure can use cached catalog', () async {
    final server = _SourceServer();
    final client = clientFor(server);
    await client.getChaptersForDownload(_source, 'book');
    server.catalogStatus = 503;
    expect((await client.getChapters(_source, 'book')).single.id, 'old');
  });

  for (final failure in [
    DioExceptionType.cancel,
    DioExceptionType.badCertificate,
  ]) {
    test('does not hide $failure behind stale data', () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.failure = failure;
      await expectLater(
        client.getChapters(_source, 'book'),
        throwsA(isA<BookSourceProtocolException>()),
      );
    });
  }

  for (final status in [401, 404]) {
    test('does not hide catalog HTTP $status behind stale data', () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.catalogStatus = status;

      await expectLater(
        client.getChapters(_source, 'book'),
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

  test(
    'does not hide an invalid refreshed catalog behind stale data',
    () async {
      final server = _SourceServer();
      final client = clientFor(server);
      await client.getChaptersForDownload(_source, 'book');
      server.malformed = true;

      await expectLater(
        client.getChapters(_source, 'book'),
        throwsA(isA<BookSourceProtocolException>()),
      );
    },
  );

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
  bool catalogReady = true;
  bool offline = false;
  bool malformed = false;
  DioExceptionType? failure;
  int catalogStatus = 200;
  int missingContentRequests = 0;
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
      catalogReady = true;
      return _json(
        '{"items":[{"id":"$chapterId","title":"Chapter","order":1}],'
        '"page":1,"pageSize":100,"hasMore":false}',
      );
    }
    final requestedId = options.uri.pathSegments.last;
    events.add('content:$requestedId');
    if (!catalogReady || requestedId != chapterId) {
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
