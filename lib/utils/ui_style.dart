// 文件说明：应用 UI 风格扩展，定义 Material3 与玻璃态等风格切换。
// 技术要点：工具方法、Flutter。

import 'package:flutter/material.dart';

enum AppUiStyle { glass, material3 }

double normalizeLiquidGlassOpacity(double value) =>
    value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0;

enum GlassStyle {
  frosted,
  liquid;

  String get storageValue {
    switch (this) {
      case GlassStyle.frosted:
        return 'frosted';
      case GlassStyle.liquid:
        return 'liquid';
    }
  }

  static GlassStyle fromStorage(String? value) {
    switch (value) {
      case 'liquid':
        return GlassStyle.liquid;
      case 'frosted':
        return GlassStyle.frosted;
      default:
        return defaultGlassStyle;
    }
  }
}

/// Shared defaults for startup, saved-preference fallback and theme surfaces.
const defaultGlassStyle = GlassStyle.liquid;
const double defaultLiquidGlassOpacity = 0.5;

extension AppUiStyleX on AppUiStyle {
  String get storageValue {
    switch (this) {
      case AppUiStyle.glass:
        return 'glass';
      case AppUiStyle.material3:
        return 'material3';
    }
  }
}

AppUiStyle appUiStyleFromStorage(String? value) {
  switch (value) {
    case 'material3':
      return AppUiStyle.material3;
    case 'glass':
    default:
      return AppUiStyle.glass;
  }
}

@immutable
class UiStyleThemeExtension extends ThemeExtension<UiStyleThemeExtension> {
  final AppUiStyle style;
  final GlassStyle glassStyle;
  final double liquidGlassOpacity;

  const UiStyleThemeExtension({
    required this.style,
    this.glassStyle = defaultGlassStyle,
    this.liquidGlassOpacity = defaultLiquidGlassOpacity,
  });

  bool get isMaterial3Style => style == AppUiStyle.material3;

  @override
  UiStyleThemeExtension copyWith({
    AppUiStyle? style,
    GlassStyle? glassStyle,
    double? liquidGlassOpacity,
  }) {
    return UiStyleThemeExtension(
      style: style ?? this.style,
      glassStyle: glassStyle ?? this.glassStyle,
      liquidGlassOpacity: liquidGlassOpacity ?? this.liquidGlassOpacity,
    );
  }

  @override
  UiStyleThemeExtension lerp(
    covariant ThemeExtension<UiStyleThemeExtension>? other,
    double t,
  ) {
    if (other is! UiStyleThemeExtension) return this;
    final selected = t < 0.5 ? this : other;
    return selected.copyWith(
      liquidGlassOpacity:
          liquidGlassOpacity +
          (other.liquidGlassOpacity - liquidGlassOpacity) * t,
    );
  }
}
