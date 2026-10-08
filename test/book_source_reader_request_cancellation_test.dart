@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';

import 'support/book_source_progress_test_utils.dart';
import 'support/no_shelf_book_source_service.dart';

void main() {
  late ReplaceRuleService replaceRules;
  late BookSourceProgressTestFixture progressFixture;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    replaceRules = ReplaceRuleService();
    progressFixture = await BookSourceProgressTestFixture.create();
  });

  tearDown(() async {
    await replaceRules.close();
    await progressFixture.close();
  });

  testWidgets('exiting cancels this reader catalog on a borrowed client', (
    tester,
  ) async {
    final client = _CancellationClient(pendingCatalog: true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    _pushReader(
      navigator,
      client: client,
      replaceRules: replaceRules,
      progressFixture: progressFixture,
      initialShelfBook: _shelfBook,
    );

    await _pumpUntil(tester, () => client.catalogCancellation != null);
    final cancellation = client.catalogCancellation!;
    await navigator.currentState!.maybePop();
    await _pumpUntil(tester, () => cancellation.isCancelled);

    expect(find.byType(BookSourceReaderPage), findsNothing);
    expect(find.text('source detail'), findsOneWidget);
    expect(client.closeCount, 0);
    client.close();
  });

  testWidgets('exiting cancels this reader content on a borrowed client', (
    tester,
  ) async {
    final client = _CancellationClient(pendingContent: true);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    _pushReader(
      navigator,
      client: client,
      replaceRules: replaceRules,
      progressFixture: progressFixture,
      initialShelfBook: _shelfBook,
    );

    await _pumpUntil(tester, () => client.contentCancellation != null);
    final cancellation = client.contentCancellation!;
    await navigator.currentState!.maybePop();
    await _pumpUntil(tester, () => cancellation.isCancelled);

    expect(find.byType(BookSourceReaderPage), findsNothing);
    expect(client.closeCount, 0);
    client.close();
  });

  testWidgets('back cancels content before waiting for progress persistence', (
    tester,
  ) async {
    final client = _CancellationClient(pendingPrefetch: true);
    final progressStore = _BlockingProgressStore();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    _pushReader(
      navigator,
      client: client,
      replaceRules: replaceRules,
      progressStore: progressStore,
      initialShelfBook: _shelfBook,
    );

    await _pumpUntil(
      tester,
      () =>
          find.byType(ReaderAnnotatedTextPage).evaluate().isNotEmpty &&
          client.prefetchCancellation != null,
    );
    final cancellation = client.prefetchCancellation!;
    await tester.tapAt(
      tester.getCenter(find.byType(ReaderAnnotatedTextPage).first),
    );
    await _pumpUntil(
      tester,
      () => find
          .byIcon(Icons.arrow_back_rounded)
          .hitTestable()
          .evaluate()
          .isNotEmpty,
    );
    progressStore.blockNextSave();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable().first);
    await _pumpUntil(tester, () => progressStore.saveStarted.isCompleted);

    expect(cancellation.isCancelled, isTrue);
    expect(find.byType(BookSourceReaderPage), findsOneWidget);

    progressStore.releaseSave();
    await _pumpUntil(
      tester,
      () => find.byType(BookSourceReaderPage).evaluate().isEmpty,
    );
    expect(find.text('source detail'), findsOneWidget);
    expect(client.closeCount, 0);
    client.close();
  });

  testWidgets('dismissing the exit dialog keeps reader requests usable', (
    tester,
  ) async {
    final client = _CancellationClient();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigator));
    _pushReader(
      navigator,
      client: client,
      replaceRules: replaceRules,
      progressFixture: progressFixture,
    );

    await _pumpUntil(
      tester,
      () => find.byType(ReaderAnnotatedTextPage).evaluate().isNotEmpty,
    );
    final cancellation = client.contentCancellation!;
    await navigator.currentState!.maybePop();
    await _pumpUntil(
      tester,
      () => find.byType(AlertDialog).evaluate().isNotEmpty,
    );
    expect(cancellation.isCancelled, isFalse);

    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.byType(BookSourceReaderPage), findsOneWidget);
    expect(find.byType(ReaderAnnotatedTextPage), findsWidgets);
    expect(cancellation.isCancelled, isFalse);
    expect(client.closeCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    client.close();
  });
}

Widget _app(GlobalKey<NavigatorState> navigator) => MaterialApp(
  navigatorKey: navigator,
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const Scaffold(body: Text('source detail')),
);

void _pushReader(
  GlobalKey<NavigatorState> navigator, {
  required _CancellationClient client,
  required ReplaceRuleService replaceRules,
  BookSourceProgressTestFixture? progressFixture,
  BookSourceReadingProgressStore? progressStore,
  Book? initialShelfBook,
}) {
  unawaited(
    navigator.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => BookSourceReaderPage(
          source: _source,
          book: _book,
          client: client,
          shelfService: _TestShelfService(client),
          replaceRuleService: replaceRules,
          progressStore: progressStore ?? progressFixture!.store,
          paginationCacheDao: _MemoryPaginationCacheDao(),
          initialShelfBook: initialShelfBook,
          initialTheme: ReaderThemes.day,
        ),
      ),
    ),
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for reader request state.');
}

class _CancellationClient extends BookSourceClient {
  _CancellationClient({
    this.pendingCatalog = false,
    this.pendingContent = false,
    this.pendingPrefetch = false,
  });

  final bool pendingCatalog;
  final bool pendingContent;
  final bool pendingPrefetch;
  BookDownloadCancellation? catalogCancellation;
  BookDownloadCancellation? contentCancellation;
  BookDownloadCancellation? prefetchCancellation;
  int closeCount = 0;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) {
    catalogCancellation = cancellation;
    if (pendingCatalog) {
      return _untilCancelled<List<BookSourceChapter>>(cancellation);
    }
    return Future.value([
      const BookSourceChapter(id: 'chapter-1', title: '第一章', order: 0),
      if (pendingPrefetch)
        const BookSourceChapter(id: 'chapter-2', title: '第二章', order: 1),
    ]);
  }

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) {
    contentCancellation = cancellation;
    if (pendingContent) {
      return _untilCancelled<BookSourceChapterContent>(cancellation);
    }
    if (pendingPrefetch && chapterId == 'chapter-2') {
      prefetchCancellation = cancellation;
      return _untilCancelled<BookSourceChapterContent>(cancellation);
    }
    return Future.value(
      BookSourceChapterContent(
        bookId: bookId,
        chapterId: chapterId,
        title: '第一章',
        content: '正文内容可以在退出对话框取消后继续阅读。',
        contentType: 'text/plain',
      ),
    );
  }

  Future<T> _untilCancelled<T>(BookDownloadCancellation? cancellation) {
    final completer = Completer<T>();
    cancellation?.addListener(() {
      if (!completer.isCompleted) {
        completer.completeError(const BookDownloadCancelledException());
      }
    });
    return completer.future;
  }

  @override
  void close({bool force = false}) {
    closeCount++;
    super.close(force: force);
  }
}

class _TestShelfService extends NoShelfBookSourceService {
  _TestShelfService(super.client);

  int updateCalls = 0;

  @override
  Future<void> updateShelfProgress({
    required int shelfBookId,
    required int chapterIndex,
    required int chapterCount,
    required double chapterProgress,
  }) async {
    updateCalls++;
  }
}

class _BlockingProgressStore extends BookSourceReadingProgressStore {
  _BlockingProgressStore();

  bool _block = false;
  Completer<void> saveStarted = Completer<void>();
  Completer<void> _saveRelease = Completer<void>();

  void blockNextSave() {
    _block = true;
    saveStarted = Completer<void>();
    _saveRelease = Completer<void>();
  }

  void releaseSave() {
    if (!_saveRelease.isCompleted) _saveRelease.complete();
  }

  @override
  Future<BookSourceReadingProgress?> load({
    required String sourceId,
    required String bookId,
  }) async => null;

  @override
  Future<void> save({
    required String sourceId,
    required String bookId,
    required BookSourceReadingProgress progress,
  }) async {
    if (!_block) return;
    _block = false;
    if (!saveStarted.isCompleted) saveStarted.complete();
    await _saveRelease.future;
  }
}

class _MemoryPaginationCacheDao extends PaginationCacheDao {
  @override
  Future<Map<String, Uint8List>> loadForIdentity(
    String identity,
    String bookRevision,
  ) async => const {};

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

final _source = RegisteredBookSource(
  id: 'shared-source',
  name: '共享书源',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: const {'search'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

const _book = BookSourceBook(
  id: 'book-1',
  title: '取消测试',
  author: '作者',
  description: '',
  categories: [],
);

final _shelfBook = Book(
  id: 7,
  title: _book.title,
  author: _book.author,
  filePath: '',
  format: 'source',
  storageType: 'online',
  sourceId: _source.id,
  sourceBookId: _book.id,
);
