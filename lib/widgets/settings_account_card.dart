import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/account/account_page.dart';
import '../pages/account/premium_membership_page.dart';
import '../services/account/account.dart';
import '../services/core/app_distribution.dart';
import '../utils/localization_extension.dart';
import '../utils/page_style_helper.dart';
import 'account_avatar_image.dart';
import 'account_identity_card.dart';
import 'premium_card_style.dart';
import 'membership_offer_card.dart';
import '../pages/account/store_reader_unlock_page.dart';

class SettingsAccountCard extends StatelessWidget {
  const SettingsAccountCard({
    super.key,
    this.quiet = false,
    this.showMembershipSection = false,
  }) : assert(!showMembershipSection || quiet);

  final bool quiet;
  final bool showMembershipSection;

  @override
  Widget build(BuildContext context) {
    final account = context.watch<MemberAccountController>();
    final summary = account.summary;
    final premium = account.hasPremiumAccess && !quiet;
    final scheme = Theme.of(context).colorScheme;
    final palette = PageStyleHelper.palette(context);
    final title =
        summary?.effectiveName ??
        (quiet
            ? context.l10n.settingsGuestTitle
            : context.l10n.settingsAccountGuestTitle);
    final subtitle = summary == null
        ? quiet
              ? context.l10n.settingsGuestSubtitle
              : context.l10n.settingsAccountGuestSubtitle
        : '@${summary.username} · ${account.membership == null || account.membershipSyncFailed ? context.l10n.premiumSyncPending : context.l10n.settingsAccountVerified}';

    if (showMembershipSection) {
      final l10n = context.l10n;
      final explore = account.hasPremiumAccess;
      // A trial or sandbox session is not an owned Read plan. Direct builds
      // already include Read, so their next step is Explore.
      final offerRead =
          AppDistribution.isStore &&
          !account.hasPermanentReaderAccess &&
          !explore;
      return Column(
        key: const ValueKey('settings-account-membership-group'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AccountIdentityCard(
            tier: explore
                ? AccountIdentityTier.explore
                : account.hasStoreReaderEntitlement ||
                      (AppDistribution.isStore &&
                          account.hasPermanentReaderAccess)
                ? AccountIdentityTier.read
                : AccountIdentityTier.none,
            title: title,
            subtitle: summary == null
                ? l10n.settingsGuestSubtitle
                : '@${summary.username}',
            avatar: _AccountAvatar(
              effectiveName: summary?.effectiveName,
              avatarUrl: summary?.avatarUrl,
              premium: false,
              quiet: true,
            ),
            loading: account.loading,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const AccountPage()),
            ),
          ),
          if (!explore) ...[
            const SizedBox(height: 14),
            MembershipOfferCard(
              offerRead: offerRead,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => offerRead
                      ? StoreReaderUnlockPage(account: account)
                      : PremiumMembershipPage(
                          account: account,
                          focusBilling: true,
                        ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Semantics(
      button: true,
      label: context.l10n.settingsAccountOpen,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('settings-account-card'),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const AccountPage())),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: quiet ? palette.card : null,
              gradient: quiet
                  ? null
                  : premium
                  ? premiumCardGradient
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF123456), Color(0xFF1768B4)],
                    ),
              border: quiet
                  ? Border.all(color: palette.border)
                  : premium
                  ? Border.all(
                      color: premiumGold.withValues(alpha: 0.78),
                      width: 1.5,
                    )
                  : null,
              boxShadow: quiet
                  ? null
                  : [
                      BoxShadow(
                        color: (premium ? premiumGold : const Color(0xFF1768B4))
                            .withValues(alpha: premium ? 0.24 : 0.2),
                        blurRadius: premium ? 30 : 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                if (premium)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _PremiumCardPattern()),
                    ),
                  )
                else if (!quiet)
                  const Positioned(
                    right: -18,
                    bottom: -32,
                    child: _AccountCardMark(),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 17, 16, premium ? 14 : 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AccountAvatar(
                            effectiveName: summary?.effectiveName,
                            avatarUrl: summary?.avatarUrl,
                            premium: premium,
                            quiet: quiet,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: quiet
                                                  ? scheme.onSurface
                                                  : premium
                                                  ? premiumIvory
                                                  : Colors.white,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                            ),
                                      ),
                                    ),
                                    if (premium) ...[
                                      const SizedBox(width: 8),
                                      _PremiumBadge(
                                        label:
                                            context.l10n.accountSupporterBadge,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: quiet
                                            ? scheme.onSurfaceVariant
                                            : Colors.white.withValues(
                                                alpha: premium ? 0.68 : 0.72,
                                              ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (account.loading && summary == null)
                            const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (quiet ? scheme.primary : Colors.white)
                                    .withValues(alpha: premium ? 0.1 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      (quiet
                                              ? scheme.primary
                                              : premium
                                              ? premiumGold
                                              : Colors.white)
                                          .withValues(
                                            alpha: premium ? 0.28 : 0.14,
                                          ),
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: quiet
                                    ? scheme.onSurfaceVariant
                                    : premium
                                    ? premiumIvory
                                    : scheme.surface,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      if (premium) ...[
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: premiumGold,
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                context.l10n.premiumLifetimeTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFF8DDA9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            Text(
                              'EXPLORE',
                              style: TextStyle(
                                color: premiumIvory.withValues(alpha: 0.48),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
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
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('settings-account-premium-badge'),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: premiumGold.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: premiumGold.withValues(alpha: 0.34)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: premiumGold,
          size: 12,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            color: premiumIvory,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PremiumCardPattern extends CustomPainter {
  const _PremiumCardPattern();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              premiumGold.withValues(alpha: 0.17),
              premiumGold.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.92, size.height * 0.04),
              radius: size.width * 0.74,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
    final line = Paint()
      ..color = premiumIvory.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final radius = size.height * 0.64;
    final center = Offset(size.width * 0.98, size.height * 0.03);
    canvas.drawCircle(center, radius, line);
    canvas.drawCircle(center, radius * 0.72, line);

    final innerBorder = Paint()
      ..color = premiumIvory.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4.5, 4.5, size.width - 9, size.height - 9),
        const Radius.circular(18),
      ),
      innerBorder,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumCardPattern oldDelegate) => false;
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.effectiveName,
    required this.avatarUrl,
    required this.premium,
    required this.quiet,
  });

  final String? effectiveName;
  final String? avatarUrl;
  final bool premium;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackColor = quiet
        ? scheme.primary
        : premium
        ? premiumIvory
        : Colors.white;
    final resolvedAvatarUrl = avatarUrl;
    final initial = (effectiveName?.trim().isNotEmpty ?? false)
        ? effectiveName!.trim().characters.first.toUpperCase()
        : null;
    final outerSize = premium ? 60.0 : 52.0;
    final imageSize = premium ? 52.0 : 50.0;
    return Container(
      key: const ValueKey('settings-account-avatar'),
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        color: quiet
            ? scheme.primary.withValues(alpha: 0.12)
            : premium
            ? premiumGold.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(
          color: quiet
              ? scheme.primary.withValues(alpha: 0.2)
              : premium
              ? premiumGold.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.2),
          width: premium ? 2.2 : 1,
        ),
        boxShadow: premium
            ? [
                BoxShadow(
                  color: premiumGold.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(premium ? 3 : 1),
      child: ClipOval(
        key: const ValueKey('settings-account-avatar-clip'),
        child: SizedBox(
          width: imageSize,
          height: imageSize,
          child: resolvedAvatarUrl != null
              ? AccountAvatarImage(
                  url: Uri.parse(resolvedAvatarUrl),
                  fallback: _avatarFallback(initial, fallbackColor),
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                )
              : _avatarFallback(initial, fallbackColor),
        ),
      ),
    );
  }

  Widget _avatarFallback(String? initial, Color color) => Center(
    key: const ValueKey('settings-account-avatar-fallback'),
    child: initial == null
        ? Icon(Icons.person_outline_rounded, color: color, size: 27)
        : Text(
            initial,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
  );
}

class _AccountCardMark extends StatelessWidget {
  const _AccountCardMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 24,
        ),
      ),
    );
  }
}
