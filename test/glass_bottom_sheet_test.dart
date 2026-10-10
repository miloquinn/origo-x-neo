import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  testWidgets('resolves one shared panel across every appearance mode', (
    tester,
  ) async {
    final modes =
        <
          ({
            GlassStyle style,
            AppUiStyle ui,
            bool disableGlass,
            bool highContrast,
            bool liquid,
          })
        >[
          (
            style: GlassStyle.frosted,
            ui: AppUiStyle.glass,
            disableGlass: false,
            highContrast: false,
            liquid: false,
          ),
          (
            style: GlassStyle.liquid,
            ui: AppUiStyle.glass,
            disableGlass: false,
            highContrast: false,
            liquid: true,
          ),
          (
            style: GlassStyle.liquid,
            ui: AppUiStyle.material3,
            disableGlass: false,
            highContrast: false,
            liquid: false,
          ),
          (
            style: GlassStyle.liquid,
            ui: AppUiStyle.glass,
            disableGlass: true,
            highContrast: false,
            liquid: false,
          ),
          (
            style: GlassStyle.liquid,
            ui: AppUiStyle.glass,
            disableGlass: false,
            highContrast: true,
            liquid: false,
          ),
        ];

    for (final mode in modes) {
      GlassEffectConfig.setDisableAllGlassEffects(mode.disableGlass);
      await tester.pumpWidget(
        _host(
          style: mode.style,
          ui: mode.ui,
          media: MediaQueryData(
            size: const Size(800, 600),
            highContrast: mode.highContrast,
          ),
        ),
      );
      await _open(tester);

      expect(find.byType(GlassSurface), findsOneWidget, reason: '$mode');
      expect(
        find.byKey(GlassBottomSheetSurface.dragHandleKey),
        findsOneWidget,
        reason: '$mode',
      );
      expect(
        find.byType(LiquidGlassSurface),
        mode.liquid ? findsOneWidget : findsNothing,
        reason: '$mode',
      );
      expect(
        find.ancestor(
          of: find.byType(GlassSurface),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('returns typed results and supports back and barrier dismissal', (
    tester,
  ) async {
    int? result;
    await tester.pumpWidget(_host(onResult: (value) => result = value));
    await _open(tester);
    await tester.tap(find.text('Return 7'));
    await tester.pumpAndSettle();
    expect(result, 7);

    await _open(tester);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);

    await _open(tester);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('shared handle dismisses by tap and by a native route drag', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _open(tester);
    final handle = find.byKey(GlassBottomSheetSurface.dragHandleKey);
    expect(
      tester.getSize(handle).height,
      GlassBottomSheetSurface.dragHandleExtent,
    );
    await tester.tap(handle);
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);

    await _open(tester);
    await tester.drag(handle, const Offset(0, 420));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsNothing);
  });

  testWidgets('an aborted native drag restores the panel', (tester) async {
    await tester.pumpWidget(_host());
    await _open(tester);
    await tester.drag(
      find.byKey(GlassBottomSheetSurface.dragHandleKey),
      const Offset(0, 40),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
  });

  testWidgets('nested delegated shell does not duplicate glass or handle', (
    tester,
  ) async {
    await tester.pumpWidget(_host(nestedSurface: true));
    await _open(tester);
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
  });

  testWidgets('builder-owned surface updates its live palette and dismisses', (
    tester,
  ) async {
    final palette = ValueNotifier(ReaderThemes.day);
    addTearDown(palette.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showGlassBottomSheet<void>(
              context: context,
              builderOwnsSurface: true,
              builder: (context) => ValueListenableBuilder<ReaderThemePalette>(
                valueListenable: palette,
                builder: (context, current, _) => Theme(
                  data: current.toThemeData(),
                  child: GlassBottomSheetSurface(
                    color: current.controlBar,
                    brightness: current.brightness,
                    child: TextButton(
                      onPressed: () => palette.value = ReaderThemes.pureBlack,
                      child: const Text('Change palette'),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Open dynamic'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dynamic'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
    expect(
      tester.widget<GlassSurface>(find.byType(GlassSurface)).color,
      ReaderThemes.day.controlBar,
    );

    await tester.tap(find.text('Change palette'));
    await tester.pumpAndSettle();
    final surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
    expect(surface.color, ReaderThemes.pureBlack.controlBar);
    expect(surface.brightness, Brightness.dark);
    final handleDecoration = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(GlassBottomSheetSurface.dragHandleKey),
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .single;
    expect(
      handleDecoration.color,
      ReaderThemes.pureBlack.secondaryText.withValues(alpha: 0.56),
    );

    await tester.tap(find.byKey(GlassBottomSheetSurface.dragHandleKey));
    await tester.pumpAndSettle();
    expect(find.text('Change palette'), findsNothing);
  });

  testWidgets('small large-text sheet keeps caller scrolling and bounds', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      _host(
        scrollContent: true,
        media: const MediaQueryData(
          size: Size(320, 540),
          textScaler: TextScaler.linear(2.4),
          viewInsets: EdgeInsets.only(bottom: 140),
        ),
        constraints: const BoxConstraints(maxHeight: 340),
      ),
    );
    await _open(tester);

    expect(tester.takeException(), isNull);
    final panel = tester.getRect(find.byType(GlassSurface));
    expect(panel.width, lessThanOrEqualTo(304));
    expect(panel.height, lessThanOrEqualTo(332));
    expect(find.text('keyboard: 140'), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets(
    'safe route clears nested bottom padding and keeps panel afloat',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(nestedSafeArea: true));
      await _open(tester);

      final panel = tester.getRect(find.byType(GlassSurface));
      final content = tester.getRect(
        find.byKey(const Key('safe-area-content')),
      );
      expect(panel.bottom, lessThanOrEqualTo(900 - 34 - 8));
      expect(content.bottom, panel.bottom);
    },
  );

  testWidgets('useSafeArea false leaves the bottom inset to the caller', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(useSafeArea: false));
    await _open(tester);

    final panel = tester.getRect(find.byType(GlassSurface));
    expect(panel.bottom, 900 - 8);
  });

  testWidgets('reduced motion requests a zero-duration native transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        media: const MediaQueryData(
          size: Size(800, 600),
          disableAnimations: true,
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();

    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    expect(sheet.animationController!.duration, Duration.zero);
    expect(sheet.animationController!.reverseDuration, Duration.zero);
  });

  testWidgets('non-dismissible transaction disables every handle exit', (
    tester,
  ) async {
    await tester.pumpWidget(_host(isDismissible: false, enableDrag: false));
    await _open(tester);
    final handle = find.byKey(GlassBottomSheetSurface.dragHandleKey);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    await tester.tap(handle);
    await tester.drag(handle, const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
  });

  testWidgets('transaction can suppress the shared handle completely', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(isDismissible: false, enableDrag: false, showDragHandle: false),
    );
    await _open(tester);

    expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsNothing);
    expect(find.byType(GlassSurface), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Sheet body'), findsOneWidget);
  });

  testWidgets('optional theme, focus and transparent tint preserve contracts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        backgroundColor: Colors.transparent,
        requestFocus: true,
        sheetTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        focusContent: true,
      ),
    );
    await _open(tester);

    expect(find.byType(GlassSurface), findsOneWidget);
    expect(
      tester.widget<GlassSurface>(find.byType(GlassSurface)).color,
      isNull,
    );
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.focusNode!.hasFocus, isTrue);
    expect(
      Theme.of(tester.element(find.text('Sheet body'))).colorScheme.primary,
      isNot(ThemeData().colorScheme.primary),
    );
  });

  testWidgets('standalone surface provides clipped Material ink and bounds', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GlassBottomSheetSurface(
          child: ListTile(
            title: const Text('Standalone'),
            onTap: () => taps += 1,
          ),
        ),
      ),
    );
    expect(find.byType(GlassSurface), findsOneWidget);
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(GlassSurface),
        matching: find.byType(Material),
      ),
    );
    expect(material.type, MaterialType.transparency);
    expect(material.clipBehavior, Clip.antiAlias);
    await tester.tap(find.text('Standalone'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(GlassSurface)).width,
      lessThanOrEqualTo(640),
    );
  });
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Widget _host({
  GlassStyle style = GlassStyle.frosted,
  AppUiStyle ui = AppUiStyle.glass,
  MediaQueryData? media,
  bool nestedSurface = false,
  bool scrollContent = false,
  bool nestedSafeArea = false,
  bool useSafeArea = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  BoxConstraints? constraints,
  bool? requestFocus,
  ThemeData? sheetTheme,
  bool focusContent = false,
  ValueChanged<int?>? onResult,
}) => MaterialApp(
  theme: ThemeData(
    extensions: [UiStyleThemeExtension(style: ui, glassStyle: style)],
  ),
  builder: (context, child) =>
      MediaQuery(data: media ?? MediaQuery.of(context), child: child!),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final result = await showGlassBottomSheet<int>(
              context: context,
              isScrollControlled: true,
              useSafeArea: useSafeArea,
              isDismissible: isDismissible,
              enableDrag: enableDrag,
              showDragHandle: showDragHandle,
              backgroundColor: backgroundColor,
              constraints: constraints,
              requestFocus: requestFocus,
              theme: sheetTheme,
              builder: (context) {
                Widget child;
                if (nestedSafeArea) {
                  child = const SafeArea(
                    top: false,
                    child: SizedBox(
                      key: Key('safe-area-content'),
                      height: 80,
                      child: Text('Nested safe area'),
                    ),
                  );
                } else if (scrollContent) {
                  child = SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          'keyboard: ${MediaQuery.viewInsetsOf(context).bottom.toInt()}',
                        ),
                        ...List.generate(
                          30,
                          (index) => Text('A long sheet row $index'),
                        ),
                      ],
                    ),
                  );
                } else {
                  final focusNode = FocusNode();
                  addTearDown(focusNode.dispose);
                  child = Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sheet body'),
                        if (focusContent)
                          TextField(focusNode: focusNode, autofocus: true),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, 7),
                          child: const Text('Return 7'),
                        ),
                      ],
                    ),
                  );
                }
                return nestedSurface
                    ? GlassBottomSheetSurface(child: child)
                    : child;
              },
            );
            onResult?.call(result);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);
