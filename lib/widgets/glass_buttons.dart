import 'package:flutter/material.dart';

import 'elastic_press.dart';
import 'glass_control_surface.dart';

/// Native icon interaction with shared spring motion and glass materials.
/// Role adapters own their dimensions and palette; layout stays at rest.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.dimension = 44,
    this.iconSize = 22,
    this.color,
    this.foregroundColor,
    this.brightness,
    this.border,
    this.blurBackground = true,
    this.highlighted = false,
    this.animatePress = true,
    this.padding = EdgeInsets.zero,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double dimension;
  final double iconSize;
  final Color? color;
  final Color? foregroundColor;
  final Brightness? brightness;
  final BorderSide? border;
  final bool blurBackground;
  final bool highlighted;
  final bool animatePress;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: dimension,
    child: _GlassButtonFrame(
      enabled: onPressed != null,
      animatePress: animatePress,
      shape: const CircleBorder(),
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
      brightness: brightness,
      border: border,
      highlighted: highlighted,
      blurBackground: blurBackground,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        style: IconButton.styleFrom(
          foregroundColor: foregroundColor,
          disabledForegroundColor: foregroundColor?.withValues(alpha: 0.58),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          padding: padding,
          minimumSize: Size.square(dimension),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
          iconSize: iconSize,
        ),
      ),
    ),
  );
}

/// Compact 44 px tools used by the bookshelf and primary page headers.
class GlassToolbarButton extends StatelessWidget {
  const GlassToolbarButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.highlighted = false,
    this.blurBackground = true,
    this.foregroundColor,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool highlighted;
  final bool blurBackground;
  final Color? foregroundColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassIconButton(
      icon: Icon(icon),
      iconSize: 20,
      tooltip: tooltip,
      onPressed: onPressed,
      highlighted: highlighted,
      blurBackground: blurBackground,
      color:
          color ??
          (highlighted ? scheme.primaryContainer : scheme.surfaceContainer),
      foregroundColor:
          foregroundColor ??
          (highlighted
              ? scheme.onPrimaryContainer
              : scheme.onSurface.withValues(alpha: 0.78)),
    );
  }
}

/// A content-sized text capsule with a minimum 44 px interaction target.
class GlassTextButton extends StatelessWidget {
  const GlassTextButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tooltip,
    this.blurBackground = true,
    this.color,
    this.foregroundColor,
    this.highlighted = false,
    this.brightness,
    this.minimumHeight = 44,
    this.border,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool blurBackground;
  final Color? color;
  final Color? foregroundColor;
  final bool highlighted;
  final Brightness? brightness;
  final double minimumHeight;
  final BorderSide? border;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = _GlassButtonFrame(
      enabled: onPressed != null,
      shape: const StadiumBorder(),
      color:
          color ??
          (highlighted ? scheme.primaryContainer : scheme.surfaceContainerHigh),
      highlighted: highlighted,
      brightness: brightness,
      border: border,
      blurBackground: blurBackground,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor:
              foregroundColor ??
              (highlighted ? scheme.onPrimaryContainer : scheme.primary),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          minimumSize: Size(44, minimumHeight),
          padding: padding,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
        ),
        child: child,
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _GlassButtonFrame extends StatelessWidget {
  const _GlassButtonFrame({
    required this.enabled,
    required this.shape,
    required this.color,
    required this.child,
    this.brightness,
    this.border,
    this.animatePress = true,
    this.highlighted = false,
    this.blurBackground = true,
  });

  final bool enabled;
  final OutlinedBorder shape;
  final Color color;
  final Widget child;
  final Brightness? brightness;
  final BorderSide? border;
  final bool animatePress;
  final bool highlighted;
  final bool blurBackground;

  @override
  Widget build(BuildContext context) {
    final surface = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: GlassControlSurface(
              shape: shape,
              color: color,
              brightness: brightness,
              border: border,
              enabled: enabled,
              emphasized: highlighted,
              blurBackground: blurBackground,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Border padding belongs to the optical surface, not the hit target.
        Material(type: MaterialType.transparency, child: child),
      ],
    );
    return animatePress
        ? ElasticPress(enabled: enabled, child: surface)
        : surface;
  }
}
