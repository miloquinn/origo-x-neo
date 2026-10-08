import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'disabled transport rejects account and reading requests before HTTP',
    () async {
      final adapter = _AsyncAdapter((_) async => _json({}));
      final api = _client(adapter, _MemoryTokenStore(accessToken: 'access'));
      api.setNetworkAllowed(false);

      await expectLater(api.authConfig(), _throwsLegalConsentRequired);
      await expectLater(
        api.readingRequest('GET', 'summary', 'reader-id'),
        _throwsLegalConsentRequired,
      );

      expect(adapter.requests, isEmpty);
    },
  );

  test(
    'enabling controller transport allows lifecycle synchronization',
    () async {
      final adapter = _AsyncAdapter((options) async {
        return switch (options.uri.path) {
          '/api/v1/auth/config' => _json({'providers': <String, Object?>{}}),
          '/api/v1/membership/config' => _json({
            'product': 'premium_lifetime',
            'features': <Object?>[],
          }),
          _ => throw StateError('Unexpected route ${options.uri.path}'),
        };
      });
      final controller = MemberAccountController(
        api: _client(adapter, _MemoryTokenStore()),
        networkAllowed: false,
      );
      addTearDown(controller.dispose);

      await controller.synchronize();
      expect(adapter.requests, isEmpty);

      controller.setNetworkAllowed(true);
      await controller.synchronize();

      expect(
        adapter.requests.map((request) => request.uri.path),
        unorderedEquals(<String>[
          '/api/v1/auth/config',
          '/api/v1/membership/config',
        ]),
      );
    },
  );

  test(
    'revoked request generation cannot refresh after permission returns',
    () async {
      final firstResponse = Completer<ResponseBody>();
      final requestStarted = Completer<void>();
      final tokens = _MemoryTokenStore(
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      final adapter = _AsyncAdapter((_) {
        if (!requestStarted.isCompleted) requestStarted.complete();
        return firstResponse.future;
      });
      final api = _client(adapter, tokens);

      final request = api.readingRequest('GET', 'summary', 'reader-id');
      await requestStarted.future;
      api.setNetworkAllowed(false);
      api.setNetworkAllowed(true);
      firstResponse.complete(
        _json({
          'detail': {'code': 'invalid_access_token'},
        }, status: 401),
      );

      await expectLater(request, _throwsLegalConsentRequired);
      expect(adapter.requests, hasLength(1));
      expect(tokens.accessToken, 'access');
      expect(tokens.refreshToken, 'refresh');
    },
  );

  test(
    'legal permission interruption preserves signed-in account state',
    () async {
      final pendingMembership = Completer<ResponseBody>();
      final refreshStarted = Completer<void>();
      var membershipRequests = 0;
      final tokens = _MemoryTokenStore();
      final adapter = _AsyncAdapter((options) async {
        return switch (options.uri.path) {
          '/api/v1/auth/password/login' => _json(_session()),
          '/api/v1/membership' => () {
            membershipRequests++;
            if (membershipRequests == 1) {
              return Future<ResponseBody>.value(_membership());
            }
            if (!refreshStarted.isCompleted) refreshStarted.complete();
            return pendingMembership.future;
          }(),
          '/api/v1/membership/reader/account-status' => _json({
            'detail': 'temporarily unavailable',
          }, status: 503),
          '/api/v1/membership/referral' => _json({
            'invite_code': 'TEST',
            'invite_url': 'https://example.test/invite',
          }),
          _ => throw StateError('Unexpected route ${options.uri.path}'),
        };
      });
      final controller = MemberAccountController(api: _client(adapter, tokens));
      addTearDown(controller.dispose);

      await controller.loginPassword('reader@example.com', 'secret');
      final signedInUser = controller.user;
      expect(signedInUser, isNotNull);
      expect(controller.hasPremiumAccess, isTrue);

      final refresh = controller.loadMembership();
      await refreshStarted.future;
      controller.setNetworkAllowed(false);
      controller.setNetworkAllowed(true);
      pendingMembership.complete(_membership());

      await expectLater(refresh, _throwsLegalConsentRequired);
      expect(controller.user, same(signedInUser));
      expect(controller.hasPremiumAccess, isTrue);
      expect(tokens.accessToken, 'access');
      expect(tokens.refreshToken, 'refresh');
    },
  );

  test('disabling transport cancels a scheduled membership retry', () async {
    final releaseResponses = Completer<void>();
    final initialRequestsStarted = Completer<void>();
    var requestCount = 0;
    final adapter = _AsyncAdapter((options) async {
      await releaseResponses.future;
      return switch (options.uri.path) {
        '/api/v1/auth/config' => _json({'providers': <String, Object?>{}}),
        '/api/v1/membership/config' => _json({
          'product': 'premium_lifetime',
          'features': <Object?>[],
        }),
        _ => throw StateError('Unexpected route ${options.uri.path}'),
      };
    });
    adapter.onRequest = () {
      requestCount++;
      if (requestCount == 2 && !initialRequestsStarted.isCompleted) {
        initialRequestsStarted.complete();
      }
    };
    final controller = MemberAccountController(
      api: _client(adapter, _MemoryTokenStore()),
      membershipRetryDelay: const Duration(milliseconds: 20),
    );
    addTearDown(controller.dispose);

    final initialization = controller.initialize();
    await initialRequestsStarted.future;
    await controller.synchronize();
    controller.setNetworkAllowed(false);
    controller.setNetworkAllowed(true);
    releaseResponses.complete();
    await initialization;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(adapter.requests, hasLength(2));
  });
}

final Matcher _throwsLegalConsentRequired = throwsA(
  isA<MemberAccountException>().having(
    (error) => error.code,
    'code',
    MemberAccountException.legalConsentRequiredCode,
  ),
);

MemberAccountApiClient _client(
  HttpClientAdapter adapter,
  MemberTokenStore tokens,
) {
  final dio = Dio()..httpClientAdapter = adapter;
  return MemberAccountApiClient(dio: dio, tokenStore: tokens);
}

ResponseBody _json(Map<String, Object?> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

ResponseBody _membership() => _json({
  'premium': true,
  'user_id': 'reader-id',
  'features': <String, bool>{},
  'entitlements': <Object?>[],
});

Map<String, Object?> _session() => {
  'token_type': 'bearer',
  'access_token': 'access',
  'refresh_token': 'refresh',
  'access_expires_in': 900,
  'refresh_expires_in': 2592000,
  'mfa_required': false,
  'user': <String, Object?>{
    'id': 'reader-id',
    'email': 'reader@example.com',
    'email_verified': true,
    'username': 'reader',
    'display_name': 'Reader',
    'effective_name': 'Reader',
    'avatar_url': null,
    'auth_methods': <String>['password'],
    'created_at': '2026-08-03T00:00:00Z',
  },
};

class _AsyncAdapter implements HttpClientAdapter {
  _AsyncAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];
  void Function()? onRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    onRequest?.call();
    return handler(options);
  }
}

class _MemoryTokenStore implements MemberTokenStore {
  _MemoryTokenStore({this.accessToken, this.refreshToken});

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
