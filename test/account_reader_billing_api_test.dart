import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'reader status is anonymous and carries installation credential',
    () async {
      late RequestOptions request;
      final api = _api((value) {
        request = value;
        return _json(_readerResult());
      });

      final result = await api.readerStatus('google_play');

      expect(request.path, endsWith('/reader/status?channel=google_play'));
      expect(request.headers['Authorization'], isNull);
      expect(request.headers['X-Origo-Reader-Key'], isNotEmpty);
      expect(result.readerAccess.hasPermanentAccess, isTrue);
    },
  );

  test('premium purchase carries both bearer and reader credential', () async {
    late RequestOptions request;
    final tokens = _Tokens(access: 'access-token');
    final api = _api((value) {
      request = value;
      return _json({
        'premium': true,
        'features': const <String, bool>{},
        'entitlements': const <Object>[],
      });
    }, tokens: tokens);

    await api.submitPremiumGooglePurchase('purchase-token');

    expect(request.path, endsWith('/premium/google/purchase'));
    expect(request.headers['Authorization'], 'Bearer access-token');
    expect(request.headers['X-Origo-Reader-Key'], isNotEmpty);
    expect(request.data, {'purchase_token': 'purchase-token'});
  });
}

MemberAccountApiClient _api(
  FutureOr<ResponseBody> Function(RequestOptions options) handler, {
  _Tokens? tokens,
}) {
  final dio = Dio()..httpClientAdapter = _Adapter(handler);
  return MemberAccountApiClient(dio: dio, tokenStore: tokens ?? _Tokens());
}

Map<String, Object?> _readerResult() {
  final now = DateTime.now();
  return {
    'reader_access': {
      'unlocked': true,
      'trial_active': false,
      'access': 'lifetime',
      'channel': 'google_play',
      'trial_started_at': null,
      'trial_expires_at': null,
    },
    'offline_license': {
      'version': 1,
      'issued_at': now.toIso8601String(),
      'valid_until': now.add(const Duration(days: 30)).toIso8601String(),
      'reader_unlocked': true,
      'trial_expires_at': null,
      'installation_key_hash': 'server-hash',
      'channel': 'google_play',
      'signature': 'opaque',
    },
  };
}

ResponseBody _json(Map<String, Object?> value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  @override
  void close({bool force = false}) {}
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);
}

class _Tokens implements MemberTokenStore {
  _Tokens({this.access});
  String? access;
  @override
  Future<void> clear() async => access = null;
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<bool> readMfaPending() async => false;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async => access = accessToken;
}
