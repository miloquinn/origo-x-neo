import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/glass_config.dart';
import '../utils/ui_style.dart';

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
    final borderRadius = BorderRadius.circular(height / 2);

    final surface = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isMaterial3Style
            ? scheme.surfaceContainerHigh
            : GlassEffectConfig.chromeSurfaceColor(context),
        borderRadius: borderRadius,
        border: Border.all(
          color: scheme.outline.withValues(
            alpha: isMaterial3Style ? 0.18 : (isLightTheme ? 0.08 : 0.14),
          ),
          width: 0.6,
        ),
      ),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
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
      child: ClipRRect(
        borderRadius: borderRadius,
        child: disableBlur
            ? surface
            : BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassEffectConfig.navigationBarBlur,
                  sigmaY: GlassEffectConfig.navigationBarBlur,
                ),
                child: surface,
              ),
      ),
    );
  }
}
