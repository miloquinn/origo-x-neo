import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../utils/glass_config.dart';

/// A live refracting backdrop with a lightly tinted, readable foreground.
/// Callers own clipping and shadows; content is painted after the filter.
class LiquidGlassSurface extends StatefulWidget {
  const LiquidGlassSurface({
    super.key,
    required this.shape,
    required this.color,
    required this.child,
    this.brightness,
    this.filterBackground = true,
  });

  final OutlinedBorder shape;
  final Color color;
  final Widget child;
  final Brightness? brightness;
  final bool filterBackground;

  @override
  State<LiquidGlassSurface> createState() => _LiquidGlassSurfaceState();
}

class _LiquidGlassSurfaceState extends State<LiquidGlassSurface> {
  static Future<ui.FragmentProgram>? _program;
  ui.FragmentShader? _shader;
  ui.Image? _seed;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.filterBackground && widget.filterBackground) _loadShader();
  }

  Future<void> _loadShader() async {
    if (!widget.filterBackground ||
        !ui.ImageFilter.isShaderFilterSupported ||
        _loading ||
        _shader != null) {
      return;
    }
    _loading = true;
    try {
      final program = await (_program ??= ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      ));
      if (!mounted) return;
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.transparent, BlendMode.src);
      final picture = recorder.endRecording();
      final ui.Image seed;
      try {
        seed = await picture.toImage(1, 1);
      } finally {
        picture.dispose();
      }
      if (!mounted) {
        seed.dispose();
        return;
      }
      final shader = program.fragmentShader()
        ..setImageSampler(0, seed, filterQuality: FilterQuality.low);
      setState(() {
        _seed = seed;
        _shader = shader;
      });
    } catch (error) {
      // Keep the lightweight blur and edge lighting on unsupported assets.
      debugPrint('Liquid glass shader unavailable: $error');
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _shader?.dispose();
    _seed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness ?? Theme.of(context).brightness;
    final highContrast = MediaQuery.highContrastOf(context);
    final light = brightness == Brightness.light;
    final surface = CustomPaint(
      foregroundPainter: _LiquidRimPainter(
        shape: widget.shape,
        light: light,
        textDirection: Directionality.of(context),
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: widget.shape,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                widget.color,
                Colors.white,
                light ? 0.35 : 0.12,
              )!.withValues(alpha: highContrast ? 0.94 : (light ? 0.32 : 0.26)),
              widget.color.withValues(alpha: highContrast ? 0.94 : 0.18),
            ],
          ),
        ),
        child: widget.child,
      ),
    );
    if (!widget.filterBackground) return surface;
    if (_shader == null || highContrast) {
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: surface,
      );
    }
    return _LiquidBackdrop(
      shader: _shader!,
      shape: widget.shape,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      strength: GlassEffectConfig.liquidRefractionStrength,
      textDirection: Directionality.of(context),
      child: surface,
    );
  }
}

class _LiquidBackdrop extends SingleChildRenderObjectWidget {
  const _LiquidBackdrop({
    required this.shader,
    required this.shape,
    required this.pixelRatio,
    required this.strength,
    required this.textDirection,
    required super.child,
  });

  final ui.FragmentShader shader;
  final OutlinedBorder shape;
  final double pixelRatio;
  final double strength;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLiquidBackdrop(shader, shape, pixelRatio, strength, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderLiquidBackdrop render) {
    render
      ..shader = shader
      ..shape = shape
      ..pixelRatio = pixelRatio
      ..strength = strength
      ..textDirection = textDirection
      ..markNeedsPaint();
  }
}

class _RenderLiquidBackdrop extends RenderProxyBox {
  _RenderLiquidBackdrop(
    this.shader,
    this.shape,
    this.pixelRatio,
    this.strength,
    this.textDirection,
  );

  ui.FragmentShader shader;
  OutlinedBorder shape;
  double pixelRatio;
  double strength;
  TextDirection textDirection;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    layer ??= _LiquidBackdropLayer(this);
    context.pushLayer(layer!, super.paint, offset);
  }

  ui.ImageFilter _resolveFilter() {
    final transform = getTransformTo(null);
    final determinant = transform.invert();
    if (!determinant.isFinite || determinant.abs() < 0.000001) {
      return ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5);
    }
    final origin = MatrixUtils.transformPoint(transform, Offset.zero);
    final x =
        MatrixUtils.transformPoint(transform, const Offset(1, 0)) - origin;
    final y =
        MatrixUtils.transformPoint(transform, const Offset(0, 1)) - origin;
    final radius = switch (shape) {
      RoundedRectangleBorder(:final borderRadius) =>
        borderRadius.resolve(textDirection).topLeft.x,
      RoundedSuperellipseBorder(:final borderRadius) =>
        borderRadius.resolve(textDirection).topLeft.x,
      CircleBorder() || StadiumBorder() => size.shortestSide / 2,
      _ => 0.0,
    };
    final values = [
      x.dx,
      y.dx,
      x.dy,
      y.dy,
      origin.dx * pixelRatio,
      origin.dy * pixelRatio,
      size.width * pixelRatio,
      size.height * pixelRatio,
      math.min(radius, size.shortestSide / 2) * pixelRatio,
      strength * pixelRatio,
      0.75 * pixelRatio,
    ];
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i + 2, values[i]);
    }
    // Recreate the filter after changing uniforms: native filters snapshot them.
    return ui.ImageFilter.shader(shader);
  }
}

/// Transform animations and scrolling can reuse a clean RepaintBoundary.
/// Refresh uniforms when the scene is composed, even without child painting.
class _LiquidBackdropLayer extends ContainerLayer {
  _LiquidBackdropLayer(this.render);

  final _RenderLiquidBackdrop render;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    engineLayer = builder.pushBackdropFilter(
      render._resolveFilter(),
      oldLayer: engineLayer as ui.BackdropFilterEngineLayer?,
    );
    addChildrenToScene(builder);
    builder.pop();
  }
}

class _LiquidRimPainter extends CustomPainter {
  const _LiquidRimPainter({
    required this.shape,
    required this.light,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final bool light;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(0.75);
    if (bounds.isEmpty) return;
    final path = shape.getOuterPath(bounds, textDirection: textDirection);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: light ? 0.88 : 0.60),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: light ? 0.06 : 0.03),
          Colors.white.withValues(alpha: light ? 0.58 : 0.36),
        ],
        stops: const [0, 0.42, 0.65, 1],
      ).createShader(bounds);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidRimPainter old) =>
      old.shape != shape ||
      old.light != light ||
      old.textDirection != textDirection;
}
