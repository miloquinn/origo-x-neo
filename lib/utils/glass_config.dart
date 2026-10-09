import 'ui_style.dart';

/// Glass preferences and performance state; visual recipes live in GlassMaterial.
class GlassEffectConfig {
  static double _blurScale = 0.85;
  static bool _reduceEffects = false;
  static bool _disableAllGlassEffects = false;
  static GlassStyle _glassStyle = defaultGlassStyle;
  static double _liquidGlassOpacity = defaultLiquidGlassOpacity;

  static double get blurScale => _blurScale;
  static bool get reduceEffects => _reduceEffects;
  static bool get shouldDisableBlur => _disableAllGlassEffects;
  static double get liquidGlassOpacity => _liquidGlassOpacity;
  static bool get usesLiquidGlass =>
      !_disableAllGlassEffects && _glassStyle == GlassStyle.liquid;

  static void setGlassStyle(GlassStyle style) => _glassStyle = style;

  static void setLiquidGlassOpacity(double value) =>
      _liquidGlassOpacity = normalizeLiquidGlassOpacity(value);

  static void applyPerformanceMode({required bool reduceEffects}) {
    _reduceEffects = reduceEffects;
    _syncBlurScale();
  }

  static void setDisableAllGlassEffects(bool disabled) {
    _disableAllGlassEffects = disabled;
    _syncBlurScale();
  }

  static void _syncBlurScale() {
    _blurScale = _disableAllGlassEffects ? 0 : (_reduceEffects ? 0.65 : 0.85);
  }
}
