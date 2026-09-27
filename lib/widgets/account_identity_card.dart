import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';
import '../utils/page_style_helper.dart';

enum AccountIdentityTier { none, read, explore }

/// An owned membership lives on the identity card; purchase offers stay separate.
class AccountIdentityCard extends StatelessWidget {
  const AccountIdentityCard({
    super.key,
    required this.tier,
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.loading,
    required this.onTap,
  });

  final AccountIdentityTier tier;
  final String title;
  final String subtitle;
  final Widget avatar;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = PageStyleHelper.palette(context);
    final explore = tier == AccountIdentityTier.explore;
    final member = tier != AccountIdentityTier.none;
    final dark = theme.brightness == Brightness.dark;
    final metal = Color.lerp(scheme.primary, Colors.white, 0.82)!;
    final foreground = explore ? metal : scheme.onSurface;
    final accent = explore ? metal : scheme.primary;
    final base = explore
        ? Color.lerp(scheme.primary, Colors.black, 0.79)!
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: dark ? 0.08 : 0.04),
            palette.card,
          );
    final sheen = explore
        ? Color.lerp(scheme.primary, Colors.black, 0.51)!
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: dark ? 0.20 : 0.13),
            palette.card,
          );

    return Container(
      key: const ValueKey('settings-account-panel'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: explore
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: dark ? 0.08 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: member ? base : palette.card,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: member
                  ? accent.withValues(alpha: explore ? 0.42 : 0.25)
                  : palette.border,
            ),
            gradient: member
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [base, sheen, base],
                    stops: const [0, 0.66, 1],
                  )
                : null,
          ),
          child: InkWell(
            key: const ValueKey('settings-account-card'),
            onTap: onTap,
            child: Semantics(
              button: true,
              label: context.l10n.settingsAccountOpen,
              child: Stack(
                children: [
                  if (member)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: CustomPaint(
                            painter: _MembershipEngraving(
                              color: accent,
                              explore: explore,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(member ? 22 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            avatar,
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    key: const ValueKey(
                                      'settings-account-name',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w600,
                                          fontSize: member ? 19 : null,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: explore
                                          ? metal.withValues(alpha: 0.78)
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox.square(
                              dimension: 24,
                              child: loading
                                  ? Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: accent,
                                      ),
                                    )
                                  : Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: member
                                          ? accent
                                          : scheme.onSurfaceVariant,
                                    ),
                            ),
                          ],
                        ),
                        if (member) ...[
                          const SizedBox(height: 25),
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(
                                      alpha: explore ? 0.08 : 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.26),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        explore
                                            ? Icons.explore_outlined
                                            : Icons.auto_stories_outlined,
                                        size: 17,
                                        color: accent,
                                      ),
                                      const SizedBox(width: 7),
                                      Flexible(
                                        child: Text(
                                          explore
                                              ? context
                                                    .l10n
                                                    .premiumLifetimeTitle
                                              : context
                                                    .l10n
                                                    .storeReaderLicenseTitle,
                                          key: ValueKey(
                                            explore
                                                ? 'settings-account-premium-badge'
                                                : 'settings-account-reader-badge',
                                          ),
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: accent,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 54),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fine page contours and a bookplate seal, like an engraved collector's cover.
class _MembershipEngraving extends CustomPainter {
  const _MembershipEngraving({required this.color, required this.explore});

  final Color color;
  final bool explore;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: explore ? 0.10 : 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var i = 0; i < 12; i++) {
      final step = i * 9.0;
      final curve = Path()
        ..moveTo(size.width * 0.48 + step, -12)
        ..cubicTo(
          size.width * 0.65 + step,
          size.height * 0.25,
          size.width * 0.34 + step,
          size.height * 0.61,
          size.width * 0.72 + step,
          size.height + 18,
        );
      canvas.drawPath(curve, line);
    }

    // A small bookplate is independent of text and remains at the trailing edge.
    canvas.save();
    canvas.translate(size.width - 45, size.height - 42);
    line.color = color.withValues(alpha: explore ? 0.64 : 0.45);
    line.strokeWidth = 0.8;
    if (explore) {
      final seal = Path();
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * math.pi / 4;
        final point = Offset(math.cos(angle) * 20, math.sin(angle) * 20);
        if (i == 0) {
          seal.moveTo(point.dx, point.dy);
        } else {
          seal.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(seal..close(), line);
      canvas.drawCircle(
        Offset.zero,
        16,
        line..color = color.withValues(alpha: 0.20),
      );
    }
    final book = Path()
      ..moveTo(0, -6)
      ..quadraticBezierTo(-6, -11, -12, -8)
      ..lineTo(-12, 8)
      ..quadraticBezierTo(-6, 5, 0, 10)
      ..quadraticBezierTo(6, 5, 12, 8)
      ..lineTo(12, -8)
      ..quadraticBezierTo(6, -11, 0, -6)
      ..lineTo(0, 10);
    canvas.drawPath(
      book,
      line..color = color.withValues(alpha: explore ? 0.75 : 0.55),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MembershipEngraving oldDelegate) =>
      oldDelegate.color != color || oldDelegate.explore != explore;
}
