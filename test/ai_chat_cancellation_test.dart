import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancelled chat does not load settings or start HTTP', () async {
    final store = _SettingsStore();
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final service = ReaderHttpAIService(dio: dio, settingsStore: store);
    final token = CancelToken()..cancel('stop');

    await expectLater(_chat(service, token), throwsA(_cancelled));

    expect(store.loads, 0);
    expect(adapter.requests, 0);
  });

  test('stop during settings lookup never reaches HTTP', () async {
    final store = _SettingsStore()..pending = Completer<AIProviderSettings>();
    final adapter = _PendingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final service = ReaderHttpAIService(dio: dio, settingsStore: store);
    final token = CancelToken();
    final result = _chat(service, token);
    await store.started.future;
    final cancelled = expectLater(result, throwsA(_cancelled));

    token.cancel('stop');
    store.pending!.complete(_settings);
    await cancelled;

    expect(adapter.requests, 0);
  });

  test(
    'stop cancels the in-flight Dio transport and rejects its late reply',
    () async {
      final adapter = _PendingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final service = ReaderHttpAIService(
        dio: dio,
        settingsStore: _SettingsStore(),
      );
      final token = CancelToken();
      final result = _chat(service, token);
      await adapter.started.future;
      final cancelled = expectLater(result, throwsA(_cancelled));

      token.cancel('stop');
      await cancelled;
      await adapter.cancelled.future;
      adapter.reply();

      expect(adapter.requests, 1);
      expect(token.isCancelled, isTrue);
    },
  );
}

final _cancelled = isA<DioException>().having(
  CancelToken.isCancel,
  'cancellation is preserved',
  true,
);

const _settings = AIProviderSettings(
  provider: AIProviderType.openai,
  apiKey: 'test-key',
  baseUrl: 'https://example.test/v1',
  model: 'test-model',
  temperature: 0.7,
);

Future<String> _chat(AIService service, CancelToken token) => service.chat(
  history: const [AIChatMessage(role: 'user', content: '推荐一本书')],
  pageText: '',
  meta: const AIRequestMeta(bookId: '', chapterId: 'cancel-test'),
  cancelToken: token,
);

class _SettingsStore implements AISettingsStore {
  int loads = 0;
  final started = Completer<void>();
  Completer<AIProviderSettings>? pending;

  @override
  Future<AIProviderSettings> load([AIProviderType? provider]) async {
    loads++;
    if (!started.isCompleted) started.complete();
    return pending?.future ?? _settings;
  }

  @override
  Future<void> save(AIProviderSettings settings) async {}
}

class _PendingAdapter implements HttpClientAdapter {
  int requests = 0;
  final started = Completer<void>();
  final cancelled = Completer<void>();
  final response = Completer<ResponseBody>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests++;
    started.complete();
    cancelFuture?.then((_) => cancelled.complete());
    return response.future;
  }

  void reply() {
    if (response.isCompleted) return;
    response.complete(
      ResponseBody.fromString(
        '{"choices":[{"message":{"role":"assistant","content":"late"}}]}',
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
  }

  @override
  void close({bool force = false}) => reply();
}
