import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/system_ui_helper.dart';

/// Owns imperative system-bar updates while its enclosing route is visible.
///
/// [AnnotatedRegion] remains the declarative source of truth for rendered
/// system-bar style. This widget only restores edge-to-edge mode and the same
/// style when route ownership, app lifecycle, or brightness changes.
class PageSystemUi extends StatefulWidget {
  const PageSystemUi({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  State<PageSystemUi> createState() => _PageSystemUiState();
}

class _PageSystemUiState extends State<PageSystemUi>
    with WidgetsBindingObserver {
  bool _isCurrentRoute = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrentRoute = ModalRoute.isCurrentOf(context) ?? true;
    if (_isCurrentRoute == isCurrentRoute) return;
    _isCurrentRoute = isCurrentRoute;
    if (isCurrentRoute) _apply(mode: true, style: true);
  }

  @override
  void didUpdateWidget(covariant PageSystemUi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrentRoute && oldWidget.brightness != widget.brightness) {
      _apply(style: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isCurrentRoute && state == AppLifecycleState.resumed) {
      _apply(mode: true, style: true);
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_isCurrentRoute) _apply(style: true);
  }

  void _apply({bool mode = false, bool style = false}) {
    if (mode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (style) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiHelper.overlayStyleForBrightness(widget.brightness),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
