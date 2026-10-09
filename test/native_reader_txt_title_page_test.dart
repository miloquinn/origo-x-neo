import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_layout.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/native/native_reader_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/core/custom_font_service.dart';
import 'package:xxread/services/core/online_font_service.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/utils/book_open_transition.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/pages/settings/replace_rules_page.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';
import 'package:xxread/widgets/reader_chapter_title_page.dart';
import 'package:xxread/widgets/reader_paper_page_leaf.dart';
import 'package:xxread/widgets/reader_text_page_content.dart';
import 'package:xxread/widgets/reader_theme_background.dart';

import 'support/controllable_replace_rule_service.dart';
import 'support/reader_cache_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fullscreenChannel = MethodChannel('com.niki.xxread/fullscreen');
  const readerKeysChannel = MethodChannel('com.niki.xxread/reader_keys');
  const readerStatusChannel = MethodChannel('com.niki.xxread/reader_status');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;
  late File bookFile;
  late ReplaceRuleService replaceRuleService;

  setUp(() {
    replaceRuleService = ReplaceRuleService();
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.instantPage.name,
    });
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'origo-x-txt-title-page-',
    );
    bookFile = File('${temporaryDirectory.path}/title-page.txt')
      ..writeAsStringSync(
        '第十二章  风暴将至\n\n'
        '天边压着墨色的云。\n\n'
        '风从旷野尽头吹来。',
      );

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(fullscreenChannel, (_) async => null);
    messenger.setMockMethodCallHandler(readerKeysChannel, (_) async => null);
    messenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => call.method == 'getApplicationSupportDirectory'
          ? temporaryDirectory.path
          : null,
    );
    messenger.setMockMethodCallHandler(
      readerStatusChannel,
      (_) async => <String, Object?>{'level': 80, 'charging': false},
    );
  });

  tearDown(() async {
    await replaceRuleService.close();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(fullscreenChannel, null);
    messenger.setMockMethodCallHandler(readerKeysChannel, null);
    messenger.setMockMethodCallHandler(readerStatusChannel, null);
    messenger.setMockMethodCallHandler(pathProviderChannel, null);
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('native TXT replacement rules clean title and content', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.instantPage.name,
      ReplaceRuleService.preferenceKey: '''[
        {
          "id":"title",
          "name":"title",
          "pattern":"风暴",
          "replacement":"晨曦",
          "enabled":true,
          "isRegex":false,
          "scopeTitle":true,
          "scopeContent":false,
          "order":0
        },
        {
          "id":"content",
          "name":"content",
          "pattern":"墨色",
          "replacement":"银色",
          "enabled":true,
          "isRegex":false,
          "scopeTitle":false,
          "scopeContent":true,
          "order":1
        }
      ]''',
    });
    await replaceRuleService.close();
    replaceRuleService = ReplaceRuleService();
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NativeReaderPage(
          replaceRuleService: replaceRuleService,
          book: Book(
            title: '测试书',
            filePath: bookFile.path,
            format: 'txt',
            textEncoding: 'utf8',
            fileModifiedTime: bookFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.textContaining('晨曦').evaluate().isNotEmpty) return;
      }
    });
    await _pumpUntilFound(tester, find.textContaining('晨曦'));
    expect(find.textContaining('风暴'), findsNothing);
    expect(_richTextContaining('墨色'), findsNothing);
  });

  testWidgets('native live purification restores original title and body', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_replacementReader(bookFile, replaceRuleService));
    await _waitForNativeText(tester, '风暴');
    await replaceRuleService.upsert(
      const ReplaceRule(
        id: 'live-title',
        name: 'title',
        pattern: '风暴',
        replacement: '晨曦',
        isRegex: false,
        scopeTitle: true,
        scopeContent: false,
      ),
    );
    await replaceRuleService.upsert(
      const ReplaceRule(
        id: 'live-body',
        name: 'body',
        pattern: '墨色',
        replacement: '银色',
        isRegex: false,
      ),
    );
    await _waitForNativeText(tester, '晨曦');
    expect(find.textContaining('风暴'), findsNothing);
    await replaceRuleService.setDefaultEnabled(false);
    await _waitForNativeText(tester, '风暴');
    expect(find.textContaining('晨曦'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native latest purification wins when old body finishes last', (
    tester,
  ) async {
    await replaceRuleService.close();
    final controlled = ControllableReplaceRuleService();
    replaceRuleService = controlled;
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    await tester.pumpWidget(_replacementReader(bookFile, controlled));
    await _waitForNativeText(tester, '墨色');
    controlled.delayBodies = true;
    await controlled.upsert(
      const ReplaceRule(
        id: 'race',
        name: 'body',
        pattern: '墨色',
        replacement: '银色',
        isRegex: false,
      ),
    );
    await _waitForPendingBodies(tester, controlled, 1);
    // A rebuild during the suspended replacement must not mark raw text as
    // already purified, or prevent the next generation from starting.
    await tester.pump();
    await controlled.upsert(
      const ReplaceRule(
        id: 'race',
        name: 'body',
        pattern: '墨色',
        replacement: '金色',
        isRegex: false,
      ),
    );
    await _waitForPendingBodies(tester, controlled, 2);
    controlled.pendingBodies[1].complete();
    await _waitForNativeText(tester, '金色');
    controlled.pendingBodies[0].complete();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_richTextContaining('金色'), findsWidgets);
    expect(_richTextContaining('银色'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native source rules read registered nested source config', (
    tester,
  ) async {
    await replaceRuleService.upsert(
      const ReplaceRule(
        id: 'source-body',
        name: 'body',
        pattern: '墨色',
        replacement: '银色',
        isRegex: false,
        scope: 'https://actual-source.example',
      ),
    );
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
      ReplaceRuleService.preferenceKey: jsonEncode(
        replaceRuleService.rules.map((r) => r.toJson()).toList(),
      ),
    });
    await tester.pumpWidget(
      _replacementReader(
        bookFile,
        replaceRuleService,
        sourceJson: jsonEncode({
          'name': 'Registered source',
          'manifestUrl': 'https://manifest.example/source.json',
          'sourceConfig': {
            'bookSourceUrl': 'https://actual-source.example',
            'bookSourceName': 'Nested source',
          },
        }),
      ),
    );
    await _waitForNativeText(tester, '银色');
    expect(_richTextContaining('墨色'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native initial title batch retries after a rule save', (
    tester,
  ) async {
    await replaceRuleService.close();
    final controlled = ControllableReplaceRuleService()..delayNextTitle = true;
    replaceRuleService = controlled;
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_replacementReader(bookFile, controlled));
    for (
      var attempt = 0;
      attempt < 40 && controlled.pendingTitles.isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(controlled.pendingTitles, hasLength(1));
    await controlled.upsert(
      const ReplaceRule(
        id: 'initial-title',
        name: 'title',
        pattern: '风暴',
        replacement: '晨曦',
        isRegex: false,
        scopeTitle: true,
        scopeContent: false,
      ),
    );
    controlled.pendingTitles.single.complete();
    await _waitForNativeText(tester, '晨曦');
    expect(find.textContaining('风暴'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('native book rule entry shares the DB key and current effects', (
    tester,
  ) async {
    bookFile.writeAsStringSync('第十二章 风暴将至\n墨色的云。\n第十三章 另一章\n远古的云。');
    await replaceRuleService.upsert(
      const ReplaceRule(
        id: 'current-body',
        name: 'body',
        pattern: '墨色',
        replacement: '银色',
        isRegex: false,
      ),
    );
    await replaceRuleService.upsert(
      const ReplaceRule(
        id: 'neighbor-body',
        name: 'other body',
        pattern: '远古',
        replacement: '现代',
        isRegex: false,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _replacementReader(bookFile, replaceRuleService, bookId: 7),
    );
    await _waitForNativeText(tester, '风暴');
    await tester.tapAt(tester.getCenter(find.byType(NativeReaderPage)));
    await tester.pump(const Duration(milliseconds: 350));
    tester
        .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
        .onBookSettings!();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('book-settings-replace-rules-action')),
    );
    await tester.pumpAndSettle();
    for (
      var attempt = 0;
      attempt < 30 && find.byType(ReplaceRulesPage).evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    final rulesPage = tester.widget<ReplaceRulesPage>(
      find.byType(ReplaceRulesPage),
    );
    expect(rulesPage.bookId, 'book:7');
    expect(rulesPage.effectiveRuleIds, contains('current-body'));
    expect(rulesPage.effectiveRuleIds, isNot(contains('neighbor-body')));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TXT chapter title is a dedicated first page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NativeReaderPage(
          replaceRuleService: replaceRuleService,
          book: Book(
            title: '测试书',
            filePath: bookFile.path,
            format: 'txt',
            textEncoding: 'utf8',
            fileModifiedTime: bookFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find
            .byKey(const ValueKey('native-chapter-title-page'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
    });

    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('native-chapter-title-page')),
    );

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('native-chapter-title-page')),
    );
    expect(title.data, '第十二章  风暴将至');
    expect(title.textAlign, TextAlign.center);
    expect(title.style?.fontSize, 34);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(_richTextContaining('天边压着墨色的云。'), findsNothing);
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.tune_rounded),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Layout'));
    await tester.pumpAndSettle();
    final titleSwitch = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('reader-chapter-title-page-switch')),
    );
    expect(titleSwitch.value, isTrue);
    titleSwitch.onChanged!(false);
    await tester.pumpAndSettle();
    expect(
      (await const ReaderSettingsStore().load()).chapterTitlePageEnabled,
      isFalse,
    );
  });

  testWidgets('native open failure keeps the seeded reader theme background', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.instantPage.name,
      ReaderSettingsStore.themeKey: ReaderThemes.night.id,
    });
    final brokenFile = File('${temporaryDirectory.path}/broken.epub')
      ..writeAsBytesSync(const [0, 1, 2, 3]);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NativeReaderPage(
          replaceRuleService: replaceRuleService,
          initialTheme: ReaderThemes.night,
          book: Book(
            title: 'Broken EPUB',
            filePath: brokenFile.path,
            format: 'epub',
            fileModifiedTime: brokenFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find
            .byKey(const ValueKey('native-reader-error'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
    });
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('native-reader-error')),
    );

    final background = tester.widget<ReaderThemeBackground>(
      find.descendant(
        of: find.byKey(const ValueKey('native-reader-error')),
        matching: find.byType(ReaderThemeBackground),
      ),
    );
    expect(background.palette.background, ReaderThemes.night.background);
    expect(find.textContaining('Broken EPUB'), findsWidgets);
  });

  testWidgets('disabled TXT title page places the heading above body text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.instantPage.name,
      ReaderSettingsStore.chapterTitlePageKey: false,
    });
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NativeReaderPage(
          replaceRuleService: replaceRuleService,
          book: Book(
            title: '测试书',
            filePath: bookFile.path,
            format: 'txt',
            textEncoding: 'utf8',
            fileModifiedTime: bookFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find
            .byKey(ReaderInlineChapterTitle.contentKey)
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
    });
    await _pumpUntilFound(
      tester,
      find.byKey(ReaderInlineChapterTitle.contentKey),
    );

    expect(find.byKey(ReaderChapterTitlePage.contentKey), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(ReaderInlineChapterTitle.contentKey)).data,
      '第十二章  风暴将至',
    );
    expect(_richTextContaining('天边压着墨色的云。'), findsOneWidget);
    final bodyText = tester
        .widgetList<RichText>(_richTextContaining('天边压着墨色的云。'))
        .single
        .text
        .toPlainText();
    expect(bodyText, contains('风从旷野尽头吹来。'));
    expect(bodyText, isNot(contains('\n\n')));
    expect(find.text('1 / 1'), findsOneWidget);
  });

  testWidgets('opening placeholder uses the seeded reader theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: NativeReaderPage(
          replaceRuleService: replaceRuleService,
          initialTheme: ReaderThemes.pureBlack,
          book: Book(
            title: 'Dark opening',
            filePath: bookFile.path,
            format: 'txt',
            textEncoding: 'utf8',
            fileModifiedTime: bookFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
        ),
      ),
    );

    final placeholderBackground = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('native-reader-opening-placeholder')),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(placeholderBackground.color, ReaderThemes.pureBlack.background);

    expect(
      tester
          .widget<AnimatedPositioned>(
            find.byKey(const ValueKey('native-reader-opening-top-controls')),
          )
          .top,
      -130,
    );
    await tester.tapAt(
      tester
          .getRect(
            find.byKey(const ValueKey('native-reader-opening-placeholder')),
          )
          .center,
    );
    await tester.pump();
    expect(
      tester
          .widgetList<AnimatedPositioned>(
            find.byKey(const ValueKey('native-reader-opening-top-controls')),
          )
          .any((bar) => bar.top == 10),
      isTrue,
    );
  });

  testWidgets('waits for reader font restoration before revealing text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appSettings = _ControllableAppSettingsNotifier(temporaryDirectory);
    addTearDown(appSettings.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsNotifier>.value(
        value: appSettings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'Font restoration',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      ),
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('native-reader-opening-placeholder')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('native-reader-content')), findsNothing);

    appSettings.markReaderFontReady();
    await tester.pump();
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find
            .byKey(const ValueKey('native-reader-content'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
    });
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('native-reader-content')),
    );
  });

  testWidgets('applies reader system UI before revealing the first text page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final applyStarted = Completer<void>();
    final finishApply = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(fullscreenChannel, (call) async {
          if (call.method == 'hideSystemUI') {
            if (!applyStarted.isCompleted) applyStarted.complete();
            await finishApply.future;
          }
          return null;
        });

    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'Stable opening geometry',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (applyStarted.isCompleted) return;
        }
      });
      expect(applyStarted.isCompleted, isTrue);
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find
              .byKey(const ValueKey('native-reader-content'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
      });
      expect(find.byKey(const ValueKey('native-reader-content')), findsNothing);

      finishApply.complete();
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find
              .byKey(const ValueKey('native-reader-content'))
              .evaluate()
              .isNotEmpty) {
            return;
          }
        }
      });
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('native-reader-content')),
      );
    } finally {
      if (!finishApply.isCompleted) finishApply.complete();
    }
  });

  testWidgets(
    'vertical paging preserves the dedicated TXT chapter title page',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.verticalScroll.name,
      });
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'Vertical title test',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find
              .byKey(const ValueKey('native-chapter-title-page'))
              .evaluate()
              .isNotEmpty) {
            return;
          }
        }
      });

      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('native-chapter-title-page')),
      );

      expect(
        find.byKey(const ValueKey('native-chapter-title-page')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('native-vertical-reading-window')),
        findsOneWidget,
      );
    },
  );

  for (final (fontSize, lineHeight) in [(19.0, 1.75), (28.0, 2.0)]) {
    testWidgets('continuous TXT chapters leave a body-scaled gap '
        '(fontSize=$fontSize, lineHeight=$lineHeight)', (tester) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.verticalScroll.name,
        ReaderSettingsStore.scrollByChapterKey: false,
        ReaderSettingsStore.chapterTitlePageKey: false,
        ReaderSettingsStore.fontSizeKey: fontSize,
        ReaderSettingsStore.lineHeightKey: lineHeight,
      });
      bookFile.writeAsStringSync(
        '第1章 风暴将至\n\n上一章的最后一段。\n\n'
        '第2章 雨过天晴\n\n下一章的第一段。',
      );
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: '章间距测试',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      final nextPage = find.byWidgetPredicate(
        (widget) =>
            widget is ReaderAnnotatedTextPage &&
            widget.chapterTitle == '第2章 雨过天晴',
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 30; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (nextPage.evaluate().isNotEmpty) return;
        }
      });
      await _pumpUntilFound(tester, nextPage);
      final previousPage = find.byWidgetPredicate(
        (widget) =>
            widget is ReaderAnnotatedTextPage &&
            widget.chapterTitle == '第1章 风暴将至',
      );
      final nextHeading = find.descendant(
        of: nextPage,
        matching: find.byType(ReaderInlineChapterTitle),
      );
      expect(
        tester.getTopLeft(nextHeading).dy -
            tester.getBottomLeft(previousPage).dy,
        closeTo(fontSize * lineHeight * 1.5, 0.5),
      );
      final next = tester.widget<ReaderAnnotatedTextPage>(nextPage);
      expect(next.page.startOffset, 0);
      expect(next.sourceText, contains('下一章的第一段。'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  for (final chapterTitlePageEnabled in [true, false]) {
    for (final scrollByChapter in [true, false]) {
      testWidgets('vertical TXT TOC jump aligns the chapter start '
          '(titlePage=$chapterTitlePageEnabled, '
          'scrollByChapter=$scrollByChapter)', (tester) async {
        SharedPreferences.setMockInitialValues({
          ReaderSettingsStore.pageModeKey: ReaderPageMode.verticalScroll.name,
          ReaderSettingsStore.chapterTitlePageKey: chapterTitlePageEnabled,
          ReaderSettingsStore.scrollByChapterKey: scrollByChapter,
        });
        const targetTitle = '第8章 远方的灯塔';
        bookFile.writeAsStringSync(
          List.generate(9, (chapterIndex) {
            final chapterNumber = chapterIndex + 1;
            final title = chapterNumber == 8
                ? targetTitle
                : '第$chapterNumber章 长篇测试章节';
            final body = List.generate(
              48,
              (paragraphIndex) =>
                  '第$chapterNumber章第$paragraphIndex段正文，'
                  '用于确保目录远距离跳转需要跨过多个长章节。',
            ).join('\n\n');
            return '$title\n\n$body';
          }).join('\n\n'),
        );
        await tester.binding.setSurfaceSize(const Size(400, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: '竖向目录对齐测试',
                filePath: bookFile.path,
                format: 'txt',
                textEncoding: 'utf8',
                fileModifiedTime: bookFile
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );

        final readingWindow = find.byKey(
          const ValueKey('native-vertical-reading-window'),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 200; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (readingWindow.evaluate().isNotEmpty) return;
          }
        });
        await _pumpUntilFound(tester, readingWindow);
        expect(_chapterHeading('第1章 长篇测试章节'), findsOneWidget);

        for (var jump = 0; jump < 2; jump++) {
          await _jumpToTxtChapter(tester, targetTitle);
          final heading = _chapterHeading(targetTitle);
          await _pumpUntilFound(tester, heading);
          await tester.pumpAndSettle();

          final visibleTop = _verticalReadingContentTop(tester, readingWindow);
          if (chapterTitlePageEnabled) {
            final pageRect = _chapterTitlePageFrameRect(tester, heading);
            expect(
              pageRect.top,
              closeTo(visibleTop, 1),
              reason:
                  'A dedicated chapter-title page must align its whole '
                  'page frame to the visible reading window after TOC jump '
                  '${jump + 1}.',
            );
            expect(
              pageRect.height,
              closeTo(_verticalReadingContentHeight(tester, readingWindow), 1),
            );
          } else {
            final headingRect = tester.getRect(heading);
            expect(
              headingRect.top,
              closeTo(visibleTop, 1),
              reason:
                  'An inline chapter heading must start at the visible '
                  'reading window after TOC jump ${jump + 1}.',
            );
            final bodyRect = _targetChapterBodyRect(tester, targetTitle);
            expect(bodyRect.top, greaterThan(headingRect.bottom));
            expect(
              headingRect.center.dy,
              lessThan(
                visibleTop +
                    _verticalReadingContentHeight(tester, readingWindow) / 3,
              ),
              reason:
                  'The chapter start must not be centered like a dedicated '
                  'title page when the title-page setting is disabled.',
            );
          }
          if (jump == 0) {
            await tester.drag(readingWindow, const Offset(0, -520));
            await tester.pumpAndSettle();
          }
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets(
    'iOS vertical TXT keeps its canonical center anchor across all lifecycle layout configurations',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
      try {
        for (final chapterTitlePageEnabled in [true, false]) {
          for (final scrollByChapter in [true, false]) {
            SharedPreferences.setMockInitialValues({
              ReaderSettingsStore.pageModeKey:
                  ReaderPageMode.verticalScroll.name,
              ReaderSettingsStore.chapterTitlePageKey: chapterTitlePageEnabled,
              ReaderSettingsStore.scrollByChapterKey: scrollByChapter,
            });
            bookFile.writeAsStringSync(
              List.generate(12, (chapterIndex) {
                final chapterNumber = chapterIndex + 1;
                final body = List.generate(
                  32,
                  (paragraphIndex) =>
                      '第$chapterNumber章第$paragraphIndex段正文，用于验证前后台恢复后的中心阅读位置。',
                ).join('\n\n');
                return '第$chapterNumber章 生命周期测试\n\n$body';
              }).join('\n\n'),
            );

            await tester.pumpWidget(
              MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: NativeReaderPage(
                  replaceRuleService: replaceRuleService,
                  paginationCacheDao: MemoryPaginationCacheDao(),
                  usePaginationMemoryCache: false,
                  book: Book(
                    title: 'iOS 生命周期回归',
                    filePath: bookFile.path,
                    format: 'txt',
                    textEncoding: 'utf8',
                    fileModifiedTime: bookFile
                        .lastModifiedSync()
                        .millisecondsSinceEpoch,
                  ),
                ),
              ),
            );

            final readingWindow = find.byKey(
              const ValueKey('native-vertical-reading-window'),
            );
            await tester.runAsync(() async {
              for (var attempt = 0; attempt < 200; attempt++) {
                await Future<void>.delayed(const Duration(milliseconds: 50));
                await tester.pump();
                if (readingWindow.evaluate().isNotEmpty) return;
              }
            });
            await _pumpUntilFound(tester, readingWindow);

            await _jumpToTxtChapter(tester, '第6章 生命周期测试');
            await tester.pumpAndSettle();
            _NativeCenterAnchor? before;
            for (var attempt = 0; attempt < 12; attempt++) {
              await tester.drag(readingWindow, const Offset(0, -680));
              await tester.pumpAndSettle();
              try {
                final candidate = _nativeCenterAnchor(tester);
                if (candidate.chapterIndex == 5 &&
                    candidate.sourceOffset > 200) {
                  before = candidate;
                  break;
                }
              } on TestFailure {
                // A dedicated title page or chapter gap can briefly cover center.
              }
            }
            expect(
              before,
              isNotNull,
              reason:
                  'The fixture must reach the middle of a later TXT chapter.',
            );

            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            tester.view.padding = FakeViewPadding.zero;
            tester.view.viewPadding = FakeViewPadding.zero;
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 100));

            tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
            tester.view.viewPadding = const FakeViewPadding(
              top: 59,
              bottom: 34,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();

            final after = _nativeCenterAnchor(tester);
            _expectSameNativeCenterAnchor(before!, after);

            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            await tester.pump();
            expect(
              find.byKey(const ValueKey('native-reader-content')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('native-reader-opening-placeholder')),
              findsNothing,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.hidden,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('native-reader-content')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('native-reader-opening-placeholder')),
              findsNothing,
            );
            final stableMetricsAfter = _nativeCenterAnchor(tester);
            _expectSameNativeCenterAnchor(after, stableMetricsAfter);

            tester
                .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
                .onTableOfContents!();
            await tester.pumpAndSettle();
            final navigation = tester.widget<ReaderNavigationSheet>(
              find.byType(ReaderNavigationSheet),
            );
            expect(
              navigation.currentChapterIndex,
              stableMetricsAfter.chapterIndex,
            );
            expect(
              navigation.currentChapterOffset,
              closeTo(stableMetricsAfter.sourceOffset, 2),
            );
            expect(
              navigation.chapters
                  .where(
                    (chapter) =>
                        chapter.index == stableMetricsAfter.chapterIndex,
                  )
                  .map((chapter) => chapter.title),
              contains(stableMetricsAfter.chapterTitle),
            );
            expect(tester.takeException(), isNull);
            final navigationSheet = find.byType(ReaderNavigationSheet);
            Navigator.of(tester.element(navigationSheet)).pop();
            await tester.pumpAndSettle();
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
        }
      } finally {
        final navigationSheet = find.byType(ReaderNavigationSheet);
        if (navigationSheet.evaluate().isNotEmpty) {
          Navigator.of(tester.element(navigationSheet)).pop();
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetViewPadding();
      }
    },
  );

  testWidgets(
    'horizontal TOC jump mounts the target title on the first frame and keeps the previous page ready',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
      });
      bookFile.writeAsStringSync(
        List.generate(8, (chapterIndex) {
          final chapterNumber = chapterIndex + 1;
          final title = chapterNumber == 8 ? '第8章 远方' : '第$chapterNumber章 测试章节';
          final body = List.generate(
            36,
            (paragraphIndex) =>
                '第$chapterNumber章第$paragraphIndex段正文，用于确保上一章末页已经完成分页。',
          ).join('\n\n');
          return '$title\n\n$body';
        }).join('\n\n'),
      );
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: '目录远跳测试',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      final readerPageView = find.descendant(
        of: find.byType(NativeReaderPage),
        matching: find.byType(PageView),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 40; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (readerPageView.evaluate().isNotEmpty) return;
        }
      });
      await _pumpUntilFound(tester, readerPageView);
      final originalController = tester
          .widget<PageView>(readerPageView)
          .controller!;

      await tester.tapAt(tester.getRect(readerPageView).center);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(ReaderNavigationSheet),
          matching: find.byType(TextField),
        ),
        '第8章',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ReaderNavigationSheet),
          matching: find.text('第8章 远方'),
        ),
      );
      await tester.pump();

      final jumpedController = tester
          .widget<PageView>(readerPageView)
          .controller!;
      expect(jumpedController, isNot(same(originalController)));
      await tester.pump();
      expect(
        tester
            .widgetList<Text>(
              find.byKey(const ValueKey('native-chapter-title-page')),
            )
            .any((title) => title.data == '第8章 远方'),
        isTrue,
      );

      final titlePage = jumpedController.page!;
      final settledChildCount = tester
          .widget<PageView>(readerPageView)
          .childrenDelegate
          .estimatedChildCount!;
      final pageViewRect = tester.getRect(readerPageView);
      final backwardGesture = await tester.startGesture(
        Offset(pageViewRect.left + 8, pageViewRect.center.dy),
      );
      await backwardGesture.moveBy(Offset(pageViewRect.width * 0.65, 0));
      await tester.pump();
      final heldPage = jumpedController.page!;
      expect(heldPage, isNot(heldPage.roundToDouble()));
      expect(
        tester.widget<PageView>(readerPageView).controller,
        same(jumpedController),
      );
      expect(
        tester
            .widget<PageView>(readerPageView)
            .childrenDelegate
            .estimatedChildCount,
        settledChildCount,
      );

      await backwardGesture.up();
      await tester.pumpAndSettle();
      final previousPageController = tester
          .widget<PageView>(readerPageView)
          .controller!;
      expect(previousPageController, same(jumpedController));
      final pageView = tester.widget<PageView>(readerPageView);
      final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
      final visibleLeaf = delegate.builder(
        tester.element(readerPageView),
        previousPageController.page!.round(),
      );
      expect(visibleLeaf, isA<ReaderPaperPageLeaf>());
      final metadata = (visibleLeaf! as ReaderPaperPageLeaf).metadata;
      expect(metadata.chapterTitle, '第7章 测试章节');
      expect(metadata.pageNumber, metadata.pageCount);
      expect(titlePage, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'TXT horizontal paging keeps its legacy delegate stable during a chapter turn',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
      });
      bookFile.writeAsStringSync(
        List.generate(4, (chapterIndex) {
          final chapterNumber = chapterIndex + 1;
          final body = List.generate(
            28,
            (paragraphIndex) => '第$chapterNumber章第$paragraphIndex段，用于水平分页回归测试。',
          ).join('\n\n');
          return '第$chapterNumber章 测试章节\n\n$body';
        }).join('\n\n'),
      );
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'TXT 水平分页回归',
              filePath: bookFile.path,
              format: 'txt',
              textEncoding: 'utf8',
              fileModifiedTime: bookFile
                  .lastModifiedSync()
                  .millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      final pageView = find.descendant(
        of: find.byType(NativeReaderPage),
        matching: find.byType(PageView),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 40; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (pageView.evaluate().isNotEmpty) return;
        }
      });
      await _pumpUntilFound(tester, pageView);

      final pageViewWidget = tester.widget<PageView>(pageView);
      final delegate = pageViewWidget.childrenDelegate;
      expect(delegate, isA<SliverChildBuilderDelegate>());
      expect(
        (delegate as SliverChildBuilderDelegate).findChildIndexCallback,
        isNull,
      );

      final currentPage = pageViewWidget.controller?.page?.round() ?? 0;
      final firstChapterPages = <int>[];
      final firstIndex = math.max(0, currentPage - 160);
      final lastIndex = math.min(
        delegate.estimatedChildCount! - 1,
        currentPage + 160,
      );
      for (var index = firstIndex; index <= lastIndex; index++) {
        final leaf = delegate.builder(tester.element(pageView), index);
        if (leaf is! ReaderPaperPageLeaf) continue;
        if (leaf.metadata.chapterTitle == '第1章 测试章节') {
          firstChapterPages.add(index);
        }
      }
      expect(firstChapterPages, isNotEmpty);

      final controller = pageViewWidget.controller!;
      controller.jumpToPage(firstChapterPages.last);
      await tester.pumpAndSettle();
      final settledChildCount = tester
          .widget<PageView>(pageView)
          .childrenDelegate
          .estimatedChildCount!;
      final rect = tester.getRect(pageView);
      final forwardGesture = await tester.startGesture(
        Offset(rect.right - 8, rect.center.dy),
      );
      await forwardGesture.moveBy(const Offset(-150, 0));
      await tester.pump();
      await forwardGesture.moveBy(Offset(-rect.width * 0.35, 0));
      await tester.pump();

      final heldPage = controller.page!;
      expect(heldPage, isNot(heldPage.roundToDouble()));
      expect(tester.widget<PageView>(pageView).controller, same(controller));
      expect(
        tester.widget<PageView>(pageView).childrenDelegate.estimatedChildCount,
        settledChildCount,
      );

      await forwardGesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageView>(pageView).childrenDelegate.estimatedChildCount,
        greaterThan(settledChildCount),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TXT initialization preloads behind the cover route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final navigatorKey = GlobalKey<NavigatorState>();
    final coverKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: coverKey,
              width: 120,
              height: 180,
              child: const ColoredBox(color: Colors.brown),
            ),
          ),
        ),
      ),
    );
    final animation = BookOpenAnimation.fromCoverKey(
      coverKey,
      radius: BorderRadius.circular(12),
      coverBuilder: (_) => const ColoredBox(color: Colors.brown),
    );

    navigatorKey.currentState!.push<void>(
      BookOpenTransition.createRoute<void>(
        (_) => NativeReaderPage(
          replaceRuleService: replaceRuleService,
          book: Book(
            title: 'Transition test',
            filePath: bookFile.path,
            format: 'txt',
            textEncoding: 'utf8',
            fileModifiedTime: bookFile
                .lastModifiedSync()
                .millisecondsSinceEpoch,
          ),
          initialTheme: ReaderThemes.day,
        ),
        animation: animation,
        readerBackgroundColor: ReaderThemes.day.background,
        waitForReaderReady: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('book-open-transition-deferred-page')),
      findsNothing,
    );
    expect(find.byType(NativeReaderPage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 30; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find
            .byKey(const ValueKey('native-chapter-title-page'))
            .evaluate()
            .isNotEmpty) {
          return;
        }
      }
    });
    expect(
      find.byKey(const ValueKey('native-chapter-title-page')),
      findsOneWidget,
    );
    final readerOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('book-open-transition-reader-opacity')),
    );
    expect(readerOpacity.opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  });
}

class _ControllableAppSettingsNotifier extends AppSettingsNotifier {
  _ControllableAppSettingsNotifier(Directory directory)
    : super(
        customFontService: CustomFontService(
          supportDirectory: () async => directory,
          registrar: (_, _) async {},
        ),
        onlineFontService: OnlineFontService(
          supportDirectory: () async => directory,
          registrar: (_, _, _) async {},
        ),
      );

  bool _readerFontReady = false;

  @override
  bool get isInitialized => _readerFontReady;

  @override
  FontOption get readerFont => FontCatalog.systemFont;

  void markReaderFontReady() {
    _readerFontReady = true;
    notifyListeners();
  }
}

Finder _richTextContaining(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(text),
);

typedef _NativeCenterAnchor = ({
  int chapterIndex,
  String chapterTitle,
  int sourceOffset,
  double caretY,
});

void _expectSameNativeCenterAnchor(
  _NativeCenterAnchor before,
  _NativeCenterAnchor after,
) {
  expect(after.chapterIndex, before.chapterIndex);
  expect(
    after.sourceOffset,
    closeTo(before.sourceOffset, 2),
    reason: 'The restored body must keep the same canonical text anchor.',
  );
  expect(
    after.caretY,
    closeTo(before.caretY, 20),
    reason: 'The canonical text anchor must remain at viewport center.',
  );
}

_NativeCenterAnchor _nativeCenterAnchor(WidgetTester tester) {
  final center =
      tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
  for (final element in find.byType(ReaderAnnotatedTextPage).evaluate()) {
    final page = element.widget as ReaderAnnotatedTextPage;
    final paragraphs = find.descendant(
      of: find.byWidget(page),
      matching: find.byElementPredicate((candidate) {
        if (candidate.widget is! RichText) return false;
        var isBody = false;
        candidate.visitAncestorElements((ancestor) {
          if (ancestor.widget is ReaderInlineChapterTitle ||
              ancestor.widget is ReaderChapterTitlePage) {
            return false;
          }
          if (ancestor.widget is ReaderTextPageContent) {
            isBody = true;
            return false;
          }
          if (ancestor.widget == page) return false;
          return true;
        });
        return isBody;
      }),
    );
    for (final rich in paragraphs.evaluate()) {
      final paragraph = rich.renderObject as RenderParagraph;
      final top = paragraph.localToGlobal(Offset.zero).dy;
      if (top > center || top + paragraph.size.height < center) continue;
      final position = paragraph.getPositionForOffset(
        Offset(paragraph.size.width / 2, center - top),
      );
      return (
        chapterIndex: page.chapterIndex,
        chapterTitle: page.chapterTitle,
        sourceOffset: page.page.sourceOffsetForTextOffset(position.offset),
        caretY: top + paragraph.getOffsetForCaret(position, Rect.zero).dy,
      );
    }
  }
  throw TestFailure('No native TXT body paragraph at viewport center');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();
  fail(
    'Timed out waiting for $finder. Texts: $texts. '
    'Exception: ${tester.takeException()}',
  );
}

Finder _chapterHeading(String title) => find.byWidgetPredicate(
  (widget) =>
      widget is Text &&
      widget.data == title &&
      (widget.key == ReaderChapterTitlePage.contentKey ||
          widget.key == ReaderInlineChapterTitle.contentKey),
  description: 'rendered chapter heading "$title"',
);

Future<void> _jumpToTxtChapter(WidgetTester tester, String title) async {
  final readingWindow = find.byKey(
    const ValueKey('native-vertical-reading-window'),
  );
  await tester.tapAt(tester.getRect(readingWindow).center);
  await tester.pumpAndSettle();
  tester
      .widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.format_list_bulleted_rounded),
          matching: find.byType(IconButton),
        ),
      )
      .onPressed!();
  await tester.pumpAndSettle();
  final navigationSheet = find.byType(ReaderNavigationSheet);
  await tester.enterText(
    find.descendant(of: navigationSheet, matching: find.byType(TextField)),
    title,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: navigationSheet,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == title,
      ),
    ),
  );
  await tester.pump();
}

double _verticalReadingContentTop(WidgetTester tester, Finder readingWindow) {
  final padding = tester
      .widget<Padding>(readingWindow)
      .padding
      .resolve(TextDirection.ltr);
  return tester.getTopLeft(readingWindow).dy + padding.top;
}

double _verticalReadingContentHeight(
  WidgetTester tester,
  Finder readingWindow,
) {
  final padding = tester
      .widget<Padding>(readingWindow)
      .padding
      .resolve(TextDirection.ltr);
  return tester.getSize(readingWindow).height - padding.vertical;
}

Rect _chapterTitlePageFrameRect(WidgetTester tester, Finder heading) {
  final readingWindow = find.byKey(
    const ValueKey('native-vertical-reading-window'),
  );
  final expectedHeight = _verticalReadingContentHeight(tester, readingWindow);
  Rect? frame;
  heading.evaluate().single.visitAncestorElements((ancestor) {
    final renderObject = ancestor.renderObject;
    if (renderObject is! RenderBox || !renderObject.hasSize) return true;
    if ((renderObject.size.height - expectedHeight).abs() <= 1) {
      frame = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      return false;
    }
    return true;
  });
  expect(
    frame,
    isNotNull,
    reason: 'The dedicated chapter title must be mounted in a full-page cell.',
  );
  return frame!;
}

Rect _targetChapterBodyRect(WidgetTester tester, String title) {
  final targetPage = tester
      .widgetList<ReaderAnnotatedTextPage>(find.byType(ReaderAnnotatedTextPage))
      .singleWhere(
        (page) =>
            page.chapterTitle == title && page.page.showsInlineChapterTitle,
      );
  final body = find.descendant(
    of: find.byWidget(targetPage),
    matching: find.byType(RichText),
  );
  final bodyParagraph = body.evaluate().firstWhere((element) {
    var belongsToHeading = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is ReaderInlineChapterTitle) {
        belongsToHeading = true;
        return false;
      }
      if (ancestor.widget == targetPage) return false;
      return true;
    });
    return !belongsToHeading;
  });
  final renderObject = bodyParagraph.renderObject! as RenderBox;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}

Widget _replacementReader(
  File file,
  ReplaceRuleService rules, {
  String? sourceJson,
  int? bookId,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: NativeReaderPage(
    replaceRuleService: rules,
    book: Book(
      title: '测试书',
      filePath: file.path,
      format: 'txt',
      textEncoding: 'utf8',
      id: bookId,
      sourceJson: sourceJson,
      sourceLocator: 'source-id-that-is-not-a-url',
      fileModifiedTime: file.lastModifiedSync().millisecondsSinceEpoch,
    ),
  ),
);

Future<void> _waitForNativeText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.textContaining(text, findRichText: true).evaluate().isNotEmpty) {
      return;
    }
  }
  expect(find.textContaining(text, findRichText: true), findsWidgets);
}

Future<void> _waitForPendingBodies(
  WidgetTester tester,
  ControllableReplaceRuleService rules,
  int count,
) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (rules.pendingBodies.length >= count) return;
  }
  expect(rules.pendingBodies.length, greaterThanOrEqualTo(count));
}
