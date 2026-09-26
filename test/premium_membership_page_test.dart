import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/premium_membership_page.dart';
import 'package:xxread/pages/account/premium_policy_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/widgets/app_brand_icon.dart';
import 'package:xxread/widgets/purchase_page_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screenshotDirectory = Platform.environment['PREMIUM_SCREENSHOT_DIR'];

  setUp(AppDistribution.debugReset);

  for (final ready in [true, false]) {
    testWidgets('Google Play shows only native payment actions, ready=$ready', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
      final store = _FakeAppleStore();
      final account = _TestAccount(
        store: store,
        billingReady: ready,
        offerTrial: true,
      );
      addTearDown(account.dispose);
      addTearDown(store.close);
      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-google-purchase')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-google-restore')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('store-start-trial')), findsNothing);
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsNothing,
      );
      expect(
        find.text('商店购买暂未开放，请稍后重试。已有权益不受影响。'),
        ready ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('store Premium stays hidden until the app is permanently owned', (
    tester,
  ) async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store, permanentReader: false);
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('store-reader-license-page')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('premium-membership-card')), findsNothing);
    expect(find.byKey(const ValueKey('account-google-purchase')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('owned store app keeps Premium sign-in action in the footer', (
    tester,
  ) async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store, authenticated: false);
    addTearDown(account.dispose);
    addTearDown(store.close);

    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('purchase-fixed-footer')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('premium-sign-in')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('account-google-purchase')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  tearDown(() {
    AppDistribution.debugReset();
    _resetPlatform();
  });

  setUpAll(() async {
    if (screenshotDirectory == null) return;
    final fontPath = Platform.environment['PREMIUM_PREVIEW_FONT'];
    if (fontPath != null) {
      final text = FontLoader('PremiumPreview');
      text.addFont(File(fontPath).readAsBytes().then(ByteData.sublistView));
      await text.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('active trial shows expiration and can redeem another code', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.android);
    final store = _FakeAppleStore();
    final account = _TestAccount(
      store: store,
      premium: true,
      source: 'promotion',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();
    expect(find.text('高级版体验'), findsOneWidget);
    expect(find.textContaining('高级版体验有效至'), findsWidgets);
    expect(
      find.byKey(const ValueKey('account-redemption-code')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-redeem-premium')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    _resetPlatform();
  });

  for (final source in ['admin', 'card', 'apple']) {
    testWidgets('existing $source member sees channel and retains restore', (
      tester,
    ) async {
      _usePlatform(TargetPlatform.iOS);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store, premium: true, source: source);
      addTearDown(account.dispose);
      addTearDown(store.close);
      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();
      expect(
        find.text(switch (source) {
          'admin' => '你已获赠高级会员，无需重复购买。',
          'card' => '你已通过其他渠道开通高级会员，无需重复购买。',
          _ => '你已通过 App Store 开通高级会员，无需重复购买。',
        }),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-apple-restore')),
        findsOneWidget,
      );
      _resetPlatform();
    });
  }

  testWidgets(
    'shows localized App Store price and the real premium benefits on iOS',
    (tester) async {
      _usePlatform(TargetPlatform.iOS);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);

      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();

      expect(find.text('¥28.00'), findsOneWidget);
      expect(find.text('更多书源协议'), findsOneWidget);
      expect(find.textContaining('局域网'), findsOneWidget);
      await _tapVisible(tester, const ValueKey('premium-benefits-details'));
      expect(find.byType(PurchaseDetailsPage), findsOneWidget);
      expect(find.text('会员不提供书籍内容或书源地址，第三方服务可能另行收费。'), findsOneWidget);
      Navigator.of(
        tester.element(find.byType(PurchaseDetailsPage)),
      ).pop<void>();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-apple-restore')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsOneWidget,
      );
      _resetPlatform();
    },
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('direct entry reveals billing actions on $platform', (
      tester,
    ) async {
      _usePlatform(platform);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);

      await _pumpPage(tester, account: account, focusBilling: true);
      await tester.pumpAndSettle();
      final action = platform == TargetPlatform.iOS
          ? const ValueKey('account-apple-purchase')
          : const ValueKey('account-redemption-code');
      expect(
        find.byKey(const ValueKey('purchase-fixed-footer')),
        findsOneWidget,
      );
      expect(find.byKey(action).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      _resetPlatform();
    });
  }

  testWidgets('focusBilling reveals the footer in adaptive direct layout', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.android);
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 600);
    addTearDown(tester.view.reset);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);

    await _pumpPage(tester, account: account, focusBilling: true);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('purchase-adaptive-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-redemption-code')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    _resetPlatform();
  });

  testWidgets(
    'keeps restore but removes refund actions for an active iOS member',
    (tester) async {
      _usePlatform(TargetPlatform.iOS);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store, premium: true);
      addTearDown(account.dispose);
      addTearDown(store.close);

      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('premium-active')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-apple-restore')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('premium-refund')), findsNothing);
      expect(find.byKey(const ValueKey('premium-apple-support')), findsNothing);
      expect(find.text('申请退款'), findsNothing);
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsNothing,
      );
      _resetPlatform();
    },
  );

  testWidgets(
    'macOS website builds keep redemption instead of App Store purchase',
    (tester) async {
      _usePlatform(TargetPlatform.macOS);
      AppDistribution.debugOverride(usesAppleBilling: false);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);
      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-redeem-premium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('account-apple-restore')), findsNothing);
      expect(find.byKey(const ValueKey('premium-eula-link')), findsNothing);
      _resetPlatform();
    },
  );

  testWidgets(
    'macOS App Store builds keep store actions without refund entry points',
    (tester) async {
      _usePlatform(TargetPlatform.macOS);
      AppDistribution.debugOverride(usesAppleBilling: true);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);
      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();
      expect(find.text('¥28.00'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-apple-restore')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('premium-refund')), findsNothing);
      expect(find.byKey(const ValueKey('premium-apple-support')), findsNothing);
      expect(find.byKey(const ValueKey('premium-eula-link')), findsNothing);
      await _tapVisible(tester, const ValueKey('premium-purchase-details'));
      expect(find.byKey(const ValueKey('premium-eula-link')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsNothing,
      );
      _resetPlatform();
    },
  );

  testWidgets(
    'keeps restore available when the App Store product query fails',
    (tester) async {
      _usePlatform(TargetPlatform.iOS);
      final store = _FakeAppleStore(productAvailable: false);
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);

      await _pumpPage(tester, account: account);
      await tester.pumpAndSettle();

      expect(find.text('商品信息加载失败，点击重试'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-apple-restore')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-apple-purchase')),
        findsOneWidget,
      );
      _resetPlatform();
    },
  );

  testWidgets('opens complete membership terms without a network request', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.iOS);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();

    await _tapVisible(tester, const ValueKey('premium-purchase-details'));
    expect(find.byType(PurchaseDetailsPage), findsOneWidget);
    await _tapVisible(tester, const ValueKey('premium-terms-link'));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PremiumPolicyPage && widget.policy == PremiumPolicy.terms,
      ),
      findsOneWidget,
    );
    expect(find.text('账号与权益'), findsOneWidget);
    expect(find.text('申请退款'), findsOneWidget);
    _resetPlatform();
  });

  testWidgets('opens complete privacy disclosures without a network request', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.iOS);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();

    await _tapVisible(tester, const ValueKey('premium-purchase-details'));
    expect(find.byType(PurchaseDetailsPage), findsOneWidget);
    await _tapVisible(tester, const ValueKey('premium-privacy-link'));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PremiumPolicyPage &&
            widget.policy == PremiumPolicy.privacy,
      ),
      findsOneWidget,
    );
    expect(find.text('账号服务'), findsOneWidget);
    expect(find.text('购买与验证数据'), findsOneWidget);
    _resetPlatform();
  });

  testWidgets('preserves redemption-code access on Android', (tester) async {
    _usePlatform(TargetPlatform.android);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);

    await _pumpPage(tester, account: account);

    expect(
      find.byKey(const ValueKey('account-redemption-code')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-redeem-premium')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('account-apple-restore')), findsNothing);
    expect(find.byKey(const ValueKey('premium-eula-link')), findsNothing);
    _resetPlatform();
  });

  testWidgets('active Android membership has no empty purchase panel', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.android);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store, premium: true);
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('premium-active')), findsOneWidget);
    expect(find.text('购买说明'), findsNothing);
    expect(find.byKey(const ValueKey('account-redemption-code')), findsNothing);
    expect(
      find.byKey(const ValueKey('premium-purchase-details')),
      findsOneWidget,
    );
    _resetPlatform();
  });

  testWidgets('reports an Apple purchase that is waiting for approval', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.iOS);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);
    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      store.emit(PurchaseStatus.pending);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();

    expect(find.text('正在等待 Apple 批准。批准并验证后会自动解锁。'), findsOneWidget);
    _resetPlatform();
  });

  testWidgets('lays out narrow large-text dark mode without overflow', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.iOS);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);

    await _pumpPage(
      tester,
      account: account,
      themeMode: ThemeMode.dark,
      textScaler: const TextScaler.linear(1.5),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('purchase-adaptive-scroll')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('account-apple-purchase')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('account-apple-purchase')).hitTestable(),
      findsOneWidget,
    );
    _resetPlatform();
  });

  testWidgets('direct redemption remains reachable above the keyboard', (
    tester,
  ) async {
    _usePlatform(TargetPlatform.android);
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = _FakeAppleStore();
    final account = _TestAccount(store: store);
    addTearDown(account.dispose);
    addTearDown(store.close);

    await _pumpPage(tester, account: account);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final code = find.byKey(const ValueKey('account-redemption-code'));
    await tester.ensureVisible(code);
    await tester.enterText(code, 'PREMIUM-TEST-CODE');
    final redeem = find.byKey(const ValueKey('account-redeem-premium'));
    await tester.ensureVisible(redeem);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('purchase-adaptive-scroll')),
      findsOneWidget,
    );
    expect(redeem.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    _resetPlatform();
  });

  for (final premium in [false, true]) {
    testWidgets(
      'German large text fits the ${premium ? 'active' : 'busy'} footer',
      (tester) async {
        _usePlatform(TargetPlatform.iOS);
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final store = _FakeAppleStore();
        final account = _TestAccount(
          store: store,
          premium: premium,
          purchaseLoadingOverride: !premium,
          purchasePhaseOverride: premium
              ? StorePurchasePhase.purchased
              : StorePurchasePhase.purchasing,
        );
        addTearDown(account.dispose);
        addTearDown(store.close);

        await _pumpPage(
          tester,
          account: account,
          locale: const Locale('de'),
          textScaler: const TextScaler.linear(1.5),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final target = find.byKey(
          ValueKey(
            premium ? 'premium-active-footer' : 'account-apple-purchase',
          ),
        );
        await tester.ensureVisible(target);
        await tester.pump();

        expect(target.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        _resetPlatform();
      },
    );
  }

  testWidgets(
    'exports the phone light membership review image when requested',
    (tester) async {
      _usePlatform(TargetPlatform.iOS);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store);
      addTearDown(account.dispose);
      addTearDown(store.close);
      final previewKey = GlobalKey();

      await _pumpPage(
        tester,
        account: account,
        previewKey: previewKey,
        previewFont: true,
      );
      await tester.pumpAndSettle();
      await _loadBrandIcon(tester);
      await _capture(
        tester,
        previewKey,
        '$screenshotDirectory/premium-membership-phone-light.png',
      );
      await _tapVisible(tester, const ValueKey('premium-purchase-details'));
      await _capture(
        tester,
        previewKey,
        '$screenshotDirectory/premium-membership-phone-purchase-light.png',
      );
      _resetPlatform();
    },
    skip: screenshotDirectory == null,
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'exports active phone membership in ${mode.name}',
      (tester) async {
        _usePlatform(TargetPlatform.iOS);
        addTearDown(_resetPlatform);
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = _FakeAppleStore();
        final account = _TestAccount(store: store, premium: true);
        addTearDown(account.dispose);
        addTearDown(store.close);
        final previewKey = GlobalKey();
        await _pumpPage(
          tester,
          account: account,
          previewKey: previewKey,
          previewFont: true,
          themeMode: mode,
        );
        await tester.pumpAndSettle();
        await _loadBrandIcon(tester);
        expect(tester.takeException(), isNull);
        await _capture(
          tester,
          previewKey,
          '$screenshotDirectory/premium-active-phone-${mode.name}.png',
        );
        _resetPlatform();
      },
      skip: screenshotDirectory == null,
    );
  }

  testWidgets(
    'exports the tablet dark membership review image when requested',
    (tester) async {
      _usePlatform(TargetPlatform.iOS);
      tester.view.physicalSize = const Size(1180, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _FakeAppleStore();
      final account = _TestAccount(store: store, premium: true);
      addTearDown(account.dispose);
      addTearDown(store.close);
      final previewKey = GlobalKey();

      await _pumpPage(
        tester,
        account: account,
        themeMode: ThemeMode.dark,
        previewKey: previewKey,
        previewFont: true,
      );
      await tester.pumpAndSettle();
      await _loadBrandIcon(tester);
      await _capture(
        tester,
        previewKey,
        '$screenshotDirectory/premium-membership-tablet-dark.png',
      );
      _resetPlatform();
    },
    skip: screenshotDirectory == null,
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required MemberAccountController account,
  bool focusBilling = false,
  ThemeMode themeMode = ThemeMode.light,
  TextScaler textScaler = TextScaler.noScaling,
  GlobalKey? previewKey,
  bool previewFont = false,
  Locale locale = const Locale('zh'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _theme(Brightness.light, previewFont: previewFont),
      darkTheme: _theme(Brightness.dark, previewFont: previewFont),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: RepaintBoundary(
        key: previewKey,
        child: PremiumMembershipPage(
          account: account,
          focusBilling: focusBilling,
        ),
      ),
    ),
  );
}

Future<void> _tapVisible(WidgetTester tester, ValueKey<String> key) async {
  await _scrollVisible(tester, key);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _scrollVisible(WidgetTester tester, ValueKey<String> key) async {
  final target = find.byKey(key);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void _usePlatform(TargetPlatform platform) {
  debugDefaultTargetPlatformOverride = platform;
}

void _resetPlatform() => debugDefaultTargetPlatformOverride = null;

ThemeData _theme(Brightness brightness, {required bool previewFont}) {
  final theme = ThemeData(brightness: brightness);
  if (!previewFont) return theme;
  const previewStyle = TextStyle(fontFamily: 'PremiumPreview');
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'PremiumPreview'),
    cupertinoOverrideTheme: const CupertinoThemeData(
      textTheme: CupertinoTextThemeData(
        textStyle: previewStyle,
        actionTextStyle: previewStyle,
        navActionTextStyle: previewStyle,
        navTitleTextStyle: previewStyle,
      ),
    ),
  );
}

Future<void> _loadBrandIcon(WidgetTester tester) async {
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(kAppBrandIconAsset),
      tester.element(find.byType(PremiumMembershipPage)),
    ),
  );
  await tester.pump();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

class _TestAccount extends MemberAccountController {
  _TestAccount({
    required PurchaseStore store,
    this.premium = false,
    this.source,
    this.expiresAt,
    this.billingReady = true,
    this.offerTrial = false,
    this.permanentReader = true,
    this.authenticated = true,
    this.purchaseLoadingOverride,
    this.purchasePhaseOverride,
  }) : super(purchaseStore: store);

  final bool premium;
  final String? source;
  final DateTime? expiresAt;
  final bool billingReady;
  final bool offerTrial;
  final bool permanentReader;
  final bool authenticated;
  final bool? purchaseLoadingOverride;
  final StorePurchasePhase? purchasePhaseOverride;

  @override
  bool get hasPermanentReaderAccess => permanentReader;

  @override
  bool get premiumPurchaseLoading =>
      purchaseLoadingOverride ?? super.premiumPurchaseLoading;

  @override
  StorePurchasePhase get premiumPurchasePhase =>
      purchasePhaseOverride ?? super.premiumPurchasePhase;

  @override
  MemberMembershipConfig get membershipConfig => MemberMembershipConfig(
    product: 'premium_lifetime',
    features: const [],
    googleProductId: MemberAccountController.appleProductId,
    premiumGoogleProductId: MemberAccountController.appleProductId,
    premiumAppleProductId: MemberAccountController.appleProductId,
    appleTrialProductId: 'trial.14days',
    googleBillingEnabled: billingReady,
    appleBillingEnabled: billingReady,
    storeTrialEnabled: offerTrial,
  );

  @override
  MemberMembership get membership => MemberMembership(
    premium: premium,
    features: const {},
    entitlements: [
      if (source != null)
        MemberEntitlement(
          featureKey: 'premium',
          source: source!,
          status: 'active',
          grantedAt: _createdAt,
          expiresAt: expiresAt,
        ),
    ],
  );

  @override
  bool get isAuthenticated => authenticated;

  @override
  bool get hasPremiumAccess => premium;

  @override
  MemberUser? get user => authenticated
      ? MemberUser(
          id: 'reader-1',
          email: 'reader@example.com',
          emailVerified: true,
          username: 'reader',
          effectiveName: '阅读者',
          authMethods: ['apple'],
          createdAt: _createdAt,
        )
      : null;

  static final _createdAt = DateTime.utc(2026, 1, 1);
}

class _FakeAppleStore implements PurchaseStore {
  _FakeAppleStore({this.productAvailable = true});

  final bool productAvailable;
  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  void emit(PurchaseStatus status) {
    _purchases.add([
      PurchaseDetails(
        purchaseID: 'transaction-1',
        productID: MemberAccountController.appleProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'signed-jws',
          source: 'app_store',
        ),
        transactionDate: '1767225600000',
        status: status,
      ),
    ]);
  }

  Future<void> close() => _purchases.close();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: productAvailable
        ? [
            ProductDetails(
              id: MemberAccountController.appleProductId,
              title: '永久高级会员',
              description: '一次购买，永久解锁',
              price: '¥28.00',
              rawPrice: 28,
              currencyCode: 'CNY',
              currencySymbol: '¥',
            ),
          ]
        : const [],
    notFoundIDs: productAvailable
        ? const []
        : const [MemberAccountController.appleProductId],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  }) async => const {};
}
