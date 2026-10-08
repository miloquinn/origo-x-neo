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

  test(
    'store startup displays cache before auth and config without StoreKit work',
    () async {
      AppDistribution.debugOverride(
        channel: AppDistributionChannel.appleStore,
        readerLicenseRequired: true,
      );
      const summaryCache = MemberAccountSummaryCache();
      const membershipCache = MemberMembershipCache();
      await summaryCache.save(
        const MemberAccountSummary(
          userId: _userId,
          username: 'reader',
          effectiveName: 'Reader',
          premium: true,
        ),
      );
      await membershipCache.save(
        _userId,
        const MemberMembership(
          userId: _userId,
          premium: true,
          features: {},
          entitlements: [],
        ),
      );
      final authGate = Completer<void>();
      final configGate = Completer<void>();
      final localReady = Completer<void>();
      final membershipApplied = Completer<void>();
      var configRequests = 0;
      final store = _TestStore();
      final tokens = _Tokens(access: 'access', refresh: 'refresh');
      final dio = Dio()
        ..httpClientAdapter = _Adapter((request) async {
          if (request.uri.path.endsWith('/config')) {
            configRequests++;
            await configGate.future;
          }
          if (request.uri.path == '/api/v1/auth/me') {
            await authGate.future;
            return _json(_session());
          }
          return _routes(request, access: 'lifetime');
        });
      final account = MemberAccountController(
        api: MemberAccountApiClient(dio: dio, tokenStore: tokens),
        summaryCache: summaryCache,
        membershipCache: membershipCache,
        purchaseStore: store,
      );
      account.addListener(() {
        if (account.initialized && !localReady.isCompleted) {
          localReady.complete();
        }
        if (account.membership != null && !membershipApplied.isCompleted) {
          membershipApplied.complete();
        }
      });
      final initialization = account.initialize();
      addTearDown(() async {
        if (!authGate.isCompleted) authGate.complete();
        if (!configGate.isCompleted) configGate.complete();
        await initialization.catchError((_) {});
        account.dispose();
        await store.close();
      });

      await localReady.future.timeout(const Duration(seconds: 5));
      expect(AppDistribution.usesAppleBilling, isTrue);
      expect(account.loading, isTrue);
      expect(account.isAuthenticated, isFalse);
      expect(account.premiumForDisplay, isTrue);
      expect(account.hasPremiumAccess, isFalse);
      expect(store.isAvailableCalls, 0);
      expect(store.queryProductDetailsCalls, 0);
      expect(store.restoreCalls, 0);

      authGate.complete();
      await membershipApplied.future.timeout(const Duration(seconds: 5));
      expect(configRequests, 2);
      expect(configGate.isCompleted, isFalse);
      expect(account.isAuthenticated, isTrue);
      expect(account.premiumForDisplay, isFalse);
      expect(store.isAvailableCalls, 0);
      expect(store.queryProductDetailsCalls, 0);

      configGate.complete();
      await initialization;
      expect(account.storeBillingReady, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(store.isAvailableCalls, 0);
      expect(store.queryProductDetailsCalls, 0);
      expect(store.restoreCalls, 0);
    },
  );

  test(
    'failed anonymous reader startup stays retryable until passive sync succeeds',
    () async {
      var readerAvailable = false;
      var readerRequests = 0;
      var configRequests = 0;
      final store = _TestStore();
      addTearDown(store.close);
      final dio = Dio()
        ..httpClientAdapter = _Adapter((request) {
          if (request.uri.path.endsWith('/config')) configRequests++;
          if (request.uri.path == '/api/v1/membership/reader/status') {
            readerRequests++;
            if (!readerAvailable) {
              return _json({
                'detail': 'temporarily unavailable',
              }, statusCode: 503);
            }
          }
          return _routes(request, access: 'lifetime');
        });
      final account = MemberAccountController(
        api: MemberAccountApiClient(dio: dio, tokenStore: _Tokens()),
        purchaseStore: store,
        // Keep recovery deterministic: this test exercises a passive lifecycle
        // sync, rather than waiting for the scheduled retry timer.
        membershipRetryDelay: const Duration(hours: 1),
        accountSyncInterval: const Duration(minutes: 5),
      );
      addTearDown(account.dispose);

      await account.initialize();
      expect(account.initialized, isTrue);
      expect(account.isAuthenticated, isFalse);
      expect(configRequests, 2);
      expect(readerRequests, 1);
      expect(account.hasReaderAccess, isFalse);

      readerAvailable = true;
      await account.synchronize();
      expect(readerRequests, 2);
      expect(account.hasReaderAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);

      final requestsAfterSuccess = configRequests;
      await account.synchronize();
      expect(readerRequests, 2);
      expect(configRequests, requestsAfterSuccess);
    },
  );

  for (final lateBranch in ['authentication', 'configuration']) {
    test(
      'store startup listens for unfinished transactions after late $lateBranch',
      () async {
        AppDistribution.debugOverride(
          channel: AppDistributionChannel.appleStore,
          readerLicenseRequired: true,
        );
        final authGate = Completer<void>();
        final configGate = Completer<void>();
        final firstBranchApplied = Completer<void>();
        final store = _TestStore();
        var verifiedPurchases = 0;
        final dio = Dio()
          ..httpClientAdapter = _Adapter((request) async {
            if (request.uri.path.endsWith('/config')) {
              await configGate.future;
            }
            if (request.uri.path == '/api/v1/auth/me') {
              await authGate.future;
              return _json(_session());
            }
            if (request.uri.path ==
                '/api/v1/membership/reader/apple/account-purchase') {
              verifiedPurchases++;
              return _json(_readerResult(request, 'lifetime'));
            }
            return _routes(request, access: 'locked');
          });
        final account = MemberAccountController(
          api: MemberAccountApiClient(
            dio: dio,
            tokenStore: _Tokens(access: 'access', refresh: 'refresh'),
          ),
          purchaseStore: store,
        );
        account.addListener(() {
          final ready = lateBranch == 'authentication'
              ? account.membershipConfig != null
              : account.isAuthenticated;
          if (ready && !firstBranchApplied.isCompleted) {
            firstBranchApplied.complete();
          }
        });
        final initialization = account.initialize();
        addTearDown(() async {
          if (!authGate.isCompleted) authGate.complete();
          if (!configGate.isCompleted) configGate.complete();
          await initialization.catchError((_) {});
          account.dispose();
          await store.close();
        });

        if (lateBranch == 'authentication') {
          configGate.complete();
        } else {
          authGate.complete();
        }
        await firstBranchApplied.future.timeout(const Duration(seconds: 5));
        expect(store.hasListener, isFalse);
        expect(store.purchaseStreamReads, 0);
        expect(store.isAvailableCalls, 0);
        expect(store.queryProductDetailsCalls, 0);
        expect(store.restoreCalls, 0);

        if (lateBranch == 'authentication') {
          authGate.complete();
        } else {
          configGate.complete();
        }
        await initialization;
        expect(account.isAuthenticated, isTrue);
        expect(account.storeBillingReady, isTrue);
        expect(store.hasListener, isTrue);
        expect(store.purchaseStreamReads, 1);
        expect(store.isAvailableCalls, 0);
        expect(store.queryProductDetailsCalls, 0);
        expect(store.restoreCalls, 0);

        store.emit(
          'com.niki.xxread.reader.lifetime',
          'unfinished-before-restart',
          pendingComplete: true,
        );
        await pumpEventQueue(times: 30);
        expect(verifiedPurchases, 1);
        expect(account.hasPermanentReaderAccess, isTrue);
        expect(store.completed.map((p) => p.purchaseID), [
          'unfinished-before-restart',
        ]);
        expect(store.isAvailableCalls, 0);
        expect(store.queryProductDetailsCalls, 0);
        expect(store.restoreCalls, 0);
      },
    );
  }

  test(
    'store stream failure cannot invalidate a restored premium account',
    () async {
      final store = _TestStore(streamUnavailable: true);
      addTearDown(store.close);
      final dio = Dio()
        ..httpClientAdapter = _Adapter((request) {
          if (request.uri.path == '/api/v1/auth/me') {
            return _json(_session());
          }
          if (request.uri.path == '/api/v1/membership') {
            return _json({
              'user_id': _userId,
              'premium': true,
              'features': const <String, bool>{},
              'entitlements': const <Object>[],
            });
          }
          return _routes(request, access: 'locked');
        });
      final account = MemberAccountController(
        api: MemberAccountApiClient(
          dio: dio,
          tokenStore: _Tokens(access: 'access', refresh: 'refresh'),
        ),
        purchaseStore: store,
      );
      addTearDown(account.dispose);

      await account.initialize();

      expect(account.storeBillingReady, isTrue);
      expect(store.purchaseStreamReads, greaterThan(0));
      expect(store.hasListener, isFalse);
      expect(account.initialized, isTrue);
      expect(account.loading, isFalse);
      expect(account.isAuthenticated, isTrue);
      expect(account.user?.id, _userId);
      expect(account.membership?.userId, _userId);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.membershipSyncFailed, isFalse);
      expect(store.isAvailableCalls, 0);
      expect(store.queryProductDetailsCalls, 0);
      expect(store.restoreCalls, 0);
      expect((await const MemberMembershipCache().load())?.userId, _userId);
    },
  );

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

  test(
    'sandbox Read qualifies for upgrade and grants stay independently revocable',
    () async {
      final store = _TestStore();
      addTearDown(store.close);
      var readerRevoked = false;
      var premiumRevoked = false;
      final fixture = _Fixture((request) {
        if (request.uri.path.contains('/reader/google/account-')) {
          return _json({
            ..._readerResult(request, 'locked'),
            'test_purchase': true,
            'purchase_status': readerRevoked ? 'revoked' : 'active',
            'test_access': readerRevoked
                ? null
                : {
                    'kind': 'reader_lifetime',
                    'reader': true,
                    'premium': false,
                    'expires_at': null,
                  },
          });
        }
        if (request.uri.path.contains('/premium/google/')) {
          return _json({
            'user_id': _userId,
            'premium': false,
            'features': <String, bool>{},
            'entitlements': <Object>[],
            'test_purchase': true,
            'purchase_status': premiumRevoked ? 'revoked' : 'active',
            'test_access': premiumRevoked
                ? null
                : {
                    'kind': 'premium_lifetime',
                    'reader': false,
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
      expect(account.hasAccountReaderUpgradeEligibility, isTrue);
      expect(account.readerPurchasePhase, StorePurchasePhase.testVerified);
      expect(account.hasAdvancedSourceAccess, isFalse);
      final readPurchase = store.lastPurchase;
      await account.purchaseReaderLifetime();
      expect(store.lastPurchase, same(readPurchase));
      await account.purchaseStorePremium();
      expect(store.lastPurchase?.productDetails.id, 'origo_x_premium_lifetime');
      store.emit('origo_x_premium_lifetime', 'premium-test');
      await pumpEventQueue(times: 30);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(account.membership?.testPurchase, isFalse);
      expect(account.premiumPurchasePhase, StorePurchasePhase.testVerified);
      readerRevoked = true;
      store.emit('origo_x_reader_lifetime', 'reader-refunded');
      await pumpEventQueue(times: 30);
      expect(account.hasPremiumAccess, isFalse);
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasPermanentReaderAccess, isFalse);
      store.emit('origo_x_premium_lifetime', 'premium-replay-without-read');
      await pumpEventQueue(times: 30);
      expect(account.premiumPurchasePhase, StorePurchasePhase.failed);
      expect(account.hasPremiumAccess, isFalse);
      readerRevoked = false;
      store.emit('origo_x_reader_lifetime', 'reader-restored');
      await pumpEventQueue(times: 30);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);
      premiumRevoked = true;
      store.emit('origo_x_premium_lifetime', 'premium-refunded');
      await pumpEventQueue(times: 30);
      expect(account.hasPremiumAccess, isFalse);
      expect(account.hasPermanentReaderAccess, isTrue);
      readerRevoked = true;
      store.emit('origo_x_reader_lifetime', 'reader-refunded-again');
      await pumpEventQueue(times: 30);
      expect(account.hasPermanentReaderAccess, isFalse);
      expect(account.hasAccountReaderUpgradeEligibility, isFalse);
      await account.logout();
      expect(account.hasPermanentReaderAccess, isFalse);
      expect(account.hasAdvancedSourceAccess, isFalse);
      final restarted = fixture.account();
      addTearDown(restarted.dispose);
      await restarted.initialize();
      expect(restarted.hasPermanentReaderAccess, isFalse);
    },
  );

  test(
    'explicit Explore restore rebuilds sandbox Read before upgrade',
    () async {
      final store = _TestStore(
        restoreProducts: const [
          'origo_x_reader_lifetime',
          'origo_x_premium_lifetime',
        ],
      );
      addTearDown(store.close);
      final fixture = _Fixture((request) {
        if (request.uri.path.contains('/reader/google/account-')) {
          return _json({
            ..._readerResult(request, 'locked'),
            'test_purchase': true,
            'purchase_status': 'active',
            'test_access': const {
              'kind': 'reader_lifetime',
              'reader': true,
              'premium': false,
              'expires_at': null,
            },
          });
        }
        if (request.uri.path.contains('/premium/google/')) {
          return _json({
            'user_id': _userId,
            'premium': false,
            'features': <String, bool>{},
            'entitlements': <Object>[],
            'test_purchase': true,
            'purchase_status': 'active',
            'test_access': const {
              'kind': 'premium_lifetime',
              'reader': false,
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

      await account.restoreStorePremiumPurchases();

      expect(store.restoreCalls, 2);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(account.hasAccountReaderUpgradeEligibility, isTrue);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.readerPurchasePhase, StorePurchasePhase.testVerified);
      expect(account.premiumPurchasePhase, StorePurchasePhase.testVerified);
    },
  );

  test('sandbox grants are cleared when the Origo account changes', () async {
    final store = _TestStore();
    addTearDown(store.close);
    var currentUserId = _userId;
    final fixture = _Fixture((request) {
      if (request.uri.path == '/api/v1/auth/password/login') {
        final email = (request.data as Map)['email'] as String;
        currentUserId = email.startsWith('other') ? _otherUserId : _userId;
        return _json(_session(userId: currentUserId, email: email));
      }
      if (request.uri.path == '/api/v1/membership') {
        return _json({
          'user_id': currentUserId,
          'premium': false,
          'features': const <String, bool>{},
          'entitlements': const <Object>[],
        });
      }
      if (request.uri.path.endsWith('/premium/google/purchase')) {
        return _json({
          'user_id': currentUserId,
          'premium': false,
          'features': <String, bool>{},
          'entitlements': <Object>[],
          'test_purchase': true,
          'purchase_status': 'active',
          'test_access': const {
            'kind': 'premium_lifetime',
            'reader': false,
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
    store.emit('origo_x_explorer_lifetime', 'full-for-first-account');
    await pumpEventQueue(times: 30);
    expect(account.hasPremiumAccess, isTrue);
    expect(account.hasPermanentReaderAccess, isTrue);
    expect(account.membership?.testPurchase, isFalse);

    await account.loginPassword('other@example.com', 'password');

    expect(account.hasPremiumAccess, isFalse);
    expect(account.hasPermanentReaderAccess, isFalse);
    expect(account.hasAdvancedSourceAccess, isFalse);
  });

  test('sandbox grant must match the purchased Read product', () async {
    final store = _TestStore();
    addTearDown(store.close);
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
                .add(const Duration(days: 14))
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
    expect(account.hasReaderAccess, isFalse);
    expect(account.readerPurchasePhase, StorePurchasePhase.failed);
    expect(account.hasActiveReaderTrial, isFalse);
    expect(account.hasPermanentReaderAccess, isFalse);
    expect(account.canPurchaseStorePremium, isFalse);
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
    'reader purchase rejects an account switch while loading store config',
    () => _expectConfigWaitRejectsAccountSwitch(
      (account) => account.purchaseReaderLifetime(),
    ),
  );

  test(
    'Apple reader trial rejects an account switch while loading store config',
    () => _expectConfigWaitRejectsAccountSwitch(
      (account) => account.startReaderTrial(),
      apple: true,
    ),
  );

  test(
    'reader restore rejects an account switch while loading store config',
    () => _expectConfigWaitRejectsAccountSwitch(
      (account) => account.restoreReaderPurchases(),
    ),
  );

  test(
    'email challenge rejects a session invalidation while awaiting response',
    () => _expectEmailActionRejectsSessionInvalidation(change: false),
  );

  test(
    'email change rejects a session invalidation while awaiting response',
    () => _expectEmailActionRejectsSessionInvalidation(change: true),
  );

  test(
    'Apple sandbox full Explore unlocks both products for this session',
    () async {
      await _enableAppleBeta();
      final store = _TestStore();
      addTearDown(store.close);
      var revoked = false;
      final fixture = _Fixture((request) {
        if (request.uri.path.endsWith('/premium/apple/purchase')) {
          return _json({
            'user_id': _userId,
            'premium': false,
            'features': <String, bool>{},
            'entitlements': <Object>[],
            'test_purchase': true,
            'purchase_status': revoked ? 'revoked' : 'active',
            'test_access': revoked
                ? null
                : {
                    'kind': 'premium_lifetime',
                    'reader': false,
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
      expect(AppDistribution.isAppleTestEnvironment, isTrue);
      expect(account.hasReaderAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isFalse);
      await expectLater(
        account.purchaseReaderLifetime(),
        throwsA(isA<MemberAccountException>()),
      );
      await expectLater(
        account.purchaseStorePremiumBundle(),
        throwsA(isA<MemberAccountException>()),
      );
      expect(store.lastPurchase, isNull);
      await account.loginPassword('reader@example.com', 'password');
      expect(account.hasAdvancedSourceAccess, isFalse);
      await account.purchaseStorePremiumBundle();
      expect(
        store.lastPurchase?.productDetails.id,
        'com.niki.xxread.explorer.lifetime',
      );
      store.emit('com.niki.xxread.explorer.lifetime', 'apple-test-explore');
      await pumpEventQueue(times: 30);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.premiumPurchasePhase, StorePurchasePhase.testVerified);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(account.hasAccountReaderUpgradeEligibility, isFalse);
      final fullPurchase = store.lastPurchase;
      await account.purchaseStorePremiumBundle();
      expect(store.lastPurchase, same(fullPurchase));
      revoked = true;
      store.emit(
        'com.niki.xxread.explorer.lifetime',
        'apple-test-explore-revoked',
      );
      await pumpEventQueue(times: 30);
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasPermanentReaderAccess, isFalse);
      revoked = false;
      store.emit(
        'com.niki.xxread.explorer.lifetime',
        'apple-test-explore-restored',
      );
      await pumpEventQueue(times: 30);
      expect(account.hasAdvancedSourceAccess, isTrue);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(account.premiumPurchasePhase, StorePurchasePhase.testVerified);
      await account.logout();
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasReaderAccess, isTrue);
    },
  );

  test(
    'TestFlight retains formal Explore rights independent of sandbox orders',
    () async {
      await _enableAppleBeta();
      final store = _TestStore();
      addTearDown(store.close);
      final fixture = _Fixture((request) {
        if (request.uri.path == '/api/v1/membership' ||
            request.uri.path.endsWith('/premium/apple/purchase')) {
          return _json({
            'user_id': _userId,
            'premium': true, // Existing Production account entitlement.
            'features': <String, bool>{},
            'entitlements': <Object>[],
            if (request.uri.path.endsWith('/purchase')) ...{
              'test_purchase': true,
              'purchase_status': 'active',
              'test_access': {
                'kind': 'premium_lifetime',
                'reader': false,
                'premium': true,
                'expires_at': null,
              },
            },
          });
        }
        return _routes(request, access: 'locked');
      });
      final account = fixture.account(store: store);
      addTearDown(account.dispose);
      await account.initialize();
      expect(account.hasAdvancedSourceAccess, isFalse);
      await account.loginPassword('reader@example.com', 'password');
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isTrue);
      store.emit(
        'com.niki.xxread.explorer.lifetime',
        'test-with-formal-rights',
      );
      await pumpEventQueue(times: 30);
      expect(account.premiumPurchasePhase, StorePurchasePhase.testVerified);
      expect(account.hasPremiumAccess, isTrue);
      expect(account.hasAdvancedSourceAccess, isTrue);
      await account.logout();
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasReaderAccess, isTrue);
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

  test(
    'active Premium notifies listeners when its entitlement expires',
    () async {
      final expiresAt = DateTime.now().add(const Duration(milliseconds: 150));
      final fixture = _Fixture((request) {
        if (request.uri.path == '/api/v1/membership') {
          return _json({
            'user_id': _userId,
            'premium': true,
            'features': const <String, bool>{},
            'entitlements': [
              {
                'feature_key': 'premium',
                'source': 'test',
                'status': 'active',
                'granted_at': DateTime.now().toIso8601String(),
                'expires_at': expiresAt.toIso8601String(),
              },
            ],
          });
        }
        return _routes(request, access: 'locked');
      });
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      await account.loginPassword('reader@example.com', 'password');
      expect(account.hasPremiumAccess, isTrue);

      final expired = Completer<void>();
      account.addListener(() {
        if (!account.hasPremiumAccess && !expired.isCompleted) {
          expired.complete();
        }
      });

      await expectLater(
        expired.future.timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(account.hasPremiumAccess, isFalse);
    },
  );

  test(
    'active reader trial notifies listeners and revokes reading at expiry',
    () async {
      final expiresAt = DateTime.now().add(const Duration(milliseconds: 150));
      final fixture = _Fixture((request) {
        if (request.uri.path.endsWith('/reader/account-status')) {
          return _json(
            _readerResult(request, 'trial', trialExpiresAt: expiresAt),
          );
        }
        return _routes(request, access: 'locked');
      });
      final account = fixture.account();
      addTearDown(account.dispose);
      await account.initialize();
      await account.loginPassword('reader@example.com', 'password');
      expect(account.hasActiveReaderTrial, isTrue);
      expect(account.hasReaderAccess, isTrue);

      final expired = Completer<void>();
      account.addListener(() {
        if (!account.hasReaderAccess && !expired.isCompleted) {
          expired.complete();
        }
      });

      await expectLater(
        expired.future.timeout(const Duration(seconds: 1)),
        completes,
      );
      expect(account.hasActiveReaderTrial, isFalse);
      expect(account.hasReaderAccess, isFalse);
    },
  );

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

  for (final channel in [
    AppDistributionChannel.appleStore,
    AppDistributionChannel.googlePlay,
  ]) {
    test(
      'free $channel reading does not grant ownership or consume trial',
      () async {
        AppDistribution.debugOverride(channel: channel);
        var trialRequests = 0;
        final fixture = _Fixture((request) {
          if (request.uri.path.endsWith('/reader/account-trial')) {
            trialRequests++;
          }
          return _routes(request, access: 'locked');
        });
        final account = fixture.account();
        addTearDown(account.dispose);
        await account.initialize();
        expect(account.isAuthenticated, isFalse);
        expect(account.hasReaderAccess, isTrue);
        expect(account.hasPermanentReaderAccess, isFalse);
        expect(account.hasStoreReaderEntitlement, isFalse);
        expect(account.hasAdvancedSourceAccess, isFalse);
        expect(account.hasAccountReaderUpgradeEligibility, isFalse);
        expect(account.canStartReaderTrial, isFalse);
        await account.loginPassword('reader@example.com', 'password');
        expect(account.hasReaderAccess, isTrue);
        expect(account.hasPermanentReaderAccess, isFalse);
        expect(account.hasAdvancedSourceAccess, isFalse);
        expect(account.hasAccountReaderUpgradeEligibility, isFalse);
        await expectLater(
          account.startReaderTrial(),
          throwsA(isA<MemberAccountException>()),
        );
        expect(trialRequests, 0);
        expect(account.hasActiveReaderTrial, isFalse);
        await account.logout();
        expect(account.hasReaderAccess, isTrue);
        expect(account.hasAdvancedSourceAccess, isFalse);
      },
    );
  }

  test(
    'optional Read purchase grants ownership while free reading survives refund',
    () async {
      AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
      final store = _TestStore();
      addTearDown(store.close);
      var ownsRead = false;
      final fixture = _Fixture((request) {
        if (request.uri.path.endsWith('/reader/google/account-purchase')) {
          ownsRead = true;
          return _json({
            ..._readerResult(request, 'lifetime'),
            'test_purchase': false,
            'purchase_status': 'active',
          });
        }
        return _routes(
          request,
          access: ownsRead && request.uri.path.contains('account-')
              ? 'lifetime'
              : 'locked',
        );
      });
      final account = fixture.account(store: store);
      addTearDown(account.dispose);
      await account.initialize();
      expect(account.hasReaderAccess, isTrue);
      await expectLater(
        account.purchaseReaderLifetime(),
        throwsA(isA<MemberAccountException>()),
      );
      await expectLater(
        account.restoreReaderPurchases(),
        throwsA(isA<MemberAccountException>()),
      );
      expect(store.lastPurchase, isNull);
      expect(store.restoreCalls, 0);
      await account.loginPassword('reader@example.com', 'password');
      await account.purchaseReaderLifetime();
      expect(store.lastPurchase?.productDetails.id, 'origo_x_reader_lifetime');
      expect(account.hasPermanentReaderAccess, isFalse);
      store.emit('origo_x_reader_lifetime', 'optional-read-purchase');
      await pumpEventQueue(times: 30);
      expect(account.hasPermanentReaderAccess, isTrue);
      expect(account.hasAccountReaderUpgradeEligibility, isTrue);
      expect(account.hasAdvancedSourceAccess, isFalse);
      await account.restoreReaderPurchases();
      expect(store.restoreCalls, 1);
      ownsRead = false; // Authoritative account status after a refunded order.
      await account.refreshReaderAccess();
      expect(account.hasPermanentReaderAccess, isFalse);
      expect(account.hasAccountReaderUpgradeEligibility, isFalse);
      expect(account.hasAdvancedSourceAccess, isFalse);
      expect(account.hasReaderAccess, isTrue);
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

Future<void> _expectConfigWaitRejectsAccountSwitch(
  Future<void> Function(MemberAccountController account) action, {
  bool apple = false,
}) async {
  if (apple) {
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.appleStore,
      readerLicenseRequired: true,
    );
  }
  final store = _TestStore();
  final configRequested = Completer<void>();
  final delayedConfig = Completer<ResponseBody>();
  var delayConfig = false;
  var currentUserId = _userId;
  final fixture = _Fixture((request) {
    if (request.uri.path == '/api/v1/auth/password/login') {
      final email = (request.data as Map)['email'] as String;
      currentUserId = email.startsWith('other') ? _otherUserId : _userId;
      return _json(_session(userId: currentUserId, email: email));
    }
    if (request.uri.path == '/api/v1/membership/config' && delayConfig) {
      if (!configRequested.isCompleted) configRequested.complete();
      return delayedConfig.future;
    }
    if (request.uri.path == '/api/v1/membership') {
      return _json({
        'user_id': currentUserId,
        'premium': false,
        'features': const <String, bool>{},
        'entitlements': const <Object>[],
      });
    }
    if (request.uri.path.endsWith('/reader/account-status')) {
      return _json(_readerResult(request, 'locked', accountId: currentUserId));
    }
    return _routes(request, access: 'locked');
  });
  final account = fixture.account(store: store);
  addTearDown(store.close);
  addTearDown(account.dispose);
  await account.initialize();
  await account.loginPassword('reader@example.com', 'password');

  delayConfig = true;
  final operation = action(account);
  await configRequested.future;
  await account.logout();
  await account.loginPassword('other@example.com', 'password');
  delayedConfig.complete(
    _routes(
      RequestOptions(path: '/api/v1/membership/config'),
      access: 'locked',
    ),
  );

  await expectLater(
    operation,
    throwsA(
      isA<MemberAccountException>().having(
        (error) => error.message,
        'message',
        contains('账号已切换'),
      ),
    ),
  );
  expect(store.lastPurchase, isNull);
  expect(store.restoreCalls, 0);
}

Future<void> _expectEmailActionRejectsSessionInvalidation({
  required bool change,
}) async {
  final tokens = _Tokens();
  final requestStarted = Completer<void>();
  final delayedResponse = Completer<ResponseBody>();
  var delayEmailRequest = false;
  final dio = Dio()
    ..httpClientAdapter = _Adapter((request) {
      if (delayEmailRequest &&
          request.uri.path ==
              (change
                  ? '/api/v1/auth/security/email/change'
                  : '/api/v1/auth/security/email/code')) {
        requestStarted.complete();
        return delayedResponse.future;
      }
      if (request.uri.path == '/api/v1/auth/refresh') {
        return _json({'detail': 'session revoked'}, statusCode: 401);
      }
      return _routes(request, access: 'locked');
    });
  final api = MemberAccountApiClient(dio: dio, tokenStore: tokens);
  final store = _TestStore();
  addTearDown(store.close);
  final account = MemberAccountController(api: api, purchaseStore: store);
  addTearDown(account.dispose);
  await account.initialize();
  await account.loginPassword('reader@example.com', 'password');

  delayEmailRequest = true;
  final operation = change
      ? account.changeEmail(
          newEmail: 'new@example.com',
          newChallengeId: 'new-id',
          newCode: '123456',
        )
      : account.requestEmailChangeCode('new@example.com').then<void>((_) {});
  await requestStarted.future;
  await expectLater(
    api.refreshSession(),
    throwsA(isA<MemberAccountException>()),
  );
  await pumpEventQueue();
  expect(account.isAuthenticated, isFalse);
  delayedResponse.complete(
    change
        ? _json(_session(email: 'new@example.com'))
        : _json({
            'current': null,
            'current_code_required': false,
            'new': {'challenge_id': 'new-id', 'expires_in': 600},
            'message': 'sent',
          }),
  );

  await expectLater(
    operation,
    throwsA(
      change
          ? isA<MemberAccountException>().having(
              (error) => error.code,
              'code',
              'session_changed',
            )
          : isA<MemberAccountException>().having(
              (error) => error.message,
              'message',
              contains('账号已切换'),
            ),
    ),
  );
  expect(account.isAuthenticated, isFalse);
}

class _Fixture {
  _Fixture(this.handler);
  final FutureOr<ResponseBody> Function(RequestOptions request) handler;
  MemberAccountController account({PurchaseStore? store}) {
    if (store == null) {
      final testStore = _TestStore();
      addTearDown(testStore.close);
      store = testStore;
    }
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
        'apple_billing_enabled': true,
        'reader_google_product_id': 'origo_x_reader_lifetime',
        'reader_apple_product_id': 'com.niki.xxread.reader.lifetime',
        'reader_apple_trial_product_id': 'com.niki.xxread.reader.trial14d',
        'premium_google_product_id': 'origo_x_premium_lifetime',
        'premium_full_google_product_id': 'origo_x_explorer_lifetime',
        'premium_full_apple_product_id': 'com.niki.xxread.explorer.lifetime',
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
  final store = _TestStore();
  addTearDown(store.close);
  final dio = Dio()..httpClientAdapter = _Adapter(routes);
  return MemberAccountController(
    purchaseStore: store,
    api: MemberAccountApiClient(dio: dio, tokenStore: tokens),
  );
}

Map<String, Object?> _readerResult(
  RequestOptions request,
  String access, {
  bool derivedFromPremium = false,
  String accountId = _userId,
  DateTime? trialExpiresAt,
}) {
  final now = DateTime.now();
  final accountOwned = request.uri.path.contains('account-');
  final key = request.headers['X-Origo-Reader-Key'] as String;
  final trial = access == 'trial';
  final lifetime = access == 'lifetime';
  final expires = trial
      ? trialExpiresAt ?? now.add(const Duration(days: 14))
      : null;
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
      if (accountOwned) 'account_id': accountId,
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

Map<String, Object?> _session({
  String userId = _userId,
  String email = 'reader@example.com',
}) => {
  'access_token': 'access',
  'refresh_token': 'refresh',
  'access_expires_in': 900,
  'refresh_expires_in': 2592000,
  'user': {
    'id': userId,
    'email': email,
    'email_verified': true,
    'username': 'reader',
    'effective_name': 'Reader',
    'auth_methods': const <String>['password'],
    'created_at': '2026-01-01T00:00:00Z',
  },
};

const _userId = '123e4567-e89b-42d3-a456-426614174000';
const _otherUserId = '123e4567-e89b-42d3-a456-426614174001';

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
  _TestStore({
    this.restoreProducts = const <String>[],
    this.streamUnavailable = false,
  });

  final List<String> restoreProducts;
  final bool streamUnavailable;
  PurchaseParam? lastPurchase;
  int restoreCalls = 0;
  int isAvailableCalls = 0;
  int queryProductDetailsCalls = 0;
  int purchaseStreamReads = 0;
  final completed = <PurchaseDetails>[];
  bool get hasListener => _stream.hasListener;
  final _stream = StreamController<List<PurchaseDetails>>.broadcast();
  Future<void> close() => _stream.close();
  void emit(String product, String id, {bool pendingComplete = false}) {
    final purchase = PurchaseDetails(
      purchaseID: id,
      productID: product,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: id,
        source: 'test',
      ),
      transactionDate: '1',
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = pendingComplete;
    _stream.add([purchase]);
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream {
    purchaseStreamReads++;
    if (streamUnavailable)
      throw StateError('Store transaction stream unavailable');
    return _stream.stream;
  }

  @override
  Future<bool> isAvailable() async {
    isAvailableCalls++;
    return true;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queryProductDetailsCalls++;
    return ProductDetailsResponse(
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
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchase = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  }) async {
    restoreCalls++;
    final restored = restoreProducts
        .where((product) => productIds?.contains(product) ?? true)
        .toList();
    for (final product in restored) {
      scheduleMicrotask(
        () => _stream.add([
          PurchaseDetails(
            purchaseID: 'restore-$restoreCalls-$product',
            productID: product,
            verificationData: PurchaseVerificationData(
              localVerificationData: '',
              serverVerificationData: 'restore-$restoreCalls-$product',
              source: 'test',
            ),
            transactionDate: '1',
            status: PurchaseStatus.restored,
          ),
        ]),
      );
    }
    return restored.map((product) => 'restore-$restoreCalls-$product').toSet();
  }
}
