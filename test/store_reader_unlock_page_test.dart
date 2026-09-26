import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/premium_membership_page.dart';
import 'package:xxread/pages/account/store_reader_unlock_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/widgets/app_brand_icon.dart';

final _previewFontPath = Platform.environment['SPLIT_BILLING_PREVIEW_FONT'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screenshotDirectory =
      Platform.environment['SPLIT_BILLING_SCREENSHOT_DIR'];

  setUpAll(() async {
    final fontPath = _previewFontPath;
    if (fontPath != null) {
      final text = FontLoader('SplitBillingPreview');
      text.addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
      await text.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  setUp(() {
    AppDistribution.debugReset();
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
  });
  tearDown(AppDistribution.debugReset);

  testWidgets('guest can buy or restore the permanent app unlock', (
    tester,
  ) async {
    final account = _UnlockAccount();
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-restore')), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-sign-in')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('store-reader-purchase')));
    await tester.pump();
    expect(account.purchaseCalls, 1);

    await tester.tap(find.byKey(const ValueKey('store-reader-restore')));
    await tester.pump();
    expect(account.restoreCalls, 1);
  });

  testWidgets('reader trial does not expose Premium or count as ownership', (
    tester,
  ) async {
    final account = _UnlockAccount(
      trialExpiresAt: DateTime.now().add(const Duration(days: 10)),
      premium: true,
    );
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(find.byKey(const ValueKey('store-trial-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsOneWidget);
    expect(find.byKey(const ValueKey('premium-membership-card')), findsNothing);
    expect(find.text('永久高级版'), findsNothing);
  });

  testWidgets('permanent reader ownership hides duplicate purchase', (
    tester,
  ) async {
    final account = _UnlockAccount(permanent: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(find.byKey(const ValueKey('store-reader-active')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsNothing);
    expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
    expect(find.byKey(const ValueKey('store-reader-restore')), findsOneWidget);
  });

  testWidgets('Premium alone does not unlock the reader purchase page', (
    tester,
  ) async {
    final account = _UnlockAccount(premium: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(account.hasPremiumAccess, isTrue);
    expect(account.hasPermanentReaderAccess, isFalse);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-active')), findsNothing);
  });

  testWidgets(
    'exports App Store reader and Premium purchase frames when requested',
    (tester) async {
      AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
      tester.view.physicalSize = const Size(1290, 2796);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final readerAccount = _UnlockAccount();
      addTearDown(readerAccount.dispose);
      final readerBoundary = GlobalKey();
      await _pumpPage(tester, readerAccount, boundaryKey: readerBoundary);
      await _precacheBrandIcon(tester, find.byType(StoreReaderUnlockPage));
      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        readerBoundary,
        '$screenshotDirectory/apple-reader-unlock-1290x2796.png',
        pixelRatio: 3,
      );

      final premiumAccount = _UnlockAccount(
        permanent: true,
        authenticated: true,
      );
      addTearDown(premiumAccount.dispose);
      final premiumBoundary = GlobalKey();
      await _pumpWidgetPage(
        tester,
        boundaryKey: premiumBoundary,
        child: PremiumMembershipPage(account: premiumAccount),
      );
      await _precacheBrandIcon(tester, find.byType(PremiumMembershipPage));
      expect(tester.takeException(), isNull);
      await _capture(
        tester,
        premiumBoundary,
        '$screenshotDirectory/apple-premium-1290x2796.png',
        pixelRatio: 3,
      );
    },
    skip: screenshotDirectory == null,
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  MemberAccountController account, {
  GlobalKey? boundaryKey,
}) async {
  await _pumpWidgetPage(
    tester,
    boundaryKey: boundaryKey,
    child: StoreReaderUnlockPage(account: account),
  );
}

Future<void> _pumpWidgetPage(
  WidgetTester tester, {
  required Widget child,
  GlobalKey? boundaryKey,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _previewFontPath == null
          ? null
          : ThemeData(
              textTheme: ThemeData().textTheme.apply(
                fontFamily: 'SplitBillingPreview',
              ),
            ),
      home: RepaintBoundary(key: boundaryKey, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _precacheBrandIcon(WidgetTester tester, Finder page) async {
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(kAppBrandIconAsset),
      tester.element(page),
    ),
  );
  await tester.pump();
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String path, {
  double pixelRatio = 1,
}) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

class _UnlockAccount extends MemberAccountController {
  _UnlockAccount({
    this.permanent = false,
    this.trialExpiresAt,
    this.premium = false,
    this.authenticated = false,
  });

  final bool permanent;
  final DateTime? trialExpiresAt;
  final bool premium;
  final bool authenticated;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  bool get initialized => true;

  @override
  bool get isAuthenticated => authenticated;

  @override
  MemberUser? get user => authenticated
      ? MemberUser(
          id: 'preview-user',
          email: 'reader@example.com',
          emailVerified: true,
          username: 'reader',
          effectiveName: '阅读者',
          authMethods: const ['apple'],
          createdAt: DateTime.utc(2026),
        )
      : null;

  @override
  bool get hasPermanentReaderAccess => permanent;

  @override
  bool get hasActiveReaderTrial =>
      trialExpiresAt?.isAfter(DateTime.now()) == true;

  @override
  DateTime? get readerTrialExpiresAt => trialExpiresAt;

  @override
  bool get canStartReaderTrial => trialExpiresAt == null && !permanent;

  @override
  bool get hasPremiumAccess => premium;

  @override
  bool get storeBillingReady => true;

  @override
  ProductDetails? get readerLifetimeProduct => ProductDetails(
    id: 'origo_x_lifetime',
    title: 'Origo X Lifetime Unlock',
    description: 'Permanent local reading access',
    price: r'$9.99',
    rawPrice: 9.99,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );

  @override
  ProductDetails? get premiumLifetimeProduct => ProductDetails(
    id: 'origo_x_premium_lifetime',
    title: 'Origo X Premium',
    description: 'Lifetime Premium bound to your Origo account',
    price: r'$8.99',
    rawPrice: 8.99,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );

  @override
  StorePurchasePhase get readerPurchasePhase => StorePurchasePhase.idle;

  @override
  bool get readerPurchaseLoading => false;

  @override
  String? get readerPurchaseError => null;

  @override
  StorePurchasePhase get premiumPurchasePhase => StorePurchasePhase.idle;

  @override
  bool get premiumPurchaseLoading => false;

  @override
  String? get premiumPurchaseError => null;

  @override
  MemberMembership? get membership => authenticated
      ? MemberMembership(
          premium: premium,
          features: const {},
          entitlements: const [],
        )
      : null;

  @override
  MemberMembershipConfig get membershipConfig => const MemberMembershipConfig(
    product: 'premium_lifetime',
    features: [],
    storeTrialDays: 14,
  );

  @override
  Future<void> initializeStorePurchases() async {}

  @override
  Future<void> purchaseReaderLifetime() async {
    purchaseCalls += 1;
  }

  @override
  Future<void> restoreReaderPurchases() async {
    restoreCalls += 1;
  }

  @override
  Future<void> startReaderTrial() async {}

  @override
  Future<void> loadStoreProducts() async {}

  @override
  Future<void> synchronize() async {}
}
