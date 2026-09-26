import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/app_brand_icon.dart';
import '../../widgets/purchase_page_scaffold.dart';

/// Store-owned local reading license.
///
/// This page deliberately has no Origo sign-in requirement. The store account
/// owns the app unlock; account-bound Premium is purchased on a separate page.
class StoreReaderUnlockPage extends StatefulWidget {
  const StoreReaderUnlockPage({super.key, required this.account});

  final MemberAccountController account;

  @override
  State<StoreReaderUnlockPage> createState() => _StoreReaderUnlockPageState();
}

class _StoreReaderUnlockPageState extends State<StoreReaderUnlockPage>
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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.account,
    builder: (context, _) {
      final account = widget.account;
      final l10n = context.l10n;
      final colors = Theme.of(context).colorScheme;
      final permanent = account.hasPermanentReaderAccess;
      final trial = account.hasActiveReaderTrial;
      final busy = account.readerPurchaseLoading || account.loading;
      final status = _message ?? _purchaseStatus(context, account);
      return PurchasePageScaffold(
        key: const ValueKey('store-reader-license-page'),
        title: l10n.storeReaderLicenseTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AppBrandIcon(size: 64, borderRadius: 18)),
            const SizedBox(height: 18),
            Text(
              l10n.basicEditionTitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.basicEditionSummary,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (final feature in _features().take(6))
                    SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: _summaryLine(feature.icon, feature.title),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _summaryLine(
              Icons.person_outline_rounded,
              l10n.basicEditionNoAccount,
            ),
            if (permanent) ...[
              const SizedBox(height: 20),
              _summaryLine(
                Icons.verified_rounded,
                l10n.storeReaderPurchaseSuccess,
                key: const ValueKey('store-reader-active'),
              ),
            ] else if (trial && account.readerTrialExpiresAt != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.storeReaderTrialExpiresAt(
                  MaterialLocalizations.of(
                    context,
                  ).formatFullDate(account.readerTrialExpiresAt!.toLocal()),
                ),
                key: const ValueKey('store-trial-status'),
                style: TextStyle(color: colors.primary),
              ),
            ] else if (account.readerTrialExpiresAt != null) ...[
              const SizedBox(height: 20),
              Text(
                l10n.storeTrialExpired,
                key: const ValueKey('store-trial-status'),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 22),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('store-reader-benefits'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.purchaseBenefitsAction),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openBenefits,
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('store-reader-details'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.purchaseDetailsTitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openDetails,
            ),
          ],
        ),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!permanent) ...[
              if (account.readerLifetimeProduct case final product?) ...[
                Text(
                  product.price,
                  key: const ValueKey('store-reader-lifetime-price'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.premiumLifetimeCaption,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (!account.storeBillingReady) ...[
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
                    : () => _perform(
                        account.readerLifetimeProduct == null ||
                                !account.storeBillingReady
                            ? account.loadStoreProducts
                            : account.purchaseReaderLifetime,
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
                        account.readerLifetimeProduct == null ||
                                !account.storeBillingReady
                            ? l10n.accountAppleProductRetry
                            : l10n.storePurchaseButton(_storeName),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              if (account.canStartReaderTrial) ...[
                const SizedBox(height: 4),
                TextButton(
                  key: const ValueKey('store-start-trial'),
                  onPressed: busy
                      ? null
                      : () => _perform(account.startReaderTrial),
                  child: Text(
                    l10n.storeTrialStart(
                      account.membershipConfig?.storeTrialDays ?? 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
            TextButton.icon(
              key: const ValueKey('store-reader-restore'),
              onPressed: busy
                  ? null
                  : () => _perform(account.restoreReaderPurchases),
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: Text(l10n.accountAppleRestore),
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

  Widget _summaryLine(IconData icon, String text, {Key? key}) => Row(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );

  List<({IconData icon, String title, String body})> _features() {
    final l10n = context.l10n;
    return [
      (
        icon: Icons.auto_stories_outlined,
        title: l10n.basicReadingTitle,
        body: l10n.basicReadingBody,
      ),
      (
        icon: Icons.palette_outlined,
        title: l10n.basicAppearanceTitle,
        body: l10n.basicAppearanceBody,
      ),
      (
        icon: Icons.headphones_rounded,
        title: l10n.basicTtsTitle,
        body: l10n.basicTtsBody,
      ),
      (
        icon: Icons.cloud_outlined,
        title: l10n.basicCloudTtsTitle,
        body: l10n.basicCloudTtsBody,
      ),
      (
        icon: Icons.auto_awesome_outlined,
        title: l10n.basicAiTitle,
        body: l10n.basicAiBody,
      ),
      (
        icon: Icons.sync_rounded,
        title: l10n.basicSyncTitle,
        body: l10n.basicSyncBody,
      ),
      (
        icon: Icons.edit_note_rounded,
        title: l10n.basicNotesTitle,
        body: l10n.basicNotesBody,
      ),
      (
        icon: Icons.public_rounded,
        title: l10n.basicSourcesTitle,
        body: l10n.basicSourcesBody,
      ),
    ];
  }

  void _openBenefits() {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => PurchaseDetailsPage(
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
    );
  }

  void _openDetails() {
    final l10n = context.l10n;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => PurchaseDetailsPage(
          key: const ValueKey('store-reader-details-page'),
          title: l10n.purchaseDetailsTitle,
          children: [
            Text(
              l10n.storeReaderBenefitTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(l10n.storeReaderBenefitBody),
            const SizedBox(height: 24),
            Text(l10n.storePurchaseBilling(_storeName)),
            const SizedBox(height: 24),
            Text(
              l10n.storeTrialDetails(
                widget.account.membershipConfig?.storeTrialDays ?? 14,
              ),
            ),
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
    );
  }

  String? _purchaseStatus(
    BuildContext context,
    MemberAccountController account,
  ) {
    final l10n = context.l10n;
    return switch (account.readerPurchasePhase) {
      StorePurchasePhase.idle => null,
      StorePurchasePhase.loadingProduct => l10n.accountAppleProductLoading,
      StorePurchasePhase.purchasing => l10n.loading,
      StorePurchasePhase.pending => l10n.storeReaderPendingApproval(_storeName),
      StorePurchasePhase.verifying => l10n.storeReaderVerifying,
      StorePurchasePhase.restoring => l10n.storeReaderRestoring,
      StorePurchasePhase.purchased =>
        account.hasPermanentReaderAccess
            ? l10n.storeReaderPurchaseSuccess
            : account.hasActiveReaderTrial
            ? l10n.storeTrialStarted
            : null,
      StorePurchasePhase.restored =>
        account.hasPermanentReaderAccess
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
