import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';

/// One next membership step, illustrated with original, theme-tinted paper art.
class MembershipOfferCard extends StatefulWidget {
  const MembershipOfferCard({
    super.key,
    required this.offerRead,
    required this.onTap,
  });

  final bool offerRead;
  final VoidCallback onTap;

  @override
  State<MembershipOfferCard> createState() => _MembershipOfferCardState();
}

class _MembershipOfferCardState extends State<MembershipOfferCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opening = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _opening.value = 1;
    } else if (_opening.status == AnimationStatus.dismissed) {
      _opening.forward();
    }
  }

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // Keep the current accent's hue while guaranteeing a dark paper backdrop.
    final ink = Color.lerp(scheme.primary, Colors.black, 0.64)!;
    final edge = Color.lerp(scheme.primary, Colors.black, 0.54)!;
    return Semantics(
      container: true,
      child: Material(
        key: const ValueKey('settings-membership-offer'),
        color: ink,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey(
            widget.offerRead
                ? 'settings-reader-license'
                : 'settings-membership-entry',
          ),
          onTap: widget.onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ink, edge],
                begin: Alignment.centerLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 19;
                final artWidth = math.min(constraints.maxWidth * 0.40, 180.0);
                return Stack(
                  children: [
                    PositionedDirectional(
                      end: -8,
                      top: largeText ? 90 : 3,
                      bottom: largeText ? 28 : 0,
                      width: artWidth,
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _opening,
                              builder: (context, child) => CustomPaint(
                                key: const ValueKey('membership-paper-art'),
                                painter: _OpeningPagesPainter(
                                  accent: scheme.primary,
                                  progress: Curves.easeOutCubic.transform(
                                    _opening.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        22,
                        24,
                        largeText ? 22 : artWidth - 6,
                        22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.offerRead
                                ? l10n.storeReaderLicenseTitle
                                : l10n.premiumEditorialTitle,
                            key: const ValueKey('settings-membership-title'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: largeText ? artWidth - 30 : 0,
                            ),
                            child: Text(
                              widget.offerRead
                                  ? l10n.basicBenefitsTitle
                                  : l10n.premiumEditionSummary,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.purchaseBenefitsAction,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// A fan of curved pages, drawn locally rather than using a static stock image.
class _OpeningPagesPainter extends CustomPainter {
  const _OpeningPagesPainter({required this.accent, required this.progress});

  final Color accent;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 185, size.height / 200);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 5);
    canvas.scale(scale);
    canvas.rotate(-0.20);
    canvas.translate(-94, -75);

    // Each leaf shares the same bound spine. Opening changes their curvature,
    // not the card's layout, and settles after a single entrance.
    for (var i = 0; i < 9; i++) {
      final spread = i / 8;
      final lift = spread * (30 + 35 * progress);
      final outer = 10 + spread * 24;
      final top = 59 - lift;
      final paper = Path()
        ..moveTo(99, 154)
        ..cubicTo(
          71,
          129 - lift * 0.35,
          38,
          137 - lift * 0.6,
          outer,
          145 - lift,
        )
        ..lineTo(outer - 6, top)
        ..cubicTo(38, top - 15, 75, 44 - lift * 0.3, 98, 71)
        ..cubicTo(
          117,
          48 - lift * 0.45,
          148,
          top - 11,
          173 - spread * 14,
          top + 2,
        )
        ..lineTo(180 - spread * 14, 143 - lift)
        ..cubicTo(152, 136 - lift * 0.6, 123, 133 - lift * 0.3, 99, 154)
        ..close();
      canvas.drawShadow(paper, Colors.black.withValues(alpha: 0.35), 3, false);
      final paperTint = Color.lerp(accent, Colors.white, 0.72 + spread * 0.26)!;
      canvas.drawPath(
        paper,
        Paint()
          ..shader = LinearGradient(
            colors: [
              paperTint,
              Colors.white,
              Color.lerp(paperTint, accent, 0.16)!,
            ],
            stops: const [0, 0.50, 1],
          ).createShader(const Rect.fromLTWH(10, 0, 170, 160)),
      );
      canvas.drawPath(
        paper,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55
          ..color = accent.withValues(alpha: 0.20),
      );
    }
    final spine = Path()
      ..moveTo(98, 71)
      ..quadraticBezierTo(94, 113, 99, 154);
    canvas.drawPath(
      spine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = accent.withValues(alpha: 0.30),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OpeningPagesPainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.progress != progress;
}
