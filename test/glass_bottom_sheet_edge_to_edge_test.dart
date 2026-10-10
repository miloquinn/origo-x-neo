import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';

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
    'explicit legacy mode keeps fixed bottom and landscape side protection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final media in const [
        MediaQueryData(
          size: Size(390, 900),
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
        MediaQueryData(
          size: Size(900, 390),
          padding: EdgeInsets.fromLTRB(47, 0, 47, 21),
          viewPadding: EdgeInsets.fromLTRB(47, 0, 47, 21),
        ),
      ]) {
        tester.view.physicalSize = media.size;
        await tester.pumpWidget(
          _routeHost(
            media: media,
            extendContentIntoBottomSafeArea: false,
            child: const SizedBox(
              key: ValueKey('fixed-sheet-content'),
              height: 80,
              width: double.infinity,
            ),
          ),
        );
        await _open(tester);

        final panel = tester.getRect(find.byType(GlassSurface));
        final content = tester.getRect(
          find.byKey(const ValueKey('fixed-sheet-content')),
        );
        expect(media.size.width - panel.right, 8);
        expect(media.size.height - panel.bottom, 8);
        expect(content.bottom, media.size.height - media.padding.bottom);
        if (media.orientation == Orientation.landscape) {
          expect(content.left, media.padding.left);
          expect(content.right, media.size.width - media.padding.right);
        }
        final contentMedia = MediaQuery.of(
          tester.element(find.byKey(const ValueKey('fixed-sheet-content'))),
        );
        expect(contentMedia.padding.bottom, 0);
        expect(
          contentMedia.viewPadding.bottom,
          media.viewPadding.bottom - media.padding.bottom,
        );

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('route legacy choice overrides the child surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _routeHost(
        media: const MediaQueryData(
          size: Size(390, 900),
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
        builderOwnsSurface: true,
        extendContentIntoBottomSafeArea: false,
        child: const GlassBottomSheetSurface(
          extendContentIntoBottomSafeArea: true,
          child: SizedBox(
            key: ValueKey('legacy-owned-content'),
            height: 80,
            width: double.infinity,
          ),
        ),
      ),
    );
    await _open(tester);

    final content = find.byKey(const ValueKey('legacy-owned-content'));
    expect(tester.getRect(content).bottom, 900 - 34);
    expect(MediaQuery.paddingOf(tester.element(content)).bottom, 0);
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'default scroll route reaches the surface and protects its last action',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      var taps = 0;

      await tester.pumpWidget(
        _routeHost(
          media: const MediaQueryData(
            size: Size(390, 900),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          childBuilder: (context) => SizedBox(
            height: 300,
            child: SingleChildScrollView(
              key: const ValueKey('edge-to-edge-scroll-viewport'),
              child: SafeArea(
                top: false,
                left: false,
                right: false,
                minimum: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    for (var index = 0; index < 12; index++)
                      SizedBox(height: 56, child: Text('Row $index')),
                    FilledButton(
                      key: const ValueKey('last-sheet-action'),
                      onPressed: () => taps += 1,
                      child: const Text('Last action'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _open(tester);

      final panel = tester.getRect(find.byType(GlassSurface));
      final viewport = tester.getRect(
        find.byKey(const ValueKey('edge-to-edge-scroll-viewport')),
      );
      expect(panel.bottom, 892);
      expect(viewport.bottom, panel.bottom);
      final contentMedia = MediaQuery.of(
        tester.element(
          find.byKey(const ValueKey('edge-to-edge-scroll-viewport')),
        ),
      );
      expect(contentMedia.padding.bottom, 26);
      expect(contentMedia.viewPadding.bottom, 26);
      final innerSafeArea = find.ancestor(
        of: find.byKey(const ValueKey('last-sheet-action')),
        matching: find.byType(SafeArea),
      );
      expect(innerSafeArea, findsOneWidget);
      expect(
        find.ancestor(of: innerSafeArea, matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      expect(find.byType(GlassSurface), findsOneWidget);
      expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byKey(GlassBottomSheetSurface.dragHandleKey),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );

      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('edge-to-edge-scroll-viewport')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      final action = tester.getRect(
        find.byKey(const ValueKey('last-sheet-action')),
      );
      expect(action.bottom, lessThanOrEqualTo(900 - 34));
      await tester.tap(find.byKey(const ValueKey('last-sheet-action')));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'default fixed-footer menu protects its action without a global bottom band',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(tester.view.reset);
      var taps = 0;

      await tester.pumpWidget(
        _routeHost(
          media: const MediaQueryData(
            size: Size(390, 900),
            padding: EdgeInsets.only(bottom: 34),
            viewPadding: EdgeInsets.only(bottom: 34),
          ),
          childBuilder: (context) => SizedBox(
            key: const ValueKey('fixed-footer-menu'),
            height: 420,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('fixed-footer-scroll-body'),
                    child: Column(
                      children: [
                        for (var index = 0; index < 12; index++)
                          SizedBox(height: 48, child: Text('Menu row $index')),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  key: const ValueKey('fixed-footer-safe-area'),
                  top: false,
                  left: false,
                  right: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('fixed-footer-action'),
                      onPressed: () => taps += 1,
                      child: const Text('Apply menu choice'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await _open(tester);

      final panel = tester.getRect(find.byType(GlassSurface));
      final menu = tester.getRect(
        find.byKey(const ValueKey('fixed-footer-menu')),
      );
      final scrollBody = tester.getRect(
        find.byKey(const ValueKey('fixed-footer-scroll-body')),
      );
      final footerSafeArea = tester.getRect(
        find.byKey(const ValueKey('fixed-footer-safe-area')),
      );
      final footerAction = tester.getRect(
        find.byKey(const ValueKey('fixed-footer-action')),
      );

      expect(menu.bottom, panel.bottom);
      expect(footerSafeArea.bottom, panel.bottom);
      expect(scrollBody.bottom, footerSafeArea.top);
      expect(footerAction.bottom, lessThanOrEqualTo(900 - 34));
      expect(
        panel.bottom - footerSafeArea.bottom,
        0,
        reason: 'the route must not add a second 26pt global safe-area band',
      );
      final footerMedia = MediaQuery.of(
        tester.element(find.byKey(const ValueKey('fixed-footer-safe-area'))),
      );
      expect(footerMedia.padding.bottom, 26);
      expect(footerMedia.viewPadding.bottom, 26);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('fixed-footer-action')),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('fixed-footer-action')));
      await tester.pump();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Widget _routeHost({
  required MediaQueryData media,
  Widget? child,
  WidgetBuilder? childBuilder,
  bool builderOwnsSurface = false,
  bool? extendContentIntoBottomSafeArea,
}) => MaterialApp(
  theme: ThemeData(
    extensions: const [
      UiStyleThemeExtension(
        style: AppUiStyle.glass,
        glassStyle: GlassStyle.frosted,
      ),
    ],
  ),
  builder: (context, appChild) => MediaQuery(data: media, child: appChild!),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => _showTestSheet(
            context,
            builder: childBuilder ?? (_) => child!,
            builderOwnsSurface: builderOwnsSurface,
            extendContentIntoBottomSafeArea: extendContentIntoBottomSafeArea,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _showTestSheet(
  BuildContext context, {
  required WidgetBuilder builder,
  required bool builderOwnsSurface,
  required bool? extendContentIntoBottomSafeArea,
}) {
  if (extendContentIntoBottomSafeArea == null) {
    return showGlassBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builderOwnsSurface: builderOwnsSurface,
      builder: builder,
    );
  }
  return showGlassBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builderOwnsSurface: builderOwnsSurface,
    extendContentIntoBottomSafeArea: extendContentIntoBottomSafeArea,
    builder: builder,
  );
}
