import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/book_sources/caching/book_source_chapter_cache.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/networking/book_source_network_policy.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/library/source_book_status_card.dart';
import 'package:xxread/pages/reader/book_settings_page.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/pages/reader/book_source/online_reader_factory.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
  });

  for (final rulesFinishFirst in [true, false]) {
    testWidgets('startup overlaps independent work and waits for both gates '
        '(rules first: $rulesFinishFirst)', (tester) async {
      final rules = _BlockingReplaceRuleService();
      final client = _StartupClient();
      final shelf = _ControlledShelfService(client);
      final progress = _TrackingProgressStore();
      addTearDown(rules.close);

      await tester.pumpWidget(
        _reader(
          client: client,
          shelfService: shelf,
          replaceRules: rules,
          progressStore: progress,
        ),
      );
      await tester.pump();

      expect(rules.loadCount, greaterThanOrEqualTo(1));
      expect(shelf.findCount, 1);
      expect(client.catalogCount, 1);
      expect(progress.loadCount, 1);
      expect(client.contentCount, 0);

      if (rulesFinishFirst) {
        rules.completeLoad();
      } else {
        shelf.completeFind(null);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(client.contentCount, 0);

      if (rulesFinishFirst) {
        shelf.completeFind(null);
      } else {
        rules.completeLoad();
      }
      await _pumpUntil(tester, () => client.contentCount == 1);
      expect(shelf.findCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      shelf.close();
      client.close();
    });
  }

  testWidgets(
    'factory forwards shelf identity without another lookup and keeps book rules',
    (tester) async {
      final rules = ReplaceRuleService();
      final client = _StartupClient();
      final shelf = _ControlledShelfService(client);
      final progress = _TrackingProgressStore();
      final shelfBook = _shelfBook(id: 42);
      await rules.load();
      await rules.upsert(
        const ReplaceRule(
          id: 'book-scope',
          name: 'book scope',
          pattern: '广告内容',
          replacement: '已净化段落',
          isRegex: false,
        ),
      );
      await rules.setBookEnabled('book:42', false);
      addTearDown(rules.close);

      final reader = buildOnlineReader(
        shelfBook: shelfBook,
        client: client,
        shelfService: shelf,
        replaceRuleService: rules,
        initialTheme: ReaderThemes.day,
      );
      expect(reader, isA<BookSourceReaderPage>());
      expect(
        (reader as BookSourceReaderPage).initialShelfBook,
        same(shelfBook),
      );

      await tester.pumpWidget(
        _reader(
          client: client,
          shelfService: shelf,
          replaceRules: rules,
          progressStore: progress,
          initialShelfBook: shelfBook,
        ),
      );
      await _pumpUntil(tester, () => client.contentCount == 1);

      expect(shelf.findCount, 0);
      await _pumpUntil(
        tester,
        () => find
            .textContaining('广告内容', findRichText: true)
            .evaluate()
            .isNotEmpty,
      );
      expect(find.textContaining('广告内容', findRichText: true), findsWidgets);
      expect(find.textContaining('已净化段落', findRichText: true), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      shelf.close();
      client.close();
    },
  );

  testWidgets('transient shelf identity falls back to one lookup', (
    tester,
  ) async {
    final rules = ReplaceRuleService();
    final client = _StartupClient();
    final shelf = _ControlledShelfService(client);
    final progress = _TrackingProgressStore();
    final transientShelfBook = _shelfBook();
    final persistedShelfBook = _shelfBook(id: 42);
    addTearDown(rules.close);

    final reader =
        buildOnlineReader(
              shelfBook: transientShelfBook,
              client: client,
              shelfService: shelf,
              replaceRuleService: rules,
              initialTheme: ReaderThemes.day,
            )
            as BookSourceReaderPage;
    expect(reader.initialShelfBook, same(transientShelfBook));

    await tester.pumpWidget(
      _reader(
        client: client,
        shelfService: shelf,
        replaceRules: rules,
        progressStore: progress,
        initialShelfBook: reader.initialShelfBook,
      ),
    );
    await tester.pump();
    expect(shelf.findCount, 1);
    expect(client.contentCount, 0);

    shelf.completeFind(persistedShelfBook);
    await _pumpUntil(tester, () => client.contentCount == 1);
    expect(shelf.findCount, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    shelf.close();
    client.close();
  });

  testWidgets(
    'settings refresh remains authoritative during reinitialization',
    (tester) async {
      final rules = ReplaceRuleService();
      final client = _StartupClient();
      final shelf = _ControlledShelfService(client);
      final progress = _TrackingProgressStore();
      final initialShelfBook = _shelfBook(id: 42);
      final refreshedShelfBook = _shelfBook(id: 84);
      await rules.load();
      await rules.upsert(
        const ReplaceRule(
          id: 'refreshed-book-scope',
          name: 'refreshed book scope',
          pattern: '广告内容',
          replacement: '已净化段落',
          isRegex: false,
        ),
      );
      await rules.setBookEnabled('book:42', false);
      shelf.completeFind(initialShelfBook);
      addTearDown(rules.close);

      await tester.pumpWidget(
        _reader(
          client: client,
          shelfService: shelf,
          replaceRules: rules,
          progressStore: progress,
          initialShelfBook: initialShelfBook,
        ),
      );
      await _pumpUntil(tester, () => client.contentCount == 1);
      expect(shelf.findCount, 0);

      tester
          .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
          .onBookSettings!();
      await tester.pumpAndSettle();
      final settings = find.byType(BookSettingsPage);
      final statusCard = tester.widget<SourceBookStatusCard>(
        find.byType(SourceBookStatusCard),
      );
      statusCard.onBookChanged!(refreshedShelfBook);
      Navigator.of(tester.element(settings)).pop();

      await _pumpUntil(tester, () => client.contentCount >= 2);
      await _pumpUntil(
        tester,
        () => find
            .textContaining('已净化段落', findRichText: true)
            .evaluate()
            .isNotEmpty,
      );
      expect(shelf.findCount, 1);
      expect(find.textContaining('广告内容', findRichText: true), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      shelf.close();
      client.close();
    },
  );

  testWidgets('cached catalog shows body while its source refresh is pending', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('online-reader-stale-catalog-'),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    final server = _OrspStartupServer();
    final dio = Dio()..httpClientAdapter = server;
    final client = BookSourceClient(
      dio: dio,
      chapterCache: BookSourceChapterCache(cacheDirectory: directory),
      networkPolicy: BookSourceNetworkPolicy(
        lookup: (_) async => [InternetAddress('93.184.216.34')],
      ),
    );
    final rules = ReplaceRuleService();
    final shelf = _ControlledShelfService(client);
    final progress = _TrackingProgressStore();
    await rules.load();
    addTearDown(rules.close);
    addTearDown(() {
      final gate = server.catalogGate;
      if (gate != null && !gate.isCompleted) gate.complete();
      shelf.close();
      client.close();
    });

    await tester.runAsync(() async {
      await client.getChaptersForDownload(_source, _sourceBook.id);
      await client.getChapterContent(
        _source,
        bookId: _sourceBook.id,
        chapterId: 'chapter-1',
      );
      final catalogFile = await _waitForReaderCacheFiles(directory);
      await catalogFile.setLastModified(
        DateTime.now().subtract(const Duration(minutes: 31)),
      );
    });
    BookSourceChapterCache.releaseMemory();
    server.events.clear();
    server.catalogGate = Completer<void>();

    await tester.pumpWidget(
      _reader(
        client: client,
        shelfService: shelf,
        replaceRules: rules,
        progressStore: progress,
        initialShelfBook: _shelfBook(id: 42),
      ),
    );
    await _pumpUntil(tester, () => server.events.contains('catalog'));
    await _pumpUntil(
      tester,
      () =>
          find.textContaining('缓存正文', findRichText: true).evaluate().isNotEmpty,
    );

    expect(server.catalogGate!.isCompleted, isFalse);
    expect(server.events, ['catalog']);
    expect(find.textContaining('缓存正文', findRichText: true), findsWidgets);

    server.catalogGate!.complete();
    await _pumpUntil(tester, () => server.catalogResponses == 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Widget _reader({
  required BookSourceClient client,
  required BookSourceShelfService shelfService,
  required ReplaceRuleService replaceRules,
  required BookSourceReadingProgressStore progressStore,
  Book? initialShelfBook,
}) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BookSourceReaderPage(
    source: _source,
    book: _sourceBook,
    client: client,
    shelfService: shelfService,
    initialShelfBook: initialShelfBook,
    replaceRuleService: replaceRules,
    progressStore: progressStore,
    paginationCacheDao: _MemoryPaginationCacheDao(),
    initialTheme: ReaderThemes.day,
  ),
);

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 60 && !condition(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 25));
  }
  expect(condition(), isTrue);
}

final _source = RegisteredBookSource(
  id: 'startup.source',
  name: '启动测试书源',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.0',
  languages: const ['zh-CN'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026, 10, 8),
);

const _sourceBook = BookSourceBook(
  id: 'startup-book',
  title: '启动测试书籍',
  author: '测试作者',
  description: '',
  categories: [],
);

Book _shelfBook({int? id}) => Book(
  id: id,
  title: _sourceBook.title,
  author: _sourceBook.author,
  filePath: '',
  format: 'source',
  storageType: 'online',
  sourceId: _source.id,
  sourceBookId: _sourceBook.id,
  sourceJson: jsonEncode(_source.toJson()),
  sourceBookJson: jsonEncode(_sourceBook.toJson()),
);

class _BlockingReplaceRuleService extends ReplaceRuleService {
  final Completer<void> _load = Completer<void>();
  int loadCount = 0;

  @override
  Future<void> load() {
    loadCount++;
    return _load.future;
  }

  void completeLoad() {
    if (!_load.isCompleted) _load.complete();
  }
}

class _StartupClient extends BookSourceClient {
  int catalogCount = 0;
  int contentCount = 0;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async {
    catalogCount++;
    return const [BookSourceChapter(id: 'chapter-1', title: '第一章', order: 1)];
  }

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async {
    contentCount++;
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: '第一章',
      content: '正文开头\n广告内容\n正文结尾',
      contentType: 'text/plain',
    );
  }
}

class _ControlledShelfService extends BookSourceShelfService {
  _ControlledShelfService(BookSourceClient client) : super(client: client);

  final Completer<Book?> _find = Completer<Book?>();
  int findCount = 0;

  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) {
    findCount++;
    return _find.future;
  }

  void completeFind(Book? book) {
    if (!_find.isCompleted) _find.complete(book);
  }

  @override
  Future<void> updateShelfProgress({
    required int shelfBookId,
    required int chapterIndex,
    required int chapterCount,
    required double chapterProgress,
  }) async {}
}

class _TrackingProgressStore extends BookSourceReadingProgressStore {
  int loadCount = 0;

  @override
  Future<BookSourceReadingProgress?> load({
    required String sourceId,
    required String bookId,
  }) async {
    loadCount++;
    return null;
  }

  @override
  Future<void> save({
    required String sourceId,
    required String bookId,
    required BookSourceReadingProgress progress,
  }) async {}
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

class _OrspStartupServer implements HttpClientAdapter {
  Completer<void>? catalogGate;
  int catalogResponses = 0;
  final events = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('/chapters')) {
      events.add('catalog');
      await catalogGate?.future;
      catalogResponses++;
      return _json(
        '{"items":[{"id":"chapter-1","title":"第一章","order":1}],'
        '"page":1,"pageSize":100,"hasMore":false}',
      );
    }
    events.add('content');
    return _json(
      '{"bookId":"${_sourceBook.id}","chapterId":"chapter-1",'
      '"title":"第一章","contentType":"text/plain",'
      '"content":"缓存正文"}',
    );
  }

  ResponseBody _json(String body) => ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<File> _waitForReaderCacheFiles(Directory directory) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    final files = await directory
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .cast<File>()
        .toList();
    File? catalog;
    var hasChapter = false;
    for (final file in files) {
      if (file.parent.path.endsWith('catalogs')) {
        catalog = file;
      } else if (file.parent.path == directory.path) {
        hasChapter = true;
      }
    }
    if (catalog != null && hasChapter) return catalog;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Catalog and current chapter were not persisted');
}
