import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/widgets/reader_desktop_input.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';

import 'support/book_source_progress_test_utils.dart';
import 'support/no_shelf_book_source_service.dart';

const _missing = BookSourceProtocolException(
  'chapter not found (HTTP 404)',
  code: 'CHAPTER_NOT_FOUND',
);

void main() {
  late ReplaceRuleService rules;
  late BookSourceProgressTestFixture progress;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.instantPage.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    rules = ReplaceRuleService();
    progress = await BookSourceProgressTestFixture.create();
  });

  tearDown(() async {
    await rules.close();
    await progress.close();
  });

  Future<void> open(WidgetTester tester, _RecoveryClient client) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      client.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceReaderPage(
          source: _source,
          book: _book,
          client: client,
          shelfService: NoShelfBookSourceService(client),
          replaceRuleService: rules,
          progressStore: progress.store,
          paginationCacheDao: _NoDiskPagination(),
        ),
      ),
    );
  }

  testWidgets('chapter recovery remaps a changed ID without manual updates', (
    tester,
  ) async {
    final client = _RecoveryClient(
      catalog: const [_chapterOld],
      refreshedCatalog: const [_chapterNew],
      load: (id, _) async {
        if (id == 'old') throw _missing;
        return _content(id, 'Recovered chapter body.');
      },
    );
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('Recovered chapter body.', findRichText: true),
    );
    expect(client.refreshCount, 1);
    expect(client.requests, ['old', 'new']);
    expect(find.text(_missing.message), findsNothing);
  });

  testWidgets('chapter recovery rebuilds server state for the same stable ID', (
    tester,
  ) async {
    final client = _RecoveryClient(
      catalog: const [_chapterOld],
      refreshedCatalog: const [_chapterOld],
      load: (id, refreshed) async {
        if (!refreshed) throw _missing;
        return _content(id, 'Stable ID body.');
      },
    );
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('Stable ID body.', findRichText: true),
    );
    expect(client.refreshCount, 1);
    expect(client.requests, ['old', 'old']);
  });

  for (final mode in [
    (BookSourcePageMode.instantPage, false),
    (BookSourcePageMode.verticalScroll, false),
    (BookSourcePageMode.verticalScroll, true),
  ]) {
    testWidgets(
      'repeated retry preserves the failed chapter and saved progress '
      '(${mode.$1.name}, scrollByChapter=${mode.$2})',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          ReaderSettingsStore.pageModeKey: mode.$1.name,
          ReaderSettingsStore.scrollByChapterKey: mode.$2,
          ReaderSettingsStore.chapterTitlePageKey: false,
        });
        var unavailable = true;
        const second = BookSourceChapter(
          id: 'second',
          title: 'Second',
          order: 2,
        );
        const denied = BookSourceProtocolException(
          'Chapter request failed with HTTP 403.',
          statusCode: 403,
        );
        final client = _RecoveryClient(
          catalog: const [_chapterOld, second],
          refreshedCatalog: const [_chapterOld, second],
          load: (id, _) async {
            if (id == 'second' && unavailable) throw denied;
            return _content(
              id,
              id == 'old' ? _openingBody : 'Second retry body.',
            );
          },
        );
        await progress.store.save(
          sourceId: _source.id,
          bookId: _book.id,
          progress: BookSourceReadingProgress(
            chapterId: 'old',
            chapterIndex: 0,
            chapterProgress: 0,
            updatedAt: DateTime.utc(2026),
          ),
        );
        await open(tester, client);
        await _pumpFor(
          tester,
          find.textContaining('Opening body', findRichText: true),
        );
        await tester.pumpAndSettle();
        await _selectChapter(tester, 1);
        await _pumpFor(tester, find.text(denied.message));
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await _pumpFor(tester, find.text(denied.message));
        expect(client.refreshCount, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 400));
        final savedAfterFailure = await progress.store.load(
          sourceId: _source.id,
          bookId: _book.id,
        );
        expect(savedAfterFailure?.chapterId, 'old');

        await open(tester, client);
        await _pumpFor(
          tester,
          find.textContaining('Opening body', findRichText: true),
        );
        await tester.pumpAndSettle();
        await _selectChapter(tester, 1);
        await _pumpFor(tester, find.text(denied.message));
        unavailable = false;
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await _pumpFor(
          tester,
          find.textContaining('Second retry body.', findRichText: true),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 400));
        final savedAfterRetry = await progress.store.load(
          sourceId: _source.id,
          bookId: _book.id,
        );
        expect(savedAfterRetry?.chapterId, 'second');

        await open(tester, client);
        await _pumpFor(
          tester,
          find.textContaining('Second retry body.', findRichText: true),
        );
        expect(client.refreshCount, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a late invisible scroll failure cannot replace the visible chapter',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
        ReaderSettingsStore.scrollByChapterKey: false,
        ReaderSettingsStore.chapterTitlePageKey: false,
      });
      final delayed = Completer<BookSourceChapterContent>();
      final client = _RecoveryClient(
        catalog: const [
          _chapterOld,
          BookSourceChapter(id: 'second', title: 'Second', order: 2),
          BookSourceChapter(id: 'third', title: 'Third', order: 3),
        ],
        refreshedCatalog: const [],
        load: (id, _) async {
          if (id == 'second') return delayed.future;
          return _content(
            id,
            id == 'old' ? _openingBody : 'Visible third body.',
          );
        },
      );
      addTearDown(() {
        if (!delayed.isCompleted) {
          delayed.complete(_content('second', 'Unused'));
        }
      });
      await open(tester, client);
      await _pumpFor(
        tester,
        find.textContaining('Opening body', findRichText: true),
      );
      final list = tester.widget<ScrollablePositionedList>(
        find.byType(ScrollablePositionedList),
      );
      list.itemScrollController!.jumpTo(index: 1);
      await tester.pump(const Duration(milliseconds: 400));
      list.itemScrollController!.jumpTo(index: 2);
      await _pumpFor(
        tester,
        find.textContaining('Visible third body.', findRichText: true),
      );
      delayed.completeError(
        const BookSourceProtocolException('Obsolete invisible failure'),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Obsolete invisible failure'), findsNothing);
      expect(
        find.textContaining('Visible third body.', findRichText: true),
        findsWidgets,
      );
      expect(client.refreshCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'chapter recovery retries only once when the chapter remains missing',
    (tester) async {
      final client = _RecoveryClient(
        catalog: const [_chapterOld],
        refreshedCatalog: const [_chapterNew],
        load: (_, _) async => throw _missing,
      );
      await open(tester, client);
      await _pumpFor(tester, find.text(_missing.message));
      await tester.pump(const Duration(seconds: 1));
      expect(client.refreshCount, 1);
      expect(client.requests, ['old', 'new']);
    },
  );

  for (final code in ['LOGIN_REQUIRED', 'BOOK_NOT_FOUND', 'ROUTE_NOT_FOUND']) {
    testWidgets('chapter recovery does not refresh for $code', (tester) async {
      final error = BookSourceProtocolException(
        'Unavailable: $code',
        code: code,
      );
      final client = _RecoveryClient(
        catalog: const [_chapterOld],
        refreshedCatalog: const [_chapterNew],
        load: (_, _) async => throw error,
      );
      await open(tester, client);
      await _pumpFor(tester, find.text(error.message));
      expect(client.refreshCount, 0);
      expect(client.requests, ['old']);
    });
  }

  testWidgets('chapter recovery retry keeps the failed next chapter target', (
    tester,
  ) async {
    var failSecond = true;
    const second = BookSourceChapter(id: 'second', title: 'Second', order: 2);
    final client = _RecoveryClient(
      catalog: const [_chapterOld, second],
      refreshedCatalog: const [_chapterOld, second],
      load: (id, _) async {
        if (id == 'second' && failSecond) {
          throw const BookSourceProtocolException('Temporary failure');
        }
        return _content(id, id == 'old' ? 'First body.' : 'Second body.');
      },
    );
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('First body.', findRichText: true),
    );
    await _nextChapter(tester, find.text('Temporary failure'));
    failSecond = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await _pumpFor(
      tester,
      find.textContaining('Second body.', findRichText: true),
    );
    expect(client.requests.last, 'second');
    expect(client.refreshCount, 0);
  });

  testWidgets(
    'chapter recovery discards old prefetch after a catalog insertion',
    (tester) async {
      final delayed = Completer<BookSourceChapterContent>();
      const first = BookSourceChapter(id: 'first', title: 'First', order: 1);
      const secondOld = BookSourceChapter(
        id: 'second-old',
        title: 'Second',
        order: 2,
      );
      const thirdOld = BookSourceChapter(
        id: 'third-old',
        title: 'Third',
        order: 3,
      );
      const inserted = BookSourceChapter(
        id: 'inserted',
        title: 'Inserted',
        order: 2,
      );
      const secondNew = BookSourceChapter(
        id: 'second-new',
        title: 'Second',
        order: 3,
      );
      const thirdNew = BookSourceChapter(
        id: 'third-new',
        title: 'Third',
        order: 4,
      );
      final client = _RecoveryClient(
        catalog: const [first, secondOld, thirdOld],
        refreshedCatalog: const [first, inserted, secondNew, thirdNew],
        load: (id, _) async {
          if (id == 'second-old') throw _missing;
          if (id == 'third-old') return delayed.future;
          return _content(id, 'Body for $id.');
        },
      );
      addTearDown(() {
        if (!delayed.isCompleted) {
          delayed.complete(_content('third-old', 'Obsolete body.'));
        }
      });
      await open(tester, client);
      await _pumpFor(
        tester,
        find.textContaining('Body for first.', findRichText: true),
      );
      expect(client.requests, contains('third-old'));
      await _nextChapter(
        tester,
        find.textContaining('Body for second-new.', findRichText: true),
      );
      delayed.complete(_content('third-old', 'Obsolete body.'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.textContaining('Obsolete body.', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Body for second-new.', findRichText: true),
        findsWidgets,
      );
      await _nextChapter(
        tester,
        find.textContaining('Body for third-new.', findRichText: true),
      );
      expect(client.refreshCount, 1);
      expect(client.requests, contains('third-new'));
    },
  );

  testWidgets('chapter recovery handles a visible continuous-scroll chapter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    const first = BookSourceChapter(id: 'first', title: 'First', order: 1);
    const secondOld = BookSourceChapter(
      id: 'second-old',
      title: 'Second',
      order: 2,
    );
    const secondNew = BookSourceChapter(
      id: 'second-new',
      title: 'Second',
      order: 2,
    );
    final client = _RecoveryClient(
      catalog: const [first, secondOld],
      refreshedCatalog: const [first, secondNew],
      load: (id, _) async {
        if (id == 'second-old') throw _missing;
        return _content(
          id,
          id == 'first'
              ? List.generate(
                  35,
                  (i) => 'Opening body paragraph $i.',
                ).join('\n')
              : 'Visible recovered body.',
        );
      },
    );
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('Opening body', findRichText: true),
    );
    expect(
      client.refreshCount,
      0,
      reason: 'Prefetch failures must not force a catalog refresh.',
    );
    await _nextChapter(
      tester,
      find.textContaining('Visible recovered body.', findRichText: true),
    );
    expect(client.refreshCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapter recovery handles continuous-scroll catalog navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    const first = BookSourceChapter(id: 'first', title: 'First', order: 1);
    const secondOld = BookSourceChapter(
      id: 'second-old',
      title: 'Second',
      order: 2,
    );
    const secondNew = BookSourceChapter(
      id: 'second-new',
      title: 'Second',
      order: 2,
    );
    final client = _RecoveryClient(
      catalog: const [first, secondOld],
      refreshedCatalog: const [first, secondNew],
      load: (id, _) async {
        if (id == 'second-old') throw _missing;
        return _content(
          id,
          id == 'first' ? _openingBody : 'Catalog recovered body.',
        );
      },
    );
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('Opening body', findRichText: true),
    );
    await _selectChapter(tester, 1);
    await _pumpFor(
      tester,
      find.textContaining('Catalog recovered body.', findRichText: true),
    );
    expect(client.refreshCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapter recovery ignores a superseded continuous-scroll jump', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    final delayed = Completer<BookSourceChapterContent>();
    const first = BookSourceChapter(id: 'first', title: 'First', order: 1);
    const secondOld = BookSourceChapter(
      id: 'second-old',
      title: 'Second',
      order: 2,
    );
    const thirdOld = BookSourceChapter(
      id: 'third-old',
      title: 'Third',
      order: 3,
    );
    const secondNew = BookSourceChapter(
      id: 'second-new',
      title: 'Second',
      order: 2,
    );
    const thirdNew = BookSourceChapter(
      id: 'third-new',
      title: 'Third',
      order: 3,
    );
    final client = _RecoveryClient(
      catalog: const [first, secondOld, thirdOld],
      refreshedCatalog: const [first, secondNew, thirdNew],
      load: (id, _) async {
        if (id == 'second-old') return delayed.future;
        if (id == 'third-old') throw _missing;
        return _content(
          id,
          id == 'first' ? _openingBody : 'Current body for $id.',
        );
      },
    );
    addTearDown(() {
      if (!delayed.isCompleted) {
        delayed.complete(_content('second-old', 'Obsolete jump body.'));
      }
    });
    await open(tester, client);
    await _pumpFor(
      tester,
      find.textContaining('Opening body', findRichText: true),
    );
    await _selectChapter(tester, 1);
    expect(client.requests, contains('second-old'));
    await _selectChapter(tester, 2);
    expect(client.refreshCount, 1);
    expect(client.requests, contains('third-new'));
    await _pumpFor(
      tester,
      find.textContaining('Current body for third-new.', findRichText: true),
    );
    delayed.complete(_content('second-old', 'Obsolete jump body.'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('Obsolete jump body.', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Current body for third-new.', findRichText: true),
      findsWidgets,
    );
    expect(client.refreshCount, 1);
    expect(tester.takeException(), isNull);
  });

  for (final ambiguous in [false, true]) {
    testWidgets(
      'chapter recovery preserves the error for an ${ambiguous ? 'ambiguous' : 'absent'} chapter',
      (tester) async {
        final client = _RecoveryClient(
          catalog: const [_chapterOld],
          refreshedCatalog: ambiguous
              ? const [
                  _chapterNew,
                  BookSourceChapter(
                    id: 'duplicate',
                    title: 'Chapter',
                    order: 2,
                  ),
                ]
              : const [
                  BookSourceChapter(
                    id: 'other',
                    title: 'Different chapter',
                    order: 1,
                  ),
                ],
          load: (_, _) async => throw _missing,
        );
        await open(tester, client);
        await _pumpFor(tester, find.text(_missing.message));
        expect(client.refreshCount, 1);
        expect(client.requests, ['old']);
      },
    );
  }
}

Future<void> _pumpFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _nextChapter(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 5 && target.evaluate().isEmpty; i++) {
    tester.widget<ReaderDesktopInput>(find.byType(ReaderDesktopInput)).onNext();
    for (var step = 0; step < 8; step++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await _pumpFor(tester, target);
}

Future<void> _selectChapter(WidgetTester tester, int index) async {
  tester
      .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
      .onTableOfContents!();
  await _pumpFor(tester, find.byType(ReaderNavigationSheet));
  tester
      .widget<ReaderNavigationSheet>(find.byType(ReaderNavigationSheet))
      .onChapterSelected(index);
  await tester.pump(const Duration(milliseconds: 400));
}

final _openingBody = List.generate(
  35,
  (i) => 'Opening body paragraph $i.',
).join('\n');

const _chapterOld = BookSourceChapter(id: 'old', title: 'Chapter', order: 1);
const _chapterNew = BookSourceChapter(id: 'new', title: 'Chapter', order: 1);
const _book = BookSourceBook(
  id: 'book',
  title: 'Recovery test',
  author: '',
  description: '',
  categories: [],
);
final _source = RegisteredBookSource(
  id: 'recovery.source',
  name: 'Recovery',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

BookSourceChapterContent _content(String id, String text) =>
    BookSourceChapterContent(
      bookId: 'book',
      chapterId: id,
      title: '',
      content: text,
      contentType: 'text/plain',
    );

class _RecoveryClient extends BookSourceClient {
  _RecoveryClient({
    required this.catalog,
    required this.refreshedCatalog,
    required this.load,
  });
  final List<BookSourceChapter> catalog;
  final List<BookSourceChapter> refreshedCatalog;
  final Future<BookSourceChapterContent> Function(String, bool) load;
  final List<String> requests = [];
  int refreshCount = 0;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => catalog;

  @override
  Future<List<BookSourceChapter>> getChaptersForDownload(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    refreshCount++;
    return refreshedCatalog;
  }

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) {
    requests.add(chapterId);
    return load(chapterId, refreshCount > 0);
  }
}

class _NoDiskPagination extends PaginationCacheDao {
  @override
  Future<Map<String, Uint8List>> loadForIdentity(
    String identity,
    String bookRevision,
  ) async => {};
  @override
  Future<void> upsertForIdentity({
    required String identity,
    int? localBookId,
    required String bookRevision,
    required String layoutFingerprint,
    required int chapterIndex,
    required Uint8List payload,
    int? expectedEpoch,
    int? expectedRevisionEpoch,
  }) async {}
}
