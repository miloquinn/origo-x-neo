import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_layout.dart';
import 'package:xxread/core/reader/reader_system_ui.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/reader_settings_controls.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(true);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  testWidgets(
    'reading settings scrolls to the rounded edge and keeps the last control safe',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      var taps = 0;

      await tester.pumpWidget(
        _host(
          child: ReaderSettingsSheetFrame(
            palette: ReaderThemes.day,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Reading settings'),
                for (var index = 0; index < 12; index++)
                  SizedBox(height: 56, child: Text('Setting $index')),
                FilledButton(
                  key: const ValueKey('reader-settings-final-control'),
                  onPressed: () => taps += 1,
                  child: const Text('Final setting'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(GlassSurface));
      final scrollView = find.byType(SingleChildScrollView);
      final scrollable = find.descendant(
        of: scrollView,
        matching: find.byType(Scrollable),
      );
      final viewport = tester.getRect(scrollView);
      expect(panel.bottom, 892);
      expect(viewport.bottom, panel.bottom);
      expect(panel.height, 476);
      expect(viewport.height, 432);
      expect(panel.top, 416);
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(GlassBottomSheetSurface.dragHandleKey),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );

      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final finalControl = tester.getRect(
        find.byKey(const ValueKey('reader-settings-final-control')),
      );
      expect(finalControl.bottom, lessThanOrEqualTo(900 - 34));
      await tester.tap(
        find.byKey(const ValueKey('reader-settings-final-control')),
      );
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'route-owned reading settings keeps one surface and the expanded viewport',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      var taps = 0;

      await tester.pumpWidget(
        _host(
          builderOwnsSurface: false,
          child: ReaderSettingsSheetFrame(
            palette: ReaderThemes.day,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nested reading settings'),
                for (var index = 0; index < 12; index++)
                  SizedBox(height: 56, child: Text('Nested setting $index')),
                FilledButton(
                  key: const ValueKey('nested-reader-settings-final-control'),
                  onPressed: () => taps += 1,
                  child: const Text('Nested final setting'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final panel = tester.getRect(find.byType(GlassSurface));
      final scrollView = find.byType(SingleChildScrollView);
      final viewport = tester.getRect(scrollView);
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
      expect(panel, const Rect.fromLTWH(8, 416, 374, 476));
      expect(viewport.bottom, panel.bottom);
      expect(viewport.height, 432);
      expect(
        find.ancestor(
          of: find.byKey(GlassBottomSheetSurface.dragHandleKey),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );

      final scrollable = find.descendant(
        of: scrollView,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final finalControl = tester.getRect(
        find.byKey(const ValueKey('nested-reader-settings-final-control')),
      );
      expect(finalControl.bottom, lessThanOrEqualTo(900 - 34));
      await tester.tap(
        find.byKey(const ValueKey('nested-reader-settings-final-control')),
      );
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'route-owned reader submenus keep their scroll viewport to edge',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);

      final sheets = <Widget>[
        ReaderTopBarStyleSheet(
          palette: ReaderThemes.day,
          title: 'Top bar style',
          selectedStyle: ReaderTopBarStyle.system,
          titleFor: (style) => style.name,
          hintFor: (style) => '${style.name} hint',
          onSelected: (_) {},
        ),
        ReaderPageModeSheet(
          palette: ReaderThemes.day,
          title: 'Page mode',
          selectedMode: ReaderPageMode.verticalScroll,
          titleFor: (mode) => mode.name,
          hintFor: (mode) => '${mode.name} hint',
          onSelected: (_) {},
        ),
      ];

      for (final sheet in sheets) {
        await tester.pumpWidget(_host(child: sheet, builderOwnsSurface: false));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final panel = tester.getRect(find.byType(GlassSurface));
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(viewport.bottom, panel.bottom);
        expect(find.byType(GlassSurface), findsOneWidget);
        expect(
          find.byKey(GlassBottomSheetSurface.dragHandleKey),
          findsOneWidget,
        );

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
      }
    },
  );
}

Widget _host({required Widget child, bool builderOwnsSurface = true}) =>
    MaterialApp(
      theme: ThemeData(
        extensions: const [
          UiStyleThemeExtension(
            style: AppUiStyle.glass,
            glassStyle: GlassStyle.frosted,
          ),
        ],
      ),
      builder: (context, appChild) => MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 900),
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
        child: appChild!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showGlassBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builderOwnsSurface: builderOwnsSurface,
                builder: (_) => child,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
