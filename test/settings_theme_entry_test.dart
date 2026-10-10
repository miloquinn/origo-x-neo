import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/app_theme_page.dart';
import 'package:xxread/pages/settings/settings_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/backup/webdav_backup_controller.dart';
import 'package:xxread/services/core/core_services.dart';

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

Future<ThemeNotifier> _loadTheme() async {
  final theme = ThemeNotifier();
  if (theme.isInitialized) return theme;
  final initialized = Completer<void>();
  void listener() {
    if (theme.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  theme.addListener(listener);
  listener();
  await initialized.future;
  theme.removeListener(listener);
  return theme;
}

Future<void> _pumpPreferences(
  WidgetTester tester, {
  SettingsCategory? category = SettingsCategory.preferences,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);

  final theme = (await tester.runAsync(_loadTheme))!;
  final appSettings = AppSettingsNotifier();
  final webDav = WebDavBackupController();
  final account = MemberAccountController();
  addTearDown(theme.dispose);
  addTearDown(appSettings.dispose);
  addTearDown(webDav.dispose);
  addTearDown(account.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: theme),
        ChangeNotifierProvider<AppSettingsNotifier>.value(value: appSettings),
        ChangeNotifierProvider<WebDavBackupController>.value(value: webDav),
        ChangeNotifierProvider<MemberAccountController>.value(value: account),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          category: category,
          cacheManager: _FakeCacheManager(),
          preferencesStore: _FakePreferencesStore(),
          aiService: MockAIService(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('preferences replace the accent picker with one theme summary', (
    tester,
  ) async {
    await _pumpPreferences(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(SettingsPage)));

    expect(
      find.byKey(const ValueKey('settings-theme-gallery')),
      findsOneWidget,
    );
    expect(find.text(l10n.settingsAccentColorTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the settings theme summary opens the theme gallery', (
    tester,
  ) async {
    await _pumpPreferences(tester);
    final entry = find.byKey(const ValueKey('settings-theme-gallery'));

    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(AppThemePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My page keeps the theme entry only inside preferences', (
    tester,
  ) async {
    await _pumpPreferences(tester, category: null);
    expect(find.byKey(const ValueKey('settings-theme-gallery')), findsNothing);
    expect(find.byType(AppThemePage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
