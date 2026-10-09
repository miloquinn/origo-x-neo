import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/core/reader/reader_layout.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/native/native_reader_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/core/online_font_service.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/services/reader_aloud_service.dart';
import 'package:xxread/services/reader_aloud_session.dart';
import 'package:xxread/services/tts_service.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_aloud_panel.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

import 'support/reader_cache_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDirectory;

  setUpAll(() {
    supportDirectory = Directory.systemTemp.createTempSync(
      'origo-x-aloud-typography-support-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => supportDirectory.path,
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    supportDirectory.deleteSync(recursive: true);
  });

  testWidgets(
    'native EPUB listening follows book, system, and explicit reader typography',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
        ReaderSettingsStore.fontSizeKey: 23.0,
        ReaderSettingsStore.fontWeightKey: 600,
        ReaderSettingsStore.lineHeightKey: 1.9,
        ReaderSettingsStore.letterSpacingKey: 0.4,
        'reader_aloud_presentation': 'player',
        'epub_reader_font_id_v1': FontCatalog.bookEmbeddedId,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-aloud-typography-',
      );
      final epub = File(path.join(directory.path, 'typography.epub'))
        ..writeAsBytesSync(_epubFixture());
      final onlineFonts = _seededOnlineFontService(
        directory,
        FontCatalog.newsreader,
      );
      final appSettings = AppSettingsNotifier(onlineFontService: onlineFonts);
      final rules = ReplaceRuleService();
      final paginationCache = MemoryPaginationCacheDao();
      final tts = _HeldTts();
      final aloud = ReaderAloudService(
        systemEngine: tts,
        settingsStore: _SettingsStore(),
        bytesPlayer: _SilentPlayer(),
      );
      final session = ReaderAloudSession();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const mediaChannel = MethodChannel('com.niki.xxread/reader_aloud');
      messenger.setMockMethodCallHandler(mediaChannel, (_) async => null);
      var cleanedUp = false;
      Future<void> cleanup() async {
        if (cleanedUp) return;
        cleanedUp = true;
        await session.stop();
        await tester.pumpWidget(const SizedBox.shrink());
        await drainReaderCache(tester);
        await tester.pump();
        session.dispose();
        aloud.dispose();
        tts.dispose();
        appSettings.dispose();
        messenger.setMockMethodCallHandler(mediaChannel, null);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }

      addTearDown(() async {
        await cleanup();
        await rules.close();
      });

      await _waitFor(
        tester,
        () => appSettings.isInitialized,
        message: 'app font settings did not initialize',
      );
      await tester.pumpWidget(
        _app(
          session: session,
          aloud: aloud,
          tts: tts,
          appSettings: appSettings,
          home: NativeReaderPage(
            replaceRuleService: rules,
            paginationCacheDao: paginationCache,
            book: Book(
              title: 'Listening typography fixture',
              filePath: epub.path,
              format: 'epub',
              fileModifiedTime: epub.lastModifiedSync().millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      await _waitFor(tester, () {
        final chrome = find.byType(ReaderChromeOverlay);
        return chrome.evaluate().isNotEmpty &&
            tester.widget<ReaderChromeOverlay>(chrome).onReadAloud != null;
      }, message: 'native reader read-aloud action did not become ready');

      await _openPlayer(tester);
      final controller = session.controller!;
      final embedded = await _visibleRun(
        tester,
        controller,
        'Embedded opening marker',
      );
      expect(embedded.fontFamily, 'serif');
      expect(embedded.fontFamily, isNot('AppThemeFont'));
      expect(
        (controller.source as ReaderAloudTextSource).preserveDocumentFont,
        isTrue,
      );

      await _closePlayer(tester);
      await tester.runAsync(
        () => appSettings.setEpubReaderFontId(FontCatalog.systemId),
      );
      await tester.pump();
      await _openPlayer(tester);
      final system = await _visibleRun(
        tester,
        controller,
        'Embedded opening marker',
      );
      expect(system.fontFamily, 'sans-serif');
      expect(system.fontFamily, isNot('serif'));
      expect(
        (controller.source as ReaderAloudTextSource).preserveDocumentFont,
        isFalse,
      );

      await _closePlayer(tester);
      await tester.runAsync(
        () => appSettings.setEpubReaderFontId(FontCatalog.newsreaderId),
      );
      await tester.pump();
      await _openPlayer(tester);
      final explicit = await _visibleRun(
        tester,
        controller,
        'Embedded opening marker',
      );
      expect(explicit.fontFamily, 'Newsreader');
      expect(explicit.fontSize, 23);
      expect(explicit.fontWeight, FontWeight.w600);
      expect(explicit.height, 1.9);
      expect(explicit.letterSpacing, 0.4);
      expect(
        explicit.fontVariations,
        contains(const FontVariation('wght', 600)),
      );
      expect(
        explicit.fontFamilyFallback,
        containsAll(<String>['SourceHanSerifCN', 'serif']),
      );
      expect(explicit.fontFamily, isNot('AppThemeFont'));

      unawaited(
        controller.playFromOffset(
          const ReaderAloudPosition(chapterIndex: 7, offset: 0),
        ),
      );
      await _waitFor(
        tester,
        () => controller.currentChapter?.index == 7,
        message: 'far EPUB chapter did not load into the listening snapshot',
      );
      final farChapter = controller.currentChapter!;
      expect(farChapter.text, contains('Far chapter marker'));

      // Replace the whole Navigator so NativeReaderPage and its private chapter
      // objects are disposed. The app-scoped listening session must keep the
      // immutable text/block snapshot usable by the player.
      await tester.pumpWidget(const SizedBox.shrink());
      await drainReaderCache(tester);
      await tester.pump();
      await tester.pumpWidget(
        _app(
          session: session,
          aloud: aloud,
          tts: tts,
          appSettings: appSettings,
          home: ReaderAloudPlayerPage(
            controller: controller,
            ttsService: tts,
            aloudService: aloud,
            palette: ReaderThemes.day,
          ),
        ),
      );
      await tester.pump();
      final afterReaderClosed = await _visibleRun(
        tester,
        controller,
        'Far chapter marker',
      );
      expect(afterReaderClosed.fontFamily, 'Newsreader');
      expect(afterReaderClosed.fontWeight, FontWeight.w600);
      expect(controller.currentChapter, same(farChapter));
      expect(tester.takeException(), isNull);
      await controller.stop();
      await tester.pump();
      await cleanup();
    },
  );
}

Widget _app({
  required ReaderAloudSession session,
  required ReaderAloudService aloud,
  required TtsService tts,
  required AppSettingsNotifier appSettings,
  required Widget home,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider<ReaderAloudSession>.value(value: session),
    ChangeNotifierProvider<ReaderAloudService>.value(value: aloud),
    ChangeNotifierProvider<TtsService>.value(value: tts),
    ChangeNotifierProvider<AppSettingsNotifier>.value(value: appSettings),
  ],
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(fontFamily: 'AppThemeFont'),
    home: home,
  ),
);

Future<void> _openPlayer(WidgetTester tester) async {
  final chrome = find.byType(ReaderChromeOverlay);
  await _waitFor(
    tester,
    () =>
        chrome.evaluate().isNotEmpty &&
        tester.widget<ReaderChromeOverlay>(chrome).onReadAloud != null,
    message: 'native reader read-aloud action was not ready',
  );
  tester.widget<ReaderChromeOverlay>(chrome).onReadAloud!();
  await _waitFor(
    tester,
    () => find.byType(ReaderAloudPlayerPage).evaluate().isNotEmpty,
    message: 'listening player did not open',
  );
}

Future<void> _closePlayer(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(ReaderAloudPlayerPage))).pop();
  await _waitFor(
    tester,
    () => find.byType(ReaderAloudPlayerPage).evaluate().isEmpty,
    message: 'listening player did not close',
  );
}

Future<TextStyle> _visibleRun(
  WidgetTester tester,
  ReaderAloudController controller,
  String marker,
) async {
  await _waitFor(
    tester,
    () =>
        controller.currentChapter != null &&
        controller.chapterSegments.any(
          (candidate) => candidate.text.contains(marker),
        ),
    message: 'listening chapter segments were not prepared',
  );
  final mode = tester.widget<SegmentedButton<bool>>(
    find.byKey(const ValueKey('reader-aloud-content-mode')),
  );
  mode.onSelectionChanged!({true});
  await tester.pump();
  final segment = controller.chapterSegments.firstWhere(
    (candidate) => candidate.text.contains(marker),
  );
  final row = find.byKey(
    ValueKey(
      'reader-aloud-transcript-segment-'
      '${segment.chapterIndex}-${segment.startOffset}',
    ),
  );
  await _waitFor(
    tester,
    () => row.evaluate().isNotEmpty,
    message: 'marked listening segment was not rendered',
  );
  final richText = tester.widget<RichText>(
    find.descendant(of: row, matching: find.byType(RichText)).first,
  );
  final style = _styleForMarker(richText.text, marker);
  expect(style, isNotNull, reason: 'marker did not retain a styled text run');
  return style!;
}

TextStyle? _styleForMarker(InlineSpan span, String marker) {
  if (span is! TextSpan) return null;
  if (span.text?.contains(marker) ?? false) return span.style;
  for (final child in span.children ?? const <InlineSpan>[]) {
    final result = _styleForMarker(child, marker);
    if (result != null) return result;
  }
  return null;
}

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() done, {
  required String message,
}) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 120; attempt++) {
      if (done()) return;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
    }
  });
  expect(done(), isTrue, reason: message);
}

OnlineFontService _seededOnlineFontService(
  Directory sandbox,
  FontOption option,
) {
  final fontsRoot = Directory(path.join(sandbox.path, 'online_fonts'));
  final fontDirectory = Directory(path.join(fontsRoot.path, option.id));
  fontDirectory.createSync(recursive: true);
  final files = <Map<String, Object?>>[];
  for (final file in option.downloadFiles) {
    File(
      path.join(fontDirectory.path, file.fileName),
    ).writeAsBytesSync(const <int>[0, 1, 0, 0]);
    files.add({'fileName': file.fileName, 'sha256': 'test', 'size': 4});
  }
  File(path.join(fontsRoot.path, 'manifest.json')).writeAsStringSync(
    jsonEncode([
      {
        'id': option.id,
        'files': files,
        'downloadedAt': DateTime.now().toUtc().toIso8601String(),
      },
    ]),
  );
  return OnlineFontService(
    supportDirectory: () async => sandbox,
    registrar: (family, bytes, style) async {},
  );
}

List<int> _epubFixture() {
  const chapterCount = 8;
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('mimetype', 'application/epub+zip');
  add('META-INF/container.xml', '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''');
  add('OEBPS/content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">aloud-typography-fixture</dc:identifier>
    <dc:title>Listening typography fixture</dc:title><dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    ${List.generate(chapterCount, (index) => '<item id="c${index + 1}" href="chapter${index + 1}.xhtml" media-type="application/xhtml+xml"/>').join()}
  </manifest>
  <spine toc="ncx">${List.generate(chapterCount, (index) => '<itemref idref="c${index + 1}"/>').join()}</spine>
</package>''');
  add('OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="aloud-typography-fixture"/></head>
  <docTitle><text>Listening typography fixture</text></docTitle>
  <navMap>${List.generate(chapterCount, (index) => '<navPoint id="nav${index + 1}" playOrder="${index + 1}"><navLabel><text>Chapter ${index + 1}</text></navLabel><content src="chapter${index + 1}.xhtml"/></navPoint>').join()}</navMap>
</ncx>''');
  for (var chapter = 1; chapter <= chapterCount; chapter++) {
    final marker = chapter == 1
        ? 'Embedded opening marker'
        : chapter == chapterCount
        ? 'Far chapter marker'
        : 'Chapter $chapter marker';
    add('OEBPS/chapter$chapter.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter $chapter</title></head><body>
<h1>Chapter $chapter</h1>
<p style="font-family: serif">$marker remains readable after navigation. A second sentence keeps speech active.</p>
</body></html>''');
  }
  return ZipEncoder().encode(archive)!;
}

class _HeldTts extends TtsService {
  Completer<void>? _speech;

  @override
  Future<void> initialize({bool force = false}) async {}

  @override
  Future<void> ensureVoicesLoaded({bool force = false}) async {}

  @override
  bool get supportsQueuedText => false;

  @override
  bool get supportsContinuousText => false;

  @override
  bool get isPlaying => _speech != null;

  @override
  int get currentPosition => 0;

  @override
  Future<void> speak(String text) async {
    _speech = Completer<void>();
    notifyListeners();
    await _speech!.future;
  }

  @override
  Future<void> stop() async {
    final speech = _speech;
    _speech = null;
    if (speech != null && !speech.isCompleted) speech.complete();
  }
}

class _SettingsStore implements ReaderAloudCloudSettingsStore {
  @override
  Future<ReaderAloudEngineType> loadEngineType() async =>
      ReaderAloudEngineType.system;

  @override
  Future<ReaderAloudCloudSettings> loadSettings() async =>
      const ReaderAloudCloudSettings();

  @override
  Future<String?> readApiKey() async => null;

  @override
  Future<void> clearApiKey() async {}

  @override
  Future<void> writeApiKey(String apiKey) async {}

  @override
  Future<void> saveEngineType(ReaderAloudEngineType type) async {}

  @override
  Future<void> saveSettings(ReaderAloudCloudSettings settings) async {}
}

class _SilentPlayer extends ChangeNotifier implements ReaderAloudBytesPlayer {
  @override
  bool get isPlaying => false;

  @override
  bool get isPaused => false;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}
}
