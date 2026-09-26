import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'security overview stays compact and email verification shows one method',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final controller = MemberAccountController(
        api: MemberAccountApiClient(
          dio: Dio()..httpClientAdapter = _SecurityAdapter(),
          tokenStore: _SecurityTokenStore(),
        ),
      );
      addTearDown(controller.dispose);
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

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('account-security')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('account-security')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('account-change-email')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('account-change-password')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('account-mfa-setup')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-login-methods')),
        findsOneWidget,
      );
      expect(find.text('密码'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account-login-methods')));
      await tester.pumpAndSettle();
      expect(find.text('登录方式'), findsWidgets);
      expect(find.text('密码'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('account-change-email')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'new@example.com');
      await tester.tap(
        find.byKey(const ValueKey('account-change-email-submit')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('account-current-verification-picker')),
        findsOneWidget,
      );
      expect(find.text('当前邮箱验证码'), findsOneWidget);
      expect(find.text('当前密码（可代替验证码）'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('account-verify-current-password')),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前邮箱验证码'), findsNothing);
      expect(find.text('当前密码（可代替验证码）'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -320));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('account-change-email-submit')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _SecurityAdapter implements HttpClientAdapter {
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
        'premium': false,
        'features': <String, bool>{},
        'entitlements': <Object>[],
      },
      '/api/v1/membership/referral' => {
        'invite_code': 'OR-SECURITY',
        'invite_url': 'https://open.xxread.top/account?invite=OR-SECURITY',
        'stats': {'invited': 0, 'rewarded': 0},
        'inviter': null,
      },
      '/api/v1/auth/security/mfa/status' => {
        'enabled': false,
        'recovery_codes_remaining': 0,
      },
      '/api/v1/auth/security/email/code' => {
        'current': {'challenge_id': 'current-id', 'expires_in': 600},
        'new': {'challenge_id': 'new-id', 'expires_in': 600},
        'message': 'sent',
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

class _SecurityTokenStore implements MemberTokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'access-token';

  @override
  Future<bool> readMfaPending() async => false;

  @override
  Future<String?> readRefreshToken() async => 'refresh-token';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async {}
}
