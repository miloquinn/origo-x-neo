import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/widgets/elastic_pill_navigation_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_item.dart';

void main() {
  testWidgets(
    'drag follows continuously and commits one destination on release',
    (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(
        _testApp(selectedIndex: 0, onSelected: selected.add),
      );

      final bar = find.byType(ElasticPillNavigationBar);
      final barRect = tester.getRect(bar);
      final gesture = await tester.startGesture(
        Offset(barRect.left + 40, barRect.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(Offset(barRect.left + 150, barRect.center.dy));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 80));

      expect(selected, isEmpty);
      expect(_lensCenter(tester), inExclusiveRange(80, 200));

      await gesture.moveTo(Offset(barRect.left + 250, barRect.center.dy));
      await tester.pump(const Duration(milliseconds: 80));
      expect(selected, isEmpty);
      expect(_lensCenter(tester), greaterThan(150));

      await gesture.up();
      await tester.pump();
      expect(selected, [2]);
    },
  );

  testWidgets('cancel restores the externally selected destination', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _testApp(selectedIndex: 1, onSelected: selected.add),
    );
    final barRect = tester.getRect(find.byType(ElasticPillNavigationBar));
    final gesture = await tester.startGesture(
      Offset(barRect.center.dx, barRect.center.dy),
    );
    await gesture.moveTo(Offset(barRect.right - 20, barRect.center.dy));
    await tester.pump(const Duration(milliseconds: 80));
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(_lensCenter(tester), closeTo(150, 0.1));
  });

  testWidgets('external selection retargets the existing lens', (tester) async {
    await tester.pumpWidget(_testApp(selectedIndex: 0, onSelected: (_) {}));
    expect(_lensCenter(tester), closeTo(50, 0.1));

    await tester.pumpWidget(_testApp(selectedIndex: 2, onSelected: (_) {}));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_lensCenter(tester), inExclusiveRange(50, 250));
    await tester.pumpAndSettle();
    expect(_lensCenter(tester), closeTo(250, 0.1));
  });

  testWidgets('reduced motion moves the lens without transitional frames', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(selectedIndex: 0, onSelected: (_) {}, disableAnimations: true),
    );
    await tester.pumpWidget(
      _testApp(selectedIndex: 2, onSelected: (_) {}, disableAnimations: true),
    );

    expect(_lensCenter(tester), closeTo(250, 0.1));
  });

  testWidgets('RTL positions the first destination at the visual start', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        selectedIndex: 0,
        onSelected: (_) {},
        textDirection: TextDirection.rtl,
      ),
    );

    expect(_lensCenter(tester), closeTo(250, 0.1));
  });

  testWidgets(
    'real navigation buttons dispatch one callback for tap and drag',
    (tester) async {
      final selections = <int>[];
      await tester.pumpWidget(_realButtonApp(selections));

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(selections, [1]);

      final barRect = tester.getRect(find.byType(ElasticPillNavigationBar));
      final gesture = await tester.startGesture(
        Offset(barRect.left + 150, barRect.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveTo(Offset(barRect.right - 20, barRect.center.dy));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selections, [1, 2]);
    },
  );
}

double _lensCenter(WidgetTester tester) =>
    tester
        .getRect(find.byKey(const ValueKey('home-navigation-selection-lens')))
        .center
        .dx -
    tester.getRect(find.byType(ElasticPillNavigationBar)).left;

Widget _testApp({
  required int selectedIndex,
  required ValueChanged<int> onSelected,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    builder: (context, child) =>
        Directionality(textDirection: textDirection, child: child!),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            height: 56,
            child: ElasticPillNavigationBar(
              selectedIndex: selectedIndex,
              onSelected: onSelected,
              children: const [
                SizedBox.expand(),
                SizedBox.expand(),
                SizedBox.expand(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _realButtonApp(List<int> selections) {
  return MaterialApp(home: _RealButtonHarness(selections: selections));
}

class _RealButtonHarness extends StatefulWidget {
  const _RealButtonHarness({required this.selections});

  final List<int> selections;

  @override
  State<_RealButtonHarness> createState() => _RealButtonHarnessState();
}

class _RealButtonHarnessState extends State<_RealButtonHarness> {
  int selectedIndex = 0;

  void select(int index) {
    widget.selections.add(index);
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 56,
          child: ElasticPillNavigationBar(
            selectedIndex: selectedIndex,
            onSelected: select,
            children: [
              for (var index = 0; index < 3; index++)
                FloatingPillNavigationButton(
                  item: FloatingPillNavigationItem(
                    icon: Icons.circle_outlined,
                    selectedIcon: Icons.circle,
                    label: ['One', 'Two', 'Three'][index],
                  ),
                  isSelected: selectedIndex == index,
                  showLabel: true,
                  showSelectionIndicator: false,
                  onTap: () => select(index),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
