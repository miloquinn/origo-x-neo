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
import 'package:xxread/widgets/membership_offer_card.dart';

final _screenshotDirectory = Platform.environment['PROFILE_SCREENSHOT_DIR'];
final _previewFontPath = Platform.environment['PROFILE_PREVIEW_FONT'];

class _Account extends MemberAccountController {
  bool permanent = false;
  bool premium = false;
  bool readerEntitlement = false;
  bool temporary = false;

  @override
  bool get hasPermanentReaderAccess => permanent;
  @override
  bool get hasPremiumAccess => premium;
  @override
  bool get hasStoreReaderEntitlement => readerEntitlement;
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

  void update({
    required bool ownsApp,
    required bool ownsPremium,
    bool ownsReaderEntitlement = false,
  }) {
    permanent = ownsApp;
    premium = ownsPremium;
    readerEntitlement = ownsReaderEntitlement;
    temporary = false;
    notifyListeners();
  }

  void grantTemporaryAccess() {
    permanent = false;
    premium = false;
    readerEntitlement = false;
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
    testWidgets('$channel shows exactly one next membership step', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: channel);
      addTearDown(AppDistribution.debugReset);
      final store = channel != AppDistributionChannel.direct;
      final account = _Account()..update(ownsApp: !store, ownsPremium: false);
      addTearDown(account.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SettingsAccountCard()),
          ),
        ),
      );
      final reader = find.byKey(const ValueKey('settings-reader-license'));
      final upgrade = find.byKey(const ValueKey('settings-membership-entry'));
      final readerBadge = find.byKey(
        const ValueKey('settings-account-reader-badge'),
      );
      final exploreBadge = find.byKey(
        const ValueKey('settings-account-premium-badge'),
      );
      final explore = find.byKey(
        const ValueKey('settings-explore-entitlement'),
      );
      expect(reader, store ? findsOneWidget : findsNothing);
      expect(upgrade, store ? findsNothing : findsOneWidget);
      expect(explore, findsNothing);
      // The direct build is free to use; free access is not a paid Read badge.
      expect(readerBadge, findsNothing);
      expect(exploreBadge, findsNothing);

      // Store testing access is temporary and must not impersonate ownership.
      account.grantTemporaryAccess();
      await tester.pump();
      expect(readerBadge, findsNothing);
      expect(exploreBadge, findsNothing);
      expect(explore, findsNothing);
      expect(reader, store ? findsOneWidget : findsNothing);
      expect(upgrade, store ? findsNothing : findsOneWidget);

      // Explore includes reading, even when no separate Read purchase exists.
      account.update(ownsApp: false, ownsPremium: true);
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(readerBadge, findsNothing);
      expect(exploreBadge, findsOneWidget);
      expect(tester.widget<Text>(exploreBadge).data, 'Origo Explore');
      expect(explore, findsNothing);
      expect(
        find.byKey(const ValueKey('settings-membership-offer')),
        findsNothing,
      );
      expect(reader, findsNothing);

      account.update(
        ownsApp: true,
        ownsPremium: false,
        ownsReaderEntitlement: !store,
      );
      await tester.pump();
      expect(upgrade, findsOneWidget);
      expect(reader, findsNothing);
      expect(readerBadge, findsOneWidget);
      expect(tester.widget<Text>(readerBadge).data, 'Origo Read');
      expect(exploreBadge, findsNothing);

      account.update(
        ownsApp: true,
        ownsPremium: true,
        ownsReaderEntitlement: true,
      );
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(readerBadge, findsNothing);
      expect(exploreBadge, findsOneWidget);
      expect(tester.widget<Text>(exploreBadge).data, 'Origo Explore');
      expect(explore, findsNothing);
      expect(reader, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final reducedMotion in [false, true]) {
    testWidgets('paper entrance respects reduced motion: $reducedMotion', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: Scaffold(
              body: MembershipOfferCard(offerRead: true, onTap: () {}),
            ),
          ),
        ),
      );
      final art = find.byKey(const ValueKey('membership-paper-art'));
      final first = tester.widget<CustomPaint>(art).painter!;
      await tester.pump(const Duration(milliseconds: 500));
      final middle = tester.widget<CustomPaint>(art).painter!;
      expect(middle.shouldRepaint(first), !reducedMotion);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  for (final layout in [
    (name: 'read', read: false, explore: false, dark: false, scale: 1.0),
    (name: 'upgrade', read: true, explore: false, dark: false, scale: 1.0),
    (name: 'explore', read: true, explore: true, dark: false, scale: 1.0),
    (name: 'dark', read: true, explore: false, dark: true, scale: 1.0),
    (name: 'large', read: true, explore: false, dark: false, scale: 1.6),
    (name: 'explore-dark', read: true, explore: true, dark: true, scale: 1.0),
    (name: 'explore-large', read: true, explore: true, dark: false, scale: 1.6),
    (name: 'english', read: true, explore: false, dark: false, scale: 1.6),
    (name: 'german', read: false, explore: false, dark: false, scale: 1.0),
  ]) {
    testWidgets('separate account and illustrated membership ${layout.name}', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
      addTearDown(AppDistribution.debugReset);
      tester.view.physicalSize = Size(layout.scale > 1 ? 320 : 390, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final account = _Account()
        ..update(ownsApp: layout.read, ownsPremium: layout.explore);
      addTearDown(account.dispose);
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: MaterialApp(
            locale: Locale(switch (layout.name) {
              'english' => 'en',
              'german' => 'de',
              _ => 'zh',
            }),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: layout.dark
                    ? const Color(0xFF8859BA)
                    : const Color(0xFF3569A4),
                brightness: layout.dark ? Brightness.dark : Brightness.light,
              ),
              fontFamily: _previewFontPath == null
                  ? null
                  : 'AccountCardPreview',
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(layout.scale)),
              child: RepaintBoundary(key: boundaryKey, child: child),
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: SettingsAccountCard(),
              ),
            ),
          ),
        ),
      );
      if (_screenshotDirectory != null && layout.name == 'read') {
        final path = _screenshotDirectory!;
        await tester.runAsync(() => Directory(path).create(recursive: true));
        for (var frame = 0; frame <= 20; frame++) {
          if (frame > 0) await tester.pump(const Duration(milliseconds: 70));
          await _capture(
            tester,
            boundaryKey,
            '$path/opening-${frame.toString().padLeft(2, '0')}.png',
          );
        }
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final panel = find.byKey(const ValueKey('settings-account-panel'));
      final offer = find.byKey(const ValueKey('settings-membership-offer'));
      final readerBadge = find.byKey(
        const ValueKey('settings-account-reader-badge'),
      );
      final exploreBadge = find.byKey(
        const ValueKey('settings-account-premium-badge'),
      );
      expect(panel, findsOneWidget);
      if (layout.explore) {
        expect(offer, findsNothing);
        expect(readerBadge, findsNothing);
        expect(exploreBadge, findsOneWidget);
      } else {
        expect(offer, findsOneWidget);
        expect(exploreBadge, findsNothing);
        expect(readerBadge, layout.read ? findsOneWidget : findsNothing);
        expect(tester.getTopLeft(panel).dx, tester.getTopLeft(offer).dx);
        expect(tester.getSize(panel).width, tester.getSize(offer).width);
        expect(
          tester.getTopLeft(offer).dy - tester.getBottomLeft(panel).dy,
          closeTo(14, 0.001),
        );
      }
      // Entrance motion finishes; the account hub must not animate forever.
      expect(tester.binding.transientCallbackCount, 0);
      if (_screenshotDirectory case final path?) {
        await tester.runAsync(() => Directory(path).create(recursive: true));
        await _capture(tester, boundaryKey, '$path/account-${layout.name}.png');
      }
    });
  }
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
