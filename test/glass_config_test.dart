import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  test('startup glass configuration uses liquid with medium opacity', () {
    expect(GlassEffectConfig.usesLiquidGlass, isTrue);
    expect(GlassEffectConfig.liquidGlassOpacity, 0.5);
  });

  test('disabling effects preserves glass style and opacity preferences', () {
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    GlassEffectConfig.setLiquidGlassOpacity(0.75);
    GlassEffectConfig.setDisableAllGlassEffects(true);
    expect(GlassEffectConfig.shouldDisableBlur, isTrue);
    expect(GlassEffectConfig.usesLiquidGlass, isFalse);
    expect(GlassEffectConfig.blurScale, 0);
    expect(GlassEffectConfig.liquidGlassOpacity, 0.75);
    GlassEffectConfig.setDisableAllGlassEffects(false);
    expect(GlassEffectConfig.usesLiquidGlass, isTrue);
    expect(GlassEffectConfig.liquidGlassOpacity, 0.75);
  });

  test('performance preference survives a complete effects disable cycle', () {
    final normalScale = GlassEffectConfig.blurScale;
    GlassEffectConfig.applyPerformanceMode(reduceEffects: true);
    final reducedScale = GlassEffectConfig.blurScale;
    expect(GlassEffectConfig.reduceEffects, isTrue);
    expect(reducedScale, greaterThan(0));
    expect(reducedScale, lessThan(normalScale));
    GlassEffectConfig.setDisableAllGlassEffects(true);
    expect(GlassEffectConfig.blurScale, 0);
    GlassEffectConfig.setDisableAllGlassEffects(false);
    expect(GlassEffectConfig.blurScale, reducedScale);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
    expect(GlassEffectConfig.reduceEffects, isFalse);
    expect(GlassEffectConfig.blurScale, normalScale);
  });

  test('opacity is normalized without changing the selected glass style', () {
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    GlassEffectConfig.setLiquidGlassOpacity(-1);
    expect(GlassEffectConfig.liquidGlassOpacity, 0);
    GlassEffectConfig.setLiquidGlassOpacity(2);
    expect(GlassEffectConfig.liquidGlassOpacity, 1);
    expect(GlassEffectConfig.usesLiquidGlass, isTrue);
  });
}
