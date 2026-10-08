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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScaleFactor),
            disableAnimations: true,
          ),
          child: child!,
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
    expect(tester.takeException(), isNull);
  });
}
