import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_press.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_selection_toolbar.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setLiquidGlassOpacity(0.6);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  testWidgets(
    'floating navigation keeps geometry and hit behavior across materials',
    (tester) async {
      for (final mode in _modes) {
        var taps = 0;
        await _pump(
          tester,
          mode: mode,
          child: Center(
            child: FloatingPillNavigationSurface(
              width: 240,
              height: 56,
              child: GestureDetector(
                key: const ValueKey('navigation-hit-target'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps += 1,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );

        expect(
          tester.getSize(find.byType(FloatingPillNavigationSurface)),
          const Size(240, 56),
          reason: mode.name,
        );
        await tester.tap(find.byKey(const ValueKey('navigation-hit-target')));
        await tester.pump();
        expect(taps, 1, reason: mode.name);
      }
    },
  );

  testWidgets('reader chrome owns one glass bar with plain embedded actions', (
    tester,
  ) async {
    await _pump(
      tester,
      child: Center(
        child: ReaderControlBar(
          palette: ReaderThemes.day,
          isTopBar: true,
          child: ReaderControlIconButton(
            palette: ReaderThemes.day,
            tooltip: 'Back',
            icon: Icons.arrow_back_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ReaderControlBar),
        matching: find.byType(GlassSurface),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(ReaderControlIconButton),
        matching: find.byType(GlassControlSurface),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ReaderControlBar),
        matching: find.byType(ElasticPress),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(IconButton)), const Size.square(44));
  });

  testWidgets('reader selection keeps its rounded geometry across materials', (
    tester,
  ) async {
    Size? expectedSize;
    for (final mode in _modes) {
      await _pump(
        tester,
        mode: mode,
        child: ReaderSelectionToolbar(
          palette: ReaderThemes.day,
          anchors: const TextSelectionToolbarAnchors(
            primaryAnchor: Offset(200, 150),
            secondaryAnchor: Offset(200, 170),
          ),
          onCopy: () {},
          onHighlight: () {},
          onNote: () {},
        ),
      );

      final toolbar = find.byKey(const ValueKey('reader-selection-toolbar'));
      final size = tester.getSize(toolbar);
      expectedSize ??= size;
      expect(size, expectedSize, reason: mode.name);
      final surface = tester.widget<GlassControlSurface>(
        find.byType(GlassControlSurface),
      );
      expect(surface.shape, isA<RoundedSuperellipseBorder>());
      expect(surface.color, ReaderThemes.day.controlBar);
      expect(surface.brightness, ReaderThemes.day.brightness);
    }
  });

  testWidgets('pill input keeps its hit target across materials', (
    tester,
  ) async {
    Size? expectedSize;
    for (final mode in _modes) {
      var taps = 0;
      await _pump(
        tester,
        mode: mode,
        child: Center(
          child: SizedBox(
            width: 260,
            child: PillInputSurface(
              child: SizedBox(
                width: 260,
                height: 52,
                child: GestureDetector(
                  key: const ValueKey('input-hit-target'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps += 1,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(PillInputSurface));
      expectedSize ??= size;
      expect(size, expectedSize, reason: mode.name);
      await tester.tap(find.byKey(const ValueKey('input-hit-target')));
      await tester.pump();
      expect(taps, 1, reason: mode.name);
    }
  });

  testWidgets('frosted shared consumers each own one background sample', (
    tester,
  ) async {
    for (final child in <Widget>[
      const Center(
        child: FloatingPillNavigationSurface(
          width: 240,
          height: 56,
          child: SizedBox.expand(),
        ),
      ),
      Center(
        child: ReaderControlBar(
          palette: ReaderThemes.day,
          isTopBar: false,
          child: const SizedBox(width: 240, height: 52),
        ),
      ),
      const Center(
        child: SizedBox(
          width: 260,
          child: PillInputSurface(child: SizedBox(height: 52)),
        ),
      ),
    ]) {
      await _pump(tester, child: child);
      expect(find.byType(BackdropFilter), findsOneWidget);
    }
  });

  testWidgets('effects-off and Material 3 avoid glass renderers', (
    tester,
  ) async {
    for (final mode in const [
      _Mode('effects-off', disabled: true),
      _Mode('material-3', uiStyle: AppUiStyle.material3),
    ]) {
      await _pump(
        tester,
        mode: mode,
        child: const Center(
          child: SizedBox(
            width: 260,
            child: PillInputSurface(child: SizedBox(height: 52)),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing, reason: mode.name);
      expect(find.byType(LiquidGlassSurface), findsNothing, reason: mode.name);
    }
  });

  testWidgets(
    '[future contract] theme liquid overrides stale global frosted style',
    (tester) async {
      GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
      await _pump(
        tester,
        mode: const _Mode('theme-liquid', glassStyle: GlassStyle.liquid),
        child: const Center(
          child: SizedBox(
            width: 120,
            height: 48,
            child: GlassControlSurface(child: SizedBox.expand()),
          ),
        ),
      );

      expect(find.byType(LiquidGlassSurface), findsOneWidget);
    },
  );

  testWidgets(
    '[future contract] theme frosted overrides stale global liquid style',
    (tester) async {
      GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
      await _pump(
        tester,
        mode: const _Mode('theme-frosted'),
        child: const Center(
          child: SizedBox(
            width: 120,
            height: 48,
            child: GlassControlSurface(child: SizedBox.expand()),
          ),
        ),
      );

      expect(find.byType(LiquidGlassSurface), findsNothing);
      expect(find.byType(BackdropFilter), findsOneWidget);
    },
  );

  testWidgets('absent theme extension falls back to the global glass style', (
    tester,
  ) async {
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              height: 48,
              child: GlassSurface(child: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LiquidGlassSurface), findsOneWidget);
  });

  testWidgets('high contrast forces the shared surface to solid material', (
    tester,
  ) async {
    await _pump(
      tester,
      mode: const _Mode(
        'high-contrast-liquid',
        glassStyle: GlassStyle.liquid,
        highContrast: true,
      ),
      child: const Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassSurface(child: SizedBox.expand()),
        ),
      ),
    );

    expect(find.byType(LiquidGlassSurface), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('shared surface adds no layout inset around its child', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassSurface(
            child: SizedBox(
              key: ValueKey('layout-neutral-child'),
              width: 120,
              height: 48,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('layout-neutral-child'))),
      const Size(120, 48),
    );
  });

  testWidgets('zero visibility removes material without changing child hits', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      mode: const _Mode('liquid', glassStyle: GlassStyle.liquid),
      child: Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassSurface(
            visibility: 0,
            child: GestureDetector(
              key: const ValueKey('zero-visibility-hit-target'),
              behavior: HitTestBehavior.opaque,
              onTap: () => taps += 1,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(LiquidGlassSurface), findsNothing);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('zero-visibility-hit-target'))),
      const Size(120, 48),
    );
    await tester.tap(find.byKey(const ValueKey('zero-visibility-hit-target')));
    expect(taps, 1);
  });

  testWidgets('partial visibility does not wrap the moving filter in opacity', (
    tester,
  ) async {
    await _pump(
      tester,
      mode: const _Mode('liquid', glassStyle: GlassStyle.liquid),
      child: const Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassSurface(visibility: 0.5, child: SizedBox.expand()),
        ),
      ),
    );

    expect(find.byType(LiquidGlassSurface), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(LiquidGlassSurface),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('filterBackground false avoids a second background sample', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const Center(
        child: SizedBox(
          width: 120,
          height: 48,
          child: GlassSurface(
            filterBackground: false,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  test('normal consumers do not bypass the shared glass background', () {
    const allowlist = {
      'lib/widgets/first_home_support_overlay.dart',
      'lib/widgets/glass_surface.dart',
      'lib/widgets/gradient_top_backdrop.dart',
      'lib/widgets/liquid_glass_surface.dart',
    };
    final bypasses = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      final source = entity.readAsStringSync();
      if ((source.contains('BackdropFilter(') ||
              source.contains('LiquidGlassSurface(')) &&
          !allowlist.contains(path)) {
        bypasses.add(path);
      }
    }

    expect(bypasses, isEmpty);
  });
}

const _modes = [
  _Mode('frosted'),
  _Mode('liquid', glassStyle: GlassStyle.liquid),
  _Mode('effects-off', disabled: true),
];

class _Mode {
  const _Mode(
    this.name, {
    this.glassStyle = GlassStyle.frosted,
    this.disabled = false,
    this.uiStyle = AppUiStyle.glass,
    this.highContrast = false,
  });

  final String name;
  final GlassStyle glassStyle;
  final bool disabled;
  final AppUiStyle uiStyle;
  final bool highContrast;
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  _Mode mode = const _Mode('frosted'),
}) async {
  GlassEffectConfig.setGlassStyle(mode.glassStyle);
  GlassEffectConfig.setDisableAllGlassEffects(mode.disabled);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: [
          UiStyleThemeExtension(
            style: mode.uiStyle,
            glassStyle: mode.glassStyle,
            liquidGlassOpacity: 0.6,
          ),
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          highContrast: mode.highContrast,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}
