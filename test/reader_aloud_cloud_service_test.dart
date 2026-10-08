import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/services/reader_aloud_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'late stop completion cannot clear the replacement sentence progress',
    () async {
      final player = _DelayedStopBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore()..type = ReaderAloudEngineType.cloud,
        cloudClient: _FakeCloudClient(),
        bytesPlayer: player,
      );
      addTearDown(service.dispose);
      await service.initialize();
      final old = service.speakQueued(['old'], onTextStarted: (_) {});
      await _flushQueue();
      final stopping = service.stop();
      final latest = service.speakQueued(['latest'], onTextStarted: (_) {});
      await _flushQueue();
      expect(service.currentPosition, 3);
      player.stopGate.complete();
      await stopping;
      await old;
      expect(service.currentPosition, 3);
      player.complete();
      await latest;
    },
  );

  test(
    'cloud queue prioritizes first audio and buffers four with two requests',
    () async {
      final client = _QueuedCloudClient();
      final player = _QueuedBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore()..type = ReaderAloudEngineType.cloud,
        cloudClient: client,
        bytesPlayer: player,
      );
      addTearDown(service.dispose);
      await service.initialize();
      expect(service.supportsQueuedText, isTrue);
      final started = <int>[];
      final playback = service.speakQueued([
        'first',
        'second',
        'third',
        'fourth',
        'fifth',
        'sixth',
      ], onTextStarted: started.add);
      await _flushQueue();
      expect(client.texts, ['first']);
      expect(started, isEmpty);
      client.complete(0);
      await _flushQueue();
      expect(player.audio, [
        [0],
      ]);
      expect(client.texts, ['first', 'second', 'third']);
      expect(client.maximumInFlight, 2);
      client.complete(2); // Out-of-order completion must not advance playback.
      await _flushQueue();
      expect(client.texts, ['first', 'second', 'third', 'fourth']);
      client.complete(3);
      await _flushQueue();
      expect(client.texts, ['first', 'second', 'third', 'fourth', 'fifth']);
      client.complete(4);
      await _flushQueue();
      expect(client.texts, hasLength(5)); // Bounded to four ahead of first.
      expect(started, [0]);
      client.complete(1);
      player.complete();
      await _flushQueue();
      expect(started, [0, 1]);
      expect(client.texts.last, 'sixth');
      client.complete(5);
      for (var index = 2; index < 6; index++) {
        player.complete();
        await _flushQueue();
        expect(started.last, index);
      }
      player.complete();
      await playback;
      expect(player.audio, [
        [0],
        [1],
        [2],
        [3],
        [4],
        [5],
      ]);
      expect(player.firstInQueue, [true, false, false, false, false, false]);
      expect(client.maximumInFlight, 2);
    },
  );

  for (final action in ['pause', 'stop']) {
    test(
      '$action invalidates pending cloud prefetch and prevents stale playback',
      () async {
        final client = _QueuedCloudClient();
        final player = _QueuedBytesPlayer();
        final service = ReaderAloudService(
          systemEngine: _FakeSystemEngine(),
          settingsStore: _FakeSettingsStore()
            ..type = ReaderAloudEngineType.cloud,
          cloudClient: client,
          bytesPlayer: player,
        );
        addTearDown(service.dispose);
        final started = <int>[];
        final playback = service.speakQueued([
          'first',
          'second',
          'third',
        ], onTextStarted: started.add);
        await _flushQueue();
        client.complete(0);
        await _flushQueue();
        expect(client.texts, ['first', 'second', 'third']);
        if (action == 'pause') {
          await service.pause();
        } else {
          await service.stop();
        }
        client.complete(1);
        client.complete(2);
        await playback;
        await _flushQueue();
        expect(started, [0]);
        expect(player.audio, [
          [0],
        ]);
        expect(client.texts, hasLength(3));
      },
    );
  }

  test(
    'prefetch failure is deferred and falls back only when its segment starts',
    () async {
      final system = _FakeSystemEngine();
      final client = _QueuedCloudClient();
      final player = _QueuedBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: system,
        settingsStore: _FakeSettingsStore()..type = ReaderAloudEngineType.cloud,
        cloudClient: client,
        bytesPlayer: player,
      );
      addTearDown(service.dispose);
      final started = <int>[];
      final playback = service.speakQueued([
        'first',
        'second',
      ], onTextStarted: started.add);
      await _flushQueue();
      client.complete(0);
      await _flushQueue();
      client.results[1].completeError(
        const ReaderAloudCloudException('failed', 'failed'),
      );
      await _flushQueue();
      expect(system.spoken, isEmpty);
      expect(service.cloudError, isNull);
      expect(started, [0]);
      player.complete();
      await playback;
      expect(system.spoken, ['second']);
      expect(player.audio, [
        [0],
      ]);
      expect(started, [0, 1]);
    },
  );

  test('failed synthesis does not announce an unplayable sentence', () async {
    final client = _QueuedCloudClient();
    final player = _QueuedBytesPlayer();
    final service = ReaderAloudService(
      systemEngine: _FakeSystemEngine(),
      settingsStore: _FakeSettingsStore()
        ..type = ReaderAloudEngineType.cloud
        ..settings = const ReaderAloudCloudSettings(fallbackToSystem: false),
      cloudClient: client,
      bytesPlayer: player,
    );
    addTearDown(service.dispose);
    final started = <int>[];
    final playback = service.speakQueued(['first'], onTextStarted: started.add);
    final failed = expectLater(
      playback,
      throwsA(isA<ReaderAloudCloudException>()),
    );
    await _flushQueue();
    client.results[0].completeError(
      const ReaderAloudCloudException('failed', 'failed'),
    );
    await failed;
    expect(started, isEmpty);
    expect(player.audio, isEmpty);
  });

  test(
    'repeated seeks share two request slots and only latest plays',
    () async {
      final client = _QueuedCloudClient();
      final player = _QueuedBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore()..type = ReaderAloudEngineType.cloud,
        cloudClient: client,
        bytesPlayer: player,
      );
      addTearDown(service.dispose);
      final old = service.speakQueued([
        'old',
        'ahead',
        'later',
      ], onTextStarted: (_) {});
      await _flushQueue();
      client.complete(0);
      await _flushQueue();
      expect(client.texts, ['old', 'ahead', 'later']);
      await service.stop();
      final superseded = service.speakQueued([
        'superseded',
      ], onTextStarted: (_) {});
      await _flushQueue();
      await service.stop();
      final started = <int>[];
      final latest = service.speakQueued([
        'latest',
      ], onTextStarted: started.add);
      await _flushQueue();
      expect(client.texts, hasLength(3));
      client.complete(1);
      await _flushQueue();
      expect(client.texts, ['old', 'ahead', 'later', 'latest']);
      client.complete(2);
      client.complete(3);
      await _flushQueue();
      expect(started, [0]);
      expect(player.audio, [
        [0],
        [3],
      ]);
      player.complete();
      await Future.wait([old, superseded, latest]);
      expect(client.maximumInFlight, 2);
    },
  );

  for (final action in ['stop', 'pause', 'new queue', 'dispose']) {
    test(
      '$action cancels real cloud response streams without stale fallback',
      () async {
        final adapter = _CancellableStreamAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        final system = _FakeSystemEngine();
        final player = _QueuedBytesPlayer();
        final service = ReaderAloudService(
          systemEngine: system,
          settingsStore: _FakeSettingsStore()
            ..type = ReaderAloudEngineType.cloud,
          cloudClient: OpenAiCompatibleReaderAloudCloudClient(dio: dio),
          bytesPlayer: player,
        );
        if (action != 'dispose') addTearDown(service.dispose);
        final started = <int>[];
        final old = service.speakQueued([
          'first',
          'ahead',
          'later',
        ], onTextStarted: started.add);
        await adapter.prefetchStarted.future.timeout(
          const Duration(seconds: 2),
        );
        expect(adapter.texts, ['first', 'ahead', 'later']);
        expect(adapter.listening, [true, true, true]);
        expect(started, [0]);
        Future<void>? latest;
        if (action == 'dispose') {
          service.dispose();
          player.complete();
        } else if (action == 'pause') {
          await service.pause();
        } else if (action == 'stop') {
          await service.stop();
        } else {
          // The controller stops the old player before starting the new queue.
          player.complete();
          latest = service.speakQueued(['latest'], onTextStarted: (_) {});
        }
        await _flushQueue();
        expect(adapter.cancelled, containsAll([1, 2]));
        expect(system.spoken, isEmpty);
        expect(service.cloudError, isNull);
        if (action != 'dispose') {
          latest ??= service.speakQueued(['latest'], onTextStarted: (_) {});
          await adapter.latestRequested.future.timeout(
            const Duration(seconds: 2),
          );
          // Neither abandoned response body has been finished by the test.
          // Cancellation frees both slots before the provider's 90s timeout.
          expect(adapter.texts.last, 'latest');
          final played = player.waitForNextPlayback();
          adapter.complete(3);
          await played.timeout(const Duration(seconds: 2));
          expect(player.audio, [
            [0],
            [3],
          ]);
          player.complete();
          await latest;
        }
        await old;
        expect(system.spoken, isEmpty);
      },
    );
  }

  test(
    'tap to seek defaults off and persists independently of page following',
    () async {
      final service = ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore(),
        bytesPlayer: _FakeBytesPlayer(),
      );
      addTearDown(service.dispose);
      await service.initialize();
      expect(service.tapToSeek, isFalse);
      await service.setTapToSeek(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reader_aloud_tap_to_seek'), isTrue);
      expect(service.followPageTurns, isFalse);
      final restored = ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore(),
        bytesPlayer: _FakeBytesPlayer(),
      );
      addTearDown(restored.dispose);
      await restored.initialize();
      expect(restored.tapToSeek, isTrue);
      await restored.setTapToSeek(false);
      expect(prefs.getBool('reader_aloud_tap_to_seek'), isFalse);
    },
  );

  test(
    'new voice and speed queue does not reuse audio from cancelled prefetch',
    () async {
      final system = _FakeSystemEngine();
      final client = _QueuedCloudClient();
      final player = _QueuedBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: system,
        settingsStore: _FakeSettingsStore()..type = ReaderAloudEngineType.cloud,
        cloudClient: client,
        bytesPlayer: player,
      );
      addTearDown(service.dispose);
      final old = service.speakQueued([
        'first',
        'second',
      ], onTextStarted: (_) {});
      await _flushQueue();
      client.complete(0);
      await _flushQueue();
      await service.stop();
      await service.updateCloudSettings(
        const ReaderAloudCloudSettings(voice: 'nova'),
      );
      system.speechRateValue = 1;
      final next = service.speakQueued(['second'], onTextStarted: (_) {});
      await _flushQueue();
      expect(client.texts, ['first', 'second', 'second']);
      expect(client.voices, ['alloy', 'alloy', 'nova']);
      expect(client.speeds, [1, 1, 2]);
      client.complete(1);
      client.complete(2);
      await _flushQueue();
      expect(player.audio, [
        [0],
        [2],
      ]);
      player.complete();
      await Future.wait([old, next]);
    },
  );

  test(
    'named voices migrate legacy settings and keep keys isolated after restart',
    () async {
      final secrets = _FakeSecretStorage();
      final store = PreferencesReaderAloudCloudSettingsStore(
        secretStorage: secrets,
      );
      await store.saveSettings(const ReaderAloudCloudSettings(voice: 'legacy'));
      await store.writeApiKey('legacy-secret');
      final system = _FakeSystemEngine();
      final client = _FakeCloudClient();
      final service = ReaderAloudService(
        systemEngine: system,
        settingsStore: store,
        cloudClient: client,
        bytesPlayer: _FakeBytesPlayer(),
      );
      addTearDown(service.dispose);
      await service.initialize();
      expect(service.cloudProfiles.single.settings.voice, 'legacy');
      await service.saveCloudProfile(
        const ReaderAloudCloudProfile(
          id: 'second',
          name: 'Narrator',
          settings: ReaderAloudCloudSettings(
            baseUrl: 'https://second.example/v1',
            voice: 'nova',
          ),
        ),
        apiKey: 'second-secret',
      );
      expect(service.activeProfileId, 'default');
      expect(service.cloudProfiles, hasLength(2));
      await service.selectCloudProfile('second');
      await service.setEngineType(ReaderAloudEngineType.cloud);
      await service.speak('第二个音色');
      expect(client.keys.last, 'second-secret');
      expect(client.settings.last.voice, 'nova');
      final restarted = ReaderAloudService(
        systemEngine: system,
        settingsStore: store,
        cloudClient: client,
        bytesPlayer: _FakeBytesPlayer(),
      );
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.activeProfileId, 'second');
      expect(restarted.cloudSettings.voice, 'nova');
      await restarted.selectCloudProfile('default');
      await restarted.speak('原有音色');
      expect(client.keys.last, 'legacy-secret');
      expect(client.settings.last.voice, 'legacy');
      await restarted.deleteCloudProfile('second');
      expect(await store.readProfileKey('second'), isNull);
      expect(await store.readProfileKey('default'), 'legacy-secret');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('reader_aloud_cloud_profiles_v1'),
        isNot(contains('secret')),
      );
    },
  );

  test('failed profile save restores the previous credential', () async {
    final store = _FailingProfileStore();
    final service = ReaderAloudService(
      systemEngine: _FakeSystemEngine(),
      settingsStore: store,
      bytesPlayer: _FakeBytesPlayer(),
    );
    addTearDown(service.dispose);
    await service.initialize();
    await expectLater(
      service.saveCloudProfile(
        const ReaderAloudCloudProfile(
          id: 'default',
          name: 'replacement',
          settings: ReaderAloudCloudSettings(
            baseUrl: 'https://replacement.example/v1',
          ),
        ),
        apiKey: 'replacement-key',
      ),
      throwsStateError,
    );
    expect(store.apiKey, 'test-key');
    expect(service.cloudSettings.baseUrl, 'https://api.openai.com/v1');
  });

  test(
    'draft preview uses 2x without saving, switching engines or fallback',
    () async {
      final system = _FakeSystemEngine()..speechRateValue = 1;
      final store = _FakeSettingsStore();
      final client = _FakeCloudClient();
      final player = _FakeBytesPlayer();
      final previewPlayer = _FakeBytesPlayer();
      final service = ReaderAloudService(
        systemEngine: system,
        settingsStore: store,
        cloudClient: client,
        bytesPlayer: player,
        previewPlayerFactory: () => previewPlayer,
      );
      addTearDown(service.dispose);
      await service.previewCloudVoice(
        settings: const ReaderAloudCloudSettings(voice: 'draft'),
        apiKey: 'draft-key',
        text: '试听短文',
      );
      expect(client.settings.single.voice, 'draft');
      expect(client.keys.single, 'draft-key');
      expect(client.speeds.single, 2.0);
      expect(previewPlayer.played, 1);
      expect(player.played, 0);
      expect(system.spoken, isEmpty);
      expect(service.engineType, ReaderAloudEngineType.system);
      expect(store.settings.voice, 'alloy');
      expect(store.apiKey, 'test-key');
    },
  );

  test('new draft never borrows the active profile key', () async {
    final client = _FakeCloudClient();
    final service = ReaderAloudService(
      systemEngine: _FakeSystemEngine(),
      settingsStore: _FakeSettingsStore(),
      cloudClient: client,
      bytesPlayer: _FakeBytesPlayer(),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.previewCloudVoice(
        settings: const ReaderAloudCloudSettings(),
        text: 'preview',
        useSavedKey: false,
      ),
      throwsA(isA<ReaderAloudCloudException>()),
    );
    expect(client.calls, 0);
  });

  test('failed preview never substitutes a system voice', () async {
    final system = _FakeSystemEngine();
    final service = ReaderAloudService(
      systemEngine: system,
      settingsStore: _FakeSettingsStore(),
      cloudClient: _FakeCloudClient(fail: true),
      bytesPlayer: _FakeBytesPlayer(),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.previewCloudVoice(
        settings: const ReaderAloudCloudSettings(),
        text: 'preview',
      ),
      throwsA(isA<ReaderAloudCloudException>()),
    );
    expect(system.spoken, isEmpty);
  });

  test('closing a preview prevents late synthesis from playing', () async {
    final client = _PendingCloudClient();
    final player = _FakeBytesPlayer();
    final service = ReaderAloudService(
      systemEngine: _FakeSystemEngine(),
      settingsStore: _FakeSettingsStore(),
      cloudClient: client,
      bytesPlayer: _FakeBytesPlayer(),
      previewPlayerFactory: () => player,
    );
    addTearDown(service.dispose);
    final preview = service.previewCloudVoice(
      settings: const ReaderAloudCloudSettings(),
      text: 'preview',
    );
    await client.started.future;
    await service.stopPreview();
    client.complete();
    await preview;
    expect(player.played, 0);
  });

  test(
    'listening presentation defaults to full player and persists controls mode',
    () async {
      ReaderAloudService makeService() => ReaderAloudService(
        systemEngine: _FakeSystemEngine(),
        settingsStore: _FakeSettingsStore(),
        bytesPlayer: _FakeBytesPlayer(),
      );
      final first = makeService();
      addTearDown(first.dispose);
      await first.initialize();
      expect(first.presentation, ReaderAloudPresentation.player);
      await first.setPresentation(ReaderAloudPresentation.controls);
      final second = makeService();
      addTearDown(second.dispose);
      await second.initialize();
      expect(second.presentation, ReaderAloudPresentation.controls);
    },
  );

  test('cloud endpoint requires HTTPS except for localhost', () {
    expect(
      () => readerAloudCloudEndpoint('http://tts.example.com/v1'),
      throwsA(
        isA<ReaderAloudCloudException>().having(
          (error) => error.code,
          'code',
          'insecure_base_url',
        ),
      ),
    );
    expect(
      readerAloudCloudEndpoint('http://localhost:8080/v1/audio/speech'),
      Uri.parse('http://localhost:8080/v1/audio/speech'),
    );
  });

  test('API key is stored separately from non-secret preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final secrets = _FakeSecretStorage();
    final store = PreferencesReaderAloudCloudSettingsStore(
      preferences: preferences,
      secretStorage: secrets,
    );

    await store.saveSettings(
      const ReaderAloudCloudSettings(
        baseUrl: 'https://tts.example.com/v1/',
        model: 'voice-model',
        voice: 'reader',
      ),
    );
    await store.writeApiKey(' secret-key ');

    expect(await store.readApiKey(), 'secret-key');
    expect(secrets.values.values, contains('secret-key'));
    expect(
      preferences.getKeys(),
      isNot(contains('reader_aloud_cloud_api_key')),
    );
    expect((await store.loadSettings()).baseUrl, 'https://tts.example.com/v1');
  });

  test(
    'OpenAI-compatible client sends bounded authenticated audio request',
    () async {
      late RequestOptions request;
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = options;
              handler.resolve(
                Response<ResponseBody>(
                  requestOptions: options,
                  statusCode: 200,
                  data: ResponseBody.fromBytes([1, 2, 3], 200),
                ),
              );
            },
          ),
        );
      final client = OpenAiCompatibleReaderAloudCloudClient(
        dio: dio,
        maxResponseBytes: 8,
      );

      final bytes = await client.synthesize(
        settings: const ReaderAloudCloudSettings(
          baseUrl: 'https://tts.example.com/v1',
          model: 'voice-model',
          voice: 'reader',
        ),
        apiKey: 'secret',
        text: '你好。',
        speed: 1,
      );

      expect(bytes, [1, 2, 3]);
      expect(request.uri.path, '/v1/audio/speech');
      expect(request.headers['Authorization'], 'Bearer secret');
      expect(request.data, containsPair('input', '你好。'));
      expect(request.responseType, ResponseType.stream);
      expect(request.followRedirects, isFalse);
    },
  );

  test('cloud audio is cached and reused for the same sentence', () async {
    final system = _FakeSystemEngine();
    final client = _FakeCloudClient();
    final player = _FakeBytesPlayer();
    final service = ReaderAloudService(
      systemEngine: system,
      settingsStore: _FakeSettingsStore(),
      cloudClient: client,
      bytesPlayer: player,
    );
    addTearDown(service.dispose);

    await service.setEngineType(ReaderAloudEngineType.cloud);
    await service.speak('同一句。');
    await service.speak('同一句。');

    expect(client.calls, 1);
    expect(player.played, 2);
    expect(system.spoken, isEmpty);
  });

  test('changed speech rate produces fresh cloud audio immediately', () async {
    final system = _FakeSystemEngine();
    final client = _FakeCloudClient();
    final service = ReaderAloudService(
      systemEngine: system,
      settingsStore: _FakeSettingsStore(),
      cloudClient: client,
      bytesPlayer: _FakeBytesPlayer(),
    );
    addTearDown(service.dispose);

    await service.setEngineType(ReaderAloudEngineType.cloud);
    await service.speak('调速句子。');
    system.speechRateValue = 1;
    await service.speak('调速句子。');

    expect(client.calls, 2);
    expect(client.speeds, [1.0, 2.0]);
  });

  test('cloud failure falls back to the system engine when enabled', () async {
    final system = _FakeSystemEngine();
    final service = ReaderAloudService(
      systemEngine: system,
      settingsStore: _FakeSettingsStore(),
      cloudClient: _FakeCloudClient(fail: true),
      bytesPlayer: _FakeBytesPlayer(),
    );
    addTearDown(service.dispose);

    await service.setEngineType(ReaderAloudEngineType.cloud);
    await service.speak('回退句子。');

    expect(system.spoken, ['回退句子。']);
    expect(service.activeEngineType, ReaderAloudEngineType.system);
    expect(service.cloudError, isNotNull);
  });

  test('stopping during cloud synthesis never starts stale audio', () async {
    final system = _FakeSystemEngine();
    final client = _PendingCloudClient();
    final player = _FakeBytesPlayer();
    final service = ReaderAloudService(
      systemEngine: system,
      settingsStore: _FakeSettingsStore(),
      cloudClient: client,
      bytesPlayer: player,
    );
    addTearDown(service.dispose);

    await service.setEngineType(ReaderAloudEngineType.cloud);
    final speaking = service.speak('取消的句子。');
    await client.started.future;
    await service.stop();
    client.complete();
    await speaking;

    expect(player.played, 0);
    expect(system.spoken, isEmpty);
  });
}

class _FakeSecretStorage implements ReaderAloudSecretStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakeSettingsStore implements ReaderAloudCloudSettingsStore {
  ReaderAloudEngineType type = ReaderAloudEngineType.system;
  ReaderAloudCloudSettings settings = const ReaderAloudCloudSettings();
  String? apiKey = 'test-key';

  @override
  Future<void> clearApiKey() async => apiKey = null;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<ReaderAloudEngineType> loadEngineType() async => type;

  @override
  Future<ReaderAloudCloudSettings> loadSettings() async => settings;

  @override
  Future<void> saveEngineType(ReaderAloudEngineType type) async {
    this.type = type;
  }

  @override
  Future<void> saveSettings(ReaderAloudCloudSettings settings) async {
    this.settings = settings;
  }

  @override
  Future<void> writeApiKey(String apiKey) async => this.apiKey = apiKey;
}

class _FakeCloudClient implements ReaderAloudCloudClient {
  _FakeCloudClient({this.fail = false});

  final bool fail;
  int calls = 0;
  final List<double> speeds = [];
  final List<String> keys = [];
  final List<ReaderAloudCloudSettings> settings = [];

  @override
  Future<Uint8List> synthesize({
    required ReaderAloudCloudSettings settings,
    required String apiKey,
    required String text,
    required double speed,
  }) async {
    calls++;
    speeds.add(speed);
    keys.add(apiKey);
    this.settings.add(settings);
    if (fail) {
      throw const ReaderAloudCloudException('failed', '云端失败');
    }
    return Uint8List.fromList([1, 2, 3]);
  }
}

class _PendingCloudClient implements ReaderAloudCloudClient {
  final Completer<void> started = Completer<void>();
  final Completer<Uint8List> _result = Completer<Uint8List>();

  void complete() => _result.complete(Uint8List.fromList([1, 2, 3]));

  @override
  Future<Uint8List> synthesize({
    required ReaderAloudCloudSettings settings,
    required String apiKey,
    required String text,
    required double speed,
  }) {
    started.complete();
    return _result.future;
  }
}

class _FakeBytesPlayer extends ChangeNotifier
    implements ReaderAloudBytesPlayer {
  int played = 0;

  @override
  Duration get duration => const Duration(seconds: 1);

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Duration get position => duration;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) async {
    played++;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}

class _FakeSystemEngine extends ChangeNotifier
    implements ReaderAloudAdjustableEngine {
  final List<String> spoken = [];
  double speechRateValue = 0.5;

  @override
  int get currentPosition => 0;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  double get speechRate => speechRateValue;

  @override
  double get speechVolume => 1;

  @override
  Future<void> pause() async {}

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

class _FailingProfileStore extends _FakeSettingsStore
    implements ReaderAloudProfileStore {
  @override
  Future<String> loadActiveProfileId() async => 'default';
  @override
  Future<List<ReaderAloudCloudProfile>> loadProfiles() async => [
    ReaderAloudCloudProfile(
      id: 'default',
      name: 'Original',
      settings: settings,
    ),
  ];
  @override
  Future<void> saveProfiles(
    List<ReaderAloudCloudProfile> profiles,
    String activeId,
  ) async {
    throw StateError('Storage full');
  }

  @override
  Future<String?> readProfileKey(String id) async => apiKey;
  @override
  Future<void> writeProfileKey(String id, String? key) async {
    apiKey = key;
  }
}

Future<void> _flushQueue() => Future<void>.delayed(Duration.zero);

class _QueuedCloudClient implements ReaderAloudCloudClient {
  int inFlight = 0;
  int maximumInFlight = 0;
  final texts = <String>[];
  final voices = <String>[];
  final speeds = <double>[];
  final results = <Completer<Uint8List>>[];
  void complete(int index) =>
      results[index].complete(Uint8List.fromList([index]));
  @override
  Future<Uint8List> synthesize({
    required ReaderAloudCloudSettings settings,
    required String apiKey,
    required String text,
    required double speed,
  }) {
    texts.add(text);
    voices.add(settings.voice);
    speeds.add(speed);
    final result = Completer<Uint8List>();
    results.add(result);
    inFlight++;
    if (inFlight > maximumInFlight) maximumInFlight = inFlight;
    return result.future.whenComplete(() => inFlight--);
  }
}

class _QueuedBytesPlayer extends _FakeBytesPlayer
    implements ReaderAloudQueuedBytesPlayer {
  final audio = <List<int>>[];
  final firstInQueue = <bool>[];
  Completer<void>? active;
  Completer<void>? _nextPlayback;
  Future<void> waitForNextPlayback() {
    _nextPlayback = Completer<void>();
    return _nextPlayback!.future;
  }

  void complete() {
    final value = active;
    if (value != null && !value.isCompleted) value.complete();
  }

  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) {
    audio.add(bytes.toList());
    _nextPlayback?.complete();
    _nextPlayback = null;
    active = Completer<void>();
    return active!.future;
  }

  @override
  Future<void> playNext(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
    required bool firstInQueue,
  }) {
    this.firstInQueue.add(firstInQueue);
    return play(bytes, mimeType: mimeType, volume: volume);
  }

  @override
  Future<void> pause() async => complete();
  @override
  Future<void> stop() async => complete();
}

class _DelayedStopBytesPlayer extends _QueuedBytesPlayer {
  final stopGate = Completer<void>();
  @override
  Duration get duration => const Duration(seconds: 1);
  @override
  Duration get position => const Duration(milliseconds: 500);
  @override
  Future<void> stop() async {
    complete();
    await stopGate.future;
  }
}

class _CancellableStreamAdapter implements HttpClientAdapter {
  final texts = <String>[];
  final bodies = <StreamController<Uint8List>>[];
  final listening = <bool>[];
  final cancelled = <int>[];
  final prefetchStarted = Completer<void>();
  final latestRequested = Completer<void>();

  void complete(int index) {
    bodies[index].add(Uint8List.fromList([index]));
    unawaited(bodies[index].close());
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = texts.length;
    texts.add(options.data['input'] as String);
    if (index == 3) latestRequested.complete();
    listening.add(false);
    final body = StreamController<Uint8List>(
      onListen: () {
        listening[index] = true;
        if (index == 2) prefetchStarted.complete();
      },
      onCancel: () => cancelled.add(index),
    );
    bodies.add(body);
    if (index == 0) complete(index);
    return ResponseBody(
      body.stream,
      200,
      headers: {
        Headers.contentTypeHeader: ['audio/mpeg'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
