import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  test('glass defaults agree across storage and theme extensions', () {
    expect(GlassStyle.fromStorage(null), GlassStyle.liquid);
    expect(GlassStyle.fromStorage('unknown'), GlassStyle.liquid);
    expect(GlassStyle.fromStorage('frosted'), GlassStyle.frosted);
    expect(GlassStyle.fromStorage('liquid'), GlassStyle.liquid);
    const appearance = UiStyleThemeExtension(style: AppUiStyle.glass);
    expect(appearance.glassStyle, GlassStyle.liquid);
    expect(appearance.liquidGlassOpacity, 0.5);
  });

  group('appUiStyleFromStorage', () {
    test('defaults to glass effects when no preference is saved', () {
      expect(appUiStyleFromStorage(null), AppUiStyle.glass);
    });

    test('keeps explicitly saved glass preference', () {
      expect(appUiStyleFromStorage('glass'), AppUiStyle.glass);
    });

    test('keeps explicitly saved Material 3 preference', () {
      expect(appUiStyleFromStorage('material3'), AppUiStyle.material3);
    });
  });

  test(
    'liquid opacity normalization rejects invalid and out-of-range values',
    () {
      expect(normalizeLiquidGlassOpacity(double.nan), 0);
      expect(normalizeLiquidGlassOpacity(double.infinity), 0);
      expect(normalizeLiquidGlassOpacity(-0.2), 0);
      expect(normalizeLiquidGlassOpacity(0.45), 0.45);
      expect(normalizeLiquidGlassOpacity(1.2), 1);
    },
  );

  test('theme extension copyWith preserves and updates opacity', () {
    const original = UiStyleThemeExtension(
      style: AppUiStyle.glass,
      glassStyle: GlassStyle.liquid,
      liquidGlassOpacity: 0.35,
    );

    expect(original.copyWith().liquidGlassOpacity, 0.35);
    expect(
      original.copyWith(style: AppUiStyle.material3).glassStyle,
      GlassStyle.liquid,
    );
    expect(original.copyWith(liquidGlassOpacity: 0.7).liquidGlassOpacity, 0.7);
  });

  test(
    'theme extension lerp switches styles while opacity stays continuous',
    () {
      const clear = UiStyleThemeExtension(
        style: AppUiStyle.glass,
        glassStyle: GlassStyle.frosted,
        liquidGlassOpacity: 0.2,
      );
      const tinted = UiStyleThemeExtension(
        style: AppUiStyle.material3,
        glassStyle: GlassStyle.liquid,
        liquidGlassOpacity: 0.8,
      );

      final early = clear.lerp(tinted, 0.25);
      expect(early.style, AppUiStyle.glass);
      expect(early.glassStyle, GlassStyle.frosted);
      expect(early.liquidGlassOpacity, closeTo(0.35, 0.001));

      final late = clear.lerp(tinted, 0.75);
      expect(late.style, AppUiStyle.material3);
      expect(late.glassStyle, GlassStyle.liquid);
      expect(late.liquidGlassOpacity, closeTo(0.65, 0.001));
    },
  );
}
