import 'package:flutter/widgets.dart';

import '../services/reader_aloud_service.dart';
import 'ai_provider_logo.dart';

/// Cloud speech providers share the same offline artwork as AI configuration.
class CloudTtsProviderLogo extends StatelessWidget {
  const CloudTtsProviderLogo({
    super.key,
    required this.provider,
    this.size = 32,
  });

  final ReaderAloudCloudProvider provider;
  final double size;

  static String assetFor(ReaderAloudCloudProvider provider) =>
      switch (provider) {
        ReaderAloudCloudProvider.openai => 'assets/ai_providers/openai.png',
        ReaderAloudCloudProvider.doubao => 'assets/ai_providers/doubao.png',
        ReaderAloudCloudProvider.minimax => 'assets/ai_providers/minimax.png',
        ReaderAloudCloudProvider.mimo => 'assets/ai_providers/mimo.png',
      };

  @override
  Widget build(BuildContext context) =>
      AiProviderLogo(asset: assetFor(provider), size: size);
}
