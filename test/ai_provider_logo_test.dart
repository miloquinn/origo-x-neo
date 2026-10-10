import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';
import 'package:xxread/widgets/app_skin_icon.dart';

void main() {
  const names = [
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
  ];
  for (final brightness in Brightness.values) {
    testWidgets('provider artwork loads without theme tint in $brightness', (
      tester,
    ) async {
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
                for (final name in names)
                  AiProviderLogo(asset: 'assets/ai_providers/$name.png'),
                const AiProviderLogo(),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(
            image.image,
            tester.element(find.byType(Scaffold)),
          );
        }
      });
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(12));
      expect(find.byType(AppSkinIcon), findsOneWidget);
      for (final image in images) {
        expect(image.color, isNull);
        expect(image.fit, BoxFit.contain);
        expect(image.width, 32);
        expect(image.height, 32);
      }
      final assets = images
          .map(
            (image) => (image.image as ResizeImage).imageProvider as AssetImage,
          )
          .map((image) => image.assetName)
          .toSet();
      for (final name in ['openai', 'groq', 'mimo', 'moonshot']) {
        expect(
          assets,
          contains(
            'assets/ai_providers/$name${brightness == Brightness.dark ? '-dark' : ''}.png',
          ),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
