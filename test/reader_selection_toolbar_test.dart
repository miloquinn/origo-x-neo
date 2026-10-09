import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_selection_toolbar.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setLiquidGlassOpacity(0);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  testWidgets('shows copy, highlight, note, and more in primary order', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 800);

    final primaryActions = [
      find.byKey(const ValueKey('reader-selection-copy')),
      find.byKey(const ValueKey('reader-selection-highlight')),
      find.byKey(const ValueKey('reader-selection-note')),
      find.byKey(const ValueKey('reader-selection-more')),
    ];
    for (final action in primaryActions) {
      expect(action, findsOneWidget);
    }
    final centers = primaryActions.map(tester.getCenter).toList();
    expect(
      centers.map((center) => center.dx),
      orderedEquals([...centers.map((center) => center.dx).toList()..sort()]),
    );
  });

  testWidgets('primary actions invoke their matching callbacks', (
    tester,
  ) async {
    final calls = <String>[];
    await _pumpToolbar(
      tester,
      width: 800,
      onCopy: () => calls.add('copy'),
      onHighlight: () => calls.add('highlight'),
      onNote: () => calls.add('note'),
    );

    await tester.tap(find.byKey(const ValueKey('reader-selection-copy')));
    await tester.tap(find.byKey(const ValueKey('reader-selection-highlight')));
    await tester.tap(find.byKey(const ValueKey('reader-selection-note')));
    expect(calls, ['copy', 'highlight', 'note']);
  });

  testWidgets('uses one pill-like glass background without action capsules', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 800);

    expect(find.byType(GlassControlSurface), findsOneWidget);
    expect(find.byType(GlassTextButton), findsNothing);
    expect(find.byType(ReaderControlBar), findsNothing);
    final surface = tester.widget<GlassControlSurface>(
      find.byType(GlassControlSurface),
    );
    expect(surface.blurBackground, isTrue);
    expect(surface.shape, isA<RoundedSuperellipseBorder>());
    final surfaceHeight = tester
        .getSize(find.byType(GlassControlSurface))
        .height;
    expect(
      (surface.shape as RoundedSuperellipseBorder).borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x,
      closeTo(surfaceHeight / 2, 0.01),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('reader-selection-toolbar')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'default primary row fits without scrolling or clipped separators',
    (tester) async {
      await _pumpToolbar(tester, width: 800);
      final toolbar = find.byKey(const ValueKey('reader-selection-toolbar'));
      final horizontalScroll = find.descendant(
        of: toolbar,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              (widget.axisDirection == AxisDirection.left ||
                  widget.axisDirection == AxisDirection.right),
        ),
      );
      expect(horizontalScroll, findsOneWidget);
      expect(
        tester
            .state<ScrollableState>(horizontalScroll)
            .position
            .maxScrollExtent,
        0,
      );

      final separators = find.descendant(
        of: toolbar,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 1 && widget.height == 16,
        ),
      );
      expect(separators, findsNWidgets(3));
      final toolbarRect = tester.getRect(toolbar);
      final separatorRects = separators.evaluate().map((element) {
        return tester.getRect(
          find.byElementPredicate((candidate) => candidate == element),
        );
      }).toList();
      expect(
        separatorRects.map((rect) => rect.center.dx),
        orderedEquals([
          ...separatorRects.map((rect) => rect.center.dx).toList()..sort(),
        ]),
      );
      for (final rect in separatorRects) {
        expect(rect.width, 1);
        expect(rect.height, 16);
        expect(toolbarRect.contains(rect.center), isTrue);
      }
    },
  );

  testWidgets('disabled copy remains visible and exposes disabled semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpToolbar(tester, width: 800, onCopy: null);

      final copy = find.byKey(const ValueKey('reader-selection-copy'));
      expect(copy, findsOneWidget);
      expect(tester.widget<TextButton>(copy).onPressed, isNull);
      final data = tester.getSemantics(copy).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('more semantics announce collapsed and expanded states', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpToolbar(tester, width: 800, onSearch: () {});
      final more = find.byKey(const ValueKey('reader-selection-more'));
      final material = MaterialLocalizations.of(tester.element(more));
      final moreSemantics = find.ancestor(
        of: more,
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.expanded != null,
        ),
      );
      expect(moreSemantics, findsOneWidget);

      var data = tester.getSemantics(moreSemantics).getSemanticsData();
      expect(data.flagsCollection.isExpanded, ui.Tristate.isFalse);
      expect(
        tester.getSemantics(more).getSemanticsData().tooltip,
        material.moreButtonTooltip,
      );

      await tester.tap(more);
      await tester.pumpAndSettle();
      data = tester.getSemantics(moreSemantics).getSemanticsData();
      expect(data.flagsCollection.isExpanded, ui.Tristate.isTrue);
      expect(
        tester.getSemantics(more).getSemanticsData().tooltip,
        material.closeButtonTooltip,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'more expands available actions in place and closes after action',
    (tester) async {
      final calls = <String>[];
      await _pumpToolbar(
        tester,
        width: 800,
        onSearch: () => calls.add('search'),
        onPurify: () => calls.add('purify'),
        onAskAi: () => calls.add('ask-ai'),
      );

      expect(
        find.byKey(const ValueKey('reader-selection-search')),
        findsNothing,
      );
      expect(find.byType(Overlay), findsOneWidget);
      final barriersBefore = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.byKey(const ValueKey('reader-selection-more')));
      await tester.pumpAndSettle();

      final secondaryActions = [
        find.byKey(const ValueKey('reader-selection-search')),
        find.byKey(const ValueKey('reader-selection-purify')),
        find.byKey(const ValueKey('reader-selection-ask-ai')),
      ];
      for (final action in secondaryActions) {
        expect(action, findsOneWidget);
      }
      expect(find.byType(GlassControlSurface), findsOneWidget);
      expect(find.byType(ModalBarrier), findsNWidgets(barriersBefore));

      await tester.tap(secondaryActions[0]);
      await tester.pumpAndSettle();
      expect(calls, ['search']);
      expect(
        find.byKey(const ValueKey('reader-selection-search')),
        findsNothing,
      );
    },
  );

  testWidgets('more closes an expanded panel when tapped again', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 800, onSearch: () {});
    final more = find.byKey(const ValueKey('reader-selection-more'));

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-selection-search')),
      findsOneWidget,
    );

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-selection-search')), findsNothing);
  });

  testWidgets('omits unavailable and obsolete overflow actions', (
    tester,
  ) async {
    await _pumpToolbar(tester, width: 800, onSearch: () {});
    await tester.tap(find.byKey(const ValueKey('reader-selection-more')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-selection-search')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-selection-purify')), findsNothing);
    expect(find.byKey(const ValueKey('reader-selection-ask-ai')), findsNothing);
    expect(find.text('分享'), findsNothing);
    expect(find.text('翻译'), findsNothing);
    expect(find.text('朗读'), findsNothing);
    expect(find.text('反馈'), findsNothing);
  });

  testWidgets('matches frosted, liquid, disabled, and Material surfaces', (
    tester,
  ) async {
    for (final mode in [
      (
        name: 'frosted',
        glass: GlassStyle.frosted,
        disabled: false,
        material: false,
      ),
      (
        name: 'liquid',
        glass: GlassStyle.liquid,
        disabled: false,
        material: false,
      ),
      (
        name: 'disabled',
        glass: GlassStyle.frosted,
        disabled: true,
        material: false,
      ),
      (
        name: 'material',
        glass: GlassStyle.frosted,
        disabled: false,
        material: true,
      ),
    ]) {
      GlassEffectConfig.setGlassStyle(mode.glass);
      GlassEffectConfig.setLiquidGlassOpacity(0.6);
      GlassEffectConfig.setDisableAllGlassEffects(mode.disabled);
      await _pumpToolbar(
        tester,
        width: 800,
        glassStyle: mode.glass,
        uiStyle: mode.material ? AppUiStyle.material3 : AppUiStyle.glass,
      );

      expect(
        find.byType(GlassControlSurface),
        findsOneWidget,
        reason: mode.name,
      );
      if (mode.name == 'liquid') {
        expect(find.byType(LiquidGlassSurface), findsOneWidget);
      } else {
        expect(
          find.byType(LiquidGlassSurface),
          findsNothing,
          reason: mode.name,
        );
      }
      if (mode.name == 'frosted') {
        expect(find.byType(BackdropFilter), findsOneWidget);
      } else if (mode.disabled || mode.material) {
        expect(find.byType(BackdropFilter), findsNothing, reason: mode.name);
      }
    }
  });

  testWidgets('keeps high contrast actions readable and operational', (
    tester,
  ) async {
    var copies = 0;
    await _pumpToolbar(
      tester,
      width: 800,
      highContrast: true,
      onCopy: () => copies += 1,
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<GlassControlSurface>(find.byType(GlassControlSurface))
          .useGlass,
      isFalse,
    );
    await tester.tap(find.byKey(const ValueKey('reader-selection-copy')));
    expect(copies, 1);
    expect(find.byType(GlassControlSurface), findsOneWidget);
  });

  testWidgets('keeps toolbar inside the viewport at edge anchors', (
    tester,
  ) async {
    for (final anchor in const [Offset(2, 2), Offset(358, 298)]) {
      await _pumpToolbar(tester, width: 360, height: 300, anchor: anchor);
      final rect = tester.getRect(
        find.byKey(const ValueKey('reader-selection-toolbar')),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
      expect(rect.bottom, lessThanOrEqualTo(300));
    }
  });

  testWidgets(
    'expanded actions stay inside safe bounds and remain scrollable at large text',
    (tester) async {
      var asks = 0;
      const safePadding = EdgeInsets.fromLTRB(14, 12, 18, 16);
      await _pumpToolbar(
        tester,
        width: 320,
        height: 180,
        anchor: const Offset(300, 168),
        textScale: 2,
        safePadding: safePadding,
        onSearch: () {},
        onPurify: () {},
        onAskAi: () => asks += 1,
      );

      await tester.tap(find.byKey(const ValueKey('reader-selection-more')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final toolbar = find.byKey(const ValueKey('reader-selection-toolbar'));
      final toolbarRect = tester.getRect(toolbar);
      expect(toolbarRect.left, greaterThanOrEqualTo(safePadding.left + 8));
      expect(toolbarRect.top, greaterThanOrEqualTo(safePadding.top + 8));
      expect(toolbarRect.right, lessThanOrEqualTo(320 - safePadding.right - 8));
      expect(
        toolbarRect.bottom,
        lessThanOrEqualTo(180 - safePadding.bottom - 8),
      );
      expect(
        find.descendant(of: toolbar, matching: find.byType(Scrollable)),
        findsWidgets,
      );

      final askAi = find.byKey(const ValueKey('reader-selection-ask-ai'));
      await tester.ensureVisible(askAi);
      await tester.pumpAndSettle();
      expect(toolbarRect.contains(tester.getCenter(askAi)), isTrue);
      await tester.tap(askAi);
      await tester.pumpAndSettle();
      expect(asks, 1);
    },
  );

  for (final localeCase in [
    (name: 'English', locale: const Locale('en'), direction: TextDirection.ltr),
    (name: 'RTL', locale: const Locale('ar'), direction: TextDirection.rtl),
  ]) {
    testWidgets(
      'keeps copy and more visible without truncation on 320px ${localeCase.name}',
      (tester) async {
        await _pumpToolbar(
          tester,
          width: 320,
          locale: localeCase.locale,
          textDirection: localeCase.direction,
          textScale: 2,
          onSearch: () {},
          onPurify: () {},
          onAskAi: () {},
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('reader-selection-copy')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('reader-selection-more')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('reader-selection-highlight')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('reader-selection-note')),
          findsNothing,
        );
        final toolbarRect = tester.getRect(
          find.byKey(const ValueKey('reader-selection-toolbar')),
        );
        expect(toolbarRect.left, greaterThanOrEqualTo(0));
        expect(toolbarRect.right, lessThanOrEqualTo(320));
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('reader-selection-toolbar')),
            matching: find.byType(Text),
          ),
        )) {
          expect(text.overflow, isNot(TextOverflow.ellipsis));
        }
        await tester.tap(find.byKey(const ValueKey('reader-selection-more')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('reader-selection-highlight')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('reader-selection-note')),
          findsOneWidget,
        );
      },
    );
  }
}

Future<void> _pumpToolbar(
  WidgetTester tester, {
  double width = 360,
  double height = 300,
  Offset? anchor,
  Locale locale = const Locale('zh'),
  TextDirection? textDirection,
  double textScale = 1,
  bool highContrast = false,
  EdgeInsets safePadding = EdgeInsets.zero,
  GlassStyle glassStyle = GlassStyle.frosted,
  AppUiStyle uiStyle = AppUiStyle.glass,
  VoidCallback? onCopy = _noop,
  VoidCallback? onHighlight,
  VoidCallback? onNote,
  VoidCallback? onSearch,
  VoidCallback? onPurify,
  VoidCallback? onAskAi,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(Size(width, height));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: [
          UiStyleThemeExtension(
            style: uiStyle,
            glassStyle: glassStyle,
            liquidGlassOpacity: 0.6,
          ),
        ],
      ),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          highContrast: highContrast,
          padding: safePadding,
        ),
        child: Directionality(
          textDirection: textDirection ?? TextDirection.ltr,
          child: Scaffold(
            body: Stack(
              children: [
                ReaderSelectionToolbar(
                  palette: ReaderThemes.day,
                  anchors: TextSelectionToolbarAnchors(
                    primaryAnchor: anchor ?? Offset(width / 2, height / 2),
                  ),
                  onCopy: onCopy,
                  onHighlight: onHighlight ?? _noop,
                  onNote: onNote ?? _noop,
                  onSearch: onSearch,
                  onPurify: onPurify,
                  onAskAi: onAskAi,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}
