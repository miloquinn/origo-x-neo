import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/widgets/account_identity_card.dart';

void main() {
  testWidgets('Explore badge uses the owned bookplate insignia', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 300);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'InsigniaCapture',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final icons = await File(
        '/Users/xiaoyuan/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('insignia-capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            key: ValueKey(brightness),
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF456C9E),
                brightness: brightness,
              ),
              fontFamily: 'InsigniaCapture',
            ),
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AccountIdentityCard(
                    tier: AccountIdentityTier.explore,
                    title: 'Origo reader',
                    subtitle: '@reader',
                    avatar: const CircleAvatar(child: Icon(Icons.person)),
                    loading: false,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('settings-account-explore-insignia')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.explore_outlined), findsNothing);
      expect(
        find.byKey(const ValueKey('settings-account-premium-badge')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('insignia-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File(
          'build/verification-store/membership-insignia/${brightness.name}.png',
        );
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
