import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/core/advanced_feature_access.dart';
import '../../models/registered_book_source.dart';
import '../../services/book_download_cancellation.dart';
import '../../caching/book_source_chapter_cache.dart';
import '../../source_engine/source_login_ui.dart';
import '../../source_engine/source_runtime.dart';
import '../book_source_protocol.dart';

abstract interface class ReadingSourceBackendPort {
  Future<List<SourceLoginField>> loadLoginFields(RegisteredBookSource source);
  Future<String?> loginSource(
    RegisteredBookSource source,
    Map<String, String> values, {
    String? action,
  });
  Future<void> clearSourceLogin(RegisteredBookSource source);
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  });
  Future<List<BookSourceCategory>> getCategories(RegisteredBookSource source);
  Future<BookSourceSearchPage> browse(
    RegisteredBookSource source, {
    String? category,
    int page = 1,
    int pageSize = 20,
  });
  Future<BookSourceBook> getBook(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  });
  Future<BookSourceBook> getBookForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<List<BookSourceChapter>> getChaptersForDownload(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<List<BookSourceChapter>> getChaptersForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<BookSourceChapterContent> getChapterContentForDownload(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
  Future<BookSourceChapterContent> getChapterContentForValidation(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  });
}

class ReadingSourceBackend implements ReadingSourceBackendPort {
  ReadingSourceBackend(
    this._runtime, {
    this._chapterCache = const BookSourceChapterCache(),
    Future<bool> Function()? additionalProtocolsEnabled,
  }) : _additionalProtocolsEnabled =
           additionalProtocolsEnabled ??
           AdvancedFeatureAccess.additionalProtocolsEnabled;

  static const _cacheAuthRevisionPrefix =
      'reading_source_chapter_cache_auth_revision_v1:';
  static const _readerContextVariableKeys = {
    'chapterIndex',
    'chapterTitle',
    'bookName',
    'bookAuthor',
    'bookType',
  };
  // Bump when rule semantics change so persisted catalogs and content are
  // reparsed. Revision 6 prevents content parsed without its catalog/runtime
  // state from reusing a body that may have crossed a chapter boundary.
  static const _ruleEngineRevision = 7;

  final SourceRuntime Function() _runtime;
  final BookSourceChapterCache _chapterCache;
  final Future<bool> Function() _additionalProtocolsEnabled;
  final Map<String, int> _cacheAuthRevisions = {};
  final Expando<Map<String, _RuntimeCatalogFlight>>
  _runtimeCatalogInitializations = Expando();

  @override
  Future<List<SourceLoginField>> loadLoginFields(
    RegisteredBookSource source,
  ) async {
    await _ensureEnabled();
    return _runtime().loadLoginFields(source);
  }

  @override
  Future<String?> loginSource(
    RegisteredBookSource source,
    Map<String, String> values, {
    String? action,
  }) async {
    await _ensureEnabled();
    try {
      return await _runtime().login(source, values, action: action);
    } finally {
      // The runtime saves login data before executing the source script, so a
      // thrown script can still leave a different session or cookie state.
      // This helper absorbs persistence failures and preserves login errors.
      await _bumpCacheAuthRevision(source.id);
    }
  }

  @override
  Future<void> clearSourceLogin(RegisteredBookSource source) async {
    await _ensureEnabled();
    try {
      await _runtime().clearLoginSession(source);
    } finally {
      await _bumpCacheAuthRevision(source.id);
    }
  }

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    await _ensureEnabled();
    return _runtime().search(
      source,
      query,
      page: page,
      pageSize: pageSize,
      cancellation: cancellation,
    );
  }

  @override
  Future<List<BookSourceCategory>> getCategories(
    RegisteredBookSource source,
  ) async {
    await _ensureEnabled();
    return _runtime().getExploreCategories(source);
  }

  @override
  Future<BookSourceSearchPage> browse(
    RegisteredBookSource source, {
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    await _ensureEnabled();
    return _runtime().browse(
      source,
      category: category,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<BookSourceBook> getBook(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async {
    await _ensureEnabled();
    return _runtime().getBook(source, bookId, sourceVariables: sourceVariables);
  }

  @override
  Future<BookSourceBook> getBookForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    await _ensureEnabled();
    return _runtime().getBook(
      source,
      bookId,
      sourceVariables: sourceVariables,
      cancellation: cancellation,
    );
  }

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final chapters = await _chapterCache.getChapterCatalogOrLoad(
      sourceId: source.id,
      sourceRevision: sourceRevision,
      bookId: bookId,
      requestScope: cancellation ?? #interactive,
      loader: () {
        final runtime = _runtime();
        return _refreshRuntimeCatalog(
          runtime,
          source,
          bookId,
          sourceRevision: catalogIdentity.revision,
          sourceVariables: catalogIdentity.variables,
          cancellation: cancellation,
        );
      },
    );
    cancellation?.throwIfCancelled();
    return chapters;
  }

  @override
  Future<List<BookSourceChapter>> getChaptersForDownload(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final chapters = await _chapterCache.getChapterCatalogOrLoad(
      sourceId: source.id,
      sourceRevision: sourceRevision,
      bookId: bookId,
      refreshAfter: Duration.zero,
      staleWhileRevalidate: false,
      requestScope: cancellation ?? #download,
      loader: () {
        final runtime = _runtime();
        return _refreshRuntimeCatalog(
          runtime,
          source,
          bookId,
          sourceRevision: catalogIdentity.revision,
          sourceVariables: catalogIdentity.variables,
          cancellation: cancellation,
        );
      },
    );
    cancellation?.throwIfCancelled();
    return chapters;
  }

  @override
  Future<List<BookSourceChapter>> getChaptersForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final runtime = _runtime();
    return _refreshRuntimeCatalog(
      runtime,
      source,
      bookId,
      sourceRevision: catalogIdentity.revision,
      sourceVariables: catalogIdentity.variables,
      cancellation: cancellation,
    );
  }

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final content = await _chapterCache.getOrLoad(
      sourceId: source.id,
      sourceRevision: sourceRevision,
      bookId: bookId,
      chapterId: chapterId,
      requestScope: cancellation ?? #interactiveChapterContent,
      loader: () {
        final runtime = _runtime();
        return _loadRuntimeChapterContent(
          runtime,
          source,
          bookId: bookId,
          chapterId: chapterId,
          catalogRevision: catalogIdentity.revision,
          catalogVariables: catalogIdentity.variables,
          sourceVariables: sourceVariables,
          cancellation: cancellation,
        );
      },
    );
    cancellation?.throwIfCancelled();
    return content;
  }

  @override
  Future<BookSourceChapterContent> getChapterContentForDownload(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final content = await _chapterCache.getOrLoad(
      sourceId: source.id,
      sourceRevision: sourceRevision,
      bookId: bookId,
      chapterId: chapterId,
      staleWhileRevalidate: false,
      requestScope: cancellation ?? #downloadChapterContent,
      loader: () {
        final runtime = _runtime();
        return _loadRuntimeChapterContent(
          runtime,
          source,
          bookId: bookId,
          chapterId: chapterId,
          catalogRevision: catalogIdentity.revision,
          catalogVariables: catalogIdentity.variables,
          sourceVariables: sourceVariables,
          cancellation: cancellation,
        );
      },
    );
    cancellation?.throwIfCancelled();
    return content;
  }

  @override
  Future<BookSourceChapterContent> getChapterContentForValidation(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    await _ensureEnabled();
    final sourceRevision = await _cacheRevision(source, sourceVariables);
    final catalogIdentity = await _runtimeCatalogIdentity(
      source,
      sourceVariables,
      sourceRevision: sourceRevision,
    );
    final runtime = _runtime();
    return _loadRuntimeChapterContent(
      runtime,
      source,
      bookId: bookId,
      chapterId: chapterId,
      catalogRevision: catalogIdentity.revision,
      catalogVariables: catalogIdentity.variables,
      sourceVariables: sourceVariables,
      cancellation: cancellation,
    );
  }

  Future<BookSourceChapterContent> _loadRuntimeChapterContent(
    SourceRuntime runtime,
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    required String catalogRevision,
    required Map<String, String> catalogVariables,
    required Map<String, String> sourceVariables,
    BookDownloadCancellation? cancellation,
  }) async {
    await _ensureRuntimeCatalog(
      runtime,
      source,
      bookId,
      chapterId: chapterId,
      sourceRevision: catalogRevision,
      sourceVariables: catalogVariables,
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    final content = await runtime.getChapterContent(
      source,
      bookId: bookId,
      chapterId: chapterId,
      sourceVariables: sourceVariables,
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    return content;
  }

  Future<void> _ensureRuntimeCatalog(
    SourceRuntime runtime,
    RegisteredBookSource source,
    String bookId, {
    required String chapterId,
    required String sourceRevision,
    required Map<String, String> sourceVariables,
    BookDownloadCancellation? cancellation,
  }) {
    final flights = _runtimeCatalogInitializations[runtime] ??=
        <String, _RuntimeCatalogFlight>{};
    final key = '${source.id}\u0000$bookId';
    final existing = flights[key];
    if (existing != null &&
        existing.revision == sourceRevision &&
        !existing.cancellation.isCancelled) {
      return _waitForRuntimeCatalog(existing.future, existing, cancellation);
    }
    if (existing == null &&
        runtime.hasReadingCatalogState(
          source,
          bookId,
          sourceRevision,
          chapterId: chapterId,
        )) {
      cancellation?.throwIfCancelled();
      return Future<void>.value();
    }
    final queued = _queueRuntimeCatalog(
      flights,
      key,
      runtime,
      source,
      bookId,
      sourceRevision: sourceRevision,
      sourceVariables: sourceVariables,
    );
    return _waitForRuntimeCatalog(
      queued.future.then<void>((_) {}),
      queued.flight,
      cancellation,
    );
  }

  Future<List<BookSourceChapter>> _refreshRuntimeCatalog(
    SourceRuntime runtime,
    RegisteredBookSource source,
    String bookId, {
    required String sourceRevision,
    required Map<String, String> sourceVariables,
    BookDownloadCancellation? cancellation,
  }) {
    final flights = _runtimeCatalogInitializations[runtime] ??=
        <String, _RuntimeCatalogFlight>{};
    final key = '${source.id}\u0000$bookId';
    final queued = _queueRuntimeCatalog(
      flights,
      key,
      runtime,
      source,
      bookId,
      sourceRevision: sourceRevision,
      sourceVariables: sourceVariables,
    );
    return _waitForRuntimeCatalog(queued.future, queued.flight, cancellation);
  }

  ({Future<List<BookSourceChapter>> future, _RuntimeCatalogFlight flight})
  _queueRuntimeCatalog(
    Map<String, _RuntimeCatalogFlight> flights,
    String key,
    SourceRuntime runtime,
    RegisteredBookSource source,
    String bookId, {
    required String sourceRevision,
    required Map<String, String> sourceVariables,
  }) {
    final previous = flights[key]?.future;
    final internalCancellation = BookDownloadCancellation();
    final attempt = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {
          // A newer initialization remains useful after an earlier failure.
        }
      }
      internalCancellation.throwIfCancelled();
      final chapters = await runtime.getChapters(
        source,
        bookId,
        sourceVariables: sourceVariables,
        cancellation: internalCancellation,
      );
      internalCancellation.throwIfCancelled();
      runtime.rememberReadingCatalogIdentity(source, bookId, sourceRevision);
      return chapters;
    }();
    final completion = attempt.then<void>((_) {});
    final flight = _RuntimeCatalogFlight(
      sourceRevision,
      completion,
      internalCancellation,
    );
    flights[key] = flight;
    unawaited(
      completion.then<void>(
        (_) {
          if (identical(flights[key], flight)) flights.remove(key);
        },
        onError: (Object _, StackTrace _) {
          if (identical(flights[key], flight)) flights.remove(key);
        },
      ),
    );
    return (future: attempt, flight: flight);
  }

  Future<T> _waitForRuntimeCatalog<T>(
    Future<T> catalog,
    _RuntimeCatalogFlight flight,
    BookDownloadCancellation? cancellation,
  ) async {
    cancellation?.throwIfCancelled();
    flight.addWaiter();
    try {
      if (cancellation == null) return await catalog;
      return await Future.any<T>([
        catalog,
        cancellation.whenCancelled.then<T>(
          (_) => throw const BookDownloadCancelledException(),
        ),
      ]);
    } finally {
      flight.removeWaiter();
    }
  }

  Future<({String revision, Map<String, String> variables})>
  _runtimeCatalogIdentity(
    RegisteredBookSource source,
    Map<String, String> sourceVariables, {
    required String sourceRevision,
  }) async {
    if (!sourceVariables.keys.any(_readerContextVariableKeys.contains)) {
      return (revision: sourceRevision, variables: sourceVariables);
    }
    final variables = <String, String>{
      for (final entry in sourceVariables.entries)
        if (!_readerContextVariableKeys.contains(entry.key))
          entry.key: entry.value,
    };
    return (
      revision: await _cacheRevision(source, variables),
      variables: variables,
    );
  }

  Future<String> _cacheRevision(
    RegisteredBookSource source,
    Map<String, String> sourceVariables,
  ) async {
    final authRevision = await _cacheAuthRevision(source.id);
    final stable = _stableCacheJson({
      'ruleEngineRevision': _ruleEngineRevision,
      'manifestUrl': source.manifestUrl.toString(),
      'apiBaseUrl': source.apiBaseUrl.toString(),
      'protocolVersion': source.protocolVersion,
      'sourceConfig': source.sourceConfig,
      'sourceVariables': sourceVariables,
      'authRevision': authRevision,
    });
    return sha256.convert(utf8.encode(jsonEncode(stable))).toString();
  }

  Future<int> _cacheAuthRevision(String sourceId) async {
    final remembered = _cacheAuthRevisions[sourceId];
    if (remembered != null) return remembered;
    final preferences = await SharedPreferences.getInstance();
    final revision =
        preferences.getInt('$_cacheAuthRevisionPrefix$sourceId') ?? 0;
    _cacheAuthRevisions[sourceId] = revision;
    return revision;
  }

  Future<void> _bumpCacheAuthRevision(String sourceId) async {
    final revision = DateTime.now().microsecondsSinceEpoch;
    _cacheAuthRevisions[sourceId] = revision;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('$_cacheAuthRevisionPrefix$sourceId', revision);
    } catch (_) {
      // A cache invalidation failure must not turn a successful login into an
      // apparent authentication failure. This runtime still uses the new key.
    }
  }

  Future<void> _ensureEnabled() async {
    if (!await _additionalProtocolsEnabled()) {
      throw const BookSourceProtocolException(
        'This source is unavailable for the current account or settings.',
      );
    }
  }
}

Object? _stableCacheJson(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
    return <String, Object?>{
      for (final entry in entries)
        '${entry.key}': _stableCacheJson(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_stableCacheJson).toList(growable: false);
  }
  return value;
}

class _RuntimeCatalogFlight {
  _RuntimeCatalogFlight(this.revision, this.future, this.cancellation);

  final String revision;
  final Future<void> future;
  final BookDownloadCancellation cancellation;
  int _waiters = 0;

  void addWaiter() => _waiters++;

  void removeWaiter() {
    assert(_waiters > 0);
    _waiters--;
    if (_waiters == 0) cancellation.cancel();
  }
}
