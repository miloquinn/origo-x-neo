import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/glass_material.dart';
import 'gradient_top_backdrop.dart';

/// The single glass chrome surface shared by the home shell and pushed pages.
class GlassTopBar extends StatelessWidget {
  // Finish the taper inside the bar so scrolling content remains sharp.
  static const _clearTail = 4.0;

  const GlassTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.centerTitle = false,
    this.systemTopInset,
    this.contentHeight = 60,
    this.titleFontSize = 34,
    this.titleFontWeight = FontWeight.w700,
    this.horizontalPadding = 16,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool centerTitle;
  final double? systemTopInset;
  final double contentHeight;
  final double titleFontSize;
  final FontWeight titleFontWeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topInset = systemTopInset ?? MediaQuery.viewPaddingOf(context).top;
    final material = GlassMaterial.resolve(
      context,
      role: GlassSurfaceRole.floating,
    );
    final useBlur = material.mode != GlassMaterialMode.solid;
    final height = topInset + contentHeight;
    final peakSigma = math.min(
      material.blurSigma * (material.mode == GlassMaterialMode.liquid ? 1 : 2),
      math.max(0, height - 16) / 3,
    );
    final titleStyle = TextStyle(
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      color: scheme.onSurface,
      height: 1,
      shadows: useBlur && scheme.brightness == Brightness.dark
          ? [
              Shadow(
                color: scheme.surface.withValues(alpha: 0.9),
                blurRadius: 10,
              ),
            ]
          : null,
    );
    final content = SizedBox(
      key: const ValueKey('glass-top-bar-surface'),
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topInset + 6,
          horizontalPadding,
          6,
        ),
        child: centerTitle
            ? NavigationToolbar(
                centerMiddle: true,
                middleSpacing: 16,
                leading: leading,
                trailing: trailing,
                middle: IgnorePointer(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
              )
            : Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ?trailing,
                ],
              ),
      ),
    );

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: GradientTopBackdrop(
              height: height,
              clearTail: _clearTail,
              fallbackBands: 16,
              maxSigma: peakSigma,
            ),
          ),
          content,
        ],
      ),
    );
  }
}
