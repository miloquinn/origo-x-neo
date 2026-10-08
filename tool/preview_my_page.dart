// flutter test --no-pub tool/preview_my_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _PreviewCacheManager extends AppCacheManager {
  @override
  Future<AppCacheUsage> usage() async => AppCacheUsage({
    for (final category in AppCacheCategory.values) category: 0,
  });
}

class _PreviewPreferencesStore implements SettingsPagePreferencesStore {
  SettingsPagePreferences value = const SettingsPagePreferences();

  @override
  Future<SettingsPagePreferences> load() async => value;

  @override
  Future<void> save(SettingsPagePreferences preferences) async {
    value = preferences;
  }
}

class _PreviewAccount extends MemberAccountController {
  bool _premium = false;

  @override
  bool get hasPremiumAccess => _premium;

  @override
  MemberAccountSummary? get summary => _premium
      ? const MemberAccountSummary(
          userId: 'preview',
          username: 'reader',
          effectiveName: '开元读者',
          premium: true,
        )
      : super.summary;

  @override
  MemberMembership? get membership => _premium
      ? const MemberMembership(premium: true, features: {}, entitlements: [])
      : super.membership;

  void setPremium(bool value) {
    _premium = value;
    notifyListeners();
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('my-page-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = Directory('docs/previews')..createSync(recursive: true);
    await File(
      '${output.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets('capture the real My page and preferences widgets', (
    tester,
  ) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Origo X',
      packageName: 'com.niki.xxread',
      version: '2.7.1',
      buildNumber: '0',
      buildSignature: '',
    );
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'MyPagePreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    final theme = ThemeNotifier();
    final settings = await tester.runAsync(() async {
      final notifier = AppSettingsNotifier();
      final ready = Completer<void>();
      void listener() {
        if (notifier.isInitialized && !ready.isCompleted) ready.complete();
      }

      notifier.addListener(listener);
      listener();
      await ready.future;
      notifier.removeListener(listener);
      return notifier;
    });
    final backup = WebDavBackupController();
    final account = _PreviewAccount();
    addTearDown(theme.dispose);
    addTearDown(settings!.dispose);
    addTearDown(backup.dispose);
    addTearDown(account.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: theme),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: backup),
          ChangeNotifierProvider<MemberAccountController>.value(value: account),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'MyPagePreview',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1768B4),
            ),
          ),
          builder: (context, child) =>
              RepaintBoundary(key: const Key('my-page-preview'), child: child!),
          home: SettingsPage(
            cacheManager: _PreviewCacheManager(),
            preferencesStore: _PreviewPreferencesStore(),
            aiService: MockAIService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'my-page-phone');

    account.setPremium(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'my-page-premium-phone');
    account.setPremium(false);
    await tester.pumpAndSettle();

    final preferences = find.byKey(
      const ValueKey('settings-category-preferences'),
    );
    await tester.ensureVisible(preferences);
    await tester.pumpAndSettle();
    await tester.tap(preferences);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'my-preferences-phone');
  });
}
