import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/glass_material.dart';
import 'liquid_glass_surface.dart';

export '../utils/glass_material.dart' show GlassSurfaceRole;

/// Shared, layout-neutral background. Components own shape, layout and actions.
/// Shadows stay outside clipping; content is painted above the filtered backdrop.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.role = GlassSurfaceRole.control,
    this.color,
    this.outlineColor,
    this.shadowColor,
    this.brightness,
    this.enabled = true,
    this.emphasized = false,
    this.useGlass = true,
    this.filterBackground = true,
    this.visibility = 1,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
  }) : assert(visibility >= 0 && visibility <= 1);

  final Widget child;
  final OutlinedBorder shape;
  final GlassSurfaceRole role;
  final Color? color;
  final Color? outlineColor;
  final Color? shadowColor;
  final Brightness? brightness;
  final bool enabled;
  final bool emphasized;
  final bool useGlass;
  final bool filterBackground;
  final double visibility;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (visibility == 0) return child;
    final material = GlassMaterial.resolve(
      context,
      role: role,
      color: color,
      outlineColor: outlineColor,
      shadowColor: shadowColor,
      brightness: brightness,
      enabled: enabled,
      emphasized: emphasized,
      useGlass: useGlass,
      visibility: visibility,
    );
    Widget background;
    if (material.mode == GlassMaterialMode.liquid) {
      background = LiquidGlassSurface(
        shape: shape,
        material: material,
        filterBackground: filterBackground,
        child: const SizedBox.expand(),
      );
    } else {
      background = AnimatedContainer(
        duration: duration,
        curve: curve,
        decoration: ShapeDecoration(
          shape: shape.copyWith(side: material.border),
          color: material.gradient == null ? material.color : null,
          gradient: material.gradient,
        ),
      );
      if (material.mode == GlassMaterialMode.frosted && filterBackground) {
        background = BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: material.blurSigma * visibility,
            sigmaY: material.blurSigma * visibility,
          ),
          child: background,
        );
      }
    }
    return DecoratedBox(
      decoration: ShapeDecoration(shape: shape, shadows: material.shadows),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ClipPath(
                clipper: ShapeBorderClipper(shape: shape),
                child: background,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
