import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'elastic_motion.dart';

class ElasticPress extends StatefulWidget {
  const ElasticPress({
    super.key,
    this.enabled = true,
    this.edgePullOnly = false,
    required this.child,
  });

  final bool enabled;
  final bool edgePullOnly;
  final Widget child;

  @override
  State<ElasticPress> createState() => _ElasticPressState();
}

class _ElasticPressState extends State<ElasticPress>
    with TickerProviderStateMixin {
  static final _pressSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 280),
    bounce: 0.2,
  );
  static final _followSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 120),
  );
  static final _releaseSpring = SpringDescription.withDurationAndBounce(
    duration: const Duration(milliseconds: 500),
    bounce: 0.32,
  );
  late final _lift = ElasticSpring(this, 0);
  late final _x = ElasticSpring(this, 0);
  late final _y = ElasticSpring(this, 0);
  late final _motion = Listenable.merge([_lift, _x, _y]);
  int? _pointer;
  Offset _origin = Offset.zero;
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) _reset();
  }

  @override
  void didUpdateWidget(covariant ElasticPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _reset();
  }

  void _reset() {
    _pointer = null;
    _lift.jumpTo(0);
    _x.jumpTo(0);
    _y.jumpTo(0);
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled ||
        _reducedMotion ||
        _pointer != null ||
        event.buttons & kPrimaryButton == 0) {
      return;
    }
    _pointer = event.pointer;
    _origin = event.localPosition;
    _lift.animateTo(1, _pressSpring);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    final size = context.size!;
    final limit = size.shortestSide * 0.22;
    final point = event.localPosition;
    final delta = widget.edgePullOnly
        ? Offset(
            point.dx - point.dx.clamp(0.0, size.width),
            point.dy - point.dy.clamp(0.0, size.height),
          )
        : point - _origin;
    double resisted(double distance) => limit == 0
        ? 0
        : distance.sign * limit * (1 - 1 / (distance.abs() * 0.55 / limit + 1));
    _x.animateTo(resisted(delta.dx), _followSpring);
    _y.animateTo(resisted(delta.dy), _followSpring);
  }

  void _end(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _lift.animateTo(0, _releaseSpring);
    _x.animateTo(0, _releaseSpring);
    _y.animateTo(0, _releaseSpring);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _end,
    onPointerCancel: _end,
    child: AnimatedBuilder(
      animation: _motion,
      builder: (_, child) => _PressPaint(
        lift: _lift.value,
        pull: Offset(_x.value, _y.value),
        child: child,
      ),
      child: widget.child,
    ),
  );

  @override
  void dispose() {
    _lift.dispose();
    _x.dispose();
    _y.dispose();
    super.dispose();
  }
}

class _PressPaint extends SingleChildRenderObjectWidget {
  const _PressPaint({required this.lift, required this.pull, super.child});
  final double lift;
  final Offset pull;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPressPaint(lift, pull);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPressPaint renderObject,
  ) {
    renderObject
      ..lift = lift
      ..pull = pull
      ..markNeedsPaint();
  }
}

/// Painting alone moves the glass; layout and popup anchors stay at rest.
class _RenderPressPaint extends RenderProxyBox {
  _RenderPressPaint(this.lift, this.pull);
  double lift;
  Offset pull;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty || (lift == 0 && pull == Offset.zero)) {
      super.paint(context, offset);
      return;
    }
    final swell = 1 + lift * math.min(0.25, 16 / size.longestSide);
    final sx = swell * (1 + pull.dx.abs() / size.width * 0.5);
    final sy = swell * (1 + pull.dy.abs() / size.height * 0.5);
    final center = size.center(Offset.zero);
    final transform = Matrix4.diagonal3Values(sx, sy, 1)
      ..setTranslationRaw(
        center.dx * (1 - sx) + pull.dx,
        center.dy * (1 - sy) + pull.dy,
        0,
      );
    context.pushTransform(needsCompositing, offset, transform, super.paint);
  }
}
