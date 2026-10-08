import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/book_source_chapter_cache.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/networking/book_source_network_policy.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';

void main() {
  setUp(BookSourceChapterCache.clearMemory);

  test(
    'cancelling an earlier download does not cancel a reader refresh',
    () async {
      final adapter = _ControlledCatalogAdapter();
      final cache = _memoryOnlyCache();
      final client = _client(adapter, cache);
      final cancellation = BookDownloadCancellation();

      final download = client.getChaptersForDownload(
        _source,
        'book',
        cancellation: cancellation,
      );
      await adapter.waitForRequests(1);
      final reader = client.getChapters(_source, 'book');
      await adapter.waitForRequests(2);

      final downloadExpectation = expectLater(
        download,
        throwsA(isA<BookDownloadCancelledException>()),
      );
      cancellation.cancel();
      adapter.interactive.single.complete('reader');

      expect((await reader).single.id, 'reader');
      await downloadExpectation;
    },
  );

  test(
    'a reader refresh does not absorb a later download cancellation',
    () async {
      final adapter = _ControlledCatalogAdapter();
      final cache = _memoryOnlyCache();
      final client = _client(adapter, cache);
      final cancellation = BookDownloadCancellation();

      final reader = client.getChapters(_source, 'book');
      await adapter.waitForRequests(1);
      final download = client.getChaptersForDownload(
        _source,
        'book',
        cancellation: cancellation,
      );
      await adapter.waitForRequests(2);

      final downloadExpectation = expectLater(
        download,
        throwsA(isA<BookDownloadCancelledException>()),
      );
      cancellation.cancel();
      adapter.interactive.single.complete('reader');

      expect((await reader).single.id, 'reader');
      await downloadExpectation;
    },
  );

  test(
    'different download tokens do not share a cancellable request',
    () async {
      final adapter = _ControlledCatalogAdapter();
      final cache = _memoryOnlyCache();
      final client = _client(adapter, cache);
      final firstCancellation = BookDownloadCancellation();
      final secondCancellation = BookDownloadCancellation();

      final first = client.getChaptersForDownload(
        _source,
        'book',
        cancellation: firstCancellation,
      );
      await adapter.waitForRequests(1);
      final second = client.getChaptersForDownload(
        _source,
        'book',
        cancellation: secondCancellation,
      );
      await adapter.waitForRequests(2);

      final firstExpectation = expectLater(
        first,
        throwsA(isA<BookDownloadCancelledException>()),
      );
      firstCancellation.cancel();
      adapter.downloads.elementAt(1).complete('second');

      expect((await second).single.id, 'second');
      await firstExpectation;
    },
  );

  test('an older response cannot overwrite a newer catalog response', () async {
    final adapter = _ControlledCatalogAdapter();
    final cache = _memoryOnlyCache();
    final client = _client(adapter, cache);
    final cancellation = BookDownloadCancellation();

    final older = client.getChaptersForDownload(
      _source,
      'book',
      cancellation: cancellation,
    );
    await adapter.waitForRequests(1);
    final newer = client.getChapters(_source, 'book');
    await adapter.waitForRequests(2);

    adapter.interactive.single.complete('newer');
    expect((await newer).single.id, 'newer');
    adapter.downloads.single.complete('older');
    expect((await older).single.id, 'older');

    final cached = await cache.getChapterCatalogOrLoad(
      sourceId: _source.id,
      sourceRevision: _source.apiBaseUrl.toString(),
      bookId: 'book',
      loader: () => throw StateError('expected the shared cached catalog'),
    );
    expect(cached.single.id, 'newer');
  });
}

BookSourceChapterCache _memoryOnlyCache() => BookSourceChapterCache(
  beforeDiskRead: () async => throw const FileSystemException('no disk'),
  beforeDiskWrite: () async => throw const FileSystemException('no disk'),
);

BookSourceClient _client(
  _ControlledCatalogAdapter adapter,
  BookSourceChapterCache cache,
) {
  final dio = Dio()..httpClientAdapter = adapter;
  final client = BookSourceClient(
    dio: dio,
    chapterCache: cache,
    networkPolicy: BookSourceNetworkPolicy(
      lookup: (_) async => [InternetAddress('93.184.216.34')],
    ),
  );
  addTearDown(client.close);
  return client;
}

final _source = RegisteredBookSource(
  id: 'catalog.isolation.test',
  name: 'Catalog isolation test',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

class _ControlledCatalogAdapter implements HttpClientAdapter {
  final requests = <_PendingCatalogRequest>[];

  Iterable<_PendingCatalogRequest> get interactive => requests.where(
    (request) => request.options.receiveTimeout == const Duration(seconds: 6),
  );

  Iterable<_PendingCatalogRequest> get downloads => requests.where(
    (request) => request.options.receiveTimeout == const Duration(seconds: 90),
  );

  Future<void> waitForRequests(int count) async {
    while (requests.length < count) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final request = _PendingCatalogRequest(options);
    requests.add(request);
    cancelFuture?.then((_) => request.cancel());
    return request.response.future;
  }

  @override
  void close({bool force = false}) {
    for (final request in requests) {
      request.cancel();
    }
  }
}

class _PendingCatalogRequest {
  _PendingCatalogRequest(this.options);

  final RequestOptions options;
  final response = Completer<ResponseBody>();
  bool cancelled = false;

  void complete(String chapterId) {
    if (response.isCompleted) return;
    response.complete(
      ResponseBody.fromString(
        '{"items":[{"id":"$chapterId","title":"Chapter","order":1}],'
        '"page":1,"pageSize":100,"hasMore":false}',
        HttpStatus.ok,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
  }

  void cancel() {
    cancelled = true;
    if (response.isCompleted) return;
    response.completeError(
      DioException(requestOptions: options, type: DioExceptionType.cancel),
    );
  }
}
