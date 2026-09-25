import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_change_service.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/data/migration/book_source_reading_progress_schema_migration.dart';

void main() {
  late Database database;
  late BookSourceReadingProgressStore progressStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    database = await openDatabase(inMemoryDatabasePath);
    await BookSourceReadingProgressSchemaMigration.migrate(database);
    progressStore = BookSourceReadingProgressStore(
      database: () async => database,
    );
  });

  tearDown(() => database.close());

  test('normalizes book identity and maps a renamed chapter by number', () {
    expect(sameBookTitle('《测试 小说》', '测试小说'), isTrue);
    expect(sameBookTitle('Ａ计划', 'A计划'), isTrue);
    expect(sameBookTitle('時々', '時'), isFalse);
    expect(sameBookAuthor('作者：张三 著', '张三'), isTrue);
    expect(
      matchBookSourceChapter(
        oldIndex: 48,
        oldTitle: '第49章 旧标题',
        oldChapterCount: 100,
        newChapters: List.generate(
          110,
          (index) => BookSourceChapter(
            id: 'new-$index',
            title: '第${index + 1}章 新标题',
            order: index,
          ),
        ),
      ),
      48,
    );
    expect(
      matchBookSourceChapter(
        oldIndex: 5,
        oldTitle: '第六章 旧标题',
        oldChapterCount: 10,
        newChapters: List.generate(
          10,
          (index) => BookSourceChapter(
            id: 'arabic-$index',
            title: '第${index + 1}章 新标题',
            order: index,
          ),
        ),
      ),
      5,
    );
  });

  test(
    'searches, validates content, and replaces the same shelf row',
    () async {
      final dao = _MemoryBookDao(_shelfBook, progressStore);
      final shelfService = BookSourceShelfService(bookDao: dao);
      final client = _ChangeClient();
      final service = BookSourceChangeService(
        client: client,
        shelfService: shelfService,
        progressStore: progressStore,
      );
      await progressStore.save(
        sourceId: _oldSource.id,
        bookId: _oldBook.id,
        progress: BookSourceReadingProgress(
          chapterId: 'old-5',
          chapterIndex: 5,
          chapterProgress: 0.4,
          updatedAt: DateTime.utc(2026, 8, 2),
        ),
      );

      final position = await service.loadPosition(
        source: _oldSource,
        book: _oldBook,
        shelfBook: _shelfBook,
      );
      final events = await service
          .search(
            sources: [_oldSource, _newSource],
            title: _oldBook.title,
            author: _oldBook.author,
            checkAuthor: true,
            currentSourceId: _oldSource.id,
          )
          .toList();

      expect(events, hasLength(1));
      expect(events.single.candidates, hasLength(1));
      final candidate = events.single.candidates.single;
      final stages = <BookSourceChangeValidationStage>[];
      final validated = await service.validate(
        candidate: candidate,
        position: position,
        onStage: stages.add,
      );
      final result = await service.commit(
        validated: validated,
        shelfBook: _shelfBook,
      );

      expect(result.shelfBook?.id, _shelfBook.id);
      expect(dao.stored.id, _shelfBook.id);
      expect(dao.stored.sourceId, _newSource.id);
      expect(dao.stored.sourceBookId, _newBook.id);
      expect(dao.stored.title, _shelfBook.title);
      expect(dao.stored.currentPage, 5000);
      final migrated = await progressStore.load(
        sourceId: _newSource.id,
        bookId: _newBook.id,
      );
      expect(migrated?.chapterIndex, 5);
      expect(migrated?.chapterProgress, 0);
      expect(client.contentRequests, 1);
      expect(
        validated.mappingConfidence,
        BookSourceChapterMappingConfidence.exactTitle,
      );
      expect(stages, BookSourceChangeValidationStage.values);
    },
  );

  test(
    'manual chapter selection is revalidated and starts at chapter top',
    () async {
      final client = _ChangeClient();
      final service = BookSourceChangeService(client: client);

      final validated = await service.validate(
        candidate: BookSourceChangeCandidate(
          source: _newSource,
          book: _newBook,
          authorMatches: true,
        ),
        position: const BookSourceChangePosition(
          chapterIndex: 8,
          chapterProgress: 0.85,
          chapterTitle: '未匹配章节',
          chapterCount: 20,
        ),
        selectedChapterIndex: 2,
      );

      expect(validated.chapterIndex, 2);
      expect(validated.chapterProgress, 0);
      expect(
        validated.mappingConfidence,
        BookSourceChapterMappingConfidence.manual,
      );
      expect(client.contentRequests, 1);
    },
  );

  test(
    'transaction target conflict remains a typed source-change conflict',
    () async {
      final dao = _MemoryBookDao(_shelfBook, progressStore)
        ..bindingError = const BookSourceBindingConflictException(
          BookSourceBindingConflictReason.targetAlreadyBound,
        );
      final service = BookSourceChangeService(
        shelfService: BookSourceShelfService(bookDao: dao),
        progressStore: progressStore,
      );
      final validated = ValidatedBookSourceChange(
        candidate: BookSourceChangeCandidate(
          source: _newSource,
          book: _newBook,
          authorMatches: true,
        ),
        book: _newBook,
        chapters: const [
          BookSourceChapter(id: 'chapter-1', title: '第一章', order: 0),
        ],
        chapterIndex: 0,
        chapterProgress: 0,
        responseTime: Duration.zero,
      );

      await expectLater(
        service.commit(validated: validated, shelfBook: _shelfBook),
        throwsA(isA<BookSourceChangeConflict>()),
      );
    },
  );

  test(
    'search uses bounded workers instead of starting every source',
    () async {
      final client = _ConcurrentSearchClient();
      final service = BookSourceChangeService(
        client: client,
        maxConcurrentSearches: 3,
      );
      final sources = List.generate(
        24,
        (index) => _source('source-$index', 'Source $index'),
      );

      final events = await service
          .search(
            sources: sources,
            title: _oldBook.title,
            author: _oldBook.author,
            checkAuthor: true,
          )
          .toList();

      expect(events, hasLength(24));
      expect(client.maxActive, lessThanOrEqualTo(3));
      expect(client.started, 24);
    },
  );

  test('cancelling search stops scheduling untouched sources', () async {
    final client = _ConcurrentSearchClient();
    final service = BookSourceChangeService(
      client: client,
      maxConcurrentSearches: 2,
    );
    final sources = List.generate(
      40,
      (index) => _source('cancel-$index', 'Cancel $index'),
    );

    await service
        .search(
          sources: sources,
          title: _oldBook.title,
          author: _oldBook.author,
          checkAuthor: true,
        )
        .take(1)
        .drain<void>();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(client.started, lessThan(40));
    expect(client.maxActive, lessThanOrEqualTo(2));
  });

  test('known fast and verified sources are searched first', () async {
    final client = _OrderTrackingClient();
    final service = BookSourceChangeService(
      client: client,
      maxConcurrentSearches: 1,
    );
    final slow = _readingSource('slow', 180000);
    final fast = _readingSource('fast', 280);

    await service
        .search(
          sources: [slow, fast],
          title: _oldBook.title,
          author: _oldBook.author,
          checkAuthor: true,
        )
        .drain<void>();

    expect(client.sourceOrder, ['fast', 'slow']);
  });

  test('limited search keeps only the highest-priority sources', () async {
    final client = _OrderTrackingClient();
    final service = BookSourceChangeService(
      client: client,
      maxConcurrentSearches: 1,
    );
    final slowSources = List.generate(
      1000,
      (index) => _readingSource('slow-$index', 180000),
    );
    final fast = _readingSource('fast', 180);

    await service
        .search(
          sources: [...slowSources, fast],
          title: _oldBook.title,
          author: _oldBook.author,
          checkAuthor: true,
          sourceLimit: 1,
        )
        .drain<void>();

    expect(client.sourceOrder, ['fast']);
  });

  test('a timed-out source releases its worker for the next source', () async {
    final client = _TimeoutAwareClient();
    final service = BookSourceChangeService(
      client: client,
      maxConcurrentSearches: 1,
      perSourceSearchTimeout: const Duration(milliseconds: 35),
    );
    final stopwatch = Stopwatch()..start();

    final events = await service
        .search(
          sources: [_source('a-dead', 'A dead'), _source('b-fast', 'B fast')],
          title: _oldBook.title,
          author: _oldBook.author,
          checkAuthor: true,
        )
        .toList();
    stopwatch.stop();

    expect(events, hasLength(2));
    expect(events.last.candidates, hasLength(1));
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 300)));
  });

  test('validation timeout cancels the active detail request', () async {
    final client = _HangingValidationClient();
    final service = BookSourceChangeService(client: client);
    final candidate = BookSourceChangeCandidate(
      source: _newSource,
      book: _newBook,
      authorMatches: true,
    );

    await expectLater(
      service.validate(
        candidate: candidate,
        position: const BookSourceChangePosition(
          chapterIndex: 0,
          chapterProgress: 0,
          chapterTitle: '',
          chapterCount: 0,
        ),
        timeout: const Duration(milliseconds: 35),
      ),
      throwsA(isA<BookSourceChangeTimeoutException>()),
    );

    expect(client.cancelled, isTrue);
  });

  test(
    'validation deadline returns when a client ignores cancellation',
    () async {
      final service = BookSourceChangeService(
        client: _CancellationIgnoringClient(),
      );
      final stopwatch = Stopwatch()..start();

      await expectLater(
        service.validate(
          candidate: BookSourceChangeCandidate(
            source: _newSource,
            book: _newBook,
            authorMatches: true,
          ),
          position: const BookSourceChangePosition(
            chapterIndex: 0,
            chapterProgress: 0,
            chapterTitle: '',
            chapterCount: 0,
          ),
          timeout: const Duration(milliseconds: 35),
        ),
        throwsA(isA<BookSourceChangeTimeoutException>()),
      );

      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 300)));
    },
  );

  test(
    'search deadline releases a worker when a client never returns',
    () async {
      final service = BookSourceChangeService(
        client: _CancellationIgnoringClient(),
        maxConcurrentSearches: 1,
        perSourceSearchTimeout: const Duration(milliseconds: 35),
      );
      final stopwatch = Stopwatch()..start();

      final events = await service
          .search(
            sources: [_source('a-dead', 'A dead'), _source('b-fast', 'B fast')],
            title: _oldBook.title,
            author: _oldBook.author,
            checkAuthor: true,
          )
          .toList();

      stopwatch.stop();
      expect(events, hasLength(2));
      expect(events.first.error, isA<BookSourceChangeTimeoutException>());
      expect(events.last.candidates, hasLength(1));
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 300)));
    },
  );
}

final _oldSource = _source('old-source', '旧来源');
final _newSource = _source('new-source', '新来源');

RegisteredBookSource _source(String id, String name) => RegisteredBookSource(
  id: id,
  name: name,
  description: '',
  manifestUrl: Uri.parse('https://$id.example/source.json'),
  apiBaseUrl: Uri.parse('https://$id.example/api/'),
  protocolVersion: '1.5',
  languages: const ['zh-CN'],
  capabilities: const {'search', 'detail', 'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026, 8, 2),
);

RegisteredBookSource _readingSource(String id, int respondTime) =>
    RegisteredBookSource(
      id: id,
      name: id,
      description: '',
      manifestUrl: Uri.parse('https://$id.example/'),
      apiBaseUrl: Uri.parse('https://$id.example/'),
      protocolVersion: 'reading-source-1',
      languages: const [],
      capabilities: const {'search'},
      enabled: true,
      addedAt: DateTime.utc(2026, 8, 2),
      sourceProtocol: BookSourceProtocolKind.readingSource,
      sourceConfig: {'respondTime': respondTime},
    );

const _oldBook = BookSourceBook(
  id: 'old-book',
  title: '测试小说',
  author: '张三',
  description: '',
  categories: [],
);

const _newBook = BookSourceBook(
  id: 'new-book',
  title: '《测试小说》',
  author: '张三 著',
  description: '新来源详情',
  categories: [],
  latestChapter: '第20章',
);

final _shelfBook = Book(
  id: 7,
  title: '用户保留的书名',
  author: '张三',
  filePath: '',
  format: 'source',
  storageType: 'online',
  sourceId: _oldSource.id,
  sourceBookId: _oldBook.id,
  sourceJson: jsonEncode(_oldSource.toJson()),
  sourceBookJson: jsonEncode(_oldBook.toJson()),
  currentPage: 5400,
  totalPages: 10000,
);

class _ChangeClient extends BookSourceClient {
  int contentRequests = 0;

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async => BookSourceSearchPage(
    items: source.id == _newSource.id ? const [_newBook] : const [],
    page: 1,
    pageSize: pageSize,
    hasMore: false,
  );

  @override
  Future<BookSourceBook> getBook(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async => _newBook;

  @override
  Future<BookSourceBook> getBookForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return _newBook;
  }

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async => List.generate(
    source.id == _oldSource.id ? 10 : 12,
    (index) => BookSourceChapter(
      id: '${source.id}-$index',
      title: '第${index + 1}章 标题',
      order: index,
    ),
  );

  @override
  Future<List<BookSourceChapter>> getChaptersForDownload(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return getChapters(source, bookId, sourceVariables: sourceVariables);
  }

  @override
  Future<List<BookSourceChapter>> getChaptersForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) => getChaptersForDownload(
    source,
    bookId,
    sourceVariables: sourceVariables,
    cancellation: cancellation,
  );

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
  }) async {
    contentRequests++;
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: '',
      content: '可读取的正文',
      contentType: 'text/plain',
    );
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
    return getChapterContent(
      source,
      bookId: bookId,
      chapterId: chapterId,
      sourceVariables: sourceVariables,
    );
  }

  @override
  Future<BookSourceChapterContent> getChapterContentForValidation(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) => getChapterContentForDownload(
    source,
    bookId: bookId,
    chapterId: chapterId,
    sourceVariables: sourceVariables,
    cancellation: cancellation,
  );
}

class _ConcurrentSearchClient extends BookSourceClient {
  int active = 0;
  int maxActive = 0;
  int started = 0;

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    started++;
    active++;
    if (active > maxActive) maxActive = active;
    await Future<void>.delayed(const Duration(milliseconds: 12));
    active--;
    return BookSourceSearchPage(
      items: const [],
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}

class _OrderTrackingClient extends BookSourceClient {
  final List<String> sourceOrder = [];

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    sourceOrder.add(source.id);
    return BookSourceSearchPage(
      items: const [],
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}

class _TimeoutAwareClient extends BookSourceClient {
  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    if (source.id == 'a-dead') {
      final cancelled = Completer<void>();
      void onCancelled() {
        if (!cancelled.isCompleted) cancelled.complete();
      }

      cancellation?.addListener(onCancelled);
      try {
        await cancelled.future;
        cancellation?.throwIfCancelled();
      } finally {
        cancellation?.removeListener(onCancelled);
      }
    }
    return BookSourceSearchPage(
      items: source.id == 'b-fast' ? const [_oldBook] : const [],
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}

class _HangingValidationClient extends BookSourceClient {
  bool cancelled = false;

  @override
  Future<BookSourceBook> getBookForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    final completed = Completer<void>();
    void onCancelled() {
      cancelled = true;
      if (!completed.isCompleted) completed.complete();
    }

    cancellation?.addListener(onCancelled);
    try {
      await completed.future;
      cancellation?.throwIfCancelled();
      return _newBook;
    } finally {
      cancellation?.removeListener(onCancelled);
    }
  }
}

class _CancellationIgnoringClient extends BookSourceClient {
  @override
  Future<BookSourceBook> getBookForValidation(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) => Completer<BookSourceBook>().future;

  @override
  Future<BookSourceSearchPage> search(
    RegisteredBookSource source,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) {
    if (source.id == 'a-dead') {
      return Completer<BookSourceSearchPage>().future;
    }
    return Future.value(
      BookSourceSearchPage(
        items: const [_oldBook],
        page: page,
        pageSize: pageSize,
        hasMore: false,
      ),
    );
  }
}

class _MemoryBookDao extends BookDao {
  _MemoryBookDao(this.stored, this.progressStore);

  Book stored;
  final BookSourceReadingProgressStore progressStore;
  Object? bindingError;

  @override
  Future<Book?> getBookBySource({
    required String sourceId,
    required String sourceBookId,
  }) async {
    if (stored.sourceId == sourceId && stored.sourceBookId == sourceBookId) {
      return stored;
    }
    return null;
  }

  @override
  Future<Book> updateSourceBinding(Book expected, Book replacement) async {
    stored = replacement;
    return stored;
  }

  @override
  Future<Book> updateSourceBindingWithProgress(
    Book expected,
    Book replacement, {
    required BookSourceReadingProgress progress,
  }) async {
    final error = bindingError;
    if (error != null) throw error;
    stored = replacement;
    await progressStore.save(
      sourceId: replacement.sourceId!,
      bookId: replacement.sourceBookId!,
      progress: progress,
    );
    return stored;
  }

  @override
  Future<void> updateBook(Book book) async => stored = book;
}
