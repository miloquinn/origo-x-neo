import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'one listener routes reader and premium products independently',
    () async {
      final store = _FakeStore();
      final verified = <StoreProductKind>[];
      final service = _service(
        store,
        verify: (kind, _, _) async {
          verified.add(kind);
          return const StorePurchaseVerification(authorized: true);
        },
      );
      addTearDown(store.close);
      addTearDown(service.dispose);

      await service.initialize();
      expect(store.hasListener, isTrue);
      expect(
        service.productFor(StoreProductKind.readerLifetime)?.price,
        r'$9.99',
      );
      expect(
        service.productFor(StoreProductKind.premiumLifetime)?.price,
        r'$8.99',
      );

      store.emit(_purchase(_readerId, PurchaseStatus.purchased, 'reader-tx'));
      await pumpEventQueue();
      expect(verified, [StoreProductKind.readerLifetime]);
      expect(
        service.phaseFor(StorePurchaseDomain.reader),
        StorePurchasePhase.purchased,
      );
      expect(
        service.phaseFor(StorePurchaseDomain.premium),
        StorePurchasePhase.idle,
      );

      store.emit(_purchase(_premiumId, PurchaseStatus.purchased, 'premium-tx'));
      await pumpEventQueue();
      expect(verified.last, StoreProductKind.premiumLifetime);
      expect(
        service.phaseFor(StorePurchaseDomain.premium),
        StorePurchasePhase.purchased,
      );
      expect(store.completed, hasLength(2));
    },
  );

  test(
    'reader purchase is anonymous while premium requires an Origo account',
    () async {
      final store = _FakeStore();
      String? accountId;
      final service = _service(
        store,
        accountId: () => accountId,
        applicationUserName: (kind) => kind.domain == StorePurchaseDomain.reader
            ? 'reader-key-hash'
            : accountId,
      );
      addTearDown(store.close);
      addTearDown(service.dispose);

      await service.purchaseKind(StoreProductKind.readerLifetime);
      expect(store.lastPurchase?.applicationUserName, 'reader-key-hash');
      await expectLater(
        service.purchaseKind(StoreProductKind.premiumLifetime),
        throwsA(isA<MemberAccountException>()),
      );

      accountId = _accountId;
      await service.purchaseKind(StoreProductKind.premiumLifetime);
      expect(store.lastPurchase?.applicationUserName, _accountId);
    },
  );

  test('account switch prevents Premium transaction completion', () async {
    final store = _FakeStore();
    var accountId = _accountId;
    final verification = Completer<StorePurchaseVerification>();
    final service = _service(
      store,
      accountId: () => accountId,
      verify: (_, _, _) => verification.future,
    );
    addTearDown(store.close);
    addTearDown(service.dispose);

    await service.initialize();
    store.emit(_purchase(_premiumId, PurchaseStatus.purchased, 'premium-tx'));
    await pumpEventQueue();
    accountId = _otherAccountId;
    verification.complete(const StorePurchaseVerification(authorized: true));
    await pumpEventQueue();

    expect(store.completed, isEmpty);
    expect(
      service.phaseFor(StorePurchaseDomain.premium),
      StorePurchasePhase.failed,
    );
    expect(service.errorFor(StorePurchaseDomain.premium), contains('账号已切换'));
  });

  test(
    'pending reader payment never completes or changes premium state',
    () async {
      final store = _FakeStore();
      final service = _service(
        store,
        verify: (_, _, _) async =>
            const StorePurchaseVerification(authorized: false, pending: true),
      );
      addTearDown(store.close);
      addTearDown(service.dispose);

      await service.initialize();
      store.emit(
        _purchase(_readerId, PurchaseStatus.pending, 'pending-reader'),
      );
      await pumpEventQueue();

      expect(
        service.phaseFor(StorePurchaseDomain.reader),
        StorePurchasePhase.pending,
      );
      expect(
        service.phaseFor(StorePurchaseDomain.premium),
        StorePurchasePhase.idle,
      );
      expect(store.completed, isEmpty);
    },
  );

  test(
    'purchased update queues behind pending verification for same transaction',
    () async {
      final store = _FakeStore();
      final pending = Completer<StorePurchaseVerification>();
      var calls = 0;
      final service = _service(
        store,
        usesAppleBilling: false,
        verify: (_, purchase, _) {
          calls++;
          if (purchase.status == PurchaseStatus.pending) return pending.future;
          return Future.value(
            const StorePurchaseVerification(authorized: true),
          );
        },
      );
      addTearDown(store.close);
      addTearDown(service.dispose);
      await service.initialize();
      store.emit(_purchase(_readerId, PurchaseStatus.pending, 'same-tx'));
      await pumpEventQueue();
      store.emit(_purchase(_readerId, PurchaseStatus.purchased, 'same-tx'));
      await pumpEventQueue();
      expect(calls, 1);
      pending.complete(
        const StorePurchaseVerification(authorized: false, pending: true),
      );
      await pumpEventQueue();
      expect(calls, 2);
      expect(
        service.phaseFor(StorePurchaseDomain.reader),
        StorePurchasePhase.purchased,
      );
      expect(store.completed, hasLength(1));
    },
  );

  test('purchase stream error ends the active domain operation', () async {
    final store = _FakeStore();
    final service = _service(store);
    addTearDown(store.close);
    addTearDown(service.dispose);
    await service.purchaseKind(StoreProductKind.readerLifetime);
    store.emitError(StateError('stream failed'));
    await pumpEventQueue();
    expect(
      service.phaseFor(StorePurchaseDomain.reader),
      StorePurchasePhase.failed,
    );
    expect(
      service.errorFor(StorePurchaseDomain.reader),
      contains('stream failed'),
    );
    expect(
      service.phaseFor(StorePurchaseDomain.premium),
      StorePurchasePhase.idle,
    );
  });

  test('Premium restore waits for legacy bundle verification', () async {
    final verification = Completer<StorePurchaseVerification>();
    final store = _FakeStore(
      restoreIds: {'legacy-delayed'},
      onRestore: (store) {
        scheduleMicrotask(
          () => store.emit(
            _purchase(_legacyId, PurchaseStatus.restored, 'legacy-delayed'),
          ),
        );
      },
    );
    final service = _service(
      store,
      legacy: true,
      verify: (_, _, _) => verification.future,
    );
    addTearDown(store.close);
    addTearDown(service.dispose);
    var finished = false;
    final restoring = service
        .restoreDomain(StorePurchaseDomain.premium)
        .then((_) => finished = true);
    await pumpEventQueue();
    expect(finished, isFalse);
    verification.complete(const StorePurchaseVerification(authorized: true));
    await restoring;
    expect(
      service.phaseFor(StorePurchaseDomain.premium),
      StorePurchasePhase.restored,
    );
  });

  test('reader restore verifies only reader inventory', () async {
    final store = _FakeStore(
      onRestore: (value) {
        scheduleMicrotask(() {
          value.emit(
            _purchase(_readerId, PurchaseStatus.restored, 'reader-restore'),
          );
          value.emit(
            _purchase(_premiumId, PurchaseStatus.restored, 'premium-restore'),
          );
        });
      },
      restoreIds: const {'reader-restore', 'premium-restore'},
    );
    final verified = <StoreProductKind>[];
    final service = _service(
      store,
      verify: (kind, _, _) async {
        verified.add(kind);
        if (kind == StoreProductKind.premiumLifetime) {
          throw StateError('premium requires login');
        }
        return const StorePurchaseVerification(authorized: true);
      },
    );
    addTearDown(store.close);
    addTearDown(service.dispose);

    await service.restoreDomain(StorePurchaseDomain.reader);
    expect(verified, contains(StoreProductKind.readerLifetime));
    expect(
      service.phaseFor(StorePurchaseDomain.reader),
      StorePurchasePhase.restored,
    );
    expect(
      service.phaseFor(StorePurchaseDomain.premium),
      StorePurchasePhase.failed,
    );
  });

  test('legacy bundle cannot be newly purchased', () async {
    final store = _FakeStore();
    final service = _service(store, legacy: true);
    addTearDown(store.close);
    addTearDown(service.dispose);
    await expectLater(
      service.purchaseKind(StoreProductKind.legacyBundle),
      throwsA(isA<MemberAccountException>()),
    );
    expect(store.lastPurchase, isNull);
  });

  test(
    'legacy bundle restore is routed to Premium when restoring Premium',
    () async {
      final store = _FakeStore(
        onRestore: (value) => scheduleMicrotask(
          () => value.emit(
            _purchase(_legacyId, PurchaseStatus.restored, 'legacy-restore'),
          ),
        ),
        restoreIds: const {'legacy-restore'},
      );
      String? capturedAccount;
      final service = _service(
        store,
        legacy: true,
        verify: (kind, _, accountId) async {
          expect(kind, StoreProductKind.legacyBundle);
          capturedAccount = accountId;
          return const StorePurchaseVerification(authorized: true);
        },
      );
      addTearDown(store.close);
      addTearDown(service.dispose);

      await service.restoreDomain(StorePurchaseDomain.premium);

      expect(capturedAccount, _accountId);
      expect(
        service.phaseFor(StorePurchaseDomain.premium),
        StorePurchasePhase.restored,
      );
    },
  );
}

const _readerId = 'origo_x_reader_lifetime';
const _premiumId = 'origo_x_premium_lifetime';
const _trialId = 'origo_x_reader_trial14d';
const _legacyId = 'origo_x_lifetime';
const _accountId = '123e4567-e89b-42d3-a456-426614174000';
const _otherAccountId = '123e4567-e89b-42d3-a456-426614174001';

StorePurchaseService _service(
  _FakeStore store, {
  ValueGetter<String?>? accountId,
  StorePurchaseVerifier? verify,
  StoreApplicationUserNameProvider? applicationUserName,
  bool legacy = false,
  bool usesAppleBilling = true,
}) {
  final service = StorePurchaseService(
    store: store,
    accountIdProvider: accountId ?? () => _accountId,
    applicationUserNameProvider: applicationUserName,
    usesAppleBilling: usesAppleBilling,
    verify:
        verify ??
        (_, _, _) async => const StorePurchaseVerification(authorized: true),
    restoreDeliveryTimeout: const Duration(seconds: 1),
  );
  service.configureProductIds(
    readerLifetime: _readerId,
    readerTrial: _trialId,
    premiumLifetime: _premiumId,
    legacyBundle: legacy ? _legacyId : null,
  );
  return service;
}

PurchaseDetails _purchase(String productId, PurchaseStatus status, String id) =>
    _TestPurchase(
      purchaseID: id,
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: 'proof-$id',
        source: 'test',
      ),
      transactionDate: '1',
      status: status,
    );

class _TestPurchase extends PurchaseDetails {
  _TestPurchase({
    super.purchaseID,
    required super.productID,
    required super.verificationData,
    required super.transactionDate,
    required super.status,
  });
  @override
  bool get pendingCompletePurchase => true;
}

class _FakeStore implements PurchaseStore {
  _FakeStore({this.onRestore, this.restoreIds = const <String>{}});
  final void Function(_FakeStore store)? onRestore;
  final Set<String>? restoreIds;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  PurchaseParam? lastPurchase;
  bool get hasListener => _controller.hasListener;

  void emit(PurchaseDetails purchase) => _controller.add([purchase]);
  void emitError(Object error) => _controller.addError(error);
  Future<void> close() => _controller.close();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      for (final id in identifiers)
        ProductDetails(
          id: id,
          title: id,
          description: id,
          price: id == _readerId ? r'$9.99' : r'$8.99',
          rawPrice: id == _readerId ? 9.99 : 8.99,
          currencyCode: 'USD',
          currencySymbol: r'$',
        ),
    ],
    notFoundIDs: const [],
  );
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
    onRestore?.call(this);
    return restoreIds;
  }
}
