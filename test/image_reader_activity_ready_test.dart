import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/comic/continuous_image_reader.dart';
import 'package:xxread/pages/reader/comic/image_reader_source.dart';
import 'package:xxread/pages/reader/image/paged_image_reader.dart';
import 'package:xxread/utils/reader_themes.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAABkCAYAAABHLFpgAAAAEElEQVR4nGP4DwQMo8RIIgAyH46AmqFmEAAAAABJRU5ErkJggg==',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'com.niki.xxread/fullscreen',
      'com.niki.xxread/reader_keys',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'com.niki.xxread/fullscreen',
      'com.niki.xxread/reader_keys',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  testWidgets('paged image waits for current decoded page and reports once', (
    tester,
  ) async {
    final visible = Completer<Uint8List>();
    var readyCount = 0;
    var preloads = 0;
    await tester.pumpWidget(
      _app(
        PagedImageReader(
          title: 'Images',
          pageCount: 3,
          initialPage: 1,
          loadPage: (index, {preload = false}) {
            if (preload) preloads++;
            return index == 1 ? visible.future : Future.value(_png);
          },
          onContentReady: () => readyCount++,
        ),
      ),
    );
    await _pump(tester);
    expect(preloads, greaterThan(0));
    expect(readyCount, 0);
    visible.complete(_png);
    await _pump(tester);
    expect(readyCount, 1);
    await _pump(tester);
    expect(readyCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final decodeFailure in [false, true]) {
    testWidgets(
      'failed ${decodeFailure ? 'decode' : 'load'} does not report readiness',
      (tester) async {
        var readyCount = 0;
        await tester.pumpWidget(
          _app(
            PagedImageReader(
              title: 'Failed image',
              pageCount: 1,
              initialPage: 0,
              loadPage: (index, {preload = false}) => decodeFailure
                  ? Future.value(Uint8List.fromList([1, 2, 3]))
                  : Future.error(StateError('image unavailable')),
              onContentReady: () => readyCount++,
            ),
          ),
        );
        await _pump(tester);
        expect(readyCount, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'continuous comics ignore adjacent preloads until current frame is ready',
    (tester) async {
      final source = _ActivityImageSource();
      var readyCount = 0;
      final document = await source.loadDocument();
      await tester.pumpWidget(
        _app(
          ContinuousImageReader(
            document: document,
            source: source,
            initialChapterIndex: 1,
            initialPageIndex: 0,
            onTableOfContents: null,
            onSettings: () {},
            onChangeReadingMode: () {},
            onContentReady: () => readyCount++,
          ),
        ),
      );
      await _pump(tester);
      expect(source.preloads, greaterThan(0));
      expect(readyCount, 0);
      source.visible.complete(_png);
      await _pump(tester);
      expect(readyCount, 1);
      await _pump(tester);
      expect(readyCount, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

class _ActivityImageSource extends ImageReaderSource {
  final visible = Completer<Uint8List>();
  int preloads = 0;
  @override
  String get bookTitle => 'Comic activity';
  @override
  ReaderThemePalette get theme => ReaderThemes.day;
  @override
  Future<ImageReaderDocument> loadDocument() async => const ImageReaderDocument(
    chapters: [
      ImageReaderChapter(id: '0', title: 'Zero'),
      ImageReaderChapter(id: '1', title: 'One'),
      ImageReaderChapter(id: '2', title: 'Two'),
    ],
    initialChapterIndex: 1,
  );
  @override
  Future<int> loadChapterPageCount(int chapterIndex) async => 1;
  @override
  Future<Uint8List> loadPage(
    int chapterIndex,
    int pageIndex, {
    bool preload = false,
  }) {
    if (preload) preloads++;
    return chapterIndex == 1 ? visible.future : Future.value(_png);
  }

  @override
  Future<void> saveProgress({
    required int chapterIndex,
    required int pageIndex,
    required int pageCount,
  }) async {}
  @override
  String emptyPagesMessage(AppLocalizations l10n) => 'Empty';
  @override
  String describeError(Object error, AppLocalizations l10n) => '$error';
}
