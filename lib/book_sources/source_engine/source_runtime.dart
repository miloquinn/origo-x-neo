import '../models/registered_book_source.dart';
import '../protocol/book_source_protocol.dart';
import '../services/book_download_cancellation.dart';
import 'source_concurrency_limiter.dart';
import 'source_browser_session.dart';
import 'source_debug.dart';
import 'source_http_transport.dart';
import 'source_html_runtime.dart';
import 'source_interaction_coordinator.dart';
import 'source_login_session.dart';
import 'source_login_ui.dart';
import 'rules/source_rule_engine.dart';
import 'source_runtime_catalog.dart';
import 'source_runtime_chapter_actions.dart';
import 'source_runtime_dependencies.dart';
import 'source_runtime_login.dart';
import 'source_runtime_reading.dart';
import 'source_runtime_requests.dart';
import 'source_runtime_rules.dart';
import 'source_runtime_state.dart';
import 'scripting/source_script_contract.dart';
import 'source_transport.dart';

class SourceRuntime {
  SourceRuntime({
    SourceTransport? transport,
    SourceScriptEvaluator? scriptEvaluator,
    SourceLoginSessionStore? loginSessionStore,
    SourceConcurrencyLimiter? concurrencyLimiter,
    SourceDebugRecorder? debugRecorder,
    SourceInteractionCoordinatorPort? interactionCoordinator,
    SourceRuntimeState? state,
    SourceBrowserSessionClient browserClient =
        const SourceBrowserSessionClient(),
  }) : _transport =
           transport ?? SourceHttpTransport(browserClient: browserClient),
       _debugRecorder = debugRecorder {
    final interactionTransport = switch (_transport) {
      final SourceInteractionTransport value => value,
      _ => null,
    };
    final cookieTransport = switch (_transport) {
      final SourceCookieTransport value => value,
      _ => null,
    };
    _trace = SourceRuntimeTrace(debugRecorder);
    _scripts = SourceRuntimeScriptOwner(scriptEvaluator);
    _state = state ?? SourceRuntimeState();
    _sessions = SourceRuntimeSessionManager(
      loginSessionStore ?? SecureSourceLoginSessionStore(),
      cookieTransport,
    );
    _rules = SourceRuntimeRules(
      SourceRuleEngine(scriptEvaluatorProvider: () => _scripts.evaluator),
    );
    _requests = SourceRuntimeRequests(
      transport: _transport,
      limiter: concurrencyLimiter ?? SourceConcurrencyLimiter(),
      sessions: _sessions,
      rules: _rules,
      state: _state,
      trace: _trace,
      scripts: () => _scripts.evaluator,
      interactionCoordinator:
          interactionCoordinator ?? SourceInteractionCoordinator.instance,
      interactionTransport: interactionTransport,
    );
    _login = SourceRuntimeLogin(
      sessions: _sessions,
      contexts: _requests,
      browser: browserClient,
      scripts: () => _scripts.evaluator,
    );
    _html = SourceHtmlRuntime(
      scripts: () => _scripts.evaluator,
      contexts: _requests,
      sessions: _sessions,
    );
    _catalog = SourceRuntimeCatalog(
      requests: _requests,
      rules: _rules,
      state: _state,
      sessions: _sessions,
    );
    _reading = SourceRuntimeReading(
      requests: _requests,
      rules: _rules,
      state: _state,
      sessions: _sessions,
    );
    _chapterActions = SourceRuntimeChapterActions(
      _requests,
      _rules,
      _state,
      _sessions,
      () => _scripts.evaluator,
    );
  }

  final SourceTransport _transport;
  late final SourceRuntimeTrace _trace;
  late final SourceRuntimeScriptOwner _scripts;
  late final SourceRuntimeState _state;
  late final SourceRuntimeSessionPort _sessions;
  late final SourceRuntimeRulePort _rules;
  late final SourceRuntimeRequests _requests;
  late final SourceRuntimeLogin _login;
  late final SourceHtmlRuntime _html;
  late final SourceRuntimeCatalog _catalog;
  late final SourceRuntimeReading _reading;
  late final SourceRuntimeChapterActions _chapterActions;
  SourceDebugRecorder? _debugRecorder;
  bool _closed = false;

  /// When set, traces every request and flow stage made through this
  /// runtime. Meant for a single dedicated runtime driving one debug
  /// session — a shared, long-lived runtime should never have one attached,
  /// since concurrent unrelated calls would interleave in its trace.
  SourceDebugRecorder? get debugRecorder => _debugRecorder;
  set debugRecorder(SourceDebugRecorder? value) {
    _debugRecorder = value;
    _trace.recorder = value;
  }

  void close({bool force = true}) {
    if (_closed) return;
    _closed = true;
    _state.clear();
    _html.clear();
    _sessions.clearMemory();
    _scripts.close();
    final transport = _transport;
    if (transport case final SourceClosableTransport closable) {
      closable.close(force: force);
    }
  }

  Future<T> _whileOpen<T>(Future<T> Function() action) {
    if (_closed) {
      return Future<T>.error(StateError('The source runtime is closed.'));
    }
    return action();
  }

  bool hasReadingCatalogState(
    RegisteredBookSource registered,
    String bookId,
    String identity, {
    String? chapterId,
  }) {
    if (_closed) return false;
    try {
      return _state.hasCatalogIdentity(
        sourceFromRegistered(registered),
        bookId,
        identity,
        chapterId: chapterId,
      );
    } on FormatException {
      return _state.hasExternalCatalogIdentity(registered.id, bookId, identity);
    }
  }

  void rememberReadingCatalogIdentity(
    RegisteredBookSource registered,
    String bookId,
    String identity,
  ) {
    if (_closed) return;
    try {
      _state.rememberCatalogIdentity(
        sourceFromRegistered(registered),
        bookId,
        identity,
      );
    } on FormatException {
      _state.rememberExternalCatalogIdentity(registered.id, bookId, identity);
    }
  }

  Future<BookSourceSearchPage> search(
    RegisteredBookSource registered,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _trace.stage(
      'search',
      () => _html.handles(registered)
          ? _html.search(
              registered,
              query,
              page: page,
              pageSize: pageSize,
              cancellation: cancellation,
            )
          : _catalog.search(
              registered,
              query,
              page: page,
              pageSize: pageSize,
              cancellation: cancellation,
            ),
      describe: (page) => '${page.items.length} result(s)',
    ),
  );

  Future<List<BookSourceCategory>> getExploreCategories(
    RegisteredBookSource registered, {
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _catalog.getExploreCategories(registered, cancellation: cancellation),
  );

  Future<BookSourceSearchPage> browse(
    RegisteredBookSource registered, {
    required String? category,
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _trace.stage(
      'explore',
      () => _catalog.browse(
        registered,
        category: category,
        page: page,
        pageSize: pageSize,
        cancellation: cancellation,
      ),
      describe: (page) => '${page.items.length} result(s)',
    ),
  );

  Future<BookSourceBook> getBook(
    RegisteredBookSource registered,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _trace.stage(
      'info',
      () => _html.handles(registered)
          ? _html.getBook(registered, bookId, cancellation: cancellation)
          : _catalog.getBook(
              registered,
              bookId,
              sourceVariables: sourceVariables,
              cancellation: cancellation,
            ),
      describe: (book) =>
          '"${book.title}" by ${book.author.isEmpty ? 'unknown author' : book.author}',
    ),
  );

  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource registered,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    int? maxChapters,
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _trace.stage(
      'toc',
      () => _html.handles(registered)
          ? _html.getChapters(
              registered,
              bookId,
              maxChapters: maxChapters,
              cancellation: cancellation,
            )
          : _reading.getChapters(
              registered,
              bookId,
              sourceVariables: sourceVariables,
              maxChapters: maxChapters,
              cancellation: cancellation,
            ),
      describe: (chapters) => '${chapters.length} chapter(s)',
    ),
  );

  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource registered, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) => _whileOpen(
    () => _trace.stage(
      'content',
      () => _html.handles(registered)
          ? _html.getChapterContent(
              registered,
              bookId: bookId,
              chapterId: chapterId,
              cancellation: cancellation,
            )
          : _reading.getChapterContent(
              registered,
              bookId: bookId,
              chapterId: chapterId,
              sourceVariables: sourceVariables,
              cancellation: cancellation,
            ),
      describe: (content) => '${content.content.length} character(s)',
    ),
  );

  Future<String> executeChapterAction(
    RegisteredBookSource registered, {
    required String bookId,
    required String chapterId,
    required String script,
    required String result,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
    Future<SourceScriptInteractionResult> Function(
      SourceScriptInteractionRequest request,
    )?
    interactionHandler,
  }) => _whileOpen(
    () => _trace.stage(
      'chapterAction',
      () => _chapterActions.execute(
        registered,
        bookId: bookId,
        chapterId: chapterId,
        script: script,
        result: result,
        sourceVariables: sourceVariables,
        cancellation: cancellation,
        interactionHandler: interactionHandler,
      ),
    ),
  );

  Future<void> saveLoginSession(
    RegisteredBookSource registered, {
    Map<String, String> loginInfo = const {},
    Map<String, String> loginHeaders = const {},
  }) async {
    if (_closed) throw StateError('The source runtime is closed.');
    final source = sourceFromRegistered(registered);
    try {
      await _login.saveLoginSession(
        registered,
        loginInfo: loginInfo,
        loginHeaders: loginHeaders,
      );
    } finally {
      _state.clearSource(source);
      _html.clearSource(source);
    }
  }

  Future<void> clearLoginSession(RegisteredBookSource registered) async {
    if (_closed) throw StateError('The source runtime is closed.');
    final source = sourceFromRegistered(registered);
    try {
      await _login.clearLoginSession(registered);
    } finally {
      _state.clearSource(source);
      _html.clearSource(source);
    }
  }

  Future<List<SourceLoginField>> loadLoginFields(
    RegisteredBookSource registered,
  ) => _whileOpen(() => _login.loadLoginFields(registered));

  Future<String?> login(
    RegisteredBookSource registered,
    Map<String, String> values, {
    String? action,
  }) async {
    if (_closed) throw StateError('The source runtime is closed.');
    final source = sourceFromRegistered(registered);
    try {
      return await _login.login(registered, values, action: action);
    } finally {
      // Login persists the submitted session before running the source script,
      // which can also mutate cookies before throwing. Either outcome changes
      // the authentication context of remembered source responses.
      _state.clearSource(source);
      _html.clearSource(source);
    }
  }
}
