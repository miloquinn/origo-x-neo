import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/purchase_icons.dart';
import '../../widgets/purchase_page_scaffold.dart';
import 'account_page.dart';
import 'membership_redemption_page.dart';

enum _ReaderDetailsAction { benefits, purchase }

/// Account-bound reading access purchased through the current app store.
class StoreReaderUnlockPage extends StatelessWidget {
  const StoreReaderUnlockPage({super.key, required this.account});
  final MemberAccountController account;
  @override
  Widget build(BuildContext context) =>
      PurchasePageTheme(child: _ReaderPurchaseContent(account: account));
}

class _ReaderPurchaseContent extends StatefulWidget {
  const _ReaderPurchaseContent({required this.account});
  final MemberAccountController account;
  @override
  State<_ReaderPurchaseContent> createState() => _StoreReaderUnlockPageState();
}

class _StoreReaderUnlockPageState extends State<_ReaderPurchaseContent>
    with WidgetsBindingObserver {
  String? _message;
  bool _messageIsError = false;

  String get _storeName =>
      AppDistribution.usesAppleBilling ? 'App Store' : 'Google Play';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_initializeStore());
    });
  }

  Future<void> _initializeStore() async {
    if (!AppDistribution.usesStoreBilling) return;
    try {
      if (widget.account.readerLifetimeProduct == null) {
        await widget.account.loadStoreProducts();
      } else {
        await widget.account.initializeStorePurchases();
      }
    } catch (error) {
      debugPrint('store reader products unavailable: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.account.synchronize());
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (mounted) {
      setState(() {
        _message = null;
        _messageIsError = false;
      });
    }
    try {
      await action();
    } catch (error) {
      if (!mounted ||
          widget.account.readerPurchasePhase == StorePurchasePhase.failed) {
        return;
      }
      setState(() {
        _message = switch (error) {
          MemberAccountException() => error.message,
          PlatformException() =>
            error.message ?? context.l10n.premiumOperationFailed,
          _ => context.l10n.premiumOperationFailed,
        };
        _messageIsError = true;
      });
    }
  }

  Future<void> _openSignIn() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const AccountPage()));
    if (mounted && widget.account.isAuthenticated) {
      unawaited(_initializeStore());
    }
  }

  Future<void> _performAccountAction(Future<void> Function() action) async {
    if (!widget.account.isAuthenticated) {
      await _openSignIn();
      return;
    }
    await _perform(action);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.account,
    builder: (context, _) {
      final account = widget.account;
      final l10n = context.l10n;
      final colors = Theme.of(context).colorScheme;
      final licenseRequired = AppDistribution.readerLicenseRequired;
      final usesStoreBilling = AppDistribution.usesStoreBilling;
      final active = account.readerFeaturesForDisplay;
      final permanent = account.permanentReaderFeaturesForDisplay;
      final trial = account.hasActiveReaderTrial;
      final busy = account.readerPurchaseLoading || account.loading;
      final status = _message ?? _purchaseStatus(context, account);
      final String activeLabel = permanent
          ? l10n.storeReaderCrossPlatformAccess
          : (trial && account.readerTrialExpiresAt != null)
          ? l10n.storeReaderTrialExpiresAt(
              MaterialLocalizations.of(
                context,
              ).formatFullDate(account.readerTrialExpiresAt!.toLocal()),
            )
          : l10n.premiumCrossPlatformAccess;
      return PurchasePageScaffold(
        key: const ValueKey('store-reader-license-page'),
        title: l10n.storeReaderLicenseTitle,
        actions: [
          FloatingSubpageMenuButton<_ReaderDetailsAction>(
            key: const ValueKey('store-reader-details-menu'),
            icon: Icons.more_horiz_rounded,
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            items: [
              FloatingSubpageMenuItem(
                value: _ReaderDetailsAction.benefits,
                itemKey: const ValueKey('store-reader-benefits'),
                child: Text(l10n.purchaseBenefitsAction),
              ),
              FloatingSubpageMenuItem(
                value: _ReaderDetailsAction.purchase,
                itemKey: const ValueKey('store-reader-details'),
                child: Text(l10n.purchaseDetailsTitle),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _ReaderDetailsAction.benefits:
                  _openBenefits();
                case _ReaderDetailsAction.purchase:
                  _openDetails();
              }
            },
          ),
        ],
        pinFooter: !permanent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.basicEditionSummary,
              key: const ValueKey('store-reader-benefits-heading'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.storeReaderLicenseSubtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _coreBenefits(),
            const SizedBox(height: 14),
            Text(
              l10n.basicServicesNote,
              key: const ValueKey('store-reader-service-cost-note'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 16),
              _summaryLine(
                Icons.verified_rounded,
                activeLabel,
                key: trial && account.readerTrialExpiresAt != null
                    ? const ValueKey('store-trial-status')
                    : const ValueKey('store-reader-active'),
                textStyle: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ] else if (licenseRequired &&
                account.readerTrialExpiresAt != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.storeTrialExpired,
                key: const ValueKey('store-trial-status'),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!permanent) ...[
              if (usesStoreBilling)
                if (account.readerLifetimeProduct case final product?) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          product.price,
                          key: const ValueKey('store-reader-lifetime-price'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          '${l10n.premiumLifetimeCaption}\n${l10n.purchaseAccountCaption}',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                color: colors.onSurfaceVariant,
                                height: 1.6,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              if (usesStoreBilling && !account.storeBillingReady) ...[
                Text(
                  l10n.storeBillingUnavailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                key: const ValueKey('store-reader-purchase'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: busy
                    ? null
                    : !account.isAuthenticated
                    ? _openSignIn
                    : usesStoreBilling
                    ? () => _perform(
                        account.readerLifetimeProduct == null ||
                                !account.storeBillingReady
                            ? account.loadStoreProducts
                            : account.purchaseReaderLifetime,
                      )
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              MembershipRedemptionPage(account: account),
                        ),
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy) ...[
                      CupertinoActivityIndicator(color: colors.primary),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        !account.isAuthenticated
                            ? l10n.storeReaderSignInAction
                            : !usesStoreBilling
                            ? l10n.accountHaveRedemptionCode
                            : account.readerLifetimeProduct == null ||
                                  !account.storeBillingReady
                            ? l10n.accountAppleProductRetry
                            : l10n.storePurchaseButton(_storeName),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (usesStoreBilling &&
                licenseRequired &&
                !permanent &&
                account.canStartReaderTrial)
              TextButton(
                key: const ValueKey('store-start-trial'),
                onPressed: busy
                    ? null
                    : () => _performAccountAction(account.startReaderTrial),
                child: Text(
                  l10n.storeTrialStart(
                    account.membershipConfig?.storeTrialDays ?? 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            PurchaseActionRow(
              children: [
                if (usesStoreBilling)
                  TextButton(
                    key: const ValueKey('store-reader-restore'),
                    onPressed: busy
                        ? null
                        : () => _performAccountAction(
                            account.restoreReaderPurchases,
                          ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restore_rounded, size: 17),
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
                if (usesStoreBilling && account.isAuthenticated)
                  TextButton(
                    key: const ValueKey('store-reader-redeem-entry'),
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
            if (status != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  key: const ValueKey('store-reader-purchase-status'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        _messageIsError ||
                            account.readerPurchasePhase ==
                                StorePurchasePhase.failed
                        ? colors.error
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _coreBenefits() {
    final l10n = context.l10n;
    final benefits = [
      (key: 'ai', icon: PurchaseIcons.sparkle, title: l10n.basicAiTitle),
      (
        key: 'cloud-tts',
        icon: Icons.cloud_outlined,
        title: l10n.basicCloudTtsTitle,
      ),
      (
        key: 'comics',
        icon: Icons.photo_library_outlined,
        title: l10n.basicComicTitle,
      ),
      (
        key: 'fonts',
        icon: Icons.font_download_outlined,
        title: l10n.basicCustomFontsTitle,
      ),
    ];
    final scheme = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 18;
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        key: const ValueKey('store-reader-core-benefits'),
        crossAxisCount: constraints.maxWidth >= 340 && !largeText ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth >= 340 && !largeText ? 3.2 : 5,
        children: [
          for (final benefit in benefits)
            GlassSurface(
              key: ValueKey('store-reader-feature-${benefit.key}'),
              role: GlassSurfaceRole.control,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(benefit.icon, size: 21, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit.title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    IconData icon,
    String text, {
    Key? key,
    TextStyle? textStyle,
  }) => Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );

  List<({IconData icon, String title, String body})> _features() {
    final l10n = context.l10n;
    return [
      (
        icon: PurchaseIcons.sparkle,
        title: l10n.basicAiTitle,
        body: l10n.basicAiBody,
      ),
      (
        icon: Icons.cloud_outlined,
        title: l10n.basicCloudTtsTitle,
        body: l10n.basicCloudTtsBody,
      ),
      (
        icon: Icons.photo_library_outlined,
        title: l10n.basicComicTitle,
        body: l10n.basicComicBody,
      ),
      (
        icon: Icons.font_download_outlined,
        title: l10n.basicCustomFontsTitle,
        body: l10n.basicCustomFontsBody,
      ),
    ];
  }

  void _openBenefits() {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => InheritedTheme.captureAll(
          this.context,
          PurchaseDetailsPage(
            key: const ValueKey('store-reader-benefits-page'),
            title: l10n.basicBenefitsTitle,
            children: [
              for (final feature in _features()) ...[
                _summaryLine(feature.icon, feature.title),
                const SizedBox(height: 8),
                Text(feature.body),
                const SizedBox(height: 24),
              ],
              Text(
                l10n.basicFormatNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.basicServicesNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails() {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => InheritedTheme.captureAll(
          this.context,
          PurchaseDetailsPage(
            key: const ValueKey('store-reader-details-page'),
            title: l10n.purchaseDetailsTitle,
            children: [
              Text(
                l10n.storeReaderBenefitTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(l10n.basicEditionSummary),
              const SizedBox(height: 8),
              Text(l10n.basicServicesNote),
              const SizedBox(height: 24),
              Text(l10n.storePurchaseBilling(_storeName)),
              if (AppDistribution.readerLicenseRequired) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.storeTrialDetails(
                    widget.account.membershipConfig?.storeTrialDays ?? 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.accountAppleRestore,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(l10n.storePurchaseRestoreHelp(_storeName)),
            ],
          ),
        ),
      ),
    );
  }

  String? _purchaseStatus(
    BuildContext context,
    MemberAccountController account,
  ) {
    final l10n = context.l10n;
    return switch (account.readerPurchasePhase) {
      StorePurchasePhase.idle => null,
      StorePurchasePhase.loadingProduct =>
        account.hasPermanentAccountReaderFeatureAccess
            ? null
            : l10n.accountAppleProductLoading,
      StorePurchasePhase.productUnavailable =>
        account.hasPermanentAccountReaderFeatureAccess
            ? null
            : l10n.storeBillingUnavailable,
      StorePurchasePhase.purchasing => l10n.loading,
      StorePurchasePhase.pending => l10n.storeReaderPendingApproval(_storeName),
      StorePurchasePhase.verifying => l10n.storeReaderVerifying,
      StorePurchasePhase.restoring => l10n.storeReaderRestoring,
      StorePurchasePhase.purchased =>
        account.hasPermanentAccountReaderFeatureAccess
            ? l10n.storeReaderPurchaseSuccess
            : account.hasActiveReaderTrial
            ? l10n.storeTrialStarted
            : null,
      StorePurchasePhase.restored =>
        account.hasPermanentAccountReaderFeatureAccess
            ? l10n.storeReaderRestoreSuccess
            : account.hasActiveReaderTrial
            ? l10n.storeTrialStarted
            : null,
      StorePurchasePhase.testVerified => l10n.storeReaderTestPurchaseVerified,
      StorePurchasePhase.revoked => l10n.storeReaderPurchaseRevoked,
      StorePurchasePhase.nothingToRestore => l10n.basicRestoreEmpty,
      StorePurchasePhase.canceled => l10n.premiumPurchaseCanceled,
      StorePurchasePhase.failed => account.readerPurchaseError,
    };
  }
}
