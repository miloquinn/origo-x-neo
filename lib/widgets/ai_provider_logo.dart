import 'package:flutter/material.dart';

/// Shared brand labels for preset and hand-edited compatible connections.
String aiProviderDisplayName(
  BuildContext context,
  String? asset, {
  required String fallback,
}) {
  final language = Localizations.localeOf(context).languageCode;
  return switch (asset?.split('/').last) {
    'openai.png' => 'OpenAI',
    'claude.png' => 'Claude',
    'gemini.png' => 'Google Gemini',
    'deepseek.png' => 'DeepSeek',
    'qwen.png' => language == 'zh' ? '通义千问' : 'Qwen',
    'zhipu.png' => language == 'zh' ? '智谱 AI' : 'Zhipu AI',
    'minimax.png' => 'MiniMax',
    'moonshot.png' => 'Kimi',
    'groq.png' => 'Groq',
    'siliconflow.png' => language == 'zh' ? '硅基流动' : 'SiliconFlow',
    _ => fallback,
  };
}

/// Bundled provider artwork stays available offline and never contacts a logo CDN.
class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({super.key, this.asset, this.size = 32});

  static const _monochromeAssets = {
    'assets/ai_providers/openai.png',
    'assets/ai_providers/zhipu.png',
    'assets/ai_providers/moonshot.png',
    'assets/ai_providers/groq.png',
    'assets/ai_providers/mimo.png',
  };

  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = this.asset;
    if (asset == null) {
      return Icon(Icons.hub_outlined, size: size);
    }

    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: _monochromeAssets.contains(asset)
          ? Theme.of(context).colorScheme.onSurface
          : null,
      colorBlendMode: BlendMode.srcIn,
      errorBuilder: (_, _, _) => Icon(Icons.hub_outlined, size: size),
    );
  }
}
