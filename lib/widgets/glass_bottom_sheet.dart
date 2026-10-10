import 'package:flutter/material.dart';

import 'glass_surface.dart';

const _sheetRadius = 28.0;
const _sheetMaxWidth = 640.0;
const _sheetMargin = EdgeInsets.fromLTRB(8, 0, 8, 8);
const _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(_sheetRadius)),
);
const _sheetAnimation = AnimationStyle(
  curve: Curves.easeOutCubic,
  duration: Duration(milliseconds: 300),
  reverseCurve: Curves.easeInCubic,
  reverseDuration: Duration(milliseconds: 220),
);

/// Shows a modal bottom sheet whose route keeps Flutter's native interaction
/// contract while [GlassBottomSheetSurface] owns the visible panel.
///
/// The native route remains responsible for drag-to-dismiss, the barrier,
/// focus, typed results and transition progress. The route material itself is
/// transparent so there is exactly one visible surface and one drag handle.
/// Set [builderOwnsSurface] when live content owns its palette and returns a
/// [GlassBottomSheetSurface] whose material must rebuild with that state.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  Color? barrierColor,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
  ThemeData? theme,
  bool builderOwnsSurface = false,
}) {
  final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final panelColor = backgroundColor?.a == 0 ? null : backgroundColor;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    clipBehavior: Clip.none,
    barrierColor: barrierColor,
    constraints: _boundedConstraints(constraints),
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
    sheetAnimationStyle: reducedMotion
        ? AnimationStyle.noAnimation
        : _sheetAnimation,
    builder: (routeContext) {
      Widget content = builderOwnsSurface
          ? Builder(builder: builder)
          : GlassBottomSheetSurface(
              showDragHandle: showDragHandle,
              color: panelColor,
              child: Builder(builder: builder),
            );
      Widget surface = _GlassBottomSheetRouteScope(
        onDismiss: isDismissible
            ? () => Navigator.of(routeContext).maybePop()
            : null,
        showDragHandle: showDragHandle,
        child: content,
      );
      if (useSafeArea) {
        surface = SafeArea(
          top: false,
          left: false,
          right: false,
          child: surface,
        );
      }
      if (theme != null) surface = Theme(data: theme, child: surface);
      return surface;
    },
  );
}

BoxConstraints _boundedConstraints(BoxConstraints? constraints) =>
    (constraints ?? const BoxConstraints()).enforce(
      const BoxConstraints(maxWidth: _sheetMaxWidth),
    );

/// Shared rounded panel for bottom-sheet content and standalone previews.
///
/// When a migrated content shell is nested inside [showGlassBottomSheet], the
/// outer route surface remains the sole glass/filter and handle owner.
class GlassBottomSheetSurface extends StatelessWidget {
  const GlassBottomSheetSurface({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.color,
    this.outlineColor,
    this.shadowColor,
    this.brightness,
    this.margin = _sheetMargin,
  });

  static const dragHandleKey = ValueKey<String>(
    'glass-bottom-sheet-drag-handle',
  );
  static const double dragHandleExtent = 44;

  final Widget child;
  final bool showDragHandle;
  final Color? color;
  final Color? outlineColor;
  final Color? shadowColor;
  final Brightness? brightness;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (_GlassBottomSheetSurfaceScope.maybeOf(context) != null) return child;

    final routeScope = _GlassBottomSheetRouteScope.maybeOf(context);
    final dismiss = routeScope?.onDismiss;
    final effectiveShowDragHandle =
        routeScope?.showDragHandle ?? showDragHandle;
    Widget content = child;
    if (effectiveShowDragHandle) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlassBottomSheetDragHandle(onDismiss: dismiss),
          Flexible(fit: FlexFit.loose, child: child),
        ],
      );
    }

    return _GlassBottomSheetSurfaceScope(
      child: Padding(
        padding: margin,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
            child: SizedBox(
              width: double.infinity,
              child: GlassSurface(
                role: GlassSurfaceRole.panel,
                shape: _sheetShape,
                color: color?.a == 0 ? null : color,
                outlineColor: outlineColor,
                shadowColor: shadowColor,
                brightness: brightness,
                child: Material(
                  type: MaterialType.transparency,
                  shape: _sheetShape,
                  clipBehavior: Clip.antiAlias,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBottomSheetDragHandle extends StatelessWidget {
  const _GlassBottomSheetDragHandle({this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final handle = Center(
      child: Container(
        width: 40,
        height: highContrast ? 5 : 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withValues(
            alpha: highContrast ? 0.82 : 0.56,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );

    if (onDismiss == null) {
      return SizedBox(
        key: GlassBottomSheetSurface.dragHandleKey,
        height: GlassBottomSheetSurface.dragHandleExtent,
        child: ExcludeSemantics(child: handle),
      );
    }

    final localizations = MaterialLocalizations.of(context);
    return Semantics(
      label: localizations.modalBarrierDismissLabel,
      button: true,
      onTap: onDismiss,
      child: GestureDetector(
        key: GlassBottomSheetSurface.dragHandleKey,
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: SizedBox(
          height: GlassBottomSheetSurface.dragHandleExtent,
          child: handle,
        ),
      ),
    );
  }
}

class _GlassBottomSheetSurfaceScope extends InheritedWidget {
  const _GlassBottomSheetSurfaceScope({required super.child});

  static _GlassBottomSheetSurfaceScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_GlassBottomSheetSurfaceScope>();

  @override
  bool updateShouldNotify(_GlassBottomSheetSurfaceScope oldWidget) => false;
}

class _GlassBottomSheetRouteScope extends InheritedWidget {
  const _GlassBottomSheetRouteScope({
    required this.onDismiss,
    required this.showDragHandle,
    required super.child,
  });

  final VoidCallback? onDismiss;
  final bool showDragHandle;

  static _GlassBottomSheetRouteScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassBottomSheetRouteScope>();

  @override
  bool updateShouldNotify(_GlassBottomSheetRouteScope oldWidget) =>
      onDismiss != oldWidget.onDismiss ||
      showDragHandle != oldWidget.showDragHandle;
}
