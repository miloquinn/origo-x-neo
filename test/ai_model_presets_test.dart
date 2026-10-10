import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/reader_core/ai/ai_service.dart';

void main() {
  test('preset IDs are non-empty and unique', () {
    final ids = AIModelPresets.all.map((preset) => preset.id).toList();

    expect(ids, everyElement(isNotEmpty));
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('preset brand metadata is complete', () {
    for (final preset in AIModelPresets.all) {
      expect(preset.brand, isNotEmpty, reason: preset.id);
      expect(
        preset.logoAsset,
        startsWith('assets/ai_providers/'),
        reason: preset.id,
      );
      expect(preset.logoAsset, endsWith('.png'), reason: preset.id);
    }
  });

  test('BigModel Coding Plan uses its documented Anthropic endpoint', () {
    final presets = AIModelPresets.all.where(
      (preset) => preset.vendor == 'BigModel Coding Plan',
    );

    expect(presets, hasLength(2));
    expect(
      presets.map((preset) => preset.model),
      containsAll(<String>['glm-5.3', 'glm-5.3-flash']),
    );
    for (final preset in presets) {
      expect(preset.provider, AIProviderType.glm);
      expect(preset.protocol, AIProtocolType.anthropic);
      expect(preset.baseUrl, 'https://open.bigmodel.cn/api/anthropic');
      expect(preset.toSettings().effectiveProtocol, AIProtocolType.anthropic);
    }
  });

  test('Claude presets use the current documented API aliases', () {
    final models = AIModelPresets.byProvider(
      AIProviderType.claude,
    ).map((preset) => preset.model);

    expect(
      models,
      unorderedEquals(<String>[
        'claude-fable-5-1',
        'claude-opus-5-5',
        'claude-sonnet-5-5',
        'claude-haiku-5-5',
      ]),
    );
  });

  test('every provider has a valid default preset', () {
    for (final provider in AIProviderType.values) {
      final preset = AIModelPresets.defaultForProvider(provider);
      final settings = preset.toSettings(apiKey: 'test-key');

      final expectedProvider = provider == AIProviderType.custom
          ? AIProviderType.openai
          : provider;
      expect(preset.provider, expectedProvider);
      expect(settings.provider, expectedProvider);
      expect(validateAIProviderSettings(settings), isNull);
    }
  });

  test('provider filtering returns only matching presets', () {
    for (final provider in AIProviderType.values) {
      final presets = AIModelPresets.byProvider(provider);

      if (provider == AIProviderType.custom) {
        expect(presets, isEmpty);
        continue;
      }
      expect(presets, isNotEmpty);
      expect(
        presets,
        everyElement(
          predicate<AIModelPreset>((preset) => preset.provider == provider),
        ),
      );
    }
  });

  test('settings created from presets match the same preset', () {
    for (final preset in AIModelPresets.all) {
      final settings = preset.toSettings(apiKey: 'test-key').normalized();

      expect(AIModelPresets.match(settings), preset);
    }
  });

  test('logo helpers preserve brands for saved and custom settings', () {
    const savedKimi = AIProviderSettings(
      provider: AIProviderType.openai,
      apiKey: '',
      baseUrl: 'https://api.moonshot.cn/v1',
      model: 'moonshot-v1-32k',
      temperature: 0.7,
    );
    const custom = AIProviderSettings(
      provider: AIProviderType.custom,
      apiKey: '',
      baseUrl: 'https://example.com/v1',
      model: 'private-model',
      temperature: 0.7,
    );
    const siliconFlow = AIProviderSettings(
      provider: AIProviderType.custom,
      apiKey: '',
      baseUrl: 'https://api.siliconflow.cn/v1',
      model: 'deepseek-ai/another-model',
      temperature: 0.7,
    );

    expect(
      AIModelPresets.logoAssetForSettings(savedKimi),
      'assets/ai_providers/moonshot.png',
    );
    expect(AIModelPresets.logoAssetForSettings(custom), isNull);
    expect(
      AIModelPresets.logoAssetForSettings(siliconFlow),
      'assets/ai_providers/siliconflow.png',
    );
    expect(
      AIModelPresets.logoAssetForProvider(AIProviderType.glm),
      'assets/ai_providers/zhipu.png',
    );
  });
}
