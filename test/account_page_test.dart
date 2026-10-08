import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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
  GoogleNativeSignInClient? googleNativeSignIn,
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
    googleNativeSignIn: googleNativeSignIn,
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
        api: _PageApiClient(
          dio: Dio()..httpClientAdapter = _SignedInAdapter(),
          tokenStore: _PageTokenStore()..mfaPending = false,
        ),
        purchaseStore: const _UnavailablePurchaseStore(),
        readerAccessCache: _MemoryReaderAccessCache(),
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
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('account-support')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const ValueKey('account-support')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('account-reader-license')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
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
    expect(find.textContaining('会员状态待同步'), findsNothing);
    expect(controller.hasPremiumAccess, isFalse);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('iOS Google button uses native identity token login', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final adapter = _AuthFlowAdapter(nativeGoogle: true);
    final nativeGoogle = _FakeNativeGoogleSignIn('native-id-token');
    final controller = await _pumpAuthFlowPage(
      tester,
      adapter,
      googleNativeSignIn: nativeGoogle,
    );

    expect(controller.usesNativeGoogleLogin, isTrue);
    await tester.tap(find.byKey(const ValueKey('account-provider-google')));
    await tester.pumpAndSettle();

    expect(nativeGoogle.calls, 1);
    expect(nativeGoogle.platform, TargetPlatform.iOS);
    expect(adapter.googleLoginAttempts, 1);
    expect(adapter.googleIdentityToken, 'native-id-token');
    expect(find.byKey(const ValueKey('account-mfa-verify')), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'provider without usable email opens verification and binds before MFA',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = _AuthFlowAdapter(
        nativeGoogle: true,
        emailBindingRequired: true,
      );
      await _pumpAuthFlowPage(
        tester,
        adapter,
        googleNativeSignIn: _FakeNativeGoogleSignIn('native-id-token'),
      );
      await tester.tap(find.byKey(const ValueKey('account-provider-google')));
      await tester.pumpAndSettle();
      expect(find.text('绑定邮箱'), findsOneWidget);
      expect(find.byKey(const ValueKey('account-mfa-verify')), findsNothing);
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
      await tester.pumpAndSettle();
      expect(adapter.bindingBody, {
        'binding_token': 'provider-proof-01234567890123456789',
        'email': 'reader@example.com',
        'challenge_id': 'binding-email-proof',
        'code': '123456',
      });
      expect(find.byKey(const ValueKey('account-mfa-verify')), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('canceled native Google chooser stays on sign-in', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final adapter = _AuthFlowAdapter(nativeGoogle: true);
    final nativeGoogle = _FakeNativeGoogleSignIn(null);
    await _pumpAuthFlowPage(tester, adapter, googleNativeSignIn: nativeGoogle);

    await tester.tap(find.byKey(const ValueKey('account-provider-google')));
    await tester.pumpAndSettle();

    expect(nativeGoogle.calls, 1);
    expect(adapter.googleLoginAttempts, 0);
    expect(
      find.byKey(const ValueKey('account-provider-google')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('native Google loading preserves centered entry geometry', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final adapter = _AuthFlowAdapter(nativeGoogle: true);
    final nativeGoogle = _DeferredNativeGoogleSignIn();
    await _pumpAuthFlowPage(tester, adapter, googleNativeSignIn: nativeGoogle);
    await tester.pumpAndSettle();

    final brand = find.byKey(const ValueKey('account-auth-brand'));
    final email = find.byKey(const ValueKey('account-auth-email'));
    final progress = find.byKey(const ValueKey('account-auth-progress'));
    final back = find.byKey(const ValueKey('floating-subpage-back'));
    final l10n = AppLocalizations.of(tester.element(email));
    final title = find.text(l10n.accountSignInTitle);
    final subtitle = find.text(l10n.accountSignInSubtitle);
    final idleBrand = tester.getRect(brand);
    final idleEmail = tester.getRect(email);
    expect(idleBrand.center.dx, closeTo(195, 0.5));
    expect(idleBrand.top, greaterThan(tester.getRect(back).bottom));
    expect(tester.widget<Text>(title).textAlign, TextAlign.center);
    expect(tester.widget<Text>(subtitle).textAlign, TextAlign.center);
    expect(progress, findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-provider-google')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    expect(nativeGoogle.calls, 1);
    expect(progress, findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    final progressRect = tester.getRect(progress);
    expect(progressRect.top, greaterThan(tester.getRect(subtitle).bottom));
    expect(progressRect.top, greaterThan(idleBrand.bottom));
    expect(progressRect.bottom, lessThanOrEqualTo(idleEmail.top));
    expect(tester.getRect(brand), idleBrand);
    expect(tester.getRect(email), idleEmail);

    nativeGoogle.result.complete(null);
    await tester.pumpAndSettle();
    expect(progress, findsNothing);
    expect(tester.getRect(brand), idleBrand);
    expect(tester.getRect(email), idleEmail);
    expect(adapter.googleLoginAttempts, 0);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

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

  testWidgets(
    'external login progress hides the code already embedded in the browser URL',
    (tester) async {
      const channel = MethodChannel('flutter_web_auth_2');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (_) async => 'xxread://auth/callback',
          );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await _pumpExternalLoginPage(tester);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('account-provider-github')),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('ABCD-EFGH'), findsNothing);
      expect(find.text('取消'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      debugDefaultTargetPlatformOverride = null;
    },
  );

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

  testWidgets('direct macOS Apple login uses the browser OAuth device flow', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    addTearDown(AppDistribution.debugReset);
    final previousWebAuthPlatform = FlutterWebAuth2Platform.instance;
    FlutterWebAuth2Platform.instance = FlutterWebAuth2MethodChannel();
    addTearDown(
      () => FlutterWebAuth2Platform.instance = previousWebAuthPlatform,
    );
    const channel = MethodChannel('flutter_web_auth_2');
    var authenticateCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'authenticate');
          expect(
            call.arguments,
            containsPair(
              'url',
              'https://appleid.apple.com/auth/authorize?state=member_apple',
            ),
          );
          authenticateCalls++;
          throw PlatformException(code: 'CANCELED');
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final adapter = _AppleExternalAuthAdapter();
    await _pumpAuthFlowPage(tester, adapter);

    final appleButton = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const ValueKey('account-provider-apple')),
        matching: find.byType(InkWell),
      ),
    );
    await tester.runAsync(() async {
      appleButton.onTap!();
      for (var i = 0; i < 20 && authenticateCalls == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;

    expect(adapter.appleBeginRequests, 1);
    expect(authenticateCalls, 1);
    expect(find.byKey(const ValueKey('account-auth-error')), findsNothing);
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
        for (
          var i = 0;
          i < 200 && (controller.user == null || controller.loading);
          i++
        ) {
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

    expect(find.text('未登录'), findsOneWidget);
    expect(find.text('本地阅读无需登录'), findsOneWidget);
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
      api: _PageApiClient(
        dio: Dio()..httpClientAdapter = _SignedInAdapter(premium: true),
        tokenStore: _PageTokenStore()..mfaPending = false,
      ),
      readerAccessCache: _MemoryReaderAccessCache(),
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
    expect(find.text('探元'), findsNothing);
    expect(find.text('Origo 探元'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-membership-entry')),
      findsNothing,
    );
    final avatar = tester.widget<Container>(
      find.byKey(const ValueKey('settings-account-avatar')),
    );
    final decoration = avatar.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNull);
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
    expect((decoration.border! as Border).top.width, 1);
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
        api: _PageApiClient(
          dio: Dio()..httpClientAdapter = _SignedInAdapter(),
          tokenStore: tokenStore,
        ),
        readerAccessCache: _MemoryReaderAccessCache(),
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
      expect(find.text('Origo 探元'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('premium-details-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('premium-benefits-details')));
      await tester.pumpAndSettle();
      expect(find.text('更多书源协议'), findsWidgets);
      expect(find.text('允许内网书源'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();
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

  testWidgets('signed-in header keeps cached Explore presentation', (
    tester,
  ) async {
    final controller = _CachedDisplayPremiumAccount();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MemberAccountController>.value(
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

    expect(controller.hasPremiumAccess, isFalse);
    expect(find.text('探元'), findsOneWidget);
    expect(find.byKey(const ValueKey('account-support')), findsOneWidget);
  });

  testWidgets('profile cannot be dismissed while a save request is open', (
    tester,
  ) async {
    final adapter = _SlowProfileAdapter();
    final controller = MemberAccountController(
      api: _PageApiClient(
        dio: Dio()..httpClientAdapter = adapter,
        tokenStore: _PageTokenStore()..mfaPending = false,
      ),
      readerAccessCache: _MemoryReaderAccessCache(),
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
    'invitation page reloads remote targets and rules on foreground',
    (tester) async {
      final adapter = _CampaignAdapter();
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      expect(adapter.referralRequests, 2);
      expect(find.text('服务端邀请活动'), findsOneWidget);
      expect(find.text('2 / 7'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      adapter.campaign = _referralCampaign(state: 'paused', target: 11);
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('账号操作'), findsNothing);
      expect(adapter.referralRequests, 3);
      expect(find.text('活动已暂停'), findsOneWidget);
      expect(find.text('2 / 11'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-rules')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-rules')));
      await tester.pumpAndSettle();
      expect(find.text('服务端有效用户规则'), findsOneWidget);
      expect(find.text('服务端付费用户规则'), findsOneWidget);
      adapter.campaign = {
        ..._referralCampaign(),
        'rules': ['远程修改后的规则'],
      };
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('远程修改后的规则'), findsOneWidget);
      expect(find.text('服务端有效用户规则'), findsNothing);
    },
  );

  testWidgets(
    'failed campaign refresh hides cached promises until explicit retry',
    (tester) async {
      final adapter = _CampaignAdapter();
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      adapter.failReferral = true;
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-invite-ticket')), findsNothing);
      expect(
        find.byKey(const ValueKey('account-invite-retry')),
        findsOneWidget,
      );
      expect(find.textContaining('你们两人'), findsNothing);
      adapter.failReferral = false;
      adapter.campaign = _referralCampaign(state: 'ended', target: 9);
      await tester.tap(find.byKey(const ValueKey('account-invite-retry')));
      await tester.pumpAndSettle();
      expect(find.text('活动已结束'), findsOneWidget);
      expect(find.text('2 / 9'), findsOneWidget);
    },
  );

  testWidgets(
    'rewards display revocation and historical binding can explicitly enroll',
    (tester) async {
      final adapter = _CampaignAdapter()
        ..enrolled = false
        ..canEnroll = true
        ..inviter = {'code': 'OR-FRIEND', 'name': 'Friend', 'status': 'bound'}
        ..rewards = [
          {
            'tier_id': 'active-main',
            'metric': 'active',
            'target': 7,
            'reward_days': 120,
            'granted_at': '2026-10-07T00:00:00Z',
            'expires_at': '2027-01-07T00:00:00Z',
            'revoked_at': '2026-10-08T00:00:00Z',
          },
          {
            'tier_id': 'paid-main',
            'metric': 'paid',
            'target': 4,
            'reward_days': null,
            'granted_at': '2026-10-09T00:00:00Z',
            'expires_at': null,
          },
        ];
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      expect(
        find.byKey(const ValueKey('account-invite-tier-revoked-active-main')),
        findsOneWidget,
      );
      expect(find.text('已获得永久探元'), findsOneWidget);
      expect(find.text('奖励记录'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-records')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-records')));
      await tester.pumpAndSettle();
      expect(find.text('已撤回'), findsOneWidget);
      expect(find.text('奖励记录'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-binding')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-binding')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-join-invite-campaign')),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-join-invite-campaign')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('account-join-invite-campaign')),
      );
      await tester.pumpAndSettle();
      expect(adapter.boundData, {
        'code': 'OR-FRIEND',
        'expected_user_id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
      });
      expect(
        find.byKey(const ValueKey('account-join-invite-campaign')),
        findsNothing,
      );
    },
  );

  testWidgets('ineligible historical binding cannot enroll in a campaign', (
    tester,
  ) async {
    final adapter = _CampaignAdapter()
      ..enrolled = false
      ..canEnroll = false
      ..inviter = {'code': 'OR-FRIEND', 'name': 'Friend', 'status': 'bound'};
    final controller = await _openReferralPage(tester, adapter);
    addTearDown(controller.dispose);
    await tester.ensureVisible(
      find.byKey(const ValueKey('account-invite-binding')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('account-invite-binding')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('account-join-invite-campaign')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('account-bind-invite')), findsNothing);
  });

  testWidgets(
    'initial campaign displays three remote tiers and hides disabled lifetime tier',
    (tester) async {
      final adapter = _CampaignAdapter()
        ..campaign = _initialReferralCampaign()
        ..stats = {'invited': 3, 'rewarded': 1, 'active': 2, 'paid': 0}
        ..rewards = [_tierReward('active-entry', target: 2, days: 30)];
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      final entry = find.byKey(
        const ValueKey('account-invite-tier-active-entry'),
      );
      final main = find.byKey(
        const ValueKey('account-invite-tier-active-main'),
      );
      final paid = find.byKey(
        const ValueKey('account-invite-tier-paid-lifetime'),
      );
      expect(
        find.descendant(of: entry, matching: find.text('2 位')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: main, matching: find.text('5 位')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: paid, matching: find.text('2 位')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-invite-tier-received-active-entry')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: main, matching: find.text('90 天')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-invite-tier-active-lifetime')),
        findsNothing,
      );
      expect(adapter.publicCampaignRequests, 0);
      expect(
        controller.referral?.campaign?.tiers.where((tier) => tier.enabled),
        hasLength(3),
      );
    },
  );

  testWidgets('active tier rewards are tracked by tier ID and revocation', (
    tester,
  ) async {
    final adapter = _CampaignAdapter()
      ..campaign = _initialReferralCampaign()
      ..stats = {'invited': 5, 'rewarded': 2, 'active': 5, 'paid': 0}
      ..rewards = [
        _tierReward('active-entry', target: 2, days: 30),
        _tierReward('active-main', target: 5, days: 90, revoked: true),
      ];
    final controller = await _openReferralPage(tester, adapter);
    addTearDown(controller.dispose);
    final main = find.byKey(const ValueKey('account-invite-tier-active-main'));
    expect(
      find.byKey(const ValueKey('account-invite-tier-received-active-entry')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: main, matching: find.text('90 天')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-invite-tier-received-active-main')),
      findsNothing,
    );
    expect(find.text('已撤回'), findsOneWidget);
    adapter.rewards[1] = _tierReward('active-main', target: 5, days: 90);
    await tester.runAsync(() async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('account-invite-tier-received-active-main')),
      findsOneWidget,
    );
    expect(find.text('累计 120 天探元'), findsNothing);
    expect(find.text('已撤回'), findsNothing);
  });

  testWidgets(
    'participating profile keeps locked rules when public revision changes',
    (tester) async {
      final adapter = _CampaignAdapter()
        ..campaign = _initialReferralCampaign()
        ..publicCampaign = {
          ..._initialReferralCampaign(),
          'revision': 99,
          'title': '新公开活动',
          'rules': ['不适用于已参加用户的新规则'],
        };
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      expect(controller.referral?.campaign?.revision, 2);
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-rules')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-rules')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(
        find.text('达到 5 位有效新用户累计赠送 90 天，已领 30 天时补发 60 天。'),
        findsOneWidget,
      );
      expect(find.text('不适用于已参加用户的新规则'), findsNothing);
      expect(controller.referral?.campaign?.revision, 2);
      expect(adapter.publicCampaignRequests, 0);
    },
  );

  testWidgets(
    'invite overview keeps history on the next page and copies the share link',
    (tester) async {
      Object? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') copied = call.arguments;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final adapter = _CampaignAdapter()
        ..campaign = _initialReferralCampaign()
        ..rewards = [_tierReward('active-entry', target: 2, days: 30)];
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(find.text('奖励记录'), findsNothing);
      expect(
        find.text(adapter.campaign['description'] as String),
        findsNothing,
      );
      final share = find.byKey(const ValueKey('account-share-invite'));
      expect(tester.getSize(share).height, greaterThanOrEqualTo(44));
      expect(
        tester
            .getSize(find.byKey(const ValueKey('account-copy-invite-code')))
            .height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(share);
      await tester.pumpAndSettle();
      expect(copied, {'text': 'https://example.test/invite/OR-MY-CODE'});
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-records')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-records')));
      await tester.pumpAndSettle();
      expect(find.text('奖励记录'), findsOneWidget);
      expect(find.text('累计 30 天探元'), findsOneWidget);
    },
  );

  testWidgets(
    'large text progress remains scrollable and provides valid semantic percentages',
    (tester) async {
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(1024, 768),
      ]) {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        final adapter = _CampaignAdapter()
          ..campaign = _initialReferralCampaign();
        final controller = await _openReferralPage(
          tester,
          adapter,
          textScale: 2,
        );
        expect(tester.takeException(), isNull, reason: '$size overview');
        final indicators = tester
            .widgetList<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .toList();
        expect(indicators, hasLength(2));
        expect(indicators.first.semanticsLabel, '有效新用户 2 / 5');
        expect(indicators.first.semanticsValue, '40%');
        await tester.ensureVisible(
          find.byKey(const ValueKey('account-invite-rules')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('account-invite-rules')));
        await tester.pumpAndSettle();
        expect(
          find.text('达到 5 位有效新用户累计赠送 90 天，已领 30 天时补发 60 天。'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$size rules');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        controller.dispose();
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'permanent campaign completion requires its own non-revoked reward',
    (tester) async {
      final adapter = _CampaignAdapter()
        ..campaign = _initialReferralCampaign()
        ..stats = {'invited': 5, 'rewarded': 0, 'active': 5, 'paid': 2};
      final controller = await _openReferralPage(tester, adapter);
      addTearDown(controller.dispose);
      expect(find.text('已获得永久探元'), findsNothing);
      final paid = find.byKey(const ValueKey('account-invite-track-paid'));
      expect(
        find.descendant(of: paid, matching: find.text('已达标')),
        findsOneWidget,
      );
      adapter.rewards = [_tierReward('paid-lifetime', target: 2)];
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: paid, matching: find.text('已获得永久探元')),
        findsOneWidget,
      );
      adapter.rewards = [
        _tierReward('paid-lifetime', target: 2, revoked: true),
      ];
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('已获得永久探元'), findsNothing);
      expect(
        find.descendant(of: paid, matching: find.text('已撤回')),
        findsOneWidget,
      );
    },
  );

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

Future<MemberAccountController> _openReferralPage(
  WidgetTester tester,
  _CampaignAdapter adapter, {
  double textScale = 1,
}) async {
  const webAuthChannel = MethodChannel('flutter_web_auth_2');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    webAuthChannel,
    (call) async {
      expect(call.method, 'cleanUpDanglingCalls');
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      webAuthChannel,
      null,
    ),
  );
  final controller = MemberAccountController(
    api: _PageApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      tokenStore: _PageTokenStore()..mfaPending = false,
    ),
    readerAccessCache: _MemoryReaderAccessCache(),
  );
  await tester.runAsync(controller.initialize);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const AccountPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('account-referral')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('account-referral')));
  await tester.pumpAndSettle();
  return controller;
}

class _CampaignAdapter extends _SignedInAdapter {
  Map<String, dynamic> campaign = _referralCampaign();
  Map<String, dynamic> publicCampaign = _referralCampaign();
  Map<String, dynamic> stats = {
    'invited': 3,
    'rewarded': 1,
    'active': 2,
    'paid': 1,
  };
  int publicCampaignRequests = 0;
  bool failReferral = false;
  bool enrolled = true;
  bool canEnroll = false;
  Map<String, dynamic>? inviter;
  List<Map<String, dynamic>> rewards = [];
  int referralRequests = 0;
  Object? boundData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.uri.path;
    if (path == '/api/v1/membership/referral/campaign') {
      publicCampaignRequests++;
      return ResponseBody.fromString(
        jsonEncode(publicCampaign),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (path != '/api/v1/membership/referral' &&
        path != '/api/v1/membership/referral/bind') {
      return super.fetch(options, requestStream, cancelFuture);
    }
    expect(options.headers['X-Origo-Referral-Version'], '2');
    referralRequests++;
    if (failReferral) {
      return ResponseBody.fromString(
        jsonEncode({'detail': '活动服务暂不可用'}),
        503,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (path.endsWith('/bind')) {
      boundData = options.data;
      enrolled = true;
      canEnroll = false;
    }
    return ResponseBody.fromString(
      jsonEncode({
        'invite_code': 'OR-MY-CODE',
        'invite_url': 'https://example.test/invite/OR-MY-CODE',
        'campaign': campaign,
        'stats': stats,
        'inviter': inviter,
        'enrolled': enrolled,
        'can_enroll': canEnroll,
        'rewards': rewards,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
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
  _AuthFlowAdapter({
    this.rejectFirstRegistration = false,
    this.nativeGoogle = false,
    this.emailBindingRequired = false,
  });

  final bool rejectFirstRegistration;
  final bool nativeGoogle;
  final bool emailBindingRequired;
  Map<String, dynamic>? bindingBody;
  int registrationCodeRequests = 0;
  int registrationAttempts = 0;
  int googleLoginAttempts = 0;
  String? googleIdentityToken;
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
        'providers': {'google': !nativeGoogle, 'github': true, 'passkey': true},
        if (nativeGoogle)
          'google_native': {
            'enabled': true,
            'server_client_id': 'server.apps.googleusercontent.com',
            'ios_client_id': 'ios.apps.googleusercontent.com',
          },
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
    if (path == '/api/v1/auth/google/login') {
      googleLoginAttempts++;
      googleIdentityToken = (options.data as Map)['identity_token'] as String?;
      if (emailBindingRequired) {
        return _response({
          'email_binding_required': true,
          'provider': 'google',
          'binding_token': 'provider-proof-01234567890123456789',
          'expires_in': 600,
        });
      }
      return _response({
        'token_type': 'bearer',
        'access_token': 'google-access',
        'refresh_token': 'google-refresh',
        'access_expires_in': 900,
        'refresh_expires_in': 2592000,
        'mfa_required': true,
        'user': _readerUser(),
      });
    }
    if (path == '/api/v1/auth/email/code') {
      return _response({
        'challenge_id': 'binding-email-proof',
        'expires_in': 600,
        'message': '验证码已发送',
      });
    }
    if (path == '/api/v1/auth/oauth/bind-email') {
      bindingBody = Map<String, dynamic>.from(options.data as Map);
      return _response({
        'token_type': 'bearer',
        'access_token': 'bound-access',
        'refresh_token': 'bound-refresh',
        'access_expires_in': 900,
        'refresh_expires_in': 2592000,
        'mfa_required': true,
        'user': _readerUser(),
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
        'stats': {'invited': 0, 'rewarded': 0, 'active': 0, 'paid': 0},
        'campaign': _referralCampaign(),
        'enrolled': false,
        'can_enroll': true,
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

class _DeferredNativeGoogleSignIn implements GoogleNativeSignInClient {
  final result = Completer<String?>();
  int calls = 0;

  @override
  Future<String?> authenticate(
    GoogleNativeAuthConfig config, {
    required TargetPlatform platform,
  }) {
    calls++;
    return result.future;
  }
}

class _FakeNativeGoogleSignIn implements GoogleNativeSignInClient {
  _FakeNativeGoogleSignIn(this.identityToken);

  final String? identityToken;
  int calls = 0;
  TargetPlatform? platform;

  @override
  Future<String?> authenticate(
    GoogleNativeAuthConfig config, {
    required TargetPlatform platform,
  }) async {
    calls++;
    this.platform = platform;
    return identityToken;
  }
}

class _AppleExternalAuthAdapter extends _AuthFlowAdapter {
  int appleBeginRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return switch (options.uri.path) {
      '/api/v1/auth/config' => _response({
        'providers': {'apple': true},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      }),
      '/api/v1/auth/device/apple/begin' => () {
        appleBeginRequests++;
        return _response({
          'device_code': 'apple-device-code',
          'user_code': 'APPLE-1234',
          'verification_uri': 'https://open.xxread.top/account',
          'verification_uri_complete':
              'https://appleid.apple.com/auth/authorize?state=member_apple',
          'expires_in': 600,
          'interval': 5,
        });
      }(),
      _ => super.fetch(options, requestStream, cancelFuture),
    };
  }
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

Map<String, dynamic> _referralCampaign({
  String state = 'active',
  int target = 7,
}) => {
  'id': 'campaign-v2',
  'revision': 2,
  'enabled': state == 'active',
  'state': state,
  'title': '服务端邀请活动',
  'description': '最新服务端规则，达标后发奖。',
  'active_days': 3,
  'min_daily_seconds': 60,
  'bind_window_days': 7,
  'tiers': [
    {
      'id': 'active-main',
      'metric': 'active',
      'target': target,
      'reward_days': 120,
      'enabled': true,
    },
    {
      'id': 'paid-main',
      'metric': 'paid',
      'target': 4,
      'reward_days': null,
      'enabled': true,
    },
  ],
  'rules': ['服务端有效用户规则', '服务端付费用户规则'],
  'payment_channels': {
    'apple': 'automatic',
    'ldxp': 'verified_order',
    'google_play': 'manual_review',
  },
};

Map<String, dynamic> _initialReferralCampaign() => {
  ..._referralCampaign(),
  'tiers': [
    {
      'id': 'active-entry',
      'metric': 'active',
      'target': 2,
      'reward_days': 30,
      'enabled': true,
    },
    {
      'id': 'active-main',
      'metric': 'active',
      'target': 5,
      'reward_days': 90,
      'enabled': true,
    },
    {
      'id': 'active-lifetime',
      'metric': 'active',
      'target': 12,
      'reward_days': null,
      'enabled': false,
    },
    {
      'id': 'paid-lifetime',
      'metric': 'paid',
      'target': 2,
      'reward_days': null,
      'enabled': true,
    },
  ],
  'rules': [
    '达到 2 位有效新用户赠送 30 天。',
    '达到 5 位有效新用户累计赠送 90 天，已领 30 天时补发 60 天。',
    '达到 2 位首次付费好友赠送永久探元。',
  ],
};

Map<String, dynamic> _tierReward(
  String id, {
  required int target,
  int? days,
  bool revoked = false,
}) => {
  'tier_id': id,
  'metric': id.startsWith('paid') ? 'paid' : 'active',
  'target': target,
  'reward_days': days,
  'granted_at': '2026-10-07T00:00:00Z',
  'expires_at': days == null ? null : '2027-01-07T00:00:00Z',
  'revoked_at': revoked ? '2026-10-08T00:00:00Z' : null,
};

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
      '/api/v1/membership/reader/account-status' => () {
        final now = DateTime.now();
        final installationKey = options.headers['X-Origo-Reader-Key'] as String;
        return {
          'reader_access': {
            'unlocked': premium,
            'trial_active': false,
            'access': premium ? 'lifetime' : 'locked',
            'channel': 'account',
          },
          'offline_license': {
            'version': 2,
            'account_id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
            'subject_type': 'account',
            'permanent': premium,
            'upgrade_eligible': premium,
            'issued_at': now.toIso8601String(),
            'valid_until': now.add(const Duration(days: 30)).toIso8601String(),
            'reader_unlocked': premium,
            'installation_key_hash': sha256
                .convert(utf8.encode(installationKey))
                .toString(),
            'channel': 'account',
            'signature': 'opaque-test',
          },
        };
      }(),
      '/api/v1/membership/referral' => {
        'invite_code': 'OR-MY-CODE',
        'invite_url': 'https://open.xxread.top/account?invite=OR-MY-CODE',
        'stats': {'invited': 3, 'rewarded': 1, 'active': 2, 'paid': 1},
        'campaign': _referralCampaign(),
        'enrolled': true,
        'can_enroll': false,
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

class _PageApiClient extends MemberAccountApiClient {
  _PageApiClient({required super.dio, required super.tokenStore});

  @override
  Future<String?> offlineReaderSessionBinding() async => null;
}

class _UnavailablePurchaseStore implements PurchaseStore {
  const _UnavailablePurchaseStore();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: const [],
    notFoundIDs: identifiers.toList(),
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      false;

  @override
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  }) async => const {};

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}

class _MemoryReaderAccessCache extends ReaderAccessCache {
  @override
  Future<ReaderOfflineAttestation?> load({
    required ReaderInstallationCredential credential,
    required String channel,
    DateTime? now,
  }) async => null;

  @override
  Future<ReaderOfflineAttestation?> loadAccount({
    required ReaderInstallationCredential credential,
    required String? sessionBinding,
    String? accountId,
    DateTime? now,
  }) async => null;

  @override
  Future<void> save(ReaderOfflineAttestation value) async {}

  @override
  Future<void> saveAccount(
    ReaderOfflineAttestation value, {
    required String sessionBinding,
  }) async {}

  @override
  Future<void> clearAccount() async {}

  @override
  Future<void> clear() async {}
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

class _CachedDisplayPremiumAccount extends MemberAccountController {
  @override
  bool get initialized => true;

  @override
  bool get hasPremiumAccess => false;

  @override
  bool get premiumForDisplay => true;

  @override
  MemberUser get user => MemberUser(
    id: 'reader-1',
    email: 'reader@example.com',
    emailVerified: true,
    username: 'reader',
    effectiveName: 'Reader',
    authMethods: const ['password'],
    createdAt: DateTime.utc(2026, 1, 1),
  );

  @override
  Future<void> initialize({bool force = false}) async {}
}
