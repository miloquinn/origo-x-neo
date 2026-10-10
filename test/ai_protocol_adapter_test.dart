import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/reader_core/ai/ai_service.dart';

const _messages = <Map<String, dynamic>>[
  {'role': 'system', 'content': 'system prompt'},
  {'role': 'user', 'content': 'question'},
  {'role': 'assistant', 'content': 'previous answer'},
];

void main() {
  const adapter = AIProtocolAdapter();

  test('converts OpenAI-compatible requests and responses', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.openai,
      apiKey: 'openai-key',
      baseUrl: 'https://api.example.com/v1',
      model: 'reader-model',
      temperature: 0.8,
    );

    expect(
      adapter.chatEndpoint(settings),
      'https://api.example.com/v1/chat/completions',
    );
    expect(
      adapter.modelListEndpoint(settings),
      'https://api.example.com/v1/models',
    );
    expect(
      adapter.requestOptions(settings).headers?['Authorization'],
      'Bearer openai-key',
    );
    expect(adapter.buildPayload(settings: settings, messages: _messages), {
      'model': 'reader-model',
      'messages': _messages,
      'temperature': 0.8,
      'stream': false,
    });
    expect(
      adapter.extractAssistantContent(
        settings: settings,
        responseData: {
          'choices': [
            {
              'message': {'content': 'plain response'},
            },
          ],
        },
      ),
      'plain response',
    );
    expect(
      adapter.extractAssistantContent(
        settings: settings,
        responseData: {
          'choices': [
            {
              'message': {
                'content': [
                  {'text': 'part one'},
                  ' + part two',
                ],
              },
            },
          ],
        },
      ),
      'part one + part two',
    );
  });

  test('converts Anthropic requests and responses', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.custom,
      protocol: AIProtocolType.anthropic,
      apiKey: 'anthropic-key',
      baseUrl: 'https://gateway.example.com/v1',
      model: 'claude-model',
      temperature: 0.7,
    );

    expect(
      adapter.chatEndpoint(settings),
      'https://gateway.example.com/v1/messages',
    );
    expect(
      adapter.modelListEndpoint(settings),
      'https://gateway.example.com/v1/models',
    );
    final options = adapter.requestOptions(settings);
    expect(options.headers?['x-api-key'], 'anthropic-key');
    expect(options.headers?['anthropic-version'], '2023-06-01');
    expect(adapter.buildPayload(settings: settings, messages: _messages), {
      'model': 'claude-model',
      'system': 'system prompt',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'question'},
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': 'previous answer'},
          ],
        },
      ],
      'max_tokens': 8192,
      'temperature': 0.7,
    });
    expect(
      adapter.extractAssistantContent(
        settings: settings,
        responseData: {
          'content': [
            {'type': 'text', 'text': 'first'},
            {'type': 'tool_use', 'text': 'ignored'},
            {'type': 'text', 'text': ' second'},
          ],
        },
      ),
      'first second',
    );
  });

  test('routes automatic BigModel Anthropic URLs without duplication', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.glm,
      apiKey: 'glm-key',
      baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      model: 'glm-5',
      temperature: 0.7,
    );

    expect(settings.protocol, isNull);
    expect(settings.effectiveProtocol, AIProtocolType.anthropic);
    expect(
      adapter.chatEndpoint(settings),
      'https://open.bigmodel.cn/api/anthropic/v1/messages',
    );
    expect(
      adapter.modelListEndpoint(settings),
      'https://open.bigmodel.cn/api/anthropic/v1/models',
    );
    expect(adapter.requestOptions(settings).headers?['x-api-key'], 'glm-key');
    expect(
      adapter.requestOptions(settings).headers,
      isNot(contains('Authorization')),
    );
  });

  test('manual protocol overrides automatic URL detection', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.glm,
      protocol: AIProtocolType.openai,
      apiKey: 'glm-key',
      baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      model: 'glm-5',
      temperature: 0.7,
    );

    expect(
      adapter.chatEndpoint(settings),
      'https://open.bigmodel.cn/api/anthropic/chat/completions',
    );
    expect(
      adapter.requestOptions(settings).headers?['Authorization'],
      'Bearer glm-key',
    );
  });

  test('converts Gemini requests and responses', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.gemini,
      apiKey: 'gemini-key',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-reader',
      temperature: 0.6,
    );

    expect(
      adapter.chatEndpoint(settings),
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-reader:generateContent',
    );
    expect(
      adapter.modelListEndpoint(settings),
      'https://generativelanguage.googleapis.com/v1beta/models',
    );
    expect(
      adapter.requestOptions(settings).headers?['x-goog-api-key'],
      'gemini-key',
    );
    expect(adapter.buildPayload(settings: settings, messages: _messages), {
      'systemInstruction': {
        'parts': [
          {'text': 'system prompt'},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'question'},
          ],
        },
        {
          'role': 'model',
          'parts': [
            {'text': 'previous answer'},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.6},
    });
    expect(
      adapter.extractAssistantContent(
        settings: settings,
        responseData: {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'first'},
                  {'text': ' second'},
                ],
              },
            },
          ],
        },
      ),
      'first second',
    );
  });

  test('omits unsupported temperature for current model generations', () {
    for (final model in ['claude-sonnet-5', 'claude-4-7-sonnet']) {
      final payload = adapter.buildPayload(
        settings: AIProviderSettings(
          provider: AIProviderType.claude,
          apiKey: 'key',
          baseUrl: 'https://api.anthropic.com',
          model: model,
          temperature: 0.7,
        ),
        messages: _messages,
      );
      expect(payload, isNot(contains('temperature')), reason: model);
    }

    final geminiPayload = adapter.buildPayload(
      settings: const AIProviderSettings(
        provider: AIProviderType.gemini,
        apiKey: 'key',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-3.8-flash',
        temperature: 0.7,
      ),
      messages: _messages,
    );
    expect(geminiPayload, isNot(contains('generationConfig')));
  });

  test('keeps MiniMax temperature inside its supported range', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.minimax,
      apiKey: 'minimax-key',
      baseUrl: 'https://api.minimax.io/v1',
      model: 'MiniMax-M2.5',
      temperature: 0,
    );

    expect(
      adapter.buildPayload(
        settings: settings,
        messages: _messages,
      )['temperature'],
      0.01,
    );
  });

  test('MiniMax manual Anthropic protocol uses Anthropic payload', () {
    const settings = AIProviderSettings(
      provider: AIProviderType.minimax,
      protocol: AIProtocolType.anthropic,
      apiKey: 'key',
      baseUrl: 'https://gateway.example.com/v1/messages',
      model: 'MiniMax-M3',
      temperature: 0.7,
    );

    final payload = adapter.buildPayload(
      settings: settings,
      messages: _messages,
    );
    expect(payload, containsPair('system', 'system prompt'));
    expect(payload['messages'], isA<List<dynamic>>());
    expect(payload, isNot(contains('stream')));
  });
}
