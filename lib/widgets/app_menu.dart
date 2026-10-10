import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'app_skin_icon.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'elastic_motion.dart';
import 'elastic_press.dart';
import 'glass_buttons.dart';
import 'glass_top_bar.dart';

/// Trigger appearance is independent of the shared menu surface and motion.
enum AppMenuButtonStyle { plain, circular }

/// The shared anchored menu. Keep PopupMenuEntry as the data adapter so callers
/// retain their values, disabled states, checked items and section dividers.
class AppPopupMenuButton<T> extends StatefulWidget {
  const AppPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.onCanceled,
    this.initialValue,
    this.tooltip,
    this.icon,
    this.child,
    this.enabled = true,
    this.constraints,
    this.color,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(8),
    this.anchorRadius,
    this.buttonStyle = AppMenuButtonStyle.plain,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final ValueChanged<T>? onSelected;
  final VoidCallback? onCanceled;
  final T? initialValue;
  final String? tooltip;
  final Widget? icon;
  final Widget? child;
  final bool enabled;
  final BoxConstraints? constraints;
  final Color? color;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final double? anchorRadius;
  final AppMenuButtonStyle buttonStyle;

  @override
  State<AppPopupMenuButton<T>> createState() => _AppPopupMenuButtonState<T>();
}

class _AppPopupMenuButtonState<T> extends State<AppPopupMenuButton<T>> {
  bool _open = false;

  Future<void> _show() async {
    if (_open || !widget.enabled) return;
    final items = widget.itemBuilder(context);
    if (items.isEmpty) return;
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    try {
      final value = await showAppMenu<T>(
        context: context,
        anchor: anchor,
        items: items,
        initialValue: widget.initialValue,
        constraints: widget.constraints,
        color: widget.color,
        anchorRadius: widget.anchorRadius,
        anchorIcon: widget.child == null
            ? IconTheme.merge(
                data: IconThemeData(size: widget.iconSize),
                child: AppSkinIcon.adapt(
                  widget.icon ?? const Icon(Icons.more_vert_rounded),
                ),
              )
            : null,
      );
      if (!mounted) return;
      setState(() => _open = false);
      if (value != null) {
        widget.onSelected?.call(value);
      } else {
        widget.onCanceled?.call();
      }
    } finally {
      if (mounted && _open) setState(() => _open = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tooltip =
        widget.tooltip ?? MaterialLocalizations.of(context).moreButtonTooltip;
    final originalIcon = widget.icon ?? const Icon(Icons.more_vert_rounded);
    final icon = AppSkinIcon.adapt(originalIcon);
    final resolvedPadding = widget.padding.resolve(Directionality.of(context));
    final glyphSize = originalIcon is Icon
        ? originalIcon.size ?? widget.iconSize
        : widget.iconSize;
    final tapTarget =
        IconButtonTheme.of(context).style?.tapTargetSize ??
        Theme.of(context).materialTapTargetSize;
    final minimumDimension = tapTarget == MaterialTapTargetSize.padded
        ? kMinInteractiveDimension
        : 44.0;
    final iconButton = IconButton(
      tooltip: tooltip,
      onPressed: widget.enabled ? _show : null,
      padding: widget.padding,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      iconSize: widget.iconSize,
      icon: icon,
    );
    final trigger = widget.child != null
        ? Tooltip(
            message: tooltip,
            child: Semantics(
              button: true,
              enabled: widget.enabled,
              onTap: widget.enabled ? _show : null,
              child: InkWell(
                excludeFromSemantics: true,
                onTap: widget.enabled ? _show : null,
                borderRadius: BorderRadius.circular(widget.anchorRadius ?? 24),
                child: widget.child,
              ),
            ),
          )
        : widget.buttonStyle == AppMenuButtonStyle.circular
        ? GlassIconButton(
            icon: AppSkinIcon.adapt(
              widget.icon ?? const Icon(Icons.more_vert_rounded),
            ),
            iconSize: widget.iconSize,
            padding: widget.padding,
            tooltip: tooltip,
            onPressed: widget.enabled ? _show : null,
            blurBackground:
                context.findAncestorWidgetOfExactType<GlassTopBar>() == null,
            // The route owns the trigger's single spring and visibility below.
            animatePress: false,
          )
        : icon is AppSkinIcon
        ? SizedBox(
            width: math.max(
              minimumDimension,
              glyphSize + resolvedPadding.horizontal,
            ),
            height: math.max(
              minimumDimension,
              glyphSize + resolvedPadding.vertical,
            ),
            child: iconButton,
          )
        : iconButton;
    // Retain the trigger's layout and focus while the route owns its surface.
    return IgnorePointer(
      ignoring: _open,
      child: Opacity(
        opacity: _open ? 0 : 1,
        child: ElasticPress(enabled: widget.enabled && !_open, child: trigger),
      ),
    );
  }
}

/// [anchor] is in global logical coordinates, like RenderBox.localToGlobal.
/// Resolves only after the reverse transition, before a caller opens another UI.
Future<T?> showAppMenu<T>({
  required BuildContext context,
  required Rect anchor,
  required List<PopupMenuEntry<T>> items,
  T? initialValue,
  BoxConstraints? constraints,
  Color? color,
  double? anchorRadius,
  Widget? anchorIcon,
}) async {
  if (items.isEmpty) return null;
  final navigator = Navigator.of(context);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final route = _AppMenuRoute<T>(
    anchor: anchor.shift(-overlay.localToGlobal(Offset.zero)),
    items: items,
    initialValue: initialValue,
    constraints: constraints,
    color: color,
    anchorRadius: anchorRadius ?? anchor.shortestSide / 2,
    anchorIcon: anchorIcon,
    media: MediaQuery.of(context),
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
  final result = await navigator.push<T>(route);
  await route.completed;
  route.selectedCallback?.call();
  return result;
}

class _AppMenuRoute<T> extends PopupRoute<T> {
  _AppMenuRoute({
    required this.anchor,
    required this.items,
    required this.initialValue,
    required this.constraints,
    required this.color,
    required this.anchorRadius,
    required this.anchorIcon,
    required this.media,
    required this.themes,
    required this.barrierLabel,
  });

  final Rect anchor;
  final List<PopupMenuEntry<T>> items;
  final T? initialValue;
  final BoxConstraints? constraints;
  final Color? color;
  final double anchorRadius;
  final Widget? anchorIcon;
  final MediaQueryData media;
  final CapturedThemes themes;
  VoidCallback? selectedCallback;

  static const _openDuration = Duration(milliseconds: 750);
  static const _closeDuration = Duration(milliseconds: 400);
  late final _grow = _spring(
    const Duration(milliseconds: 500),
    0.3,
    const Duration(milliseconds: 340),
  );
  late final _moveX = _spring(
    const Duration(milliseconds: 520),
    0.2,
    const Duration(milliseconds: 300),
  );
  late final _moveY = _spring(
    const Duration(milliseconds: 340),
    0.12,
    const Duration(milliseconds: 440),
  );
  late final _content = CurvedAnimation(
    parent: animation!,
    curve: const Interval(0.04, 0.45, curve: Curves.easeOutCubic),
    reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn),
  );

  CurvedAnimation _spring(
    Duration settling,
    double bounce,
    Duration returning,
  ) => CurvedAnimation(
    parent: animation!,
    curve: ElasticSpringCurve(
      duration: _openDuration,
      settlingDuration: settling,
      bounce: bounce,
    ),
    reverseCurve: ElasticSpringCurve(
      duration: _closeDuration,
      settlingDuration: returning,
    ).flipped,
  );

  @override
  void dispose() {
    _grow.dispose();
    _moveX.dispose();
    _moveY.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  final String barrierLabel;
  @override
  bool get barrierDismissible => true;
  @override
  Color? get barrierColor => Colors.transparent;
  @override
  Duration get transitionDuration =>
      media.disableAnimations ? Duration.zero : _openDuration;
  @override
  Duration get reverseTransitionDuration =>
      media.disableAnimations ? Duration.zero : _closeDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(
      MediaQuery(
        data: media,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).pop(),
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                FocusScope.of(context).nextFocus(),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                FocusScope.of(context).previousFocus(),
          },
          child: LayoutBuilder(
            builder: (context, viewport) {
              final safe = Rect.fromLTRB(
                media.padding.left + 12,
                media.padding.top + 12,
                viewport.maxWidth - media.padding.right - 12,
                viewport.maxHeight -
                    math.max(media.padding.bottom, media.viewInsets.bottom) -
                    12,
              );
              final availableWidth = math.max(1.0, safe.width);
              final double width = math.min<double>(
                availableWidth,
                math
                    .max(272.0, math.min(anchor.width, 360.0))
                    .clamp(
                      constraints?.minWidth ?? 0.0,
                      constraints?.maxWidth ?? double.infinity,
                    ),
              );
              final geometry = _MenuGeometry(anchor, safe, anchorRadius);
              return CustomSingleChildLayout(
                delegate: _MenuLayout(geometry, width),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final progress = _grow.value;
                    final clipper = _MenuClipper(
                      geometry,
                      progress,
                      _moveX.value,
                      _moveY.value,
                    );
                    final scheme = Theme.of(context).colorScheme;
                    final reveal = _content.value;
                    return CustomPaint(
                      key: const ValueKey('app-menu-morph-surface'),
                      painter: _MenuSurface(
                        clipper,
                        (color ?? scheme.surfaceContainerLow).withValues(
                          alpha: 1,
                        ),
                        scheme.shadow,
                        progress,
                      ),
                      foregroundPainter: _MenuBorder(
                        clipper,
                        scheme.outlineVariant,
                      ),
                      child: ClipPath(
                        clipper: clipper,
                        child: Material(
                          color: Colors.transparent,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IgnorePointer(
                                ignoring:
                                    animation.status !=
                                    AnimationStatus.completed,
                                child: Opacity(
                                  opacity: reveal,
                                  child: _MenuContentMotion(
                                    geometry: geometry,
                                    progress: progress,
                                    moveX: _moveX.value,
                                    moveY: _moveY.value,
                                    child: child!,
                                  ),
                                ),
                              ),
                              if (anchorIcon != null && progress < 1)
                                Positioned.fill(
                                  child: CustomSingleChildLayout(
                                    delegate: _AnchorIconLayout(
                                      geometry,
                                      progress,
                                      _moveX.value,
                                      _moveY.value,
                                    ),
                                    child: Opacity(
                                      opacity: 1 - reveal,
                                      child: anchorIcon,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: FocusTraversalGroup(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _tiles(context),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _tiles(BuildContext context) {
    bool focusAssigned = false;
    return [
      for (final item in items)
        if (item is PopupMenuDivider)
          const Divider(height: 11, indent: 12, endIndent: 12)
        else if (item is PopupMenuItem<T>)
          _AppMenuTile(
            key: item.key,
            item: item,
            selected: item is CheckedPopupMenuItem<T>
                ? item.checked
                : initialValue != null && item.value == initialValue,
            autofocus: item.enabled && !focusAssigned && (focusAssigned = true),
            onTap: item.enabled
                ? () {
                    selectedCallback = item.onTap;
                    Navigator.of(context).pop(item.value);
                  }
                : null,
          ),
    ];
  }
}

class _AppMenuTile<T> extends StatelessWidget {
  const _AppMenuTile({
    super.key,
    required this.item,
    required this.selected,
    required this.autofocus,
    required this.onTap,
  });
  final PopupMenuItem<T> item;
  final bool selected;
  final bool autofocus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = item.child;
    final tile = content is ListTile ? content : null;
    final tileTheme = ListTileTheme.of(context);
    final iconColor = tile == null
        ? scheme.onSurfaceVariant
        : tile.iconColor ?? tileTheme.iconColor ?? scheme.onSurfaceVariant;
    final textColor = tile == null
        ? scheme.onSurface
        : tile.textColor ?? tileTheme.textColor ?? scheme.onSurface;
    return Semantics(
      selected: selected,
      enabled: item.enabled,
      button: true,
      child: InkWell(
        onTap: onTap,
        autofocus: autofocus,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: item.enabled ? 1 : 0.42,
          child: Ink(
            decoration: BoxDecoration(
              color: selected ? scheme.primary.withValues(alpha: 0.09) : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(48, item.height)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: iconColor, size: 21),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    child: Row(
                      children: [
                        if (tile?.leading != null) ...[
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(child: tile!.leading),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: tile == null
                              ? content ?? const SizedBox.shrink()
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    tile.title ?? const SizedBox.shrink(),
                                    if (tile.subtitle != null) tile.subtitle!,
                                  ],
                                ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_rounded,
                            color: scheme.primary,
                            size: 19,
                          ),
                        ] else if (tile?.trailing != null)
                          tile!.trailing!,
                      ],
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

class _MenuGeometry {
  const _MenuGeometry(this.anchor, this.safe, this.radius);
  final Rect anchor;
  final Rect safe;
  final double radius;

  Offset position(Size size) {
    final x = (anchor.right - size.width).clamp(
      safe.left,
      math.max(safe.left, safe.right - size.width),
    );
    // Grow down from a top action; grow upward from a bottom list action.
    final y =
        (anchor.top + size.height <= safe.bottom
                ? anchor.top
                : anchor.bottom - size.height)
            .clamp(safe.top, math.max(safe.top, safe.bottom - size.height));
    return Offset(x.toDouble(), y.toDouble());
  }

  Rect rect(Size size, double progress, double moveX, double moveY) {
    final origin = anchor.shift(-position(size));
    final extent = Size.lerp(origin.size, size, progress)!;
    return Rect.fromCenter(
      center: Offset(
        lerpDouble(origin.center.dx, size.width / 2, moveX)!,
        lerpDouble(origin.center.dy, size.height / 2, moveY)!,
      ),
      width: math.max(0, extent.width),
      height: math.max(0, extent.height),
    );
  }

  Path shape(Size size, double progress, double moveX, double moveY) =>
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(
          math.max(0, lerpDouble(radius, 24, progress)!),
        ),
      ).getOuterPath(rect(size, progress, moveX, moveY));
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.geometry, this.width);
  final _MenuGeometry geometry;
  final double width;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        minWidth: width,
        maxWidth: width,
        maxHeight: math.max(1, geometry.safe.height),
      );
  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      geometry.position(childSize);
  @override
  bool shouldRelayout(covariant _MenuLayout oldDelegate) => true;
}

class _AnchorIconLayout extends SingleChildLayoutDelegate {
  _AnchorIconLayout(this.geometry, this.progress, this.moveX, this.moveY);
  final _MenuGeometry geometry;
  final double progress;
  final double moveX;
  final double moveY;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.tight(geometry.anchor.size);
  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      geometry.rect(size, progress, moveX, moveY).center -
      Offset(childSize.width / 2, childSize.height / 2);
  @override
  bool shouldRelayout(covariant _AnchorIconLayout oldDelegate) => true;
}

class _MenuClipper extends CustomClipper<Path> {
  _MenuClipper(this.geometry, this.progress, this.moveX, this.moveY);
  final _MenuGeometry geometry;
  final double progress;
  final double moveX;
  final double moveY;
  @override
  Path getClip(Size size) => geometry.shape(size, progress, moveX, moveY);
  @override
  bool shouldReclip(covariant _MenuClipper oldClipper) => true;
}

class _MenuSurface extends CustomPainter {
  _MenuSurface(this.clipper, this.color, this.shadow, this.progress);
  final _MenuClipper clipper;
  final Color color;
  final Color shadow;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint the same path as the clip, including spring overshoot outside layout.
    // A fixed-size Material or backdrop would leave a second visible silhouette.
    final path = clipper.getClip(size);
    canvas.drawShadow(
      path,
      shadow.withValues(alpha: 0.2 * progress.clamp(0.0, 1.0)),
      12 * progress.clamp(0.0, 1.0),
      false,
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MenuSurface oldDelegate) => true;
}

class _MenuBorder extends CustomPainter {
  _MenuBorder(this.clipper, this.color);
  final _MenuClipper clipper;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    clipper.getClip(size),
    Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8,
  );
  @override
  bool shouldRepaint(covariant _MenuBorder oldDelegate) => true;
}

class _MenuContentMotion extends SingleChildRenderObjectWidget {
  const _MenuContentMotion({
    required this.geometry,
    required this.progress,
    required this.moveX,
    required this.moveY,
    required super.child,
  });

  final _MenuGeometry geometry;
  final double progress;
  final double moveX;
  final double moveY;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMenuContentMotion(geometry, progress, moveX, moveY);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMenuContentMotion renderObject,
  ) {
    renderObject
      ..geometry = geometry
      ..progress = progress
      ..moveX = moveX
      ..moveY = moveY
      ..markNeedsPaint();
  }
}

class _RenderMenuContentMotion extends RenderProxyBox {
  _RenderMenuContentMotion(
    this.geometry,
    this.progress,
    this.moveX,
    this.moveY,
  );
  _MenuGeometry geometry;
  double progress;
  double moveX;
  double moveY;

  Matrix4 get transform {
    final rect = geometry.rect(size, progress, moveX, moveY);
    final scale = math.max(rect.width / size.width, rect.height / size.height);
    return Matrix4.translationValues(rect.center.dx, rect.center.dy, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    context.pushTransform(needsCompositing, offset, transform, super.paint);
  }
}
