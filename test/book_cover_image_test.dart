import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/source_cover_cache.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/book_cover_reference.dart';
import 'package:xxread/widgets/book_cover_image.dart';
import 'package:xxread/widgets/source_cover_image.dart';

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);

class _TrackingCache extends SourceCoverCache {
  _TrackingCache({this.memoryBytes});

  final Uint8List? memoryBytes;
  int peeks = 0;
  int loads = 0;

  @override
  Uint8List? peek(Uri uri, {Map<String, String> headers = const {}}) {
    peeks++;
    return memoryBytes;
  }

  @override
  Future<Uint8List> load(
    Uri uri, {
    Map<String, String> headers = const {},
    bool preferPlatform = false,
    SourceImageLoadPriority priority = SourceImageLoadPriority.visible,
  }) async {
    loads++;
    return memoryBytes ?? _png;
  }
}

Book _book({String? localPath, String? sourceJson, String? sourceBookJson}) =>
    Book(
      title: '书名',
      author: '作者',
      filePath: '/books/book.epub',
      format: 'EPUB',
      coverImagePath: localPath,
      sourceJson: sourceJson,
      sourceBookJson: sourceBookJson,
    );

Widget _host(Widget child) =>
    MaterialApp(home: SizedBox(width: 120, height: 168, child: child));

void main() {
  late Directory directory;
  late File localCover;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('book-cover-image-');
    localCover = File('${directory.path}/cover.png');
    await localCover.writeAsBytes(_png, flush: true);
  });

  tearDownAll(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('runtime book reference resolves source cover and freezes headers', () {
    final reference = BookCoverReference.fromBook(
      _book(
        localPath: '  ${localCover.path}  ',
        sourceJson: jsonEncode({'apiBaseUrl': 'https://api.test/v1/'}),
        sourceBookJson: jsonEncode({
          'coverUrl': 'covers/book.webp',
          'coverHeaders': {'Referer': 'https://books.test/', 'Token': null},
        }),
      ),
    );

    expect(reference.localPath, localCover.path);
    expect(
      reference.remoteUrl,
      Uri.parse('https://api.test/v1/covers/book.webp'),
    );
    expect(reference.remoteHeaders, {
      'Referer': 'https://books.test/',
      'Token': '',
    });
    expect(
      () => reference.remoteHeaders['Cookie'] = 'session',
      throwsUnsupportedError,
    );
  });

  test('absolute source cover does not require stored source metadata', () {
    final reference = BookCoverReference.fromBook(
      _book(
        sourceJson: '{',
        sourceBookJson: jsonEncode({
          'coverUrl': 'https://images.test/book.webp',
          'coverHeaders': {'X-Cover': 'fixture'},
        }),
      ),
    );

    expect(reference.remoteUrl, Uri.parse('https://images.test/book.webp'));
    expect(reference.remoteHeaders, {'X-Cover': 'fixture'});
  });

  test('scheme-relative cover resolves through a valid HTTP source base', () {
    final reference = BookCoverReference.fromBook(
      _book(
        sourceJson: jsonEncode({'apiBaseUrl': 'https://api.test/v1/'}),
        sourceBookJson: jsonEncode({'coverUrl': '//cdn.test/covers/book.webp'}),
      ),
    );

    expect(reference.remoteUrl, Uri.parse('https://cdn.test/covers/book.webp'));
  });

  test('unsafe absolute cover schemes are rejected', () {
    for (final coverUrl in [
      'ftp://images.test/book.webp',
      'file:///tmp/book.webp',
      'https:///missing-host.webp',
    ]) {
      final reference = BookCoverReference.fromBook(
        _book(sourceBookJson: jsonEncode({'coverUrl': coverUrl})),
      );
      expect(reference.remoteUrl, isNull, reason: coverUrl);
    }
  });

  testWidgets('direct metadata with an unsupported URI uses its fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        BookCoverImage(
          reference: BookCoverReference(
            remoteUrl: Uri.parse('ftp://images.test/book.webp'),
          ),
          fallback: const ColoredBox(
            key: ValueKey('cover-fallback'),
            color: Colors.grey,
          ),
        ),
      ),
    );
    expect(find.byType(SourceCoverImage), findsNothing);
    expect(find.byKey(const ValueKey('cover-fallback')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('relative covers require a valid absolute HTTP source base', () {
    for (final baseUrl in ['', '/relative/api/', 'ftp://api.test/', '{']) {
      final reference = BookCoverReference.fromBook(
        _book(
          sourceJson: jsonEncode({'apiBaseUrl': baseUrl}),
          sourceBookJson: jsonEncode({'coverUrl': 'covers/book.webp'}),
        ),
      );
      expect(reference.remoteUrl, isNull, reason: baseUrl);
    }
  });

  test('URI percent sequences are normalized before reaching the cache', () {
    final reference = BookCoverReference.fromBook(
      _book(
        sourceJson: jsonEncode({'apiBaseUrl': 'https://api.test/v1/'}),
        sourceBookJson: jsonEncode({
          'coverUrl': 'https://images.test/%ZZ/book.webp',
        }),
      ),
    );

    expect(
      reference.remoteUrl,
      Uri.parse('https://images.test/%25ZZ/book.webp'),
    );
  });

  test('malformed stored source metadata safely produces no remote cover', () {
    final reference = BookCoverReference.fromBook(
      _book(sourceJson: '{', sourceBookJson: 'not-json'),
    );

    expect(reference.remoteUrl, isNull);
    expect(reference.remoteHeaders, isEmpty);
  });

  testWidgets('successful local cover never starts the remote cover', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox).first);
    await tester.runAsync(() async {
      await precacheImage(
        ResizeImage.resizeIfNeeded(240, null, FileImage(localCover)),
        context,
      ).timeout(const Duration(seconds: 5));
    });
    final cache = _TrackingCache(memoryBytes: _png);

    await tester.pumpWidget(
      _host(
        BookCoverImage(
          reference: BookCoverReference(
            localPath: localCover.path,
            remoteUrl: Uri.parse('https://images.test/unused.webp'),
            remoteHeaders: const {'Referer': 'https://books.test/'},
          ),
          remoteCache: cache,
          fallback: const ColoredBox(color: Colors.grey),
          cacheWidth: 240,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SourceCoverImage), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(cache.peeks, 0);
    expect(cache.loads, 0);
  });

  testWidgets('invalid local cover falls through to the remote cover', (
    tester,
  ) async {
    final cache = _TrackingCache(memoryBytes: _png);
    final missing = '${directory.path}/missing.png';

    await tester.pumpWidget(
      _host(
        BookCoverImage(
          reference: BookCoverReference(
            localPath: missing,
            remoteUrl: Uri.parse('https://images.test/fallback.webp'),
            remoteHeaders: const {'Referer': 'https://books.test/'},
          ),
          remoteCache: cache,
          fallback: const ColoredBox(color: Colors.grey),
        ),
      ),
    );
    for (var attempt = 0; attempt < 50; attempt++) {
      if (find.byType(SourceCoverImage).evaluate().isNotEmpty) break;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.byType(SourceCoverImage), findsOneWidget);
    final remote = tester.widget<SourceCoverImage>(
      find.byType(SourceCoverImage),
    );
    expect(remote.url, Uri.parse('https://images.test/fallback.webp'));
    expect(remote.headers, {'Referer': 'https://books.test/'});
    expect(cache.peeks, 1);
    expect(cache.loads, 0);
    expect(tester.takeException(), isNull);
  });
}
