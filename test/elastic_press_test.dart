import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/elastic_press.dart';

void main() {
  const contentKey = Key('elastic-content');
  final painted = find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_PressPaint',
  );

  Future<void> pumpPress(WidgetTester tester, {bool reducedMotion = false}) =>
      tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: const Scaffold(
              body: Center(
                child: ElasticPress(
                  edgePullOnly: true,
                  child: ColoredBox(
                    key: contentKey,
                    color: Colors.transparent,
                    child: SizedBox(width: 300, height: 56),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a dock pulls only beyond an edge and cancellation resets it', (
    tester,
  ) async {
    await pumpPress(tester);
    final anchor = tester.getRect(painted);
    final contentAnchor = tester.getRect(find.byKey(contentKey));
    final dynamic paint = tester.renderObject(painted);
    final gesture = await tester.startGesture(anchor.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(paint.lift, greaterThan(0));
    expect(tester.getRect(painted), anchor);
    expect(tester.getRect(find.byKey(contentKey)), contentAnchor);
    await gesture.moveTo(anchor.center + const Offset(80, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(paint.pull, Offset.zero);
    await gesture.moveTo(Offset(anchor.right + 40, anchor.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect((paint.pull as Offset).dx, greaterThan(0));
    expect(tester.getRect(painted), anchor);
    expect(tester.getRect(find.byKey(contentKey)), contentAnchor);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(paint.pull, Offset.zero);
    expect(paint.lift, 0);
  });

  testWidgets('reduced motion suppresses press swell and edge pulling', (
    tester,
  ) async {
    await pumpPress(tester, reducedMotion: true);
    final anchor = tester.getRect(painted);
    final dynamic paint = tester.renderObject(painted);
    final gesture = await tester.startGesture(anchor.center);
    await gesture.moveTo(Offset(anchor.right + 40, anchor.center.dy));
    await tester.pump(const Duration(milliseconds: 180));
    expect(paint.lift, 0);
    expect(paint.pull, Offset.zero);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
