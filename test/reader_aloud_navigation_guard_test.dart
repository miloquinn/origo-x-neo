import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';
import 'package:xxread/services/books/pagination_cache_dao.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/services/reader_aloud_service.dart';
import 'package:xxread/services/reader_aloud_session.dart';
import 'package:xxread/services/tts_service.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_desktop_input.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';

import 'support/no_shelf_book_source_service.dart';

void main() {
  for (final action in ['stop', 'new target', 'reopen same book']) {
    testWidgets('real source reader rejects delayed reveal after $action', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        ReaderSettingsStore.pageModeKey: BookSourcePageMode.instantPage.name,
        'reader_aloud_presentation': 'controls',
        'native_reader_txt_chapter_title_page_enabled': false,
      });
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const mediaChannel = MethodChannel('com.niki.xxread/reader_aloud');
      messenger.setMockMethodCallHandler(mediaChannel, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(mediaChannel, null));
      final progress = _MemoryProgress();
      final rules = ReplaceRuleService();
      final client = _DelayedClient();
      final tts = _HeldTts();
      final service = ReaderAloudService(
        systemEngine: tts,
        settingsStore: _SettingsStore(),
        bytesPlayer: _SilentPlayer(),
      );
      final session = ReaderAloudSession();
      addTearDown(() async {
        if (!client.delayed.isCompleted) client.finishDelayed();
        var stopped = false;
        final stopping = session.stop().then((_) => stopped = true);
        await _pumpUntil(tester, () => stopped);
        await stopping;
        await tester.pumpWidget(const SizedBox.shrink());
        session.dispose();
        service.dispose();
        tts.dispose();
        client.close();
        await rules.close();
      });
      Widget reader({Widget? home, Key? key}) => MultiProvider(
        providers: [
          ChangeNotifierProvider<ReaderAloudSession>.value(value: session),
          ChangeNotifierProvider<ReaderAloudService>.value(value: service),
          ChangeNotifierProvider<TtsService>.value(value: tts),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home:
              home ??
              BookSourceReaderPage(
                key: key,
                source: _source,
                book: _book,
                client: client,
                shelfServiceFactory: NoShelfBookSourceService.new,
                replaceRuleService: rules,
                progressStore: progress,
                paginationCacheDao: _NoDiskPagination(),
              ),
        ),
      );
      await tester.pumpWidget(reader());
      await _pumpUntil(
        tester,
        () => find
            .textContaining('Opening body.', findRichText: true)
            .evaluate()
            .isNotEmpty,
      );
      await _startReadAloud(tester);
      await _pumpUntil(tester, () => tts.isPlaying);
      final controller = session.controller!;
      // Exercise the reader's actual callback and its asynchronous content load.
      // Controller guard lifecycle itself is covered in controller regressions.
      var revealRevision = 0;
      final stale = controller.source.revealPosition(
        const ReaderAloudPosition(chapterIndex: 1, offset: 0),
        isCurrent: () => controller.isActive && revealRevision == 0,
      );
      await tester.pump();
      if (action == 'stop') {
        var stopComplete = false;
        final stopped = session.stop().then((_) => stopComplete = true);
        await _pumpUntil(tester, () => stopComplete);
        await stopped;
      } else {
        revealRevision++;
        if (action == 'reopen same book') {
          final firstSource = controller.source;
          controller.setSleepTimer(const Duration(minutes: 10));
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await _pumpUntil(
            tester,
            () => find.byType(BottomSheet).evaluate().isEmpty,
          );
          await tester.pumpWidget(reader(home: const SizedBox.shrink()));
          await tester.pump();
          await tester.pumpWidget(reader(key: const ValueKey('reopened')));
          await _pumpUntil(
            tester,
            () => !identical(controller.source, firstSource),
          );
          expect(session.controller, same(controller));
          expect(controller.sleepDuration, const Duration(minutes: 10));
          expect(tts.calls, 1); // Rebinding keeps the already playing audio.
        }
        final latest = action == 'reopen same book'
            ? controller.playFromOffset(
                const ReaderAloudPosition(chapterIndex: 2, offset: 0),
              )
            : controller.source.revealPosition(
                const ReaderAloudPosition(chapterIndex: 2, offset: 0),
                isCurrent: () => controller.isActive && revealRevision == 1,
              );
        await _pumpUntil(
          tester,
          () => find
              .textContaining('Newest target body.', findRichText: true)
              .evaluate()
              .isNotEmpty,
        );
        await latest;
      }
      client.finishDelayed();
      await _pumpUntil(tester, () => client.delayed.isCompleted);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(() => stale);
      expect(
        find.textContaining('Obsolete target body.', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining(
          action == 'stop' ? 'Opening body.' : 'Newest target body.',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('book-source-reader-content')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      var stopped = false;
      final stopping = session.stop().then((_) => stopped = true);
      await _pumpUntil(tester, () => stopped);
      await stopping;
    });
  }

  testWidgets('turning away and back then tapping resumes that sentence', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: BookSourcePageMode.instantPage.name,
      'reader_aloud_presentation': 'controls',
      'reader_aloud_tap_to_seek': true,
      'reader_aloud_follow_page_turns': false,
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const mediaChannel = MethodChannel('com.niki.xxread/reader_aloud');
    messenger.setMockMethodCallHandler(mediaChannel, (_) async => null);
    addTearDown(() => messenger.setMockMethodCallHandler(mediaChannel, null));
    final client = _DelayedClient(
      openingText: 'Opening body.\nSecond opening sentence.',
    )..finishDelayed();
    final rules = ReplaceRuleService();
    final tts = _HeldTts();
    final service = ReaderAloudService(
      systemEngine: tts,
      settingsStore: _SettingsStore(),
      bytesPlayer: _SilentPlayer(),
    );
    final session = ReaderAloudSession();
    addTearDown(() async {
      var stopped = false;
      final stopping = session.stop().then((_) => stopped = true);
      await _pumpUntil(tester, () => stopped);
      await stopping;
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      service.dispose();
      tts.dispose();
      client.close();
      await rules.close();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReaderAloudSession>.value(value: session),
          ChangeNotifierProvider<ReaderAloudService>.value(value: service),
          ChangeNotifierProvider<TtsService>.value(value: tts),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSourceReaderPage(
            source: _source,
            book: _book,
            client: client,
            shelfServiceFactory: NoShelfBookSourceService.new,
            replaceRuleService: rules,
            progressStore: _MemoryProgress(),
            paginationCacheDao: _NoDiskPagination(),
          ),
        ),
      ),
    );
    final opening = find.textContaining('Opening body.', findRichText: true);
    await _pumpUntil(tester, () => opening.evaluate().isNotEmpty);
    await _startReadAloud(tester);
    await _pumpUntil(tester, () => tts.isPlaying);
    final controller = session.controller!;
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await _pumpUntil(tester, () => find.byType(BottomSheet).evaluate().isEmpty);
    await tester.pump(const Duration(milliseconds: 350));

    final readerInput = find.byType(ReaderDesktopInput);
    expect(tester.widget<ReaderDesktopInput>(readerInput).enabled, isTrue);
    tester.widget<ReaderDesktopInput>(readerInput).onNext();
    await _pumpUntil(
      tester,
      () => find
          .textContaining('Obsolete target body.', findRichText: true)
          .evaluate()
          .isNotEmpty,
    );
    expect(tester.widget<ReaderDesktopInput>(readerInput).enabled, isTrue);
    tester.widget<ReaderDesktopInput>(readerInput).onPrevious();
    await _pumpUntil(tester, () => opening.evaluate().isNotEmpty);
    expect(tts.spoken, ['Opening body.']);
    expect(session.controller, same(controller));

    final text = find
        .descendant(
          of: find.byType(ReaderAnnotatedTextPage),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Second opening sentence.'),
          ),
        )
        .hitTestable();
    final paragraph = tester.renderObject<RenderParagraph>(text);
    final offset = paragraph.text.toPlainText().indexOf('opening sentence');
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + 1),
        )
        .single
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await _pumpUntil(tester, () => tts.spoken.length == 2);
    expect(tts.spoken.last, 'Second opening sentence.');
    expect(
      controller.highlight?.startOffset,
      controller.currentChapter!.text.indexOf('Second opening sentence.'),
    );
    expect(controller.state, ReaderAloudPlaybackState.playing);
    expect(tester.takeException(), isNull);
    var stopped = false;
    final stopping = session.stop().then((_) => stopped = true);
    await _pumpUntil(tester, () => stopped);
    await stopping;
  });
}

Future<void> _startReadAloud(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(find.byType(BookSourceReaderPage)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  final button = find.byWidgetPredicate(
    (widget) =>
        widget is ReaderControlIconButton &&
        widget.icon == Icons.headphones_rounded,
  );
  expect(button.hitTestable(), findsOneWidget);
  expect(tester.widget<ReaderControlIconButton>(button).onPressed, isNotNull);
  await tester.tap(button);
  await tester.pump();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var index = 0; index < 80; index++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('Reader did not reach the expected state');
}

final _source = RegisteredBookSource(
  id: 'guard.source',
  name: 'Guard',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);
const _book = BookSourceBook(
  id: 'guard-book',
  title: 'Guard test',
  author: '',
  description: '',
  categories: [],
);

class _DelayedClient extends BookSourceClient {
  _DelayedClient({this.openingText = 'Opening body.'});

  final String openingText;
  final delayed = Completer<BookSourceChapterContent>();
  void finishDelayed() =>
      delayed.complete(_content('1', 'Obsolete target body.'));
  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => [
    for (var index = 0; index < 3; index++)
      BookSourceChapter(id: '$index', title: 'Chapter $index', order: index),
  ];
  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => chapterId == '1'
      ? delayed.future
      : _content(
          chapterId,
          chapterId == '0' ? openingText : 'Newest target body.',
        );
}

BookSourceChapterContent _content(String id, String text) =>
    BookSourceChapterContent(
      bookId: _book.id,
      chapterId: id,
      title: '',
      content: text,
      contentType: 'text/plain',
    );

class _HeldTts extends TtsService {
  Completer<void>? speech;
  int calls = 0;
  final spoken = <String>[];
  @override
  Future<void> initialize({bool force = false}) async {}
  @override
  Future<void> ensureVoicesLoaded({bool force = false}) async {}
  @override
  bool get supportsQueuedText => false;
  @override
  bool get supportsContinuousText => false;
  @override
  bool get isPlaying => speech != null;
  @override
  int get currentPosition => 0;
  @override
  Future<void> speak(String text) async {
    calls++;
    spoken.add(text);
    speech = Completer<void>();
    notifyListeners();
    await speech!.future;
  }

  @override
  Future<void> stop() async {
    speech?.complete();
    speech = null;
  }
}

class _SettingsStore implements ReaderAloudCloudSettingsStore {
  @override
  Future<ReaderAloudEngineType> loadEngineType() async =>
      ReaderAloudEngineType.system;
  @override
  Future<ReaderAloudCloudSettings> loadSettings() async =>
      const ReaderAloudCloudSettings();
  @override
  Future<String?> readApiKey() async => null;
  @override
  Future<void> clearApiKey() async {}
  @override
  Future<void> writeApiKey(String apiKey) async {}
  @override
  Future<void> saveEngineType(ReaderAloudEngineType type) async {}
  @override
  Future<void> saveSettings(ReaderAloudCloudSettings settings) async {}
}

class _SilentPlayer extends ChangeNotifier implements ReaderAloudBytesPlayer {
  @override
  bool get isPlaying => false;
  @override
  bool get isPaused => false;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get duration => Duration.zero;
  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double volume) async {}
}

class _NoDiskPagination extends PaginationCacheDao {
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

class _MemoryProgress extends BookSourceReadingProgressStore {
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
