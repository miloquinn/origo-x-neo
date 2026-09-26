import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/reading/reading_account_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'cancelling an in-flight authorization discards it before a new login',
    () async {
      final tokens = _MemoryTokenStore();
      final pending = _MemoryPendingAuthorizationStore();
      final adapter = _CancellationAdapter();
      final readingScope = ReadingAccountScope();
      final controller = MemberAccountController(
        api: MemberAccountApiClient(
          dio: Dio()..httpClientAdapter = adapter,
          tokenStore: tokens,
        ),
        pendingAuthorizationStore: pending,
        readingScope: readingScope,
      );
      addTearDown(controller.dispose);
      addTearDown(readingScope.dispose);

      final oldAuthorization = await controller.beginExternalLogin(
        MemberExternalAuthMethod.github,
      );
      final oldPoll = controller.pollDeviceAuthorization(oldAuthorization);
      await adapter.oldPollStarted.future;

      final cancellation = controller.cancelPendingDeviceAuthorization();
      expect(controller.pendingDeviceAuthorization, isNull);
      adapter.releaseOldPoll.complete();

      await cancellation;
      expect(await oldPoll, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(tokens.accessToken, isNull);
      expect(tokens.refreshToken, isNull);
      expect(pending.payload, isNull);

      final newAuthorization = await controller.beginExternalLogin(
        MemberExternalAuthMethod.google,
      );
      expect(newAuthorization.deviceCode, 'new-device');
      expect(controller.pendingDeviceAuthorization?.deviceCode, 'new-device');
      expect(pending.payload, contains('new-device'));

      expect(
        await controller.pollDeviceAuthorization(newAuthorization),
        isTrue,
      );
      expect(controller.user?.username, 'reader');
      expect(tokens.accessToken, 'new-access');
      expect(tokens.refreshToken, 'new-refresh');
      expect(controller.pendingDeviceAuthorization, isNull);
      expect(pending.payload, isNull);
    },
  );

  test('a password login waits for cancellation cleanup', () async {
    final tokens = _MemoryTokenStore();
    final pending = _MemoryPendingAuthorizationStore();
    final adapter = _CancellationAdapter();
    final readingScope = ReadingAccountScope();
    final controller = MemberAccountController(
      api: MemberAccountApiClient(
        dio: Dio()..httpClientAdapter = adapter,
        tokenStore: tokens,
      ),
      pendingAuthorizationStore: pending,
      readingScope: readingScope,
    );
    addTearDown(controller.dispose);
    addTearDown(readingScope.dispose);

    final authorization = await controller.beginExternalLogin(
      MemberExternalAuthMethod.github,
    );
    final oldPoll = controller.pollDeviceAuthorization(authorization);
    await adapter.oldPollStarted.future;

    final cancellation = controller.cancelPendingDeviceAuthorization();
    final passwordLogin = controller.loginPassword(
      'reader@example.com',
      'correct-password',
    );
    expect(controller.loading, isTrue);
    adapter.releaseOldPoll.complete();

    await cancellation;
    expect(await oldPoll, isFalse);
    await passwordLogin;

    expect(controller.user?.username, 'reader');
    expect(tokens.accessToken, 'password-access');
    expect(tokens.refreshToken, 'password-refresh');
  });
}

class _CancellationAdapter implements HttpClientAdapter {
  final oldPollStarted = Completer<void>();
  final releaseOldPoll = Completer<void>();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('/device/github/begin')) {
      return _json(_authorization('old-device', 'OLD-DEVICE'));
    }
    if (options.uri.path.endsWith('/device/google/begin')) {
      return _json(_authorization('new-device', 'NEW-DEVICE'));
    }
    if (options.uri.path.endsWith('/device/token')) {
      final deviceCode = (options.data as Map)['device_code'];
      if (deviceCode == 'old-device') {
        oldPollStarted.complete();
        await releaseOldPoll.future;
        return _json(_session('old-access', 'old-refresh'));
      }
      return _json(_session('new-access', 'new-refresh'));
    }
    if (options.uri.path.endsWith('/password/login')) {
      return _json(_session('password-access', 'password-refresh'));
    }
    if (options.uri.path.endsWith('/membership')) {
      return _json({
        'premium': false,
        'features': <String, bool>{},
        'entitlements': <Object>[],
      });
    }
    throw StateError('Unexpected route ${options.uri.path}');
  }

  Map<String, Object?> _authorization(String deviceCode, String userCode) => {
    'device_code': deviceCode,
    'user_code': userCode,
    'verification_uri': '/activate',
    'expires_in': 600,
    'interval': 5,
  };

  Map<String, Object?> _session(String access, String refresh) => {
    'token_type': 'bearer',
    'access_token': access,
    'refresh_token': refresh,
    'access_expires_in': 900,
    'refresh_expires_in': 2592000,
    'mfa_required': false,
    'user': {
      'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
      'email': 'reader@example.com',
      'email_verified': true,
      'username': 'reader',
      'display_name': 'Reader',
      'effective_name': 'Reader',
      'avatar_url': null,
      'auth_methods': ['google'],
      'created_at': '2026-08-03T00:00:00Z',
    },
  };

  ResponseBody _json(Map<String, Object?> body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

class _MemoryTokenStore implements MemberTokenStore {
  String? accessToken;
  String? refreshToken;
  bool mfaPending = false;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    mfaPending = false;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<bool> readMfaPending() async => mfaPending;

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

class _MemoryPendingAuthorizationStore
    implements PendingDeviceAuthorizationStore {
  String? payload;

  @override
  Future<void> clear() async => payload = null;

  @override
  Future<String?> read() async => payload;

  @override
  Future<void> save(String payload) async => this.payload = payload;
}
