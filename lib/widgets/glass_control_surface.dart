import 'package:flutter/material.dart';

import '../utils/glass_material.dart';
import 'glass_surface.dart';

export '../utils/glass_material.dart' show GlassSurfaceRole;

/// Control layout adapter. Material decisions belong to GlassSurface.
/// The legacy one-pixel layout inset is explicit here, never in the background.
class GlassControlSurface extends StatelessWidget {
  const GlassControlSurface({
    super.key,
    required this.child,
    this.shape = const StadiumBorder(),
    this.color,
    this.brightness,
    this.outlineColor,
    this.shadowColor,
    this.role = GlassSurfaceRole.control,
    this.enabled = true,
    this.emphasized = false,
    this.useGlass = true,
    this.blurBackground = true,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
  });

  final Widget child;
  final OutlinedBorder shape;
  final Color? color;
  final Brightness? brightness;

  final Color? outlineColor;
  final Color? shadowColor;
  final GlassSurfaceRole role;
  final bool enabled;
  final bool emphasized;
  final bool useGlass;
  final bool blurBackground;
  final Duration duration;
  final Curve curve;

  static bool usesGlass(BuildContext context, {bool useGlass = true}) =>
      GlassMaterial.modeOf(context, useGlass: useGlass) !=
      GlassMaterialMode.solid;

  @override
  Widget build(BuildContext context) => GlassSurface(
    shape: shape,
    role: role,
    color: color,
    outlineColor: outlineColor,
    shadowColor: shadowColor,
    brightness: brightness,
    enabled: enabled,
    emphasized: emphasized,
    useGlass: useGlass,
    filterBackground: blurBackground,
    duration: duration,
    curve: curve,
    child: Padding(
      padding: shape.copyWith(side: const BorderSide()).dimensions,
      child: Opacity(opacity: enabled ? 1 : 0.58, child: child),
    ),
  );
}
