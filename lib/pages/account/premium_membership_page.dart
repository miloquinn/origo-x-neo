import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../utils/page_style_helper.dart';
import '../../widgets/app_brand_icon.dart';
import '../../widgets/premium_card_style.dart';
import '../../widgets/purchase_page_scaffold.dart';
import 'account_page.dart';
import 'premium_policy_page.dart';
import 'store_reader_unlock_page.dart';

class PremiumMembershipPage extends StatefulWidget {
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
  State<PremiumMembershipPage> createState() => _PremiumMembershipPageState();
}

class _PremiumMembershipPageState extends State<PremiumMembershipPage>
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
      if (_usesStoreBilling && !account.hasPermanentReaderAccess) {
        return StoreReaderUnlockPage(account: account);
      }
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
        _membershipCard(account),
        if (premium) ...[
          const SizedBox(height: 10),
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
        const SizedBox(height: 16),
        _surface(
          key: const ValueKey('premium-benefits'),
          children: [
            _benefit(
              Icons.layers_outlined,
              l10n.settingsAdditionalSourceProtocolsTitle,
              l10n.premiumProtocolsBenefit,
            ),
            const Divider(height: 18),
            _benefit(
              Icons.wifi_rounded,
              l10n.settingsPrivateBookSourceNetworkTitle,
              l10n.premiumPrivateNetworkBenefit,
            ),
            const SizedBox(height: 4),
            _detailsAction(
              key: const ValueKey('premium-benefits-details'),
              icon: Icons.arrow_forward_rounded,
              label: l10n.purchaseBenefitsAction,
              onTap: () => _openBenefits(account),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _surface(
          children: [
            Row(
              children: [
                Icon(
                  account.isAuthenticated
                      ? Icons.account_circle_outlined
                      : Icons.login_rounded,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.isAuthenticated
                            ? l10n.purchaseAccountCaption
                            : l10n.premiumSignInRequired,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.user == null
                            ? l10n.accountSignIn
                            : '${account.user!.effectiveName} · ${account.user!.email}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _detailsAction(
              key: const ValueKey('premium-purchase-details'),
              icon: Icons.description_outlined,
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
            Text(
              product.price,
              key: const ValueKey('premium-store-price'),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.storePremiumPriceCaption,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
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
          TextButton.icon(
            key: ValueKey(
              _usesAppleBilling
                  ? 'account-apple-restore'
                  : 'account-google-restore',
            ),
            icon: const Icon(Icons.restore_rounded, size: 19),
            onPressed: busy
                ? null
                : () => _perform(
                    account.restoreStorePremiumPurchases,
                    usePurchaseStatus: true,
                  ),
            label: Text(l10n.accountAppleRestore),
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

  Widget _membershipCard(MemberAccountController account) {
    final l10n = context.l10n;
    final premium = account.hasPremiumAccess;
    return Container(
      key: const ValueKey('premium-membership-card'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: premiumCardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: premiumGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: premiumGold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const AppBrandIcon(size: 42, borderRadius: 12),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.premiumEditionSummary,
                  style: const TextStyle(
                    color: premiumIvory,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  premium
                      ? account.membership?.premiumExpiresAt != null
                            ? l10n.premiumTrialTitle
                            : l10n.premiumPurchaseSuccess
                      : l10n.premiumLifetimeCaption,
                  key: premium ? const ValueKey('premium-active') : null,
                  style: TextStyle(
                    color: premiumIvory.withValues(alpha: 0.74),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (premium) ...[
            const SizedBox(width: 8),
            const Icon(Icons.verified_rounded, color: premiumGold, size: 22),
          ],
        ],
      ),
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

  Widget _surface({Key? key, required List<Widget> children}) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: key,
      decoration: BoxDecoration(
        color: PageStyleHelper.palette(context).card,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String title, String description) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          icon,
          size: 21,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _detailsAction({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      key: key,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    ),
  );

  void _openBenefits(MemberAccountController account) {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PurchaseDetailsPage(
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
    );
  }

  void _openPurchaseDetails(MemberAccountController account) {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PurchaseDetailsPage(
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
