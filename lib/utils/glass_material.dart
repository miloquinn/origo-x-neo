import 'package:flutter/material.dart';

import 'glass_config.dart';
import 'ui_style.dart';

/// Material intent, independent of any component's geometry or interaction.
enum GlassSurfaceRole { control, floating, panel, selection }

enum GlassMaterialMode { solid, frosted, liquid }

/// One resolved recipe for every bounded glass background and liquid renderer.
/// Material tuning belongs here; consumers supply only semantic palette colors.
@immutable
class GlassMaterial {
  const GlassMaterial._({
    required this.mode,
    required this.color,
    required this.gradient,
    required this.border,
    required this.shadows,
    required this.blurSigma,
    required this.liquidGradient,
    required this.rimGradient,
    required this.refractionStrength,
    required this.visibility,
    required this.progressiveTint,
  });

  final GlassMaterialMode mode;
  final Color color;
  final LinearGradient? gradient;
  final BorderSide border;
  final List<BoxShadow> shadows;
  final double blurSigma;
  final LinearGradient liquidGradient;
  final LinearGradient rimGradient;
  final double refractionStrength;
  final double visibility;
  final LinearGradient? progressiveTint;

  /// Progressive consumers apply only their height/clear-tail geometry limits.
  double get progressiveBlurSigma =>
      blurSigma * (mode == GlassMaterialMode.liquid ? 1 : 2);

  static double _liquidTintOpacity(double clearOpacity, double amount) =>
      clearOpacity + (0.88 - clearOpacity) * amount;

  // Capability renderers consume these values, never invent another recipe.
  static const liquidFallbackSigma = 2.5;
  static const liquidSamplingSigma = 0.75;
  static const rimInset = 0.75;
  static const rimWidth = 1.25;

  static GlassMaterialMode modeOf(
    BuildContext context, {
    bool useGlass = true,
  }) {
    final appearance = Theme.of(context).extension<UiStyleThemeExtension>();
    if (!useGlass ||
        GlassEffectConfig.shouldDisableBlur ||
        MediaQuery.highContrastOf(context) ||
        appearance?.isMaterial3Style == true) {
      return GlassMaterialMode.solid;
    }
    final liquid =
        appearance?.glassStyle == GlassStyle.liquid ||
        (appearance == null && GlassEffectConfig.usesLiquidGlass);
    return liquid ? GlassMaterialMode.liquid : GlassMaterialMode.frosted;
  }

  static GlassMaterial resolve(
    BuildContext context, {
    GlassSurfaceRole role = GlassSurfaceRole.control,
    Color? color,
    Color? outlineColor,
    Color? shadowColor,
    Brightness? brightness,
    bool enabled = true,
    bool emphasized = false,
    bool useGlass = true,
    double visibility = 1,
  }) {
    assert(visibility >= 0 && visibility <= 1);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appearance = theme.extension<UiStyleThemeExtension>();
    final resolvedBrightness = brightness ?? scheme.brightness;
    final light = resolvedBrightness == Brightness.light;
    var mode = modeOf(context, useGlass: useGlass);
    // Frosted navigation retains the established solid selection marker.
    if (role == GlassSurfaceRole.selection &&
        mode != GlassMaterialMode.liquid) {
      mode = GlassMaterialMode.solid;
    }
    final base =
        color ??
        switch (role) {
          GlassSurfaceRole.control => scheme.secondaryContainer,
          GlassSurfaceRole.selection => Color.lerp(
            appearance?.isMaterial3Style == true
                ? scheme.surfaceContainerHighest
                : scheme.surface,
            scheme.primary,
            light ? 0.13 : 0.24,
          )!,
          GlassSurfaceRole.floating || GlassSurfaceRole.panel =>
            appearance?.isMaterial3Style == true
                ? scheme.surfaceContainerHigh
                : Color.lerp(
                    scheme.surface,
                    scheme.primary,
                    light ? 0.08 : 0.06,
                  )!,
        };
    final solid = (enabled ? base : Color.lerp(base, scheme.surface, 0.42)!)
        .withValues(alpha: visibility);
    final clean = light ? Color.lerp(base, Colors.white, 0.18)! : base;
    final highlight = Color.lerp(clean, Colors.white, light ? 0.24 : 0.12)!;
    final density = switch (role) {
      GlassSurfaceRole.control => light ? 0.68 : 0.52,
      GlassSurfaceRole.floating => (light ? 0.60 : 0.30) + 0.08,
      GlassSurfaceRole.panel => light ? 0.90 : 0.84,
      GlassSurfaceRole.selection => 1.0,
    };
    final alpha = (enabled ? 1.0 : 0.62) * visibility;
    final leading = (density + (emphasized ? 0.14 : 0)).clamp(0.0, 1.0);
    final trailing = (leading - 0.14).clamp(0.0, 1.0);
    final sourceOutline =
        outlineColor ??
        (emphasized || role == GlassSurfaceRole.selection
            ? scheme.primary
            : scheme.outlineVariant);
    final borderAlpha = role == GlassSurfaceRole.selection
        ? (light ? 0.08 : 0.16)
        : mode == GlassMaterialMode.solid
        ? (enabled ? 0.72 : 0.34)
        : enabled
        ? (emphasized ? 0.62 : 0.42)
        : 0.24;
    final border = BorderSide(
      color:
          (mode == GlassMaterialMode.solid
                  ? sourceOutline
                  : Color.lerp(
                      sourceOutline,
                      Colors.white,
                      light ? 0.16 : 0.24,
                    )!)
              .withValues(alpha: borderAlpha * visibility),
      width: role == GlassSurfaceRole.selection ? 0.8 : 1,
    );
    final castsShadow =
        role == GlassSurfaceRole.floating || role == GlassSurfaceRole.panel;
    final shadow = shadowColor ?? scheme.shadow;
    final opacity = normalizeLiquidGlassOpacity(
      appearance?.liquidGlassOpacity ?? GlassEffectConfig.liquidGlassOpacity,
    );
    final liquidLead = _liquidTintOpacity(
      role == GlassSurfaceRole.panel ? 0.72 : (light ? 0.32 : 0.26),
      opacity,
    );
    final liquidTrail = _liquidTintOpacity(
      role == GlassSurfaceRole.panel ? 0.64 : 0.18,
      opacity,
    );
    final blurBase = switch (role) {
      GlassSurfaceRole.control || GlassSurfaceRole.selection => 8.0,
      GlassSurfaceRole.floating => 15.0,
      GlassSurfaceRole.panel => 25.0,
    };
    // A pale reflected edge alone disappears on light canvases and becomes a
    // white outline on dark ones. Keep the reflected light close to the actual
    // surface, with a palette-derived backlit edge completing the contour.
    final reflectedEdge = Color.lerp(
      Color.lerp(base, Colors.white, light ? 0.52 : 0.08),
      sourceOutline,
      light ? 0.10 : 0.40,
    )!;
    final shadedEdge = Color.lerp(
      sourceOutline,
      light ? scheme.onSurface : base,
      light ? 0.16 : 0.35,
    )!;
    return GlassMaterial._(
      mode: mode,
      visibility: visibility,
      color: solid,
      gradient: mode == GlassMaterialMode.frosted
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                highlight.withValues(alpha: leading * alpha),
                clean.withValues(alpha: trailing * alpha),
              ],
            )
          : null,
      border: border,
      shadows: castsShadow && visibility > 0
          ? [
              BoxShadow(
                color: shadow.withValues(
                  alpha: (light ? 0.10 : 0.25) * visibility,
                ),
                blurRadius: light ? 24 : 32,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
      blurSigma: blurBase * GlassEffectConfig.blurScale,
      liquidGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            base,
            Colors.white,
            light ? 0.35 : 0.12,
          )!.withValues(alpha: liquidLead * visibility),
          base.withValues(alpha: liquidTrail * visibility),
        ],
      ),
      rimGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          reflectedEdge.withValues(alpha: (light ? 0.52 : 0.36) * visibility),
          reflectedEdge.withValues(alpha: (light ? 0.08 : 0.10) * visibility),
          shadedEdge.withValues(alpha: (light ? 0.16 : 0.08) * visibility),
          shadedEdge.withValues(alpha: (light ? 0.30 : 0.24) * visibility),
        ],
        stops: const [0, 0.42, 0.65, 1],
      ),
      refractionStrength: GlassEffectConfig.reduceEffects ? 3 : 6,
      progressiveTint: mode == GlassMaterialMode.liquid && opacity > 0
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                base.withValues(alpha: _liquidTintOpacity(0, opacity)),
                base.withValues(alpha: 0.55 * opacity),
                base.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            )
          : null,
    );
  }
}
