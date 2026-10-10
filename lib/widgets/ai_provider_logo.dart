import 'package:flutter/material.dart';

import '../models/app_skin.dart';
import 'app_skin_icon.dart';

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

/// Shared offline provider artwork, retaining supplied colors and variants.
/// Unknown services and failed image loads use the app's semantic icon.
class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({super.key, this.asset, this.size = 32});

  final String? asset;
  final double size;

  static const _darkVariants = {
    'openai.png',
    'groq.png',
    'mimo.png',
    'moonshot.png',
  };

  static String assetForBrightness(String asset, Brightness brightness) {
    if (brightness == Brightness.dark &&
        _darkVariants.contains(asset.split('/').last)) {
      return asset.replaceFirst(RegExp(r'\.png$'), '-dark.png');
    }
    return asset;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = AppSkinIcon(
      slot: AppSkinIconSlot.network,
      fallback: Icon(Icons.hub_outlined, size: size),
    );
    if (asset == null) return fallback;
    return Image.asset(
      assetForBrightness(asset!, Theme.of(context).brightness),
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
