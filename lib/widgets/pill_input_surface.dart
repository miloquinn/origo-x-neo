import 'package:flutter/material.dart';

import 'glass_control_surface.dart';

/// The common glass shell for search fields and multiline AI composers.
/// Foreground editing and actions keep their native layout and gestures.
class PillInputSurface extends StatelessWidget {
  const PillInputSurface({
    super.key,
    required this.child,
    this.fillColor,
    this.borderColor,
    this.brightness,
    this.enabled = true,
    this.blurBackground = true,
    this.focusColor,
    this.shadows,
  });

  final Widget child;
  final Color? fillColor;
  final Color? borderColor;
  final Brightness? brightness;
  final bool enabled;
  final bool blurBackground;
  final Color? focusColor;
  final List<BoxShadow>? shadows;

  static const shape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(999)),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: GlassControlSurface(
              shape: shape,
              color: fillColor ?? scheme.surfaceContainerLow,
              brightness: brightness,
              border: BorderSide(
                color: borderColor ?? scheme.outline.withValues(alpha: .18),
                width: .8,
              ),
              enabled: enabled,
              blurBackground: blurBackground,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (focusColor case final color?)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: shape.copyWith(
                    side: BorderSide(color: color.withValues(alpha: .65)),
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: shadows == null
          ? content
          : DecoratedBox(
              decoration: ShapeDecoration(shape: shape, shadows: shadows),
              child: content,
            ),
    );
  }
}
