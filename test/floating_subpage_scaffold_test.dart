import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/gradient_top_backdrop.dart';
import 'package:xxread/widgets/glass_buttons.dart';

void main() {
  testWidgets('parent rebuild does not rewrite unchanged system UI', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method.startsWith('SystemChrome.')) calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final rebuild = ValueNotifier(0);
    addTearDown(rebuild.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: rebuild,
          builder: (context, value, child) => FloatingSubpageScaffold(
            title: 'Preferences $value',
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pump();
    calls.clear();

    rebuild.value += 1;
    await tester.pump();

    expect(calls, isEmpty);
  });

  testWidgets('header reserves the measured width of text actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: FloatingSubpageScaffold(
          title: 'A long reader configuration title',
          actions: [
            GlassTextButton(
              onPressed: () {},
              minimumHeight: 48,
              blurBackground: false,
              child: const Text('Reset settings'),
            ),
          ],
          body: const SizedBox.shrink(),
        ),
      ),
    );
    final title = tester.getRect(
      find.text('A long reader configuration title'),
    );
    final action = tester.getRect(find.byType(GlassTextButton));
    final back = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-back')),
    );
    expect(action.width, greaterThan(48));
    expect(title.left, greaterThanOrEqualTo(back.right + 16));
    expect(title.right, lessThanOrEqualTo(action.left - 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('content extends behind the gesture area with safe scroll end', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FloatingSubpageScaffold(
            title: 'Stats',
            body: ListView(
              padding: floatingSubpagePadding(context, bottom: 20),
              children: const [SizedBox(height: 900, child: Text('Content'))],
            ),
          ),
        ),
      ),
    );

    expect(tester.getBottomLeft(find.byType(ListView)).dy, 800);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect((list.padding! as EdgeInsets).bottom, 44);
  });

  testWidgets('renders secondary navigation without a standard app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => FloatingSubpageScaffold(
                      title: 'Cache management',
                      actions: [
                        FloatingSubpageAction(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Refresh',
                          onPressed: () {},
                        ),
                      ],
                      tools: const Text('Page tools'),
                      body: const Text('Page body'),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(GradientTopBackdrop), findsOneWidget);
    expect(
      find.byKey(const ValueKey('floating-subpage-header')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('Cache management')).style?.fontSize,
      22,
    );
    // The shared gradient is the header's only background/filter owner.
    final headerSurface = find.byKey(const ValueKey('glass-top-bar-surface'));
    expect(tester.widget(headerSurface), isA<SizedBox>());
    expect(
      find.descendant(of: headerSurface, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('floating-subpage-back')), findsOneWidget);
    final backAction = find.descendant(
      of: find.byKey(const ValueKey('floating-subpage-back')),
      matching: find.byType(IconButton),
    );
    expect(
      tester.widget<IconButton>(backAction).style?.iconSize?.resolve({}),
      28,
    );
    expect(find.text('Cache management'), findsOneWidget);
    expect(find.text('Page tools'), findsOneWidget);
    expect(find.text('Page body'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    final backRect = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-back')),
    );
    final titleRect = tester.getRect(find.text('Cache management'));
    final screenCenter =
        tester.getSize(find.byType(FloatingSubpageScaffold)).width / 2;
    expect((titleRect.center.dx - screenCenter).abs(), lessThan(1));
    expect((titleRect.center.dy - backRect.center.dy).abs(), lessThan(1));
    final bodyRect = tester.getRect(find.text('Page body'));
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-header')),
    );
    final contentSurfaceRect = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-content-surface')),
    );
    expect(contentSurfaceRect.top, 0);
    expect(contentSurfaceRect.bottom, greaterThan(headerRect.bottom));
    expect(bodyRect.top, greaterThanOrEqualTo(headerRect.bottom));

    await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('can scroll page content behind the shared glass header', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FloatingSubpageScaffold(
            title: 'Account',
            body: ListView(
              padding: floatingSubpagePadding(
                context,
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
              ),
              children: const [SizedBox(height: 900, child: Text('Content'))],
            ),
          ),
        ),
      ),
    );

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-header')),
    );
    expect(tester.getTopLeft(find.text('Content')).dy, headerRect.bottom);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Content')).dy,
      lessThan(headerRect.bottom),
    );
    expect(find.byType(GradientTopBackdrop), findsOneWidget);
  });

  testWidgets('ellipsizes long titles between the header controls', (
    tester,
  ) async {
    const title = 'Dart QR encoder adaptation with an intentionally long name';
    await tester.pumpWidget(
      const MaterialApp(
        home: FloatingSubpageScaffold(title: title, body: SizedBox.shrink()),
      ),
    );

    final titleFinder = find.text(title);
    final titleWidget = tester.widget<Text>(titleFinder);
    final titleRect = tester.getRect(titleFinder);
    final backRect = tester.getRect(
      find.byKey(const ValueKey('floating-subpage-back')),
    );

    expect(titleWidget.maxLines, 1);
    expect(titleWidget.overflow, TextOverflow.ellipsis);
    expect(titleRect.left, greaterThanOrEqualTo(backRect.right + 8));
  });

  testWidgets('shared menu morphs from its anchor and returns selection', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: FloatingSubpageMenuButton<String>(
              key: const ValueKey('test-glass-menu'),
              icon: Icons.more_horiz_rounded,
              tooltip: 'More',
              items: const [
                FloatingSubpageMenuItem(value: 'import', child: Text('Import')),
              ],
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('test-glass-menu')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Import'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-menu-morph-surface')),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(selected, 'import');
  });
}
