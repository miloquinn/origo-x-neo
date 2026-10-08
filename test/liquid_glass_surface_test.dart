import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
  });
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
  });

  testWidgets('unsupported shader backend keeps a lightweight blur fallback', (
    tester,
  ) async {
    expect(ui.ImageFilter.isShaderFilterSupported, isFalse);
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);

    await tester.pumpWidget(_surfaceHost(filterBackground: true));
    await tester.pump();

    expect(find.byType(LiquidGlassSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'filterBackground false paints the liquid surface without filter',
    (tester) async {
      GlassEffectConfig.setGlassStyle(GlassStyle.liquid);

      await tester.pumpWidget(_surfaceHost(filterBackground: false));

      expect(find.byType(LiquidGlassSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('visibility scales tint and zero keeps only the laid out child', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surfaceHost(filterBackground: true, visibility: 0.5),
    );

    final liquid = find.byType(LiquidGlassSurface);
    final child = find.byKey(const ValueKey('liquid-surface-child'));
    final visibleSize = tester.getSize(child);
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: liquid,
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as ShapeDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors.first.a, closeTo(0.16, 0.001));
    expect(gradient.colors.last.a, closeTo(0.09, 0.001));
    expect(find.byType(BackdropFilter), findsOneWidget);

    await tester.pumpWidget(
      _surfaceHost(filterBackground: true, visibility: 0),
    );

    expect(tester.getSize(child), visibleSize);
    expect(
      find.descendant(of: liquid, matching: find.byType(BackdropFilter)),
      findsNothing,
    );
    expect(
      find.descendant(of: liquid, matching: find.byType(CustomPaint)),
      findsNothing,
    );
    expect(
      find.descendant(of: liquid, matching: find.byType(DecoratedBox)),
      findsNothing,
    );
  });

  testWidgets('disabled glass switches shared controls to a solid surface', (
    tester,
  ) async {
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    GlassEffectConfig.setDisableAllGlassEffects(true);

    await tester.pumpWidget(_controlHost());

    expect(find.byType(LiquidGlassSurface), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as ShapeDecoration;
    expect(decoration.color, isNotNull);
  });

  testWidgets('mode changes preserve shared surface size and hit targets', (
    tester,
  ) async {
    await tester.pumpWidget(const _InteractiveHarness());

    final initialNavigation = tester.getSize(
      find.byKey(const ValueKey('navigation-hit-target')),
    );
    final initialControl = tester.getSize(
      find.byKey(const ValueKey('control-hit-target')),
    );
    await _tapSharedSurfaces(tester, expectedHits: 2);

    for (final mode in ['liquid', 'off', 'frosted']) {
      await tester.tap(find.byKey(ValueKey('mode-$mode')));
      await tester.pump();

      expect(
        tester.getSize(find.byKey(const ValueKey('navigation-hit-target'))),
        initialNavigation,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('control-hit-target'))),
        initialControl,
      );
      await _tapSharedSurfaces(
        tester,
        expectedHits: 2 + (['liquid', 'off', 'frosted'].indexOf(mode) + 1) * 2,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapSharedSurfaces(
  WidgetTester tester, {
  required int expectedHits,
}) async {
  await tester.tap(find.byKey(const ValueKey('navigation-hit-target')));
  await tester.tap(find.byKey(const ValueKey('control-hit-target')));
  await tester.pump();
  expect(find.text('hits:$expectedHits'), findsOneWidget);
}

Widget _surfaceHost({required bool filterBackground, double visibility = 1}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 160,
          height: 64,
          child: LiquidGlassSurface(
            shape: const StadiumBorder(),
            color: Colors.indigo,
            filterBackground: filterBackground,
            visibility: visibility,
            child: const Center(
              key: ValueKey('liquid-surface-child'),
              child: Text('Liquid'),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _controlHost() {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [
        UiStyleThemeExtension(
          style: AppUiStyle.glass,
          glassStyle: GlassStyle.liquid,
        ),
      ],
    ),
    home: const Scaffold(
      body: Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassControlSurface(child: Center(child: Text('Control'))),
        ),
      ),
    ),
  );
}

class _InteractiveHarness extends StatefulWidget {
  const _InteractiveHarness();

  @override
  State<_InteractiveHarness> createState() => _InteractiveHarnessState();
}

class _InteractiveHarnessState extends State<_InteractiveHarness> {
  GlassStyle _style = GlassStyle.frosted;
  bool _disabled = false;
  int _hits = 0;

  void _setMode(String mode) {
    setState(() {
      _disabled = mode == 'off';
      _style = mode == 'liquid' ? GlassStyle.liquid : GlassStyle.frosted;
      GlassEffectConfig.setGlassStyle(_style);
      GlassEffectConfig.setDisableAllGlassEffects(_disabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [
          UiStyleThemeExtension(
            style: _disabled ? AppUiStyle.material3 : AppUiStyle.glass,
            glassStyle: _style,
          ),
        ],
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('hits:$_hits'),
              for (final mode in ['frosted', 'liquid', 'off'])
                TextButton(
                  key: ValueKey('mode-$mode'),
                  onPressed: () => _setMode(mode),
                  child: Text(mode),
                ),
              FloatingPillNavigationSurface(
                width: 260,
                height: 64,
                child: GestureDetector(
                  key: const ValueKey('navigation-hit-target'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _hits++),
                  child: const Center(child: Text('Navigation')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 132,
                height: 48,
                child: GlassControlSurface(
                  child: GestureDetector(
                    key: const ValueKey('control-hit-target'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _hits++),
                    child: const Center(child: Text('Control')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
