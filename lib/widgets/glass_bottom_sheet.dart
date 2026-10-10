import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_surface.dart';

const _sheetPhoneRadius = 40.0;
const _sheetCardRadius = 32.0;
const _sheetCompactShortestSide = 600.0;
const _sheetMaxWidth = 640.0;
const _sheetMargin = EdgeInsets.all(8);
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
/// Content extends to the panel edge by default. Builders consume the bottom
/// safe-area inset at the end of scrolling content or in their fixed footer.
/// Set [extendContentIntoBottomSafeArea] to false for a protected legacy layout.
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
  bool extendContentIntoBottomSafeArea = true,
}) {
  final reducedMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  final panelColor = backgroundColor?.a == 0 ? null : backgroundColor;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    // Keep the panel's paint outside side/bottom system insets. The shared
    // surface protects content inside it, and the route still caps its height
    // below the top status area.
    useSafeArea: false,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    clipBehavior: Clip.none,
    barrierColor: barrierColor,
    constraints: constraints ?? const BoxConstraints(),
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
        useSafeArea: useSafeArea,
        extendContentIntoBottomSafeArea: extendContentIntoBottomSafeArea,
        child: content,
      );
      if (useSafeArea) {
        // The native route removes top padding when useSafeArea is false.
        // Read above that removal, so tall panels retain status-bar protection
        // without adding an invisible top spacer to ordinary half sheets.
        final topInset = MediaQuery.paddingOf(
          Navigator.of(routeContext).context,
        ).top;
        surface = ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.max(
              0,
              MediaQuery.sizeOf(routeContext).height - topInset,
            ),
          ),
          child: surface,
        );
      }
      if (theme != null) surface = Theme(data: theme, child: surface);
      return surface;
    },
  );
}

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
    this.extendContentIntoBottomSafeArea = false,
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

  /// Leaves the bottom safe-area inset that remains inside [margin] in
  /// [MediaQuery], so a scrolling child can consume it at the end of its
  /// content while its viewport fills the rounded panel. Shared routes enable
  /// this by default; fixed content protects its own controls or footer.
  final bool extendContentIntoBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    if (_GlassBottomSheetSurfaceScope.maybeOf(context) != null) return child;

    final routeScope = _GlassBottomSheetRouteScope.maybeOf(context);
    final dismiss = routeScope?.onDismiss;
    final effectiveShowDragHandle =
        routeScope?.showDragHandle ?? showDragHandle;
    final effectiveExtendContentIntoBottomSafeArea =
        routeScope?.extendContentIntoBottomSafeArea ??
        extendContentIntoBottomSafeArea;
    final media = MediaQuery.of(context);
    final compact = media.size.shortestSide < _sheetCompactShortestSide;
    final resolvedMargin = margin.resolve(Directionality.of(context));
    final shape = _sheetShape(media, compact, resolvedMargin);
    Widget content = child;
    if (routeScope?.useSafeArea ?? false) {
      final bottomContentInset = math.max(
        0.0,
        media.padding.bottom - resolvedMargin.bottom,
      );
      final bottomViewContentInset = math.max(
        0.0,
        media.viewPadding.bottom - resolvedMargin.bottom,
      );
      final removedMedia = media.removePadding(
        removeLeft: true,
        removeRight: true,
        removeBottom: true,
      );
      final contentMedia = effectiveExtendContentIntoBottomSafeArea
          ? removedMedia.copyWith(
              padding: removedMedia.padding.copyWith(
                bottom: bottomContentInset,
              ),
              viewPadding: removedMedia.viewPadding.copyWith(
                bottom: bottomViewContentInset,
              ),
            )
          : removedMedia;
      content = Padding(
        padding: EdgeInsets.only(
          left: math.max(0.0, media.padding.left - resolvedMargin.left),
          right: math.max(0.0, media.padding.right - resolvedMargin.right),
          bottom: effectiveExtendContentIntoBottomSafeArea
              ? 0.0
              : bottomContentInset,
        ),
        child: MediaQuery(data: contentMedia, child: content),
      );
    }
    if (effectiveShowDragHandle) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlassBottomSheetDragHandle(onDismiss: dismiss),
          Flexible(fit: FlexFit.loose, child: content),
        ],
      );
    }

    return _GlassBottomSheetSurfaceScope(
      child: Padding(
        padding: margin,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: compact ? double.infinity : _sheetMaxWidth,
            ),
            child: SizedBox(
              width: double.infinity,
              child: GlassSurface(
                role: GlassSurfaceRole.panel,
                shape: shape,
                color: color?.a == 0 ? null : color,
                outlineColor: outlineColor,
                shadowColor: shadowColor,
                brightness: brightness,
                child: Material(
                  type: MaterialType.transparency,
                  shape: shape,
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

RoundedSuperellipseBorder _sheetShape(
  MediaQueryData media,
  bool compact,
  EdgeInsets margin,
) {
  var radius = compact ? _sheetPhoneRadius : _sheetCardRadius;
  final screenCorners = media.displayCornerRadii;
  if (compact && screenCorners != null) {
    final reported = [
      screenCorners.topLeft.x,
      screenCorners.topRight.x,
      screenCorners.bottomLeft.x,
      screenCorners.bottomRight.x,
    ].where((value) => value.isFinite && value > 0);
    if (reported.isNotEmpty) {
      // The shared liquid shader accepts one radius. Use a conservative
      // uniform concentric radius on displays that report their geometry.
      radius = math.max(0, reported.reduce(math.min) - margin.bottom);
    }
  }
  // iOS does not report displayCornerRadii. These are optical design tokens,
  // never an inferred hardware radius or a device-model lookup table.
  return RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));
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
    required this.useSafeArea,
    required this.extendContentIntoBottomSafeArea,
    required super.child,
  });

  final VoidCallback? onDismiss;
  final bool showDragHandle;
  final bool useSafeArea;
  final bool extendContentIntoBottomSafeArea;

  static _GlassBottomSheetRouteScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GlassBottomSheetRouteScope>();

  @override
  bool updateShouldNotify(_GlassBottomSheetRouteScope oldWidget) =>
      onDismiss != oldWidget.onDismiss ||
      showDragHandle != oldWidget.showDragHandle ||
      useSafeArea != oldWidget.useSafeArea ||
      extendContentIntoBottomSafeArea !=
          oldWidget.extendContentIntoBottomSafeArea;
}
