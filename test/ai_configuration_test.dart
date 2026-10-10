import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/reader_core/ai/ai_service.dart';

void main() {
  test('automatic detection ignores trailing endpoint separators', () {
    expect(
      detectAIProtocol(
        AIProviderType.glm,
        baseUrl: 'https://gateway.example/v1/messages/',
      ),
      AIProtocolType.anthropic,
    );
    expect(
      detectAIProtocol(
        AIProviderType.claude,
        baseUrl: 'https://gateway.example/v1/chat/completions///',
      ),
      AIProtocolType.openai,
    );
  });
  test('provider and protocol storage mappings remain stable', () {
    for (final provider in AIProviderType.values) {
      expect(AIProviderTypeX.fromValue(provider.value), provider);
    }
    expect(
      AIProviderTypeX.fromValue('future-provider'),
      AIProviderType.minimax,
    );
    expect(
      AIProtocolTypeX.fromValue(
        'future-protocol',
        fallback: AIProtocolType.gemini,
      ),
      AIProtocolType.gemini,
    );
    expect(AIProviderType.openai.defaultProtocol, AIProtocolType.openai);
    expect(AIProviderType.claude.defaultProtocol, AIProtocolType.anthropic);
    expect(AIProviderType.gemini.defaultProtocol, AIProtocolType.gemini);
  });

  test('normalizes full protocol endpoints to stable base URLs', () {
    expect(
      normalizeAIBaseUrl(
        AIProviderType.openai,
        'https://api.example.com/v1/chat/completions/',
      ),
      'https://api.example.com/v1',
    );
    expect(
      normalizeAIBaseUrl(
        AIProviderType.custom,
        'https://gateway.example.com/v1/messages',
        protocol: AIProtocolType.anthropic,
      ),
      'https://gateway.example.com/v1',
    );
    expect(
      normalizeAIBaseUrl(
        AIProviderType.gemini,
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-reader:generateContent',
      ),
      'https://generativelanguage.googleapis.com/v1beta',
    );
    expect(
      normalizeAIBaseUrl(
        AIProviderType.glm,
        'https://open.bigmodel.cn/api/anthropic/v1/messages',
      ),
      'https://open.bigmodel.cn/api/anthropic/v1',
    );
  });

  test('automatic protocol detection prefers URL shape then provider', () {
    expect(
      detectAIProtocol(
        AIProviderType.glm,
        baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      ),
      AIProtocolType.anthropic,
    );
    expect(
      detectAIProtocol(
        AIProviderType.custom,
        baseUrl:
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent',
      ),
      AIProtocolType.gemini,
    );
    expect(
      detectAIProtocol(
        AIProviderType.glm,
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      ),
      AIProtocolType.openai,
    );
    expect(
      detectAIProtocol(
        AIProviderType.claude,
        baseUrl: 'https://gateway.example.com/v1/chat/completions',
      ),
      AIProtocolType.openai,
    );
  });

  test('normalization preserves automatic and manual protocol modes', () {
    final automatic = const AIProviderSettings(
      provider: AIProviderType.glm,
      apiKey: 'key',
      baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      model: 'glm-5',
      temperature: 0.7,
    ).normalized();
    expect(automatic.protocol, isNull);
    expect(automatic.effectiveProtocol, AIProtocolType.anthropic);

    final manual = automatic.copyWith(protocol: AIProtocolType.openai);
    expect(manual.effectiveProtocol, AIProtocolType.openai);
    expect(manual.copyWith(clearProtocol: true).protocol, isNull);
  });

  test('automatic endpoint normalization is idempotent', () {
    for (final entry in <(AIProviderType, String, AIProtocolType)>[
      (
        AIProviderType.claude,
        'https://gateway.example.com/v1/chat/completions',
        AIProtocolType.openai,
      ),
      (
        AIProviderType.custom,
        'https://gateway.example.com/v1/messages',
        AIProtocolType.anthropic,
      ),
      (
        AIProviderType.custom,
        'https://gateway.example.com/v1beta/models/gemini-reader:generateContent',
        AIProtocolType.gemini,
      ),
    ]) {
      final once = AIProviderSettings(
        provider: entry.$1,
        apiKey: 'key',
        baseUrl: entry.$2,
        model: 'reader-model',
        temperature: 0.7,
      ).normalized();
      final twice = once.normalized();
      expect(once.protocol, isNull);
      expect(once.effectiveProtocol, entry.$3);
      expect(twice.baseUrl, once.baseUrl);
      expect(twice.effectiveProtocol, entry.$3);
    }
  });

  test('built-in and custom provider defaults remain valid', () {
    for (final provider in AIProviderType.values) {
      final settings = AIProviderSettings.defaults(provider);
      expect(settings.provider, provider);
      if (provider == AIProviderType.custom) {
        expect(settings.apiKey, isEmpty);
        expect(settings.baseUrl, isEmpty);
        expect(settings.model, isEmpty);
        expect(settings.protocol, isNull);
        expect(settings.effectiveProtocol, AIProtocolType.openai);
      } else {
        expect(
          validateAIProviderSettings(settings.copyWith(apiKey: 'test-key')),
          isNull,
        );
      }
    }
  });

  test('normalizes fields and temperature boundaries', () {
    final settings = const AIProviderSettings(
      provider: AIProviderType.custom,
      protocol: AIProtocolType.anthropic,
      apiKey: '  secret  ',
      baseUrl: ' https://gateway.example.com/v1/messages/ ',
      model: '  private-model  ',
      temperature: 3,
    ).normalized();

    expect(settings.apiKey, 'secret');
    expect(settings.baseUrl, 'https://gateway.example.com/v1');
    expect(settings.model, 'private-model');
    expect(settings.protocol, AIProtocolType.anthropic);
    expect(settings.temperature, 2);
  });

  test('returns stable validation error codes', () {
    const base = AIProviderSettings(
      provider: AIProviderType.openai,
      apiKey: 'key',
      baseUrl: 'https://api.example.com/v1',
      model: 'reader-model',
      temperature: 0.7,
    );

    expect(
      validateAIProviderSettings(base.copyWith(apiKey: '')),
      'api_key_required',
    );
    expect(
      validateAIProviderSettings(base.copyWith(baseUrl: 'not-a-url')),
      'base_url_invalid',
    );
    expect(
      validateAIProviderSettings(
        const AIProviderSettings(
          provider: AIProviderType.claude,
          apiKey: 'key',
          baseUrl: 'https://api.anthropic.com',
          model: 'not-claude',
          temperature: 0.7,
        ),
      ),
      'model_mismatch_claude',
    );
    expect(
      validateAIProviderSettings(
        const AIProviderSettings(
          provider: AIProviderType.gemini,
          apiKey: 'key',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          model: 'gemini-reader',
          temperature: 1.2,
        ),
      ),
      'temp_error_out_of_range',
    );
  });
}
