import 'source_config.dart';
import 'source_response.dart';

class SourceRuntimeState {
  SourceRuntimeState({
    this.maxRememberedBookStates = 1024,
    this.maxChapters = 30000,
  });

  final int maxRememberedBookStates;
  final int maxChapters;

  final Map<String, Map<String, Object?>> _bookRuleStates = {};
  final Map<String, Map<String, Object?>> _bookEntityContexts = {};
  final Map<String, Map<String, Object?>> _chapterRuleContexts = {};
  final Map<String, SourceResponse> _bookInfoResponses = {};
  final Map<String, _CatalogRuntimeState> _catalogRuntimeStates = {};

  Map<String, Object?> ruleStateFor(
    ReadingSourceConfig source,
    String bookId,
    Map<String, String> sourceVariables,
  ) => <String, Object?>{
    ...?_bookRuleStates[bookKey(source, bookId)],
    ...sourceVariables,
  };

  void rememberRuleState(
    ReadingSourceConfig source,
    String bookId,
    Map<String, Object?> state,
  ) {
    if (bookId.trim().isEmpty || state.isEmpty) return;
    _rememberBounded(
      _bookRuleStates,
      bookKey(source, bookId),
      Map<String, Object?>.from(state),
      maxRememberedBookStates,
    );
  }

  Map<String, Object?> bookContext(
    ReadingSourceConfig source,
    String bookId,
    Map<String, Object?> state, {
    required int bookType,
  }) {
    final context = <String, Object?>{
      ...?_bookEntityContexts[bookKey(source, bookId)],
      ...state,
    };
    context['bookUrl'] = bookId;
    context['name'] ??= state['bookName'];
    context['author'] ??= state['bookAuthor'];
    context['type'] =
        int.tryParse('${state['bookType'] ?? ''}') ??
        context['type'] ??
        bookType;
    context['durChapterIndex'] ??= 0;
    context['durChapterTitle'] ??= '';
    return context;
  }

  void rememberBookContext(
    ReadingSourceConfig source,
    String bookId,
    Map<String, Object?> context,
  ) => _rememberBounded(
    _bookEntityContexts,
    bookKey(source, bookId),
    Map<String, Object?>.from(context),
    maxRememberedBookStates,
  );

  Map<String, Object?> chapterContext(
    ReadingSourceConfig source,
    String bookId,
    String chapterId,
  ) => Map<String, Object?>.from(
    _chapterRuleContexts[chapterKey(source, bookId, chapterId)] ?? const {},
  );

  void rememberChapterContext(
    ReadingSourceConfig source,
    String bookId,
    String chapterId,
    Map<String, Object?> context,
  ) => _rememberBounded(
    _chapterRuleContexts,
    chapterKey(source, bookId, chapterId),
    Map<String, Object?>.from(context),
    maxChapters,
  );

  void rememberBookInfoResponse(
    ReadingSourceConfig source,
    String bookId,
    SourceResponse response,
  ) => _rememberBounded(
    _bookInfoResponses,
    bookKey(source, bookId),
    response,
    maxRememberedBookStates,
  );

  void rememberCatalogParsed(ReadingSourceConfig source, String bookId) {
    final key = bookKey(source, bookId);
    _rememberBounded(
      _catalogRuntimeStates,
      key,
      _CatalogRuntimeState(requiresRuleState: _bookRuleStates.containsKey(key)),
      maxRememberedBookStates,
    );
  }

  void rememberCatalogIdentity(
    ReadingSourceConfig source,
    String bookId,
    String identity,
  ) {
    final key = bookKey(source, bookId);
    final current = _catalogRuntimeStates[key];
    _rememberBounded(
      _catalogRuntimeStates,
      key,
      (current ?? const _CatalogRuntimeState(external: true)).copyWith(
        identity: identity,
      ),
      maxRememberedBookStates,
    );
  }

  bool hasCatalogIdentity(
    ReadingSourceConfig source,
    String bookId,
    String identity, {
    String? chapterId,
  }) {
    final key = bookKey(source, bookId);
    final catalog = _catalogRuntimeStates[key];
    if (catalog == null || catalog.identity != identity) return false;
    if (catalog.external) return true;
    if (!_bookEntityContexts.containsKey(key)) return false;
    if (catalog.requiresRuleState && !_bookRuleStates.containsKey(key)) {
      return false;
    }
    if (chapterId == null) return true;
    final chapter = _chapterRuleContexts[chapterKey(source, bookId, chapterId)];
    return chapter != null && chapter.containsKey('nextChapterUrl');
  }

  void rememberExternalCatalogIdentity(
    String sourceId,
    String bookId,
    String identity,
  ) => _rememberBounded(
    _catalogRuntimeStates,
    'external\u0000$sourceId\u0000$bookId',
    _CatalogRuntimeState(identity: identity, external: true),
    maxRememberedBookStates,
  );

  bool hasExternalCatalogIdentity(
    String sourceId,
    String bookId,
    String identity,
  ) =>
      _catalogRuntimeStates['external\u0000$sourceId\u0000$bookId']?.identity ==
      identity;

  SourceResponse? takeBookInfoResponse(
    ReadingSourceConfig source,
    String bookId,
  ) => _bookInfoResponses.remove(bookKey(source, bookId));

  String bookKey(ReadingSourceConfig source, String bookId) =>
      '${source.stableId}\u0000$bookId';

  String chapterKey(
    ReadingSourceConfig source,
    String bookId,
    String chapterId,
  ) => '${source.stableId}\u0000$bookId\u0000$chapterId';

  void clearSource(ReadingSourceConfig source) {
    final prefix = '${source.stableId}\u0000';
    _bookRuleStates.removeWhere((key, _) => key.startsWith(prefix));
    _bookEntityContexts.removeWhere((key, _) => key.startsWith(prefix));
    _chapterRuleContexts.removeWhere((key, _) => key.startsWith(prefix));
    _bookInfoResponses.removeWhere((key, _) => key.startsWith(prefix));
    _catalogRuntimeStates.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _bookRuleStates.clear();
    _bookEntityContexts.clear();
    _chapterRuleContexts.clear();
    _bookInfoResponses.clear();
    _catalogRuntimeStates.clear();
  }
}

class _CatalogRuntimeState {
  const _CatalogRuntimeState({
    this.identity,
    this.requiresRuleState = false,
    this.external = false,
  });

  final String? identity;
  final bool requiresRuleState;
  final bool external;

  _CatalogRuntimeState copyWith({String? identity}) => _CatalogRuntimeState(
    identity: identity ?? this.identity,
    requiresRuleState: requiresRuleState,
    external: external,
  );
}

void _rememberBounded<K, V>(Map<K, V> values, K key, V value, int limit) {
  values.remove(key);
  values[key] = value;
  while (values.length > limit) {
    values.remove(values.keys.first);
  }
}
