import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/glass_config.dart';
import '../utils/ui_style.dart';
import 'elastic_motion.dart';
import 'liquid_glass_surface.dart';

/// A row of navigation destinations with one spring-driven selection lens.
///
/// The widget owns only pointer presentation and destination picking. The
/// caller remains the source of truth for the selected index.
class ElasticPillNavigationBar extends StatefulWidget {
  const ElasticPillNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.children,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<Widget> children;

  @override
  State<ElasticPillNavigationBar> createState() =>
      _ElasticPillNavigationBarState();
}

class _ElasticPillNavigationBarState extends State<ElasticPillNavigationBar>
    with TickerProviderStateMixin {
  static final _trackSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 120),
  );
  static final _liftSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 280),
    bounce: 0.2,
  );
  static final _settleSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 500),
    bounce: 0.32,
  );

  late final ElasticSpring _lens = ElasticSpring(
    this,
    _selectedIndex.toDouble(),
  );
  late final ElasticSpring _lift = ElasticSpring(this, 0);
  late final Listenable _motion = Listenable.merge([_lens, _lift]);

  int? _pointer;
  int? _pressedIndex;
  double _pressX = 0;
  bool _dragging = false;
  bool _reduceMotion = false;

  int get _lastIndex => math.max(0, widget.children.length - 1);
  int get _selectedIndex => widget.selectedIndex.clamp(0, _lastIndex);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (reduceMotion) {
        _lens.jumpTo(_selectedIndex.toDouble());
        _lift.jumpTo(0);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ElasticPillNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.isEmpty) return;
    final target = _selectedIndex.toDouble();
    if (_pressedIndex == null) {
      _moveLensTo(target, _settleSpring);
    }
  }

  void _moveLensTo(double target, SpringDescription spring) {
    if (_reduceMotion) {
      _lens.jumpTo(target);
    } else {
      _lens.animateTo(target, spring);
    }
  }

  void _moveLiftTo(double target, SpringDescription spring) {
    if (_reduceMotion) {
      _lift.jumpTo(0);
    } else {
      _lift.animateTo(target, spring);
    }
  }

  double _positionAt(Offset localPosition) {
    final width = context.size?.width ?? 0;
    if (width <= 0 || widget.children.isEmpty) return 0;
    final dx = Directionality.of(context) == TextDirection.ltr
        ? localPosition.dx
        : width - localPosition.dx;
    final position = dx / (width / widget.children.length) - 0.5;
    return position.clamp(0.0, _lastIndex.toDouble());
  }

  int _indexAt(double position) => position.round().clamp(0, _lastIndex);

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointer != null ||
        widget.children.isEmpty ||
        event.buttons & kPrimaryButton == 0) {
      return;
    }
    _pointer = event.pointer;
    _pressX = event.localPosition.dx;
    _dragging = false;
    final position = _positionAt(event.localPosition);
    _pressedIndex = _indexAt(position);
    _moveLiftTo(1, _liftSpring);
    _moveLensTo(_pressedIndex!.toDouble(), _settleSpring);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || _pressedIndex == null) return;
    if (!_dragging && (event.localPosition.dx - _pressX).abs() < kTouchSlop) {
      return;
    }
    _dragging = true;
    final position = _positionAt(event.localPosition);
    _pressedIndex = _indexAt(position);
    _moveLensTo(position, _trackSpring);
  }

  void _handlePointerEnd(PointerEvent event) {
    if (event.pointer != _pointer) return;
    final commit = event is PointerUpEvent && _dragging;
    final selectedIndex = _pressedIndex;
    _pointer = null;
    _pressedIndex = null;
    _dragging = false;
    _moveLiftTo(0, _settleSpring);
    if (!commit || selectedIndex == null) {
      _moveLensTo(_selectedIndex.toDouble(), _settleSpring);
      return;
    }
    _moveLensTo(selectedIndex.toDouble(), _settleSpring);
    if (selectedIndex != widget.selectedIndex) {
      widget.onSelected(selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final isMaterial3Style =
        Theme.of(
          context,
        ).extension<UiStyleThemeExtension>()?.isMaterial3Style ??
        false;
    final selectedColor = Color.lerp(
      isMaterial3Style ? scheme.surfaceContainerHighest : scheme.surface,
      scheme.primary,
      scheme.brightness == Brightness.light ? 0.13 : 0.24,
    )!;
    final usesLiquidGlass =
        GlassEffectConfig.usesLiquidGlass && !isMaterial3Style;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final extent = constraints.maxWidth / widget.children.length;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _motion,
                builder: (context, _) {
                  final speedStretch =
                      (_lens.velocity.abs() / 8).clamp(0.0, 1.0) * 0.25;
                  final growth = 14 * 2 * _lift.value;
                  final width = (extent + growth) * (1 + speedStretch);
                  final height =
                      (constraints.maxHeight + growth) * (1 - speedStretch / 2);
                  final centerX = (_lens.value + 0.5) * extent;
                  final lensShape = RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(height / 2),
                  );
                  return PositionedDirectional(
                    key: const ValueKey('home-navigation-selection-lens'),
                    start: centerX - width / 2,
                    top: (constraints.maxHeight - height) / 2,
                    width: width,
                    height: height,
                    child: IgnorePointer(
                      child: usesLiquidGlass
                          ? ClipPath(
                              clipper: ShapeBorderClipper(shape: lensShape),
                              child: LiquidGlassSurface(
                                shape: lensShape,
                                color: selectedColor,
                                child: const SizedBox.expand(),
                              ),
                            )
                          : DecoratedBox(
                              decoration: ShapeDecoration(
                                color: selectedColor,
                                shape: RoundedSuperellipseBorder(
                                  side: BorderSide(
                                    color: scheme.primary.withValues(
                                      alpha:
                                          scheme.brightness == Brightness.light
                                          ? 0.08
                                          : 0.16,
                                    ),
                                    width: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    height / 2,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (final child in widget.children) Expanded(child: child),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _lens.dispose();
    _lift.dispose();
    super.dispose();
  }
}
