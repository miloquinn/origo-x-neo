import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/settings_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/backup/webdav_backup_controller.dart';
import 'package:xxread/services/core/core_services.dart';

// This measures avoidable UI/IO work, not raster duration or device frame rate.
// Baseline mode retains behavior assertions and reports pre-optimization work.
const _baseline = bool.fromEnvironment('SETTINGS_PERF_BASELINE');
const _updateChannel = MethodChannel('com.niki.xxread/app_update');
int _versionReads = 0;

class _TestTheme extends ThemeNotifier {
  void ping() => notifyListeners();
}

class _TestAccount extends MemberAccountController {
  bool explore = false;

  @override
  bool get hasPremiumAccess => explore;

  @override
  bool get hasAdvancedSourceAccess => explore;

  @override
  bool get hasPermanentReaderAccess => explore;

  @override
  bool get hasStoreReaderEntitlement => false;

  void ping() => notifyListeners();

  void setExplore(bool value) {
    explore = value;
    notifyListeners();
  }
}

class _TestAppSettings extends AppSettingsNotifier {
  _TestAppSettings(_TestAccount account) : super(account: account);

  void ping() => notifyListeners();
}

class _TestBackup extends WebDavBackupController {
  bool configured = false;

  @override
  bool get isConfigured => configured;

  void progressChanged() {
    completedBytes++;
    notifyListeners();
  }

  void setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  void setConfigured(bool value) {
    configured = value;
    notifyListeners();
  }
}

class _CountingCache extends AppCacheManager {
  int reads = 0;

  @override
  Future<AppCacheUsage> usage() async {
    reads++;
    return AppCacheUsage({
      for (final category in AppCacheCategory.values) category: 0,
    });
  }
}

class _CountingPreferences implements SettingsPagePreferencesStore {
  _CountingPreferences({
    this.value = const SettingsPagePreferences(),
    this.pending,
  });

  SettingsPagePreferences value;
  final Future<SettingsPagePreferences>? pending;
  int reads = 0;
  int writes = 0;

  @override
  Future<SettingsPagePreferences> load() async {
    reads++;
    return pending ?? value;
  }

  @override
  Future<void> save(SettingsPagePreferences preferences) async {
    writes++;
    value = preferences;
  }
}

class _CountingAi extends MockAIService {
  _CountingAi({this.pending, this.fail = false});

  final Future<AIProviderSettings>? pending;
  final bool fail;
  int reads = 0;

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async {
    reads++;
    if (fail) throw StateError('AI configuration unavailable');
    return pending ?? super.loadSettings(provider);
  }
}

class _Fixture {
  _Fixture({
    required this.account,
    required this.settings,
    required this.theme,
    required this.backup,
    required this.preferences,
    required this.ai,
    required this.cache,
  });

  final _TestAccount account;
  final _TestAppSettings settings;
  final _TestTheme theme;
  final _TestBackup backup;
  final _CountingPreferences preferences;
  final _CountingAi ai;
  final _CountingCache cache;
}

Future<_Fixture> _pumpPage(
  WidgetTester tester, {
  SettingsCategory? category,
  _CountingPreferences? preferences,
  _CountingAi? ai,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 844);
  addTearDown(tester.view.reset);
  final fixture = (await tester.runAsync(() async {
    final account = _TestAccount();
    final settings = _TestAppSettings(account);
    final theme = _TestTheme();
    final backup = _TestBackup();
    for (var i = 0; i < 100 && !settings.isInitialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return _Fixture(
      account: account,
      settings: settings,
      theme: theme,
      backup: backup,
      preferences: preferences ?? _CountingPreferences(),
      ai: ai ?? _CountingAi(),
      cache: _CountingCache(),
    );
  }))!;
  addTearDown(fixture.account.dispose);
  addTearDown(fixture.settings.dispose);
  addTearDown(fixture.theme.dispose);
  addTearDown(fixture.backup.dispose);
  expect(fixture.settings.isInitialized, isTrue);
  expect(fixture.theme.isInitialized, isTrue);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>.value(value: fixture.theme),
        ChangeNotifierProvider<AppSettingsNotifier>.value(
          value: fixture.settings,
        ),
        ChangeNotifierProvider<MemberAccountController>.value(
          value: fixture.account,
        ),
        ChangeNotifierProvider<WebDavBackupController>.value(
          value: fixture.backup,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(
          category: category,
          cacheManager: fixture.cache,
          preferencesStore: fixture.preferences,
          aiService: fixture.ai,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return fixture;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SettingsPage)));

Finder _pageList() => find.descendant(
  of: find.byType(SettingsPage),
  matching: find.byType(ListView),
);

Future<int> _countWidgetUpdates(
  WidgetTester tester,
  Finder finder,
  VoidCallback notify,
) async {
  final element = tester.element(finder);
  var previous = element.widget;
  var updates = 0;
  for (var i = 0; i < 30; i++) {
    notify();
    await tester.pump();
    if (!identical(previous, element.widget)) updates++;
    previous = element.widget;
  }
  return updates;
}

Finder _switchWithTitle(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first,
  matching: find.byType(Switch),
);

Future<void> _scrollTo(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(
    find.text(title),
    350,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _versionReads = 0;
    PackageInfo.setMockInitialValues(
      appName: 'Origo X',
      packageName: 'com.niki.xxread',
      version: '2.7.2',
      buildNumber: '261008001',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_updateChannel, (_) async {
          _versionReads++;
          return '261008001';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_updateChannel, null);
  });

  for (final category in [null, ...SettingsCategory.values]) {
    final label = category?.name ?? 'hub';
    testWidgets(
      '$label isolates notifications and owned initialization',
      (tester) async {
        final fixture = await _pumpPage(tester, category: category);
        final updates = <String, int>{
          'webdav': await _countWidgetUpdates(
            tester,
            _pageList(),
            fixture.backup.progressChanged,
          ),
          'app': await _countWidgetUpdates(
            tester,
            _pageList(),
            fixture.settings.ping,
          ),
          'theme': await _countWidgetUpdates(
            tester,
            _pageList(),
            fixture.theme.ping,
          ),
        };
        final reads = <String, int>{
          'preferences': fixture.preferences.reads,
          'ai': fixture.ai.reads,
          'cache': fixture.cache.reads,
          'version': _versionReads,
        };
        debugPrint('SETTINGS_PERF $label updates=$updates reads=$reads');
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (!_baseline) {
          expect(updates, {'webdav': 0, 'app': 0, 'theme': 0});
          expect(reads, {
            'preferences': category == SettingsCategory.preferences ? 1 : 0,
            'ai': category == SettingsCategory.contentServices ? 1 : 0,
            'cache': category == SettingsCategory.dataSync ? 1 : 0,
            'version': category == SettingsCategory.aboutSupport ? 1 : 0,
          });
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }

  testWidgets(
    'data-sync hub row still reflects busy state immediately',
    (tester) async {
      final fixture = await _pumpPage(tester);
      final l10n = _l10n(tester);
      final entry = find.byKey(const ValueKey('settings-category-dataSync'));
      expect(
        find.descendant(
          of: entry,
          matching: find.text(l10n.settingsWebDavWorking),
        ),
        findsNothing,
      );
      fixture.backup.setBusy(true);
      await tester.pump();
      expect(
        find.descendant(
          of: entry,
          matching: find.text(l10n.settingsWebDavWorking),
        ),
        findsOneWidget,
      );
      final busyUpdates = await _countWidgetUpdates(
        tester,
        entry,
        fixture.backup.progressChanged,
      );
      debugPrint('SETTINGS_PERF busy-data-sync-row updates=$busyUpdates');
      if (!_baseline) expect(busyUpdates, 0);
      fixture.backup.setBusy(false);
      await tester.pump();
      expect(
        find.descendant(
          of: entry,
          matching: find.text(l10n.settingsDataSyncSubtitle),
        ),
        findsOneWidget,
      );
      fixture.backup.setConfigured(true);
      await tester.pump();
      expect(
        find.descendant(
          of: entry,
          matching: find.text(l10n.settingsWebDavConfigured),
        ),
        findsOneWidget,
      );
      fixture.backup.setConfigured(false);
      await tester.pump();
      expect(
        find.descendant(
          of: entry,
          matching: find.text(l10n.settingsDataSyncSubtitle),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'account display and global settings ignore unrelated events',
    (tester) async {
      final fixture = await _pumpPage(tester);
      var globalNotifications = 0;
      fixture.settings.addListener(() => globalNotifications++);
      final updates = await _countWidgetUpdates(
        tester,
        find.byKey(const ValueKey('settings-account-membership-group')),
        fixture.account.ping,
      );
      debugPrint(
        'SETTINGS_PERF account updates=$updates globalNotifications=$globalNotifications',
      );
      expect(
        find.byKey(const ValueKey('settings-membership-entry')),
        findsOneWidget,
      );
      if (!_baseline) {
        expect(updates, 0);
        expect(globalNotifications, 0);
      }
      fixture.account.setExplore(true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('settings-membership-entry')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings-account-premium-badge')),
        findsOneWidget,
      );
      expect(fixture.settings.advancedFeaturesUnlocked, isTrue);
      fixture.account.setExplore(false);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('settings-membership-entry')),
        findsOneWidget,
      );
      expect(fixture.settings.advancedFeaturesUnlocked, isFalse);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'content services responds to access grant and revocation',
    (tester) async {
      final fixture = await _pumpPage(
        tester,
        category: SettingsCategory.contentServices,
      );
      final l10n = _l10n(tester);
      expect(find.text(l10n.settingsSectionAdvancedFeatures), findsNothing);
      fixture.account.setExplore(true);
      await tester.pump();
      await _scrollTo(tester, l10n.settingsSectionAdvancedFeatures);
      expect(
        find.text(l10n.settingsAdditionalSourceProtocolsTitle),
        findsOneWidget,
      );
      fixture.account.setExplore(false);
      await tester.pump();
      expect(find.text(l10n.settingsSectionAdvancedFeatures), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'preferences load independently of delayed AI configuration',
    (tester) async {
      final aiResult = Completer<AIProviderSettings>();
      final ai = _CountingAi(pending: aiResult.future);
      final fixture = await _pumpPage(
        tester,
        category: SettingsCategory.preferences,
        preferences: _CountingPreferences(
          value: const SettingsPagePreferences(enableVolumeKeyTurn: true),
        ),
        ai: ai,
      );
      final title = _l10n(tester).settingsVolumeKeyTurnTitle;
      await _scrollTo(tester, title);
      final valueWhileAiPending = tester
          .widget<Switch>(_switchWithTitle(title))
          .value;
      debugPrint(
        'SETTINGS_PERF preferences AI-pending loaded=$valueWhileAiPending',
      );
      if (!_baseline) {
        expect(valueWhileAiPending, isTrue);
        expect(ai.reads, 0);
      }
      aiResult.complete(await MockAIService().loadSettings());
      await tester.pump();
      expect(tester.widget<Switch>(_switchWithTitle(title)).value, isTrue);
      expect(fixture.preferences.writes, 0);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'preferences load independently of failed AI configuration',
    (tester) async {
      final ai = _CountingAi(fail: true);
      Object? error;
      await runZonedGuarded(
        () => _pumpPage(
          tester,
          category: SettingsCategory.preferences,
          preferences: _CountingPreferences(
            value: const SettingsPagePreferences(enableVolumeKeyTurn: true),
          ),
          ai: ai,
        ),
        (caught, stack) => error = caught,
      );
      final title = _l10n(tester).settingsVolumeKeyTurnTitle;
      await _scrollTo(tester, title);
      final loaded = tester.widget<Switch>(_switchWithTitle(title)).value;
      debugPrint(
        'SETTINGS_PERF preferences AI-failed loaded=$loaded reads=${ai.reads}',
      );
      if (_baseline && error != null) {
        expect(error, isA<StateError>());
        expect(loaded, isFalse);
      } else {
        expect(error, isNull);
        expect(loaded, isTrue);
        expect(ai.reads, 0);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'page preference controls wait for their stored values',
    (tester) async {
      final loaded = Completer<SettingsPagePreferences>();
      final preferences = _CountingPreferences(pending: loaded.future);
      await _pumpPage(
        tester,
        category: SettingsCategory.preferences,
        preferences: preferences,
      );
      final glassTitle = _l10n(tester).settingsUiStyleTitle;
      expect(
        tester.widget<Switch>(_switchWithTitle(glassTitle)).onChanged,
        isNotNull,
      );
      final title = _l10n(tester).settingsVolumeKeyTurnTitle;
      await _scrollTo(tester, title);
      final control = tester.widget<Switch>(_switchWithTitle(title));
      debugPrint(
        'SETTINGS_PERF pending-preferences enabled=${control.onChanged != null}',
      );
      if (!_baseline) {
        expect(control.onChanged, isNull);
        // Move the row below the floating title before testing the row tap.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 140));
        await tester.pumpAndSettle();
        await tester.tap(find.text(title));
        await tester.pump();
      }
      expect(preferences.writes, 0);
      loaded.complete(const SettingsPagePreferences(enableVolumeKeyTurn: true));
      await tester.pump();
      await tester.pump();
      final ready = tester.widget<Switch>(_switchWithTitle(title));
      expect(ready.onChanged, isNotNull);
      expect(ready.value, isTrue);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'visible toggle preserves hidden persisted values',
    (tester) async {
      final preferences = _CountingPreferences(
        value: const SettingsPagePreferences(
          autoSaveInterval: 120,
          enableAutoExtractCover: false,
          enableDeveloperMode: true,
          enableDebugLogging: true,
          enablePerformanceMonitor: true,
          enableMemoryStats: true,
          showFPS: true,
        ),
      );
      await _pumpPage(
        tester,
        category: SettingsCategory.preferences,
        preferences: preferences,
      );
      final title = _l10n(tester).settingsAutoResumeReadingTitle;
      await _scrollTo(tester, title);
      await tester.tap(_switchWithTitle(title));
      await tester.pump();
      expect(preferences.writes, 1);
      expect(preferences.value.autoResumeReading, isTrue);
      expect(preferences.value.autoSaveInterval, 120);
      expect(preferences.value.enableAutoExtractCover, isFalse);
      expect(preferences.value.enableDeveloperMode, isTrue);
      expect(preferences.value.enableDebugLogging, isTrue);
      expect(preferences.value.enablePerformanceMonitor, isTrue);
      expect(preferences.value.enableMemoryStats, isTrue);
      expect(preferences.value.showFPS, isTrue);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'glass switch saves only its owning theme preferences',
    (tester) async {
      final fixture = await _pumpPage(
        tester,
        category: SettingsCategory.preferences,
      );
      final title = _l10n(tester).settingsUiStyleTitle;
      await tester.tap(_switchWithTitle(title));
      await tester.pump();
      debugPrint(
        'SETTINGS_PERF glass pagePreferenceWrites=${fixture.preferences.writes}',
      );
      expect(fixture.theme.isGlassEffectsEnabled, isFalse);
      if (!_baseline) expect(fixture.preferences.writes, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ui_style_mode'), 'material3');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'preferences final section mounts when scrolled into view',
    (tester) async {
      await _pumpPage(tester, category: SettingsCategory.preferences);
      final title = _l10n(tester).settingsSectionGeneral;
      final initiallyMounted = find.text(title).evaluate().length;
      debugPrint(
        'SETTINGS_PERF general-section initialMounts=$initiallyMounted',
      );
      if (!_baseline) expect(initiallyMounted, 0);
      await _scrollTo(tester, title);
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
