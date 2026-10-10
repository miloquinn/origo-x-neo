import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/reading/reading_stats_dao.dart';

/// Local, bounded facts that the reading Agent may request after the caller
/// has enforced the corresponding consent category.
abstract class ReadingAgentDataSource {
  Future<Map<String, dynamic>> readingOverview();

  Future<Map<String, dynamic>> listBooks({int offset = 0, int limit = 20});

  Future<Map<String, dynamic>> readingStatistics({
    int days = 30,
    int offset = 0,
    int limit = 20,
  });

  Future<Map<String, dynamic>> readingSessions({
    int offset = 0,
    int limit = 20,
  });

  Future<Map<String, dynamic>> listSources({int offset = 0, int limit = 20});

  Future<Map<String, dynamic>> searchBooks({
    required String query,
    List<String> sourceIds = const [],
    int page = 1,
    int limit = 12,
  });

  SourcedBook? candidate(String id);

  Future<SourcedBook?> resolveRecommendation({
    required String sourceKey,
    required String title,
    required String author,
  });

  /// Starts a new Agent request and drops aliases from the previous request.
  void beginRequest();

  void cancel();

  void dispose();
}

class LocalReadingAgentDataSource implements ReadingAgentDataSource {
  LocalReadingAgentDataSource({
    BookDao? bookDao,
    ReadingStatsDao? readingStatsDao,
    BookSourceRegistry? sourceRegistry,
    BookSourceClient? client,
    BookSourceClient Function()? clientFactory,
    Duration? searchTimeout,
  }) : assert(client == null || clientFactory == null),
       _bookDao = bookDao ?? BookDao(),
       _readingStatsDao = readingStatsDao ?? ReadingStatsDao(),
       _sourceRegistry = sourceRegistry ?? BookSourceRegistry(),
       _client = client ?? clientFactory?.call() ?? BookSourceClient(),
       _ownsClient = client == null,
       _searchTimeout = searchTimeout ?? const Duration(seconds: 12);

  static const int _maxPageSize = 50;
  static const int _maxSearchSources = 4;
  static const int _maxSearchResults = 20;

  final BookDao _bookDao;
  final ReadingStatsDao _readingStatsDao;
  final BookSourceRegistry _sourceRegistry;
  final BookSourceClient _client;
  final bool _ownsClient;
  final Duration _searchTimeout;

  final Map<String, RegisteredBookSource> _sourcesByAlias = {};
  final Map<String, SourcedBook> _candidates = {};
  final Set<BookDownloadCancellation> _activeCancellations = {};
  int _generation = 0;
  bool _disposed = false;

  /// Public for existing recommendation navigation, while ownership remains
  /// with this data source only when it created the client itself.
  BookSourceClient get client => _client;

  @override
  void beginRequest() {
    _ensureActive();
    _resetRequestState();
  }

  @override
  Future<Map<String, dynamic>> readingOverview() async {
    _ensureActive();
    final results = await Future.wait<Object>([
      _readingStatsDao.getSummaryStats(),
      _readingStatsDao.getSessionSummary(),
      _readingStatsDao.getRecentBookIds(limit: 10),
    ]);
    final recentIds = results[2] as List<int>;
    final recentBooks = await _bookDao.getBooksByIds(recentIds);
    return {
      'asOf': _asOf(),
      'summary': _serializeSummary(results[0] as Map<String, int>),
      'sessions': _serializeSessionSummary(results[1] as Map<String, int>),
      'recentBooks': recentBooks.map(_serializeBook).toList(growable: false),
    };
  }

  @override
  Future<Map<String, dynamic>> listBooks({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureActive();
    final safeOffset = math.max(0, offset);
    final safeLimit = limit.clamp(1, _maxPageSize);
    final books = await _bookDao.getAllBooks();
    final end = math.min(books.length, safeOffset + safeLimit);
    final page = safeOffset >= books.length
        ? const <Book>[]
        : books.sublist(safeOffset, end);
    return {
      'asOf': _asOf(),
      'offset': safeOffset,
      'limit': safeLimit,
      'hasMore': end < books.length,
      'items': page.map(_serializeBook).toList(growable: false),
    };
  }

  @override
  Future<Map<String, dynamic>> readingStatistics({
    int days = 30,
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureActive();
    final safeDays = days.clamp(1, 365);
    final safeOffset = math.max(0, offset);
    final safeLimit = limit.clamp(1, _maxPageSize);
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: safeDays - 1));
    final results = await Future.wait<Object>([
      _readingStatsDao.getSummaryStats(),
      _readingStatsDao.getDailyStatsRange(start, now),
      _readingStatsDao.getHourlyReadingDistribution(days: safeDays),
      _readingStatsDao.getBookReadingStats(),
      _readingStatsDao.getSessionSummary(recentDays: safeDays),
    ]);
    final bookStats = results[3] as Map<int, Map<String, dynamic>>;
    final sortedBookStats = bookStats.entries.toList(growable: false)
      ..sort((left, right) {
        final byLastRead = _statInt(
          right.value,
          'lastReadMs',
        ).compareTo(_statInt(left.value, 'lastReadMs'));
        return byLastRead != 0 ? byLastRead : left.key.compareTo(right.key);
      });
    final bookEnd = math.min(sortedBookStats.length, safeOffset + safeLimit);
    final bookPage = safeOffset >= sortedBookStats.length
        ? const <MapEntry<int, Map<String, dynamic>>>[]
        : sortedBookStats.sublist(safeOffset, bookEnd);
    final daily = results[1] as List<Map<String, dynamic>>;
    final hourly = results[2] as Map<int, int>;
    return {
      'asOf': _asOf(),
      'days': safeDays,
      'dailyStatisticsScope': 'lastDays',
      'bookStatisticsScope': 'allTime',
      'summary': _serializeSummary(results[0] as Map<String, int>),
      'daily': daily.map(_serializeDailyStats).toList(growable: false),
      'hourlyMinutes': {
        for (var hour = 0; hour < 24; hour++) '$hour': hourly[hour] ?? 0,
      },
      'sessions': _serializeSessionSummary(results[4] as Map<String, int>),
      'booksOffset': safeOffset,
      'booksLimit': safeLimit,
      'booksTotal': sortedBookStats.length,
      'nextOffset': bookEnd < sortedBookStats.length ? bookEnd : null,
      'books': bookPage
          .map(
            (entry) => {
              'bookId': entry.key,
              ..._serializeBookStats(entry.value),
            },
          )
          .toList(growable: false),
    };
  }

  @override
  Future<Map<String, dynamic>> readingSessions({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureActive();
    final safeOffset = math.max(0, offset);
    final safeLimit = limit.clamp(1, _maxPageSize);
    final rows = await _readingStatsDao.getReadingSessions(
      offset: safeOffset,
      limit: safeLimit,
    );
    return {
      'asOf': _asOf(),
      'offset': safeOffset,
      'limit': safeLimit,
      'durationUnit': 'seconds',
      'recordUnit': 'dailySessionFragments',
      'hasMore': rows.length == safeLimit,
      'items': rows
          .map((row) {
            return <String, dynamic>{
              'date': row['date'],
              if (row['bookId'] is int) 'bookId': row['bookId'],
              'startTimeMs': row['startTimeMs'],
              'endTimeMs': row['endTimeMs'],
              'durationSeconds': row['durationInSeconds'],
              'pagesRead': row['pagesRead'],
            };
          })
          .toList(growable: false),
    };
  }

  @override
  Future<Map<String, dynamic>> listSources({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureActive();
    final safeOffset = math.max(0, offset);
    final safeLimit = limit.clamp(1, _maxPageSize);
    final generation = _generation;
    final sources = await _searchableSources();
    if (generation != _generation || _disposed) {
      return {
        'asOf': _asOf(),
        'offset': safeOffset,
        'limit': safeLimit,
        'stale': true,
        'hasMore': false,
        'items': const <Map<String, dynamic>>[],
      };
    }
    _refreshSourceAliases(sources);
    final end = math.min(sources.length, safeOffset + safeLimit);
    final page = safeOffset >= sources.length
        ? const <RegisteredBookSource>[]
        : sources.sublist(safeOffset, end);
    return {
      'asOf': _asOf(),
      'offset': safeOffset,
      'limit': safeLimit,
      'hasMore': end < sources.length,
      'items': page.map(_serializeSource).toList(growable: false),
    };
  }

  @override
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    List<String> sourceIds = const [],
    int page = 1,
    int limit = 12,
  }) async {
    _ensureActive();
    final normalizedQuery = query.trim();
    final safePage = math.max(1, page);
    final safeLimit = limit.clamp(1, _maxSearchResults);
    if (normalizedQuery.isEmpty) {
      return {
        'asOf': _asOf(),
        'page': safePage,
        'limit': safeLimit,
        'items': const <Map<String, dynamic>>[],
        'failures': const <Map<String, dynamic>>[],
      };
    }

    final generation = _generation;
    final available = await _searchableSources();
    if (generation != _generation || _disposed) {
      return _staleSearchResult(page: safePage, limit: safeLimit);
    }
    _refreshSourceAliases(available);
    final availableById = {for (final source in available) source.id: source};
    final selected = sourceIds.isEmpty
        ? available.take(_maxSearchSources).toList(growable: false)
        : _sourcesForAliases(sourceIds, availableById);
    final searchedAliases = selected
        .map(_aliasForSource)
        .toList(growable: false);

    final outcomes = await Future.wait(
      selected.map(
        (source) => _searchSource(
          source,
          _boundedText(normalizedQuery, 200),
          page: safePage,
          pageSize: safeLimit,
        ),
      ),
    );
    if (generation != _generation || _disposed) {
      return _staleSearchResult(page: safePage, limit: safeLimit);
    }

    final items = <Map<String, dynamic>>[];
    final failures = outcomes
        .where((outcome) => outcome.failure != null)
        .map(
          (outcome) => <String, dynamic>{
            'sourceId': _aliasForSource(outcome.source),
            'reason': outcome.failure,
          },
        )
        .toList(growable: false);
    final availableItems = outcomes.fold<int>(
      0,
      (count, outcome) => count + outcome.books.length,
    );
    for (final outcome in outcomes) {
      final sourceAlias = _aliasForSource(outcome.source);
      if (outcome.failure != null) continue;
      for (final book in outcome.books) {
        if (items.length >= safeLimit) break;
        final candidateId = 'c${_candidates.length + 1}';
        _candidates[candidateId] = SourcedBook(
          source: outcome.source,
          book: book,
        );
        items.add({
          'candidateId': candidateId,
          'sourceId': sourceAlias,
          'title': _boundedText(book.title, 200),
          'author': _boundedText(book.author, 200),
          'description': _boundedText(book.description, 1600),
          'categories': book.categories
              .take(20)
              .map((category) => _boundedText(category, 80))
              .toList(growable: false),
          if (book.status?.isNotEmpty == true)
            'status': _boundedText(book.status!, 80),
          if (book.latestChapter?.isNotEmpty == true)
            'latestChapter': _boundedText(book.latestChapter!, 200),
        });
      }
      if (items.length >= safeLimit) break;
    }
    return {
      'asOf': _asOf(),
      'page': safePage,
      'limit': safeLimit,
      'searchedSourceIds': searchedAliases,
      'sourcesSearched': selected.length,
      'sourcesAvailable': available.length,
      'sourceCoverageComplete': selected.length == available.length,
      'resultsAvailable': availableItems,
      'hasMore':
          availableItems > safeLimit ||
          outcomes.any((outcome) => outcome.hasMore) ||
          selected.length < available.length,
      'items': items,
      'failures': failures,
    };
  }

  @override
  Future<SourcedBook?> resolveRecommendation({
    required String sourceKey,
    required String title,
    required String author,
  }) async {
    _ensureActive();
    final normalizedTitle = title.trim();
    final normalizedAuthor = author.trim();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sourceKey) ||
        normalizedTitle.isEmpty ||
        normalizedTitle.runes.length > 200 ||
        normalizedAuthor.runes.length > 200) {
      return null;
    }
    final generation = _generation;
    final sources = await _searchableSources();
    if (generation != _generation || _disposed) return null;
    final matches = sources
        .where((source) => _sourceKey(source.id) == sourceKey)
        .take(2)
        .toList(growable: false);
    if (matches.length != 1) return null;

    final source = matches.single;
    final outcome = await _searchSource(
      source,
      normalizedTitle,
      page: 1,
      pageSize: _maxSearchResults,
    );
    if (generation != _generation || _disposed || outcome.failure != null) {
      return null;
    }
    final exactMatches = outcome.books
        .where(
          (book) =>
              book.title.trim() == normalizedTitle &&
              book.author.trim() == normalizedAuthor,
        )
        .take(2)
        .toList(growable: false);
    if (exactMatches.length != 1) return null;
    return SourcedBook(source: source, book: exactMatches.single);
  }

  Future<_SearchOutcome> _searchSource(
    RegisteredBookSource source,
    String query, {
    required int page,
    required int pageSize,
  }) async {
    final cancellation = BookDownloadCancellation();
    _activeCancellations.add(cancellation);
    try {
      final result = await _client
          .search(
            source,
            query,
            page: page,
            pageSize: pageSize,
            cancellation: cancellation,
          )
          .timeout(
            _searchTimeout,
            onTimeout: () {
              cancellation.cancel();
              throw TimeoutException('Book source search timed out.');
            },
          );
      return _SearchOutcome(
        source: source,
        books: result.items,
        hasMore: result.hasMore,
      );
    } on TimeoutException {
      return _SearchOutcome(source: source, failure: 'timeout');
    } on BookDownloadCancelledException {
      return _SearchOutcome(source: source, failure: 'cancelled');
    } catch (_) {
      return _SearchOutcome(source: source, failure: 'search_failed');
    } finally {
      _activeCancellations.remove(cancellation);
    }
  }

  Future<List<RegisteredBookSource>> _searchableSources() async {
    final sources = await _sourceRegistry.loadRunnableInBackground();
    return sources
        .where(
          (source) => source.enabled && source.capabilities.contains('search'),
        )
        .toList(growable: false);
  }

  void _refreshSourceAliases(List<RegisteredBookSource> sources) {
    final aliasesBySourceId = <String, String>{
      for (final entry in _sourcesByAlias.entries) entry.value.id: entry.key,
    };
    for (final source in sources) {
      final existingAlias = aliasesBySourceId[source.id];
      if (existingAlias != null) {
        _sourcesByAlias[existingAlias] = source;
        continue;
      }
      final alias = 's${_sourcesByAlias.length + 1}';
      _sourcesByAlias[alias] = source;
      aliasesBySourceId[source.id] = alias;
    }
  }

  List<RegisteredBookSource> _sourcesForAliases(
    List<String> aliases,
    Map<String, RegisteredBookSource> availableById,
  ) {
    final selected = <RegisteredBookSource>[];
    final seenAliases = <String>{};
    for (final alias in aliases) {
      if (!seenAliases.add(alias)) continue;
      final aliased = _sourcesByAlias[alias];
      if (aliased == null) continue;
      final current = availableById[aliased.id];
      if (current == null) continue;
      selected.add(current);
      if (selected.length == _maxSearchSources) break;
    }
    return selected;
  }

  String _aliasForSource(RegisteredBookSource source) {
    for (final entry in _sourcesByAlias.entries) {
      if (entry.value.id == source.id) return entry.key;
    }
    final alias = 's${_sourcesByAlias.length + 1}';
    _sourcesByAlias[alias] = source;
    return alias;
  }

  Map<String, dynamic> _serializeBook(Book book) => {
    if (book.id != null) 'id': book.id,
    'title': _boundedText(book.title, 200),
    'author': _boundedText(book.author, 200),
    'format': book.format,
    'progress': book.progress,
  };

  Map<String, dynamic> _serializeSummary(Map<String, int> summary) => {
    'unit': 'seconds',
    'total': summary['total'] ?? 0,
    'today': summary['today'] ?? 0,
    'week': summary['week'] ?? 0,
  };

  Map<String, dynamic> _serializeSessionSummary(Map<String, int> summary) => {
    'durationUnit': 'minutes',
    'recordUnit': 'dailySessionFragments',
    'totalSessions': summary['totalSessions'] ?? 0,
    'totalMinutes': summary['totalMinutes'] ?? 0,
    'avgSessionMinutes': summary['avgSessionMinutes'] ?? 0,
    'maxSessionMinutes': summary['maxSessionMinutes'] ?? 0,
  };

  Map<String, dynamic> _serializeDailyStats(Map<String, dynamic> stats) => {
    'date': '${stats['date'] ?? ''}',
    'durationSeconds': (stats['duration'] as num?)?.toInt() ?? 0,
    'pagesRead': (stats['pages'] as num?)?.toInt() ?? 0,
    'booksRead': (stats['books_read'] as num?)?.toInt() ?? 0,
  };

  int _statInt(Map<String, dynamic> stats, String key) =>
      (stats[key] as num?)?.toInt() ?? 0;

  String _boundedText(String value, int maxLength) {
    final normalized = value.trim();
    return normalized.runes.length <= maxLength
        ? normalized
        : String.fromCharCodes(normalized.runes.take(maxLength));
  }

  Map<String, int> _serializeBookStats(Map<String, dynamic> stats) => {
    'durationSeconds': (stats['durationSeconds'] as num?)?.toInt() ?? 0,
    'durationMinutes': (stats['durationMinutes'] as num?)?.toInt() ?? 0,
    'pagesRead': (stats['pagesRead'] as num?)?.toInt() ?? 0,
    'sessionCount': (stats['sessionCount'] as num?)?.toInt() ?? 0,
    'lastReadMs': (stats['lastReadMs'] as num?)?.toInt() ?? 0,
  };

  Map<String, dynamic> _serializeSource(RegisteredBookSource source) => {
    'sourceId': _aliasForSource(source),
    'name': _boundedText(source.name, 200),
    'protocol': source.sourceProtocol.name,
    'capabilities': source.capabilities.toList()..sort(),
  };

  String _asOf() => DateTime.now().toUtc().toIso8601String();

  String _sourceKey(String sourceId) =>
      sha256.convert(utf8.encode(sourceId)).toString();

  Map<String, dynamic> _staleSearchResult({
    required int page,
    required int limit,
  }) => {
    'asOf': _asOf(),
    'page': page,
    'limit': limit,
    'stale': true,
    'searchedSourceIds': const <String>[],
    'sourcesSearched': 0,
    'items': const <Map<String, dynamic>>[],
    'failures': const <Map<String, dynamic>>[],
  };

  @override
  SourcedBook? candidate(String id) => _candidates[id];

  @override
  void cancel() {
    if (_disposed) return;
    _cancelInflight();
  }

  void _resetRequestState() {
    _cancelInflight();
    _sourcesByAlias.clear();
    _candidates.clear();
  }

  void _cancelInflight() {
    _generation++;
    for (final cancellation in _activeCancellations.toList(growable: false)) {
      cancellation.cancel();
    }
    _activeCancellations.clear();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _resetRequestState();
    _disposed = true;
    if (_ownsClient) _client.close();
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('ReadingAgentDataSource has been disposed.');
    }
  }
}

class _SearchOutcome {
  const _SearchOutcome({
    required this.source,
    this.books = const [],
    this.failure,
    this.hasMore = false,
  });

  final RegisteredBookSource source;
  final List<BookSourceBook> books;
  final String? failure;
  final bool hasMore;
}
