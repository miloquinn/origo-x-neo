import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/settings_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/core/core_services.dart';
import 'package:xxread/utils/ui_style.dart';

class _FakeCacheManager extends AppCacheManager {
  @override
  Future<AppCacheUsage> usage() async => AppCacheUsage({
    for (final category in AppCacheCategory.values) category: 0,
  });
}

class _FakePreferencesStore implements SettingsPagePreferencesStore {
  @override
  Future<SettingsPagePreferences> load() async =>
      const SettingsPagePreferences();

  @override
  Future<void> save(SettingsPagePreferences preferences) async {}
}

Future<ThemeNotifier> _loadThemeNotifier() async {
  final notifier = ThemeNotifier();
  if (notifier.isInitialized) return notifier;

  final initialized = Completer<void>();
  void listener() {
    if (notifier.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  notifier.addListener(listener);
  listener();
  await initialized.future;
  notifier.removeListener(listener);
  return notifier;
}

Future<ThemeNotifier> _pumpGlassSettings(
  WidgetTester tester, {
  Size surfaceSize = const Size(390, 900),
  double textScaleFactor = 1,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = surfaceSize;
  addTearDown(tester.view.reset);

  final theme = await _loadThemeNotifier();
  final appSettings = AppSettingsNotifier();
  addTearDown(theme.dispose);
  addTearDown(appSettings.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: appSettings),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
        home: SettingsPage(
          category: SettingsCategory.preferences,
          cacheManager: _FakeCacheManager(),
          preferencesStore: _FakePreferencesStore(),
          aiService: MockAIService(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return theme;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('glass style is visible only while glass effects are enabled', (
    tester,
  ) async {
    final theme = await _pumpGlassSettings(tester);

    expect(find.byKey(const ValueKey('settings-glass-style')), findsOneWidget);

    await theme.setGlassEffectsEnabled(false);
    await tester.pump();
    expect(find.byKey(const ValueKey('settings-glass-style')), findsNothing);

    await theme.setGlassEffectsEnabled(true);
    await tester.pump();
    expect(find.byKey(const ValueKey('settings-glass-style')), findsOneWidget);
  });

  testWidgets('selecting liquid glass applies immediately and closes picker', (
    tester,
  ) async {
    final theme = await _pumpGlassSettings(tester);

    await tester.tap(find.text('玻璃样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('glass-style-liquid')));
    await tester.pumpAndSettle();

    expect(theme.glassStyle, GlassStyle.liquid);
    expect(find.byKey(const ValueKey('glass-style-liquid')), findsNothing);
    expect(find.text('液态玻璃'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-liquid-glass-opacity')),
      findsOneWidget,
    );
  });

  testWidgets('liquid opacity is visible only for enabled liquid glass', (
    tester,
  ) async {
    final theme = await _pumpGlassSettings(tester);
    final setting = find.byKey(const ValueKey('settings-liquid-glass-opacity'));

    expect(setting, findsNothing);
    await theme.setGlassStyle(GlassStyle.liquid);
    await tester.pump();
    expect(setting, findsOneWidget);

    await theme.setGlassEffectsEnabled(false);
    await tester.pump();
    expect(setting, findsNothing);

    await theme.setGlassEffectsEnabled(true);
    await theme.setGlassStyle(GlassStyle.frosted);
    await tester.pump();
    expect(setting, findsNothing);
  });

  testWidgets('physical right on the slider increases opacity in RTL', (
    tester,
  ) async {
    final theme = await _pumpGlassSettings(
      tester,
      textDirection: TextDirection.rtl,
    );
    await theme.setGlassStyle(GlassStyle.liquid);
    await tester.pump();

    final sliderFinder = find.byKey(
      const ValueKey('liquid-glass-opacity-slider'),
    );
    final sliderRect = tester.getRect(sliderFinder);
    await tester.tapAt(Offset(sliderRect.left + 36, sliderRect.center.dy));
    await tester.pump();
    final leftValue = theme.liquidGlassOpacity;

    await tester.tapAt(Offset(sliderRect.right - 36, sliderRect.center.dy));
    await tester.pump();

    expect(theme.liquidGlassOpacity, greaterThan(leftValue));
    expect(tester.widget<Slider>(sliderFinder).value, theme.liquidGlassOpacity);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble('liquid_glass_opacity'),
      closeTo(theme.liquidGlassOpacity, 0.001),
    );
  });

  testWidgets('hiding liquid opacity preserves its selected value', (
    tester,
  ) async {
    final theme = await _pumpGlassSettings(tester);
    await theme.setGlassStyle(GlassStyle.liquid);
    await theme.setLiquidGlassOpacity(0.68);
    await tester.pump();

    await theme.setGlassEffectsEnabled(false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('settings-liquid-glass-opacity')),
      findsNothing,
    );
    expect(theme.liquidGlassOpacity, closeTo(0.68, 0.001));

    await theme.setGlassEffectsEnabled(true);
    await theme.setGlassStyle(GlassStyle.frosted);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('settings-liquid-glass-opacity')),
      findsNothing,
    );
    expect(theme.liquidGlassOpacity, closeTo(0.68, 0.001));

    await theme.setGlassStyle(GlassStyle.liquid);
    await tester.pump();
    expect(
      tester
          .widget<Slider>(
            find.byKey(const ValueKey('liquid-glass-opacity-slider')),
          )
          .value,
      closeTo(0.68, 0.001),
    );
  });

  testWidgets('glass style picker fits a small screen with large text', (
    tester,
  ) async {
    await _pumpGlassSettings(
      tester,
      surfaceSize: const Size(320, 640),
      textScaleFactor: 2,
    );

    await tester.tap(find.text('玻璃样式'));
    await tester.pumpAndSettle();

    expect(find.text('毛玻璃'), findsWidgets);
    expect(find.text('液态玻璃'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('glass-style-liquid')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-liquid-glass-opacity')),
      findsOneWidget,
    );
    expect(find.text('通透'), findsOneWidget);
    expect(find.text('更不透明'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
