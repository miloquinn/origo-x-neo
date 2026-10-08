import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/liquid_glass_transform.dart';

void main() {
  test('collects root, affine, offset and paint transforms in scene order', () {
    const pixelRatio = 3.0;
    const paintOffset = Offset(12, 7);
    final root = TransformLayer(
      transform: Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1),
    );
    final affine = Matrix4.identity()
      ..translateByDouble(40, 24, 0, 1)
      ..rotateZ(math.pi / 12)
      ..scaleByDouble(1.18, 0.86, 1, 1);
    final motion = TransformLayer(transform: affine);
    final offset = OffsetLayer(offset: const Offset(5, 9));
    final glass = ContainerLayer();
    root.append(motion);
    motion.append(offset);
    offset.append(glass);

    final actual = collectLiquidGlassLocalToSceneTransform(glass, paintOffset);
    final expected = Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1)
      ..multiply(affine)
      ..translateByDouble(5, 9, 0, 1)
      ..translateByDouble(paintOffset.dx, paintOffset.dy, 0, 1);

    for (var index = 0; index < 16; index++) {
      expect(actual.storage[index], closeTo(expected.storage[index], 0.000001));
    }
  });

  test('inverse maps scene pixels to physical local shader coordinates', () {
    const pixelRatio = 2.5;
    final localToScene = Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1)
      ..translateByDouble(30, 18, 0, 1)
      ..rotateZ(-0.2)
      ..scaleByDouble(1.12, 0.94, 1, 1);
    final sceneToLocal = invertLiquidGlassSceneTransform(
      localToScene,
      pixelRatio,
    )!;
    const localPoint = Offset(17, 11);
    final scenePoint = MatrixUtils.transformPoint(localToScene, localPoint);

    final recovered = MatrixUtils.transformPoint(sceneToLocal, scenePoint);
    expect(recovered.dx, closeTo(localPoint.dx * pixelRatio, 0.000001));
    expect(recovered.dy, closeTo(localPoint.dy * pixelRatio, 0.000001));
    final origin = MatrixUtils.transformPoint(sceneToLocal, Offset.zero);
    final basisX =
        MatrixUtils.transformPoint(sceneToLocal, const Offset(1, 0)) - origin;
    final basisY =
        MatrixUtils.transformPoint(sceneToLocal, const Offset(0, 1)) - origin;
    expect(basisX.distance, greaterThan(0));
    expect(basisY.distance, greaterThan(0));
  });

  test('device scale applies equally to shader basis and origin', () {
    const pixelRatio = 3.0;
    final localToScene = Matrix4.diagonal3Values(pixelRatio, pixelRatio, 1)
      ..translateByDouble(10, 20, 0, 1);
    final sceneToLocal = invertLiquidGlassSceneTransform(
      localToScene,
      pixelRatio,
    )!;
    final origin = MatrixUtils.transformPoint(sceneToLocal, Offset.zero);
    final basisX =
        MatrixUtils.transformPoint(sceneToLocal, const Offset(1, 0)) - origin;
    final basisY =
        MatrixUtils.transformPoint(sceneToLocal, const Offset(0, 1)) - origin;

    expect(origin.dx, closeTo(-30, 0.000001));
    expect(origin.dy, closeTo(-60, 0.000001));
    expect(basisX.dx, closeTo(1, 0.000001));
    expect(basisX.dy, closeTo(0, 0.000001));
    expect(basisY.dx, closeTo(0, 0.000001));
    expect(basisY.dy, closeTo(1, 0.000001));
  });

  test('rejects a degenerate scene transform', () {
    final singular = Matrix4.diagonal3Values(0, 1, 1);
    expect(invertLiquidGlassSceneTransform(singular, 3), isNull);
  });
}
