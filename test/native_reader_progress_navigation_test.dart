import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/native/native_reader_page.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/widgets/reader_paper_page_leaf.dart';
import 'package:xxread/widgets/reader_progress_pill.dart';

import 'support/reader_cache_test_utils.dart';
import 'support/reading_cloud_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fullscreenChannel = MethodChannel('com.niki.xxread/fullscreen');
  const readerKeysChannel = MethodChannel('com.niki.xxread/reader_keys');
  const readerStatusChannel = MethodChannel('com.niki.xxread/reader_status');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory temporaryDirectory;
  late ReplaceRuleService replaceRules;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'origo-x-native-progress-',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      pathProviderChannel,
      (_) async => temporaryDirectory.path,
    );
    await prepareReadingCloudTestDatabase();
  });

  setUp(() {
    replaceRules = ReplaceRuleService();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(fullscreenChannel, (_) async => null);
    messenger.setMockMethodCallHandler(readerKeysChannel, (_) async => null);
    messenger.setMockMethodCallHandler(
      readerStatusChannel,
      (_) async => <String, Object?>{'level': 80, 'charging': false},
    );
  });

  tearDown(() async {
    await replaceRules.close();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(fullscreenChannel, null);
    messenger.setMockMethodCallHandler(readerKeysChannel, null);
    messenger.setMockMethodCallHandler(readerStatusChannel, null);
  });

  tearDownAll(() async {
    await closeReadingCloudTestDatabase();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('native TXT progress pill switches logical chapters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    _registerReaderTearDown(tester);
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: NativePageMode.instantPage.name,
      ReaderSettingsStore.progressBarEnabledKey: true,
    });
    final file = _writeBook(
      temporaryDirectory,
      'chapters.txt',
      '${_chapter("第1章 起点", "起点正文")}'
          '${_chapter("第2章 终点", "终点正文")}',
    );
    await _pumpReader(tester, file, replaceRules);
    await _showProgressPill(tester);
    expect(_pill(tester).position.chapterIndex, 0);
    expect(_pill(tester).position.chapterCount, 2);

    await tester.tap(find.byKey(const ValueKey('reader-progress-next')));
    await _pumpUntil(tester, () => _pill(tester).position.chapterIndex == 1);
    await _showProgressPill(tester);
    await tester.tap(find.byKey(const ValueKey('reader-progress-previous')));
    await _pumpUntil(tester, () => _pill(tester).position.chapterIndex == 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('native chapter slider seeks to a real middle page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    _registerReaderTearDown(tester);
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: NativePageMode.instantPage.name,
      ReaderSettingsStore.progressBarEnabledKey: true,
      ReaderSettingsStore.progressBarScopeKey: ReaderProgressScope.chapter.name,
    });
    final file = _writeBook(
      temporaryDirectory,
      'seek.txt',
      _chapter('第1章 长路', '章内跳转', paragraphs: 260),
    );
    await _pumpReader(tester, file, replaceRules);
    await _showProgressPill(tester);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('reader-progress-slider')),
    );
    slider.onChangeStart!(slider.value);
    slider.onChanged!(0.5);
    await tester.pump();
    slider.onChangeEnd!(0.5);

    await _pumpUntil(
      tester,
      () => _pill(tester).position.chapterProgress > 0.3,
    );
    expect(_pill(tester).position.chapterProgress, lessThan(0.7));
    expect(
      tester
          .widget<ReaderPaperPageLeaf>(find.byType(ReaderPaperPageLeaf))
          .metadata
          .pageNumber,
      greaterThan(1),
    );
  });

  testWidgets('split TXT seek weights a short tail by source length', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    _registerReaderTearDown(tester);
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: NativePageMode.instantPage.name,
      ReaderSettingsStore.progressBarEnabledKey: true,
      ReaderSettingsStore.progressBarScopeKey: ReaderProgressScope.chapter.name,
    });
    final file = _writeBook(
      temporaryDirectory,
      'weighted-split.txt',
      '第1章 分段长度\n\n${List<String>.filled(33000, '字').join()}',
    );
    await _pumpReader(tester, file, replaceRules);
    await _showProgressPill(tester);
    expect(_pill(tester).position.chapterCount, 1);
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('reader-progress-slider')),
    );
    slider.onChangeStart!(slider.value);
    slider.onChanged!(0.75);
    await tester.pump();
    slider.onChangeEnd!(0.75);
    await _pumpUntil(
      tester,
      () => _pill(tester).position.chapterProgress > 0.65,
    );

    final leaf = tester.widget<ReaderPaperPageLeaf>(
      find.byType(ReaderPaperPageLeaf),
    );
    expect(
      leaf.metadata.pageNumber,
      greaterThan(1),
      reason: '75% of a 32K + short-tail chapter remains in its first part.',
    );
  });

  testWidgets('native vertical progress advances inside one long part', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    _registerReaderTearDown(tester);
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: NativePageMode.verticalScroll.name,
      ReaderSettingsStore.progressBarEnabledKey: true,
      ReaderSettingsStore.progressBarScopeKey: ReaderProgressScope.chapter.name,
    });
    final file = _writeBook(
      temporaryDirectory,
      'vertical.txt',
      _chapter('第1章 长卷', '连续阅读', paragraphs: 180),
    );
    await _pumpReader(tester, file, replaceRules);
    await _showProgressPill(tester);
    final before = _pill(tester).position.chapterProgress;
    final window = find.byKey(const ValueKey('native-vertical-reading-window'));
    await tester.drag(window, const Offset(0, -420));
    await tester.pumpAndSettle();
    if (find.byType(ReaderProgressPill).evaluate().isEmpty) {
      await tester.tapAt(const Offset(210, 350));
      await tester.pump();
    }
    await _pumpUntil(
      tester,
      () => _pill(tester).position.chapterProgress > before,
    );
    expect(_pill(tester).position.chapterProgress, greaterThan(0));
  });
}

String _chapter(String title, String prefix, {int paragraphs = 90}) =>
    '$title\n\n${List.generate(paragraphs, (i) => '$prefix 第$i段用于分页和进度验证。').join('\n\n')}\n\n';

File _writeBook(Directory directory, String name, String content) =>
    File('${directory.path}/$name')..writeAsStringSync(content);

Future<void> _pumpReader(
  WidgetTester tester,
  File file,
  ReplaceRuleService replaceRules,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NativeReaderPage(
        replaceRuleService: replaceRules,
        book: Book(
          title: '进度测试',
          filePath: file.path,
          format: 'txt',
          textEncoding: 'utf8',
          fileModifiedTime: file.lastModifiedSync().millisecondsSinceEpoch,
        ),
      ),
    ),
  );
  await _pumpUntil(
    tester,
    () =>
        find.byType(ReaderPaperPageLeaf).evaluate().isNotEmpty ||
        find
            .byKey(const ValueKey('native-vertical-reading-window'))
            .evaluate()
            .isNotEmpty,
  );
}

Future<void> _showProgressPill(WidgetTester tester) async {
  await _pumpUntil(
    tester,
    () => find.byType(ReaderProgressPill).evaluate().isNotEmpty,
  );
  final visiblePill = find.byType(ReaderProgressPill).hitTestable();
  if (visiblePill.evaluate().isNotEmpty) return;
  await tester.tapAt(const Offset(210, 350));
  await tester.pump();
  await _pumpUntil(tester, () => visiblePill.evaluate().isNotEmpty);
}

ReaderProgressPill _pill(WidgetTester tester) =>
    tester.widget<ReaderProgressPill>(find.byType(ReaderProgressPill));

void _registerReaderTearDown(WidgetTester tester) {
  addTearDown(() async {
    await _disposeReader(tester);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for native reader progress state.');
}

Future<void> _disposeReader(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await drainReaderCache(tester);
  await drainReadingCloudWrites(tester);
  await tester.binding.setSurfaceSize(null);
}
