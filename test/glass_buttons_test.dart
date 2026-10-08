import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_press.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/glass_buttons.dart';
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

  Future<void> host(
    WidgetTester tester,
    Widget child, {
    GlassStyle glassStyle = GlassStyle.frosted,
    AppUiStyle style = AppUiStyle.glass,
    bool reducedMotion = false,
    double textScale = 1,
  }) async {
    GlassEffectConfig.setGlassStyle(glassStyle);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            UiStyleThemeExtension(
              style: style,
              glassStyle: glassStyle,
              liquidGlassOpacity: 0.6,
            ),
          ],
        ),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reducedMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('back and toolbar roles retain distinct stable hit targets', (
    tester,
  ) async {
    await host(
      tester,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingSubpageAction(
            icon: Icons.arrow_back,
            iconSize: 28,
            tooltip: 'Back',
            onPressed: () {},
          ),
          GlassToolbarButton(
            icon: Icons.search,
            tooltip: 'Search',
            onPressed: () {},
          ),
        ],
      ),
    );
    expect(
      tester.getSize(find.byType(FloatingSubpageAction)),
      const Size.square(48),
    );
    expect(
      tester.getSize(find.byType(GlassToolbarButton)),
      const Size.square(44),
    );
    final target = find.byType(GlassToolbarButton);
    final anchor = tester.getRect(target);
    final native = find.descendant(
      of: target,
      matching: find.byType(IconButton),
    );
    final nativeAnchor = tester.getRect(native);
    final paintFinder = find.descendant(
      of: target,
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_PressPaint',
      ),
    );
    final dynamic paint = tester.renderObject(paintFinder);
    final gesture = await tester.startGesture(anchor.center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(paint.lift, greaterThan(0));
    await gesture.moveBy(const Offset(12, 6));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect((paint.pull as Offset).distance, greaterThan(0));
    expect(tester.getRect(target), anchor);
    expect(tester.getRect(native), nativeAnchor);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(paint.lift, 0);
    expect(paint.pull, Offset.zero);
  });

  testWidgets(
    'the full 44 and 48 pixel controls remain interactive in every material',
    (tester) async {
      for (final glassStyle in GlassStyle.values) {
        for (final style in AppUiStyle.values) {
          var taps = 0;
          await host(
            tester,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingSubpageAction(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onPressed: () => taps++,
                ),
                GlassToolbarButton(icon: Icons.search, onPressed: () => taps++),
              ],
            ),
            glassStyle: glassStyle,
            style: style,
          );
          for (final role in [
            find.byType(FloatingSubpageAction),
            find.byType(GlassToolbarButton),
          ]) {
            final native = find.descendant(
              of: role,
              matching: find.byType(IconButton),
            );
            expect(tester.getSize(native), tester.getSize(role));
            final icon = find.descendant(
              of: native,
              matching: find.byType(Icon),
            );
            expect(tester.getCenter(icon), tester.getCenter(role));
            await tester.tapAt(
              tester.getRect(role).centerLeft + const Offset(0.5, 0),
            );
            await tester.pumpAndSettle();
          }
          expect(taps, 2);
        }
      }
    },
  );

  testWidgets(
    'tap, keyboard activation and cancellation preserve native interaction',
    (tester) async {
      var taps = 0;
      await host(
        tester,
        GlassToolbarButton(
          icon: Icons.search,
          tooltip: 'Search',
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassToolbarButton)),
      );
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disabled controls neither activate nor start a spring', (
    tester,
  ) async {
    await host(
      tester,
      const GlassToolbarButton(
        icon: Icons.search,
        tooltip: 'Search',
        onPressed: null,
      ),
    );
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<ElasticPress>(find.byType(ElasticPress)).enabled,
      isFalse,
    );
    await tester.tap(find.byType(GlassToolbarButton));
    await tester.pumpAndSettle();
    final dynamic paint = tester.renderObject(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PressPaint'),
    );
    expect(paint.lift, 0);
  });

  testWidgets('reduced motion keeps activation but suppresses shape motion', (
    tester,
  ) async {
    var taps = 0;
    await host(
      tester,
      GlassToolbarButton(icon: Icons.search, onPressed: () => taps++),
      reducedMotion: true,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GlassToolbarButton)),
    );
    await tester.pump(const Duration(milliseconds: 220));
    final dynamic paint = tester.renderObject(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PressPaint'),
    );
    expect(paint.lift, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('both materials and solid style preserve highlight and palette', (
    tester,
  ) async {
    for (final glassStyle in GlassStyle.values) {
      await host(
        tester,
        GlassToolbarButton(
          icon: Icons.filter_alt,
          highlighted: true,
          blurBackground: false,
          onPressed: () {},
        ),
        glassStyle: glassStyle,
      );
      final context = tester.element(find.byType(GlassToolbarButton));
      final surface = tester.widget<GlassControlSurface>(
        find.byType(GlassControlSurface),
      );
      expect(surface.color, Theme.of(context).colorScheme.primaryContainer);
      expect(surface.emphasized, isTrue);
      expect(find.byType(BackdropFilter), findsNothing);
      if (glassStyle == GlassStyle.liquid) {
        expect(find.byType(LiquidGlassSurface), findsOneWidget);
      }
    }
    await host(
      tester,
      GlassToolbarButton(icon: Icons.search, onPressed: () {}),
      style: AppUiStyle.material3,
    );
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassSurface), findsNothing);
    GlassEffectConfig.setDisableAllGlassEffects(true);
    await tester.pumpWidget(const SizedBox.shrink());
    await host(
      tester,
      GlassToolbarButton(icon: Icons.search, onPressed: () {}),
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('text capsules grow with text scaling and activate once', (
    tester,
  ) async {
    var taps = 0;
    await host(
      tester,
      GlassTextButton(onPressed: () => taps++, child: const Text('Save')),
      textScale: 2,
    );
    expect(
      tester.getSize(find.byType(GlassTextButton)).height,
      greaterThanOrEqualTo(44),
    );
    expect(tester.getSize(find.byType(GlassTextButton)).width, greaterThan(44));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
