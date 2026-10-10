import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/glass_material.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  setUp(() => GlassEffectConfig.setDisableAllGlassEffects(false));
  tearDown(() => GlassEffectConfig.setDisableAllGlassEffects(false));

  for (final palette in [
    ReaderThemes.day,
    ReaderThemes.parchment,
    ReaderThemes.night,
    ReaderThemes.pureBlack,
    ReaderThemes.navy,
  ]) {
    testWidgets('${palette.id} lighting separates the edge without glare', (
      tester,
    ) async {
      for (final role in GlassSurfaceRole.values) {
        final material = await _resolve(tester, palette, role: role);
        final fill = Color.alphaBlend(
          material.liquidGradient.colors.last,
          palette.background,
        );
        final edgeLuminances = material.rimGradient.colors.map(
          (edge) => Color.alphaBlend(edge, fill).computeLuminance(),
        );
        if (palette.brightness == Brightness.dark) {
          for (final luminance in edgeLuminances) {
            expect(
              luminance - fill.computeLuminance(),
              lessThan(0.09),
              reason: '$role must not draw a glaring white rim',
            );
          }
        } else {
          expect(
            edgeLuminances.any(
              (luminance) => fill.computeLuminance() - luminance > 0.06,
            ),
            isTrue,
            reason: '$role needs a shaded edge on a pale backdrop',
          );
        }
      }
    });
  }

  testWidgets('reading palette and brightness override own liquid lighting', (
    tester,
  ) async {
    final cool = await _resolve(
      tester,
      ReaderThemes.day,
      outlineColor: const Color(0xff547b9d),
    );
    final warm = await _resolve(
      tester,
      ReaderThemes.day,
      outlineColor: const Color(0xff9d7354),
    );
    expect(cool.rimGradient.colors, isNot(warm.rimGradient.colors));

    final darkOverride = await _resolve(
      tester,
      ReaderThemes.day,
      color: ReaderThemes.navy.surface,
      outlineColor: ReaderThemes.navy.border,
      brightness: Brightness.dark,
    );
    final darkFill = Color.alphaBlend(
      darkOverride.liquidGradient.colors.last,
      ReaderThemes.navy.background,
    );
    for (final edge in darkOverride.rimGradient.colors) {
      expect(
        Color.alphaBlend(edge, darkFill).computeLuminance() -
            darkFill.computeLuminance(),
        lessThan(0.09),
      );
    }
  });

  testWidgets('visibility scales every directional lighting stop', (
    tester,
  ) async {
    final full = await _resolve(tester, ReaderThemes.navy);
    final partial = await _resolve(tester, ReaderThemes.navy, visibility: 0.4);
    final hidden = await _resolve(tester, ReaderThemes.navy, visibility: 0);
    for (var i = 0; i < full.rimGradient.colors.length; i++) {
      expect(
        partial.rimGradient.colors[i].a,
        closeTo(full.rimGradient.colors[i].a * 0.4, 0.00001),
      );
      expect(hidden.rimGradient.colors[i].a, 0);
    }
    expect(partial.rimGradient.stops, full.rimGradient.stops);
    expect(partial.rimGradient.begin, full.rimGradient.begin);
    expect(partial.rimGradient.end, full.rimGradient.end);
  });
}

Future<GlassMaterial> _resolve(
  WidgetTester tester,
  ReaderThemePalette palette, {
  GlassSurfaceRole role = GlassSurfaceRole.control,
  Color? color,
  Color? outlineColor,
  Brightness? brightness,
  double visibility = 1,
}) async {
  late GlassMaterial material;
  await tester.pumpWidget(
    MaterialApp(
      theme: palette.toThemeData().copyWith(
        extensions: const [
          UiStyleThemeExtension(
            style: AppUiStyle.glass,
            glassStyle: GlassStyle.liquid,
            liquidGlassOpacity: 0.5,
          ),
        ],
      ),
      home: Builder(
        builder: (context) {
          material = GlassMaterial.resolve(
            context,
            role: role,
            color: color ?? palette.surface,
            outlineColor: outlineColor ?? palette.border,
            brightness: brightness,
            visibility: visibility,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return material;
}
