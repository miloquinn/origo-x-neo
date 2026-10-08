import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/reader_aloud_service.dart';

void main() {
  test(
    'creating a cloud or preview player does not change the shared session',
    () {
      final native = _Player();
      final player = AudioplayersReaderAloudBytesPlayer(player: native);
      addTearDown(player.dispose);
      expect(native.contexts, isEmpty);
    },
  );

  test('cloud playback restores nonmixable playback after a preview', () async {
    final session = _Session();
    final native = _Player(session: session);
    final previewNative = _Player(session: session);
    final player = AudioplayersReaderAloudBytesPlayer(player: native);
    final preview = AudioplayersReaderAloudBytesPlayer(player: previewNative);
    addTearDown(player.dispose);
    addTearDown(preview.dispose);

    await _play(player);
    await _play(preview);
    // Another plugin changed the process-global policy while our player was idle.
    session.context = AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    );
    await _play(player);

    expect(native.contexts, hasLength(2));
    expect(previewNative.contexts, hasLength(1));
    for (final context in [
      ...native.playedContexts,
      ...previewNative.playedContexts,
    ]) {
      expect(context.category, AVAudioSessionCategory.playback);
      expect(context.options, isEmpty);
    }
    expect(native.volumes, [0.6, 0.6]);
    expect(player.isPlaying, isFalse);
  });

  test(
    'adjacent queued sentences reuse session without redundant stops',
    () async {
      final native = _Player();
      final player = AudioplayersReaderAloudBytesPlayer(player: native);
      addTearDown(player.dispose);
      for (var index = 0; index < 3; index++) {
        await player.playNext(
          Uint8List.fromList([index]),
          mimeType: 'audio/mpeg',
          volume: 0.6,
          firstInQueue: index == 0,
        );
      }
      expect(native.contexts, hasLength(1));
      expect(native.playedContexts, hasLength(3));
      expect(native.stops, 0);
      await player.stop();
      await player.playNext(
        Uint8List.fromList([4]),
        mimeType: 'audio/mpeg',
        volume: 0.6,
        firstInQueue: true,
      );
      expect(native.contexts, hasLength(2));
      expect(native.stops, 1);
    },
  );

  for (final action in ['stop', 'pause', 'dispose']) {
    test('$action during session setup cancels late playback', () async {
      final gate = Completer<void>();
      final native = _Player(contextGate: gate);
      final player = AudioplayersReaderAloudBytesPlayer(player: native);
      if (action != 'dispose') addTearDown(player.dispose);
      final playing = _play(player);
      await native.contextStarted.future;
      if (action == 'dispose') {
        player.dispose();
      } else if (action == 'pause') {
        await player.pause();
      } else {
        await player.stop();
      }
      gate.complete();
      await playing;
      expect(native.playedContexts, isEmpty);
      expect(player.isPlaying, isFalse);
    });
  }

  test('session setup failure is reported and can be retried', () async {
    final native = _Player()..failContext = true;
    final player = AudioplayersReaderAloudBytesPlayer(player: native);
    addTearDown(player.dispose);
    await expectLater(_play(player), throwsStateError);
    expect(native.playedContexts, isEmpty);
    expect(player.isPlaying, isFalse);
    native.failContext = false;
    await _play(player);
    expect(native.playedContexts, hasLength(1));
  });
  test('a late pause response cannot pause replacement audio', () async {
    final gate = Completer<void>();
    final native = _Player(pauseGate: gate, completeOnPlay: false);
    final player = AudioplayersReaderAloudBytesPlayer(player: native);
    addTearDown(player.dispose);
    final old = _play(player);
    await Future<void>.delayed(Duration.zero);
    expect(player.isPlaying, isTrue);
    final paused = player.pause();
    final latest = _play(player);
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await paused;
    await old;
    expect(player.isPlaying, isTrue);
    expect(player.isPaused, isFalse);
    native.complete();
    await latest;
  });
}

Future<void> _play(AudioplayersReaderAloudBytesPlayer player) => player.play(
  Uint8List.fromList([1, 2, 3]),
  mimeType: 'audio/mpeg',
  volume: 0.6,
);

class _Session {
  AudioContextIOS? context;
}

class _Player implements AudioPlayer {
  _Player({
    _Session? session,
    this.contextGate,
    this.pauseGate,
    this.completeOnPlay = true,
  }) : session = session ?? _Session();

  final _Session session;
  final Completer<void>? contextGate;
  final Completer<void>? pauseGate;
  final bool completeOnPlay;
  final contextStarted = Completer<void>();
  final contexts = <AudioContext>[];
  final playedContexts = <AudioContextIOS>[];
  final volumes = <double?>[];
  final _completed = StreamController<void>.broadcast();
  bool failContext = false;
  int stops = 0;

  @override
  Stream<Duration> get onPositionChanged => const Stream.empty();
  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();
  @override
  Stream<void> get onPlayerComplete => _completed.stream;

  @override
  Future<void> setAudioContext(AudioContext context) async {
    contexts.add(context);
    if (!contextStarted.isCompleted) contextStarted.complete();
    await contextGate?.future;
    if (failContext) throw StateError('Session unavailable');
    session.context = context.iOS;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    playedContexts.add(session.context!);
    volumes.add(volume);
    if (completeOnPlay) complete();
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> pause() async {
    await pauseGate?.future;
  }

  void complete() => _completed.add(null);
  @override
  Future<void> dispose() => _completed.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
