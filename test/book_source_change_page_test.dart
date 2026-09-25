import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_change_service.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/book_source_change_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('change page closes only a factory-created service', (
    tester,
  ) async {
    final ownedService = _CloseTrackingChangeService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: const [],
          currentSource: _oldSource,
          currentBook: _oldBook,
          serviceFactory: () => ownedService,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    expect(ownedService.closeCount, 1);

    final borrowedService = _CloseTrackingChangeService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: const [],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: borrowedService,
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(borrowedService.closeCount, 0);
    borrowedService.close();
  });

  testWidgets(
    'candidate must be validated before source switching is enabled',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      final service = _PageChangeService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceChangePage(
            sources: [_oldSource, _newSource],
            currentSource: _oldSource,
            currentBook: _oldBook,
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current source'), findsOneWidget);
      expect(find.text('New source'), findsOneWidget);
      expect(find.byKey(const Key('bookSourceChangeCommit')), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Current chapter readable'), findsOneWidget);
      final after = tester.widget<FilledButton>(
        find.byKey(const Key('bookSourceChangeCommit')),
      );
      expect(after.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'starts source search before current reading position finishes loading',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      final service = _DeferredPreparationService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceChangePage(
            sources: [_oldSource, _newSource],
            currentSource: _oldSource,
            currentBook: _oldBook,
            service: service,
          ),
        ),
      );

      expect(find.text('Finding other sources'), findsOneWidget);
      await tester.pump();
      await tester.pump();

      expect(service.searchCount, 1);
      expect(service.positionCompleted, isFalse);
      expect(find.text('Finding other sources'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.completePosition();
      service.completeSearch();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('candidate validation waits for deferred reading position', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _DeferredCandidateService();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pump();
    expect(service.validateCount, 0);

    service.completePosition();
    await tester.pumpAndSettle();

    expect(service.validateCount, 1);
    final commit = tester.widget<FilledButton>(
      find.byKey(const Key('bookSourceChangeCommit')),
    );
    expect(commit.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an author-matching candidate that arrives later moves above an earlier mismatch',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      final service = _CandidateOrderService();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceChangePage(
            sources: [_oldSource, _mismatchSource, _matchSource],
            currentSource: _oldSource,
            currentBook: _oldBook,
            service: service,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(
        find.byKey(const ValueKey('bookSourceChangeCandidate-mismatch-source')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('bookSourceChangeCandidate-match-source')),
        findsNothing,
      );

      service.releaseSecond();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('bookSourceChangeCandidate-match-source')),
        findsOneWidget,
      );
      final matchY = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('bookSourceChangeCandidate-match-source'),
            ),
          )
          .dy;
      final mismatchY = tester
          .getTopLeft(
            find.byKey(
              const ValueKey('bookSourceChangeCandidate-mismatch-source'),
            ),
          )
          .dy;
      expect(matchY, lessThan(mismatchY));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quick search pauses before scanning every source', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final client = _FastEmptyClient();
    final sources = <RegisteredBookSource>[
      _oldSource,
      for (var index = 0; index < 65; index++)
        _source('bulk-$index', 'Bulk $index'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: sources,
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: BookSourceChangeService(client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(client.searchCount, 60);
    expect(
      find.byKey(const Key('bookSourceChangeSearchRemaining')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('bookSourceChangeSearchRemaining')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(client.searchCount, 65);
    expect(
      find.byKey(const Key('bookSourceChangeSearchRemaining')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving confirmation ignores a late validation result', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _LateValidationService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pump();
    expect(find.byKey(const Key('bookSourceChangeCommit')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    service.release();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bookSourceChangeConfirmation')), findsNothing);
    expect(find.byKey(const Key('bookSourceChangeCommit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uncertain chapter mapping requires an explicit choice', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _ManualMappingService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceChangeCommit')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('bookSourceChangeChooseChapter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3. Chapter 3'));
    await tester.pumpAndSettle();
    expect(service.selectedChapterIndex, 2);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceChangeCommit')))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable old position still allows manual source change', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _UnavailablePositionService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('previous reading position'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceChangeCommit')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('bookSourceChangeChooseChapter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3. Chapter 3'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceChangeCommit')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('stopping search preserves candidates and restores controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _SlowSearchService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource, _matchSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('bookSourceChangeStopSearch')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('bookSourceChangeStopSearch')), findsNothing);
    expect(find.byKey(const Key('bookSourceChangeQuery')), findsOneWidget);
    service.release();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search action aligns with the search field on a phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final service = _SlowSearchService();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource, _matchSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: service,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final search = tester.getRect(
      find.byKey(const Key('bookSourceChangeQuery')),
    );
    final stop = tester.getRect(
      find.byKey(const Key('bookSourceChangeStopSearch')),
    );
    expect(stop.left, closeTo(search.left, 0.5));
    expect(stop.right, closeTo(search.right, 0.5));
    await tester.tap(find.byKey(const Key('bookSourceChangeStopSearch')));
    await tester.pump();
    final remaining = tester.getRect(
      find.byKey(const Key('bookSourceChangeSearchRemaining')),
    );
    expect(remaining.left, closeTo(search.left, 0.5));
    expect(remaining.right, closeTo(search.right, 0.5));
    service.release();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow large-text layout keeps search and confirmation usable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceChangePage(
            sources: [_oldSource, _newSource],
            currentSource: _oldSource,
            currentBook: _oldBook,
            service: _PageChangeService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const Key('bookSourceChangeQuery'))),
      ).scale(14),
      closeTo(21, 0.01),
    );
    expect(find.byKey(const Key('bookSourceChangeQuery')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bookSourceChangeCommit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation deadline offers a recoverable timeout state', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [_oldSource, _newSource],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: _TimeoutValidationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('bookSourceChangeCandidate-new-source')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('check timed out'), findsOneWidget);
    expect(find.byKey(const Key('bookSourceChangeRetryCheck')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceChangeCommit')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('three thousand sources keep the initial search bounded', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
    final client = _FastEmptyClient();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceChangePage(
          sources: [
            _oldSource,
            for (var index = 0; index < 3000; index++)
              _source('many-$index', 'Many $index'),
          ],
          currentSource: _oldSource,
          currentBook: _oldBook,
          service: BookSourceChangeService(client: client),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(client.searchCount, 60);
    expect(find.textContaining('3000 sources available'), findsOneWidget);
    expect(find.byKey(const Key('bookSourceChangeQuery')), findsOneWidget);
    expect(
      find.byKey(const Key('bookSourceChangeSearchRemaining')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

final _oldSource = _source('old-source', 'Old source');
final _newSource = _source('new-source', 'New source');
final _mismatchSource = _source('mismatch-source', 'Mismatch source');
final _matchSource = _source('match-source', 'Match source');

RegisteredBookSource _source(String id, String name) => RegisteredBookSource(
  id: id,
  name: name,
  description: '',
  manifestUrl: Uri.parse('https://$id.example/source.json'),
  apiBaseUrl: Uri.parse('https://$id.example/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'search', 'detail', 'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026, 8, 2),
);

const _oldBook = BookSourceBook(
  id: 'old-book',
  title: 'Test book',
  author: 'Author',
  description: '',
  categories: [],
);

const _newBook = BookSourceBook(
  id: 'new-book',
  title: 'Test book',
  author: 'Author',
  description: '',
  categories: [],
);

class _PageChangeService extends BookSourceChangeService {
  late final candidate = BookSourceChangeCandidate(
    source: _newSource,
    book: _newBook,
    authorMatches: true,
  );

  @override
  Future<BookSourceChangePosition> loadPosition({
    required RegisteredBookSource source,
    required BookSourceBook book,
    Book? shelfBook,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 8),
  }) async => const BookSourceChangePosition(
    chapterIndex: 4,
    chapterProgress: 0.5,
    chapterTitle: 'Chapter 5',
    chapterCount: 10,
  );

  @override
  Stream<BookSourceChangeSearchEvent> search({
    required Iterable<RegisteredBookSource> sources,
    required String title,
    required String author,
    required bool checkAuthor,
    String? currentSourceId,
    Set<String> excludedSourceIds = const {},
    int? sourceLimit,
    int? candidateLimit,
  }) async* {
    yield BookSourceChangeSearchEvent(
      source: _newSource,
      completed: 1,
      candidates: [candidate],
    );
  }

  @override
  Future<ValidatedBookSourceChange> validate({
    required BookSourceChangeCandidate candidate,
    required BookSourceChangePosition position,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 20),
    void Function(BookSourceChangeValidationStage stage)? onStage,
    int? selectedChapterIndex,
  }) async => ValidatedBookSourceChange(
    candidate: candidate,
    book: _newBook,
    chapters: List.generate(
      12,
      (index) => BookSourceChapter(
        id: 'chapter-$index',
        title: 'Chapter ${index + 1}',
        order: index,
      ),
    ),
    chapterIndex: 4,
    chapterProgress: 0.5,
    mappingConfidence: BookSourceChapterMappingConfidence.exactTitle,
    responseTime: const Duration(milliseconds: 240),
  );
}

class _CandidateOrderService extends BookSourceChangeService {
  final _second = Completer<void>();

  void releaseSecond() => _second.complete();

  @override
  Future<BookSourceChangePosition> loadPosition({
    required RegisteredBookSource source,
    required BookSourceBook book,
    Book? shelfBook,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 8),
  }) async => const BookSourceChangePosition(
    chapterIndex: 0,
    chapterProgress: 0,
    chapterTitle: '',
    chapterCount: 0,
  );

  @override
  Stream<BookSourceChangeSearchEvent> search({
    required Iterable<RegisteredBookSource> sources,
    required String title,
    required String author,
    required bool checkAuthor,
    String? currentSourceId,
    Set<String> excludedSourceIds = const {},
    int? sourceLimit,
    int? candidateLimit,
  }) async* {
    yield BookSourceChangeSearchEvent(
      source: _mismatchSource,
      completed: 1,
      candidates: [
        BookSourceChangeCandidate(
          source: _mismatchSource,
          book: const BookSourceBook(
            id: 'mismatch-book',
            title: 'Test book',
            author: 'A Different Author',
            description: '',
            categories: [],
          ),
          authorMatches: false,
        ),
      ],
    );
    await _second.future;
    yield BookSourceChangeSearchEvent(
      source: _matchSource,
      completed: 2,
      candidates: [
        BookSourceChangeCandidate(
          source: _matchSource,
          book: const BookSourceBook(
            id: 'match-book',
            title: 'Test book',
            author: 'Author',
            description: '',
            categories: [],
          ),
          authorMatches: true,
        ),
      ],
    );
  }
}

class _CloseTrackingChangeService extends _PageChangeService {
  int closeCount = 0;

  @override
  void close() {
    closeCount++;
    super.close();
  }
}

class _FastEmptyClient extends BookSourceClient {
  int searchCount = 0;

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    searchCount++;
    return BookSourceSearchPage(
      items: const [],
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async => const [
    BookSourceChapter(id: 'chapter-1', title: 'Chapter 1', order: 0),
  ];
}

class _DeferredPreparationService extends BookSourceChangeService {
  final Completer<BookSourceChangePosition> _position = Completer();
  final Completer<void> _search = Completer();
  int searchCount = 0;

  bool get positionCompleted => _position.isCompleted;

  void completePosition() {
    _position.complete(
      const BookSourceChangePosition(
        chapterIndex: 0,
        chapterProgress: 0,
        chapterTitle: 'Chapter 1',
        chapterCount: 1,
      ),
    );
  }

  void completeSearch() => _search.complete();

  @override
  Future<BookSourceChangePosition> loadPosition({
    required RegisteredBookSource source,
    required BookSourceBook book,
    Book? shelfBook,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 8),
  }) => _position.future;

  @override
  Stream<BookSourceChangeSearchEvent> search({
    required Iterable<RegisteredBookSource> sources,
    required String title,
    required String author,
    required bool checkAuthor,
    String? currentSourceId,
    Set<String> excludedSourceIds = const {},
    int? sourceLimit,
    int? candidateLimit,
  }) async* {
    searchCount++;
    await _search.future;
  }
}

class _DeferredCandidateService extends BookSourceChangeService {
  final Completer<BookSourceChangePosition> _position = Completer();
  int validateCount = 0;

  void completePosition() {
    _position.complete(
      const BookSourceChangePosition(
        chapterIndex: 4,
        chapterProgress: 0.5,
        chapterTitle: 'Chapter 5',
        chapterCount: 10,
      ),
    );
  }

  @override
  Future<BookSourceChangePosition> loadPosition({
    required RegisteredBookSource source,
    required BookSourceBook book,
    Book? shelfBook,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 8),
  }) => _position.future;

  @override
  Stream<BookSourceChangeSearchEvent> search({
    required Iterable<RegisteredBookSource> sources,
    required String title,
    required String author,
    required bool checkAuthor,
    String? currentSourceId,
    Set<String> excludedSourceIds = const {},
    int? sourceLimit,
    int? candidateLimit,
  }) async* {
    yield BookSourceChangeSearchEvent(
      source: _newSource,
      completed: 1,
      candidates: [
        BookSourceChangeCandidate(
          source: _newSource,
          book: _newBook,
          authorMatches: true,
        ),
      ],
    );
  }

  @override
  Future<ValidatedBookSourceChange> validate({
    required BookSourceChangeCandidate candidate,
    required BookSourceChangePosition position,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 20),
    void Function(BookSourceChangeValidationStage stage)? onStage,
    int? selectedChapterIndex,
  }) async {
    validateCount++;
    return ValidatedBookSourceChange(
      candidate: candidate,
      book: _newBook,
      chapters: const [
        BookSourceChapter(id: 'chapter-5', title: 'Chapter 5', order: 4),
      ],
      chapterIndex: 0,
      chapterProgress: position.chapterProgress,
      mappingConfidence: BookSourceChapterMappingConfidence.exactTitle,
      responseTime: const Duration(milliseconds: 120),
    );
  }
}

class _LateValidationService extends _PageChangeService {
  final Completer<void> _release = Completer();

  void release() => _release.complete();

  @override
  Future<ValidatedBookSourceChange> validate({
    required BookSourceChangeCandidate candidate,
    required BookSourceChangePosition position,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 20),
    void Function(BookSourceChangeValidationStage stage)? onStage,
    int? selectedChapterIndex,
  }) async {
    await _release.future;
    return super.validate(candidate: candidate, position: position);
  }
}

class _ManualMappingService extends _PageChangeService {
  int? selectedChapterIndex;

  @override
  Future<ValidatedBookSourceChange> validate({
    required BookSourceChangeCandidate candidate,
    required BookSourceChangePosition position,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 20),
    void Function(BookSourceChangeValidationStage stage)? onStage,
    int? selectedChapterIndex,
  }) async {
    this.selectedChapterIndex = selectedChapterIndex;
    final result = await super.validate(
      candidate: candidate,
      position: position,
    );
    return ValidatedBookSourceChange(
      candidate: result.candidate,
      book: result.book,
      chapters: result.chapters,
      chapterIndex: selectedChapterIndex ?? result.chapterIndex,
      chapterProgress: 0,
      mappingConfidence: selectedChapterIndex == null
          ? BookSourceChapterMappingConfidence.proportional
          : BookSourceChapterMappingConfidence.manual,
      responseTime: result.responseTime,
    );
  }
}

class _UnavailablePositionService extends _ManualMappingService {
  @override
  Future<BookSourceChangePosition> loadPosition({
    required RegisteredBookSource source,
    required BookSourceBook book,
    Book? shelfBook,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 8),
  }) async => throw StateError('old catalog is unavailable');
}

class _SlowSearchService extends _PageChangeService {
  final Completer<void> _release = Completer();

  void release() => _release.complete();

  @override
  Stream<BookSourceChangeSearchEvent> search({
    required Iterable<RegisteredBookSource> sources,
    required String title,
    required String author,
    required bool checkAuthor,
    String? currentSourceId,
    Set<String> excludedSourceIds = const {},
    int? sourceLimit,
    int? candidateLimit,
  }) async* {
    yield BookSourceChangeSearchEvent(
      source: _newSource,
      completed: 1,
      candidates: [candidate],
    );
    await _release.future;
    yield BookSourceChangeSearchEvent(source: _matchSource, completed: 2);
  }
}

class _TimeoutValidationService extends _PageChangeService {
  @override
  Future<ValidatedBookSourceChange> validate({
    required BookSourceChangeCandidate candidate,
    required BookSourceChangePosition position,
    BookDownloadCancellation? cancellation,
    Duration timeout = const Duration(seconds: 20),
    void Function(BookSourceChangeValidationStage stage)? onStage,
    int? selectedChapterIndex,
  }) async =>
      throw const BookSourceChangeTimeoutException(Duration(seconds: 20));
}
