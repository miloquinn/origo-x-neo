import 'package:flutter/material.dart';

import '../../services/legal/legal_document_repository.dart';
import 'user_agreement_page.dart';

/// Registers the consent guard on root routes, so system back and interactive
/// back gestures cannot discard a hidden reader while the agreement is shown.
class LegalAgreementNavigationObserver extends NavigatorObserver {
  final _entry = _LegalAgreementPopEntry();
  final _routes = <ModalRoute<dynamic>>{};
  set required(bool value) => _entry.canPopNotifier.value = !value;
  set onBlockedBack(VoidCallback? callback) => _entry.onBlockedBack = callback;

  void _register(Route<dynamic>? route) {
    if (route is ModalRoute && _routes.add(route)) {
      route.registerPopEntry(_entry);
    }
  }

  void _unregister(Route<dynamic>? route) {
    if (route is ModalRoute && _routes.remove(route)) {
      route.unregisterPopEntry(_entry);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _register(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _unregister(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _unregister(oldRoute);
    _register(newRoute);
  }

  void dispose() {
    for (final route in _routes.toList()) {
      _unregister(route);
    }
    _entry.canPopNotifier.dispose();
  }
}

class _LegalAgreementPopEntry extends PopEntry<Object?> {
  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(true);
  VoidCallback? onBlockedBack;
  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop && !canPopNotifier.value) onBlockedBack?.call();
  }
}

/// Keeps the existing navigation stack intact while an updated policy needs
/// acceptance. Its own navigator lets the reader inspect full documents without
/// exposing any reader/settings route behind the required agreement.
class LegalAgreementGate extends StatefulWidget {
  const LegalAgreementGate({
    super.key,
    required this.required,
    required this.child,
    required this.onAgreed,
    required this.navigationObserver,
    this.onDisagreed,
    this.repository,
  });
  final bool required;
  final Widget child;
  final VoidCallback onAgreed;
  final LegalAgreementNavigationObserver navigationObserver;
  final VoidCallback? onDisagreed;
  final LegalDocumentRepository? repository;
  @override
  State<LegalAgreementGate> createState() => _LegalAgreementGateState();
}

class _LegalAgreementGateState extends State<LegalAgreementGate> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _guardNavigation() {
    widget.navigationObserver.required = widget.required;
    widget.navigationObserver.onBlockedBack = () {
      _navigatorKey.currentState?.maybePop();
    };
  }

  @override
  void initState() {
    super.initState();
    _guardNavigation();
  }

  @override
  void didUpdateWidget(LegalAgreementGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _guardNavigation();
  }

  @override
  void dispose() {
    widget.navigationObserver.onBlockedBack = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(
        offstage: widget.required,
        child: ExcludeFocus(
          excluding: widget.required,
          child: TickerMode(enabled: !widget.required, child: widget.child),
        ),
      ),
      if (widget.required)
        HeroControllerScope.none(
          child: Navigator(
            key: _navigatorKey,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => PopScope(
                canPop: false,
                child: UserAgreementPage(
                  initialPage: 3,
                  repository: widget.repository,
                  onAgreed: widget.onAgreed,
                  onDisagreed: widget.onDisagreed,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
