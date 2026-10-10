// flutter test tool/preview_reader_aloud_layout.dart
// macOS preview: theme text loads a CJK font; CustomPaint covers retain the
// test engine default font, so their glyphs are not a typography reference.
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/services/reader_aloud_service.dart';
import 'package:xxread/services/tts_service.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_aloud_panel.dart';

void main() {
  testWidgets('capture responsive audiobook player', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'AloudPreview',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    // This tool is executed by flutter_test as a deterministic render harness.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tts = _PanelTtsService();
    final aloud = ReaderAloudService(
      systemEngine: tts,
      settingsStore: _PanelSettingsStore(),
      cloudClient: _PanelCloudClient(),
      bytesPlayer: _PanelBytesPlayer(),
    );
    final controller = ReaderAloudController(
      engine: aloud,
      source: CallbackReaderAloudSource(
        bookTitle: '学习的逻辑：中学生高效学习策略体系',
        bookMetadata: ReaderAloudBookMetadata(
          author: '叶修',
          localCoverPath: File(
            'test/fixtures/reader_aloud/cover.png',
          ).absolute.path,
        ),
        textStyle: const TextStyle(
          inherit: false,
          fontFamily: 'AloudPreview',
          fontSize: 20,
          height: 1.85,
        ),
        chapterCount: () => 2,
        currentPosition: () async =>
            const ReaderAloudPosition(chapterIndex: 0, offset: 0),
        loadChapter: (index) async => ReaderAloudChapter(
          index: index,
          id: 'chapter-$index',
          title: '自序 策略红利',
          text:
              '我们怎样才能更好地学习？这个问题的答案一直在变化。'
              '每一次重新审视自己的学习方法，都是向前迈出的一步。'
              '先了解自己，再选择合适的节奏。'
              '知识不只在书页里，也在观察、思考与尝试之中。'
              '保持专注，给自己一点安静的时间。'
              '把复杂的问题拆开，从能够理解的地方开始。'
              '遇到不懂的内容，可以慢下来，也可以再听一遍。'
              '学习是一段持续的旅程，读懂一个问题，就多看见一片风景。',
        ),
        revealPosition: (_) async {},
        persistPosition: (_) async {},
      ),
    );
    addTearDown(() {
      controller.dispose();
      aloud.dispose();
      tts.dispose();
    });
    Future<void> capture(String name) async {
      // Switching from a thumbnail to artwork requests a new decode size.
      // File/codec work must advance in real async time before its capture.
      for (var attempt = 0; attempt < 20; attempt++) {
        if (tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((image) => image.image != null)) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
      }
      expect(
        tester
            .widgetList<RawImage>(find.byType(RawImage))
            .any((image) => image.image != null),
        isTrue,
        reason: '$name must capture its decoded local book cover',
      );
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('aloudPreview')),
      );
      await tester.runAsync(() async {
        final picture = await boundary.toImage(pixelRatio: 2);
        final data = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/aloud-layout-20261010/previews/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        picture.dispose();
      });
    }

    for (final scenario in [
      (
        name: 'small-landscape',
        size: const Size(568, 320),
        scale: 1.0,
        dark: false,
      ),
      (name: 'phone', size: const Size(390, 844), scale: 1.0, dark: false),
      (
        name: 'small-phone',
        size: const Size(320, 568),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'tablet-portrait',
        size: const Size(768, 1024),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'tablet-landscape',
        size: const Size(1194, 834),
        scale: 1.0,
        dark: false,
      ),
      (name: 'desktop', size: const Size(1440, 900), scale: 1.0, dark: false),
      (
        name: 'phone-landscape',
        size: const Size(844, 390),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'large-text-dark',
        size: const Size(390, 844),
        scale: 1.4,
        dark: true,
      ),
    ]) {
      tester.view.physicalSize = scenario.size;
      final padding = FakeViewPadding(
        top: scenario.size.width > scenario.size.height ? 0 : 24,
        bottom: 20,
      );
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      final palette = scenario.dark ? ReaderThemes.night : ReaderThemes.day;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: palette.toThemeData().copyWith(
            textTheme: ThemeData().textTheme.apply(fontFamily: 'AloudPreview'),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: RepaintBoundary(
              key: const Key('aloudPreview'),
              child: child!,
            ),
          ),
          home: ReaderAloudPlayerPage(
            controller: controller,
            ttsService: tts,
            aloudService: aloud,
            palette: palette,
            author: '叶修',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      await capture(scenario.name);
      if (scenario.name == 'phone') {
        await tester.drag(
          find.byKey(const ValueKey('reader-aloud-transcript')),
          const Offset(0, -180),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('reader-aloud-more')), findsNothing);
        await capture('phone-focused');
        await tester.tap(
          find.byKey(const ValueKey('reader-aloud-toggle-controls')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('封面'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await capture('phone-cover');
        await tester.tap(find.text('正文'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    await controller.stop();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    debugDisableShadows = true;
  });
}

class _PanelTtsService extends TtsService {
  @override
  Future<void> initialize({bool force = false}) async {}

  @override
  Future<void> ensureVoicesLoaded({bool force = false}) async {}

  @override
  bool get supportsQueuedText => false;

  @override
  bool get supportsContinuousText => false;

  bool _playing = false;
  bool _paused = false;

  @override
  bool get isPlaying => _playing;

  @override
  bool get isPaused => _paused;

  @override
  int get currentPosition => 0;

  @override
  Future<void> pause() async {
    _playing = false;
    _paused = true;
    notifyListeners();
  }

  @override
  Future<void> speak(String text) {
    _playing = true;
    _paused = false;
    notifyListeners();
    return Completer<void>().future;
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _paused = false;
    notifyListeners();
  }
}

class _PanelSettingsStore implements ReaderAloudCloudSettingsStore {
  @override
  Future<void> clearApiKey() async {}

  @override
  Future<ReaderAloudEngineType> loadEngineType() async =>
      ReaderAloudEngineType.system;

  @override
  Future<ReaderAloudCloudSettings> loadSettings() async =>
      const ReaderAloudCloudSettings();

  @override
  Future<String?> readApiKey() async => null;

  @override
  Future<void> saveEngineType(ReaderAloudEngineType type) async {}

  @override
  Future<void> saveSettings(ReaderAloudCloudSettings settings) async {}

  @override
  Future<void> writeApiKey(String apiKey) async {}
}

class _PanelCloudClient implements ReaderAloudCloudClient {
  @override
  Future<Uint8List> synthesize({
    required ReaderAloudCloudSettings settings,
    required String apiKey,
    required String text,
    required double speed,
  }) async => Uint8List.fromList([1]);
}

class _PanelBytesPlayer extends ChangeNotifier
    implements ReaderAloudBytesPlayer {
  @override
  Duration get duration => Duration.zero;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Duration get position => Duration.zero;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}
