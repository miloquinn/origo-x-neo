import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
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

import 'support/no_shelf_book_source_service.dart';

const _missingChapter = BookSourceProtocolException(
  'chapter not found (HTTP 404)',
  code: 'CHAPTER_NOT_FOUND',
);

void main() {
  for (final mode in [
    BookSourcePageMode.instantPage,
    BookSourcePageMode.verticalScroll,
  ]) {
    testWidgets(
      'natural read-aloud completion opens a known next chapter in ${mode.name}',
      (tester) async {
        final client = _TransitionClient(
          catalog: const [_firstChapter, _secondChapter],
          refreshedCatalog: const [_firstChapter, _secondChapter],
        );
        final harness = await _TransitionHarness.open(
          tester,
          client: client,
          pageMode: mode,
        );

        await harness.completeCurrentUtterance();
        await harness.waitForChapter('second');

        expect(harness.tts.spokenTexts, hasLength(2));
        expect(
          find.textContaining('Second body.', findRichText: true),
          findsWidgets,
        );
        expect(client.refreshCount, 0);
        await harness.stopPlayback();
      },
    );
  }

  testWidgets('natural completion reuses missing-chapter refresh and remap', (
    tester,
  ) async {
    const staleSecond = BookSourceChapter(
      id: 'second-old',
      title: 'Second',
      order: 2,
    );
    const refreshedSecond = BookSourceChapter(
      id: 'second-new',
      title: 'Second',
      order: 2,
    );
    final client = _TransitionClient(
      catalog: const [_firstChapter, staleSecond],
      refreshedCatalog: const [_firstChapter, refreshedSecond],
      load: (id, _) async {
        if (id == staleSecond.id) throw _missingChapter;
        return _chapterContent(
          id,
          id == _firstChapter.id ? 'First body.' : 'Remapped second body.',
        );
      },
    );
    final harness = await _TransitionHarness.open(tester, client: client);

    await harness.completeCurrentUtterance();
    await harness.waitForChapter(refreshedSecond.id);

    expect(client.refreshCount, 1);
    expect(client.requests, containsAll([staleSecond.id, refreshedSecond.id]));
    expect(
      find.textContaining('Remapped second body.', findRichText: true),
      findsWidgets,
    );
    await harness.stopPlayback();
  });

  testWidgets('missing next chapter refreshes and retries only once', (
    tester,
  ) async {
    const staleSecond = BookSourceChapter(
      id: 'missing-old',
      title: 'Missing second',
      order: 2,
    );
    const refreshedSecond = BookSourceChapter(
      id: 'missing-new',
      title: 'Missing second',
      order: 2,
    );
    final client = _TransitionClient(
      catalog: const [_firstChapter, staleSecond],
      refreshedCatalog: const [_firstChapter, refreshedSecond],
      load: (id, _) async {
        if (id != _firstChapter.id) throw _missingChapter;
        return _chapterContent(id, 'First body.');
      },
    );
    final harness = await _TransitionHarness.open(tester, client: client);

    await harness.completeCurrentUtterance();
    await _pumpUntil(
      tester,
      () => harness.controller.state == ReaderAloudPlaybackState.error,
    );

    expect(client.refreshCount, 1);
    expect(client.requests, containsAll([staleSecond.id, refreshedSecond.id]));
    expect(
      client.requests.where((id) => id == refreshedSecond.id),
      hasLength(1),
    );
    expect(harness.tts.spokenTexts, hasLength(1));
    await harness.stopPlayback();
  });

  testWidgets(
    'natural completion discovers a chapter appended to a stale catalog',
    (tester) async {
      final client = _TransitionClient(
        catalog: const [_firstChapter],
        refreshedCatalog: const [_firstChapter, _secondChapter],
      );
      final harness = await _TransitionHarness.open(tester, client: client);

      await harness.completeCurrentUtterance();
      await harness.waitForChapter(_secondChapter.id);

      expect(client.refreshCount, 1);
      expect(harness.tts.spokenTexts, hasLength(2));
      expect(
        find.textContaining('Second body.', findRichText: true),
        findsWidgets,
      );
      await harness.stopPlayback();
    },
  );

  testWidgets(
    'end-of-catalog refresh follows the previous chapter across an insertion',
    (tester) async {
      const inserted = BookSourceChapter(
        id: 'inserted',
        title: 'Inserted',
        order: 2,
      );
      const knownLast = BookSourceChapter(
        id: 'known-last',
        title: 'Known last',
        order: 3,
      );
      const appended = BookSourceChapter(
        id: 'appended',
        title: 'Appended',
        order: 4,
      );
      final client = _TransitionClient(
        catalog: const [_firstChapter, knownLast],
        refreshedCatalog: const [_firstChapter, inserted, knownLast, appended],
        load: (id, _) async => _chapterContent(
          id,
          id == _firstChapter.id ? 'First body.' : 'Body for $id.',
        ),
      );
      final harness = await _TransitionHarness.open(tester, client: client);
      await harness.controller.playFromOffset(
        const ReaderAloudPosition(chapterIndex: 1, offset: 0),
      );
      await _pumpUntil(
        tester,
        () => harness.controller.currentChapter?.id == knownLast.id,
      );

      await harness.completeCurrentUtterance();
      await harness.waitForChapter(appended.id);

      expect(client.refreshCount, 1);
      expect(client.requests, contains(appended.id));
      expect(harness.controller.currentChapter?.index, 3);
      expect(
        find.textContaining('Body for appended.', findRichText: true),
        findsWidgets,
      );
      await harness.stopPlayback();
    },
  );

  testWidgets('stopping cancels a delayed end-of-catalog refresh', (
    tester,
  ) async {
    final refresh = Completer<List<BookSourceChapter>>();
    final client = _TransitionClient(
      catalog: const [_firstChapter],
      refreshedCatalog: const [_firstChapter, _secondChapter],
      refresh: refresh,
    );
    final harness = await _TransitionHarness.open(tester, client: client);

    harness.tts.completeUtterance();
    await _pumpUntil(tester, () => client.refreshCount == 1);
    await harness.session.stop();
    refresh.complete(const [_firstChapter, _secondChapter]);
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.controller.state, ReaderAloudPlaybackState.stopped);
    expect(harness.tts.spokenTexts, hasLength(1));
    expect(harness.controller.currentChapter?.id, _firstChapter.id);
    expect(
      find.textContaining('Second body.', findRichText: true),
      findsNothing,
    );
    await harness.stopPlayback();
  });

  testWidgets('a delayed catalog refresh cannot stop or move a newer target', (
    tester,
  ) async {
    final refresh = Completer<List<BookSourceChapter>>();
    final client = _TransitionClient(
      catalog: const [_firstChapter],
      refreshedCatalog: const [_firstChapter, _secondChapter],
      refresh: refresh,
    );
    final harness = await _TransitionHarness.open(tester, client: client);

    harness.tts.completeUtterance();
    await _pumpUntil(tester, () => client.refreshCount == 1);
    await harness.controller.playFromOffset(
      const ReaderAloudPosition(chapterIndex: 0, offset: 0),
    );
    await _pumpUntil(tester, () => harness.tts.spokenTexts.length == 2);
    refresh.complete(const [_firstChapter, _secondChapter]);
    await tester.pump(const Duration(milliseconds: 300));

    expect(harness.controller.state, ReaderAloudPlaybackState.playing);
    expect(harness.controller.currentChapter?.id, _firstChapter.id);
    expect(harness.tts.spokenTexts, hasLength(2));
    expect(
      find.textContaining('Second body.', findRichText: true),
      findsNothing,
    );
    await harness.stopPlayback();
  });

  testWidgets(
    'stop after catalog insertion preserves the visible chapter while next content is delayed',
    (tester) async {
      const inserted = BookSourceChapter(
        id: 'inserted-before',
        title: 'Inserted before',
        order: 1,
      );
      const shiftedFirst = BookSourceChapter(
        id: 'first',
        title: 'First',
        order: 2,
      );
      const appended = BookSourceChapter(
        id: 'delayed-next',
        title: 'Delayed next',
        order: 3,
      );
      final delayedContent = Completer<BookSourceChapterContent>();
      final client = _TransitionClient(
        catalog: const [_firstChapter],
        refreshedCatalog: const [inserted, shiftedFirst, appended],
        load: (id, _) async {
          if (id == appended.id) return delayedContent.future;
          return _chapterContent(
            id,
            id == _firstChapter.id ? 'First body.' : 'Body for $id.',
          );
        },
      );
      final harness = await _TransitionHarness.open(tester, client: client);

      harness.tts.completeUtterance();
      await _pumpUntil(tester, () => client.requests.contains(appended.id));
      expect(client.refreshCount, 1);
      expect(
        find.textContaining('First body.', findRichText: true),
        findsWidgets,
      );
      await harness.session.stop();
      delayedContent.complete(
        _chapterContent(appended.id, 'Delayed next body.'),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(harness.controller.state, ReaderAloudPlaybackState.stopped);
      expect(harness.controller.currentChapter?.id, _firstChapter.id);
      expect(harness.tts.spokenTexts, hasLength(1));
      expect(
        find.textContaining('First body.', findRichText: true),
        findsWidgets,
      );
      expect(
        find.textContaining('Delayed next body.', findRichText: true),
        findsNothing,
      );
      expect(harness.progress.saved.last.chapterId, _firstChapter.id);
      expect(harness.progress.saved.last.chapterIndex, 1);
      await harness.stopPlayback();
    },
  );

  testWidgets(
    'stopping read-aloud after reader disposal saves the prepared position',
    (tester) async {
      final client = _TransitionClient(
        catalog: const [_firstChapter],
        refreshedCatalog: const [_firstChapter],
      );
      final harness = await _TransitionHarness.open(tester, client: client);
      harness.tts.position = 4;
      final expectedProgress =
          harness.controller.currentOffset /
          harness.controller.currentChapter!.text.length;
      final requestsBeforeExit = List<String>.of(client.requests);
      final savesBeforeExit = harness.progress.saved.length;

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.session.stop();

      expect(client.requests, requestsBeforeExit);
      expect(harness.progress.saved.length, greaterThan(savesBeforeExit));
      expect(harness.progress.saved.last.chapterId, _firstChapter.id);
      expect(harness.progress.saved.last.chapterIndex, 0);
      expect(
        harness.progress.saved.last.chapterProgress,
        closeTo(expectedProgress, 0.0001),
      );
    },
  );

  testWidgets('an unchanged refreshed catalog stops once at the real end', (
    tester,
  ) async {
    final client = _TransitionClient(
      catalog: const [_firstChapter],
      refreshedCatalog: const [_firstChapter],
    );
    final harness = await _TransitionHarness.open(tester, client: client);

    await harness.completeCurrentUtterance();
    await _pumpUntil(
      tester,
      () => harness.controller.state == ReaderAloudPlaybackState.stopped,
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(client.refreshCount, 1);
    expect(harness.tts.spokenTexts, hasLength(1));
    expect(harness.controller.currentChapter?.id, _firstChapter.id);
    await harness.stopPlayback();
  });
}

class _TransitionHarness {
  _TransitionHarness({
    required this.tester,
    required this.client,
    required this.rules,
    required this.progress,
    required this.tts,
    required this.service,
    required this.session,
  });

  final WidgetTester tester;
  final _TransitionClient client;
  final ReplaceRuleService rules;
  final _MemoryProgress progress;
  final _ControlledTts tts;
  final ReaderAloudService service;
  final ReaderAloudSession session;

  ReaderAloudController get controller => session.controller!;

  static Future<_TransitionHarness> open(
    WidgetTester tester, {
    required _TransitionClient client,
    BookSourcePageMode pageMode = BookSourcePageMode.instantPage,
  }) async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.pageModeKey: pageMode.name,
      'reader_aloud_presentation': 'controls',
      'native_reader_txt_chapter_title_page_enabled': false,
    });
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const mediaChannel = MethodChannel('com.niki.xxread/reader_aloud');
    messenger.setMockMethodCallHandler(mediaChannel, (_) async => null);
    final progress = _MemoryProgress();
    final rules = ReplaceRuleService();
    final tts = _ControlledTts();
    final service = ReaderAloudService(
      systemEngine: tts,
      settingsStore: _SettingsStore(),
      bytesPlayer: _SilentPlayer(),
    );
    final session = ReaderAloudSession();
    final harness = _TransitionHarness(
      tester: tester,
      client: client,
      rules: rules,
      progress: progress,
      tts: tts,
      service: service,
      session: session,
    );
    addTearDown(() async {
      final pendingRefresh = client.refresh;
      if (pendingRefresh != null && !pendingRefresh.isCompleted) {
        pendingRefresh.complete(client.refreshedCatalog);
      }
      await harness.stopPlayback();
      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      service.dispose();
      tts.dispose();
      client.close();
      await rules.close();
      messenger.setMockMethodCallHandler(mediaChannel, null);
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
            progressStore: progress,
            paginationCacheDao: _NoDiskPagination(),
          ),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find
          .textContaining('First body.', findRichText: true)
          .evaluate()
          .isNotEmpty,
    );
    tester
        .widget<ReaderChromeOverlay>(find.byType(ReaderChromeOverlay))
        .onReadAloud!();
    await _pumpUntil(tester, () => tts.isPlaying);
    return harness;
  }

  Future<void> completeCurrentUtterance() async {
    tts.completeUtterance();
    await tester.pump();
  }

  Future<void> waitForChapter(String chapterId) => _pumpUntil(
    tester,
    () => controller.currentChapter?.id == chapterId && tts.isPlaying,
  );

  Future<void> stopPlayback() async {
    var stopped = false;
    final stopping = session.stop().then((_) => stopped = true);
    await _pumpUntil(tester, () => stopped);
    await stopping;
  }
}

class _TransitionClient extends BookSourceClient {
  _TransitionClient({
    required this.catalog,
    required this.refreshedCatalog,
    this.load,
    this.refresh,
  });

  final List<BookSourceChapter> catalog;
  final List<BookSourceChapter> refreshedCatalog;
  final Future<BookSourceChapterContent> Function(String id, bool refreshed)?
  load;
  final Completer<List<BookSourceChapter>>? refresh;
  final List<String> requests = [];
  int refreshCount = 0;

  @override
  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) async => catalog;

  @override
  Future<List<BookSourceChapter>> getChaptersForDownload(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    refreshCount++;
    return refresh?.future ?? refreshedCatalog;
  }

  @override
  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource source, {
    required String bookId,
    required String chapterId,
    Map<String, String> sourceVariables = const {},
    cancellation,
  }) {
    requests.add(chapterId);
    final callback = load;
    if (callback != null) return callback(chapterId, refreshCount > 0);
    return Future.value(
      _chapterContent(
        chapterId,
        chapterId == _firstChapter.id ? 'First body.' : 'Second body.',
      ),
    );
  }
}

class _ControlledTts extends TtsService {
  Completer<void>? _speech;
  final List<String> spokenTexts = [];
  int position = 0;

  @override
  Future<void> initialize({bool force = false}) async {}
  @override
  Future<void> ensureVoicesLoaded({bool force = false}) async {}
  @override
  bool get supportsQueuedText => false;
  @override
  bool get supportsContinuousText => false;
  @override
  bool get isPlaying => _speech != null;
  @override
  int get currentPosition => position;

  @override
  Future<void> speak(String text) async {
    spokenTexts.add(text);
    final speech = Completer<void>();
    _speech = speech;
    notifyListeners();
    await speech.future;
    if (identical(_speech, speech)) _speech = null;
  }

  void completeUtterance() {
    final speech = _speech;
    _speech = null;
    if (speech != null && !speech.isCompleted) speech.complete();
    notifyListeners();
  }

  @override
  Future<void> stop() async => completeUtterance();
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
  final List<BookSourceReadingProgress> saved = [];

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
  }) async => saved.add(progress);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var index = 0; index < 100; index++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (done()) return;
  }
  fail('Reader did not reach the expected state');
}

const _firstChapter = BookSourceChapter(id: 'first', title: 'First', order: 1);
const _secondChapter = BookSourceChapter(
  id: 'second',
  title: 'Second',
  order: 2,
);
const _book = BookSourceBook(
  id: 'transition-book',
  title: 'Transition test',
  author: '',
  description: '',
  categories: [],
);
final _source = RegisteredBookSource(
  id: 'transition.source',
  name: 'Transition',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.5',
  languages: const ['en'],
  capabilities: const {'catalog', 'content'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

BookSourceChapterContent _chapterContent(String id, String text) =>
    BookSourceChapterContent(
      bookId: _book.id,
      chapterId: id,
      title: '',
      content: text,
      contentType: 'text/plain',
    );
