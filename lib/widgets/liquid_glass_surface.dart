import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../utils/glass_material.dart';
import 'liquid_glass_transform.dart';

/// Capability renderer used by GlassSurface. It paints a resolved material,
/// loads the refraction shader and retains the unsupported-backend blur.
/// All material policy and tuning belongs to GlassMaterial.
class LiquidGlassSurface extends StatefulWidget {
  const LiquidGlassSurface({
    super.key,
    required this.shape,
    required this.material,
    required this.child,
    this.filterBackground = true,
  });

  final OutlinedBorder shape;
  final GlassMaterial material;
  final Widget child;
  final bool filterBackground;

  /// Fades the tint, rim and refraction together without a backdrop saveLayer.
  double get visibility => material.visibility;

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
    if (widget.visibility == 0) return widget.child;
    final material = widget.material;
    final surface = CustomPaint(
      foregroundPainter: _LiquidRimPainter(
        shape: widget.shape,
        gradient: material.rimGradient,
        textDirection: Directionality.of(context),
        visibility: widget.visibility,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: widget.shape,
          gradient: material.liquidGradient,
        ),
        child: widget.child,
      ),
    );
    if (!widget.filterBackground) return surface;
    if (_shader == null || material.mode != GlassMaterialMode.liquid) {
      return BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: GlassMaterial.liquidFallbackSigma * widget.visibility,
          sigmaY: GlassMaterial.liquidFallbackSigma * widget.visibility,
        ),
        child: surface,
      );
    }
    return _LiquidBackdrop(
      shader: _shader!,
      shape: widget.shape,
      pixelRatio: MediaQuery.devicePixelRatioOf(context),
      strength: material.refractionStrength,
      visibility: widget.visibility,
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
    required this.visibility,
    required this.textDirection,
    required super.child,
  });

  final ui.FragmentShader shader;
  final OutlinedBorder shape;
  final double pixelRatio;
  final double strength;
  final double visibility;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLiquidBackdrop(
        shader,
        shape,
        pixelRatio,
        strength,
        visibility,
        textDirection,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderLiquidBackdrop render) {
    render
      ..shader = shader
      ..shape = shape
      ..pixelRatio = pixelRatio
      ..strength = strength
      ..visibility = visibility
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
    this.visibility,
    this.textDirection,
  );

  ui.FragmentShader shader;
  OutlinedBorder shape;
  double pixelRatio;
  double strength;
  double visibility;
  TextDirection textDirection;

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    layer ??= _LiquidBackdropLayer(this, offset);
    (layer! as _LiquidBackdropLayer).paintOffset = offset;
    context.pushLayer(layer!, super.paint, offset);
  }

  ui.ImageFilter _resolveFilter(Matrix4 localToScene) {
    final transform = invertLiquidGlassSceneTransform(localToScene, pixelRatio);
    if (transform == null) {
      return ui.ImageFilter.blur(
        sigmaX: GlassMaterial.liquidFallbackSigma * visibility,
        sigmaY: GlassMaterial.liquidFallbackSigma * visibility,
      );
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
      origin.dx,
      origin.dy,
      size.width * pixelRatio,
      size.height * pixelRatio,
      math.min(radius, size.shortestSide / 2) * pixelRatio,
      strength * pixelRatio * visibility,
      GlassMaterial.liquidSamplingSigma * pixelRatio * visibility,
      visibility,
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
  _LiquidBackdropLayer(this.render, this.paintOffset);

  final _RenderLiquidBackdrop render;
  Offset paintOffset;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder) {
    final localToScene = collectLiquidGlassLocalToSceneTransform(
      this,
      paintOffset,
    );
    engineLayer = builder.pushBackdropFilter(
      render._resolveFilter(localToScene),
      oldLayer: engineLayer as ui.BackdropFilterEngineLayer?,
    );
    addChildrenToScene(builder);
    builder.pop();
  }
}

class _LiquidRimPainter extends CustomPainter {
  const _LiquidRimPainter({
    required this.shape,
    required this.gradient,
    required this.textDirection,
    required this.visibility,
  });

  final OutlinedBorder shape;
  final LinearGradient gradient;
  final TextDirection textDirection;
  final double visibility;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(GlassMaterial.rimInset);
    if (bounds.isEmpty) return;
    final path = shape.getOuterPath(bounds, textDirection: textDirection);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GlassMaterial.rimWidth
      ..shader = gradient.createShader(bounds);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidRimPainter old) =>
      old.shape != shape ||
      old.gradient != gradient ||
      old.textDirection != textDirection ||
      old.visibility != visibility;
}
