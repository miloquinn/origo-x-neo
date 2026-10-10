import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';

const _weatherTool = AIToolDefinition(
  name: 'get_weather',
  description: 'Read weather for a city.',
  parameters: {
    'type': 'object',
    'properties': {
      'city': {'type': 'string'},
    },
    'required': ['city'],
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OpenAI-compatible loop preserves assistant tool call fields', () async {
    final adapter = _SequenceAdapter([
      _json({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'content': null,
              'reasoning_content': 'opaque-reasoning-state',
              'tool_calls': [
                {
                  'id': 'call_openai_1',
                  'type': 'function',
                  'function': {
                    'name': 'get_weather',
                    'arguments': '{"city":"Hangzhou"}',
                  },
                },
              ],
            },
          },
        ],
      }),
      _json({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '杭州今天晴。'},
          },
        ],
      }),
    ]);
    final store = _SettingsStore(_settings(AIProtocolType.openai));
    final calls = <AIToolCall>[];
    final service = _service(adapter, store);

    final answer = await service.chatWithTools(
      history: const [
        AIChatMessage(role: 'system', content: 'caller system is ignored'),
        AIChatMessage(role: 'user', content: '天气如何？'),
      ],
      systemPrompt: 'You are the reading agent.',
      tools: const [_weatherTool],
      onToolCall: (call) async {
        calls.add(call);
        return {'temperature': 26};
      },
    );

    expect(answer, '杭州今天晴。');
    expect(store.loads, 1);
    expect(calls.single.id, 'call_openai_1');
    expect(calls.single.arguments, {'city': 'Hangzhou'});
    final first = adapter.jsonRequest(0);
    expect(first['tools'], [
      {
        'type': 'function',
        'function': {
          'name': 'get_weather',
          'description': 'Read weather for a city.',
          'parameters': _weatherTool.parameters,
        },
      },
    ]);
    expect(first['messages'], [
      {'role': 'system', 'content': 'You are the reading agent.'},
      {'role': 'user', 'content': '天气如何？'},
    ]);
    final secondMessages = adapter.jsonRequest(1)['messages'] as List;
    expect(secondMessages[2]['reasoning_content'], 'opaque-reasoning-state');
    expect(secondMessages[2]['tool_calls'][0]['id'], 'call_openai_1');
    expect(secondMessages[3], {
      'role': 'tool',
      'tool_call_id': 'call_openai_1',
      'content': '{"temperature":26}',
    });
  });

  test('Anthropic loop preserves thinking blocks and tool_use ids', () async {
    final adapter = _SequenceAdapter([
      _json({
        'content': [
          {
            'type': 'thinking',
            'thinking': 'opaque',
            'signature': 'anthropic-signature',
          },
          {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'get_weather',
            'input': {'city': 'Shanghai'},
          },
        ],
        'stop_reason': 'tool_use',
      }),
      _json({
        'content': [
          {'type': 'text', 'text': '上海多云。'},
        ],
        'stop_reason': 'end_turn',
      }),
    ]);
    final service = _service(
      adapter,
      _SettingsStore(_settings(AIProtocolType.anthropic)),
    );

    final answer = await service.chatWithTools(
      history: const [AIChatMessage(role: 'user', content: '上海天气？')],
      systemPrompt: 'reader agent',
      tools: const [_weatherTool],
      onToolCall: (call) async => {'condition': 'cloudy'},
    );

    expect(answer, '上海多云。');
    final first = adapter.jsonRequest(0);
    expect(first['system'], 'reader agent');
    expect(first['max_tokens'], 8192);
    expect(first['tools'], [
      {
        'name': 'get_weather',
        'description': 'Read weather for a city.',
        'input_schema': _weatherTool.parameters,
      },
    ]);
    final messages = adapter.jsonRequest(1)['messages'] as List;
    expect(messages[1]['content'][0]['signature'], 'anthropic-signature');
    expect(messages[1]['content'][1]['id'], 'toolu_1');
    expect(messages[2], {
      'role': 'user',
      'content': [
        {
          'type': 'tool_result',
          'tool_use_id': 'toolu_1',
          'content': '{"condition":"cloudy"}',
        },
      ],
    });
  });

  test(
    'Gemini loop preserves all model parts and thought signatures',
    () async {
      final adapter = _SequenceAdapter([
        _json({
          'candidates': [
            {
              'content': {
                'role': 'model',
                'parts': [
                  {'text': '我先查询。'},
                  {
                    'functionCall': {
                      'id': 'gemini_1',
                      'name': 'get_weather',
                      'args': {'city': 'Beijing'},
                    },
                    'thoughtSignature': 'gemini-signature',
                  },
                ],
              },
            },
          ],
        }),
        _json({
          'candidates': [
            {
              'content': {
                'role': 'model',
                'parts': [
                  {'text': '北京有风。'},
                ],
              },
            },
          ],
        }),
      ]);
      final service = _service(
        adapter,
        _SettingsStore(_settings(AIProtocolType.gemini)),
      );

      final answer = await service.chatWithTools(
        history: const [AIChatMessage(role: 'user', content: '北京天气？')],
        systemPrompt: 'reader agent',
        tools: const [_weatherTool],
        onToolCall: (call) async => {'wind': true},
      );

      expect(answer, '北京有风。');
      final first = adapter.jsonRequest(0);
      expect(first['systemInstruction'], {
        'parts': [
          {'text': 'reader agent'},
        ],
      });
      expect(first['tools'], [
        {
          'functionDeclarations': [
            {
              'name': 'get_weather',
              'description': 'Read weather for a city.',
              'parameters': _weatherTool.parameters,
            },
          ],
        },
      ]);
      final contents = adapter.jsonRequest(1)['contents'] as List;
      expect(contents[1]['parts'][0], {'text': '我先查询。'});
      expect(contents[1]['parts'][1]['thoughtSignature'], 'gemini-signature');
      expect(contents[1]['parts'][1]['functionCall']['id'], 'gemini_1');
      expect(contents[2], {
        'role': 'user',
        'parts': [
          {
            'functionResponse': {
              'id': 'gemini_1',
              'name': 'get_weather',
              'response': {'wind': true},
            },
          },
        ],
      });
    },
  );

  test('text-only agent answer returns without invoking tools', () async {
    final adapter = _SequenceAdapter([
      _json({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '直接回答'},
          },
        ],
      }),
    ]);
    var callbacks = 0;
    final service = _service(
      adapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );

    final answer = await service.chatWithTools(
      history: const [AIChatMessage(role: 'user', content: '你好')],
      systemPrompt: 'reader agent',
      tools: const [_weatherTool],
      onToolCall: (_) async {
        callbacks++;
        return {};
      },
    );

    expect(answer, '直接回答');
    expect(callbacks, 0);
    expect(adapter.requests, hasLength(1));
  });

  test(
    'malformed and unknown calls return safe errors without callbacks',
    () async {
      final adapter = _SequenceAdapter([
        _json({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'id': 'bad_1',
                    'type': 'function',
                    'function': {
                      'name': 'get_weather',
                      'arguments': '{invalid json',
                    },
                  },
                  {
                    'id': 'unknown_1',
                    'type': 'function',
                    'function': {'name': 'read_secrets', 'arguments': '{}'},
                  },
                ],
              },
            },
          ],
        }),
        _json({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': '已安全处理。'},
            },
          ],
        }),
      ]);
      var callbacks = 0;
      final service = _service(
        adapter,
        _SettingsStore(_settings(AIProtocolType.openai)),
      );

      expect(
        await service.chatWithTools(
          history: const [AIChatMessage(role: 'user', content: '执行')],
          systemPrompt: 'reader agent',
          tools: const [_weatherTool],
          onToolCall: (_) async {
            callbacks++;
            return {'apiKey': 'must-not-appear'};
          },
        ),
        '已安全处理。',
      );

      expect(callbacks, 0);
      final messages = adapter.jsonRequest(1)['messages'] as List;
      expect(jsonDecode(messages[3]['content'] as String), {
        'error': 'invalid_tool_call',
      });
      expect(jsonDecode(messages[4]['content'] as String), {
        'error': 'unknown_tool',
      });
      expect(jsonEncode(messages), isNot(contains('must-not-appear')));
    },
  );

  test('tool failures return a stable error without exception text', () async {
    final adapter = _SequenceAdapter([
      _json({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'tool_calls': [
                {
                  'id': 'failed_1',
                  'type': 'function',
                  'function': {'name': 'get_weather', 'arguments': '{}'},
                },
              ],
            },
          },
        ],
      }),
      _json({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '工具暂时不可用。'},
          },
        ],
      }),
    ]);
    final service = _service(
      adapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );

    await service.chatWithTools(
      history: const [AIChatMessage(role: 'user', content: '执行')],
      systemPrompt: 'reader agent',
      tools: const [_weatherTool],
      onToolCall: (_) async => throw StateError('secret-api-key-value'),
    );

    final messages = adapter.jsonRequest(1)['messages'] as List;
    expect(jsonDecode(messages.last['content'] as String), {
      'error': 'tool_execution_failed',
    });
    expect(jsonEncode(messages), isNot(contains('secret-api-key-value')));
  });

  test('cancellation is checked before request and callback', () async {
    final beforeRequestAdapter = _SequenceAdapter(const []);
    final beforeRequestService = _service(
      beforeRequestAdapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );
    final preCancelled = CancelToken()..cancel('stop');
    await expectLater(
      beforeRequestService.chatWithTools(
        history: const [AIChatMessage(role: 'user', content: '执行')],
        systemPrompt: 'reader agent',
        tools: const [_weatherTool],
        onToolCall: (_) async => {},
        cancelToken: preCancelled,
      ),
      throwsA(isA<DioException>().having(CancelToken.isCancel, 'cancel', true)),
    );
    expect(beforeRequestAdapter.requests, isEmpty);

    final duringResponse = CancelToken();
    var callbacks = 0;
    final beforeCallbackAdapter = _SequenceAdapter([
      _json({
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'tool_calls': [
                {
                  'id': 'call_1',
                  'type': 'function',
                  'function': {'name': 'get_weather', 'arguments': '{}'},
                },
              ],
            },
          },
        ],
      }),
    ], onFetch: (_) => duringResponse.cancel('stop'));
    final beforeCallbackService = _service(
      beforeCallbackAdapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );
    await expectLater(
      beforeCallbackService.chatWithTools(
        history: const [AIChatMessage(role: 'user', content: '执行')],
        systemPrompt: 'reader agent',
        tools: const [_weatherTool],
        onToolCall: (_) async {
          callbacks++;
          return {};
        },
        cancelToken: duringResponse,
      ),
      throwsA(isA<DioException>().having(CancelToken.isCancel, 'cancel', true)),
    );
    expect(callbacks, 0);
  });

  test('tool rounds are bounded', () async {
    final adapter = _SequenceAdapter(
      List.generate(
        3,
        (index) => _json({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'id': 'call_$index',
                    'type': 'function',
                    'function': {'name': 'get_weather', 'arguments': '{}'},
                  },
                ],
              },
            },
          ],
        }),
      ),
    );
    var callbacks = 0;
    final service = _service(
      adapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );

    await expectLater(
      service.chatWithTools(
        history: const [AIChatMessage(role: 'user', content: '循环')],
        systemPrompt: 'reader agent',
        tools: const [_weatherTool],
        onToolCall: (_) async {
          callbacks++;
          return {'ok': true};
        },
        maxToolRounds: 2,
      ),
      throwsA(
        isA<AIServiceException>().having(
          (error) => error.code,
          'code',
          'tool_round_limit_exceeded',
        ),
      ),
    );
    expect(adapter.requests, hasLength(3));
    expect(callbacks, 2);
  });

  test('existing reader chat keeps its page-context request shape', () async {
    final adapter = _SequenceAdapter([
      _json({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '旧链路回答'},
          },
        ],
      }),
    ]);
    final service = _service(
      adapter,
      _SettingsStore(_settings(AIProtocolType.openai)),
    );

    final answer = await service.chat(
      history: const [AIChatMessage(role: 'user', content: '解释本页')],
      pageText: '页面正文',
      meta: const AIRequestMeta(bookId: 'book', chapterId: 'chapter'),
    );

    expect(answer, '旧链路回答');
    final messages = adapter.jsonRequest(0)['messages'] as List;
    expect(messages.first['content'], contains('页面正文'));
    expect(messages.last, {'role': 'user', 'content': '解释本页'});
    expect(adapter.jsonRequest(0), isNot(contains('tools')));
  });

  test(
    'current Claude and Gemini agents omit unsupported temperature',
    () async {
      final cases = <(AIProviderSettings, Map<String, dynamic>)>[
        (
          const AIProviderSettings(
            provider: AIProviderType.claude,
            apiKey: 'key',
            baseUrl: 'https://api.anthropic.com',
            model: 'claude-sonnet-5',
            temperature: 0.7,
          ),
          {
            'content': [
              {'type': 'text', 'text': 'Claude answer'},
            ],
          },
        ),
        (
          const AIProviderSettings(
            provider: AIProviderType.gemini,
            apiKey: 'key',
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            model: 'gemini-3.8-flash',
            temperature: 0.7,
          ),
          {
            'candidates': [
              {
                'content': {
                  'role': 'model',
                  'parts': [
                    {'text': 'Gemini answer'},
                  ],
                },
              },
            ],
          },
        ),
      ];

      for (final entry in cases) {
        final adapter = _SequenceAdapter([_json(entry.$2)]);
        final service = _service(adapter, _SettingsStore(entry.$1));
        await service.chatWithTools(
          history: const [AIChatMessage(role: 'user', content: 'question')],
          systemPrompt: 'reader agent',
          tools: const [],
          onToolCall: (_) async => const {},
        );

        final payload = adapter.jsonRequest(0);
        expect(payload, isNot(contains('temperature')));
        expect(payload, isNot(contains('generationConfig')));
      }
    },
  );
}

ReaderHttpAIService _service(
  _SequenceAdapter adapter,
  _SettingsStore settingsStore,
) => ReaderHttpAIService(
  dio: Dio()..httpClientAdapter = adapter,
  settingsStore: settingsStore,
);

AIProviderSettings _settings(AIProtocolType protocol) => AIProviderSettings(
  provider: AIProviderType.custom,
  protocol: protocol,
  apiKey: 'test-key',
  baseUrl: 'https://example.test/v1',
  model: 'reader-model',
  temperature: 0.7,
);

ResponseBody _json(Map<String, dynamic> value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _SettingsStore implements AISettingsStore {
  _SettingsStore(this.settings);

  final AIProviderSettings settings;
  int loads = 0;

  @override
  Future<AIProviderSettings> load([AIProviderType? provider]) async {
    loads++;
    return settings;
  }

  @override
  Future<void> save(AIProviderSettings settings) async {}
}

class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this.responses, {this.onFetch});

  final List<ResponseBody> responses;
  final void Function(RequestOptions options)? onFetch;
  final List<RequestOptions> requests = [];

  Map<String, dynamic> jsonRequest(int index) {
    final data = requests[index].data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return jsonDecode(data as String) as Map<String, dynamic>;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    onFetch?.call(options);
    final index = requests.length - 1;
    if (index >= responses.length) throw StateError('No fake response $index');
    return responses[index];
  }

  @override
  void close({bool force = false}) {}
}
