// 文件说明：统一瞬时反馈，提供适配三种材质的顶部悬浮提示。
// 技术要点：Flutter UI、渲染层。

import 'dart:async';

import 'package:flutter/material.dart';
import 'glass_surface.dart';

VoidCallback? _hideActiveSideToast;

/// Dismiss feedback immediately, including any action from an obsolete operation.
void hideSideToast() => _hideActiveSideToast?.call();

enum SideToastKind { info, success, warning, error }

void showSideToast(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Color? textColor,
  Duration? duration,
  IconData? icon,
  SideToastKind kind = SideToastKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  hideSideToast();
  final themes = InheritedTheme.capture(from: context, to: overlay.context);
  var removed = false;
  late OverlayEntry entry;
  void remove() {
    if (removed) return;
    removed = true;
    if (identical(_hideActiveSideToast, remove)) {
      _hideActiveSideToast = null;
    }
    entry.remove();
    entry.dispose();
  }

  entry = OverlayEntry(
    builder: (context) => themes.wrap(
      _SideToast(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration == null || duration <= Duration.zero
            ? _defaultDuration(
                kind,
                message,
                hasAction: actionLabel != null && onAction != null,
              )
            : duration,
        icon: icon,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: remove,
      ),
    ),
  );
  _hideActiveSideToast = remove;
  overlay.insert(entry);
}

Duration _defaultDuration(
  SideToastKind kind,
  String message, {
  required bool hasAction,
}) {
  final minimum = switch (kind) {
    SideToastKind.info || SideToastKind.success => 2200,
    SideToastKind.warning => 2800,
    SideToastKind.error => 3400,
  };
  final readingTime = (message.runes.length * 60 + 1000).clamp(minimum, 8000);
  return Duration(
    milliseconds: hasAction && readingTime < 5000 ? 5000 : readingTime,
  );
}

class _SideToast extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final IconData? icon;
  final SideToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _SideToast({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.icon,
    required this.kind,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_SideToast> createState() => _SideToastState();
}

class _SideToastState extends State<_SideToast>
    with SingleTickerProviderStateMixin {
  final Key _dismissibleKey = UniqueKey();
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;
  bool _dismissed = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.duration = Duration.zero;
      _controller.reverseDuration = Duration.zero;
    }
    _controller.forward();
    final needsAction = widget.actionLabel != null && widget.onAction != null;
    if (!((MediaQuery.maybeOf(context)?.accessibleNavigation ?? false) &&
        needsAction)) {
      _autoDismissTimer = Timer(widget.duration, _dismissWithAnimation);
    }
  }

  Future<void> _dismissWithAnimation() async {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    if (mounted) {
      await _controller.reverse();
    }
    if (mounted) widget.onDismissed();
  }

  void _dismissAfterSwipe() {
    if (_dismissed) return;
    _dismissed = true;
    _autoDismissTimer?.cancel();
    widget.onDismissed();
  }

  void _runAction() {
    if (_dismissed) return;
    unawaited(_dismissWithAnimation());
    widget.onAction?.call();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.width < 700;
    final horizontalInset = compact ? 16.0 : 24.0;
    final availableWidth =
        mediaQuery.size.width -
        mediaQuery.padding.horizontal -
        horizontalInset * 2;
    final stackAction =
        availableWidth < 360 || mediaQuery.textScaler.scale(14) > 18;
    final background = widget.backgroundColor ?? scheme.surfaceContainerHigh;
    final foreground = widget.textColor ?? scheme.onSurface;
    final accent = switch (widget.kind) {
      SideToastKind.info => scheme.primary,
      SideToastKind.success => scheme.tertiary,
      SideToastKind.warning => scheme.secondary,
      SideToastKind.error => scheme.error,
    };
    final icon =
        widget.icon ??
        switch (widget.kind) {
          SideToastKind.info => Icons.info_outline_rounded,
          SideToastKind.success => Icons.check_circle_outline_rounded,
          SideToastKind.warning => Icons.warning_amber_rounded,
          SideToastKind.error => Icons.error_outline_rounded,
        };
    final hasAction = widget.actionLabel != null && widget.onAction != null;
    final action = hasAction
        ? TextButton(
            onPressed: _runAction,
            style: TextButton.styleFrom(
              foregroundColor: accent,
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(widget.actionLabel!),
          )
        : null;
    final message = Text(
      widget.message,
      style: TextStyle(
        color: foreground,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
    final toastCard = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: stackAction && hasAction
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [message, const SizedBox(height: 4), action!],
                    )
                  : message,
            ),
          ),
          if (!stackAction && hasAction) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return Positioned(
      top: mediaQuery.padding.top + (compact ? 8 : 16),
      left: compact ? mediaQuery.padding.left + horizontalInset : null,
      right: mediaQuery.padding.right + horizontalInset,
      child: Semantics(
        container: true,
        liveRegion: true,
        onDismiss: () => unawaited(_dismissWithAnimation()),
        child: Align(
          alignment: compact ? Alignment.topCenter : Alignment.topRight,
          widthFactor: 1,
          child: SlideTransition(
            position: _slideAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: availableWidth.clamp(0, 440),
                maxHeight:
                    (mediaQuery.size.height -
                            mediaQuery.padding.vertical -
                            mediaQuery.viewInsets.bottom -
                            32)
                        .clamp(0, double.infinity),
              ),
              child: Dismissible(
                key: _dismissibleKey,
                direction: DismissDirection.horizontal,
                resizeDuration: null,
                onDismissed: (_) => _dismissAfterSwipe(),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) => GlassSurface(
                    role: GlassSurfaceRole.floating,
                    shape: shape,
                    color: background,
                    visibility: _fadeAnimation.value,
                    child: child!,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: shape,
                    clipBehavior: Clip.antiAlias,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(child: toastCard),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
