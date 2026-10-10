import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';
import 'package:xxread/widgets/app_skin_icon.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'unlicensed provider marks are never displayed in $brightness',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: brightness,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.pink,
                brightness: brightness,
              ),
            ),
            home: Scaffold(
              body: Wrap(
                children: [
                  for (final name in [
                    'openai',
                    'claude',
                    'gemini',
                    'deepseek',
                    'qwen',
                    'zhipu',
                    'minimax',
                    'moonshot',
                    'groq',
                    'siliconflow',
                    'doubao',
                    'mimo',
                  ])
                    AiProviderLogo(asset: 'assets/ai_providers/$name.png'),
                  const AiProviderLogo(),
                ],
              ),
            ),
          ),
        );
        expect(find.byType(AppSkinIcon), findsNWidgets(13));
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .where(
                (image) =>
                    image.image is AssetImage &&
                    (image.image as AssetImage).assetName.startsWith(
                      'assets/ai_providers/',
                    ),
              ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
