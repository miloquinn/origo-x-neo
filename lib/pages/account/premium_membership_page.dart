import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/purchase_icons.dart';
import '../../widgets/purchase_page_scaffold.dart';
import 'account_page.dart';
import 'membership_redemption_page.dart';
import 'premium_policy_page.dart';

enum _PremiumDetailsAction { benefits, purchase, terms, privacy }

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
    builder: (context, _) => PurchasePageTheme(
      child: _PremiumMembershipContent(
        account: account,
        focusBilling: focusBilling,
      ),
    ),
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
      if (_usesStoreBilling && widget.account.isAuthenticated) {
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
        actions: [
          FloatingSubpageMenuButton<_PremiumDetailsAction>(
            key: const ValueKey('premium-details-menu'),
            icon: Icons.more_horiz_rounded,
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            items: [
              FloatingSubpageMenuItem(
                value: _PremiumDetailsAction.benefits,
                itemKey: const ValueKey('premium-benefits-details'),
                child: Text(context.l10n.purchaseBenefitsAction),
              ),
              FloatingSubpageMenuItem(
                value: _PremiumDetailsAction.purchase,
                itemKey: const ValueKey('premium-purchase-details'),
                child: Text(context.l10n.purchaseDetailsTitle),
              ),
              FloatingSubpageMenuItem(
                value: _PremiumDetailsAction.terms,
                itemKey: const ValueKey('premium-menu-terms'),
                child: Text(context.l10n.premiumMembershipTerms),
              ),
              FloatingSubpageMenuItem(
                value: _PremiumDetailsAction.privacy,
                itemKey: const ValueKey('premium-menu-privacy'),
                child: Text(context.l10n.premiumPrivacyPolicy),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _PremiumDetailsAction.benefits:
                  _openBenefits(account);
                case _PremiumDetailsAction.purchase:
                  _openPurchaseDetails(account);
                case _PremiumDetailsAction.terms:
                  _openPolicy(PremiumPolicy.terms);
                case _PremiumDetailsAction.privacy:
                  _openPolicy(PremiumPolicy.privacy);
              }
            },
          ),
        ],
        pinFooter:
            !account.hasPremiumAccess ||
            account.membership?.premiumExpiresAt != null,
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
              l10n.premiumEditorialSubtitle,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
        if (premium) ...[
          const SizedBox(height: 16),
          if (account.membership?.premiumExpiresAt != null)
            DecoratedBox(
              key: const ValueKey('premium-trial-status'),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  key: const ValueKey('premium-active'),
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 17,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _membershipSourceMessage(context, account),
                        key: const ValueKey('premium-membership-source'),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
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
        const SizedBox(height: 24),
        Text(
          l10n.premiumBenefitsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 9),
        Column(
          key: const ValueKey('premium-benefits'),
          children: [
            _benefit(
              PurchaseIcons.bookOpenText,
              l10n.storeReaderLifetimeTitle,
              l10n.premiumIncludesReaderAccess,
            ),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            _benefit(
              PurchaseIcons.stack,
              l10n.settingsAdditionalSourceProtocolsTitle,
              l10n.premiumProtocolsBenefit,
            ),
            Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
            _benefit(
              PurchaseIcons.graph,
              l10n.settingsPrivateBookSourceNetworkTitle,
              l10n.premiumPrivateNetworkBenefit,
            ),
          ],
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
              Expanded(
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
      ],
    );
  }

  Widget _footer(MemberAccountController account) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final premium = account.hasPremiumAccess;
    final upgradeEligible = account.hasAccountReaderUpgradeEligibility;
    final busy = account.premiumPurchaseLoading || account.loading;
    final expiring = account.membership?.premiumExpiresAt != null;
    final status = account.isAuthenticated
        ? _message ?? _purchaseStatus(context, account)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_usesStoreBilling && (!premium || expiring)) ...[
          if ((upgradeEligible
                  ? account.premiumLifetimeProduct
                  : account.premiumBundleProduct)
              case final product?) ...[
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
                    upgradeEligible
                        ? l10n.storeExploreUpgradePriceCaption
                        : l10n.storeExploreBundlePriceCaption,
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
                      (upgradeEligible
                                      ? account.premiumLifetimeProduct
                                      : account.premiumBundleProduct) ==
                                  null ||
                              !account.storeBillingReady
                          ? account.loadStoreProducts
                          : upgradeEligible
                          ? account.purchaseStorePremium
                          : account.purchaseStorePremiumBundle,
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
                      (upgradeEligible
                                      ? account.premiumLifetimeProduct
                                      : account.premiumBundleProduct) ==
                                  null ||
                              !account.storeBillingReady
                          ? l10n.accountAppleProductRetry
                          : l10n.storePremiumPurchaseButton(_storeName),
                      textAlign: TextAlign.center,
                    ),
            )
          else
            _activeBadge(),
          PurchaseActionRow(
            children: [
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
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.accountAppleRestore,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('premium-redeem-entry'),
                onPressed: busy
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              MembershipRedemptionPage(account: account),
                        ),
                      ),
                child: Text(
                  l10n.accountHaveRedemptionCode,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
          if (AppDistribution.allowsExternalSupport)
            if (account.membershipConfig?.purchaseUrl case final url?)
              TextButton(
                key: const ValueKey('premium-direct-purchase'),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.premiumPurchaseSuccess,
              key: const ValueKey('premium-active'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _benefit(IconData icon, String title, String description) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      children: [
        Icon(
          icon,
          size: 21,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.78),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _openBenefits(MemberAccountController account) {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PurchasePageTheme(
          child: PurchaseDetailsPage(
            title: l10n.premiumBenefitsTitle,
            children: [
              _detailsSection(
                l10n.storeReaderLifetimeTitle,
                l10n.premiumIncludesReaderAccess,
              ),
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
          child: PurchaseDetailsPage(
            title: l10n.purchaseDetailsTitle,
            children: [
              _detailsSection(
                l10n.premiumBillingTitle,
                _usesStoreBilling
                    ? account.hasAccountReaderUpgradeEligibility
                          ? l10n.storeExploreUpgradeBilling(_storeName)
                          : l10n.storeExploreBundleBilling(_storeName)
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
        '${MaterialLocalizations.of(context).formatCompactDate(local)} '
        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
      );
    }
    final sources = account.membership?.activePremiumSources ?? <String>{};
    if (sources.any(
      {'admin', 'manual', 'promotion', 'referral_card'}.contains,
    )) {
      return '${l10n.premiumGrantedAccess} ${l10n.premiumCrossPlatformAccess}';
    }
    if (sources.contains('card')) {
      return '${l10n.premiumOtherChannelAccess} ${l10n.premiumCrossPlatformAccess}';
    }
    if (sources.contains('apple')) {
      return '${l10n.premiumAppleAccess} ${l10n.premiumCrossPlatformAccess}';
    }
    return '${l10n.premiumExistingAccess} ${l10n.premiumCrossPlatformAccess}';
  }

  String? _purchaseStatus(
    BuildContext context,
    MemberAccountController account,
  ) {
    final l10n = context.l10n;
    return switch (account.premiumPurchasePhase) {
      StorePurchasePhase.idle => null,
      StorePurchasePhase.loadingProduct =>
        account.hasPremiumAccess && account.membership?.premiumExpiresAt == null
            ? null
            : l10n.accountAppleProductLoading,
      StorePurchasePhase.productUnavailable =>
        account.hasPremiumAccess && account.membership?.premiumExpiresAt == null
            ? null
            : l10n.storeBillingUnavailable,
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
