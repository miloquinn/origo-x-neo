// 文件说明：AI 模型预设目录，集中维护内置供应商、模型与默认参数。
// 技术要点：静态预设、Provider 默认选择、配置匹配与品牌资产。

part of 'ai_service.dart';

class AIModelPreset {
  final String id;
  final String label;
  final String vendor;
  final String brand;
  final String logoAsset;
  final AIProviderType provider;
  final AIProtocolType? protocol;
  final String baseUrl;
  final String model;
  final double temperature;

  const AIModelPreset({
    required this.id,
    required this.label,
    required this.vendor,
    required this.brand,
    required this.logoAsset,
    required this.provider,
    this.protocol,
    required this.baseUrl,
    required this.model,
    required this.temperature,
  });

  AIProviderSettings toSettings({String apiKey = ''}) {
    return AIProviderSettings(
      provider: provider,
      protocol: protocol,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      temperature: temperature,
    ).normalized();
  }
}

class AIModelPresets {
  static const String _openAILogo = 'assets/ai_providers/openai.png';
  static const String _zhipuLogo = 'assets/ai_providers/zhipu.png';
  static const String _miniMaxLogo = 'assets/ai_providers/minimax.png';
  static const String _claudeLogo = 'assets/ai_providers/claude.png';
  static const String _geminiLogo = 'assets/ai_providers/gemini.png';
  static const String _deepSeekLogo = 'assets/ai_providers/deepseek.png';
  static const String _qwenLogo = 'assets/ai_providers/qwen.png';
  static const String _moonshotLogo = 'assets/ai_providers/moonshot.png';
  static const String _groqLogo = 'assets/ai_providers/groq.png';
  static const String _siliconFlowLogo = 'assets/ai_providers/siliconflow.png';

  static const List<AIModelPreset> all = <AIModelPreset>[
    AIModelPreset(
      id: 'openai_gpt_6_astra',
      label: 'GPT-6 Astra',
      vendor: 'OpenAI',
      brand: 'openai',
      logoAsset: _openAILogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-6-astra',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'openai_gpt_6_1_sol',
      label: 'GPT-6.1 Sol',
      vendor: 'OpenAI',
      brand: 'openai',
      logoAsset: _openAILogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-6.1-sol',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'openai_gpt_6_luna',
      label: 'GPT-6 Luna',
      vendor: 'OpenAI',
      brand: 'openai',
      logoAsset: _openAILogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-6-luna',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'glm_5_3',
      label: 'GLM-5.3',
      vendor: '智谱 GLM',
      brand: 'zhipu',
      logoAsset: _zhipuLogo,
      provider: AIProviderType.glm,
      protocol: AIProtocolType.openai,
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      model: 'glm-5.3',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'glm_5_3_flash',
      label: 'GLM-5.3-Flash',
      vendor: '智谱 GLM',
      brand: 'zhipu',
      logoAsset: _zhipuLogo,
      provider: AIProviderType.glm,
      protocol: AIProtocolType.openai,
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      model: 'glm-5.3-flash',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'bigmodel_coding_glm_5_3',
      label: 'GLM-5.3',
      vendor: 'BigModel Coding Plan',
      brand: 'zhipu',
      logoAsset: _zhipuLogo,
      provider: AIProviderType.glm,
      protocol: AIProtocolType.anthropic,
      baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      model: 'glm-5.3',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'bigmodel_coding_glm_5_3_flash',
      label: 'GLM-5.3-Flash',
      vendor: 'BigModel Coding Plan',
      brand: 'zhipu',
      logoAsset: _zhipuLogo,
      provider: AIProviderType.glm,
      protocol: AIProtocolType.anthropic,
      baseUrl: 'https://open.bigmodel.cn/api/anthropic',
      model: 'glm-5.3-flash',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'minimax_m3',
      label: 'MiniMax-M3',
      vendor: 'MiniMax',
      brand: 'minimax',
      logoAsset: _miniMaxLogo,
      provider: AIProviderType.minimax,
      baseUrl: 'https://api.minimax.io/v1',
      model: 'MiniMax-M3',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'claude_opus_5_5',
      label: 'Claude Opus 5.5',
      vendor: 'Anthropic',
      brand: 'claude',
      logoAsset: _claudeLogo,
      provider: AIProviderType.claude,
      baseUrl: 'https://api.anthropic.com',
      model: 'claude-opus-5-5',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'claude_sonnet_5_5',
      label: 'Claude Sonnet 5.5',
      vendor: 'Anthropic',
      brand: 'claude',
      logoAsset: _claudeLogo,
      provider: AIProviderType.claude,
      baseUrl: 'https://api.anthropic.com',
      model: 'claude-sonnet-5-5',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'claude_fable_5_1',
      label: 'Claude Fable 5.1',
      vendor: 'Anthropic',
      brand: 'claude',
      logoAsset: _claudeLogo,
      provider: AIProviderType.claude,
      baseUrl: 'https://api.anthropic.com',
      model: 'claude-fable-5-1',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'claude_haiku_5_5',
      label: 'Claude Haiku 5.5',
      vendor: 'Anthropic',
      brand: 'claude',
      logoAsset: _claudeLogo,
      provider: AIProviderType.claude,
      baseUrl: 'https://api.anthropic.com',
      model: 'claude-haiku-5-5',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'gemini_3_8_flash',
      label: 'Gemini 3.8 Flash',
      vendor: 'Google',
      brand: 'gemini',
      logoAsset: _geminiLogo,
      provider: AIProviderType.gemini,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-3.8-flash',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'gemini_3_1_pro_preview',
      label: 'Gemini 3.1 Pro Preview',
      vendor: 'Google',
      brand: 'gemini',
      logoAsset: _geminiLogo,
      provider: AIProviderType.gemini,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-3.1-pro-preview',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'deepseek_v4_pro',
      label: 'DeepSeek V4 Pro',
      vendor: 'DeepSeek',
      brand: 'deepseek',
      logoAsset: _deepSeekLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.deepseek.com',
      model: 'deepseek-v4-pro',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'deepseek_v4_flash',
      label: 'DeepSeek V4.1 Flash',
      vendor: 'DeepSeek',
      brand: 'deepseek',
      logoAsset: _deepSeekLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.deepseek.com',
      model: 'deepseek-flash',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'qwen_3_8_max',
      label: 'Qwen3.8 Max',
      vendor: '阿里云百炼',
      brand: 'qwen',
      logoAsset: _qwenLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      model: 'qwen3.8-max',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'qwen_3_8_flash',
      label: 'Qwen3.8 Flash',
      vendor: '阿里云百炼',
      brand: 'qwen',
      logoAsset: _qwenLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      model: 'qwen3.8-flash',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'kimi_k3',
      label: 'Kimi K3',
      vendor: 'Kimi',
      brand: 'moonshot',
      logoAsset: _moonshotLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.moonshot.cn/v1',
      model: 'kimi-k3',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'kimi_k2_7_code',
      label: 'Kimi K2.7 Code',
      vendor: 'Kimi',
      brand: 'moonshot',
      logoAsset: _moonshotLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.moonshot.cn/v1',
      model: 'kimi-k2.7-code',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'groq_gpt_oss_120b',
      label: 'GPT-OSS 120B',
      vendor: 'Groq',
      brand: 'groq',
      logoAsset: _groqLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'openai/gpt-oss-120b',
      temperature: 1.0,
    ),
    AIModelPreset(
      id: 'siliconflow_deepseek_v4_pro',
      label: 'DeepSeek V4 Pro',
      vendor: 'SiliconFlow',
      brand: 'siliconflow',
      logoAsset: _siliconFlowLogo,
      provider: AIProviderType.openai,
      baseUrl: 'https://api.siliconflow.cn/v1',
      model: 'deepseek-ai/DeepSeek-V4-Pro',
      temperature: 1.0,
    ),
  ];

  static AIModelPreset defaultForProvider(AIProviderType provider) {
    return all.firstWhere(
      (preset) => preset.provider == provider,
      orElse: () => all.first,
    );
  }

  static AIModelPreset? match(AIProviderSettings settings) {
    final normalized = settings.normalized();
    final normalizedBase = normalized.baseUrl.trim().replaceAll(
      RegExp(r'/+$'),
      '',
    );
    for (final preset in all) {
      final presetSettings = preset.toSettings();
      final presetBase = presetSettings.baseUrl.trim().replaceAll(
        RegExp(r'/+$'),
        '',
      );
      if (preset.provider == normalized.provider &&
          presetSettings.effectiveProtocol == normalized.effectiveProtocol &&
          presetBase == normalizedBase &&
          preset.model == normalized.model) {
        return preset;
      }
    }
    return null;
  }

  static List<AIModelPreset> byProvider(AIProviderType provider) {
    return all.where((preset) => preset.provider == provider).toList();
  }

  static String? logoAssetForSettings(AIProviderSettings settings) {
    final matched = match(settings);
    if (matched != null) return matched.logoAsset;

    final endpoint = settings.baseUrl.toLowerCase();
    final model = settings.model.toLowerCase();
    if (endpoint.contains('bigmodel.cn')) return _zhipuLogo;
    if (endpoint.contains('minimax.')) return _miniMaxLogo;
    if (endpoint.contains('anthropic.com')) return _claudeLogo;
    if (endpoint.contains('googleapis.com')) return _geminiLogo;
    if (endpoint.contains('deepseek.com')) return _deepSeekLogo;
    if (endpoint.contains('dashscope.aliyuncs.com')) return _qwenLogo;
    if (endpoint.contains('moonshot.cn')) return _moonshotLogo;
    if (endpoint.contains('groq.com')) return _groqLogo;
    if (endpoint.contains('siliconflow.cn')) return _siliconFlowLogo;
    if (endpoint.contains('openai.com')) return _openAILogo;

    if (model.startsWith('glm-')) return _zhipuLogo;
    if (model.startsWith('claude-')) return _claudeLogo;
    if (model.contains('gemini')) return _geminiLogo;
    if (model.startsWith('deepseek-')) return _deepSeekLogo;
    if (model.startsWith('qwen')) return _qwenLogo;
    if (model.startsWith('kimi-')) return _moonshotLogo;
    if (model.startsWith('gpt-')) return _openAILogo;
    return logoAssetForProvider(settings.provider);
  }

  static String? logoAssetForProvider(AIProviderType provider) {
    return switch (provider) {
      AIProviderType.minimax => _miniMaxLogo,
      AIProviderType.glm => _zhipuLogo,
      AIProviderType.openai => _openAILogo,
      AIProviderType.claude => _claudeLogo,
      AIProviderType.gemini => _geminiLogo,
      AIProviderType.custom => null,
    };
  }
}
