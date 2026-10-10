import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/pill_dropdown.dart';

void main() {
  const triggerKey = ValueKey('pill-dropdown');
  const panelKey = ValueKey('app-menu-adaptive-surface');

  setUp(() {
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setDisableAllGlassEffects(false);
  });
  tearDown(() {
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setDisableAllGlassEffects(false);
  });

  Future<void> pumpDropdown(
    WidgetTester tester, {
    String? value = 'one',
    ValueChanged<String?>? onChanged,
    List<DropdownMenuItem<String>>? items,
    DropdownButtonBuilder? selectedItemBuilder,
    AppUiStyle style = AppUiStyle.glass,
    GlassStyle glassStyle = GlassStyle.frosted,
    bool highContrast = false,
    double textScale = 1,
    double width = 280,
    Size screenSize = const Size(390, 844),
    EdgeInsets padding = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            UiStyleThemeExtension(style: style, glassStyle: glassStyle),
          ],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            highContrast: highContrast,
            padding: padding,
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: PillDropdown<String>(
                key: triggerKey,
                semanticLabel: 'Protocol',
                value: value,
                items:
                    items ??
                    const [
                      DropdownMenuItem(value: 'one', child: Text('One')),
                      DropdownMenuItem(value: 'two', child: Text('Two')),
                    ],
                selectedItemBuilder: selectedItemBuilder,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('opens an anchor-width shared menu and selects an item', (
    tester,
  ) async {
    String? selected;
    await pumpDropdown(tester, onChanged: (value) => selected = value);

    expect(find.byType(DropdownButton<String>), findsNothing);
    final triggerRect = tester.getRect(find.byKey(triggerKey));
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();

    final panel = find.byKey(panelKey);
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).width, closeTo(triggerRect.width, .01));
    expect(tester.getTopLeft(panel).dy, greaterThan(triggerRect.bottom));
    expect(
      find.descendant(of: panel, matching: find.byIcon(Icons.check_rounded)),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: panel, matching: find.text('Two')));
    await tester.pumpAndSettle();
    expect(selected, 'two');
    expect(panel, findsNothing);
  });

  testWidgets('announces both the field label and selected value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDropdown(tester, onChanged: (_) {});
      final data = tester
          .getSemantics(find.byKey(triggerKey))
          .getSemanticsData();
      expect(data.label, contains('Protocol'));
      expect(data.label, contains('One'));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('uses selectedItemBuilder only for the collapsed display', (
    tester,
  ) async {
    await pumpDropdown(
      tester,
      onChanged: (_) {},
      selectedItemBuilder: (_) => const [
        Text('Selected one'),
        Text('Selected two'),
      ],
    );

    expect(find.text('Selected one'), findsOneWidget);
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byKey(panelKey), matching: find.text('One')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(8, 700));
    await tester.pumpAndSettle();
  });

  testWidgets('disabled trigger and entries preserve semantics and callbacks', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpDropdown(tester);
      final data = tester
          .getSemantics(find.byKey(triggerKey))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isFalse);
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      expect(find.byKey(panelKey), findsNothing);

      String? selected;
      await pumpDropdown(
        tester,
        onChanged: (value) => selected = value,
        items: const [
          DropdownMenuItem(value: 'one', child: Text('One')),
          DropdownMenuItem(value: 'two', enabled: false, child: Text('Two')),
        ],
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byKey(panelKey), matching: find.text('Two')),
      );
      await tester.pump();
      expect(selected, isNull);
      expect(find.byKey(panelKey), findsOneWidget);
      await tester.tapAt(const Offset(8, 700));
      await tester.pumpAndSettle();
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keyboard starts at the visible selected item', (tester) async {
    String? selected;
    await pumpDropdown(
      tester,
      screenSize: const Size(320, 300),
      width: 260,
      textScale: 2,
      onChanged: (value) => selected = value,
      items: [
        for (var index = 0; index < 12; index++)
          DropdownMenuItem(value: 'item-$index', child: Text('Item $index')),
      ],
      value: 'item-8',
    );
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();

    final panel = find.byKey(panelKey);
    expect(
      find.descendant(of: panel, matching: find.byType(Scrollable)),
      findsOneWidget,
    );
    expect(tester.getRect(panel).bottom, lessThanOrEqualTo(288));
    final selectedItem = find.descendant(
      of: panel,
      matching: find.text('Item 8'),
    );
    final panelRect = tester.getRect(panel);
    final selectedRect = tester.getRect(selectedItem);
    expect(selectedRect.top, greaterThanOrEqualTo(panelRect.top));
    expect(selectedRect.bottom, lessThanOrEqualTo(panelRect.bottom));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 'item-8');

    selected = null;
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 'item-9');
  });

  testWidgets('keyboard inset bounds the panel and keeps later items usable', (
    tester,
  ) async {
    String? selected;
    await pumpDropdown(
      tester,
      screenSize: const Size(320, 568),
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      viewInsets: const EdgeInsets.only(bottom: 140),
      width: 260,
      onChanged: (value) => selected = value,
      items: [
        for (var index = 0; index < 12; index++)
          DropdownMenuItem(value: 'item-$index', child: Text('Item $index')),
      ],
      value: 'item-0',
    );
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();

    final panel = find.byKey(panelKey);
    expect(tester.getRect(panel).top, greaterThanOrEqualTo(36));
    expect(tester.getRect(panel).bottom, lessThanOrEqualTo(416));
    final lastItem = find.descendant(of: panel, matching: find.text('Item 11'));
    await tester.ensureVisible(lastItem);
    await tester.pumpAndSettle();
    await tester.tap(lastItem);
    await tester.pumpAndSettle();
    expect(selected, 'item-11');
  });

  testWidgets('outside tap dismisses once and rapid taps keep one route', (
    tester,
  ) async {
    var changes = 0;
    await pumpDropdown(tester, onChanged: (_) => changes++);
    final anchor = tester.getCenter(find.byKey(triggerKey));
    await tester.tapAt(anchor);
    await tester.tapAt(anchor);
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsOneWidget);

    await tester.tapAt(const Offset(8, 700));
    await tester.pumpAndSettle();
    expect(find.byKey(panelKey), findsNothing);
    expect(changes, 0);
  });

  testWidgets('does not notify a dropdown disposed while its menu is open', (
    tester,
  ) async {
    var changes = 0;

    Widget host({required bool showDropdown}) => MaterialApp(
      home: Scaffold(
        body: showDropdown
            ? SizedBox(
                width: 280,
                child: PillDropdown<String>(
                  key: triggerKey,
                  semanticLabel: 'Protocol',
                  value: 'one',
                  items: const [
                    DropdownMenuItem(value: 'one', child: Text('One')),
                    DropdownMenuItem(value: 'two', child: Text('Two')),
                  ],
                  onChanged: (_) => changes++,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );

    await tester.pumpWidget(host(showDropdown: true));
    await tester.tap(find.byKey(triggerKey));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(showDropdown: false));
    await tester.tap(
      find.descendant(of: find.byKey(panelKey), matching: find.text('Two')),
    );
    await tester.pumpAndSettle();
    expect(changes, 0);
  });

  testWidgets('panel follows frosted liquid and solid accessibility modes', (
    tester,
  ) async {
    for (final mode in [
      (
        style: AppUiStyle.glass,
        glass: GlassStyle.frosted,
        disabled: false,
        highContrast: false,
        expectBlur: true,
        expectLiquid: false,
      ),
      (
        style: AppUiStyle.glass,
        glass: GlassStyle.liquid,
        disabled: false,
        highContrast: false,
        expectBlur: null,
        expectLiquid: true,
      ),
      (
        style: AppUiStyle.glass,
        glass: GlassStyle.frosted,
        disabled: true,
        highContrast: false,
        expectBlur: false,
        expectLiquid: false,
      ),
      (
        style: AppUiStyle.material3,
        glass: GlassStyle.frosted,
        disabled: false,
        highContrast: false,
        expectBlur: false,
        expectLiquid: false,
      ),
      (
        style: AppUiStyle.glass,
        glass: GlassStyle.frosted,
        disabled: false,
        highContrast: true,
        expectBlur: false,
        expectLiquid: false,
      ),
    ]) {
      GlassEffectConfig.setDisableAllGlassEffects(mode.disabled);
      await pumpDropdown(
        tester,
        style: mode.style,
        glassStyle: mode.glass,
        highContrast: mode.highContrast,
        onChanged: (_) {},
      );
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();
      final panel = find.byKey(panelKey);
      if (mode.expectBlur case final expectBlur?) {
        expect(
          find.descendant(of: panel, matching: find.byType(BackdropFilter)),
          expectBlur ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.descendant(of: panel, matching: find.byType(LiquidGlassSurface)),
        mode.expectLiquid ? findsOneWidget : findsNothing,
      );
      await tester.tapAt(const Offset(8, 700));
      await tester.pumpAndSettle();
    }
  });
}
