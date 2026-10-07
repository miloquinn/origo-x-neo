import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/elastic_motion.dart';

void main() {
  testWidgets('a continuously moving target retains spring momentum', (
    tester,
  ) async {
    final motion = ElasticSpring(tester, 0);
    addTearDown(motion.dispose);
    final spring = SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 120),
    );
    motion.animateTo(1, spring);
    await tester.pump();
    var previous = motion.value;
    for (var frame = 0; frame < 10; frame++) {
      motion.animateTo(1 + frame * 0.1, spring);
      await tester.pump(const Duration(milliseconds: 16));
      expect(motion.value, greaterThan(previous));
      previous = motion.value;
    }
    await tester.pumpAndSettle();
    expect(motion.value, 1.9);
    expect(motion.velocity, 0);
  });

  test('spring curves land exactly at their endpoints after overshooting', () {
    final curve = ElasticSpringCurve(
      duration: const Duration(milliseconds: 750),
      settlingDuration: const Duration(milliseconds: 500),
      bounce: 0.3,
    );
    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);
    expect([
      for (var frame = 1; frame < 100; frame++) curve.transform(frame / 100),
    ], contains(greaterThan(1)));
  });
}
