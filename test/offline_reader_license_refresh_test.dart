import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/account/offline_reader_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'refresh rotation rebinds an offline license for the same user',
    () async {
      final tokens = _MemoryTokenStore(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      const licenses = OfflineReaderLicenseStore();
      final client = _client(
        tokens,
        licenses,
        (_) => _json(_session(userId: _userId, refreshToken: 'refresh-2')),
      );
      final oldBinding = (await client.offlineReaderSessionBinding())!;
      final expiresAt = DateTime.utc(2027, 1, 1);
      await licenses.save(
        OfflineReaderLicense(userId: _userId, expiresAt: expiresAt),
        oldBinding,
      );

      await client.refreshSession();

      final newBinding = (await client.offlineReaderSessionBinding())!;
      expect(newBinding, isNot(oldBinding));
      expect(await licenses.load(oldBinding), isNull);
      final rebound = await licenses.load(newBinding);
      expect(rebound?.userId, _userId);
      expect(rebound?.expiresAt, expiresAt);
    },
  );

  test('refresh rotation never moves another account license', () async {
    final tokens = _MemoryTokenStore(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    const licenses = OfflineReaderLicenseStore();
    final client = _client(
      tokens,
      licenses,
      (_) => _json(_session(userId: 'another-user', refreshToken: 'refresh-2')),
    );
    final oldBinding = (await client.offlineReaderSessionBinding())!;
    await licenses.save(
      const OfflineReaderLicense(userId: _userId),
      oldBinding,
    );

    await client.refreshSession();

    final newBinding = (await client.offlineReaderSessionBinding())!;
    expect(await licenses.load(newBinding), isNull);
    expect((await licenses.load(oldBinding))?.userId, _userId);
  });

  test('rejected refresh revokes the license and emits invalidation', () async {
    final tokens = _MemoryTokenStore(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    const licenses = OfflineReaderLicenseStore();
    final client = _client(
      tokens,
      licenses,
      (_) => _json({'detail': 'session expired'}, statusCode: 401),
    );
    final binding = (await client.offlineReaderSessionBinding())!;
    await licenses.save(const OfflineReaderLicense(userId: _userId), binding);
    var invalidations = 0;
    final subscription = client.sessionInvalidations.listen(
      (_) => invalidations++,
    );
    addTearDown(subscription.cancel);

    await expectLater(
      client.refreshSession(),
      throwsA(
        isA<MemberAccountException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    await pumpEventQueue();

    expect(tokens.accessToken, isNull);
    expect(tokens.refreshToken, isNull);
    expect(await licenses.load(binding), isNull);
    expect(invalidations, 1);
  });

  test('network failure preserves the session and offline license', () async {
    final tokens = _MemoryTokenStore(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    );
    const licenses = OfflineReaderLicenseStore();
    final client = _client(tokens, licenses, (options) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'offline',
      );
    });
    final binding = (await client.offlineReaderSessionBinding())!;
    await licenses.save(const OfflineReaderLicense(userId: _userId), binding);
    var invalidations = 0;
    final subscription = client.sessionInvalidations.listen(
      (_) => invalidations++,
    );
    addTearDown(subscription.cancel);

    await expectLater(
      client.refreshSession(),
      throwsA(
        isA<MemberAccountException>().having(
          (error) => error.isTransientNetworkFailure,
          'isTransientNetworkFailure',
          isTrue,
        ),
      ),
    );
    await pumpEventQueue();

    expect(tokens.accessToken, 'access-1');
    expect(tokens.refreshToken, 'refresh-1');
    expect((await licenses.load(binding))?.userId, _userId);
    expect(invalidations, 0);
  });

  test(
    'explicit local session clear also clears the offline license',
    () async {
      final tokens = _MemoryTokenStore(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      );
      const licenses = OfflineReaderLicenseStore();
      final client = _client(
        tokens,
        licenses,
        (_) => throw StateError('request not expected'),
      );
      final binding = (await client.offlineReaderSessionBinding())!;
      await licenses.save(const OfflineReaderLicense(userId: _userId), binding);
      var invalidations = 0;
      final subscription = client.sessionInvalidations.listen(
        (_) => invalidations++,
      );
      addTearDown(subscription.cancel);

      await client.clearLocalSession();
      await pumpEventQueue();

      expect(await licenses.load(binding), isNull);
      expect(invalidations, 0);
    },
  );
}

const _userId = '6e29be31-ffeb-4699-bf69-8b37afe15504';

MemberAccountApiClient _client(
  MemberTokenStore tokens,
  OfflineReaderLicenseStore licenses,
  FutureOr<ResponseBody> Function(RequestOptions options) handler,
) {
  final dio = Dio()..httpClientAdapter = _Adapter(handler);
  return MemberAccountApiClient(
    dio: dio,
    tokenStore: tokens,
    offlineReaderLicenseStore: licenses,
  );
}

Map<String, dynamic> _session({
  required String userId,
  required String refreshToken,
}) => {
  'token_type': 'bearer',
  'access_token': 'access-2',
  'refresh_token': refreshToken,
  'access_expires_in': 900,
  'refresh_expires_in': 2592000,
  'mfa_required': false,
  'user': {
    'id': userId,
    'email': 'reader@example.com',
    'username': 'reader',
    'display_name': 'Reader',
    'effective_name': 'Reader',
    'avatar_url': null,
    'providers': ['password'],
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  },
};

ResponseBody _json(Map<String, dynamic> value, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(value),
      statusCode,
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

class _MemoryTokenStore implements MemberTokenStore {
  _MemoryTokenStore({this.accessToken, this.refreshToken});

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
