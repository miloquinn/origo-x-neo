import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/caching/source_cover_cache.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/widgets/generated_book_cover.dart';
import 'package:xxread/widgets/reader_aloud_cover.dart';
import 'package:xxread/widgets/source_cover_image.dart';

class _PendingCoverCache extends SourceCoverCache {
  final pending = Completer<Uint8List>();

  @override
  Future<Uint8List> load(
    Uri uri, {
    Map<String, String> headers = const {},
    bool preferPlatform = false,
    SourceImageLoadPriority priority = SourceImageLoadPriority.visible,
  }) => pending.future;
}

class _Engine extends ChangeNotifier implements ReaderAloudEngine {
  @override
  int get currentPosition => 0;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Future<void> pause() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

CallbackReaderAloudSource _source(ReaderAloudBookMetadata? metadata) =>
    CallbackReaderAloudSource(
      bookTitle: '书名',
      bookMetadata: metadata,
      chapterCount: () => 0,
      currentPosition: () async =>
          const ReaderAloudPosition(chapterIndex: 0, offset: 0),
      loadChapter: (_) async => null,
      revealPosition: (_) async {},
      persistPosition: (_) async {},
    );

Widget _localizedCoverHost(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Center(child: SizedBox(width: 120, height: 168, child: child)),
);

void main() {
  late Directory coverDirectory;
  late Map<String, String> localCoverPaths;

  setUpAll(() async {
    coverDirectory = await Directory.systemTemp.createTemp(
      'reader-aloud-cover-',
    );
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
    );
    localCoverPaths = {};
    for (final format in ['TXT', 'EPUB']) {
      final file = File('${coverDirectory.path}/$format.png');
      await file.writeAsBytes(png, flush: true);
      localCoverPaths[format] = file.path;
    }
  });

  tearDownAll(() async {
    if (await coverDirectory.exists()) {
      await coverDirectory.delete(recursive: true);
    }
  });

  test('metadata owns an immutable snapshot of remote cover headers', () {
    final headers = <String, String>{'Referer': 'https://books.test/'};
    final metadata = ReaderAloudBookMetadata(remoteCoverHeaders: headers);

    headers['Referer'] = 'changed';

    expect(metadata.remoteCoverHeaders, {'Referer': 'https://books.test/'});
    expect(
      () => metadata.remoteCoverHeaders['Cookie'] = 'session',
      throwsUnsupportedError,
    );
  });

  test(
    'controller snapshots refreshed metadata when the source is rebound',
    () {
      final first = ReaderAloudBookMetadata(
        author: '旧作者',
        localCoverPath: '/covers/old.txt.png',
      );
      final second = ReaderAloudBookMetadata(
        author: '新作者',
        localCoverPath: '/covers/new.epub.png',
        remoteCoverUrl: Uri.parse('https://images.test/new.webp'),
      );
      final controller = ReaderAloudController(
        engine: _Engine(),
        source: _source(first),
      );
      addTearDown(controller.dispose);
      final sameController = controller;

      expect(controller.bookMetadata, same(first));
      controller.rebindSource(_source(second));
      expect(controller, same(sameController));
      expect(controller.bookMetadata?.localCoverPath, '/covers/new.epub.png');
      expect(
        controller.bookMetadata?.remoteCoverUrl,
        Uri.parse('https://images.test/new.webp'),
      );
      expect(controller.bookMetadata, same(second));
    },
  );

  testWidgets(
    'remote cover keeps headers, cache, fit, and generated fallback',
    (tester) async {
      final cache = _PendingCoverCache();
      final url = Uri.parse('https://images.test/book.webp');
      final metadata = ReaderAloudBookMetadata(
        author: '元数据作者',
        remoteCoverUrl: url,
        remoteCoverHeaders: const {'Referer': 'https://books.test/'},
      );

      await tester.pumpWidget(
        _localizedCoverHost(
          ReaderAloudCover(
            title: '书名',
            fallbackAuthor: '备用作者',
            metadata: metadata,
            remoteCache: cache,
          ),
        ),
      );

      final cover = tester.widget<SourceCoverImage>(
        find.byType(SourceCoverImage),
      );
      expect(cover.url, url);
      expect(cover.headers, metadata.remoteCoverHeaders);
      expect(cover.cache, same(cache));
      expect(cover.fit, BoxFit.cover);
      expect(
        cover.cacheWidth,
        (120 *
                MediaQuery.devicePixelRatioOf(
                  tester.element(find.byType(ReaderAloudCover)),
                ))
            .ceil(),
      );
      final fallback = cover.fallback as GeneratedBookCover;
      expect(fallback.title, '书名');
      expect(fallback.author, '元数据作者');
    },
  );

  for (final format in ['TXT', 'EPUB']) {
    testWidgets('$format metadata displays its decoded local cover', (
      tester,
    ) async {
      // Create the file stream in real async time before Image.file starts it
      // inside the widget test's fake async zone.
      await tester.pumpWidget(_localizedCoverHost(const SizedBox.shrink()));
      final hostContext = tester.element(find.byType(SizedBox).first);
      final decodeWidth = (120 * MediaQuery.devicePixelRatioOf(hostContext))
          .ceil();
      await tester.runAsync(() async {
        await precacheImage(
          ResizeImage.resizeIfNeeded(
            decodeWidth,
            null,
            FileImage(File(localCoverPaths[format]!)),
          ),
          hostContext,
        ).timeout(const Duration(seconds: 5));
      });
      await tester.pumpWidget(
        _localizedCoverHost(
          ReaderAloudCover(
            title: '$format 书名',
            fallbackAuthor: '$format 作者',
            metadata: ReaderAloudBookMetadata(
              localCoverPath: localCoverPaths[format],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SourceCoverImage), findsNothing);
      expect(find.byType(GeneratedBookCover), findsNothing);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as ResizeImage).width, decodeWidth);
      final rawImage = tester.widget<RawImage>(find.byType(RawImage));
      expect(rawImage.image, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('invalid local cover falls through to remote cover', (
    tester,
  ) async {
    final cache = _PendingCoverCache();
    await tester.pumpWidget(
      _localizedCoverHost(
        ReaderAloudCover(
          title: '书名',
          fallbackAuthor: '备用作者',
          metadata: ReaderAloudBookMetadata(
            localCoverPath: '/missing/local-cover.webp',
            remoteCoverUrl: Uri.parse('https://images.test/book.webp'),
            remoteCoverHeaders: const {'Referer': 'https://books.test/'},
          ),
          remoteCache: cache,
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
    expect(remote.url, Uri.parse('https://images.test/book.webp'));
    expect(remote.headers, {'Referer': 'https://books.test/'});
    expect(remote.cache, same(cache));
    expect(find.byType(GeneratedBookCover), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing metadata uses the supplied fallback author', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedCoverHost(
        const ReaderAloudCover(title: '书名', fallbackAuthor: '备用作者'),
      ),
    );

    final fallback = tester.widget<GeneratedBookCover>(
      find.byType(GeneratedBookCover),
    );
    expect(fallback.title, '书名');
    expect(fallback.author, '备用作者');
  });
}
