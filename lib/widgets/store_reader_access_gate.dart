import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/account/store_reader_unlock_page.dart';
import '../services/account/account.dart';
import '../services/core/app_distribution.dart';
import '../services/reader_aloud_session.dart';
import '../utils/localization_extension.dart';

/// App-level observer that stops a background read-aloud session when a store
/// reader entitlement expires after its reader route has already been closed.
class StoreReaderEntitlementListener extends StatefulWidget {
  const StoreReaderEntitlementListener({super.key, required this.child});

  final Widget child;

  @override
  State<StoreReaderEntitlementListener> createState() =>
      _StoreReaderEntitlementListenerState();
}

class _StoreReaderEntitlementListenerState
    extends State<StoreReaderEntitlementListener> {
  bool _stopScheduled = false;

  void _scheduleStop() {
    if (_stopScheduled) return;
    _stopScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stopScheduled = false;
      unawaited(context.read<ReaderAloudSession?>()?.stop());
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<MemberAccountController?>();
    final accessDenied =
        AppDistribution.readerLicenseRequired &&
        (account == null || (account.initialized && !account.hasReaderAccess));
    if (accessDenied) _scheduleStop();
    return widget.child;
  }
}

/// Builds reader content only after the current store reader entitlement has
/// been resolved. Direct builds and store builds with licensing disabled keep
/// the existing reader path unchanged.
class StoreReaderAccessGate extends StatefulWidget {
  const StoreReaderAccessGate({
    super.key,
    required this.pageBuilder,
    this.onBlockedContentReady,
  });

  final WidgetBuilder pageBuilder;
  final VoidCallback? onBlockedContentReady;

  @override
  State<StoreReaderAccessGate> createState() => _StoreReaderAccessGateState();
}

class _StoreReaderAccessGateState extends State<StoreReaderAccessGate> {
  MemberAccountController? _initializingAccount;
  Widget? _readerPage;
  bool _stoppedDeniedSession = false;
  bool _blockedReadyScheduled = false;

  @override
  void didUpdateWidget(covariant StoreReaderAccessGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pageBuilder, widget.pageBuilder)) {
      _readerPage = null;
    }
  }

  Widget _reader(BuildContext context) {
    return _readerPage ??= widget.pageBuilder(context);
  }

  void _scheduleBlockedReady() {
    if (_blockedReadyScheduled) return;
    _blockedReadyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onBlockedContentReady?.call();
    });
  }

  void _initialize(MemberAccountController account) {
    if (identical(_initializingAccount, account)) return;
    _initializingAccount = account;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_initializingAccount, account)) return;
      unawaited(
        account
            .initialize()
            .catchError((Object error) {
              debugPrint('store reader account initialization failed: $error');
            })
            .whenComplete(() {
              if (mounted && identical(_initializingAccount, account)) {
                _initializingAccount = null;
              }
            }),
      );
    });
  }

  void _stopDeniedReadAloud() {
    if (_stoppedDeniedSession) return;
    _stoppedDeniedSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stoppedDeniedSession) return;
      unawaited(context.read<ReaderAloudSession?>()?.stop());
    });
  }

  Future<void> _openUnlock(MemberAccountController account) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StoreReaderUnlockPage(account: account),
      ),
    );
    if (!mounted) return;
    await account.synchronize();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppDistribution.readerLicenseRequired) {
      _stoppedDeniedSession = false;
      return _reader(context);
    }

    final account = context.watch<MemberAccountController?>();
    if (account?.hasReaderAccess == true) {
      _stoppedDeniedSession = false;
      return _reader(context);
    }

    _readerPage = null;
    _scheduleBlockedReady();
    _stopDeniedReadAloud();
    if (account != null && !account.initialized) {
      _initialize(account);
      return _StoreReaderAccessMessage(
        title: context.l10n.storeReaderLockedTitle,
        body: context.l10n.storeReaderChecking,
        backLabel: context.l10n.storeReaderBack,
      );
    }

    return _StoreReaderAccessMessage(
      title: context.l10n.storeReaderLockedTitle,
      body: context.l10n.storeReaderLockedBody,
      backLabel: context.l10n.storeReaderBack,
      unlockLabel: account == null ? null : context.l10n.storeReaderUnlock,
      onUnlock: account == null ? null : () => _openUnlock(account),
    );
  }
}

class _StoreReaderAccessMessage extends StatelessWidget {
  const _StoreReaderAccessMessage({
    required this.title,
    required this.body,
    required this.backLabel,
    this.unlockLabel,
    this.onUnlock,
  });

  final String title;
  final String body;
  final String backLabel;
  final String? unlockLabel;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (onUnlock != null && unlockLabel != null) ...[
                    FilledButton(
                      key: const ValueKey('store-reader-open-unlock'),
                      onPressed: onUnlock,
                      child: Text(unlockLabel!),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(backLabel),
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
