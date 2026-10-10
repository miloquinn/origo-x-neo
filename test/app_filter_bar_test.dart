import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/app_filter_bar.dart';
import 'package:xxread/widgets/app_selection_pill.dart';
import 'package:xxread/widgets/glass_surface.dart';

void main() {
  tearDown(() => GlassEffectConfig.setDisableAllGlassEffects(false));

  testWidgets('filter rail samples glass once and exposes selected semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var value = -1;
    await tester.pumpWidget(_host(onSelected: (next) => value = next));
    await tester.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsOneWidget);
    final selection = tester
        .widgetList<GlassSurface>(find.byType(GlassSurface))
        .singleWhere(
          (surface) =>
              surface.role == GlassSurfaceRole.selection &&
              surface.visibility > 0,
        );
    expect(selection.filterBackground, isFalse);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('option-0'))),
      matchesSemantics(
        label: 'Filter 0',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('option-1')));
    expect(value, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'solid, disabled effects and high contrast keep layout and taps',
    (tester) async {
      Size? glassSize;
      for (final variant in [
        (style: AppUiStyle.glass, off: false, highContrast: false),
        (style: AppUiStyle.material3, off: false, highContrast: false),
        (style: AppUiStyle.glass, off: true, highContrast: false),
        (style: AppUiStyle.glass, off: false, highContrast: true),
      ]) {
        GlassEffectConfig.setDisableAllGlassEffects(variant.off);
        var value = -1;
        await tester.pumpWidget(
          _host(
            style: variant.style,
            highContrast: variant.highContrast,
            onSelected: (next) => value = next,
          ),
        );
        await tester.pumpAndSettle();
        final size = tester.getSize(find.byType(AppFilterBar<int>));
        glassSize ??= size;
        expect(size, glassSize);
        expect(
          find.byType(BackdropFilter),
          variant.off ||
                  variant.highContrast ||
                  variant.style == AppUiStyle.material3
              ? findsNothing
              : findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('option-1')));
        expect(value, 1);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'large text determines height and all labels can scroll into view',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(width: 280, textScale: 2.5));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AppFilterBar<int>)).height,
        greaterThan(52),
      );
      await tester.dragUntilVisible(
        find.byKey(const ValueKey('option-5')),
        find.byType(SingleChildScrollView),
        const Offset(-220, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('option-5')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('external selection reveals only the horizontal rail', (
    tester,
  ) async {
    final vertical = ScrollController();
    addTearDown(vertical.dispose);
    Widget page(int selected) =>
        _host(selected: selected, width: 280, verticalController: vertical);
    await tester.pumpWidget(page(0));
    await tester.pumpAndSettle();
    vertical.jumpTo(100);
    await tester.pump();
    await tester.pumpWidget(page(5));
    await tester.pumpAndSettle();
    expect(vertical.offset, 100);
    expect(
      find.byKey(const ValueKey('option-5')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard and trailing group actions remain independent', (
    tester,
  ) async {
    var selected = -1;
    var groups = 0;
    await tester.pumpWidget(
      _host(
        width: 800,
        count: 2,
        onSelected: (value) => selected = value,
        trailing: AppSelectionPill(
          label: 'Groups',
          selected: false,
          enableSurface: false,
          onPressed: () => groups++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 0);
    await tester.tap(find.text('Groups'));
    expect(groups, 1);
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting a new option retains focus for keyboard use', (
    tester,
  ) async {
    var selected = 0;
    var activations = 0;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, update) {
          return _host(
            width: 800,
            selected: selected,
            onSelected: (value) => update(() {
              selected = value;
              activations++;
            }),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    final focusBefore = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(FocusManager.instance.primaryFocus, same(focusBefore));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(activations, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard traversal reveals filters before activation', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      _host(width: 280, onSelected: (value) => selected = value),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(
      find.byKey(const ValueKey('option-5')).hitTestable(),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'disabled filters cannot activate and dynamic options keep order',
    (tester) async {
      await tester.pumpWidget(_host(enabled: false));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppSelectionPill>(find.byKey(const ValueKey('option-1')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(_host(count: 2, selected: 1));
      await tester.pumpAndSettle();
      expect(find.byType(AppSelectionPill), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Filter 0')).dx,
        lessThan(tester.getTopLeft(find.text('Filter 1')).dx),
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _host({
  int selected = 0,
  int count = 6,
  double width = 500,
  double textScale = 1,
  bool highContrast = false,
  bool enabled = true,
  AppUiStyle style = AppUiStyle.glass,
  ValueChanged<int>? onSelected,
  Widget? trailing,
  ScrollController? verticalController,
}) {
  final bar = SizedBox(
    width: width,
    child: AppFilterBar<int>(
      selected: selected,
      onSelected: enabled ? onSelected ?? (_) {} : null,
      options: [
        for (var i = 0; i < count; i++)
          AppFilterOption(
            value: i,
            label: 'Filter $i',
            key: ValueKey('option-$i'),
          ),
      ],
      trailing: trailing,
    ),
  );
  return MaterialApp(
    theme: ThemeData(
      extensions: [
        UiStyleThemeExtension(style: style, glassStyle: GlassStyle.frosted),
      ],
    ),
    home: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        highContrast: highContrast,
      ),
      child: Scaffold(
        body: verticalController == null
            ? Center(child: bar)
            : ListView(
                controller: verticalController,
                children: [
                  const SizedBox(height: 160),
                  bar,
                  const SizedBox(height: 1000),
                ],
              ),
      ),
    ),
  );
}
