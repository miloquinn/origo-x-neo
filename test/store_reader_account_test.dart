import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/services/core/legacy_reader_access.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    LegacyReaderAccess.debugReset();
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );
  });
  tearDown(() {
    LegacyReaderAccess.debugReset();
    AppDistribution.debugReset();
  });

  test('an expired trial cannot be offered again', () async {
    final fixture = _Fixture((request) {
      if (request.uri.path.endsWith('/reader/status')) {
        final result = _readerResult(request, 'locked');
        (result['reader_access'] as Map<String, Object?>).addAll({
          'trial_started_at': DateTime.now()
              .subtract(const Duration(days: 15))
              .toIso8601String(),
          'trial_expires_at': DateTime.now()
              .subtract(const Duration(days: 1))
              .toIso8601String(),
        });
        return _json(result);
      }
      return _routes(request, access: 'locked');
    });
    final account = fixture.account();
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.hasReaderAccess, isFalse);
    expect(account.canStartReaderTrial, isFalse);
  });

  test('test lifetime and Premium are independent ephemeral grants', () async {
    final store = _TestStore();
    addTearDown(store.close);
    var revoked = false;
    final fixture = _Fixture((request) {
      if (request.uri.path.endsWith('/reader/google/account-purchase')) {
        return _json({
          ..._readerResult(request, 'locked'),
          'test_purchase': true,
          'purchase_status': revoked ? 'revoked' : 'active',
          'test_access': revoked
              ? null
              : {
                  'kind': 'reader_lifetime',
                  'reader': true,
                  'premium': false,
                  'expires_at': null,
                },
        });
      }
      if (request.uri.path.endsWith('/premium/google/purchase')) {
        return _json({
          'user_id': _userId,
          'premium': false,
          'features': <String, bool>{},
          'entitlements': <Object>[],
          'test_purchase': true,
          'purchase_status': 'active',
          'test_access': {
            'kind': 'premium_lifetime',
            'reader': true,
            'premium': true,
            'expires_at': null,
          },
        });
      }
      return _routes(request, access: 'locked');
    });
    final account = fixture.account(store: store);
    addTearDown(account.dispose);
    await account.initialize();
    await account.loginPassword('reader@example.com', 'password');
    store.emit('origo_x_reader_lifetime', 'reader-test');
    await pumpEventQueue(times: 30);
    expect(account.hasPermanentReaderAccess, isTrue);
    expect(account.hasAdvancedSourceAccess, isFalse);
    await account.purchaseStorePremium(); // fresh Production status is locked.
    store.emit('origo_x_premium_lifetime', 'premium-test');
    await pumpEventQueue(times: 30);
    expect(account.hasPremiumAccess, isFalse);
    expect(account.hasAdvancedSourceAccess, isTrue);
    await account.logout();
    expect(account.hasPermanentReaderAccess, isFalse);
    expect(account.hasAdvancedSourceAccess, isFalse);
    final restarted = fixture.account();
    addTearDown(restarted.dispose);
    await restarted.initialize();
    expect(restarted.hasPermanentReaderAccess, isFalse);
    revoked = true;
    store.emit('origo_x_reader_lifetime', 'reader-refunded');
    await pumpEventQueue(times: 30);
    expect(account.hasReaderAccess, isFalse);
  });

  test('sandbox trial cannot reveal or buy Premium and expires', () async {
    final store = _TestStore();
    addTearDown(store.close);
    var expired = false;
    final fixture = _Fixture((request) {
      if (request.uri.path.endsWith('/reader/google/account-purchase')) {
        return _json({
          ..._readerResult(request, 'locked'),
          'test_purchase': true,
          'test_access': {
            'kind': 'reader_trial',
            'reader': true,
            'premium': false,
            'expires_at': DateTime.now()
                .add(Duration(days: expired ? -1 : 14))
                .toIso8601String(),
          },
        });
      }
      return _routes(request, access: 'locked');
    });
    final account = fixture.account(store: store);
    addTearDown(account.dispose);
    await account.initialize();
    await account.loginPassword('reader@example.com', 'password');
    store.emit('origo_x_reader_lifetime', 'trial-test');
    await pumpEventQueue(times: 30);
    expect(account.hasReaderAccess, isTrue);
    expect(account.hasActiveReaderTrial, isTrue);
    expect(account.hasPermanentReaderAccess, isFalse);
    expect(account.canPurchaseStorePremium, isFalse);
    expired = true;
    store.emit('origo_x_reader_lifetime', 'trial-expired');
    await pumpEventQueue(times: 30);
    expect(account.hasReaderAccess, isFalse);
  });

  test(
    'account reader trial requires login and never grants advanced sources',
    () async {
      var trialStarted = false;
      final fixture = _Fixture((request) {
        if (request.uri.path.endsWith('/reader/account-trial')) {
          trialStarted = true;
        }
        return _routes(request, access: trialStarted ? 'trial' : 'locked');
      });
      final account = fixture.account();
      addTearDown(account.dispose);

      await account.initialize();
      expect(account.isAuthenticated, isFalse);
      expect(account.hasReaderAccess, isFalse);
      expect(account.canStartReaderTrial, isTrue);

      await account.loginPassword('reader@example.com', 'password');
      await account.startReaderTrial();

      expect(trialStarted, isTrue);
      expect(account.hasActiveReaderTrial, isTrue);
      expect(account.hasReaderAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isFalse);
      expect(account.hasPremiumAccess, isFalse);
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.canPurchaseStorePremium, isFalse);
    },
  );

  test('reader lifetime survives Origo login and logout', () async {
    final fixture = _Fixture((request) => _routes(request, access: 'lifetime'));
    final account = fixture.account();
    addTearDown(account.dispose);

    await account.initialize();
    expect(account.hasPermanentReaderAccess, isTrue);
    await account.loginPassword('reader@example.com', 'password');
    expect(account.isAuthenticated, isTrue);
    expect(account.hasPermanentReaderAccess, isTrue);

    await account.logout();

    expect(account.isAuthenticated, isFalse);
    expect(account.hasPermanentReaderAccess, isTrue);
    expect(account.hasReaderAccess, isTrue);
  });

  test('trial owner cannot purchase account Premium', () async {
    final fixture = _Fixture((request) => _routes(request, access: 'trial'));
    final account = fixture.account();
    addTearDown(account.dispose);

    await account.initialize();
    await account.loginPassword('reader@example.com', 'password');

    expect(account.hasActiveReaderTrial, isTrue);
    expect(account.canPurchaseStorePremium, isFalse);
    await expectLater(
      account.purchaseStorePremium(),
      throwsA(
        isA<MemberAccountException>().having(
          (value) => value.message,
          'message',
          contains('开卷'),
        ),
      ),
    );
  });

  test(
    'guest purchases and trials never start a store or server payment',
    () async {
      final store = _TestStore();
      addTearDown(store.close);
      final account = _Fixture(
        (r) => _routes(r, access: 'locked'),
      ).account(store: store);
      addTearDown(account.dispose);
      await account.initialize();
      for (final action in [
        account.purchaseReaderLifetime,
        account.startReaderTrial,
        account.restoreReaderPurchases,
        account.purchaseStorePremiumBundle,
      ]) {
        await expectLater(action(), throwsA(isA<MemberAccountException>()));
      }
      expect(store.lastPurchase, isNull);
    },
  );

  test(
    'Apple beta purchase entry points never start a store payment',
    () async {
      await _enableAppleBeta();
      final store = _TestStore();
      addTearDown(store.close);
      final account = _Fixture(
        (request) => _routes(request, access: 'locked'),
      ).account(store: store);
      addTearDown(account.dispose);

      await account.purchaseReaderLifetime();
      await account.startReaderTrial();
      await account.purchaseStorePremium();
      await account.purchaseStorePremiumBundle();

      expect(store.lastPurchase, isNull);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.hasPremiumAccess, isFalse);
      expect(account.membership, isNull);

      AppDistribution.debugReset();
      expect(account.hasAdvancedSourceAccess, isFalse);
    },
  );

  test('account-owned reader is cross-store and removed on logout', () async {
    final fixture = _Fixture(
      (request) => _routes(
        request,
        access: request.uri.path.contains('account-') ? 'lifetime' : 'locked',
      ),
    );
    final account = fixture.account();
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.hasReaderAccess, isFalse);
    await account.loginPassword('reader@example.com', 'password');
    expect(account.readerAccess?.channel, 'account');
    expect(account.hasPermanentReaderAccess, isTrue);
    expect(account.hasAccountReaderUpgradeEligibility, isTrue);
    await account.logout();
    expect(account.hasReaderAccess, isFalse);
    expect(account.hasAccountReaderUpgradeEligibility, isFalse);
  });

  test('signed account attestation keeps Explore available offline', () async {
    final key = base64UrlEncode(List<int>.generate(32, (index) => index));
    final now = DateTime.now();
    const refresh = 'offline-refresh';
    FlutterSecureStorage.setMockInitialValues({
      ReaderInstallationCredentialStore.storageKey: key,
      ReaderAccessCache.accountStorageKey: jsonEncode({
        'session_binding': sha256.convert(utf8.encode(refresh)).toString(),
        'license': {
          'version': 2,
          'account_id': _userId,
          'subject_type': 'account',
          'permanent': true,
          'derived_from_premium': true,
          'upgrade_eligible': false,
          'issued_at': now.toIso8601String(),
          'valid_until': now.add(const Duration(days: 7)).toIso8601String(),
          'reader_unlocked': true,
          'trial_expires_at': null,
          'installation_key_hash': sha256.convert(utf8.encode(key)).toString(),
          'channel': 'account',
          'signature': 'opaque-server-attestation',
        },
      }),
    });
    final tokens = _Tokens(access: 'offline-access', refresh: refresh);
    final account = _accountWithRoutes(tokens, (request) {
      if (request.uri.path == '/api/v1/auth/me') return _json(_session());
      if (request.uri.path == '/api/v1/membership/referral') {
        return _json({
          'invite_code': 'TEST',
          'invite_url': 'https://example.test/invite',
        });
      }
      if (request.uri.path == '/api/v1/auth/config' ||
          request.uri.path == '/api/v1/membership/config') {
        return _routes(request, access: 'locked');
      }
      return _json({'detail': 'offline'}, statusCode: 503);
    });
    addTearDown(account.dispose);

    await account.initialize();

    expect(account.isAuthenticated, isTrue);
    expect(account.hasPremiumAccess, isFalse);
    expect(account.hasAdvancedSourceAccess, isTrue);
  });

  test('online refund replaces an older premium-derived attestation', () async {
    var premium = true;
    var derivedFromPremium = true;
    var offline = false;
    final tokens = _Tokens();
    FutureOr<ResponseBody> routes(RequestOptions request) {
      if (request.uri.path == '/api/v1/membership') {
        if (offline) return _json({'detail': 'offline'}, statusCode: 503);
        return _json({
          'user_id': _userId,
          'premium': premium,
          'features': const <String, bool>{},
          'entitlements': const <Object>[],
        });
      }
      if (request.uri.path.endsWith('/reader/account-status')) {
        if (offline) return _json({'detail': 'offline'}, statusCode: 503);
        return _json(
          _readerResult(
            request,
            derivedFromPremium ? 'lifetime' : 'locked',
            derivedFromPremium: derivedFromPremium,
          ),
        );
      }
      if (request.uri.path == '/api/v1/auth/me') return _json(_session());
      return _routes(request, access: 'locked');
    }

    final account = _accountWithRoutes(tokens, routes);
    await account.initialize();
    await account.loginPassword('reader@example.com', 'password');
    expect(account.hasAdvancedSourceAccess, isTrue);

    premium = false;
    derivedFromPremium = false;
    await account.synchronize();
    expect(account.hasAdvancedSourceAccess, isFalse);

    account.dispose();
    offline = true;
    final restarted = _accountWithRoutes(tokens, routes);
    addTearDown(restarted.dispose);
    await restarted.initialize();
    expect(restarted.hasPremiumAccess, isFalse);
    expect(restarted.hasAdvancedSourceAccess, isFalse);
  });

  test(
    'delayed account reader response cannot restore rights after logout',
    () async {
      final delayed = Completer<ResponseBody>();
      var delay = false;
      final fixture = _Fixture((r) {
        if (delay && r.uri.path.endsWith('/reader/account-status')) {
          return delayed.future;
        }
        return _routes(r, access: 'locked');
      });
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      await account.loginPassword('reader@example.com', 'password');
      delay = true;
      final refresh = account.refreshReaderAccess();
      await pumpEventQueue();
      await account.logout();
      final credential = await const ReaderInstallationCredentialStore()
          .getOrCreate();
      final request = RequestOptions(
        path: '/reader/account-status',
        headers: {'X-Origo-Reader-Key': credential.value},
      );
      delayed.complete(_json(_readerResult(request, 'lifetime')));
      await refresh;
      expect(account.isAuthenticated, isFalse);
      expect(account.hasReaderAccess, isFalse);
    },
  );

  test(
    'full Explore and Read-owner upgrade use different store products',
    () async {
      var ownsReader = false;
      final store = _TestStore();
      addTearDown(store.close);
      final fixture = _Fixture(
        (r) => _routes(
          r,
          access: ownsReader && r.uri.path.contains('account-')
              ? 'lifetime'
              : 'locked',
        ),
      );
      final account = fixture.account(store: store);
      addTearDown(account.dispose);
      await account.initialize();
      await account.loginPassword('reader@example.com', 'password');
      await expectLater(
        account.purchaseStorePremium(),
        throwsA(isA<MemberAccountException>()),
      );
      await account.purchaseStorePremiumBundle();
      expect(
        store.lastPurchase?.productDetails.id,
        'origo_x_explorer_lifetime',
      );
      expect(
        store.lastPurchase?.applicationUserName,
        sha256.convert(utf8.encode(_userId)).toString(),
      );
      ownsReader = true;
      await account.refreshReaderAccess();
      await expectLater(
        account.purchaseStorePremiumBundle(),
        throwsA(isA<MemberAccountException>()),
      );
      await account.purchaseStorePremium();
      expect(store.lastPurchase?.productDetails.id, 'origo_x_premium_lifetime');
    },
  );

  test(
    'Explore alone includes reading; refund preserves separate Read',
    () async {
      var premium = true;
      var reader = false;
      final fixture = _Fixture((r) {
        if (r.uri.path == '/api/v1/membership') {
          return _json({
            'user_id': _userId,
            'premium': premium,
            'features': <String, bool>{},
            'entitlements': <Object>[],
          });
        }
        return _routes(
          r,
          access: reader && r.uri.path.contains('account-')
              ? 'lifetime'
              : 'locked',
        );
      });
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      await account.loginPassword('reader@example.com', 'password');
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.hasReaderAccess, isTrue);
      premium = false;
      await account.loadMembership();
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasReaderAccess, isFalse);
      reader = true;
      await account.loadMembership();
      await account.refreshReaderAccess();
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasReaderAccess, isTrue);
    },
  );

  test('website distribution has built-in permanent reader access', () async {
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.direct,
      readerLicenseRequired: true,
    );
    final fixture = _Fixture((request) => _routes(request, access: 'locked'));
    final account = fixture.account();
    addTearDown(account.dispose);
    await account.initialize();
    expect(account.hasReaderAccess, isTrue);
    expect(account.hasPermanentReaderAccess, isTrue);
  });

  test(
    'release bypass does not consume or hide the real store trial',
    () async {
      AppDistribution.debugOverride(
        channel: AppDistributionChannel.googlePlay,
        readerLicenseRequired: false,
      );
      var trialStarted = false;
      final fixture = _Fixture((request) {
        if (request.uri.path.endsWith('/reader/account-trial')) {
          trialStarted = true;
        }
        return _routes(request, access: trialStarted ? 'trial' : 'locked');
      });
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      expect(account.hasReaderAccess, isTrue);
      expect(account.canStartReaderTrial, isTrue);
      await account.loginPassword('reader@example.com', 'password');
      await account.startReaderTrial();
      expect(trialStarted, isTrue);
      expect(account.hasActiveReaderTrial, isTrue);
    },
  );

  test(
    'legacy free install keeps reading but does not qualify for Premium',
    () async {
      SharedPreferences.setMockInitialValues({
        LegacyReaderAccess.storageKey: true,
      });
      await LegacyReaderAccess.initialize();
      final fixture = _Fixture((request) => _routes(request, access: 'locked'));
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      expect(account.hasReaderAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isFalse);
      expect(account.hasPremiumAccess, isFalse);
      expect(account.hasAdvancedSourceAccess, isFalse);
    },
  );
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

class _Fixture {
  _Fixture(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions request) handler;
  MemberAccountController account({PurchaseStore? store}) {
    final dio = Dio()..httpClientAdapter = _Adapter(handler);
    return MemberAccountController(
      purchaseStore: store,
      api: MemberAccountApiClient(dio: dio, tokenStore: _Tokens()),
    );
  }
}

ResponseBody _routes(RequestOptions request, {required String access}) {
  switch (request.uri.path) {
    case '/api/v1/auth/config':
      return _json({
        'providers': const <String, bool>{},
        'username': {'min_length': 3, 'max_length': 30},
        'password': {'min_length': 12, 'max_length': 128},
      });
    case '/api/v1/membership/config':
      return _json({
        'product': 'premium',
        'features': const <String>[],
        'reader_trial_enabled': true,
        'google_billing_enabled': true,
        'reader_google_product_id': 'origo_x_reader_lifetime',
        'premium_google_product_id': 'origo_x_premium_lifetime',
        'premium_full_google_product_id': 'origo_x_explorer_lifetime',
      });
    case '/api/v1/membership/reader/account-status':
    case '/api/v1/membership/reader/status':
    case '/api/v1/membership/reader/account-trial':
      return _json(_readerResult(request, access));
    case '/api/v1/auth/password/login':
      return _json(_session());
    case '/api/v1/membership':
      return _json({
        'user_id': _userId,
        'premium': false,
        'features': const <String, bool>{},
        'entitlements': const <Object>[],
      });
    case '/api/v1/membership/referral':
      return _json({
        'invite_code': 'TEST',
        'invite_url': 'https://example.test/invite',
      });
    case '/api/v1/auth/logout':
      return _json(const <String, Object?>{});
    default:
      return _json({'detail': 'not found'}, statusCode: 404);
  }
}

MemberAccountController _accountWithRoutes(
  _Tokens tokens,
  FutureOr<ResponseBody> Function(RequestOptions request) routes,
) {
  final dio = Dio()..httpClientAdapter = _Adapter(routes);
  return MemberAccountController(
    api: MemberAccountApiClient(dio: dio, tokenStore: tokens),
  );
}

Map<String, Object?> _readerResult(
  RequestOptions request,
  String access, {
  bool derivedFromPremium = false,
}) {
  final now = DateTime.now();
  final accountOwned = request.uri.path.contains('account-');
  final key = request.headers['X-Origo-Reader-Key'] as String;
  final trial = access == 'trial';
  final lifetime = access == 'lifetime';
  final expires = trial ? now.add(const Duration(days: 14)) : null;
  return {
    'reader_access': {
      'unlocked': trial || lifetime,
      'trial_active': trial,
      'access': access,
      'channel': accountOwned ? 'account' : 'google_play',
      'trial_started_at': trial ? now.toIso8601String() : null,
      'trial_expires_at': expires?.toIso8601String(),
    },
    'offline_license': {
      'version': accountOwned ? 2 : 1,
      if (accountOwned) 'account_id': _userId,
      if (accountOwned) 'subject_type': 'account',
      if (accountOwned) 'permanent': lifetime,
      if (accountOwned) 'derived_from_premium': derivedFromPremium,
      if (accountOwned) 'upgrade_eligible': lifetime,
      'issued_at': now.toIso8601String(),
      'valid_until': (expires ?? now.add(const Duration(days: 30)))
          .toIso8601String(),
      'reader_unlocked': trial || lifetime,
      'trial_expires_at': expires?.toIso8601String(),
      'installation_key_hash': sha256.convert(utf8.encode(key)).toString(),
      'channel': accountOwned ? 'account' : 'google_play',
      'signature': 'opaque',
    },
  };
}

Map<String, Object?> _session() => {
  'access_token': 'access',
  'refresh_token': 'refresh',
  'access_expires_in': 900,
  'refresh_expires_in': 2592000,
  'user': {
    'id': _userId,
    'email': 'reader@example.com',
    'email_verified': true,
    'username': 'reader',
    'effective_name': 'Reader',
    'auth_methods': const <String>['password'],
    'created_at': '2026-01-01T00:00:00Z',
  },
};

const _userId = '123e4567-e89b-42d3-a456-426614174000';

ResponseBody _json(Map<String, Object?> value, {int statusCode = 200}) =>
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

class _Tokens implements MemberTokenStore {
  _Tokens({this.access, this.refresh});

  String? access;
  String? refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<bool> readMfaPending() async => false;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool mfaPending = false,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }
}

class _TestStore implements PurchaseStore {
  PurchaseParam? lastPurchase;
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  Future<void> close() => _stream.close();
  void emit(String product, String id) => _stream.add([
    PurchaseDetails(
      purchaseID: id,
      productID: product,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: id,
        source: 'test',
      ),
      transactionDate: '1',
      status: PurchaseStatus.purchased,
    ),
  ]);
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _stream.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          for (final id in ids)
            ProductDetails(
              id: id,
              title: id,
              description: id,
              price: r'$8.99',
              rawPrice: 8.99,
              currencyCode: 'USD',
            ),
        ],
        notFoundIDs: [],
      );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchase = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
  @override
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  }) async => {};
}
