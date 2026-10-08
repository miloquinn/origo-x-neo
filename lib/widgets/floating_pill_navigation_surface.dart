import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/glass_config.dart';
import '../utils/ui_style.dart';
import 'elastic_press.dart';
import 'liquid_glass_surface.dart';

/// Visual surface shared by the home navigation and page-level floating tabs.
class FloatingPillNavigationSurface extends StatelessWidget {
  const FloatingPillNavigationSurface({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMaterial3Style =
        Theme.of(
          context,
        ).extension<UiStyleThemeExtension>()?.isMaterial3Style ??
        false;
    final isLightTheme = scheme.brightness == Brightness.light;
    final disableBlur = isMaterial3Style || GlassEffectConfig.shouldDisableBlur;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(height / 2),
    );

    final surface = Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: isMaterial3Style
            ? scheme.surfaceContainerHigh
            : GlassEffectConfig.chromeSurfaceColor(context),
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(height / 2),
          side: BorderSide(
            color: scheme.outline.withValues(
              alpha: isMaterial3Style ? 0.18 : (isLightTheme ? 0.08 : 0.14),
            ),
            width: 0.6,
          ),
        ),
      ),
    );

    return ElasticPress(
      edgePullOnly: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              color: isMaterial3Style
                  ? scheme.shadow.withValues(alpha: 0.1)
                  : GlassEffectConfig.chromeShadowColor(
                      source: scheme.shadow,
                      brightness: scheme.brightness,
                      darkOpacity: 0.16,
                    ),
              blurRadius: isMaterial3Style ? 18 : (isLightTheme ? 24 : 32),
              offset: const Offset(0, 9),
            ),
            if (!isMaterial3Style && !isLightTheme)
              const BoxShadow(
                color: Color(0x14000000),
                blurRadius: 48,
                offset: Offset(0, 16),
              ),
          ],
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: ShapeBorderClipper(shape: shape),
                  child: !disableBlur && GlassEffectConfig.usesLiquidGlass
                      ? LiquidGlassSurface(
                          shape: shape,
                          color: GlassEffectConfig.chromeSurfaceColor(context),
                          child: SizedBox(width: width, height: height),
                        )
                      : disableBlur
                      ? surface
                      : BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: GlassEffectConfig.navigationBarBlur,
                            sigmaY: GlassEffectConfig.navigationBarBlur,
                          ),
                          child: surface,
                        ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
