import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/core/reader/reader_layout.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/pages/reader/native/native_reader_page.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/services/reading/reading_activity_recorder.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';

import 'support/book_source_progress_test_utils.dart';
import 'support/reader_cache_test_utils.dart';
import 'support/reading_cloud_test_utils.dart';

void main() {
  late Directory directory;
  late ReplaceRuleService rules;
  late BookSourceProgressTestFixture progress;
  late _ActivityDao dao;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: ReaderPageMode.instantPage.name,
      ReaderSettingsStore.chapterTitlePageKey: false,
    });
    directory = Directory.systemTemp.createTempSync('reading-activity-');
    rules = ReplaceRuleService();
    progress = await BookSourceProgressTestFixture.create();
    dao = _ActivityDao();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'com.niki.xxread/fullscreen',
      'com.niki.xxread/reader_keys',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.niki.xxread/reader_status'),
      (_) async => {'level': 80, 'charging': false},
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.path,
    );
    await prepareReadingCloudTestDatabase();
    await BookDao().insertBook(
      Book(
        id: 7,
        title: 'Activity',
        filePath: '${directory.path}/book.txt',
        format: 'txt',
      ),
    );
  });

  tearDown(() async {
    await closeReadingCloudTestDatabase();
    await rules.close();
    await progress.close();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'com.niki.xxread/fullscreen',
      'com.niki.xxread/reader_keys',
      'com.niki.xxread/reader_status',
      'plugins.flutter.io/path_provider',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), null);
    }
    if (directory.existsSync()) directory.deleteSync(recursive: true);
  });

  for (final content in ['Readable body.', '']) {
    testWidgets(
      'native ${content.isEmpty ? 'empty' : 'successful'} content records appropriate activity',
      (tester) async {
        final file = File('${directory.path}/book.txt')
          ..writeAsStringSync(content);
        await tester.pumpWidget(
          _app(
            NativeReaderPage(
              book: Book(
                id: 7,
                title: 'Activity',
                filePath: file.path,
                format: 'txt',
                textEncoding: 'utf8',
              ),
              replaceRuleService: rules,
              initialTheme: ReaderThemes.day,
              paginationCacheDao: MemoryPaginationCacheDao(),
              readingActivityRecorder: ReadingActivityRecorder(bookDao: dao),
            ),
          ),
        );
        await _pump(tester);
        expect(dao.books, content.isEmpty ? isEmpty : [7]);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _pump(tester);
        expect(dao.books, content.isEmpty ? isEmpty : [7]);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await drainReaderCache(tester);
        await drainReadingCloudWrites(tester);
      },
    );
  }

  testWidgets('online failed chapter only records after successful retry', (
    tester,
  ) async {
    final client = _ActivityClient()..fail = true;
    final shelf = _ActivityShelf(client);
    final activity = ReadingActivityRecorder(bookDao: dao);
    await tester.pumpWidget(
      _app(
        BookSourceReaderPage(
          source: _source,
          book: _sourceBook,
          replaceRuleService: rules,
          client: client,
          shelfService: shelf,
          initialShelfBook: Book(
            id: 7,
            title: 'Saved',
            filePath: '',
            format: 'source',
          ),
          initialTheme: ReaderThemes.day,
          progressStore: progress.store,
          paginationCacheDao: MemoryPaginationCacheDao(),
          readingActivityRecorder: activity,
        ),
      ),
    );
    await _pump(tester);
    expect(dao.books, isEmpty);
    client.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, '重试'));
    await _pump(tester);
    expect(find.byType(ReaderAnnotatedTextPage), findsWidgets);
    expect(dao.books, [7]);
    await _pump(tester);
    expect(dao.books, [7]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await drainReadingCloudWrites(tester);
    shelf.close();
    client.close();
  });

  testWidgets('successful online trial records after adding it on exit', (
    tester,
  ) async {
    final client = _ActivityClient();
    final shelf = _ActivityShelf(client);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(const SizedBox(), navigator: navigator));
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => BookSourceReaderPage(
            source: _source,
            book: _sourceBook,
            replaceRuleService: rules,
            client: client,
            shelfService: shelf,
            initialTheme: ReaderThemes.day,
            progressStore: progress.store,
            paginationCacheDao: MemoryPaginationCacheDao(),
            readingActivityRecorder: ReadingActivityRecorder(bookDao: dao),
          ),
        ),
      ),
    );
    await _pump(tester);
    expect(find.byType(ReaderAnnotatedTextPage), findsWidgets);
    expect(dao.books, isEmpty);
    await navigator.currentState!.maybePop();
    await _pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, '加入书架'));
    await _pump(tester);
    expect(dao.books, [42]);
    expect(find.byType(BookSourceReaderPage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await drainReadingCloudWrites(tester);
    shelf.close();
    client.close();
  });
}

Widget _app(Widget child, {GlobalKey<NavigatorState>? navigator}) =>
    MaterialApp(
      navigatorKey: navigator,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

Future<void> _pump(WidgetTester tester) async {
  for (var i = 0; i < 35; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _ActivityDao extends BookDao {
  final books = <int>[];
  @override
  Future<void> markRead(int bookId, {DateTime? at}) async => books.add(bookId);
}

final _source = RegisteredBookSource(
  id: 'activity-source',
  name: 'Activity',
  description: '',
  manifestUrl: Uri.parse('https://example.com/manifest.json'),
  apiBaseUrl: Uri.parse('https://example.com/api'),
  protocolVersion: '1.0',
  languages: const ['zh'],
  capabilities: const {},
  enabled: true,
  addedAt: DateTime.utc(2026),
);
const _sourceBook = BookSourceBook(
  id: 'book',
  title: 'Activity',
  author: '',
  description: '',
  categories: [],
);

class _ActivityClient extends BookSourceClient {
  bool fail = false;
  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => const [
    BookSourceChapter(id: 'chapter', title: 'Chapter', order: 0),
  ];
  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async {
    if (fail) throw StateError('chapter failed');
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: 'Chapter',
      content: 'Readable body.',
      contentType: 'text/plain',
    );
  }
}

class _ActivityShelf extends BookSourceShelfService {
  _ActivityShelf(BookSourceClient client) : super(client: client);
  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) async => null;
  @override
  Future<Book> addOnline({
    required RegisteredBookSource source,
    required BookSourceBook book,
  }) async => Book(id: 42, title: book.title, filePath: '', format: 'source');
  @override
  Future<void> updateShelfProgress({
    required int shelfBookId,
    required int chapterIndex,
    required int chapterCount,
    required double chapterProgress,
  }) async {}
}
