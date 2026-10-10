import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_adjustment_slider.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

void main() {
  setUp(() => GlassEffectConfig.setDisableAllGlassEffects(false));
  tearDown(() => GlassEffectConfig.setDisableAllGlassEffects(false));

  testWidgets('step buttons preview then commit once and disable at bounds', (
    tester,
  ) async {
    final events = <(String, double)>[];
    await tester.pumpWidget(_host(initialValue: 1, max: 2, events: events));

    await tester.tap(find.byTooltip('增大字号'));
    await tester.pump();
    expect(events, [('preview', 2), ('commit', 2)]);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 2);
    expect(
      tester.widget<GlassIconButton>(find.byKey(_increase)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(_increase));
    expect(events, hasLength(2));
    await tester.tap(find.byTooltip('减小字号'));
    await tester.pump();
    await tester.tap(find.byTooltip('减小字号'));
    await tester.pump();
    expect(events.last, ('commit', 0));
    expect(
      tester.widget<GlassIconButton>(find.byKey(_decrease)).onPressed,
      isNull,
    );
  });

  testWidgets('fractional saved values remain intact until a user adjusts', (
    tester,
  ) async {
    final events = <(String, double)>[];
    await tester.pumpWidget(
      _host(
        label: '行高',
        initialValue: 1.75,
        min: 1.2,
        max: 4,
        divisions: 28,
        events: events,
      ),
    );
    expect(events, isEmpty);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 1.75);
    await tester.tap(find.byTooltip('增大行高'));
    await tester.pump();
    expect(events, [('preview', 1.85), ('commit', 1.85)]);
    await tester.tap(find.byTooltip('减小行高'));
    await tester.pump();
    expect(events.last, ('commit', 1.75));
  });

  testWidgets('dragging previews continuously and commits only on release', (
    tester,
  ) async {
    final events = <(String, double)>[];
    await tester.pumpWidget(_host(initialValue: 2, events: events));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Slider)),
    );
    await gesture.moveBy(const Offset(28, 0));
    await tester.pump();
    expect(events.where((event) => event.$1 == 'preview'), isNotEmpty);
    expect(events.where((event) => event.$1 == 'commit'), isEmpty);
    await gesture.up();
    await tester.pump();
    expect(events.where((event) => event.$1 == 'commit'), hasLength(1));
    expect(events.last.$2, tester.widget<Slider>(find.byType(Slider)).value);
  });

  testWidgets('native keyboard adjustments still commit their value', (
    tester,
  ) async {
    final events = <(String, double)>[];
    await tester.pumpWidget(_host(initialValue: 2, events: events));
    tester
        .widget<FocusableActionDetector>(
          find.descendant(
            of: find.byType(Slider),
            matching: find.byType(FocusableActionDetector),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    final before = tester.widget<Slider>(find.byType(Slider)).value;
    events.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(events.map((event) => event.$1), ['preview', 'commit']);
    for (final event in events) {
      expect(event.$2, closeTo(before + 1, .000001));
    }
  });

  testWidgets('semantics name the setting and format neighbouring values', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(label: '字距', initialValue: .3, max: 6, divisions: 60),
      );
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(Slider),
            matching: find.bySemanticsLabel('字距'),
          ),
        ),
        matchesSemantics(
          label: '字距',
          value: '0.3',
          increasedValue: '0.4',
          decreasedValue: '0.2',
          isSlider: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          hasFocusAction: true,
        ),
      );
      expect(find.byTooltip('减小字距'), findsOneWidget);
      expect(find.byTooltip('增大字距'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'glass modes, large text and narrow layouts retain touch targets',
    (tester) async {
      for (final glass in GlassStyle.values) {
        for (final width in <double>[320, 375, 720]) {
          await tester.pumpWidget(
            _host(
              label: '首行缩进与段落间距',
              initialValue: 4,
              max: 8,
              glass: glass,
              width: width,
              textScale: 3.2,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byKey(_decrease)), const Size(48, 48));
          expect(tester.getSize(find.byKey(_increase)), const Size(48, 48));
          expect(tester.getSize(find.byType(Slider)).height, 48);
          if (glass == GlassStyle.liquid) {
            expect(find.byType(LiquidGlassSurface), findsWidgets);
          } else {
            expect(find.byType(BackdropFilter), findsWidgets);
          }
        }
      }
      await tester.pumpWidget(_host(style: AppUiStyle.material3));
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(LiquidGlassSurface), findsNothing);
      GlassEffectConfig.setDisableAllGlassEffects(true);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(LiquidGlassSurface), findsNothing);
    },
  );

  testWidgets('disabled adjustments expose no active input', (tester) async {
    await tester.pumpWidget(_host(enabled: false));
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(
      tester.widget<GlassIconButton>(find.byKey(_decrease)).onPressed,
      isNull,
    );
    expect(
      tester.widget<GlassIconButton>(find.byKey(_increase)).onPressed,
      isNull,
    );
  });
}

const _decrease = ValueKey('glass-adjustment-decrease');
const _increase = ValueKey('glass-adjustment-increase');

Widget _host({
  String label = '字号',
  double initialValue = 1,
  double min = 0,
  double max = 10,
  int? divisions,
  List<(String, double)>? events,
  GlassStyle glass = GlassStyle.frosted,
  AppUiStyle style = AppUiStyle.glass,
  double width = 375,
  double textScale = 1,
  bool enabled = true,
}) {
  var value = initialValue;
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      extensions: [UiStyleThemeExtension(style: style, glassStyle: glass)],
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: StatefulBuilder(
            builder: (context, setState) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: GlassAdjustmentSlider(
                label: label,
                value: value,
                valueLabel: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                min: min,
                max: max,
                divisions: divisions ?? (max - min).round(),
                onChanged: enabled
                    ? (next) {
                        events?.add(('preview', next));
                        setState(() => value = next);
                      }
                    : null,
                onChangeEnd: (next) => events?.add(('commit', next)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
