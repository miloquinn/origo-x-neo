// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_chapter_title_page.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';
import 'package:xxread/widgets/reader_text_page_content.dart';

import '../test/support/book_source_progress_test_utils.dart';
import '../test/support/no_shelf_book_source_service.dart';
import '../test/support/reader_cache_test_utils.dart';

const _snapshotPath = 'build/reader-vertical-audit-20261010/live-books.json';

void main() {
  final samples = _loadSamples();
  for (final sample in samples) {
    for (final titlePage in [true, false]) {
      for (final scrollByChapter in [true, false]) {
        testWidgets(
          'live iOS vertical preserves ${sample.book.title} anchor '
          '[title=$titlePage chapter=$scrollByChapter]',
          (tester) => _runLiveReaderCase(
            tester,
            sample,
            titlePage: titlePage,
            scrollByChapter: scrollByChapter,
          ),
        );
      }
    }
  }
}

Future<void> _runLiveReaderCase(
  WidgetTester tester,
  _LiveBookSample sample, {
  required bool titlePage,
  required bool scrollByChapter,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  await tester.binding.setSurfaceSize(const Size(400, 800));
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  addTearDown(() async {
    tester.view.resetPadding();
    tester.view.resetViewPadding();
    await tester.binding.setSurfaceSize(null);
  });
  SharedPreferences.setMockInitialValues({
    ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
    ReaderSettingsStore.scrollByChapterKey: scrollByChapter,
    ReaderSettingsStore.chapterTitlePageKey: titlePage,
  });

  expect(sample.chapters.length, greaterThanOrEqualTo(3));
  expect(
    sample.contents.keys.toSet(),
    containsAll(sample.chapters.map((e) => e.id)),
  );
  final progress = await BookSourceProgressTestFixture.create();
  final rules = ReplaceRuleService();
  final client = _SnapshotBookSourceClient(sample);
  addTearDown(() async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    client.close();
    await rules.close();
    await progress.close();
  });

  final startIndex = _longestChapterIndex(sample);
  final startChapter = sample.chapters[startIndex];
  final startText = sample.contents[startChapter.id]!.content;
  await progress.store.save(
    sourceId: sample.source.id,
    bookId: sample.book.id,
    progress: BookSourceReadingProgress(
      chapterId: startChapter.id,
      chapterIndex: startIndex,
      chapterProgress: 0,
      updatedAt: DateTime.now().toUtc(),
    ),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BookSourceReaderPage(
        source: sample.source,
        book: sample.book,
        client: client,
        shelfServiceFactory: NoShelfBookSourceService.new,
        replaceRuleService: rules,
        progressStore: progress.store,
        paginationCacheDao: MemoryPaginationCacheDao(),
      ),
    ),
  );
  final surface = find.byKey(const ValueKey('book-source-reader-surface'));
  await _pumpUntil(
    tester,
    () => surface.evaluate().isNotEmpty,
    'reader surface',
  );
  await tester.pumpAndSettle();

  final anchor = await _scrollIntoChapterBody(
    tester,
    surface,
    chapterId: startChapter.id,
    textLength: startText.length,
  );
  expect(anchor.$1, startChapter.id);
  expect(anchor.$2, greaterThan(startText.length * 0.2));

  var resumed = anchor;
  for (var cycle = 0; cycle < 3; cycle++) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    if (cycle == 0) {
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 59, bottom: 34);
    }
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    resumed = _sourceCenterAnchor(tester);
    expect(resumed.$1, anchor.$1, reason: 'chapter changed after cycle $cycle');
    expect(
      resumed.$2,
      closeTo(anchor.$2, 80),
      reason: 'canonical offset drifted after cycle $cycle',
    );
  }

  final saved = await _waitForSavedAnchor(
    tester,
    progress.store,
    sample,
    anchor,
  );
  expect(saved.chapterId, anchor.$1);
  expect(
    (saved.chapterProgress * startText.length).round(),
    closeTo(anchor.$2, 80),
  );

  final selected = await _openCatalog(tester);
  expect(selected.currentChapterIndex, startIndex);
  final targetIndex = startIndex == 0 ? 1 : 0;
  final targetChapter = sample.chapters[targetIndex];
  final selectChapter = selected.onChapterSelected;
  selectChapter(targetIndex);
  await _pumpUntil(
    tester,
    () => _centerPage(tester)?.chapterId == targetChapter.id,
    'catalog target ${targetChapter.id}',
  );
  await tester.pumpAndSettle();
  final targetPage = _centerPage(tester)!;
  expect(targetPage.chapterId, targetChapter.id);
  expect(
    _scrollPixelsForPage(targetPage),
    closeTo(0, 1),
    reason: 'catalog jump must align the selected chapter at its actual top',
  );
  if (titlePage) {
    expect(targetPage.page.isChapterTitle, isTrue);
  } else {
    final targetAnchor = _sourceCenterAnchor(tester);
    final targetLength = sample.contents[targetChapter.id]!.content.length;
    expect(targetAnchor.$1, targetChapter.id);
    expect(
      targetAnchor.$2,
      lessThanOrEqualTo(targetLength * 0.15 + 500),
      reason: 'catalog jump inherited the prior chapter anchor',
    );
  }
  final targetNavigation = await _openCatalog(tester);
  expect(targetNavigation.currentChapterIndex, targetIndex);
  Navigator.of(tester.element(find.byType(ReaderNavigationSheet))).pop();
  await tester.pumpAndSettle();

  final result = {
    'book': sample.book.title,
    'source': sample.source.name,
    'titlePage': titlePage,
    'scrollByChapter': scrollByChapter,
    'chapterId': anchor.$1,
    'anchorOffset': anchor.$2,
    'resumedOffset': resumed.$2,
    'savedOffset': (saved.chapterProgress * startText.length).round(),
    'catalogTarget': targetChapter.id,
    'status': 'passed',
  };
  debugPrint('LIVE_BOOK_RESULT ${jsonEncode(result)}');
  debugDefaultTargetPlatformOverride = null;
  expect(tester.takeException(), isNull);
}

Future<(String, int, double)> _scrollIntoChapterBody(
  WidgetTester tester,
  Finder surface, {
  required String chapterId,
  required int textLength,
}) async {
  final desiredOffset = (textLength * 0.3).round();
  for (var attempt = 0; attempt < 40; attempt++) {
    try {
      final anchor = _sourceCenterAnchor(tester);
      if (anchor.$1 == chapterId && anchor.$2 >= desiredOffset) return anchor;
    } on TestFailure {
      // A dedicated title page can occupy the center before the first drag.
    }
    await tester.drag(surface, const Offset(0, -240));
    await tester.pumpAndSettle();
  }
  throw TestFailure('Could not scroll $chapterId into its body midpoint');
}

Future<ReaderNavigationSheet> _openCatalog(WidgetTester tester) async {
  tester
      .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
      .onTableOfContents!();
  await tester.pumpAndSettle();
  return tester.widget<ReaderNavigationSheet>(
    find.byType(ReaderNavigationSheet),
  );
}

Future<BookSourceReadingProgress> _waitForSavedAnchor(
  WidgetTester tester,
  BookSourceReadingProgressStore store,
  _LiveBookSample sample,
  (String, int, double) anchor,
) async {
  BookSourceReadingProgress? saved;
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 100; attempt++) {
      saved = await store.load(
        sourceId: sample.source.id,
        bookId: sample.book.id,
      );
      if (saved?.chapterId == anchor.$1) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  if (saved == null) throw TestFailure('Reader progress was not persisted');
  return saved!;
}

(String, int, double) _sourceCenterAnchor(WidgetTester tester) {
  final center =
      tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
  for (final element in find.byType(ReaderAnnotatedTextPage).evaluate()) {
    final page = element.widget as ReaderAnnotatedTextPage;
    if (page.page.isChapterTitle) continue;
    for (final rich in _sourceBodyText(page).evaluate()) {
      final paragraph = rich.renderObject as RenderParagraph;
      final top = paragraph.localToGlobal(Offset.zero).dy;
      if (top > center || top + paragraph.size.height < center) continue;
      final position = paragraph.getPositionForOffset(
        Offset(paragraph.size.width / 2, center - top),
      );
      return (
        page.chapterId,
        page.page.sourceOffsetForTextOffset(position.offset),
        top + paragraph.getOffsetForCaret(position, Rect.zero).dy,
      );
    }
  }
  throw TestFailure('No source body paragraph at viewport center');
}

ReaderAnnotatedTextPage? _centerPage(WidgetTester tester) {
  final center =
      tester.view.physicalSize.height / tester.view.devicePixelRatio / 2;
  for (final element in find.byType(ReaderAnnotatedTextPage).evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.top <= center && rect.bottom >= center) {
      return element.widget as ReaderAnnotatedTextPage;
    }
  }
  return null;
}

double _scrollPixelsForPage(ReaderAnnotatedTextPage page) {
  final element = find.byWidget(page).evaluate().single;
  return Scrollable.of(element).position.pixels;
}

Finder _sourceBodyText(ReaderAnnotatedTextPage page) => find.descendant(
  of: find.byWidget(page),
  matching: find.byElementPredicate((element) {
    if (element.widget is! RichText) return false;
    var isBody = false;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is ReaderInlineChapterTitle ||
          ancestor.widget is ReaderChapterTitlePage) {
        return false;
      }
      if (ancestor.widget is ReaderTextPageContent) {
        isBody = true;
        return false;
      }
      return true;
    });
    return isBody;
  }),
);

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done,
  String state,
) async {
  for (var attempt = 0; attempt < 120; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  throw TestFailure('Reader did not reach $state');
}

int _longestChapterIndex(_LiveBookSample sample) {
  var index = 0;
  for (var candidate = 1; candidate < sample.chapters.length; candidate++) {
    final currentLength =
        sample.contents[sample.chapters[index].id]!.content.length;
    final candidateLength =
        sample.contents[sample.chapters[candidate].id]!.content.length;
    if (candidateLength > currentLength) index = candidate;
  }
  return index;
}

List<_LiveBookSample> _loadSamples() {
  final file = File(Platform.environment['LIVE_BOOKS_JSON'] ?? _snapshotPath);
  if (!file.existsSync()) {
    throw StateError('Missing live reader snapshot: ${file.path}');
  }
  final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (root['samples'] as List)
      .map((value) => _LiveBookSample.fromJson(value as Map<String, dynamic>))
      .toList(growable: false);
}

class _LiveBookSample {
  _LiveBookSample({
    required this.source,
    required this.book,
    required this.chapters,
    required this.contents,
  });

  factory _LiveBookSample.fromJson(Map<String, dynamic> json) {
    final sourceJson = json['source'] as Map<String, dynamic>;
    final bookJson = json['book'] as Map<String, dynamic>;
    final chapters = (json['chapters'] as List)
        .map(
          (value) => BookSourceChapter.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
    final contents = <String, BookSourceChapterContent>{};
    for (final value in json['contents'] as List) {
      final content = value as Map<String, dynamic>;
      final chapterId = content['chapterId'] as String;
      contents[chapterId] = BookSourceChapterContent(
        bookId: bookJson['id'] as String,
        chapterId: chapterId,
        title: chapters.firstWhere((chapter) => chapter.id == chapterId).title,
        content: content['content'] as String,
        contentType: content['contentType'] as String,
      );
    }
    return _LiveBookSample(
      source: RegisteredBookSource(
        id: sourceJson['id'] as String,
        name: sourceJson['name'] as String,
        description: sourceJson['description'] as String? ?? '',
        manifestUrl: Uri.parse(sourceJson['manifestUrl'] as String),
        apiBaseUrl: Uri.parse(sourceJson['apiBaseUrl'] as String),
        protocolVersion: sourceJson['protocolVersion'] as String,
        languages: (sourceJson['languages'] as List).cast<String>(),
        capabilities: (sourceJson['capabilities'] as List)
            .cast<String>()
            .toSet(),
        enabled: true,
        addedAt: DateTime.utc(2026, 10, 10),
        sourceProtocol: sourceJson['sourceProtocol'] == 'readingSource'
            ? BookSourceProtocolKind.readingSource
            : BookSourceProtocolKind.orsp,
      ),
      book: BookSourceBook.fromJson(bookJson),
      chapters: chapters,
      contents: contents,
    );
  }

  final RegisteredBookSource source;
  final BookSourceBook book;
  final List<BookSourceChapter> chapters;
  final Map<String, BookSourceChapterContent> contents;
}

class _SnapshotBookSourceClient extends BookSourceClient {
  _SnapshotBookSourceClient(this.sample);

  final _LiveBookSample sample;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => sample.chapters;

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => sample.contents[chapterId]!;
}
