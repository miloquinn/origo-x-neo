import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/account/account_page.dart';
import '../pages/account/premium_membership_page.dart';
import '../services/account/account.dart';
import '../services/core/app_distribution.dart';
import '../utils/localization_extension.dart';
import 'account_avatar_image.dart';
import 'account_identity_card.dart';
import 'membership_offer_card.dart';

class SettingsAccountCard extends StatelessWidget {
  const SettingsAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final accountState = context.select((MemberAccountController account) {
      final summary = account.summary;
      return (
        effectiveName: summary?.effectiveName,
        username: summary?.username,
        avatarUrl: summary?.avatarUrl,
        loading: account.loading && summary == null,
        premium: account.premiumForDisplay,
        storeReader: account.hasStoreReaderEntitlement,
        permanentReader: account.hasPermanentReaderAccess,
      );
    });
    final account = context.read<MemberAccountController>();
    final l10n = context.l10n;
    final explore = accountState.premium;
    return Column(
      key: const ValueKey('settings-account-membership-group'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountIdentityCard(
          tier: explore
              ? AccountIdentityTier.explore
              : accountState.storeReader ||
                    (AppDistribution.isStore && accountState.permanentReader)
              ? AccountIdentityTier.read
              : AccountIdentityTier.none,
          title: accountState.effectiveName ?? l10n.settingsGuestTitle,
          subtitle: accountState.username == null
              ? AppDistribution.readerLicenseRequired
                    ? l10n.storeReaderLicenseSubtitle
                    : l10n.settingsGuestSubtitle
              : '@${accountState.username}',
          avatar: _AccountAvatar(
            effectiveName: accountState.effectiveName,
            avatarUrl: accountState.avatarUrl,
          ),
          loading: accountState.loading,
          onTap: () => Navigator.of(
            context,
          ).push<void>(MaterialPageRoute(builder: (_) => const AccountPage())),
        ),
        if (!explore) ...[
          const SizedBox(height: 14),
          MembershipOfferCard(
            offerRead: false,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) =>
                    PremiumMembershipPage(account: account, focusBilling: true),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.effectiveName, required this.avatarUrl});

  final String? effectiveName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallbackColor = scheme.primary;
    final resolvedAvatarUrl = avatarUrl;
    final initial = (effectiveName?.trim().isNotEmpty ?? false)
        ? effectiveName!.trim().characters.first.toUpperCase()
        : null;
    const outerSize = 52.0;
    const imageSize = 50.0;
    return Container(
      key: const ValueKey('settings-account-avatar'),
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(1),
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
