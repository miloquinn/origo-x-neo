import 'package:flutter/widgets.dart';

/// Defer incoming writes while a reader/editor/dialog owns an in-memory view.
class ICloudSyncNavigationObserver extends NavigatorObserver {
  final Set<Route<dynamic>> _routes = {};
  VoidCallback? onReady;
  bool get canApply => _routes.every(
    (route) => route.isFirst || route.settings.name == '/icloud-sync',
  );

  void _changed() {
    if (canApply) onReady?.call();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _routes.remove(oldRoute);
    if (newRoute != null) _routes.add(newRoute);
    _changed();
  }
}
