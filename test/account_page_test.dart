import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_auth_2_platform_interface/flutter_web_auth_2_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_auth_2_platform_interface/method_channel/method_channel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/widgets/settings_account_card.dart';

Future<void> _pumpExternalLoginPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  final previousWebAuthPlatform = FlutterWebAuth2Platform.instance;
  FlutterWebAuth2Platform.instance = FlutterWebAuth2MethodChannel();
  addTearDown(() => FlutterWebAuth2Platform.instance = previousWebAuthPlatform);
  final controller = MemberAccountController(
    api: MemberAccountApiClient(
      dio: Dio()..httpClientAdapter = _AccountAdapter(),
      tokenStore: _EmptyTokenStore(),
    ),
  );
  await tester.runAsync(controller.initialize);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AccountPage(),
      ),
    ),
  );
  await tester.pump();
}

Future<MemberAccountController> _pumpAuthFlowPage(
  WidgetTester tester,
  _AuthFlowAdapter adapter, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final controller = MemberAccountController(
    api: MemberAccountApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      tokenStore: _EmptyTokenStore(),
    ),
  );
  addTearDown(controller.dispose);
  await tester.runAsync(controller.initialize);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountPage(),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  for (final channel in [
    AppDistributionChannel.googlePlay,
    AppDistributionChannel.appleStore,
  ]) {
    testWidgets('$channel account has no external card referral funnel', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: channel);
      addTearDown(AppDistribution.debugReset);
      final controller = MemberAccountController(
        api: MemberAccountApiClient(
          dio: Dio()..httpClientAdapter = _SignedInAdapter(),
          tokenStore: _PageTokenStore()..mfaPending = false,
        ),
      );
      addTearDown(controller.dispose);
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            locale: Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-referral')), findsNothing);
      expect(find.byKey(const ValueKey('account-support')), findsNothing);
      expect(
        find.byKey(const ValueKey('account-reader-license')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsNothing,
      );
    });
  }
  testWidgets('cached premium cannot contradict live access in settings', (
    tester,
  ) async {
    final controller = _CachedOnlyAccount();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MemberAccountController>.value(
        value: controller,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SettingsAccountCard()),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('settings-account-premium-badge')),
      findsNothing,
    );
    expect(find.textContaining('会员状态待同步'), findsOneWidget);
    expect(controller.hasPremiumAccess, isFalse);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('iOS external login cancellation quietly stops authorization', (
    tester,
  ) async {
    const channel = MethodChannel('flutter_web_auth_2');
    var authenticateCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'authenticate');
          expect(call.arguments, containsPair('callbackUrlScheme', 'xxread'));
          authenticateCalls++;
          throw PlatformException(code: 'CANCELED');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await _pumpExternalLoginPage(tester);

    final githubButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('account-provider-github')),
        matching: find.byType(InkWell),
      ),
    );
    await tester.runAsync(() async {
      githubButton.onTap!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    debugDefaultTargetPlatformOverride = null;

    expect(authenticateCalls, 1);
    expect(find.text('ABCD-EFGH'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('iOS external login platform failures are shown to the user', (
    tester,
  ) async {
    const channel = MethodChannel('flutter_web_auth_2');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'AUTH_SESSION_FAILED',
            message: 'authentication unavailable',
          );
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await _pumpExternalLoginPage(tester);

    final githubButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('account-provider-github')),
        matching: find.byType(InkWell),
      ),
    );
    await tester.runAsync(() async {
      githubButton.onTap!();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    debugDefaultTargetPlatformOverride = null;

    expect(find.textContaining('AUTH_SESSION_FAILED'), findsOneWidget);
    expect(find.textContaining('authentication unavailable'), findsOneWidget);
  });

  testWidgets(
    'sign-in entry keeps secondary providers out of the focused password task',
    (tester) async {
      await _pumpAuthFlowPage(tester, _AuthFlowAdapter());

      expect(
        find.byKey(const ValueKey('account-provider-google')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-provider-github')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-provider-passkey')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-more-providers')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('account-more-providers')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-provider-github')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-provider-passkey')),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byType(AccountPage))).pop();
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('account-auth-email')),
        'reader@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('account-email-continue')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('account-auth-password')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('account-auth-submit')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-use-email-code')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('account-open-reset')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-more-providers')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-provider-google')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-provider-github')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('account-provider-passkey')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'password login cannot leave its task while the request is open',
    (tester) async {
      final adapter = _SlowLoginAdapter();
      final controller = await _pumpAuthFlowPage(tester, adapter);
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-email')),
        'reader@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('account-email-continue')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-password')),
        'a secure password',
      );
      await tester.pump();
      final submit = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('account-auth-submit')),
          )
          .onPressed!;
      await tester.runAsync(() async {
        submit();
        for (var i = 0; i < 20 && !adapter.loginRequested; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pump();

      expect(adapter.loginRequested, isTrue);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('account-auth-password')),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('account-auth-password')),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        adapter.completeLogin();
        for (var i = 0; i < 40 && controller.user == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pump();
      expect(
        find.byKey(const ValueKey('account-edit-profile')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'registration sends one code and submits credentials only on the last step',
    (tester) async {
      final adapter = _AuthFlowAdapter();
      await _pumpAuthFlowPage(tester, adapter);

      await tester.tap(find.byKey(const ValueKey('account-open-register')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-email')),
        'reader@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pumpAndSettle();

      expect(adapter.registrationCodeRequests, 1);
      expect(adapter.registrationAttempts, 0);
      expect(find.byKey(const ValueKey('account-auth-code')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-auth-username')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('account-auth-code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pump();

      expect(adapter.registrationAttempts, 0);
      expect(
        find.byKey(const ValueKey('account-auth-username')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-auth-password')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-auth-confirm')),
        findsOneWidget,
      );
      expect(find.text('昵称'), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('account-auth-username')),
        'reader',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-back')));
      await tester.pump();
      final codeField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('account-auth-code')),
      );
      expect(codeField.controller!.text, '123456');
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pump();
      final usernameField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('account-auth-username')),
      );
      expect(usernameField.controller!.text, 'reader');
      expect(adapter.registrationCodeRequests, 1);

      await tester.tap(find.byKey(const ValueKey('account-auth-back')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('account-resend-code')));
      await tester.pumpAndSettle();
      expect(adapter.registrationCodeRequests, 2);
      final resentCodeField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('account-auth-code')),
      );
      expect(resentCodeField.controller!.text, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('account-auth-password')),
        'a secure password',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-confirm')),
        'a secure password',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pumpAndSettle();

      expect(adapter.registrationAttempts, 1);
      expect(adapter.registrationBodies.single, {
        'email': 'reader@example.com',
        'challenge_id': 'registration-2',
        'code': '123456',
        'username': 'reader',
        'display_name': null,
        'password': 'a secure password',
      });
      expect(find.text('reader'), findsWidgets);
    },
  );

  testWidgets(
    'invalid registration code returns to code entry and keeps safe draft data',
    (tester) async {
      final adapter = _AuthFlowAdapter(rejectFirstRegistration: true);
      await _pumpAuthFlowPage(tester, adapter);

      await tester.tap(find.byKey(const ValueKey('account-open-register')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-email')),
        'reader@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-code')),
        '000000',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-username')),
        'reader',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-password')),
        'a secure password',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-auth-confirm')),
        'a secure password',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pumpAndSettle();

      expect(adapter.registrationAttempts, 1);
      expect(find.byKey(const ValueKey('account-auth-code')), findsOneWidget);
      expect(find.textContaining('验证码无效或已过期'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('account-auth-code')),
        '123456',
      );
      await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
      await tester.pump();
      final usernameField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('account-auth-username')),
      );
      final passwordField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('account-auth-password')),
      );
      expect(usernameField.controller!.text, 'reader');
      expect(passwordField.controller!.text, isEmpty);
      expect(adapter.registrationCodeRequests, 1);
    },
  );

  testWidgets('registration submit remains reachable above a small keyboard', (
    tester,
  ) async {
    final adapter = _AuthFlowAdapter();
    await _pumpAuthFlowPage(tester, adapter, size: const Size(320, 568));

    await tester.tap(find.byKey(const ValueKey('account-open-register')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('account-auth-email')),
      'reader@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-auth-code')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('account-auth-submit')));
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('account-auth-username')),
      'reader',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-auth-password')),
      'a secure password',
    );
    await tester.enterText(
      find.byKey(const ValueKey('account-auth-confirm')),
      'a secure password',
    );

    final submit = find.byKey(const ValueKey('account-auth-submit'));
    await Scrollable.ensureVisible(
      tester.element(submit),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    expect(submit, findsOneWidget);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(
      submit.hitTestable(),
      findsOneWidget,
      reason:
          'submit=${tester.getRect(submit)}, scroll=${position.pixels}/${position.maxScrollExtent}',
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(adapter.registrationAttempts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest account card opens the complete account center', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MemberAccountController(
      api: MemberAccountApiClient(
        dio: Dio()..httpClientAdapter = _AccountAdapter(),
        tokenStore: _EmptyTokenStore(),
      ),
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SettingsAccountCard(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('登录开元阅读'), findsOneWidget);
    expect(find.text('同步账号资料与安全设置'), findsOneWidget);
    final avatar = tester.widget<Container>(
      find.byKey(const ValueKey('settings-account-avatar')),
    );
    expect((avatar.decoration! as BoxDecoration).shape, BoxShape.circle);

    await tester.tap(find.byKey(const ValueKey('settings-account-card')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AccountPage), findsOneWidget);
    expect(find.text('登录 Origo X'), findsOneWidget);
    expect(find.text('管理你的账户与已购权益'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-auth-email')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-email-continue')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('account-open-register')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-provider-github')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-provider-passkey')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('account-more-providers')),
      findsOneWidget,
    );
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      0,
    );

    await tester.tap(find.byKey(const ValueKey('account-open-register')));
    await tester.pump();
    expect(find.text('注册'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-change-email')), findsNothing);
    expect(find.byKey(const ValueKey('account-auth-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-provider-github')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('account-auth-back')));
    await tester.pump();
    expect(find.text('登录 Origo X'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('account-more-providers')));
    await tester.pumpAndSettle();
    expect(find.text('使用 Passkey'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-provider-passkey')),
      findsOneWidget,
    );
    Navigator.of(tester.element(find.byType(AccountPage))).pop();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('account-auth-email')),
      'reader@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('account-email-continue')));
    await tester.pump();

    expect(find.text('使用密码登录'), findsOneWidget);
    expect(find.text('使用邮箱验证码登录'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-change-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-provider-github')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('account-privacy-link')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('account-privacy-link')));
    await tester.pumpAndSettle();
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('购买与验证数据'), findsOneWidget);
  });

  testWidgets('premium member receives the exclusive account card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MemberAccountController(
      api: MemberAccountApiClient(
        dio: Dio()..httpClientAdapter = _SignedInAdapter(premium: true),
        tokenStore: _PageTokenStore()..mfaPending = false,
      ),
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: SettingsAccountCard(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-account-premium-badge')),
      findsOneWidget,
    );
    expect(find.text('高级会员'), findsOneWidget);
    expect(find.text('永久高级版已解锁'), findsOneWidget);
    expect(find.text('PREMIUM'), findsOneWidget);
    final avatar = tester.widget<Container>(
      find.byKey(const ValueKey('settings-account-avatar')),
    );
    final decoration = avatar.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(
      find.byKey(const ValueKey('settings-account-avatar-clip')),
      findsOneWidget,
    );
    final avatarCenter = tester.getCenter(
      find.byKey(const ValueKey('settings-account-avatar-clip')),
    );
    final fallbackCenter = tester.getCenter(
      find.byKey(const ValueKey('settings-account-avatar-fallback')),
    );
    expect(fallbackCenter.dx, avatarCenter.dx);
    expect(fallbackCenter.dy, avatarCenter.dy);
    expect((decoration.border! as Border).top.width, greaterThan(2));
  });

  testWidgets('pending MFA session shows only the compact verification gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MemberAccountController(
      api: MemberAccountApiClient(
        dio: Dio()..httpClientAdapter = _PendingMfaAdapter(),
        tokenStore: _PageTokenStore(),
      ),
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('双重验证'), findsOneWidget);
    expect(find.text('验证器动态码或恢复码'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-mfa-verify')), findsOneWidget);
    expect(find.text('注册'), findsNothing);
    expect(find.text('使用 GitHub'), findsNothing);
    expect(find.text('支持高级功能'), findsNothing);
  });

  testWidgets(
    'signed-in center keeps profile and security details tucked away',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final tokenStore = _PageTokenStore()..mfaPending = false;
      final controller = MemberAccountController(
        api: MemberAccountApiClient(
          dio: Dio()..httpClientAdapter = _SignedInAdapter(),
          tokenStore: tokenStore,
        ),
      );
      await tester.runAsync(controller.initialize);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClipOval), findsOneWidget);
      expect(find.text('邀请好友'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-referral')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-support')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-invite-ticket')), findsNothing);
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsNothing,
      );
      expect(find.text('登录方式'), findsNothing);
      expect(find.text('更换邮箱'), findsNothing);
      expect(find.text('设置或更换密码'), findsNothing);
      expect(find.byKey(const ValueKey('account-mfa-setup')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('account-security')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('账号安全'), findsOneWidget);
      expect(find.text('编辑资料'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account-referral')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-invite-ticket')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('floating-subpage-back')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account-support')));
      await tester.pumpAndSettle();
      expect(find.text('永久高级会员'), findsNWidgets(2));
      expect(find.text('更多书源协议'), findsOneWidget);
      expect(find.text('允许内网书源'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-redemption-code')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account-security')));
      await tester.pumpAndSettle();

      expect(find.text('登录方式'), findsOneWidget);
      expect(find.text('更换邮箱'), findsOneWidget);
      expect(find.text('设置或更换密码'), findsOneWidget);
      expect(find.text('双重验证'), findsOneWidget);
      expect(find.textContaining('默认关闭'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-mfa-setup')), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('恢复码已复制'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('account-mfa-setup')));
      await tester.pumpAndSettle();

      expect(find.text('先验证当前邮箱'), findsOneWidget);
      expect(find.textContaining('reader@example.com'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-mfa-send-email-submit')),
        findsOneWidget,
      );
      expect(find.text('验证码'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      expect(
        find.byKey(const ValueKey('floating-subpage-back')),
        findsOneWidget,
      );
      expect(find.textContaining('第 1 步'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('account-mfa-send-email-submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('输入邮件验证码'), findsOneWidget);
      expect(find.text('验证码'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-mfa-qr-code')), findsNothing);

      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(
        find.byKey(const ValueKey('account-mfa-email-code-submit')),
      );
      await tester.pumpAndSettle();

      expect(find.text('将开元阅读添加到验证器'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-mfa-qr-code')), findsOneWidget);
      expect(find.text('BASE32SECRET'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-edit-profile')));
      await tester.pumpAndSettle();

      expect(find.text('编辑资料'), findsOneWidget);
      expect(find.text('更换头像'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('account-profile-save')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-profile-name')),
        'Reader Updated',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('account-profile-save')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();
      expect(find.text('个人资料的修改尚未保存。'), findsOneWidget);
      await tester.tap(find.text('放弃修改').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-edit-profile')),
        findsOneWidget,
      );
    },
  );

  testWidgets('profile cannot be dismissed while a save request is open', (
    tester,
  ) async {
    final adapter = _SlowProfileAdapter();
    final controller = MemberAccountController(
      api: MemberAccountApiClient(
        dio: Dio()..httpClientAdapter = adapter,
        tokenStore: _PageTokenStore()..mfaPending = false,
      ),
    );
    addTearDown(controller.dispose);
    await tester.runAsync(controller.initialize);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-edit-profile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('account-profile-name')),
      'Reader Updated',
    );
    await tester.pump();
    final save = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('account-profile-save')),
        )
        .onPressed!;
    await tester.runAsync(() async {
      save();
      for (var i = 0; i < 20 && !adapter.profileRequested; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pump();

    expect(adapter.profileRequested, isTrue);
    await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
    await tester.pump();
    expect(find.byKey(const ValueKey('account-profile-save')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('account-profile-save')), findsOneWidget);

    await tester.runAsync(() async {
      adapter.completeProfileSave();
      for (var i = 0; i < 40 && controller.loading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('account-profile-save')),
          )
          .onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-edit-profile')), findsOneWidget);
  });

  testWidgets(
    'offline account center still shows sign-in controls and a retry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MemberAccountController(
        api: MemberAccountApiClient(
          dio: Dio()..httpClientAdapter = _OfflineAdapter(),
          tokenStore: _EmptyTokenStore(),
        ),
      );
      await tester.runAsync(() async {
        await expectLater(
          controller.initialize(),
          throwsA(isA<MemberAccountException>()),
        );
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('account-load-error')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-load-retry')), findsOneWidget);
      expect(find.text('邮箱'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-provider-github')),
        findsNothing,
      );
    },
  );
}

class _AccountAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.uri.path) {
      '/api/v1/auth/config' => {
        'providers': {'google': false, 'github': true, 'passkey': true},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      },
      '/api/v1/membership/config' => {
        'product': 'premium_lifetime',
        'purchase_url': 'https://pay.ldxp.cn/item/m3rfxi',
        'features': ['supporter_badge'],
      },
      '/api/v1/auth/device/github/begin' => {
        'device_code': 'device-code',
        'user_code': 'ABCD-EFGH',
        'verification_uri': 'https://github.com/login/device',
        'expires_in': 600,
        'interval': 5,
      },
      _ => throw StateError('Unexpected route ${options.uri.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _AuthFlowAdapter implements HttpClientAdapter {
  _AuthFlowAdapter({this.rejectFirstRegistration = false});

  final bool rejectFirstRegistration;
  int registrationCodeRequests = 0;
  int registrationAttempts = 0;
  final List<Map<String, dynamic>> registrationBodies = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/api/v1/auth/config') {
      return _response({
        'providers': {'google': true, 'github': true, 'passkey': true},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      });
    }
    if (path == '/api/v1/membership/config') {
      return _response({'product': 'premium_lifetime', 'features': <String>[]});
    }
    if (path == '/api/v1/auth/password/register/code') {
      registrationCodeRequests++;
      expect(options.data, {'email': 'reader@example.com'});
      return _response({
        'challenge_id': 'registration-$registrationCodeRequests',
        'expires_in': 600,
        'message': '验证码已发送',
      });
    }
    if (path == '/api/v1/auth/password/register') {
      registrationAttempts++;
      registrationBodies.add(
        Map<String, dynamic>.from(options.data as Map<dynamic, dynamic>),
      );
      if (rejectFirstRegistration && registrationAttempts == 1) {
        return _response({
          'code': 'codeInvalid',
          'detail': [
            {
              'type': 'value_error',
              'loc': ['body', 'code'],
              'msg': 'invalid verification code',
            },
          ],
        }, status: 422);
      }
      return _response({
        'token_type': 'bearer',
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'access_expires_in': 900,
        'refresh_expires_in': 2592000,
        'mfa_required': false,
        'user': {
          'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
          'email': 'reader@example.com',
          'email_verified': true,
          'username': 'reader',
          'display_name': null,
          'effective_name': 'reader',
          'avatar_url': null,
          'auth_methods': ['password'],
          'created_at': '2026-09-26T00:00:00Z',
        },
      });
    }
    if (path == '/api/v1/membership') {
      return _response({
        'premium': false,
        'features': <String, bool>{},
        'entitlements': <Object>[],
      });
    }
    if (path == '/api/v1/membership/referral') {
      return _response({
        'invite_code': 'OR-MY-CODE',
        'invite_url': 'https://open.xxread.top/account?invite=OR-MY-CODE',
        'stats': {'invited': 0, 'rewarded': 0},
        'inviter': null,
      });
    }
    throw StateError('Unexpected route $path');
  }

  ResponseBody _response(Map<String, dynamic> body, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
}

class _SlowLoginAdapter extends _AuthFlowAdapter {
  final Completer<ResponseBody> _login = Completer<ResponseBody>();
  bool loginRequested = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.uri.path == '/api/v1/auth/password/login') {
      loginRequested = true;
      return _login.future;
    }
    return super.fetch(options, requestStream, cancelFuture);
  }

  void completeLogin() => _login.complete(
    ResponseBody.fromString(
      jsonEncode({
        'token_type': 'bearer',
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'access_expires_in': 900,
        'refresh_expires_in': 2592000,
        'mfa_required': false,
        'user': _readerUser(),
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    ),
  );
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw const SocketException('offline');
  }
}

class _EmptyTokenStore implements MemberTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;

  @override
  Future<bool> readMfaPending() async => false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async {}
}

class _PendingMfaAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.uri.path) {
      '/api/v1/auth/config' => {
        'providers': <String, bool>{},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      },
      '/api/v1/membership/config' => {
        'product': 'premium_lifetime',
        'features': <String>[],
      },
      '/api/v1/auth/me' => {
        'mfa_required': true,
        'user': {
          'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
          'email': 'reader@example.com',
          'email_verified': true,
          'username': 'reader',
          'display_name': 'Reader',
          'effective_name': 'Reader',
          'avatar_url': null,
          'auth_methods': ['password'],
          'created_at': '2026-08-03T00:00:00Z',
        },
      },
      _ => throw StateError('Unexpected route ${options.uri.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _SignedInAdapter implements HttpClientAdapter {
  _SignedInAdapter({this.premium = false});

  final bool premium;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = switch (options.uri.path) {
      '/api/v1/auth/config' => {
        'providers': <String, bool>{},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      },
      '/api/v1/membership/config' => {
        'product': 'premium_lifetime',
        'features': <String>[],
      },
      '/api/v1/auth/me' => {
        'mfa_required': false,
        'user': {
          'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
          'email': 'reader@example.com',
          'email_verified': true,
          'username': 'reader',
          'display_name': 'Reader',
          'effective_name': 'Reader',
          'avatar_url': null,
          'auth_methods': ['password'],
          'created_at': '2026-08-03T00:00:00Z',
        },
      },
      '/api/v1/membership' => {
        'premium': premium,
        'features': <String, bool>{},
        'entitlements': <Object>[],
      },
      '/api/v1/membership/referral' => {
        'invite_code': 'OR-MY-CODE',
        'invite_url': 'https://open.xxread.top/account?invite=OR-MY-CODE',
        'stats': {'invited': 3, 'rewarded': 1},
        'inviter': null,
      },
      '/api/v1/auth/security/mfa/status' => {
        'enabled': false,
        'recovery_codes_remaining': 0,
      },
      '/api/v1/auth/security/mfa/setup/code' => {
        'challenge_id': 'mfa-id',
        'expires_in': 600,
      },
      '/api/v1/auth/security/mfa/setup' => () {
        expect(options.data, {'challenge_id': 'mfa-id', 'code': '111111'});
        return {
          'secret': 'BASE32SECRET',
          'otpauth_uri':
              'otpauth://totp/OrigoReader:reader?secret=BASE32SECRET&issuer=OrigoReader',
        };
      }(),
      _ => throw StateError('Unexpected route ${options.uri.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _SlowProfileAdapter extends _SignedInAdapter {
  final Completer<ResponseBody> _profile = Completer<ResponseBody>();
  bool profileRequested = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.uri.path == '/api/v1/auth/profile') {
      profileRequested = true;
      return _profile.future;
    }
    return super.fetch(options, requestStream, cancelFuture);
  }

  void completeProfileSave() => _profile.complete(
    ResponseBody.fromString(
      jsonEncode({
        'user': {..._readerUser(), 'display_name': 'Reader Updated'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    ),
  );
}

Map<String, dynamic> _readerUser() => {
  'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
  'email': 'reader@example.com',
  'email_verified': true,
  'username': 'reader',
  'display_name': 'Reader',
  'effective_name': 'Reader',
  'avatar_url': null,
  'auth_methods': ['password'],
  'created_at': '2026-09-26T00:00:00Z',
};

class _PageTokenStore implements MemberTokenStore {
  String? accessToken = 'pending-access';
  String? refreshToken = 'pending-refresh';
  bool mfaPending = true;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    mfaPending = false;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<bool> readMfaPending() async => mfaPending;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.mfaPending = mfaPending;
  }
}

class _CachedOnlyAccount extends MemberAccountController {
  @override
  MemberAccountSummary get summary => const MemberAccountSummary(
    userId: 'cached',
    username: 'reader',
    effectiveName: 'Reader',
    premium: true,
  );
}
