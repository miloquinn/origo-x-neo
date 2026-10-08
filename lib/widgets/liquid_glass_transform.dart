import 'package:flutter/rendering.dart';

/// Collects the transform actually used to composite [layer] into the scene.
///
/// Unlike a render-tree transform, this includes paint-only transforms such as
/// the one used by `ElasticPress`, while [paintOffset] locates the render box
/// within the layer's own coordinate space.
Matrix4 collectLiquidGlassLocalToSceneTransform(
  Layer layer,
  Offset paintOffset,
) {
  final chain = <Layer>[layer];
  for (
    var ancestor = layer.parent;
    ancestor != null;
    ancestor = ancestor.parent
  ) {
    chain.add(ancestor);
  }

  final transform = Matrix4.identity();
  for (var index = chain.length - 1; index > 0; index--) {
    final parent = chain[index] as ContainerLayer;
    parent.applyTransform(chain[index - 1], transform);
  }
  transform.translateByDouble(paintOffset.dx, paintOffset.dy, 0, 1);
  return transform;
}

/// Maps physical scene coordinates into physical pixels local to the glass.
///
/// Flutter's root layer already contributes the device-pixel-ratio scale. The
/// inverse therefore produces logical local coordinates; the leading scale
/// restores physical units for the shader's extent, radius and displacement.
Matrix4? invertLiquidGlassSceneTransform(
  Matrix4 localToScene,
  double pixelRatio,
) {
  final sceneToLogicalLocal = Matrix4.copy(localToScene);
  final determinant = sceneToLogicalLocal.invert();
  if (!determinant.isFinite || determinant.abs() < 0.000001) return null;
  return Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1)
    ..multiply(sceneToLogicalLocal);
}
