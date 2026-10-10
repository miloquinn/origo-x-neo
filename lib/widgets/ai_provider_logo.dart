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

/// Providers use our own semantic icon until brand permissions are obtained.
/// The legacy asset identifier is retained for service-name matching only.
class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({super.key, this.asset, this.size = 32});

  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppSkinIcon(
      slot: AppSkinIconSlot.network,
      fallback: Icon(Icons.hub_outlined, size: size),
    );
  }
}
