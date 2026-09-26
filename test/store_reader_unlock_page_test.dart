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
import 'package:xxread/widgets/purchase_artwork.dart';

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
    final purchaseIcons = FontLoader('PhosphorPurchase');
    purchaseIcons.addFont(rootBundle.load('assets/purchase/Phosphor.ttf'));
    await purchaseIcons.load();
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('store-reader-purchase')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-reader-purchase')));
    await tester.pump();
    expect(account.purchaseCalls, 1);

    await tester.ensureVisible(
      find.byKey(const ValueKey('store-reader-restore')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-reader-restore')));
    await tester.pump();
    expect(account.restoreCalls, 1);
  });

  testWidgets(
    'phone keeps Basic purchase trial and restore visible without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final account = _UnlockAccount();
      addTearDown(account.dispose);
      await _pumpPage(tester, account);
      expect(find.text('基础版购买'), findsOneWidget);
      expect(find.text('应用解锁'), findsNothing);
      expect(
        find.byKey(const ValueKey('purchase-fixed-footer')),
        findsOneWidget,
      );
      for (final key in [
        'store-reader-purchase',
        'store-start-trial',
        'store-reader-restore',
        'store-reader-details',
        'store-reader-benefits',
      ]) {
        final finder = find.byKey(ValueKey(key));
        expect(finder.hitTestable(), findsOneWidget);
        expect(tester.getRect(finder).bottom, lessThanOrEqualTo(844));
      }
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, 0);
      for (final label in ['阅读与排版', '听书与 AI', '记录与备份']) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('basic-feature-tab-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('basic-artwork-1')), findsOneWidget);
      expect(find.text('换一种方式，走进一本书。'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('basic-feature-tab-2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('basic-artwork-2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('basic-feature-tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('store-reader-benefits')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('store-reader-benefits-page')),
        findsOneWidget,
      );
      expect(find.textContaining('第三方服务费用'), findsOneWidget);
      for (final label in [
        '多格式阅读',
        '主题与字体',
        '朗读与听书',
        '云端 TTS',
        'AI 阅读助手',
        '书库与备份',
        '笔记与阅读记录',
        '开放书源',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(account.purchaseCalls, 0);
      await tester.tap(
        find.byKey(const ValueKey('floating-subpage-back')).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('不会再次收费'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('store-reader-details')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('store-reader-details-page')),
        findsOneWidget,
      );
      expect(find.textContaining('不会再次收费'), findsOneWidget);
      expect(account.purchaseCalls, 0);
      await tester.tap(
        find.byKey(const ValueKey('floating-subpage-back')).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('store-reader-purchase')));
      await tester.pump();
      expect(account.purchaseCalls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short screen and large text keep Basic actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final account = _UnlockAccount();
    addTearDown(account.dispose);
    await _pumpWidgetPage(
      tester,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.6),
        ),
        child: StoreReaderUnlockPage(account: account),
      ),
    );
    expect(
      find.byKey(const ValueKey('purchase-adaptive-scroll')),
      findsOneWidget,
    );
    final purchase = find.byKey(const ValueKey('store-reader-purchase'));
    await tester.ensureVisible(purchase);
    await tester.pumpAndSettle();
    await tester.tap(purchase);
    await tester.pump();
    expect(account.purchaseCalls, 1);
    final restore = find.byKey(const ValueKey('store-reader-restore'));
    await tester.ensureVisible(restore);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pump();
    expect(account.restoreCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification keeps live status and blocks repeated purchases', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final account = _UnlockAccount(phase: StorePurchasePhase.verifying);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('store-reader-purchase')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const ValueKey('store-reader-restore')),
          )
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const ValueKey('store-reader-purchase-status')),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('store-reader-purchase')))
          .label,
      contains('Google Play'),
    );
    expect(account.purchaseCalls, 0);
    expect(tester.takeException(), isNull);
    semantics.dispose();
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
      final previousShadows = debugDisableShadows;
      debugDisableShadows = false;
      try {
        AppDistribution.debugOverride(
          channel: AppDistributionChannel.appleStore,
        );
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
        AppDistribution.debugOverride(
          channel: AppDistributionChannel.googlePlay,
        );
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        for (final dark in [false, true]) {
          final basicKey = GlobalKey();
          await _pumpWidgetPage(
            tester,
            boundaryKey: basicKey,
            dark: dark,
            child: StoreReaderUnlockPage(account: readerAccount),
          );
          await _precacheBrandIcon(tester, find.byType(StoreReaderUnlockPage));
          await _capture(
            tester,
            basicKey,
            '$screenshotDirectory/basic-phone-${dark ? "dark" : "light"}.png',
          );
          if (!dark) {
            for (final scene in [1, 2]) {
              await tester.tap(
                find.byKey(ValueKey('basic-feature-tab-$scene')),
              );
              await tester.pumpAndSettle();
              await _precacheBrandIcon(
                tester,
                find.byType(StoreReaderUnlockPage),
              );
              await _capture(
                tester,
                basicKey,
                '$screenshotDirectory/basic-scene-$scene.png',
              );
            }
          }
          final premiumKey = GlobalKey();
          await _pumpWidgetPage(
            tester,
            boundaryKey: premiumKey,
            dark: dark,
            child: PremiumMembershipPage(account: premiumAccount),
          );
          await _precacheBrandIcon(tester, find.byType(PremiumMembershipPage));
          await _capture(
            tester,
            premiumKey,
            '$screenshotDirectory/premium-phone-${dark ? "dark" : "light"}.png',
          );
          expect(tester.takeException(), isNull);
        }
      } finally {
        debugDisableShadows = previousShadows;
      }
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
    settle: !account.readerPurchaseLoading,
    child: StoreReaderUnlockPage(account: account),
  );
}

Future<void> _pumpWidgetPage(
  WidgetTester tester, {
  required Widget child,
  GlobalKey? boundaryKey,
  bool dark = false,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        fontFamily: _previewFontPath == null ? null : 'SplitBillingPreview',
      ),
      home: RepaintBoundary(key: boundaryKey, child: child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _precacheBrandIcon(WidgetTester tester, Finder page) async {
  await tester.runAsync(() async {
    for (final asset in [kAppBrandIconAsset, ...PurchaseArtwork.imageAssets]) {
      await precacheImage(AssetImage(asset), tester.element(page));
    }
  });
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
    this.phase = StorePurchasePhase.idle,
  });

  final bool permanent;
  final DateTime? trialExpiresAt;
  final bool premium;
  final bool authenticated;
  final StorePurchasePhase phase;
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
  StorePurchasePhase get readerPurchasePhase => phase;

  @override
  bool get readerPurchaseLoading => phase == StorePurchasePhase.verifying;

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
