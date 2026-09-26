import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/purchase_artwork.dart';
import '../../widgets/purchase_icons.dart';
import '../../widgets/purchase_page_scaffold.dart';
import 'account_page.dart';
import 'premium_policy_page.dart';
import 'store_reader_unlock_page.dart';

class PremiumMembershipPage extends StatelessWidget {
  const PremiumMembershipPage({
    super.key,
    required this.account,
    this.focusBilling = false,
  });

  final MemberAccountController account;

  /// Keeps direct purchase entries focused when the compact page falls back
  /// to its adaptive scrolling layout.
  final bool focusBilling;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([account, account.storePurchase]),
    builder: (context, _) {
      if (AppDistribution.usesStoreBilling &&
          !account.hasPermanentReaderAccess) {
        return StoreReaderUnlockPage(account: account);
      }
      return PurchasePageTheme(
        premium: true,
        child: _PremiumMembershipContent(
          account: account,
          focusBilling: focusBilling,
        ),
      );
    },
  );
}

class _PremiumMembershipContent extends StatefulWidget {
  const _PremiumMembershipContent({
    required this.account,
    required this.focusBilling,
  });

  final MemberAccountController account;
  final bool focusBilling;

  @override
  State<_PremiumMembershipContent> createState() =>
      _PremiumMembershipContentState();
}

class _PremiumMembershipContentState extends State<_PremiumMembershipContent>
    with WidgetsBindingObserver {
  final _redemptionCode = TextEditingController();
  final _footerKey = GlobalKey();
  late final _changes = Listenable.merge([
    widget.account,
    widget.account.storePurchase,
  ]);
  String? _message;
  bool _messageIsError = false;

  bool get _usesAppleBilling => AppDistribution.usesAppleBilling;
  bool get _usesStoreBilling => AppDistribution.usesStoreBilling;
  String get _storeName => _usesAppleBilling ? 'App Store' : 'Google Play';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_usesStoreBilling &&
          widget.account.isAuthenticated &&
          widget.account.hasPermanentReaderAccess) {
        unawaited(_initializeStore());
      }
      if (widget.focusBilling) {
        final footerContext = _footerKey.currentContext;
        if (footerContext != null) {
          Scrollable.ensureVisible(footerContext, alignment: 1);
        }
      }
    });
  }

  Future<void> _initializeStore() async {
    try {
      await widget.account.initializeStorePurchases();
    } catch (error) {
      debugPrint('Premium products unavailable: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.account.synchronize());
    }
  }

  void _showMessage(String text, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = text;
      _messageIsError = error;
    });
  }

  void _showFailure(Object error) {
    if (!mounted) return;
    _showMessage(switch (error) {
      MemberAccountException() => error.message,
      PlatformException() =>
        error.message ?? context.l10n.premiumOperationFailed,
      _ => context.l10n.premiumOperationFailed,
    }, error: true);
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool usePurchaseStatus = false,
  }) async {
    setState(() {
      _message = null;
      _messageIsError = false;
    });
    try {
      await action();
    } catch (error) {
      if (usePurchaseStatus &&
          widget.account.premiumPurchasePhase == StorePurchasePhase.failed) {
        return;
      }
      _showFailure(error);
    }
  }

  Future<void> _redeem() async {
    await _perform(() async {
      await widget.account.redeemMembership(_redemptionCode.text);
      _redemptionCode.clear();
      if (mounted) _showMessage(context.l10n.premiumPurchaseSuccess);
    });
  }

  Future<void> _openSignIn() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const AccountPage()));
    if (mounted && _usesStoreBilling && widget.account.isAuthenticated) {
      unawaited(_initializeStore());
    }
  }

  Future<void> _openUrl(
    Uri uri, {
    LaunchMode mode = LaunchMode.inAppBrowserView,
  }) async {
    try {
      final opened = await launchUrl(uri, mode: mode);
      if (!opened && mounted) {
        _showMessage(context.l10n.premiumLinkFailed, error: true);
      }
    } catch (_) {
      if (mounted) _showMessage(context.l10n.premiumLinkFailed, error: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _redemptionCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _changes,
    builder: (context, _) {
      final account = widget.account;
      return PurchasePageScaffold(
        title: context.l10n.premiumLifetimeTitle,
        body: _summary(account),
        footer: KeyedSubtree(key: _footerKey, child: _footer(account)),
      );
    },
  );

  Widget _summary(MemberAccountController account) {
    final l10n = context.l10n;
    final premium = account.hasPremiumAccess;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          key: const ValueKey('premium-membership-card'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.premiumEditorialTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              l10n.premiumEditorialSubtitle,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.55,
              ),
            ),
            if (premium) ...[
              const SizedBox(height: 9),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      account.membership?.premiumExpiresAt != null
                          ? l10n.premiumTrialTitle
                          : l10n.premiumPurchaseSuccess,
                      key: const ValueKey('premium-active'),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const PurchaseArtwork(
          scene: PurchaseArtworkScene.extensions,
          height: 220,
        ),
        if (premium) ...[
          Text(
            _membershipSourceMessage(context, account),
            key: const ValueKey('premium-membership-source'),
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        if (account.membershipSyncFailed ||
            (account.isAuthenticated && account.membership == null)) ...[
          const SizedBox(height: 8),
          Text(
            account.membershipSyncFailed
                ? l10n.premiumSyncFailed
                : l10n.premiumSyncPending,
            key: const ValueKey('premium-sync-failed'),
            style: TextStyle(color: colors.error, fontSize: 13, height: 1.4),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          l10n.premiumBenefitsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        DecoratedBox(
          key: const ValueKey('premium-benefits'),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: Column(
            children: [
              _benefit(
                PurchaseIcons.stack,
                l10n.settingsAdditionalSourceProtocolsTitle,
                l10n.premiumProtocolsBenefit,
              ),
              Divider(height: 1, color: colors.outlineVariant),
              _benefit(
                PurchaseIcons.graph,
                l10n.settingsPrivateBookSourceNetworkTitle,
                l10n.premiumPrivateNetworkBenefit,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  account.isAuthenticated
                      ? l10n.purchaseAccountCaption
                      : l10n.premiumSignInRequired,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  account.user == null
                      ? l10n.accountSignIn
                      : account.user!.effectiveName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 0,
          children: [
            _detailsAction(
              key: const ValueKey('premium-benefits-details'),
              label: l10n.purchaseBenefitsAction,
              onTap: () => _openBenefits(account),
            ),
            _detailsAction(
              key: const ValueKey('premium-purchase-details'),
              label: l10n.purchaseTermsAction,
              onTap: () => _openPurchaseDetails(account),
            ),
          ],
        ),
      ],
    );
  }

  Widget _footer(MemberAccountController account) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final premium = account.hasPremiumAccess;
    final busy = account.premiumPurchaseLoading || account.loading;
    final expiring = account.membership?.premiumExpiresAt != null;
    final status = account.isAuthenticated
        ? _message ?? _purchaseStatus(context, account)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usesStoreBilling) ...[
          if (account.premiumLifetimeProduct case final product?) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.price,
                  key: const ValueKey('premium-store-price'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l10n.storePremiumPriceCaption,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
        if (!account.isAuthenticated)
          FilledButton(
            key: const ValueKey('premium-sign-in'),
            style: _footerButtonStyle,
            onPressed: _openSignIn,
            child: Text(l10n.accountSignIn),
          )
        else if (_usesStoreBilling) ...[
          if (!account.storeBillingReady && (!premium || expiring)) ...[
            Text(
              l10n.storeBillingUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (!premium || expiring)
            FilledButton(
              key: ValueKey(
                _usesAppleBilling
                    ? 'account-apple-purchase'
                    : 'account-google-purchase',
              ),
              style: _footerButtonStyle,
              onPressed: busy
                  ? null
                  : () => _perform(
                      account.premiumLifetimeProduct == null ||
                              !account.storeBillingReady
                          ? account.loadStoreProducts
                          : account.purchaseStorePremium,
                      usePurchaseStatus: true,
                    ),
              child: busy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CupertinoActivityIndicator(radius: 9),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            l10n.accountAppleProductLoading,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      account.premiumLifetimeProduct == null ||
                              !account.storeBillingReady
                          ? l10n.accountAppleProductRetry
                          : l10n.storePremiumPurchaseButton(_storeName),
                      textAlign: TextAlign.center,
                    ),
            )
          else
            _activeBadge(),
          const SizedBox(height: 4),
          TextButton(
            key: ValueKey(
              _usesAppleBilling
                  ? 'account-apple-restore'
                  : 'account-google-restore',
            ),
            onPressed: busy
                ? null
                : () => _perform(
                    account.restoreStorePremiumPurchases,
                    usePurchaseStatus: true,
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restore_rounded, size: 19),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.accountAppleRestore,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ] else if (!premium || expiring) ...[
          TextField(
            key: const ValueKey('account-redemption-code'),
            controller: _redemptionCode,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.accountRedemptionCode),
          ),
          const SizedBox(height: 10),
          FilledButton(
            key: const ValueKey('account-redeem-premium'),
            style: _footerButtonStyle,
            onPressed: busy ? null : _redeem,
            child: Text(l10n.accountRedeemPremium),
          ),
          if (account.membershipConfig?.purchaseUrl case final url?)
            TextButton(
              onPressed: () => _openUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(l10n.accountSupportAction),
            ),
        ] else
          _activeBadge(),
        if (status != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              key: const ValueKey('premium-purchase-status'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    _messageIsError ||
                        account.premiumPurchasePhase ==
                            StorePurchasePhase.failed
                    ? colors.error
                    : colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }

  ButtonStyle get _footerButtonStyle => FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  Widget _activeBadge() => DecoratedBox(
    key: const ValueKey('premium-active-footer'),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 19,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.premiumPurchaseSuccess,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _benefit(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Icon(
          icon,
          size: 23,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.78),
        ),
      ],
    ),
  );

  Widget _detailsAction({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) => TextButton(
    key: key,
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      alignment: AlignmentDirectional.centerStart,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(PurchaseIcons.arrowRight, size: 15),
      ],
    ),
  );

  void _openBenefits(MemberAccountController account) {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PurchasePageTheme(
          premium: true,
          child: PurchaseDetailsPage(
            title: l10n.premiumBenefitsTitle,
            children: [
              _detailsSection(
                l10n.settingsAdditionalSourceProtocolsTitle,
                l10n.premiumProtocolsBenefit,
              ),
              _detailsSection(
                l10n.settingsPrivateBookSourceNetworkTitle,
                l10n.premiumPrivateNetworkBenefit,
              ),
              _detailsSection(
                l10n.premiumBenefitsTitle,
                l10n.premiumSourceNotice,
              ),
              if (account.hasPremiumAccess)
                _detailsSection(
                  l10n.premiumAccountBindingTitle,
                  l10n.premiumSetupHint,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPurchaseDetails(MemberAccountController account) {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PurchasePageTheme(
          premium: true,
          child: PurchaseDetailsPage(
            title: l10n.purchaseDetailsTitle,
            children: [
              _detailsSection(
                l10n.premiumBillingTitle,
                _usesStoreBilling
                    ? l10n.storePremiumBilling(_storeName)
                    : l10n.premiumBillingBodyOther,
              ),
              _detailsSection(
                l10n.premiumAccountBindingTitle,
                l10n.premiumAccountBindingBody,
              ),
              if (_usesStoreBilling)
                _detailsSection(
                  l10n.accountAppleRestore,
                  l10n.storePremiumRestoreHelp(_storeName),
                ),
              if (!account.hasPremiumAccess) ...[
                const SizedBox(height: 2),
                Text(
                  _usesAppleBilling
                      ? l10n.premiumPurchaseConsent
                      : l10n.premiumPurchaseConsentOther,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                key: const ValueKey('premium-terms-link'),
                onPressed: () => _openPolicy(PremiumPolicy.terms),
                child: Text(l10n.premiumMembershipTerms),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const ValueKey('premium-privacy-link'),
                onPressed: () => _openPolicy(PremiumPolicy.privacy),
                child: Text(l10n.premiumPrivacyPolicy),
              ),
              if (_usesAppleBilling) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('premium-eula-link'),
                  onPressed: () => _openUrl(PremiumPolicyPage.appleEulaUri),
                  child: Text(l10n.premiumAppleEula),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsSection(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(body, style: const TextStyle(fontSize: 15, height: 1.55)),
      ],
    ),
  );

  void _openPolicy(PremiumPolicy policy) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PremiumPolicyPage(
        policy: policy,
        usesAppleBilling: _usesAppleBilling,
        usesGoogleBilling: AppDistribution.usesGoogleBilling,
      ),
    ),
  );

  String _membershipSourceMessage(
    BuildContext context,
    MemberAccountController account,
  ) {
    final l10n = context.l10n;
    final expiresAt = account.membership?.premiumExpiresAt;
    if (expiresAt != null) {
      final local = expiresAt.toLocal();
      return l10n.premiumTrialExpiresAt(
        '${MaterialLocalizations.of(context).formatMediumDate(local)} '
        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
      );
    }
    final sources = account.membership?.activePremiumSources ?? <String>{};
    if (sources.any(
      {'admin', 'manual', 'promotion', 'referral_card'}.contains,
    )) {
      return l10n.premiumGrantedAccess;
    }
    if (sources.contains('card')) return l10n.premiumOtherChannelAccess;
    if (sources.contains('apple')) return l10n.premiumAppleAccess;
    return l10n.premiumExistingAccess;
  }

  String? _purchaseStatus(
    BuildContext context,
    MemberAccountController account,
  ) {
    final l10n = context.l10n;
    return switch (account.premiumPurchasePhase) {
      StorePurchasePhase.idle => null,
      StorePurchasePhase.loadingProduct => l10n.accountAppleProductLoading,
      StorePurchasePhase.purchasing => l10n.loading,
      StorePurchasePhase.pending => l10n.premiumPendingApproval,
      StorePurchasePhase.verifying => l10n.premiumVerifying,
      StorePurchasePhase.restoring => l10n.premiumRestoring,
      StorePurchasePhase.purchased =>
        account.hasPremiumAccess ? l10n.premiumPurchaseSuccess : null,
      StorePurchasePhase.restored =>
        account.hasPremiumAccess ? l10n.premiumRestoreSuccess : null,
      StorePurchasePhase.testVerified => l10n.premiumTestPurchaseVerified,
      StorePurchasePhase.revoked => l10n.premiumPurchaseRevoked,
      StorePurchasePhase.nothingToRestore =>
        _usesAppleBilling ? l10n.premiumRestoreEmpty : l10n.storeRestoreEmpty,
      StorePurchasePhase.canceled => l10n.premiumPurchaseCanceled,
      StorePurchasePhase.failed => account.premiumPurchaseError,
    };
  }
}
