import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  testWidgets('capture implemented account screens from the production page', (
    tester,
  ) async {
    // This file is a Flutter test entry point and intentionally uses the test-only mock.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(_loadFonts);

    final guest = await _pumpAccount(tester, _CaptureAdapter());
    addTearDown(guest.dispose);
    await _capture(tester, 'implemented-login.png');

    await tester.enterText(
      find.byKey(const ValueKey('account-auth-email')),
      'reader@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('account-email-continue')));
    await tester.pumpAndSettle();
    await _capture(tester, 'implemented-password.png');

    await tester.tap(find.byKey(const ValueKey('account-change-email')));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      0,
      reason: 'Registration details should fit a normal 390x844 phone.',
    );
    await _capture(tester, 'implemented-register-details.png');

    final darkGuest = await _pumpAccount(
      tester,
      _CaptureAdapter(),
      themeMode: ThemeMode.dark,
    );
    addTearDown(darkGuest.dispose);
    await _capture(tester, 'implemented-login-dark.png');

    final member = await _pumpAccount(
      tester,
      _CaptureAdapter(signedIn: true),
      tokenStore: _CaptureTokenStore.signedIn(),
    );
    addTearDown(member.dispose);
    await _capture(tester, 'implemented-account-premium.png');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('account-security')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('account-security')));
    await tester.pumpAndSettle();
    await _capture(tester, 'implemented-security.png');

    expect(tester.takeException(), isNull);
  });
}

Future<void> _loadFonts() async {
  final chinese = await File(
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ).readAsBytes();
  await (FontLoader(
    'AccountProduction',
  )..addFont(Future.value(ByteData.sublistView(chinese)))).load();
  final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
  final icons = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(icons)))).load();
}

Future<MemberAccountController> _pumpAccount(
  WidgetTester tester,
  HttpClientAdapter adapter, {
  ThemeMode themeMode = ThemeMode.light,
  MemberTokenStore? tokenStore,
}) async {
  final controller = MemberAccountController(
    api: MemberAccountApiClient(
      dio: Dio()..httpClientAdapter = adapter,
      tokenStore: tokenStore ?? _CaptureTokenStore(),
    ),
  );
  await tester.runAsync(controller.initialize);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('capture-account-production'),
      child: ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(
          key: ValueKey('account-${identityHashCode(controller)}-$themeMode'),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1976D2),
            ),
            fontFamily: 'AccountProduction',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1976D2),
              brightness: Brightness.dark,
            ),
            fontFamily: 'AccountProduction',
          ),
          themeMode: themeMode,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AccountPage(),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/app_icon.png'),
      tester.element(find.byType(AccountPage)),
    );
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  return controller;
}

Future<void> _capture(WidgetTester tester, String filename) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture-account-production')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/previews/account-redesign/$filename');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({this.signedIn = false});

  final bool signedIn;

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
        'providers': {'google': true, 'github': true, 'passkey': true},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      },
      '/api/v1/membership/config' => {
        'product': 'premium_lifetime',
        'features': <String>[],
      },
      '/api/v1/auth/password/register/code' => {
        'challenge_id': 'capture-registration',
        'expires_in': 600,
        'message': '验证码已发送至 reader@example.com',
      },
      '/api/v1/auth/me' when signedIn => {'mfa_required': false, 'user': _user},
      '/api/v1/membership' when signedIn => {
        'premium': true,
        'features': <String, bool>{},
        'entitlements': <Object>[],
      },
      '/api/v1/auth/security/mfa/status' when signedIn => {
        'enabled': false,
        'recovery_codes_remaining': 0,
      },
      _ => throw StateError('Unexpected capture route ${options.uri.path}'),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  static final Map<String, dynamic> _user = {
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
}

class _CaptureTokenStore implements MemberTokenStore {
  _CaptureTokenStore();

  _CaptureTokenStore.signedIn()
    : accessToken = 'capture-access',
      refreshToken = 'capture-refresh';

  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<bool> readMfaPending() async => false;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}
