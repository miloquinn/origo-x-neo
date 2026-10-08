import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/pill_search_field.dart';

void main() {
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
  });

  Future<void> host(
    WidgetTester tester,
    PillSearchField field, {
    double width = 320,
    double scale = 1,
    TextDirection direction = TextDirection.ltr,
    AppUiStyle style = AppUiStyle.glass,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [UiStyleThemeExtension(style: style)]),
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: direction,
                child: SizedBox(width: width, child: field),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('native editing, keyboard submit and default clear notify once', (
    tester,
  ) async {
    final changes = <String>[];
    final submissions = <String>[];
    await host(
      tester,
      PillSearchField(
        textFieldKey: const ValueKey('query'),
        hintText: 'Search',
        onChanged: changes.add,
        onSubmitted: submissions.add,
      ),
    );
    final field = find.byKey(const ValueKey('query'));
    expect(
      tester.widget<TextField>(field).textInputAction,
      TextInputAction.search,
    );
    await tester.enterText(field, 'chapter');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(changes, ['chapter']);
    expect(submissions, ['chapter']);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(changes, ['chapter', '']);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('programmatic edits update clear without dispatching a query', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final changes = <String>[];
    await host(
      tester,
      PillSearchField(
        controller: controller,
        hintText: 'Search',
        onChanged: changes.add,
      ),
    );
    controller.text = 'restored';
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    controller.clear();
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(changes, isEmpty);
  });

  testWidgets('custom clear owns reset, listener side effects and refocus', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'query');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var resets = 0;
    var changes = 0;
    var edits = 0;
    controller.addListener(() => edits++);
    await host(
      tester,
      PillSearchField(
        controller: controller,
        focusNode: focus,
        hintText: 'Search',
        onChanged: (_) => changes++,
        onClear: () {
          resets++;
          controller.clear();
          focus.requestFocus();
        },
      ),
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(resets, 1);
    expect(edits, 1);
    expect(changes, 0);
    expect(controller.text, isEmpty);
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('replacing and removing borrowed nodes never disposes them', (
    tester,
  ) async {
    final first = TextEditingController(text: 'first');
    final second = TextEditingController(text: 'second');
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    await host(
      tester,
      PillSearchField(
        controller: first,
        focusNode: firstFocus,
        hintText: 'Search',
      ),
    );
    await host(
      tester,
      PillSearchField(
        controller: second,
        focusNode: secondFocus,
        hintText: 'Search',
      ),
    );
    first.text = 'still owned';
    firstFocus.requestFocus();
    await tester.pump();
    expect(find.text('second'), findsOneWidget);
    await host(tester, const PillSearchField(hintText: 'Search'));
    expect(find.text('second'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    second.text = 'still usable';
    secondFocus.requestFocus();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'narrow RTL and large type preserve editing and 44px clear target',
    (tester) async {
      final controller = TextEditingController(text: '关键词');
      addTearDown(controller.dispose);
      await host(
        tester,
        PillSearchField(
          controller: controller,
          hintText: '搜索',
          trailing: const Text('12/128'),
        ),
        width: 260,
        scale: 2,
        direction: TextDirection.rtl,
      );
      expect(
        tester.getSize(find.byType(PillSearchField)).height,
        greaterThan(52),
      );
      final clear = find.byType(IconButton);
      expect(tester.getSize(clear).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(clear).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      await tester.tap(clear);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(find.text('12/128'), findsOneWidget);
    },
  );

  testWidgets('disabled fields retain their query and cannot clear or submit', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'locked');
    addTearDown(controller.dispose);
    var clears = 0;
    await host(
      tester,
      PillSearchField(
        controller: controller,
        hintText: 'Search',
        enabled: false,
        onClear: () => clears++,
      ),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    await tester.pump();
    expect(controller.text, 'locked');
    expect(clears, 0);
  });

  testWidgets(
    'editing and palette overrides work across glass and solid modes',
    (tester) async {
      for (final glass in GlassStyle.values) {
        GlassEffectConfig.setGlassStyle(glass);
        for (final style in AppUiStyle.values) {
          await host(
            tester,
            PillSearchField(
              key: ValueKey('$glass-$style'),
              hintText: 'Reader',
              fillColor: Colors.black,
              foregroundColor: Colors.white,
              hintColor: Colors.white70,
              accentColor: Colors.amber,
              brightness: Brightness.dark,
              showClearButton: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('12/128', key: ValueKey('counter')),
                  IconButton(
                    key: const ValueKey('retry'),
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            style: style,
          );
          await tester.enterText(find.byType(TextField), 'reader query');
          await tester.pump();
          final field = tester.widget<TextField>(find.byType(TextField));
          expect(field.style?.color, Colors.white);
          expect(field.cursorColor, Colors.amber);
          expect(find.text('reader query'), findsOneWidget);
          final counter = tester.renderObject<RenderParagraph>(
            find.byKey(const ValueKey('counter')),
          );
          expect(counter.text.style?.color, Colors.white70);
          final retryIcon = find.descendant(
            of: find.byKey(const ValueKey('retry')),
            matching: find.byType(Icon),
          );
          expect(IconTheme.of(tester.element(retryIcon)).color, Colors.white70);
          expect(tester.takeException(), isNull);
        }
      }
      GlassEffectConfig.setDisableAllGlassEffects(true);
      await host(tester, const PillSearchField(hintText: 'Search'));
      await tester.enterText(find.byType(TextField), 'solid query');
      expect(find.text('solid query'), findsOneWidget);
    },
  );
}
