import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/home_shell_page.dart';
import 'package:xxread/pages/home/widgets/home_mobile_top_bar.dart';
import 'package:xxread/widgets/glass_top_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/widgets/gradient_top_backdrop.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/book_open_transition.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '${platform.name} floating navigation respects its bottom gap',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final historyStore = AiChatHistoryStore();
        addTearDown(historyStore.dispose);
        await tester.binding.setSurfaceSize(const Size(402, 874));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AppSettingsNotifier(),
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(402, 874),
                  viewPadding: EdgeInsets.only(top: 62, bottom: 34),
                ),
                child: HomeShellPage(aiChatHistoryStore: historyStore),
              ),
            ),
          ),
        );
        await tester.pump();
        final bar = find.byType(FloatingPillNavigationSurface);
        final rect = tester.getRect(bar);
        final gap = platform == TargetPlatform.iOS ? 2.0 : 10.0;
        expect(rect.bottom, 874 - 34 - gap);
        expect(rect.height, platform == TargetPlatform.iOS ? 60 : 56);
        final metrics = HomeMobileChromeScope.of(tester.element(bar));
        expect(metrics.pageBottomPadding, 874 - rect.top + 10);
        expect(metrics.floatingActionBottomMargin, 874 - rect.top + 15);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({platform}),
    );
  }

  testWidgets(
    'unrelated settings notifications keep the home shell widget instances',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final historyStore = AiChatHistoryStore();
      final settings = _TestAppSettingsNotifier();
      addTearDown(historyStore.dispose);
      addTearDown(settings.dispose);
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider<AppSettingsNotifier>.value(
          value: settings,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HomeShellPage(aiChatHistoryStore: historyStore),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final pageViewFinder = find.byType(PageView);
      final shellScaffoldFinder = find.ancestor(
        of: pageViewFinder,
        matching: find.byType(Scaffold),
      );
      final pageViewBefore = tester.widget<PageView>(pageViewFinder);
      final scaffoldBefore = tester.widget<Scaffold>(shellScaffoldFinder.first);

      for (var iteration = 0; iteration < 30; iteration++) {
        settings.notifyUnrelatedChange();
        await tester.pump();

        expect(tester.widget<PageView>(pageViewFinder), same(pageViewBefore));
        expect(
          tester.widget<Scaffold>(shellScaffoldFinder.first),
          same(scaffoldBefore),
        );
      }

      await settings.setHomeNavigationOrder(const [
        HomeNavigationDestination.home,
        HomeNavigationDestination.discover,
        HomeNavigationDestination.library,
        HomeNavigationDestination.ai,
        HomeNavigationDestination.settings,
      ]);
      await tester.pump();

      final reorderedPageView = tester.widget<PageView>(pageViewFinder);
      final reorderedChildren =
          (reorderedPageView.childrenDelegate as SliverChildListDelegate)
              .children;
      expect(
        (reorderedChildren[1].key! as ValueKey<String>).value,
        'home-page-discover',
      );
    },
  );

  testWidgets('mobile home shell leaves the status bar to its custom top bar', (
    tester,
  ) async {
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsNotifier(),
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
            ),
            extensions: const [
              UiStyleThemeExtension(style: AppUiStyle.material3),
            ],
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              viewPadding: EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: HomeShellPage(aiChatHistoryStore: historyStore),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    final topBar = find.byType(HomeMobileTopBar);
    expect(topBar, findsOneWidget);
    expect(tester.getTopLeft(topBar), Offset.zero);
    expect(tester.getSize(topBar).height, 84);
    expect(find.byType(GradientTopBackdrop), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    final solid = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(GradientTopBackdrop),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(solid.color.a, 1);
  });

  testWidgets('mobile liquid glass top bar uses the shared gradient backdrop', (
    tester,
  ) async {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    GlassEffectConfig.setLiquidGlassOpacity(0.5);
    addTearDown(() {
      GlassEffectConfig.setDisableAllGlassEffects(false);
      GlassEffectConfig.setGlassStyle(defaultGlassStyle);
      GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewPadding: EdgeInsets.only(top: 24)),
          child: Scaffold(
            body: GlassTopBar(title: 'Library', systemTopInset: 24),
          ),
        ),
      ),
    );

    expect(find.byType(GradientTopBackdrop), findsOneWidget);
    final backdrop = tester.widget<GradientTopBackdrop>(
      find.byType(GradientTopBackdrop),
    );
    expect(backdrop.height, 84);
    expect(backdrop.clearTail, 4);
    expect(backdrop.maxSigma, closeTo(12.75, 0.001));
    expect(backdrop.fallbackBands, 16);
    expect(
      find.byKey(const ValueKey('gradient-top-backdrop-liquid-tint')),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(GlassTopBar)).height, 84);
  });

  testWidgets('book route hides and restores the floating navigation', (
    tester,
  ) async {
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsNotifier(),
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
            ),
            extensions: const [
              UiStyleThemeExtension(style: AppUiStyle.material3),
            ],
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              viewPadding: EdgeInsets.only(top: 24, bottom: 24),
            ),
            child: HomeShellPage(aiChatHistoryStore: historyStore),
          ),
        ),
      ),
    );
    await tester.pump();

    const motionKey = ValueKey('home-floating-navigation-motion');
    final motionFinder = find.byKey(motionKey, skipOffstage: false);
    expect(tester.widget<AnimatedSlide>(motionFinder).offset, Offset.zero);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final readerRoute = BookOpenTransition.createRoute<void>(
      (_) => const Scaffold(body: Text('reader')),
    );
    expect(BookOpenTransition.hasActiveReaderActivity, isTrue);
    expect(BookOpenTransition.navigationHiddenListenable.value, isTrue);
    navigator.push<void>(readerRoute);
    await tester.pump();

    expect(
      tester.widget<AnimatedSlide>(motionFinder).offset,
      const Offset(0, 1.15),
    );
    expect(
      tester.widget<AnimatedSlide>(motionFinder).curve,
      Curves.easeOutCubic,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('home-floating-navigation-pointer')),
          )
          .ignoring,
      isTrue,
    );

    await tester.pumpAndSettle();
    BookOpenTransition.beginExit();
    navigator.pop();
    await tester.pump();
    final returningMotion = tester.widget<AnimatedSlide>(motionFinder);
    expect(returningMotion.offset, Offset.zero);
    expect(returningMotion.curve, Curves.easeOutBack);
    expect(returningMotion.duration, const Duration(milliseconds: 360));
    expect(find.text('reader'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(tester.widget<AnimatedSlide>(motionFinder).offset, Offset.zero);
    expect(BookOpenTransition.hasActiveReaderActivity, isFalse);
  });

  testWidgets('reader back gesture inset changes do not move floating nav', (
    tester,
  ) async {
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final mediaQuery = ValueNotifier(
      const MediaQueryData(
        size: Size(412, 915),
        viewPadding: EdgeInsets.only(top: 24, bottom: 24),
      ),
    );
    addTearDown(mediaQuery.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppSettingsNotifier(),
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
            ),
            extensions: const [
              UiStyleThemeExtension(style: AppUiStyle.material3),
            ],
          ),
          home: ValueListenableBuilder<MediaQueryData>(
            valueListenable: mediaQuery,
            builder: (context, data, child) =>
                MediaQuery(data: data, child: child!),
            child: HomeShellPage(aiChatHistoryStore: historyStore),
          ),
        ),
      ),
    );
    await tester.pump();

    const motionKey = ValueKey('home-floating-navigation-motion');
    final motionFinder = find.byKey(motionKey, skipOffstage: false);
    expect(tester.getSize(motionFinder).height, 90);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final readerRoute = BookOpenTransition.createRoute<void>(
      (_) => const Scaffold(body: Text('reader')),
    );
    navigator.push<void>(readerRoute);
    await tester.pumpAndSettle();
    BookOpenTransition.beginExit();

    mediaQuery.value = const MediaQueryData(
      size: Size(412, 915),
      viewPadding: EdgeInsets.only(bottom: 48),
    );
    await tester.pump();
    expect(tester.getSize(motionFinder).height, 90);

    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(BookOpenTransition.hasActiveReaderActivity, isFalse);

    mediaQuery.value = const MediaQueryData(
      size: Size(412, 915),
      viewPadding: EdgeInsets.only(top: 24, bottom: 32),
    );
    await tester.pump();
    expect(tester.getSize(motionFinder).height, 98);
  });
}

class _TestAppSettingsNotifier extends AppSettingsNotifier {
  void notifyUnrelatedChange() => notifyListeners();
}
