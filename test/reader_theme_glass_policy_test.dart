import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

void main() {
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });
  testWidgets(
    'reader palette retains app material policy while owning colors',
    (tester) async {
      for (final style in AppUiStyle.values) {
        for (final glass in GlassStyle.values) {
          GlassEffectConfig.setGlassStyle(
            glass == GlassStyle.liquid ? GlassStyle.frosted : GlassStyle.liquid,
          );
          final appearance = UiStyleThemeExtension(
            style: style,
            glassStyle: glass,
            liquidGlassOpacity: .8,
          );
          final parent = ThemeData(
            colorSchemeSeed: Colors.pink,
            extensions: [appearance],
          );
          final reader = ReaderThemes.green.toThemeData(parentTheme: parent);
          expect(reader.extension<UiStyleThemeExtension>(), same(appearance));
          expect(reader.colorScheme.surface, ReaderThemes.green.surface);
          expect(reader.colorScheme.primary, ReaderThemes.green.accent);
          await tester.pumpWidget(
            MaterialApp(
              theme: reader,
              home: Scaffold(
                body: ReaderControlBar(
                  palette: ReaderThemes.green,
                  isTopBar: true,
                  child: const SizedBox(width: 240, height: 54),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final surface = tester.widget<GlassSurface>(
            find.byType(GlassSurface),
          );
          expect(surface.color, ReaderThemes.green.controlBar);
          if (style == AppUiStyle.material3) {
            expect(find.byType(BackdropFilter), findsNothing);
            expect(find.byType(LiquidGlassSurface), findsNothing);
          } else if (glass == GlassStyle.liquid) {
            expect(find.byType(LiquidGlassSurface), findsOneWidget);
          } else {
            expect(find.byType(LiquidGlassSurface), findsNothing);
            expect(find.byType(BackdropFilter), findsOneWidget);
          }
        }
      }
    },
  );
}
