import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account/account.dart';
import '../../services/core/app_distribution.dart';
import '../../utils/localization_extension.dart';
import '../../utils/page_style_helper.dart';
import '../../widgets/app_brand_icon.dart';
import '../../widgets/floating_subpage_scaffold.dart';

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
      return FloatingSubpageScaffold(
        title: l10n.storeReaderLicenseTitle,
        body: ListView(
          key: const ValueKey('store-reader-license-page'),
          padding: floatingSubpagePadding(context, bottom: 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _licenseCard(context, permanent: permanent, trial: trial),
                    const SizedBox(height: 20),
                    if (!permanent)
                      _section(context, l10n.storeReaderLifetimeTitle, [
                        if (trial && account.readerTrialExpiresAt != null) ...[
                          Text(
                            l10n.storeReaderTrialExpiresAt(
                              MaterialLocalizations.of(context).formatFullDate(
                                account.readerTrialExpiresAt!.toLocal(),
                              ),
                            ),
                            key: const ValueKey('store-trial-status'),
                          ),
                          const SizedBox(height: 16),
                        ] else if (account.canStartReaderTrial) ...[
                          Text(
                            l10n.storeTrialDetails(
                              account.membershipConfig?.storeTrialDays ?? 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            key: const ValueKey('store-start-trial'),
                            onPressed: busy
                                ? null
                                : () => _perform(account.startReaderTrial),
                            child: Text(
                              l10n.storeTrialStart(
                                account.membershipConfig?.storeTrialDays ?? 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ] else if (account.readerTrialExpiresAt != null) ...[
                          Text(
                            l10n.storeTrialExpired,
                            key: const ValueKey('store-trial-status'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (!account.storeBillingReady) ...[
                          Text(l10n.storeBillingUnavailable),
                          const SizedBox(height: 12),
                        ],
                        if (account.readerLifetimeProduct
                            case final product?) ...[
                          Text(
                            product.price,
                            key: const ValueKey('store-reader-lifetime-price'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.premiumLifetimeCaption,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        FilledButton(
                          key: const ValueKey('store-reader-purchase'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
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
                          child: busy
                              ? const CupertinoActivityIndicator()
                              : Text(
                                  account.readerLifetimeProduct == null ||
                                          !account.storeBillingReady
                                      ? l10n.accountAppleProductRetry
                                      : l10n.storePurchaseButton(_storeName),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ]),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      key: const ValueKey('store-reader-restore'),
                      onPressed: busy
                          ? null
                          : () => _perform(account.restoreReaderPurchases),
                      icon: const Icon(Icons.restore_rounded, size: 20),
                      label: Text(l10n.accountAppleRestore),
                    ),
                    Text(
                      permanent
                          ? l10n.storeReaderOwned(_storeName)
                          : l10n.storePurchaseRestoreHelp(_storeName),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          status,
                          key: const ValueKey('store-reader-purchase-status'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                _messageIsError ||
                                    account.readerPurchasePhase ==
                                        StorePurchasePhase.failed
                                ? colors.error
                                : colors.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                    if (!permanent) ...[
                      const SizedBox(height: 18),
                      Text(
                        l10n.storePurchaseBilling(_storeName),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _licenseCard(
    BuildContext context, {
    required bool permanent,
    required bool trial,
  }) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.48),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBrandIcon(size: 46, borderRadius: 13),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permanent
                        ? l10n.storeReaderLifetimeTitle
                        : l10n.storeReaderLicenseTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    permanent
                        ? l10n.storeReaderOwned(_storeName)
                        : trial && widget.account.readerTrialExpiresAt != null
                        ? l10n.storeReaderTrialExpiresAt(
                            MaterialLocalizations.of(context).formatFullDate(
                              widget.account.readerTrialExpiresAt!.toLocal(),
                            ),
                          )
                        : l10n.storeReaderLicenseSubtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  if (permanent) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            l10n.storeReaderPurchaseSuccess,
                            key: const ValueKey('store-reader-active'),
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PageStyleHelper.palette(context).card,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            ...children,
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
      StorePurchasePhase.idle ||
      StorePurchasePhase.loadingProduct ||
      StorePurchasePhase.purchasing => null,
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
      StorePurchasePhase.nothingToRestore => l10n.storeRestoreEmpty,
      StorePurchasePhase.canceled => l10n.premiumPurchaseCanceled,
      StorePurchasePhase.failed => account.readerPurchaseError,
    };
  }
}
