import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setLiquidGlassOpacity(0);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  test('liquid chrome stays lighter and remembers style while disabled', () {
    final frostedBlur = GlassEffectConfig.appBarBlur;
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    expect(GlassEffectConfig.usesLiquidGlass, isTrue);
    expect(GlassEffectConfig.appBarBlur, lessThan(frostedBlur));
    GlassEffectConfig.setDisableAllGlassEffects(true);
    expect(GlassEffectConfig.usesLiquidGlass, isFalse);
    expect(GlassEffectConfig.appBarBlur, 0);
    GlassEffectConfig.setDisableAllGlassEffects(false);
    expect(GlassEffectConfig.usesLiquidGlass, isTrue);
  });

  testWidgets('light chrome follows the active theme tint', (tester) async {
    const surface = Color(0xFFF5F2F7);
    const primary = Color(0xFF2E7D32);
    late Color surfaceColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            surface: surface,
            primary: primary,
          ),
        ),
        home: Builder(
          builder: (context) {
            surfaceColor = GlassEffectConfig.chromeSurfaceColor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final expected = Color.lerp(surface, primary, 0.08)!;
    expect(surfaceColor.a, closeTo(0.60, 0.01));
    expect(surfaceColor.r, closeTo(expected.r, 0.001));
    expect(surfaceColor.g, closeTo(expected.g, 0.001));
    expect(surfaceColor.b, closeTo(expected.b, 0.001));
  });

  testWidgets('dark chrome also keeps a restrained theme tint', (tester) async {
    const darkSurface = Color(0xFF17191D);
    const primary = Color(0xFF85B7D6);
    late Color surfaceColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            surface: darkSurface,
            primary: primary,
          ),
        ),
        home: Builder(
          builder: (context) {
            surfaceColor = GlassEffectConfig.chromeSurfaceColor(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final expected = Color.lerp(darkSurface, primary, 0.06)!;
    expect(surfaceColor.r, closeTo(expected.r, 0.001));
    expect(surfaceColor.g, closeTo(expected.g, 0.001));
    expect(surfaceColor.b, closeTo(expected.b, 0.001));
    expect(
      surfaceColor.a,
      closeTo(GlassEffectConfig.chromeOpacityFor(Brightness.dark), 0.01),
    );
  });

  test('all floating chrome uses the same adaptive opacity', () {
    expect(
      GlassEffectConfig.chromeOpacityFor(Brightness.light),
      closeTo(0.60, 0.001),
    );
    expect(GlassEffectConfig.readingTopBarBlur, GlassEffectConfig.appBarBlur);
    expect(
      GlassEffectConfig.readingBottomBarBlur,
      GlassEffectConfig.navigationBarBlur,
    );
  });

  test(
    'liquid tint opacity keeps the old clear baseline and rises below solid',
    () {
      const clearOpacity = 0.18;
      final clear = GlassEffectConfig.liquidTintOpacity(clearOpacity, 0);
      final middle = GlassEffectConfig.liquidTintOpacity(clearOpacity, 0.5);
      final opaque = GlassEffectConfig.liquidTintOpacity(clearOpacity, 1);

      expect(clear, clearOpacity);
      expect(middle, greaterThan(clear));
      expect(middle, lessThan(opaque));
      expect(opaque, closeTo(0.88, 0.000001));
      expect(opaque, lessThan(1));
    },
  );
}
