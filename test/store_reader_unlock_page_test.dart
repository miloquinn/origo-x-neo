import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
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
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );
  });
  tearDown(AppDistribution.debugReset);

  testWidgets('reader details stay in the header menu', (tester) async {
    final account = _UnlockAccount(permanent: true, authenticated: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);
    expect(find.byKey(const ValueKey('store-reader-benefits')), findsNothing);
    expect(find.byKey(const ValueKey('store-reader-details')), findsNothing);
    expect(
      find.byKey(const ValueKey('store-reader-details-menu')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('store-reader-details-menu')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('store-reader-benefits')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('store-reader-details')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final phase in [
    StorePurchasePhase.loadingProduct,
    StorePurchasePhase.productUnavailable,
  ]) {
    testWidgets('owned reader hides background product status $phase', (
      tester,
    ) async {
      final account = _UnlockAccount(
        permanent: true,
        authenticated: true,
        phase: phase,
      );
      addTearDown(account.dispose);
      await _pumpPage(tester, account);

      expect(find.byKey(const ValueKey('store-reader-active')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('store-reader-purchase-status')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('owned reader still reports a real restore failure', (
    tester,
  ) async {
    final account = _UnlockAccount(
      permanent: true,
      authenticated: true,
      phase: StorePurchasePhase.failed,
      purchaseError: '恢复购买失败',
    );
    addTearDown(account.dispose);
    await _pumpPage(tester, account);
    expect(find.text('恢复购买失败'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reader restore and redemption share a row and open redemption', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final account = _UnlockAccount(permanent: true, authenticated: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    final restore = find.byKey(const ValueKey('store-reader-restore'));
    final redeem = find.byKey(const ValueKey('store-reader-redeem-entry'));
    expect(restore.hitTestable(), findsOneWidget);
    expect(redeem.hitTestable(), findsOneWidget);
    expect(
      tester.getCenter(restore).dy,
      closeTo(tester.getCenter(redeem).dy, 1),
    );
    expect(tester.getRect(redeem).height, greaterThanOrEqualTo(48));
    final status = find.byKey(const ValueKey('store-reader-active'));
    expect(
      tester.getRect(restore).top - tester.getRect(status).bottom,
      lessThanOrEqualTo(12),
    );
    await tester.tap(redeem);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('account-redemption-code')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Apple sandbox keeps normal optional purchase actions', (
    tester,
  ) async {
    await _enableAppleBeta();
    final account = _UnlockAccount(authenticated: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(AppDistribution.isAppleTestEnvironment, isTrue);
    expect(
      find.byKey(const ValueKey('store-reader-beta-status')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('store-reader-beta-access')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('store-reader-lifetime-price')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
    expect(find.byKey(const ValueKey('store-reader-restore')), findsOneWidget);
  });

  testWidgets('complete Explore offer uses the full App Store product price', (
    tester,
  ) async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
    final account = _UnlockAccount(authenticated: true);
    addTearDown(account.dispose);
    await _pumpWidgetPage(
      tester,
      child: PremiumMembershipPage(account: account),
    );

    expect(account.hasAccountReaderUpgradeEligibility, isFalse);
    expect(find.byKey(const ValueKey('premium-store-price')), findsOneWidget);
    expect(find.text(r'$18.99'), findsOneWidget);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(PremiumMembershipPage)),
    );
    expect(find.text(l10n.premiumIncludesReaderAccess), findsWidgets);
    expect(find.text('开卷 + 探元 · 一次购买跨平台使用'), findsOneWidget);
  });

  testWidgets('owned permanent Read shows the Explore upgrade price', (
    tester,
  ) async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
    final account = _UnlockAccount(permanent: true, authenticated: true);
    addTearDown(account.dispose);
    await _pumpWidgetPage(
      tester,
      child: PremiumMembershipPage(account: account),
    );

    expect(account.hasAccountReaderUpgradeEligibility, isTrue);
    expect(find.byKey(const ValueKey('premium-store-price')), findsOneWidget);
    expect(find.text(r'$8.99'), findsOneWidget);
    expect(find.text('已拥有开卷 · 升级探元'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-apple-purchase')),
      findsOneWidget,
    );
  });

  testWidgets('guest actions open sign-in without starting store actions', (
    tester,
  ) async {
    final account = _UnlockAccount();
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsOneWidget);
    expect(find.byKey(const ValueKey('store-reader-restore')), findsOneWidget);
    expect(find.text('登录 Origo 账号并继续'), findsOneWidget);

    for (final key in const [
      ValueKey('store-reader-purchase'),
      ValueKey('store-start-trial'),
      ValueKey('store-reader-restore'),
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(AccountPage))).pop<void>();
      await tester.pumpAndSettle();
    }
    expect(account.purchaseCalls, 0);
    expect(account.restoreCalls, 0);
    expect(account.trialCalls, 0);
  });

  testWidgets(
    'free reading keeps optional account purchase but hides trial messaging',
    (tester) async {
      AppDistribution.debugOverride(
        channel: AppDistributionChannel.googlePlay,
        readerLicenseRequired: false,
      );
      final account = _UnlockAccount(
        trialExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      addTearDown(account.dispose);
      await _pumpPage(tester, account);

      expect(
        find.byKey(const ValueKey('store-reader-free-access')),
        findsNothing,
      );
      expect(find.textContaining('基础阅读目前免费开放'), findsNothing);
      expect(find.byKey(const ValueKey('store-trial-status')), findsNothing);
      expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
      expect(
        find.byKey(const ValueKey('store-reader-purchase')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('store-reader-restore')),
        findsOneWidget,
      );
      final l10n = AppLocalizations.of(
        tester.element(find.byType(StoreReaderUnlockPage)),
      );
      expect(find.text(l10n.storeReaderSignInAction), findsOneWidget);

      await _openReaderDetails(tester, const ValueKey('store-reader-details'));
      expect(find.textContaining('基础阅读目前免费开放'), findsNothing);
      expect(find.textContaining('完整本地阅读体验，一次购买长期使用'), findsNothing);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('store-reader-details-page'))),
      ).pop<void>();
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('store-reader-purchase')),
      );
      await tester.tap(find.byKey(const ValueKey('store-reader-purchase')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      expect(account.purchaseCalls, 0);
      expect(account.trialCalls, 0);
    },
  );

  testWidgets('signed-in account can purchase restore and start a trial', (
    tester,
  ) async {
    final account = _UnlockAccount(authenticated: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    for (final key in const [
      ValueKey('store-reader-purchase'),
      ValueKey('store-start-trial'),
      ValueKey('store-reader-restore'),
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await tester.pump();
    }
    expect(account.purchaseCalls, 1);
    expect(account.restoreCalls, 1);
    expect(account.trialCalls, 1);
  });

  testWidgets('direct channel uses account redemption without store actions', (
    tester,
  ) async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    final account = _UnlockAccount(authenticated: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(find.byKey(const ValueKey('store-reader-restore')), findsNothing);
    expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
    expect(find.text('我有兑换码'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('store-reader-purchase')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('account-redemption-code')),
      findsOneWidget,
    );
    expect(account.purchaseCalls, 0);
    expect(account.restoreCalls, 0);
  });

  testWidgets(
    'phone keeps Basic purchase trial and restore visible without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final account = _UnlockAccount(authenticated: true);
      addTearDown(account.dispose);
      await _pumpPage(tester, account);
      expect(find.text('Origo 开卷'), findsOneWidget);
      expect(find.text('应用解锁'), findsNothing);
      expect(
        find.byKey(const ValueKey('purchase-fixed-footer')),
        findsOneWidget,
      );
      for (final key in [
        'store-reader-purchase',
        'store-start-trial',
        'store-reader-restore',
        'store-reader-details-menu',
      ]) {
        final finder = find.byKey(ValueKey(key));
        expect(finder.hitTestable(), findsOneWidget);
        expect(tester.getRect(finder).bottom, lessThanOrEqualTo(844));
      }
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, 0);
      for (final key in [
        'store-reader-feature-ai',
        'store-reader-feature-cloud-tts',
        'store-reader-feature-comics',
        'store-reader-feature-fonts',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(find.text('AI 阅读助手'), findsOneWidget);
      expect(find.text('云端 TTS'), findsOneWidget);
      expect(find.text('漫画阅读'), findsOneWidget);
      expect(find.text('自定义字体'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('store-reader-service-cost-note')),
        findsOneWidget,
      );
      await _openReaderDetails(tester, const ValueKey('store-reader-benefits'));
      expect(
        find.byKey(const ValueKey('store-reader-benefits-page')),
        findsOneWidget,
      );
      expect(find.textContaining('第三方服务费用'), findsOneWidget);
      for (final label in ['AI 阅读助手', '云端 TTS', '漫画阅读', '自定义字体']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(account.purchaseCalls, 0);
      await tester.tap(
        find.byKey(const ValueKey('floating-subpage-back')).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('不会再次收费'), findsNothing);
      await _openReaderDetails(tester, const ValueKey('store-reader-details'));
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
    final account = _UnlockAccount(authenticated: true);
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
    final account = _UnlockAccount(
      authenticated: true,
      phase: StorePurchasePhase.verifying,
    );
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

  testWidgets('Origo Explore includes permanent Origo Read access', (
    tester,
  ) async {
    final account = _UnlockAccount(premium: true);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    expect(account.hasPremiumAccess, isTrue);
    expect(account.hasPermanentReaderAccess, isTrue);
    expect(find.byKey(const ValueKey('store-reader-purchase')), findsNothing);
    expect(find.byKey(const ValueKey('store-reader-active')), findsOneWidget);
  });

  testWidgets('purchase pages inherit and react to app accent and brightness', (
    tester,
  ) async {
    final account = _UnlockAccount(permanent: true, authenticated: true);
    addTearDown(account.dispose);
    for (final premium in [false, true]) {
      for (final dark in [false, true]) {
        for (final accent in [Colors.blue, Colors.deepOrange]) {
          final scheme = ColorScheme.fromSeed(
            seedColor: accent,
            brightness: dark ? Brightness.dark : Brightness.light,
          );
          await _pumpWidgetPage(
            tester,
            dark: dark,
            accent: accent,
            child: premium
                ? PremiumMembershipPage(account: account)
                : StoreReaderUnlockPage(account: account),
          );
          final content = premium
              ? find.byKey(const ValueKey('premium-membership-card'))
              : find.byKey(const ValueKey('store-reader-core-benefits'));
          final actual = Theme.of(tester.element(content));
          expect(actual.colorScheme, scheme);
          expect(actual.brightness, scheme.brightness);
          expect(tester.takeException(), isNull);
        }
      }
    }
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

        final ownedReaderAccount = _UnlockAccount(
          permanent: true,
          authenticated: true,
        );
        addTearDown(ownedReaderAccount.dispose);
        final ownedReaderBoundary = GlobalKey();
        await _pumpPage(
          tester,
          ownedReaderAccount,
          boundaryKey: ownedReaderBoundary,
        );
        await _precacheBrandIcon(tester, find.byType(StoreReaderUnlockPage));
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          ownedReaderBoundary,
          '$screenshotDirectory/apple-reader-owned-1290x2796.png',
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
        final fullExploreAccount = _UnlockAccount(authenticated: true);
        addTearDown(fullExploreAccount.dispose);
        final fullExploreBoundary = GlobalKey();
        await _pumpWidgetPage(
          tester,
          boundaryKey: fullExploreBoundary,
          child: PremiumMembershipPage(account: fullExploreAccount),
        );
        await _precacheBrandIcon(tester, find.byType(PremiumMembershipPage));
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          fullExploreBoundary,
          '$screenshotDirectory/apple-explore-full-1290x2796.png',
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
          final ownedKey = GlobalKey();
          await _pumpWidgetPage(
            tester,
            boundaryKey: ownedKey,
            dark: dark,
            viewPadding: const EdgeInsets.only(top: 54, bottom: 34),
            child: StoreReaderUnlockPage(account: ownedReaderAccount),
          );
          await _precacheBrandIcon(tester, find.byType(StoreReaderUnlockPage));
          await _capture(
            tester,
            ownedKey,
            '$screenshotDirectory/reader-owned-phone-${dark ? "dark" : "light"}.png',
          );

          final activeAccount = _UnlockAccount(
            permanent: true,
            authenticated: true,
            premium: true,
          );
          addTearDown(activeAccount.dispose);
          final activeKey = GlobalKey();
          await _pumpWidgetPage(
            tester,
            boundaryKey: activeKey,
            dark: dark,
            viewPadding: const EdgeInsets.only(top: 54, bottom: 34),
            child: PremiumMembershipPage(account: activeAccount),
          );
          await _precacheBrandIcon(tester, find.byType(PremiumMembershipPage));
          await _capture(
            tester,
            activeKey,
            '$screenshotDirectory/explore-owned-phone-${dark ? "dark" : "light"}.png',
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

Future<void> _openReaderDetails(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  await tester.tap(find.byKey(const ValueKey('store-reader-details-menu')));
  await tester.pumpAndSettle();
  expect(find.byKey(key).hitTestable(), findsOneWidget);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _enableAppleBeta() async {
  AppDistribution.debugOverride(channel: AppDistributionChannel.appleStore);
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  const channel = MethodChannel('com.niki.xxread/apple_purchase_support');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => 'sandbox');
  try {
    await AppDistribution.initialize();
  } finally {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
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
    account: account,
    child: StoreReaderUnlockPage(account: account),
  );
}

Future<void> _pumpWidgetPage(
  WidgetTester tester, {
  required Widget child,
  GlobalKey? boundaryKey,
  bool dark = false,
  Color accent = Colors.blue,
  bool settle = true,
  MemberAccountController? account,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  final app = MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      fontFamily: _previewFontPath == null ? null : 'SplitBillingPreview',
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: viewPadding, viewPadding: viewPadding),
      child: child!,
    ),
    home: RepaintBoundary(key: boundaryKey, child: child),
  );
  await tester.pumpWidget(
    account == null
        ? app
        : ChangeNotifierProvider<MemberAccountController>.value(
            value: account,
            child: app,
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
    this.purchaseError,
  });

  final bool permanent;
  final DateTime? trialExpiresAt;
  final bool premium;
  final bool authenticated;
  final StorePurchasePhase phase;
  final String? purchaseError;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  int trialCalls = 0;

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
  bool get hasPermanentReaderAccess => permanent || premium;

  @override
  bool get hasAccountReaderFeatureAccess =>
      permanent || premium || hasActiveReaderTrial;

  @override
  bool get hasPermanentAccountReaderFeatureAccess => permanent || premium;

  @override
  bool get readerFeaturesForDisplay => hasAccountReaderFeatureAccess;

  @override
  bool get permanentReaderFeaturesForDisplay =>
      hasPermanentAccountReaderFeatureAccess;

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
  bool get hasAccountReaderUpgradeEligibility => authenticated && permanent;

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
  ProductDetails? get premiumBundleProduct => ProductDetails(
    id: 'com.niki.xxread.explorer.lifetime',
    title: 'Origo Explore',
    description: 'Origo Read and Explore lifetime access',
    price: r'$18.99',
    rawPrice: 18.99,
    currencyCode: 'USD',
    currencySymbol: r'$',
  );

  @override
  StorePurchasePhase get readerPurchasePhase => phase;

  @override
  bool get readerPurchaseLoading => phase == StorePurchasePhase.verifying;

  @override
  String? get readerPurchaseError => purchaseError;

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
  MemberMembership? get membershipForDisplay => membership;

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
  Future<void> startReaderTrial() async {
    trialCalls += 1;
  }

  @override
  Future<void> initialize({bool force = false}) async {}

  @override
  Future<void> loadStoreProducts() async {}

  @override
  Future<void> synchronize({bool force = false}) async {}
}
