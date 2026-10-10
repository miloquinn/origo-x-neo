import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/source_engine/scripting/source_script_contract.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_paragraph_action_layer.dart';

import 'support/book_source_progress_test_utils.dart';
import 'support/no_shelf_book_source_service.dart';

void main() {
  for (final mode in [
    BookSourcePageMode.verticalScroll,
    BookSourcePageMode.horizontalSlide,
    BookSourcePageMode.pageCurl,
  ]) {
    testWidgets('Legado comments survive purification in ${mode.name}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: mode.name,
        'native_reader_txt_chapter_title_page_enabled': false,
      });
      final progress = await BookSourceProgressTestFixture.create();
      final rules = ReplaceRuleService();
      final client = _ActionClient();
      final shelf = NoShelfBookSourceService(client);
      addTearDown(() async {
        await rules.close();
        await progress.close();
        shelf.close();
        client.close();
      });
      await rules.upsert(
        const ReplaceRule(
          id: 'delete-ad',
          name: '广告',
          pattern: '广告正文\n',
          replacement: '',
          isRegex: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceReaderPage(
            source: _source(),
            book: const BookSourceBook(
              id: 'book',
              title: '测试书籍',
              author: '作者',
              description: '',
              categories: [],
              sourceVariables: {'saved': 'value'},
            ),
            client: client,
            shelfService: shelf,
            replaceRuleService: rules,
            progressStore: progress.store,
            paginationCacheDao: _MemoryPagination(),
            initialTheme: ReaderThemes.day,
          ),
        ),
      );
      final first = find.byKey(
        const ValueKey('reader-paragraph-action:book:chapter:1'),
      );
      await _ready(tester, first);
      expect(
        client.actions,
        isEmpty,
        reason: 'Loading cannot execute comments',
      );
      expect(
        find.byKey(const ValueKey('reader-paragraph-action:book:chapter:0')),
        findsNothing,
        reason: 'Fully purified paragraph loses its action',
      );
      expect(
        find.byKey(const ValueKey('reader-paragraph-action:book:chapter:2')),
        findsWidgets,
        reason: 'Identical original paragraphs remain distinct',
      );
      final annotated = tester.widget<ReaderAnnotatedTextPage>(
        find.byType(ReaderAnnotatedTextPage).first,
      );
      expect(annotated.sourceText, '同样正文。\n同样正文。');
      expect(
        annotated.paragraphActionGutter,
        ReaderParagraphActionLayer.gutter,
      );
      await tester.tap(first.first);
      await tester.pumpAndSettle();
      final choice = find.byKey(
        const ValueKey('reader-paragraph-choice:book:chapter:1'),
      );
      if (choice.evaluate().isNotEmpty) {
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }
      expect(client.actions, ['first']);
      expect(client.actionResult, contains('"click":"first"'));
      expect(client.actionVariables['bookName'], '测试书籍');
      expect(client.actionVariables['chapterTitle'], '第一章');
      expect(client.actionVariables['saved'], 'value');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reader disposal cancels a running paragraph action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.verticalScroll.name,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    final progress = await BookSourceProgressTestFixture.create();
    final rules = ReplaceRuleService();
    final client = _ActionClient()..pending = Completer<String>();
    final shelf = NoShelfBookSourceService(client);
    addTearDown(() async {
      await rules.close();
      await progress.close();
      shelf.close();
      client.close();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSourceReaderPage(
          source: _source(),
          book: const BookSourceBook(
            id: 'book',
            title: '测试书籍',
            author: '',
            description: '',
            categories: [],
          ),
          client: client,
          shelfService: shelf,
          replaceRuleService: rules,
          progressStore: progress.store,
          paginationCacheDao: _MemoryPagination(),
          initialTheme: ReaderThemes.day,
        ),
      ),
    );
    final action = find.byKey(
      const ValueKey('reader-paragraph-action:book:chapter:1'),
    );
    await _ready(tester, action);
    await tester.tap(
      find
          .byKey(const ValueKey('reader-paragraph-action:book:chapter:0'))
          .first,
    );
    await tester.pumpAndSettle();
    final choice = find.byKey(
      const ValueKey('reader-paragraph-choice:book:chapter:1'),
    );
    if (choice.evaluate().isNotEmpty) {
      await tester.tap(choice);
      await tester.pumpAndSettle();
    }
    expect(client.actionCancellation?.isCancelled, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(client.actionCancellation?.isCancelled, isTrue);
    client.pending!.complete('late result');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _ready(WidgetTester tester, Finder finder) async {
  for (var count = 0; count < 60; count++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

RegisteredBookSource _source() => RegisteredBookSource(
  id: 'paragraph-source',
  name: '示例书源',
  description: '',
  manifestUrl: Uri.parse('https://comments.test/source'),
  apiBaseUrl: Uri.parse('https://comments.test/'),
  protocolVersion: '1.0',
  languages: const ['zh'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026, 10, 10),
  sourceProtocol: BookSourceProtocolKind.readingSource,
  sourceConfig: const {
    'bookSourceUrl': 'https://comments.test/',
    'bookSourceName': '示例书源',
    'ruleContent': {'content': 'body'},
  },
);

class _ActionClient extends BookSourceClient {
  final actions = <String>[];
  String actionResult = '';
  Map<String, String> actionVariables = {};
  BookDownloadCancellation? actionCancellation;
  Completer<String>? pending;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => const [BookSourceChapter(id: 'chapter', title: '第一章', order: 0)];

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async {
    String paragraph(String text, String action) =>
        '<p>$text<img src="'
        'https://comments.test/bubble.svg,${jsonEncode({'style': 'text', 'click': action})}"></p>';
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: '',
      content:
          paragraph('广告正文', 'advert') +
          paragraph('同样正文。', 'first') +
          paragraph('同样正文。', 'second'),
      contentType: 'text/html',
    );
  }

  @override
  Future<String> executeChapterAction(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    required String script,
    required String result,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
    Future<SourceScriptInteractionResult> Function(
      SourceScriptInteractionRequest,
    )?
    interactionHandler,
  }) {
    actions.add(script);
    actionResult = result;
    actionVariables = sourceVariables;
    actionCancellation = cancellation;
    return pending?.future ?? Future.value('done');
  }
}

class _MemoryPagination extends PaginationCacheDao {
  @override
  Future<Map<String, Uint8List>> loadForIdentity(
    String identity,
    String bookRevision,
  ) async => {};
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
