import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/widgets/reader_progress_pill.dart';

import 'support/no_shelf_book_source_service.dart';
import 'support/reading_cloud_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'origo-x-source-progress-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => temporaryDirectory.path,
        );
    await prepareReadingCloudTestDatabase();
  });

  tearDownAll(() async {
    await closeReadingCloudTestDatabase();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('source progress pill switches between catalog chapters', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.horizontalSlide.name,
      ReaderSettingsStore.progressBarEnabledKey: true,
      ReaderSettingsStore.progressBarScopeKey: ReaderProgressScope.chapter.name,
    });
    final client = _TwoChapterClient();
    final replaceRules = ReplaceRuleService();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await drainReadingCloudWrites(tester);
      await replaceRules.close();
      client.close();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceReaderPage(
          paginationCacheDao: _MemoryPaginationCacheDao(),
          replaceRuleService: replaceRules,
          source: _source,
          book: _book,
          client: client,
          shelfService: NoShelfBookSourceService(client),
          progressStore: _MemoryProgressStore(),
        ),
      ),
    );
    await _pumpUntil(tester, () => find.byType(PageView).evaluate().isNotEmpty);

    await tester.tapAt(const Offset(210, 350));
    await tester.pump();
    await _pumpUntil(
      tester,
      () => find.byType(ReaderProgressPill).evaluate().isNotEmpty,
    );
    expect(
      tester
          .widget<ReaderProgressPill>(find.byType(ReaderProgressPill))
          .position
          .chapterIndex,
      0,
    );

    final nextButton = find.byKey(const ValueKey('reader-progress-next'));
    await _pumpUntil(
      tester,
      () => tester.widget<IconButton>(nextButton).onPressed != null,
    );
    tester.widget<IconButton>(nextButton).onPressed!();
    await _pumpUntil(
      tester,
      () =>
          find.byType(ReaderProgressPill).evaluate().isNotEmpty &&
          tester
                  .widget<ReaderProgressPill>(find.byType(ReaderProgressPill))
                  .position
                  .chapterIndex ==
              1,
    );
    expect(client.requestedChapterIds, contains('chapter-2'));

    final previousButton = find.byKey(
      const ValueKey('reader-progress-previous'),
    );
    await _pumpUntil(
      tester,
      () => tester.widget<IconButton>(previousButton).onPressed != null,
    );
    tester.widget<IconButton>(previousButton).onPressed!();
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<ReaderProgressPill>(find.byType(ReaderProgressPill))
              .position
              .chapterIndex ==
          0,
    );
    expect(tester.takeException(), isNull);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('reader-progress-slider')),
    );
    slider.onChangeStart!(slider.value);
    slider.onChanged!(0.5);
    await tester.pump();
    slider.onChangeEnd!(0.5);
    await _pumpUntil(
      tester,
      () =>
          tester
              .widget<ReaderProgressPill>(find.byType(ReaderProgressPill))
              .position
              .chapterProgress >
          0.3,
    );
    final position = tester
        .widget<ReaderProgressPill>(find.byType(ReaderProgressPill))
        .position;
    expect(position.chapterIndex, 0);
    expect(position.chapterProgress, lessThan(0.7));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await drainReadingCloudWrites(tester);
  });

  testWidgets('disabled source progress preference hides the pill', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.horizontalSlide.name,
      ReaderSettingsStore.progressBarEnabledKey: false,
    });
    final client = _TwoChapterClient();
    final replaceRules = ReplaceRuleService();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await drainReadingCloudWrites(tester);
      await replaceRules.close();
      client.close();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceReaderPage(
          paginationCacheDao: _MemoryPaginationCacheDao(),
          replaceRuleService: replaceRules,
          source: _source,
          book: _book,
          client: client,
          shelfService: NoShelfBookSourceService(client),
          progressStore: _MemoryProgressStore(),
        ),
      ),
    );
    await _pumpUntil(tester, () => find.byType(PageView).evaluate().isNotEmpty);
    await tester.tapAt(const Offset(210, 350));
    await tester.pump();
    expect(find.byType(ReaderProgressPill), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await drainReadingCloudWrites(tester);
  });
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for reader progress navigation.');
}

const _book = BookSourceBook(
  id: 'progress-book',
  title: 'Progress book',
  author: 'Author',
  description: '',
  categories: [],
);

final _source = RegisteredBookSource(
  id: 'progress.source',
  name: 'Progress source',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.0',
  languages: const ['zh-CN'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026, 10, 10),
);

class _TwoChapterClient extends BookSourceClient {
  final List<String> requestedChapterIds = [];

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => const [
    BookSourceChapter(id: 'chapter-1', title: 'Chapter 1', order: 0),
    BookSourceChapter(id: 'chapter-2', title: 'Chapter 2', order: 1),
  ];

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async {
    requestedChapterIds.add(chapterId);
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: chapterId == 'chapter-1' ? 'Chapter 1' : 'Chapter 2',
      content: List.generate(
        80,
        (index) => '$chapterId paragraph $index has enough text to paginate.',
      ).join('\n'),
      contentType: 'text/plain',
    );
  }
}

class _MemoryProgressStore extends BookSourceReadingProgressStore {
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
