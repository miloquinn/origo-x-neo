import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/core/reader/reader_layout.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/native/native_reader_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/reader/replace_rule_execution.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';
import 'package:xxread/widgets/reader_paper_page_leaf.dart';
import 'package:xxread/widgets/reader_shader_page_curl.dart';

import 'support/controllable_replace_rule_service.dart';
import 'support/reader_cache_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory supportDirectory;
  late ReplaceRuleService replaceRuleService;

  setUpAll(() {
    supportDirectory = Directory.systemTemp.createTempSync(
      'origo-x-epub-transition-support-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => supportDirectory.path,
        );
  });

  setUp(() {
    replaceRuleService = ReplaceRuleService();
  });

  tearDown(() async {
    await replaceRuleService.close();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    supportDirectory.deleteSync(recursive: true);
  });

  test('only book-embedded mode preserves EPUB font', () {
    expect(
      resolveNativeReaderFontFamily(
        readerFontFamily: 'sans-serif',
        documentFontFamily: 'Embedded EPUB Font',
        preserveDocumentFont: true,
      ),
      'Embedded EPUB Font',
    );
    expect(
      resolveNativeReaderFontFamily(
        readerFontFamily: 'PingFang SC',
        documentFontFamily: 'Embedded EPUB Font',
        preserveDocumentFont: false,
      ),
      'PingFang SC',
    );
    expect(
      resolveNativeReaderFontFamily(
        readerFontFamily: 'sans-serif',
        documentFontFamily: 'serif',
        preserveDocumentFont: false,
      ),
      'sans-serif',
    );
  });

  testWidgets(
    'switching EPUB font updates the visible and adjacent text pages',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-font-switch-',
      );
      final epub = File(
        '${directory.path}/font-switch.epub',
      )..writeAsBytesSync(_epubFixture(chapterCount: 1, serifParagraphs: true));
      late final AppSettingsNotifier settings;
      try {
        await tester.runAsync(() async {
          settings = AppSettingsNotifier();
          for (
            var attempt = 0;
            attempt < 100 && !settings.isInitialized;
            attempt++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          expect(settings.isInitialized, isTrue);
        });
        await tester.pumpWidget(
          ChangeNotifierProvider<AppSettingsNotifier>.value(
            value: settings,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: NativeReaderPage(
                replaceRuleService: replaceRuleService,
                book: Book(
                  title: 'EPUB font switch fixture',
                  filePath: epub.path,
                  format: 'epub',
                  fileModifiedTime: epub
                      .lastModifiedSync()
                      .millisecondsSinceEpoch,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 60; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (find.byType(ReaderAnnotatedTextPage).evaluate().isNotEmpty) {
              return;
            }
          }
        });
        await _pumpUntil(
          tester,
          () => find.byType(ReaderAnnotatedTextPage).evaluate().isNotEmpty,
        );

        ReaderAnnotatedTextPage visiblePage() =>
            tester.widget<ReaderAnnotatedTextPage>(
              find.byType(ReaderAnnotatedTextPage).first,
            );
        final firstPage = visiblePage();
        expect(firstPage.bodyStyle.fontFamily, 'sans-serif');
        expect(
          _leafFontFamilies(
            firstPage.baseSourceSpanBuilder!(
              firstPage.page.startOffset,
              firstPage.page.endOffset,
            ),
          ),
          contains('serif'),
        );

        await settings.setEpubReaderFontId(FontCatalog.systemId);
        await tester.pumpAndSettle();
        final systemPage = visiblePage();
        expect(systemPage.bodyStyle.fontFamily, 'sans-serif');
        expect(
          _leafFontFamilies(
            systemPage.baseSourceSpanBuilder!(
              systemPage.page.startOffset,
              systemPage.page.endOffset,
            ),
          ),
          isNot(contains('serif')),
        );
        final firstPageIndex = systemPage.pageIndex;
        final turn = tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .nextPage(
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
            );
        await tester.pumpAndSettle();
        await turn;
        final adjacentPage = visiblePage();
        expect(adjacentPage.pageIndex, isNot(firstPageIndex));
        expect(
          _leafFontFamilies(
            adjacentPage.baseSourceSpanBuilder!(
              adjacentPage.page.startOffset,
              adjacentPage.page.endOffset,
            ),
          ),
          isNot(contains('serif')),
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        settings.dispose();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'EPUB precaches adjacent horizontal images before the first turn',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-image-precache-',
      );
      final epub = File('${directory.path}/image-precache.epub');
      epub.writeAsBytesSync(
        _epubFixture(
          chapterCount: 3,
          imageOnlyChapterCount: 3,
          uniqueImagePerChapter: true,
        ),
      );
      final precachedImages = <ImageProvider>[];

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB image precache fixture',
                filePath: epub.path,
                format: 'epub',
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
              imagePrecacher: (image) async => precachedImages.add(image),
            ),
          ),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 60; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (precachedImages.toSet().length >= 2) return;
          }
        });
        await _pumpUntil(tester, () => precachedImages.toSet().length >= 2);

        final controller = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        expect(controller.page, controller.initialPage.toDouble());
        expect(precachedImages.toSet(), hasLength(greaterThanOrEqualTo(2)));
        expect(precachedImages, everyElement(isA<FileImage>()));
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
        expect(
          find.byKey(const ValueKey('reader-chapter-title-page-switch')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'EPUB horizontal turns warm the next pagination window before a chapter boundary',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-transition-',
      );
      final epub = File('${directory.path}/transition.epub');
      epub.writeAsBytesSync(_epubFixture());
      final paginationMisses = <int>[];

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB transition fixture',
                filePath: epub.path,
                format: 'epub',
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
              onPaginationCacheMiss: paginationMisses.add,
            ),
          ),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 60; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (find.byType(PageView).evaluate().isNotEmpty) return;
          }
        });
        await _pumpUntil(
          tester,
          () => find.byType(PageView).evaluate().isNotEmpty,
        );
        await tester.idle();
        await tester.pump();
        await _pumpUntil(tester, () => paginationMisses.contains(2));

        final pageView = find.byType(PageView);
        final pageViewWidget = tester.widget<PageView>(pageView);
        final firstChapterPages = _nearbyPageIndexes(
          tester,
          pageView,
          'Chapter 1',
        );
        expect(firstChapterPages, isNotEmpty);

        final controller = pageViewWidget.controller!;
        controller.jumpToPage(firstChapterPages.last);
        await tester.pump();
        await tester.idle();
        await tester.pump();
        await _pumpUntil(tester, () => paginationMisses.contains(3));
        paginationMisses.clear();
        final settledChildCount = tester
            .widget<PageView>(pageView)
            .childrenDelegate
            .estimatedChildCount!;

        final boundaryLeaf = find.byWidgetPredicate(
          (widget) =>
              widget is ReaderPaperPageLeaf &&
              widget.metadata.chapterTitle == 'Chapter 1' &&
              widget.metadata.pageNumber == firstChapterPages.length,
        );
        expect(boundaryLeaf, findsOneWidget);
        final boundaryElement = tester.element(boundaryLeaf);
        final rect = tester.getRect(pageView);
        final gesture = await tester.startGesture(
          Offset(rect.right - 8, rect.center.dy),
        );
        await gesture.moveBy(const Offset(-150, 0));
        await tester.pump();
        final pageDuringTurn = controller.page!;
        expect(pageDuringTurn, isNot(pageDuringTurn.roundToDouble()));
        final incomingLeaf = find.byWidgetPredicate(
          (widget) =>
              widget is ReaderPaperPageLeaf &&
              widget.metadata.chapterTitle == 'Chapter 2' &&
              widget.metadata.pageNumber == 1,
        );
        expect(incomingLeaf, findsOneWidget);
        final incomingElement = tester.element(incomingLeaf);
        expect(
          tester
              .widget<PageView>(pageView)
              .childrenDelegate
              .estimatedChildCount,
          settledChildCount,
        );

        // Cross PageView's onPageChanged threshold without releasing the
        // pointer. Chapter-window maintenance must not alter the live page
        // list or controller while the drag is still active.
        await gesture.moveBy(Offset(-rect.width * 0.35, 0));
        await tester.pump();
        final heldPage = controller.page!;
        expect(heldPage, isNot(heldPage.roundToDouble()));
        expect(tester.widget<PageView>(pageView).controller, same(controller));
        expect(
          tester
              .widget<PageView>(pageView)
              .childrenDelegate
              .estimatedChildCount,
          settledChildCount,
        );
        expect(tester.element(boundaryLeaf), same(boundaryElement));
        expect(tester.element(incomingLeaf), same(incomingElement));

        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PageView>(pageView)
              .childrenDelegate
              .estimatedChildCount,
          greaterThan(settledChildCount),
        );

        final turn = controller.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        await tester.pumpAndSettle();
        await turn;

        expect(paginationMisses, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets('EPUB horizontal paging continues past image-only front matter', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.binding.setSurfaceSize(const Size(480, 800));
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
      ReaderSettingsStore.chapterTitlePageKey: false,
    });
    final directory = Directory.systemTemp.createTempSync(
      'origo-x-epub-front-matter-',
    );
    final epub = File('${directory.path}/front-matter.epub');
    epub.writeAsBytesSync(
      _epubFixture(chapterCount: 14, imageOnlyChapterCount: 8),
    );

    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'EPUB image front matter fixture',
              filePath: epub.path,
              format: 'epub',
              fileModifiedTime: epub.lastModifiedSync().millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 60; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find.byType(PageView).evaluate().isNotEmpty) return;
        }
      });
      await _pumpUntil(
        tester,
        () => find.byType(PageView).evaluate().isNotEmpty,
      );
      final stableController = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;

      var reachedBody = false;
      for (var turn = 0; turn < 24 && !reachedBody; turn++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        });
        await tester.pump(const Duration(milliseconds: 50));
        final pageView = tester.widget<PageView>(find.byType(PageView));
        final controller = pageView.controller!;
        final delegate =
            pageView.childrenDelegate as SliverChildBuilderDelegate;
        final currentPage = controller.page?.round() ?? 0;
        final currentLeaf =
            delegate.builder(
                  tester.element(find.byType(PageView)),
                  currentPage,
                )!
                as ReaderPaperPageLeaf;
        if (currentLeaf.metadata.chapterTitle == 'Chapter 9') {
          reachedBody = true;
          break;
        }
        if (delegate.estimatedChildCount! <= currentPage + 1) {
          await _pumpUntil(tester, () {
            final latest = tester.widget<PageView>(find.byType(PageView));
            final latestPage = latest.controller!.page?.round() ?? 0;
            final latestDelegate =
                latest.childrenDelegate as SliverChildBuilderDelegate;
            return latestDelegate.estimatedChildCount! > latestPage + 1;
          });
        }
        final latest = tester.widget<PageView>(find.byType(PageView));
        final latestPage = latest.controller!.page?.round() ?? 0;
        latest.controller!.jumpToPage(latestPage + 1);
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(reachedBody, isTrue);
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller,
        same(stableController),
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await drainReaderCache(tester);
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
      directory.deleteSync(recursive: true);
    }
  });

  testWidgets(
    'EPUB horizontal paging does not bounce when turning again at a warming tail',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-warming-tail-',
      );
      final epub = File('${directory.path}/warming-tail.epub');
      epub.writeAsBytesSync(
        _epubFixture(chapterCount: 14, imageOnlyChapterCount: 8),
      );

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB warming tail fixture',
                filePath: epub.path,
                format: 'epub',
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 60; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (find.byType(PageView).evaluate().isNotEmpty) return;
          }
        });
        await _pumpUntil(
          tester,
          () => find.byType(PageView).evaluate().isNotEmpty,
        );

        final pageView = find.byType(PageView);
        final initialPageView = tester.widget<PageView>(pageView);
        final controller = initialPageView.controller!;
        final publishedTail = _lastPublishedContentPageIndex(tester, pageView);
        final tailLeaf = _pageLeafAt(tester, pageView, publishedTail);
        final tailChapterNumber = int.parse(
          tailLeaf.metadata.chapterTitle.split(' ').last,
        );
        controller.jumpToPage(publishedTail);
        expect(controller.page, publishedTail.toDouble());

        final rect = tester.getRect(pageView);
        final gesture = await tester.startGesture(
          Offset(rect.right - 8, rect.center.dy),
        );
        await gesture.moveBy(Offset(-rect.width * 0.8, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();

        final settledPage = controller.page!.round();
        final settledLeaf = _pageLeafAt(tester, pageView, settledPage);
        expect(tester.widget<PageView>(pageView).controller, same(controller));
        expect(settledPage, publishedTail + 1);
        expect(
          settledLeaf.metadata.chapterTitle,
          'Chapter ${tailChapterNumber + 1}',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets('EPUB backward turns keep one horizontal controller', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
    });
    await tester.binding.setSurfaceSize(const Size(400, 800));
    final directory = Directory.systemTemp.createTempSync(
      'origo_x_epub_backward_window_',
    );
    final epub = File('${directory.path}/backward-window.epub');
    epub.writeAsBytesSync(_epubFixture(chapterCount: 6));

    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: NativeReaderPage(
            replaceRuleService: replaceRuleService,
            book: Book(
              title: 'EPUB backward window fixture',
              filePath: epub.path,
              format: 'epub',
              currentPage: 3,
              fileModifiedTime: epub.lastModifiedSync().millisecondsSinceEpoch,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 60; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          if (find.byType(PageView).evaluate().isNotEmpty) return;
        }
      });
      await _pumpUntil(
        tester,
        () => find.byType(PageView).evaluate().isNotEmpty,
      );

      final pageView = find.byType(PageView);
      final initialWidget = tester.widget<PageView>(pageView);
      final chapterFourPages = _nearbyPageIndexes(
        tester,
        pageView,
        'Chapter 4',
      );
      expect(chapterFourPages, isNotEmpty);

      final initialController = initialWidget.controller!;
      initialController.jumpToPage(chapterFourPages.first);
      await tester.pumpAndSettle();
      final firstChildCount = tester
          .widget<PageView>(pageView)
          .childrenDelegate
          .estimatedChildCount!;
      final rect = tester.getRect(pageView);
      final firstGesture = await tester.startGesture(
        Offset(rect.left + 8, rect.center.dy),
      );
      await firstGesture.moveBy(Offset(rect.width * 0.65, 0));
      await tester.pump();
      final firstHeldPage = initialController.page!;
      expect(firstHeldPage, isNot(firstHeldPage.roundToDouble()));
      expect(
        tester.widget<PageView>(pageView).controller,
        same(initialController),
      );
      expect(
        tester.widget<PageView>(pageView).childrenDelegate.estimatedChildCount,
        firstChildCount,
      );

      await firstGesture.up();
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        () => identical(
          tester.widget<PageView>(pageView).controller,
          initialController,
        ),
      );

      final middleWidget = tester.widget<PageView>(pageView);
      final chapterThreePages = _nearbyPageIndexes(
        tester,
        pageView,
        'Chapter 3',
      );
      expect(chapterThreePages, isNotEmpty);

      final middleController = middleWidget.controller!;
      middleController.jumpToPage(chapterThreePages.first);
      await tester.pumpAndSettle();
      final secondChildCount = tester
          .widget<PageView>(pageView)
          .childrenDelegate
          .estimatedChildCount!;
      final secondGesture = await tester.startGesture(
        Offset(rect.left + 8, rect.center.dy),
      );
      await secondGesture.moveBy(Offset(rect.width * 0.65, 0));
      await tester.pump();
      final secondHeldPage = middleController.page!;
      expect(secondHeldPage, isNot(secondHeldPage.roundToDouble()));
      expect(
        tester.widget<PageView>(pageView).controller,
        same(middleController),
      );
      expect(
        tester.widget<PageView>(pageView).childrenDelegate.estimatedChildCount,
        secondChildCount,
      );

      await secondGesture.up();
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        () => identical(
          tester.widget<PageView>(pageView).controller,
          middleController,
        ),
      );

      final settledWidget = tester.widget<PageView>(pageView);
      final settledDelegate =
          settledWidget.childrenDelegate as SliverChildBuilderDelegate;
      final settledChapterTitles = {
        for (final index in _nearbyPageIndexes(tester, pageView, null))
          (settledDelegate.builder(tester.element(pageView), index)!
                  as ReaderPaperPageLeaf)
              .metadata
              .chapterTitle,
      };
      expect(
        settledChapterTitles,
        containsAll(<String>[
          'Chapter 1',
          'Chapter 2',
          'Chapter 3',
          'Chapter 4',
        ]),
      );
      expect(settledChapterTitles, isNot(contains('Chapter 5')));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await drainReaderCache(tester);
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
      directory.deleteSync(recursive: true);
    }
  });

  for (final viewport in <({String name, Size size})>[
    (name: 'phone', size: const Size(400, 800)),
    (name: 'tablet', size: const Size(1200, 800)),
  ]) {
    testWidgets(
      'EPUB TOC far-back jump mounts the cold target body on ${viewport.name}',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        SharedPreferences.setMockInitialValues({
          ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
          ReaderSettingsStore.chapterTitlePageKey: false,
        });
        await tester.binding.setSurfaceSize(viewport.size);
        final directory = Directory.systemTemp.createTempSync(
          'origo-x-epub-toc-far-back-${viewport.name}-',
        );
        final epub = File('${directory.path}/toc-far-back.epub')
          ..writeAsBytesSync(
            _epubFixture(
              chapterCount: 12,
              chapterParagraphCounts: <int>[
                4,
                2,
                3,
                5,
                8,
                12,
                20,
                28,
                44,
                60,
                72,
                84,
              ],
            ),
          );

        try {
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: NativeReaderPage(
                replaceRuleService: replaceRuleService,
                book: Book(
                  title: 'EPUB TOC far-back fixture',
                  filePath: epub.path,
                  format: 'epub',
                  currentPage: 10,
                  fileModifiedTime: epub
                      .lastModifiedSync()
                      .millisecondsSinceEpoch,
                ),
              ),
            ),
          );
          await _waitForVisibleChapter(tester, 'Chapter 11');

          final pageView = _nativeReaderPageView();
          final originalPageView = tester.widget<PageView>(pageView);
          final originalController = originalPageView.controller!;
          final originalInitialPage = originalController.initialPage;
          await _selectTocChapter(tester, 'Chapter 2');
          await _waitForControllerReplacement(tester, originalController);

          final jumpedPageView = tester.widget<PageView>(pageView);
          final jumpedController = jumpedPageView.controller!;
          expect(jumpedController, isNot(same(originalController)));
          expect(
            find.byKey(const ValueKey('native-reader-positioning-placeholder')),
            findsNothing,
          );
          final visiblePage = _visibleAnnotatedPage(tester, pageView);
          expect(visiblePage.chapterTitle, 'Chapter 2');
          expect(visiblePage.chapterId, contains('chapter2.xhtml'));
          expect(visiblePage.sourceText, contains('Chapter 2 paragraph 0'));
          expect(visiblePage.page.text.trim(), isNotEmpty);
          expect(
            jumpedController.page,
            jumpedController.initialPage.toDouble(),
            reason:
                'The replacement PageView must attach at its new chapter '
                'origin instead of inheriting the previous scroll pixels.',
          );

          originalPageView.onPageChanged!(originalInitialPage);
          await tester.pump();
          final afterStaleCallback = _visibleAnnotatedPage(tester, pageView);
          expect(afterStaleCallback.chapterTitle, 'Chapter 2');
          expect(
            afterStaleCallback.sourceText,
            contains('Chapter 2 paragraph 0'),
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          await drainReaderCache(tester);
          await tester.binding.setSurfaceSize(null);
          debugDefaultTargetPlatformOverride = null;
          directory.deleteSync(recursive: true);
        }
      },
    );
  }

  testWidgets(
    'latest EPUB TOC jump wins when an older cold jump finishes last',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      await tester.binding.setSurfaceSize(const Size(400, 800));
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-toc-latest-intent-',
      );
      final epub = File('${directory.path}/toc-latest-intent.epub')
        ..writeAsBytesSync(_epubFixture(chapterCount: 12));
      await replaceRuleService.close();
      final controlledRules = ControllableReplaceRuleService();
      replaceRuleService = controlledRules;
      var bodiesReleased = false;

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB latest TOC intent fixture',
                filePath: epub.path,
                format: 'epub',
                currentPage: 10,
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );
        await _waitForVisibleChapter(tester, 'Chapter 11');

        controlledRules.delayBodies = true;
        await _selectTocChapter(tester, 'Chapter 2');
        expect(
          find.byKey(const ValueKey('native-reader-chapter-loading')),
          findsOneWidget,
          reason: 'A cold TOC jump must acknowledge the tap immediately.',
        );
        await _waitForPendingReplacementBody(
          tester,
          controlledRules,
          'Chapter 2 paragraph 0',
        );

        // Chapter 12 belongs to the already prepared opening window, so the
        // newer intent can finish while the older cold Chapter 2 request waits.
        await _selectTocChapter(tester, 'Chapter 12');
        await _waitForVisibleChapter(tester, 'Chapter 12');

        for (final pending in controlledRules.pendingBodies) {
          pending.complete();
        }
        bodiesReleased = true;
        controlledRules.delayBodies = false;
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pumpAndSettle();

        final visiblePage = _visibleAnnotatedPage(
          tester,
          _nativeReaderPageView(),
        );
        expect(visiblePage.chapterTitle, 'Chapter 12');
        expect(visiblePage.chapterId, contains('chapter12.xhtml'));
        expect(visiblePage.sourceText, contains('Chapter 12 paragraph 0'));
        expect(tester.takeException(), isNull);
      } finally {
        if (!bodiesReleased) {
          for (final pending in controlledRules.pendingBodies) {
            pending.complete();
          }
        }
        controlledRules.delayBodies = false;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'EPUB TOC jump stays rendered while its predecessor is still preparing',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.horizontalSlide.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      await tester.binding.setSurfaceSize(const Size(400, 800));
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-toc-target-priority-',
      );
      final epub = File('${directory.path}/toc-target-priority.epub')
        ..writeAsBytesSync(
          _epubFixture(
            chapterCount: 12,
            chapterParagraphCounts: <int>[
              4,
              2,
              6,
              8,
              12,
              16,
              24,
              32,
              40,
              48,
              56,
              64,
            ],
          ),
        );
      await replaceRuleService.close();
      final blockingRules = _AdjacentBlockingReplaceRuleService(
        blockedMarker: 'Chapter 1 paragraph 0',
      );
      replaceRuleService = blockingRules;

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB target-priority fixture',
                filePath: epub.path,
                format: 'epub',
                currentPage: 10,
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );
        await _waitForVisibleChapter(tester, 'Chapter 11');

        blockingRules.enabled = true;
        await _selectTocChapter(tester, 'Chapter 2');
        await _waitForAdjacentBlock(tester, blockingRules);

        // The selected chapter is ready. Its slower neighbor should continue
        // warming in the background instead of holding the visible jump.
        await _waitForVisibleChapter(tester, 'Chapter 2');
        final visiblePage = _visibleAnnotatedPage(
          tester,
          _nativeReaderPageView(),
        );
        expect(visiblePage.chapterId, contains('chapter2.xhtml'));
        expect(visiblePage.sourceText, contains('Chapter 2 paragraph 0'));
        expect(visiblePage.page.text.trim(), isNotEmpty);
        expect(blockingRules.isBlocked, isTrue);

        final pageView = _nativeReaderPageView();
        final stableController = tester.widget<PageView>(pageView).controller!;
        final rect = tester.getRect(pageView);
        final backwardGesture = await tester.startGesture(
          Offset(rect.left + 8, rect.center.dy),
        );
        await backwardGesture.moveBy(Offset(rect.width * 0.65, 0));
        await tester.pump();
        await backwardGesture.up();
        await _pumpTransitionFrames(tester);

        final blockedVisiblePage = _visibleAnnotatedPage(tester, pageView);
        expect(blockedVisiblePage.chapterTitle, 'Chapter 2');
        expect(
          tester.widget<PageView>(pageView).controller,
          same(stableController),
        );

        blockingRules.release();
        await _pumpUntil(
          tester,
          () => _nearbyPageIndexes(tester, pageView, 'Chapter 1').isNotEmpty,
        );
        final preparedVisiblePage = _visibleAnnotatedPage(tester, pageView);
        expect(preparedVisiblePage.chapterTitle, 'Chapter 2');
        expect(preparedVisiblePage.page.text.trim(), isNotEmpty);
        expect(
          tester.widget<PageView>(pageView).controller,
          same(stableController),
        );
      } finally {
        blockingRules.release();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );

  testWidgets(
    'EPUB page curl returns from a chapter first page to the previous last page',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.binding.setSurfaceSize(const Size(480, 800));
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: ReaderPageMode.pageCurl.name,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final directory = Directory.systemTemp.createTempSync(
        'origo-x-epub-curl-boundary-',
      );
      final epub = File('${directory.path}/curl-boundary.epub');
      epub.writeAsBytesSync(_epubFixture(chapterCount: 3));

      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeReaderPage(
              replaceRuleService: replaceRuleService,
              book: Book(
                title: 'EPUB curl boundary fixture',
                filePath: epub.path,
                format: 'epub',
                fileModifiedTime: epub
                    .lastModifiedSync()
                    .millisecondsSinceEpoch,
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          for (var attempt = 0; attempt < 60; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
            if (find.byType(ReaderShaderPageCurl).evaluate().isNotEmpty) return;
          }
        });
        await _pumpUntil(
          tester,
          () => find.byType(ReaderShaderPageCurl).evaluate().isNotEmpty,
        );

        ReaderShaderPageCurl curl() => tester.widget<ReaderShaderPageCurl>(
          find.byType(ReaderShaderPageCurl),
        );
        for (var turn = 0; turn < 40; turn++) {
          final current = curl();
          if (current.currentPage.key.pageIdentity.contains(
            ':chapter2.xhtml:0:',
          )) {
            break;
          }
          if (current.forwardPage == null) {
            await tester.runAsync(() async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
            });
            await tester.pump();
            continue;
          }
          final future = current.controller!.turnForward();
          await tester.pumpAndSettle();
          await future;
        }

        final chapterTwoFirst = curl();
        expect(
          chapterTwoFirst.currentPage.key.pageIdentity,
          contains(':chapter2.xhtml:0:'),
        );
        expect(chapterTwoFirst.backwardPage, isNotNull);
        final previousIdentity = chapterTwoFirst.backwardPage!.key.pageIdentity;

        final curlRect = tester.getRect(find.byType(ReaderShaderPageCurl));
        final backwardGesture = await tester.startGesture(
          Offset(curlRect.left + 2, curlRect.center.dy),
        );
        await backwardGesture.moveBy(const Offset(40, 0));
        await tester.pump();
        await backwardGesture.moveBy(Offset(curlRect.width * 0.7, -24));
        await tester.pump();
        await backwardGesture.up();
        await tester.pumpAndSettle();

        expect(curl().currentPage.key.pageIdentity, previousIdentity);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await drainReaderCache(tester);
        await tester.binding.setSurfaceSize(null);
        debugDefaultTargetPlatformOverride = null;
        directory.deleteSync(recursive: true);
      }
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
  }
  fail('Timed out waiting for EPUB reader state.');
}

Future<void> _waitForVisibleChapter(
  WidgetTester tester,
  String chapterTitle,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
      if (_nativeReaderPageViews().evaluate().isEmpty) continue;
      final pageView = _nativeReaderPageView();
      final visible = _tryVisibleAnnotatedPage(tester, pageView);
      if (visible?.chapterTitle == chapterTitle) return;
    }
  });
  final hasPageView = _nativeReaderPageViews().evaluate().isNotEmpty;
  final pageView = hasPageView ? _nativeReaderPageView() : null;
  final visible = pageView == null
      ? null
      : _tryVisibleAnnotatedPage(tester, pageView);
  expect(
    visible?.chapterTitle,
    chapterTitle,
    reason: 'Timed out waiting for the mounted chapter body.',
  );
}

Future<void> _selectTocChapter(WidgetTester tester, String chapterTitle) async {
  final pageView = _nativeReaderPageView();
  Finder tocButton() => find
      .descendant(
        of: find.byType(NativeReaderPage),
        matching: find.byIcon(Icons.format_list_bulleted_rounded),
      )
      .hitTestable();
  if (tocButton().evaluate().isEmpty) {
    await tester.tapAt(tester.getRect(pageView).center);
    await _pumpTransitionFrames(tester);
  }
  expect(tocButton(), findsOneWidget);
  await tester.tap(tocButton());
  await _pumpTransitionFrames(tester);
  final sheet = find.byType(ReaderNavigationSheet);
  expect(sheet, findsOneWidget);
  final searchField = find.descendant(
    of: sheet,
    matching: find.byType(TextField),
  );
  await tester.enterText(searchField, chapterTitle);
  // The catalog opens around the current late chapter. Reset that retained
  // scroll offset after filtering so the single early result is built.
  await tester.pump();
  final resultList = find
      .descendant(of: sheet, matching: find.byType(ListView))
      .first;
  tester.widget<ListView>(resultList).controller!.jumpTo(0);
  await tester.pump();
  await tester.pump();
  expect(
    tester.widget<TextField>(searchField).controller!.text,
    chapterTitle,
    reason: 'Deferred TOC positioning must finish before entering a search.',
  );
  final targetLabel = find.descendant(
    of: sheet,
    matching: find.text(chapterTitle),
  );
  final targetRow = find
      .ancestor(of: targetLabel, matching: find.byType(InkWell))
      .hitTestable();
  expect(targetRow, findsOneWidget);
  await tester.tap(targetRow);
  await _pumpTransitionFrames(tester);
  expect(
    sheet,
    findsNothing,
    reason: 'Selecting a TOC row must dismiss the navigation sheet.',
  );
}

Future<void> _pumpTransitionFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _waitForControllerReplacement(
  WidgetTester tester,
  PageController originalController,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
      if (_nativeReaderPageViews().evaluate().isEmpty) continue;
      final pageView = _nativeReaderPageView();
      final current = tester.widget<PageView>(pageView).controller;
      if (!identical(current, originalController)) return;
    }
  });
  expect(
    tester.widget<PageView>(_nativeReaderPageView()).controller,
    isNot(same(originalController)),
    reason: 'Timed out waiting for the chapter-jump controller replacement.',
  );
}

Future<void> _waitForPendingReplacementBody(
  WidgetTester tester,
  ControllableReplaceRuleService service,
  String marker,
) async {
  bool containsTarget() => service.pendingBodies.any(
    (pending) => pending.values.any((value) => value.contains(marker)),
  );
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (containsTarget()) return;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
    }
  });
  expect(
    containsTarget(),
    isTrue,
    reason: 'Timed out waiting for the selected cold chapter body.',
  );
}

Future<void> _waitForAdjacentBlock(
  WidgetTester tester,
  _AdjacentBlockingReplaceRuleService service,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      if (service.isBlocked) return;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
    }
  });
  expect(
    service.isBlocked,
    isTrue,
    reason: 'Timed out waiting for the unrelated adjacent chapter blocker.',
  );
}

Finder _nativeReaderPageViews() => find.descendant(
  of: find.byType(NativeReaderPage),
  matching: find.byType(PageView),
);

Finder _nativeReaderPageView() => _nativeReaderPageViews().first;

ReaderAnnotatedTextPage _visibleAnnotatedPage(
  WidgetTester tester,
  Finder pageView,
) {
  final page = _tryVisibleAnnotatedPage(tester, pageView);
  expect(
    page,
    isNotNull,
    reason: 'The mounted viewport must contain a rendered text body.',
  );
  return page!;
}

ReaderAnnotatedTextPage? _tryVisibleAnnotatedPage(
  WidgetTester tester,
  Finder pageView,
) {
  final viewport = tester.getRect(pageView);
  ReaderAnnotatedTextPage? best;
  var bestVisibleArea = 0.0;
  for (final element in find.byType(ReaderAnnotatedTextPage).evaluate()) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderBox || !renderObject.attached) continue;
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    final overlap = rect.intersect(viewport);
    final visibleArea = overlap.isEmpty ? 0.0 : overlap.width * overlap.height;
    if (visibleArea > bestVisibleArea) {
      bestVisibleArea = visibleArea;
      best = element.widget as ReaderAnnotatedTextPage;
    }
  }
  return best;
}

class _AdjacentBlockingReplaceRuleService extends ReplaceRuleService {
  _AdjacentBlockingReplaceRuleService({required this.blockedMarker});

  final String blockedMarker;
  final Completer<void> _release = Completer<void>();
  bool enabled = false;
  bool isBlocked = false;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<ReplaceRuleExecutionResult> applyBatchAsync(
    List<String> inputs, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
    bool preserveNonEmpty = false,
  }) async {
    final result = await super.applyBatchAsync(
      inputs,
      bookTitle: bookTitle,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      bookId: bookId,
      eligibleByDefault: eligibleByDefault,
      title: title,
      preserveNonEmpty: preserveNonEmpty,
    );
    if (enabled &&
        !title &&
        inputs.any((value) => value.contains(blockedMarker))) {
      isBlocked = true;
      await _release.future;
    }
    return result;
  }
}

List<String?> _leafFontFamilies(InlineSpan span) {
  if (span is! TextSpan) return const [];
  final children = span.children;
  if (children == null || children.isEmpty) {
    return span.text?.isNotEmpty == true ? [span.style?.fontFamily] : const [];
  }
  return [for (final child in children) ..._leafFontFamilies(child)];
}

List<int> _nearbyPageIndexes(
  WidgetTester tester,
  Finder pageView,
  String? chapterTitle,
) {
  final widget = tester.widget<PageView>(pageView);
  final delegate = widget.childrenDelegate as SliverChildBuilderDelegate;
  final element = tester.element(pageView);
  final current = widget.controller?.page?.round() ?? 0;
  final first = math.max(0, current - 160);
  final last = math.min(delegate.estimatedChildCount! - 1, current + 160);
  final indexes = <int>[];
  for (var index = first; index <= last; index++) {
    final child = delegate.builder(element, index);
    if (child is! ReaderPaperPageLeaf) continue;
    if (chapterTitle == null || child.metadata.chapterTitle == chapterTitle) {
      indexes.add(index);
    }
  }
  return indexes;
}

ReaderPaperPageLeaf _pageLeafAt(
  WidgetTester tester,
  Finder pageView,
  int controllerPage,
) {
  final widget = tester.widget<PageView>(pageView);
  final delegate = widget.childrenDelegate as SliverChildBuilderDelegate;
  return delegate.builder(tester.element(pageView), controllerPage)!
      as ReaderPaperPageLeaf;
}

int _lastPublishedContentPageIndex(WidgetTester tester, Finder pageView) {
  final widget = tester.widget<PageView>(pageView);
  final delegate = widget.childrenDelegate as SliverChildBuilderDelegate;
  final element = tester.element(pageView);
  for (var index = delegate.estimatedChildCount! - 1; index >= 0; index--) {
    final child = delegate.builder(element, index);
    if (child is ReaderPaperPageLeaf &&
        child.metadata.chapterTitle.isNotEmpty) {
      return index;
    }
  }
  fail('No published EPUB content page was available.');
}

List<int> _epubFixture({
  int chapterCount = 4,
  int imageOnlyChapterCount = 0,
  bool uniqueImagePerChapter = false,
  bool serifParagraphs = false,
  List<int>? chapterParagraphCounts,
}) {
  assert(
    chapterParagraphCounts == null ||
        chapterParagraphCounts.length == chapterCount,
  );
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  void addBytes(String name, List<int> bytes) {
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
    <dc:identifier id="book-id">transition-fixture</dc:identifier>
    <dc:title>Transition fixture</dc:title><dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    ${uniqueImagePerChapter ? List.generate(chapterCount, (index) => '<item id="stripe${index + 1}" href="stripe${index + 1}.png" media-type="image/png"/>').join() : '<item id="stripe" href="stripe.png" media-type="image/png"/>'}
    ${List.generate(chapterCount, (index) => '<item id="c${index + 1}" href="chapter${index + 1}.xhtml" media-type="application/xhtml+xml"/>').join()}
  </manifest>
  <spine toc="ncx">${List.generate(chapterCount, (index) => '<itemref idref="c${index + 1}"/>').join()}</spine>
</package>''');
  add('OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="transition-fixture"/></head>
  <docTitle><text>Transition fixture</text></docTitle>
  <navMap>${List.generate(chapterCount, (index) => '<navPoint id="nav${index + 1}" playOrder="${index + 1}"><navLabel><text>Chapter ${index + 1}</text></navLabel><content src="chapter${index + 1}.xhtml"/></navPoint>').join()}</navMap>
</ncx>''');
  final imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  if (uniqueImagePerChapter) {
    for (var chapter = 1; chapter <= chapterCount; chapter++) {
      addBytes('OEBPS/stripe$chapter.png', imageBytes);
    }
  } else {
    addBytes('OEBPS/stripe.png', imageBytes);
  }
  for (var chapter = 1; chapter <= chapterCount; chapter++) {
    final paragraphCount = chapterParagraphCounts?[chapter - 1] ?? 40;
    add('OEBPS/chapter$chapter.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>Chapter $chapter</title></head><body>
${chapter <= imageOnlyChapterCount ? '<img src="${uniqueImagePerChapter ? 'stripe$chapter.png' : 'stripe.png'}" alt=""/>' : '<h1>Chapter $chapter</h1>${List.generate(paragraphCount, (index) => '<p${serifParagraphs ? ' style="font-family: serif"' : ''}>Chapter $chapter paragraph $index contains enough text to create several deterministic reader pages for transition testing.</p>').join()}'}
</body></html>''');
  }
  return ZipEncoder().encode(archive)!;
}
