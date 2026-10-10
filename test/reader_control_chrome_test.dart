import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_leaf_status.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_press.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setLiquidGlassOpacity(0);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
  });

  testWidgets('frosted reader chrome follows the global glass effect switch', (
    tester,
  ) async {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    await tester.pumpWidget(_testApp(glassEnabled: true));

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(_panelGradient(tester).colors.every((color) => color.a < 1), isTrue);
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byType(GlassControlSurface), findsNothing);

    GlassEffectConfig.setDisableAllGlassEffects(true);
    await tester.pumpWidget(_testApp(glassEnabled: false));

    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      _panelGradient(tester).colors.every((color) => color.a == 1),
      isTrue,
    );
    expect(
      _panelGradient(tester).colors,
      everyElement(ReaderThemes.day.controlBar),
    );
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byType(GlassControlSurface), findsNothing);
  });

  testWidgets(
    'embedded reader actions are plain 44px controls in one spring bar',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReaderControlBar(
              palette: ReaderThemes.day,
              isTopBar: true,
              child: ReaderControlIconButton(
                palette: ReaderThemes.day,
                onPressed: () => taps += 1,
                tooltip: 'Back',
                icon: Icons.arrow_back_rounded,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsNothing);
      expect(find.byType(GlassControlSurface), findsNothing);
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byType(ElasticPress), findsOneWidget);
      expect(
        tester.getSize(find.byType(ReaderControlIconButton)),
        const Size.square(44),
      );
      expect(tester.getSize(find.byType(IconButton)), const Size.square(44));

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      expect(taps, 1);
    },
  );

  testWidgets('press and resisted drag paint the whole bar then return', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_interactionApp(onPressed: () => taps += 1));
    final bar = find.byType(ReaderControlBar);
    final painted = find.descendant(
      of: bar,
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_PressPaint',
      ),
    );
    final dynamic paint = tester.renderObject(painted);
    expect(
      find.descendant(of: painted, matching: find.byType(GlassSurface)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: painted, matching: find.byType(IconButton)),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.arrow_back_rounded)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(paint.lift, greaterThan(0));

    await gesture.moveBy(const Offset(400, 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final pull = paint.pull as Offset;
    expect(pull.dx, greaterThan(0));
    expect(pull.dx, lessThan(13));
    expect(pull.dy, greaterThan(0));
    expect(pull.dy, lessThan(13));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(paint.lift, 0);
    expect(paint.pull, Offset.zero);
  });

  testWidgets(
    'short taps fire once and disabled actions retain tooltip target',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(_interactionApp(onPressed: () => taps += 1));
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.pumpWidget(_interactionApp(onPressed: null));
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
      expect(button.tooltip, 'Back');
      expect(
        tester.getSize(find.byType(ReaderControlIconButton)),
        const Size.square(44),
      );
    },
  );

  testWidgets('reduced motion keeps the whole bar paint transform at rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      _interactionApp(onPressed: () {}, reducedMotion: true),
    );
    final painted = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_PressPaint',
    );
    final dynamic paint = tester.renderObject(painted);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.arrow_back_rounded)),
    );
    await gesture.moveBy(const Offset(300, 80));
    await tester.pump(const Duration(milliseconds: 180));
    expect(paint.lift, 0);
    expect(paint.pull, Offset.zero);
    await gesture.up();
  });

  testWidgets('frosted reader border ignores a divergent outer app palette', (
    tester,
  ) async {
    final palette = ReaderThemes.pureBlack;
    for (final glassEnabled in [true, false]) {
      GlassEffectConfig.setDisableAllGlassEffects(!glassEnabled);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
            ).copyWith(outlineVariant: Colors.pink),
          ),
          home: Scaffold(
            body: Center(
              child: ReaderControlIconButton(
                palette: palette,
                onPressed: () {},
                tooltip: 'Back',
                icon: Icons.arrow_back,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final decoration =
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration
              as ShapeDecoration;
      final surface = tester.widget<GlassControlSurface>(
        find.byType(GlassControlSurface),
      );
      expect(surface.outlineColor, palette.border);
      final actualBorder = (decoration.shape as OutlinedBorder).side;
      expect(actualBorder.color, isNot(Colors.pink));
      expect(actualBorder.color.a, greaterThan(0));
      expect(actualBorder.width, 1);
      expect(tester.getSize(find.byType(IconButton)), const Size.square(44));
      expect(
        tester.getCenter(find.byType(Icon)),
        tester.getCenter(find.byType(ReaderControlIconButton)),
      );
    }
  });

  testWidgets('moving frosted control bars keep glass outside opacity layers', (
    tester,
  ) async {
    final visible = ValueNotifier(false);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, shown, _) => ReaderChromeOverlay(
              palette: ReaderThemes.day,
              visible: shown,
              title: 'Chapter',
              statusBottom: 8,
              statusBuilder: (context, style, key) =>
                  Text('1 / 2', key: key, style: style),
              onBack: () {},
              onBookmark: () {},
              onTableOfContents: () {},
              onSettings: () {},
              backTooltip: 'Back',
              bookmarkTooltip: 'Bookmark',
              tableOfContentsTooltip: 'Contents',
              settingsTooltip: 'Settings',
              bookmarked: false,
            ),
          ),
        ),
      ),
    );
    final bars = find.byType(ReaderControlBar);
    final hiddenTop = tester.getTopLeft(bars.first).dy;
    visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(bars.first).dy, greaterThan(hiddenTop));
    void expectGlass() {
      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(
        find.ancestor(of: bars, matching: find.byType(AnimatedOpacity)),
        findsNothing,
      );
      for (final fade in tester.widgetList<FadeTransition>(
        find.ancestor(of: bars, matching: find.byType(FadeTransition)),
      )) {
        expect(fade.opacity.value, 1);
      }
    }

    expectGlass();
    await tester.pump(const Duration(milliseconds: 220));
    final restingTop = tester.getTopLeft(bars.first).dy;
    visible.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(bars.first).dy, lessThan(restingTop));
    expectGlass();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(bars.first).dy, hiddenTop);
  });

  testWidgets('hidden reader bars exclude input and semantics', (tester) async {
    var backTaps = 0;
    const topKey = ValueKey('hidden-reader-top-bar');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChromeOverlay(
            palette: ReaderThemes.day,
            visible: false,
            title: 'Chapter',
            statusBottom: 8,
            statusBuilder: (context, style, key) =>
                Text('1 / 2', key: key, style: style),
            onBack: () => backTaps += 1,
            onBookmark: () {},
            onTableOfContents: () {},
            onSettings: () {},
            backTooltip: 'Back',
            bookmarkTooltip: 'Bookmark',
            tableOfContentsTooltip: 'Contents',
            settingsTooltip: 'Settings',
            bookmarked: false,
            topKey: topKey,
          ),
        ),
      ),
    );

    final top = find.byKey(topKey);
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(of: top, matching: find.byType(IgnorePointer))
                .first,
          )
          .ignoring,
      isTrue,
    );
    expect(
      tester
          .widget<ExcludeSemantics>(
            find
                .descendant(of: top, matching: find.byType(ExcludeSemantics))
                .first,
          )
          .excluding,
      isTrue,
    );
    await tester.tap(
      find.descendant(of: top, matching: find.byIcon(Icons.arrow_back_rounded)),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(backTaps, 0);
  });

  testWidgets('reader-owned top information shows time title and battery', (
    tester,
  ) async {
    final status = ReaderLeafStatusData(
      time: DateTime(2026, 7, 18, 9, 5),
      battery: const ReaderBatteryStatus(level: 73, charging: false),
      revision: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: Scaffold(
            body: ReaderChromeOverlay(
              palette: ReaderThemes.day,
              visible: false,
              title: 'Chapter 4',
              statusBottom: 8,
              statusBuilder: (context, style, key) =>
                  Text('4 / 12', key: key, style: style),
              onBack: () {},
              onBookmark: () {},
              onTableOfContents: () {},
              onSettings: () {},
              backTooltip: 'Back',
              bookmarkTooltip: 'Bookmark',
              tableOfContentsTooltip: 'Contents',
              settingsTooltip: 'Settings',
              bookmarked: false,
              showViewportStatus: false,
              showViewportTitle: true,
              viewportTitleTop: 24,
              viewportTitleKey: const ValueKey('reader-top-information'),
              readerStatus: status,
            ),
          ),
        ),
      ),
    );

    expect(find.text('09:05'), findsOneWidget);
    expect(find.text('Chapter 4'), findsNWidgets(2));
    expect(find.text('73%'), findsOneWidget);
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('reader-top-information')),
          )
          .opacity,
      1,
    );
  });

  testWidgets('frosted reader chrome preserves the reading theme color', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(glassEnabled: true, palette: ReaderThemes.green),
    );

    final greenSurface = _panelGradient(tester).colors.last;
    final expectedGreen = Color.lerp(
      ReaderThemes.green.controlBar,
      Colors.white,
      0.18,
    )!;
    expect(greenSurface.r, closeTo(expectedGreen.r, 0.001));
    expect(greenSurface.g, closeTo(expectedGreen.g, 0.001));
    expect(greenSurface.b, closeTo(expectedGreen.b, 0.001));

    await tester.pumpWidget(
      _testApp(glassEnabled: true, palette: ReaderThemes.rose),
    );

    final roseSurface = _panelGradient(tester).colors.last;
    expect(roseSurface.r, greaterThan(greenSurface.r));
    expect(roseSurface.g, lessThan(greenSurface.g));
  });

  testWidgets('bottom control bar only shows reader actions', (tester) async {
    const bottomKey = ValueKey('reader-bottom-controls');
    const statusKey = ValueKey('reader-status');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChromeOverlay(
            palette: ReaderThemes.day,
            visible: true,
            title: 'Chapter 4',
            statusBottom: 8,
            statusBuilder: (context, style, key) =>
                Text('4 / 12', key: key, style: style),
            onBack: () {},
            onBookmark: () {},
            onTableOfContents: () {},
            onSearch: () {},
            onReadAloud: () {},
            onAskAi: () {},
            onSettings: () {},
            backTooltip: 'Back',
            bookmarkTooltip: 'Bookmark',
            tableOfContentsTooltip: 'Contents',
            searchTooltip: 'Full-text search',
            readAloudTooltip: 'Read aloud',
            askAiTooltip: 'Ask AI',
            settingsTooltip: 'Settings',
            bookmarked: false,
            bottomKey: bottomKey,
            statusKey: statusKey,
            showViewportStatus: false,
          ),
        ),
      ),
    );

    final bottomControls = find.byKey(bottomKey);
    expect(
      find.descendant(of: bottomControls, matching: find.text('4 / 12')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: bottomControls,
        matching: find.byIcon(Icons.format_list_bulleted_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bottomControls,
        matching: find.byIcon(Icons.headphones_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bottomControls,
        matching: find.byIcon(Icons.search_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bottomControls,
        matching: find.byIcon(Icons.tune_rounded),
      ),
      findsOneWidget,
    );
    expect(find.byKey(statusKey), findsOneWidget);
  });
}

Widget _testApp({
  required bool glassEnabled,
  ReaderThemePalette palette = ReaderThemes.day,
}) {
  return MaterialApp(
    theme: palette.toThemeData(),
    home: Scaffold(
      body: Center(
        child: ReaderControlBar(
          key: ValueKey(glassEnabled),
          palette: palette,
          isTopBar: true,
          child: SizedBox(
            width: 240,
            height: 58,
            child: ReaderControlIconButton(
              palette: palette,
              onPressed: null,
              tooltip: 'Bookmark',
              icon: Icons.bookmark_border_rounded,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _interactionApp({
  required VoidCallback? onPressed,
  bool reducedMotion = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: Scaffold(
      body: Center(
        child: ReaderControlBar(
          palette: ReaderThemes.day,
          isTopBar: true,
          child: SizedBox(
            width: 240,
            height: 58,
            child: Row(
              children: [
                ReaderControlIconButton(
                  palette: ReaderThemes.day,
                  onPressed: onPressed,
                  tooltip: 'Back',
                  icon: Icons.arrow_back_rounded,
                ),
                const Expanded(child: Text('Chapter')),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

LinearGradient _panelGradient(WidgetTester tester) {
  final surface = find
      .descendant(
        of: find.byType(ReaderControlBar),
        matching: find.byType(GlassSurface),
      )
      .first;
  final decoration =
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: surface,
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as ShapeDecoration;
  return decoration.gradient as LinearGradient? ??
      LinearGradient(colors: [decoration.color!, decoration.color!]);
}
