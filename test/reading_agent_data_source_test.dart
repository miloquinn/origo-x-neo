import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/services/ai/reading_agent_data_source.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/reading/reading_stats_dao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'overview follows real session recency and exposes only book facts',
    () async {
      final books = [
        _book(1, title: 'Imported first', secret: '/private/first.epub'),
        _book(2, title: 'Read most recently', secret: '/private/recent.epub'),
      ];
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(books),
        readingStatsDao: _FakeReadingStatsDao(recentBookIds: const [2, 1]),
        sourceRegistry: _FakeRegistry(const []),
        client: _FakeClient(),
      );
      addTearDown(dataSource.dispose);

      final overview = await dataSource.readingOverview();
      final recent = overview['recentBooks'] as List<dynamic>;
      expect(recent.map((item) => (item as Map)['id']), [2, 1]);
      expect(
        (recent.first as Map<String, dynamic>).keys,
        unorderedEquals(['id', 'title', 'author', 'format', 'progress']),
      );
      expect(jsonEncode(overview), isNot(contains('/private/')));
    },
  );

  test(
    'library pagination is bounded and never serializes storage metadata',
    () async {
      final books = List.generate(
        55,
        (index) => _book(
          index + 1,
          title: 'Book $index',
          secret: '/private/book-$index.epub',
        ),
      );
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(books),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: _FakeRegistry(const []),
        client: _FakeClient(),
      );
      addTearDown(dataSource.dispose);

      final page = await dataSource.listBooks(offset: -9, limit: 500);
      expect(page['offset'], 0);
      expect(page['limit'], 50);
      expect((page['items'] as List).length, 50);
      expect(page['hasMore'], isTrue);
      final encoded = jsonEncode(page);
      expect(encoded, isNot(contains('/private/')));
      expect(encoded, isNot(contains('filePath')));
      expect(encoded, isNot(contains('sourceJson')));
    },
  );

  test('sources and candidates use opaque request-local aliases', () async {
    final source = _source(
      'https://secret.example/source?id=user-token',
      name: 'Searchable',
    );
    final disabled = _source('disabled-secret', enabled: false);
    final noSearch = _source('browse-secret', capabilities: const {'browse'});
    final client = _FakeClient(
      results: {
        source.id: const BookSourceSearchPage(
          items: [
            BookSourceBook(
              id: 'https://secret.example/book/42?cookie=hidden',
              title: 'Candidate',
              author: 'Author',
              description: 'Description',
              categories: ['Fantasy'],
              status: 'ongoing',
              latestChapter: 'Chapter 12',
              coverHeaders: {'Cookie': 'hidden'},
              sourceVariables: {'token': 'hidden'},
            ),
          ],
          page: 1,
          pageSize: 12,
          hasMore: false,
        ),
      },
    );
    final dataSource = LocalReadingAgentDataSource(
      bookDao: _FakeBookDao(const []),
      readingStatsDao: _FakeReadingStatsDao(),
      sourceRegistry: _FakeRegistry([source, disabled, noSearch]),
      client: client,
    );
    addTearDown(dataSource.dispose);
    dataSource.beginRequest();

    final sources = await dataSource.listSources();
    expect(sources['items'], [
      {
        'sourceId': 's1',
        'name': 'Searchable',
        'protocol': 'orsp',
        'capabilities': ['search'],
      },
    ]);
    final search = await dataSource.searchBooks(
      query: 'candidate',
      sourceIds: const ['s1'],
    );
    final encoded = jsonEncode(search);
    expect(encoded, contains('"candidateId":"c1"'));
    expect(encoded, contains('"sourceId":"s1"'));
    expect(encoded, isNot(contains('secret.example')));
    expect(encoded, isNot(contains('cookie')));
    expect(encoded, isNot(contains('token')));
    expect(dataSource.candidate('c1')?.book.id, contains('secret.example'));

    dataSource.cancel();
    expect(dataSource.candidate('c1'), isNotNull);
    dataSource.beginRequest();
    expect(dataSource.candidate('c1'), isNull);
  });

  test(
    'search is bounded, preserves partial results, and cancels timeouts',
    () async {
      final sources = [
        _source('good'),
        _source('broken'),
        _source('hanging'),
        _source('fourth'),
        _source('must-not-run'),
      ];
      final client = _FakeClient(
        results: {
          'good': _page('Good result'),
          'fourth': _page('Fourth result'),
        },
        failingSourceIds: const {'broken'},
        hangingSourceIds: const {'hanging'},
      );
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: _FakeRegistry(sources),
        client: client,
        searchTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(dataSource.dispose);

      final result = await dataSource.searchBooks(query: 'query', limit: 999);
      expect(result['limit'], 20);
      expect(client.searchedSourceIds, ['good', 'broken', 'hanging', 'fourth']);
      expect(client.timedOutCancellation?.isCancelled, isTrue);
      expect((result['items'] as List).map((item) => (item as Map)['title']), [
        'Good result',
        'Fourth result',
      ]);
      expect(result['failures'], [
        {'sourceId': 's2', 'reason': 'search_failed'},
        {'sourceId': 's3', 'reason': 'timeout'},
      ]);
      expect(result['searchedSourceIds'], ['s1', 's2', 's3', 's4']);
      expect(result['sourcesSearched'], 4);
      expect(result['sourcesAvailable'], 5);
      expect(result['sourceCoverageComplete'], isFalse);
      expect(result['hasMore'], isTrue);
    },
  );

  test(
    'source aliases stay stable and searches use refreshed source data',
    () async {
      final registry = _FakeRegistry([
        _source('source-a', name: 'A old'),
        _source('source-b', name: 'B old'),
      ]);
      final client = _FakeClient();
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: registry,
        client: client,
      );
      addTearDown(dataSource.dispose);
      dataSource.beginRequest();

      expect((await dataSource.listSources())['items'], [
        {
          'sourceId': 's1',
          'name': 'A old',
          'protocol': 'orsp',
          'capabilities': ['search'],
        },
        {
          'sourceId': 's2',
          'name': 'B old',
          'protocol': 'orsp',
          'capabilities': ['search'],
        },
      ]);
      registry.sources = [
        _source('source-b', name: 'B refreshed'),
        _source('source-a', name: 'A refreshed'),
      ];
      expect((await dataSource.listSources())['items'], [
        {
          'sourceId': 's2',
          'name': 'B refreshed',
          'protocol': 'orsp',
          'capabilities': ['search'],
        },
        {
          'sourceId': 's1',
          'name': 'A refreshed',
          'protocol': 'orsp',
          'capabilities': ['search'],
        },
      ]);

      await dataSource.searchBooks(
        query: 'query',
        sourceIds: const ['s1', 's1', 's2'],
      );
      expect(client.searchedSourceIds, ['source-a', 'source-b']);
      expect(client.searchedSourceNames, ['A refreshed', 'B refreshed']);
    },
  );

  test('imported source text is bounded before Agent serialization', () async {
    final source = _source('bounded-source', name: 'N' * 250);
    final client = _FakeClient(
      results: {
        source.id: BookSourceSearchPage(
          items: [
            BookSourceBook(
              id: 'private-id',
              title: 'T' * 250,
              author: 'A' * 250,
              description: 'D' * 1700,
              categories: List.generate(25, (_) => 'C' * 100),
              status: 'S' * 100,
              latestChapter: 'L' * 250,
            ),
          ],
          page: 1,
          pageSize: 20,
          hasMore: false,
        ),
      },
    );
    final dataSource = LocalReadingAgentDataSource(
      bookDao: _FakeBookDao(const []),
      readingStatsDao: _FakeReadingStatsDao(),
      sourceRegistry: _FakeRegistry([source]),
      client: client,
    );
    addTearDown(dataSource.dispose);

    final sources = await dataSource.listSources();
    expect(((sources['items'] as List).single['name'] as String).length, 200);
    final search = await dataSource.searchBooks(query: 'query');
    final item = (search['items'] as List).single as Map<String, dynamic>;
    expect((item['title'] as String).length, 200);
    expect((item['author'] as String).length, 200);
    expect((item['description'] as String).length, 1600);
    expect((item['categories'] as List).length, 20);
    expect(((item['categories'] as List).first as String).length, 80);
    expect((item['status'] as String).length, 80);
    expect((item['latestChapter'] as String).length, 200);
  });

  test(
    'cancel suppresses stale search results and lifecycle respects ownership',
    () async {
      final source = _source('delayed');
      final borrowedClient = _FakeClient(delayedSourceIds: const {'delayed'});
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: _FakeRegistry([source]),
        client: borrowedClient,
      );
      final pending = dataSource.searchBooks(query: 'query');
      await borrowedClient.started.future;
      dataSource.cancel();
      borrowedClient.releaseDelayed();
      final stale = await pending;
      expect(stale['stale'], isTrue);
      expect(stale['items'], isEmpty);
      expect(dataSource.candidate('c1'), isNull);
      dataSource.dispose();
      expect(borrowedClient.closeCount, 0);

      final ownedClient = _FakeClient();
      final owned = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: _FakeRegistry(const []),
        clientFactory: () => ownedClient,
      );
      expect(identical(owned.client, ownedClient), isTrue);
      owned.dispose();
      owned.dispose();
      expect(ownedClient.closeCount, 1);
    },
  );

  test(
    'historical recommendation resolves only one exact enabled match',
    () async {
      final active = _source('active-secret-id');
      final disabled = _source('disabled-secret-id', enabled: false);
      const exact = BookSourceBook(
        id: 'private-book-locator',
        title: 'Exact title',
        author: 'Exact author',
        description: '',
        categories: [],
      );
      final client = _FakeClient(
        results: {
          active.id: const BookSourceSearchPage(
            items: [exact],
            page: 1,
            pageSize: 20,
            hasMore: false,
          ),
        },
      );
      final registry = _FakeRegistry([active, disabled]);
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: registry,
        client: client,
      );
      addTearDown(dataSource.dispose);

      final resolved = await dataSource.resolveRecommendation(
        sourceKey: sha256.convert(utf8.encode(active.id)).toString(),
        title: exact.title,
        author: exact.author,
      );
      expect(resolved?.source.id, active.id);
      expect(resolved?.book.id, exact.id);
      expect(client.searchedSourceIds, [active.id]);

      final disabledResult = await dataSource.resolveRecommendation(
        sourceKey: sha256.convert(utf8.encode(disabled.id)).toString(),
        title: exact.title,
        author: exact.author,
      );
      expect(disabledResult, isNull);
      expect(client.searchedSourceIds, [active.id]);

      client.results[active.id] = const BookSourceSearchPage(
        items: [exact, exact],
        page: 1,
        pageSize: 20,
        hasMore: false,
      );
      final ambiguous = await dataSource.resolveRecommendation(
        sourceKey: sha256.convert(utf8.encode(active.id)).toString(),
        title: exact.title,
        author: exact.author,
      );
      expect(ambiguous, isNull);
    },
  );

  test(
    'dispose while registry loads prevents historical network search',
    () async {
      final source = _source('delayed-source');
      final registry = _DelayedRegistry([source]);
      final client = _FakeClient();
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: registry,
        client: client,
      );
      final pending = dataSource.resolveRecommendation(
        sourceKey: sha256.convert(utf8.encode(source.id)).toString(),
        title: 'Title',
        author: 'Author',
      );
      await registry.started.future;
      dataSource.dispose();
      registry.release();
      expect(await pending, isNull);
      expect(client.searchedSourceIds, isEmpty);
    },
  );

  test(
    'new request while registry loads prevents stale network search',
    () async {
      final source = _source('delayed-search-source');
      final registry = _DelayedRegistry([source]);
      final client = _FakeClient();
      final dataSource = LocalReadingAgentDataSource(
        bookDao: _FakeBookDao(const []),
        readingStatsDao: _FakeReadingStatsDao(),
        sourceRegistry: registry,
        client: client,
      );
      addTearDown(dataSource.dispose);

      final pending = dataSource.searchBooks(query: 'query');
      await registry.started.future;
      dataSource.beginRequest();
      registry.release();
      final result = await pending;
      expect(result['stale'], isTrue);
      expect(client.searchedSourceIds, isEmpty);
    },
  );

  test('stats-only methods never read library metadata', () async {
    final stats = _FakeReadingStatsDao(
      sessions: const [
        {
          'id': 99,
          'date': '2026-10-10',
          'bookId': 7,
          'startTimeMs': 100,
          'endTimeMs': 200,
          'durationInSeconds': 100,
          'pagesRead': 3,
        },
      ],
    );
    final bookDao = _ThrowingBookDao();
    final dataSource = LocalReadingAgentDataSource(
      bookDao: bookDao,
      readingStatsDao: stats,
      sourceRegistry: _FakeRegistry(const []),
      client: _FakeClient(),
    );
    addTearDown(dataSource.dispose);

    final result = await dataSource.readingSessions(offset: -1, limit: 500);
    expect(stats.lastSessionOffset, 0);
    expect(stats.lastSessionLimit, 50);
    expect(jsonEncode(result), isNot(contains('"id":99')));
    expect(jsonEncode(result), isNot(contains('/private/')));
    expect((result['items'] as List).single['bookId'], 7);

    final statistics = await dataSource.readingStatistics(
      days: 999,
      offset: 1,
      limit: 1,
    );
    expect(statistics['days'], 365);
    expect(statistics['bookStatisticsScope'], 'allTime');
    expect(statistics['booksTotal'], 3);
    expect(statistics['booksOffset'], 1);
    expect(statistics['booksLimit'], 1);
    expect(statistics['nextOffset'], 2);
    expect((statistics['books'] as List).single['bookId'], 8);
    expect((statistics['summary'] as Map)['unit'], 'seconds');
    expect(
      (statistics['sessions'] as Map)['recordUnit'],
      'dailySessionFragments',
    );
    expect(jsonEncode(statistics), isNot(contains('must-not-leak')));
    expect(bookDao.readCount, 0);
  });

  test('raw reading sessions query is ordered and parameter bounded', () async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    addTearDown(database.close);
    await database.execute('''
      CREATE TABLE reading_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        bookId INTEGER,
        startTimeMs INTEGER NOT NULL,
        endTimeMs INTEGER NOT NULL,
        durationInSeconds INTEGER NOT NULL,
        pagesRead INTEGER NOT NULL
      )
    ''');
    for (final endTime in [100, 200, 300]) {
      await database.insert('reading_sessions', {
        'date': '2026-10-10',
        'bookId': endTime ~/ 100,
        'startTimeMs': endTime - 50,
        'endTimeMs': endTime,
        'durationInSeconds': 50,
        'pagesRead': 1,
      });
    }
    final dao = ReadingStatsDao(database: () async => database);

    final middle = await dao.getReadingSessions(offset: 1, limit: 1);
    expect(middle.single['endTimeMs'], 200);
    final bounded = await dao.getReadingSessions(offset: -20, limit: 999);
    expect(bounded.map((row) => row['endTimeMs']), [300, 200, 100]);
  });
}

Book _book(
  int id, {
  String title = 'Book',
  String secret = '/private/book.epub',
}) => Book(
  id: id,
  title: title,
  author: 'Author',
  filePath: secret,
  format: 'epub',
  currentPage: 25,
  totalPages: 100,
  sourceId: 'https://secret.example/source',
  sourceJson: '{"headers":{"Cookie":"hidden"}}',
);

RegisteredBookSource _source(
  String id, {
  String name = 'Source',
  bool enabled = true,
  Set<String> capabilities = const {'search'},
}) => RegisteredBookSource(
  id: id,
  name: name,
  description: 'private description',
  manifestUrl: Uri.parse('https://manifest.secret.example/source.json'),
  apiBaseUrl: Uri.parse('https://api.secret.example/'),
  protocolVersion: '1.0',
  languages: const ['zh'],
  capabilities: capabilities,
  enabled: enabled,
  addedAt: DateTime(2026),
  sourceConfig: const {
    'headers': {'Cookie': 'hidden'},
  },
);

BookSourceSearchPage _page(String title) => BookSourceSearchPage(
  items: [
    BookSourceBook(
      id: '$title-raw-id',
      title: title,
      author: 'Author',
      description: '',
      categories: const [],
    ),
  ],
  page: 1,
  pageSize: 20,
  hasMore: false,
);

class _FakeBookDao extends BookDao {
  _FakeBookDao(this.books);

  final List<Book> books;

  @override
  Future<List<Book>> getAllBooks() async => books;

  @override
  Future<List<Book>> getBooksByIds(Iterable<int> bookIds) async {
    final byId = {for (final book in books) book.id: book};
    return bookIds.map((id) => byId[id]).whereType<Book>().toList();
  }
}

class _ThrowingBookDao extends BookDao {
  int readCount = 0;

  @override
  Future<List<Book>> getAllBooks() async {
    readCount++;
    throw StateError('library permission boundary crossed');
  }

  @override
  Future<List<Book>> getBooksByIds(Iterable<int> bookIds) async {
    readCount++;
    throw StateError('library permission boundary crossed');
  }
}

class _FakeReadingStatsDao extends ReadingStatsDao {
  _FakeReadingStatsDao({
    this.recentBookIds = const [],
    this.sessions = const [],
  });

  final List<int> recentBookIds;
  final List<Map<String, dynamic>> sessions;
  int? lastSessionOffset;
  int? lastSessionLimit;

  @override
  Future<Map<String, int>> getSummaryStats() async => const {
    'total': 600,
    'today': 120,
    'week': 300,
  };

  @override
  Future<Map<String, int>> getSessionSummary({int recentDays = 90}) async =>
      const {
        'totalSessions': 2,
        'totalMinutes': 10,
        'avgSessionMinutes': 5,
        'maxSessionMinutes': 6,
      };

  @override
  Future<List<int>> getRecentBookIds({int limit = 5}) async =>
      recentBookIds.take(limit).toList();

  @override
  Future<List<Map<String, dynamic>>> getDailyStatsRange(
    DateTime startDate,
    DateTime endDate,
  ) async => const [
    {
      'date': '2026-10-10',
      'duration': 60,
      'pages': 2,
      'books_read': 1,
      'future_private_field': 'must-not-leak',
    },
  ];

  @override
  Future<Map<int, int>> getHourlyReadingDistribution({int days = 30}) async =>
      const {};

  @override
  Future<Map<int, Map<String, dynamic>>> getBookReadingStats() async => const {
    7: {
      'durationSeconds': 60,
      'durationMinutes': 1,
      'pagesRead': 2,
      'sessionCount': 1,
      'lastReadMs': 100,
      'future_private_field': 'must-not-leak',
    },
    8: {
      'durationSeconds': 120,
      'durationMinutes': 2,
      'pagesRead': 4,
      'sessionCount': 2,
      'lastReadMs': 200,
    },
    9: {
      'durationSeconds': 180,
      'durationMinutes': 3,
      'pagesRead': 6,
      'sessionCount': 3,
      'lastReadMs': 300,
    },
  };

  @override
  Future<List<Map<String, dynamic>>> getReadingSessions({
    int offset = 0,
    int limit = 20,
  }) async {
    lastSessionOffset = offset;
    lastSessionLimit = limit;
    return sessions.take(limit).toList();
  }
}

class _FakeRegistry extends BookSourceRegistry {
  _FakeRegistry(this.sources);

  List<RegisteredBookSource> sources;

  @override
  Future<List<RegisteredBookSource>> loadRunnableInBackground() async =>
      sources;
}

class _DelayedRegistry extends BookSourceRegistry {
  _DelayedRegistry(this.sources);

  final List<RegisteredBookSource> sources;
  final Completer<void> started = Completer<void>();
  final Completer<void> _release = Completer<void>();

  void release() => _release.complete();

  @override
  Future<List<RegisteredBookSource>> loadRunnableInBackground() async {
    started.complete();
    await _release.future;
    return sources;
  }
}

class _FakeClient extends BookSourceClient {
  _FakeClient({
    this.results = const {},
    this.failingSourceIds = const {},
    this.hangingSourceIds = const {},
    this.delayedSourceIds = const {},
  });

  final Map<String, BookSourceSearchPage> results;
  final Set<String> failingSourceIds;
  final Set<String> hangingSourceIds;
  final Set<String> delayedSourceIds;
  final List<String> searchedSourceIds = [];
  final List<String> searchedSourceNames = [];
  final Completer<void> started = Completer<void>();
  final Completer<void> _release = Completer<void>();
  BookDownloadCancellation? timedOutCancellation;
  int closeCount = 0;

  void releaseDelayed() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    searchedSourceIds.add(source.id);
    searchedSourceNames.add(source.name);
    if (!started.isCompleted) started.complete();
    if (failingSourceIds.contains(source.id)) {
      throw StateError('secret failure at ${source.apiBaseUrl}');
    }
    if (hangingSourceIds.contains(source.id)) {
      timedOutCancellation = cancellation;
      await cancellation!.whenCancelled;
      cancellation.throwIfCancelled();
    }
    if (delayedSourceIds.contains(source.id)) await _release.future;
    return results[source.id] ?? _page('Result from ${source.name}');
  }

  @override
  void close({bool force = true}) {
    closeCount++;
  }
}
