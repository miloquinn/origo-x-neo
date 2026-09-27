import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/widgets/settings_account_card.dart';

final _screenshotDirectory = Platform.environment['PROFILE_SCREENSHOT_DIR'];
final _previewFontPath = Platform.environment['PROFILE_PREVIEW_FONT'];

class _Account extends MemberAccountController {
  bool permanent = false;
  bool premium = false;
  bool temporary = false;

  @override
  bool get hasPermanentReaderAccess => permanent;
  @override
  bool get hasPremiumAccess => premium;
  @override
  bool get hasSandboxStoreAccess => temporary;
  @override
  bool get hasActiveReaderTrial => !permanent;
  @override
  bool get isAuthenticated => true;
  @override
  MemberAccountSummary get summary => const MemberAccountSummary(
    userId: 'preview-account',
    username: 'origo_reader',
    effectiveName: 'Origo Reader',
    premium: true,
  );
  @override
  MemberMembership get membership => MemberMembership(
    premium: premium,
    features: const {},
    entitlements: const [],
  );

  void update({required bool ownsApp, required bool ownsPremium}) {
    permanent = ownsApp;
    premium = ownsPremium;
    temporary = false;
    notifyListeners();
  }

  void grantTemporaryAccess() {
    permanent = false;
    premium = false;
    temporary = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (_previewFontPath case final path?) {
      final font = FontLoader('AccountCardPreview');
      font.addFont(File(path).readAsBytes().then(ByteData.sublistView));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  for (final channel in AppDistributionChannel.values) {
    testWidgets('$channel always exposes Explore while keeping reader status', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: channel);
      addTearDown(AppDistribution.debugReset);
      final account = _Account();
      addTearDown(account.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsAccountCard(
                quiet: true,
                showMembershipSection: true,
              ),
            ),
          ),
        ),
      );
      final store = channel != AppDistributionChannel.direct;
      final reader = find.byKey(const ValueKey('settings-reader-license'));
      final upgrade = find.byKey(const ValueKey('settings-membership-entry'));
      final badge = find.byKey(
        const ValueKey('settings-account-premium-badge'),
      );
      final explore = find.byKey(
        const ValueKey('settings-explore-entitlement'),
      );
      expect(reader, store ? findsOneWidget : findsNothing);
      expect(upgrade, findsOneWidget);
      expect(explore, findsNothing);

      // Store testing access is temporary and must not impersonate ownership.
      account.grantTemporaryAccess();
      await tester.pump();
      expect(badge, findsNothing);
      expect(explore, findsNothing);
      expect(upgrade, findsOneWidget);

      // Explore includes reading, even when no separate Read purchase exists.
      account.update(ownsApp: false, ownsPremium: true);
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(badge, findsOneWidget);
      expect(explore, findsOneWidget);
      expect(find.text('Origo Explore'), findsOneWidget);
      expect(find.text('Origo Read included'), findsOneWidget);
      expect(reader, findsNothing);

      account.update(ownsApp: true, ownsPremium: false);
      await tester.pump();
      expect(upgrade, findsOneWidget);
      expect(badge, findsNothing);

      account.update(ownsApp: true, ownsPremium: true);
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(badge, findsOneWidget);
      expect(explore, findsOneWidget);
      expect(reader, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'exports the Explore account card when requested',
    (tester) async {
      AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
      addTearDown(AppDistribution.debugReset);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final account = _Account()..update(ownsApp: false, ownsPremium: true);
      addTearDown(account.dispose);
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3569A4),
              ),
              fontFamily: _previewFontPath == null
                  ? null
                  : 'AccountCardPreview',
            ),
            builder: (context, child) =>
                RepaintBoundary(key: boundaryKey, child: child),
            home: const Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: SettingsAccountCard(
                    quiet: true,
                    showMembershipSection: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final directory = Directory(_screenshotDirectory!);
      await tester.runAsync(() => directory.create(recursive: true));
      await _capture(
        tester,
        boundaryKey,
        '${directory.path}/settings-account-explore.png',
      );
      expect(tester.takeException(), isNull);
    },
    skip: _screenshotDirectory == null,
  );
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}
