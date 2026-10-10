import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/reader_aloud_session.dart';
import 'package:xxread/services/reading/reading_activity_recorder.dart';

void main() {
  final firstRead = DateTime.utc(2026, 10, 10, 1);

  test(
    'binding alone and unsaved trial reading do not write activity',
    () async {
      final dao = _ActivityDao();
      final recorder = ReadingActivityRecorder(
        bookDao: dao,
        now: () => firstRead,
      );
      await recorder.bindBook(7);
      expect(dao.events, isEmpty);
      await recorder.bindBook(null);
      await recorder.markContentReady();
      expect(dao.events, isEmpty);
    },
  );

  test('trial added later retains its first successful reading time', () async {
    final dao = _ActivityDao();
    var now = firstRead;
    final recorder = ReadingActivityRecorder(bookDao: dao, now: () => now);
    await recorder.markContentReady();
    now = now.add(const Duration(hours: 2));
    await recorder.bindBook(7);
    await recorder.markContentReady(bookId: 7);
    expect(dao.events, [(bookId: 7, at: firstRead)]);
  });

  test(
    'concurrent readiness, reflow and resume write once per session',
    () async {
      final dao = _ActivityDao()..pending = Completer<void>();
      final recorder = ReadingActivityRecorder(
        bookDao: dao,
        now: () => firstRead,
      );
      final ready = recorder.markContentReady(bookId: 7);
      final repeated = recorder.markContentReady(bookId: 7);
      final boundAgain = recorder.bindBook(7);
      expect(dao.events, hasLength(1));
      dao.pending!.complete();
      await Future.wait([ready, repeated, boundAgain]);
      await recorder.markContentReady(bookId: 7);
      expect(dao.events, hasLength(1));
      await ReadingActivityRecorder(
        bookDao: dao,
        now: () => firstRead,
      ).markContentReady(bookId: 7);
      expect(dao.events, hasLength(2));
    },
  );

  test(
    'storage failure is nonfatal and retry preserves reading time',
    () async {
      final dao = _ActivityDao()..fail = true;
      final recorder = ReadingActivityRecorder(
        bookDao: dao,
        now: () => firstRead,
      );
      await recorder.markContentReady(bookId: 7);
      dao.fail = false;
      await recorder.bindBook(7);
      expect(dao.events, [
        (bookId: 7, at: firstRead),
        (bookId: 7, at: firstRead),
      ]);
    },
  );

  test(
    'TTS preparation and failed speech do not record recent reading',
    () async {
      final dao = _ActivityDao();
      final engine = _HeldEngine();
      final session = ReaderAloudSession();
      final controller = session.acquire(
        sourceId: 'local:7',
        shelfBookId: 7,
        readingActivity: ReadingActivityRecorder(
          bookDao: dao,
          now: () => firstRead,
        ),
        create: () => _controller(engine),
      );
      unawaited(controller.start());
      await _flush();
      expect(controller.state, ReaderAloudPlaybackState.playing);
      expect(engine.isPlaying, isFalse);
      expect(dao.events, isEmpty);
      engine.failPreparation();
      await _flush();
      expect(controller.state, ReaderAloudPlaybackState.error);
      expect(dao.events, isEmpty);
      session.dispose();
      engine.dispose();
    },
  );

  test('TTS records actual playing once and shares reader readiness', () async {
    final dao = _ActivityDao();
    final engine = _HeldEngine();
    final activity = ReadingActivityRecorder(
      bookDao: dao,
      now: () => firstRead,
    );
    final session = ReaderAloudSession();
    final controller = session.acquire(
      sourceId: 'local:7',
      shelfBookId: 7,
      readingActivity: activity,
      create: () => _controller(engine),
    );
    unawaited(controller.start());
    await _flush();
    engine.beginPlayback();
    await _flush();
    expect(dao.events, [(bookId: 7, at: firstRead)]);
    await activity.markContentReady(bookId: 7);
    engine.beginPlayback();
    await _flush();
    expect(dao.events, hasLength(1));
    await controller.stop();
    session.dispose();
    engine.dispose();
  });
}

Future<void> _flush() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ReaderAloudController _controller(_HeldEngine engine) => ReaderAloudController(
  engine: engine,
  source: CallbackReaderAloudSource(
    bookTitle: 'Reading activity',
    chapterCount: () => 1,
    currentPosition: () async =>
        const ReaderAloudPosition(chapterIndex: 0, offset: 0),
    loadChapter: (_) async => const ReaderAloudChapter(
      index: 0,
      id: 'one',
      title: 'One',
      text: 'Actual speech.',
    ),
    revealPosition: (_) async {},
    persistPosition: (_) async {},
  ),
);

class _ActivityDao extends BookDao {
  final events = <({int bookId, DateTime? at})>[];
  Completer<void>? pending;
  bool fail = false;

  @override
  Future<void> markRead(int bookId, {DateTime? at}) async {
    events.add((bookId: bookId, at: at));
    if (fail) throw StateError('storage unavailable');
    await pending?.future;
  }
}

class _HeldEngine extends ChangeNotifier implements ReaderAloudEngine {
  Completer<void>? _speech;
  bool _playing = false;
  @override
  bool get isPlaying => _playing;
  @override
  bool get isPaused => false;
  @override
  int get currentPosition => 0;
  @override
  Future<void> speak(String text) => (_speech = Completer<void>()).future;

  void beginPlayback() {
    _playing = true;
    notifyListeners();
  }

  void failPreparation() => _speech!.completeError(StateError('speech failed'));

  @override
  Future<void> pause() => stop();
  @override
  Future<void> stop() async {
    _playing = false;
    if (_speech != null && !_speech!.isCompleted) _speech!.complete();
    notifyListeners();
  }
}
