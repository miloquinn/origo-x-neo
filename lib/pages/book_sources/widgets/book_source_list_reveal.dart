import 'package:flutter/material.dart';

/// A short, one-shot entrance used by lazily built discovery list rows.
///
/// The wrapper shape is fixed for a row's whole lifetime so the child subtree
/// never changes position in the element tree: tearing the animation wrapper
/// out after it finished would re-inflate the row and flash the generated
/// cover placeholder over an already-loaded cover. The controller only ticks
/// while the entrance plays; idle rows keep a completed controller that costs
/// nothing, and rows are disposed as soon as they scroll away.
class BookSourceListReveal extends StatefulWidget {
  const BookSourceListReveal({
    super.key,
    required this.animate,
    required this.child,
    this.order = 0,
  });

  final bool animate;
  final Widget child;
  final int order;

  @override
  State<BookSourceListReveal> createState() => _BookSourceListRevealState();
}

class _BookSourceListRevealState extends State<BookSourceListReveal>
    with SingleTickerProviderStateMixin {
  static const _entranceDuration = Duration(milliseconds: 220);

  late final bool _animate = widget.animate;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: widget.order.clamp(0, 4) * 24);
    _controller = AnimationController(
      vsync: this,
      value: 1,
      duration: _entranceDuration + delay,
    );
    _animation = _controller.drive(
      CurveTween(
        curve: Interval(
          delay.inMicroseconds / (_entranceDuration + delay).inMicroseconds,
          1,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      // Reduce motion turning on mid-entrance skips to the settled state
      // without changing the tree shape.
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller
          ..stop()
          ..value = 1;
      }
      return;
    }
    _started = true;
    if (_animate && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return widget.child;
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * value),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
