import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/utils/page_style_helper.dart';

/// Expands a folder into the shelf without retaining a second live collection.
class LibraryShelfTransition extends StatefulWidget {
  const LibraryShelfTransition({
    super.key,
    required this.directoryId,
    required this.opening,
    required this.child,
    this.originKey,
  });

  final String? directoryId;
  final bool opening;
  final GlobalKey? originKey;
  final Widget child;

  @override
  State<LibraryShelfTransition> createState() => LibraryShelfTransitionState();
}

class LibraryShelfTransitionState extends State<LibraryShelfTransition>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  late final _animation = AnimationController(vsync: this, value: 1)
    ..addStatusListener(_animationChanged);
  ui.Image? _snapshot;
  Rect _origin = Rect.zero;
  bool _hasOrigin = false;
  bool _waitingForReturnLayout = false;
  int _navigationGeneration = 0;
  bool _reduceMotion = false;
  bool _tickerEnabled = true;
  bool _finishingTransition = false;

  bool get isAnimating => _waitingForReturnLayout || _animation.isAnimating;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (reduceMotion && !_reduceMotion && isAnimating) {
      _finishTransition();
    } else if (!tickerEnabled && _tickerEnabled && isAnimating) {
      _finishTransition();
    }
    _reduceMotion = reduceMotion;
    _tickerEnabled = tickerEnabled;
  }

  @override
  void didUpdateWidget(LibraryShelfTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.directoryId == widget.directoryId) return;
    final generation = ++_navigationGeneration;
    _releaseSnapshot();
    _hasOrigin = false;
    if (!_tickerEnabled) {
      _finishTransition(invalidateCallbacks: false);
      return;
    }
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary && boundary.hasSize) {
      if (widget.opening) {
        if (_tryReadOrigin() case final origin?) {
          _origin = origin;
          _hasOrigin = true;
        }
      }
      var painted = true;
      assert(() {
        painted = !boundary.debugNeedsPaint;
        return true;
      }());
      if (!_reduceMotion && painted) {
        // One temporary image, capped at two million pixels on large screens.
        final ratio = math.min(
          MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0),
          math.sqrt(2000000 / (boundary.size.width * boundary.size.height)),
        );
        try {
          _snapshot = boundary.toImageSync(pixelRatio: ratio);
        } catch (_) {
          // A not-yet-painted surface still gets the live fade/scale transition.
        }
      }
    }
    _animation.duration = _reduceMotion
        ? const Duration(milliseconds: 80)
        : Duration(milliseconds: widget.opening ? 320 : 280);
    _waitingForReturnLayout = !widget.opening && !_reduceMotion;
    if (_waitingForReturnLayout) {
      _animation.stop();
      _animation.value = 0;
      // Restore the parent's offset, then let its lazy tile finish layout.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _navigationGeneration) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || generation != _navigationGeneration) return;
          _waitingForReturnLayout = false;
          if (_tryReadOrigin() case final origin?) {
            _origin = origin;
            _hasOrigin = true;
          }
          if (!_tickerEnabled) {
            _finishTransition();
            return;
          }
          _animation.forward(from: 0);
        });
        WidgetsBinding.instance.scheduleFrame();
      });
      return;
    }
    _animation.forward(from: 0);
  }

  Rect? _tryReadOrigin() {
    try {
      return _readOrigin();
    } catch (_) {
      // A folder tile can detach while its parent collection is being laid out.
      // Falling back to the full-surface fade must still release input.
      return null;
    }
  }

  Rect? _readOrigin() {
    final boundary = _boundaryKey.currentContext?.findRenderObject();
    final origin = widget.originKey?.currentContext?.findRenderObject();
    if (boundary is! RenderBox ||
        origin is! RenderBox ||
        !boundary.hasSize ||
        !origin.hasSize ||
        boundary.size.isEmpty) {
      return null;
    }
    final position = boundary.globalToLocal(origin.localToGlobal(Offset.zero));
    final rect = (position & origin.size).intersect(
      Offset.zero & boundary.size,
    );
    if (rect.isEmpty) return null;
    return Rect.fromLTWH(
      rect.left / boundary.size.width,
      rect.top / boundary.size.height,
      rect.width / boundary.size.width,
      rect.height / boundary.size.height,
    );
  }

  void _animationChanged(AnimationStatus status) {
    if (_finishingTransition ||
        status != AnimationStatus.completed ||
        !mounted) {
      return;
    }
    setState(_releaseSnapshot);
  }

  void _finishTransition({bool invalidateCallbacks = true}) {
    if (invalidateCallbacks) _navigationGeneration++;
    _waitingForReturnLayout = false;
    _finishingTransition = true;
    try {
      _animation.stop();
      _animation.value = 1;
    } finally {
      _finishingTransition = false;
    }
    _releaseSnapshot();
  }

  void _releaseSnapshot() {
    final image = _snapshot;
    _snapshot = null;
    if (image != null) {
      // RawImage may still be referenced by the frame currently being replaced.
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  @override
  void dispose() {
    _navigationGeneration++;
    _animation.dispose();
    _snapshot?.dispose();
    _snapshot = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    child: RepaintBoundary(
      key: _boundaryKey,
      child: KeyedSubtree(
        key: const ValueKey('library-shelf-live'),
        child: widget.child,
      ),
    ),
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final viewport = Offset.zero & size;
        final origin = Rect.fromLTWH(
          _origin.left * size.width,
          _origin.top * size.height,
          _origin.width * size.width,
          _origin.height * size.height,
        );
        final t = _animation.value;
        final progress =
            (widget.opening ? Curves.easeOutCubic : Curves.easeInOutCubic)
                .transform(t);
        final image = _snapshot;
        final moving = isAnimating;
        final surface = _hasOrigin && !_reduceMotion
            ? Rect.lerp(
                widget.opening ? origin : viewport,
                widget.opening ? viewport : origin,
                progress,
              )!
            : viewport;
        final opacity = !moving
            ? 1.0
            : _reduceMotion || !_hasOrigin
            ? t
            : Interval(
                widget.opening ? 0.28 : 0,
                widget.opening ? 0.68 : 0.42,
                curve: Curves.easeOut,
              ).transform(t);
        final background = BoxDecoration(
          gradient: PageStyleHelper.backgroundGradient(context),
        );
        final scale = _reduceMotion || !_hasOrigin || !moving
            ? 1.0
            : widget.opening
            ? 0.94 + 0.06 * progress
            : 1.02 - 0.02 * progress;
        final radius = _hasOrigin && !_reduceMotion
            ? 16.0 * (widget.opening ? 1 - progress : progress)
            : 0.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (image != null && widget.opening && _hasOrigin)
              Positioned.fill(
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
            IgnorePointer(
              ignoring: moving,
              child: ExcludeSemantics(
                excluding: moving,
                child: ClipPath(
                  clipper: _ShelfSurfaceClipper(
                    moving && widget.opening && !_reduceMotion && _hasOrigin
                        ? surface
                        : viewport,
                    moving && widget.opening && !_reduceMotion ? radius : 0,
                  ),
                  child: DecoratedBox(
                    decoration: moving && widget.opening
                        ? background
                        : const BoxDecoration(),
                    child: Transform.scale(
                      key: const ValueKey('library-shelf-content-transform'),
                      scale: scale,
                      alignment: Alignment(
                        _origin.center.dx * 2 - 1,
                        _origin.center.dy * 2 - 1,
                      ),
                      child: Opacity(
                        key: const ValueKey('library-shelf-content-opacity'),
                        opacity: opacity,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (image != null)
              Positioned.fromRect(
                key: const ValueKey('library-shelf-snapshot'),
                rect: surface,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: Opacity(
                        opacity:
                            1 -
                            (_hasOrigin && !_reduceMotion
                                ? Interval(
                                    widget.opening ? 0.16 : 0.86,
                                    widget.opening ? 0.4 : 1,
                                    curve: Curves.easeOutCubic,
                                  ).transform(t)
                                : t),
                        child: widget.opening && _hasOrigin
                            ? CustomPaint(
                                painter: _FolderPreviewPainter(image, _origin),
                              )
                            : DecoratedBox(
                                decoration: background,
                                child: RawImage(image: image, fit: BoxFit.fill),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _ShelfSurfaceClipper extends CustomClipper<Path> {
  const _ShelfSurfaceClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  bool shouldReclip(_ShelfSurfaceClipper oldClipper) =>
      oldClipper.rect != rect || oldClipper.radius != radius;
}

class _FolderPreviewPainter extends CustomPainter {
  const _FolderPreviewPainter(this.image, this.origin);

  final ui.Image image;
  final Rect origin;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(
      origin.left * image.width,
      origin.top * image.height,
      origin.width * image.width,
      origin.height * image.height,
    ),
    Offset.zero & size,
    Paint()..filterQuality = FilterQuality.medium,
  );

  @override
  bool shouldRepaint(_FolderPreviewPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.origin != origin;
}
