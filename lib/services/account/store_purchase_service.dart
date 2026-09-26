import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'account_api_client.dart';
import 'apple_purchase_support.dart';

abstract interface class PurchaseStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  });
  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseStore implements PurchaseStore {
  const InAppPurchaseStore(this._store, {this.usesAppleBilling = true});
  final InAppPurchase _store;
  final bool usesAppleBilling;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _store.purchaseStream;
  @override
  Future<bool> isAvailable() => _store.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _store.queryProductDetails(identifiers);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _store.buyNonConsumable(purchaseParam: purchaseParam);
  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _store.completePurchase(purchase);
  @override
  Future<Set<String>?> restorePurchases({
    String? applicationUserName,
    Set<String>? productIds,
  }) async {
    if (usesAppleBilling) {
      final ids = await ApplePurchaseSupport().syncPurchases(
        productIds: productIds,
      );
      await _store.restorePurchases(applicationUserName: applicationUserName);
      return ids;
    }
    final inventory = Completer<Set<String>>();
    final listener = purchaseStream.listen((purchases) {
      if (!inventory.isCompleted &&
          (purchases.isEmpty ||
              purchases.every(
                (item) => item.status == PurchaseStatus.restored,
              ))) {
        inventory.complete({for (final item in purchases) ?item.purchaseID});
      }
    });
    try {
      await _store.restorePurchases(applicationUserName: applicationUserName);
      return await inventory.future.timeout(const Duration(seconds: 20));
    } finally {
      await listener.cancel();
    }
  }
}

enum StoreProductKind {
  readerLifetime,
  readerTrial,
  premiumLifetime,
  legacyBundle,
}

enum StorePurchaseDomain { reader, premium }

extension StoreProductKindDomain on StoreProductKind {
  StorePurchaseDomain get domain => switch (this) {
    StoreProductKind.readerLifetime ||
    StoreProductKind.readerTrial ||
    StoreProductKind.legacyBundle => StorePurchaseDomain.reader,
    StoreProductKind.premiumLifetime => StorePurchaseDomain.premium,
  };
}

enum StorePurchasePhase {
  idle,
  loadingProduct,
  purchasing,
  pending,
  verifying,
  restoring,
  purchased,
  restored,
  testVerified,
  revoked,
  nothingToRestore,
  canceled,
  failed,
}

class StorePurchaseVerification {
  const StorePurchaseVerification({
    required this.authorized,
    this.pending = false,
    this.revoked = false,
    this.testPurchase = false,
  });
  final bool authorized;
  final bool pending;
  final bool revoked;
  final bool testPurchase;
}

typedef StorePurchaseVerifier =
    Future<StorePurchaseVerification> Function(
      StoreProductKind kind,
      PurchaseDetails purchase,
      String? capturedAccountId,
    );
typedef StoreApplicationUserNameProvider =
    String? Function(StoreProductKind kind);

/// One listener owns all transactions and routes them by configured SKU.
class StorePurchaseService extends ChangeNotifier {
  StorePurchaseService({
    required this._verify,
    required this.accountIdProvider,
    this.applicationUserNameProvider,
    this.usesAppleBilling = true,
    this._store,
    this.restoreDeliveryTimeout = const Duration(seconds: 20),
  });

  final bool usesAppleBilling;
  final StorePurchaseVerifier _verify;
  final ValueGetter<String?> accountIdProvider;
  final StoreApplicationUserNameProvider? applicationUserNameProvider;
  PurchaseStore? _store;
  @visibleForTesting
  final Duration restoreDeliveryTimeout;
  final Map<StoreProductKind, String> _productIds = {};
  final Map<StoreProductKind, ProductDetails> _products = {};
  final Map<StorePurchaseDomain, StorePurchasePhase> _phases = {
    StorePurchaseDomain.reader: StorePurchasePhase.idle,
    StorePurchaseDomain.premium: StorePurchasePhase.idle,
  };
  final Map<StorePurchaseDomain, String?> _errors = {};
  final Map<String, Future<bool>> _inFlight = {};
  final Map<String, PurchaseStatus> _inFlightStates = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Future<void>? _productLoad;
  _RestoreSession? _restoreSession;
  bool _disposed = false;

  PurchaseStore get _activeStore => _store ??= InAppPurchaseStore(
    InAppPurchase.instance,
    usesAppleBilling: usesAppleBilling,
  );
  StorePurchasePhase phaseFor(StorePurchaseDomain domain) => _phases[domain]!;
  String? errorFor(StorePurchaseDomain domain) => _errors[domain];
  bool busyFor(StorePurchaseDomain domain) => switch (phaseFor(domain)) {
    StorePurchasePhase.loadingProduct ||
    StorePurchasePhase.purchasing ||
    StorePurchasePhase.verifying ||
    StorePurchasePhase.restoring => true,
    _ => false,
  };
  ProductDetails? productFor(StoreProductKind kind) => _products[kind];
  StorePurchasePhase get phase => phaseFor(StorePurchaseDomain.premium);
  String? get error => errorFor(StorePurchaseDomain.premium);
  bool get busy => StorePurchaseDomain.values.any(busyFor);
  bool get loading => busy;
  ProductDetails? get product => productFor(StoreProductKind.premiumLifetime);

  void configureProductIds({
    String? readerLifetime,
    String? readerTrial,
    String? premiumLifetime,
    String? legacyBundle,
  }) {
    final next = <StoreProductKind, String>{
      if (readerLifetime?.isNotEmpty == true)
        StoreProductKind.readerLifetime: readerLifetime!,
      if (readerTrial?.isNotEmpty == true)
        StoreProductKind.readerTrial: readerTrial!,
      if (premiumLifetime?.isNotEmpty == true)
        StoreProductKind.premiumLifetime: premiumLifetime!,
      if (legacyBundle?.isNotEmpty == true)
        StoreProductKind.legacyBundle: legacyBundle!,
    };
    for (final kind in StoreProductKind.values) {
      if (_productIds[kind] != next[kind]) _products.remove(kind);
    }
    _productIds
      ..clear()
      ..addAll(next);
    _notify();
  }

  void configureProducts({required String lifetime, String? trial}) =>
      configureProductIds(premiumLifetime: lifetime, readerTrial: trial);

  void _ensureListening() {
    _subscription ??= _activeStore.purchaseStream.listen(
      _handlePurchases,
      onError: _handleStreamError,
    );
  }

  Future<void> initialize() async {
    _ensureListening();
    final active = _productLoad;
    if (active != null) return active;
    if (_productIds.isEmpty ||
        _productIds.keys.every((kind) => _products.containsKey(kind))) {
      return;
    }
    final load = _loadProducts();
    _productLoad = load;
    try {
      await load;
    } finally {
      if (identical(_productLoad, load)) _productLoad = null;
    }
  }

  Future<void> _loadProducts() async {
    for (final domain in StorePurchaseDomain.values) {
      if (_productIds.keys.any((kind) => kind.domain == domain)) {
        _setPhase(domain, StorePurchasePhase.loadingProduct);
      }
    }
    try {
      if (!await _activeStore.isAvailable().timeout(
        const Duration(seconds: 8),
      )) {
        throw const MemberAccountException('商店内购暂不可用');
      }
      final response = await _activeStore
          .queryProductDetails(_productIds.values.toSet())
          .timeout(const Duration(seconds: 8));
      if (response.error != null) {
        throw MemberAccountException(response.error!.message);
      }
      _products.clear();
      for (final entry in _productIds.entries) {
        for (final product in response.productDetails) {
          if (product.id == entry.value) _products[entry.key] = product;
        }
      }
      for (final domain in StorePurchaseDomain.values) {
        final configured = _productIds.keys.where(
          (kind) => kind.domain == domain,
        );
        if (configured.isEmpty) continue;
        if (configured.every(_products.containsKey)) {
          _setError(domain, null);
          _setPhase(domain, StorePurchasePhase.idle);
        } else {
          _setError(domain, '商店商品尚未配置或不可用');
          _setPhase(domain, StorePurchasePhase.failed);
        }
      }
    } catch (error) {
      for (final domain in StorePurchaseDomain.values) {
        if (_productIds.keys.any((kind) => kind.domain == domain)) {
          _setError(domain, error);
          _setPhase(domain, StorePurchasePhase.failed);
        }
      }
      rethrow;
    }
  }

  Future<void> purchaseKind(StoreProductKind kind) async {
    if (kind == StoreProductKind.legacyBundle) {
      throw const MemberAccountException('历史商品仅支持恢复');
    }
    if (!_productIds.containsKey(kind)) {
      throw const MemberAccountException('商品尚未配置');
    }
    final accountId = kind.domain == StorePurchaseDomain.premium
        ? _requireAccountId()
        : null;
    await initialize();
    if (accountId != null) {
      _ensureSameAccount(accountId);
    }
    final product = _products[kind];
    if (product == null) throw const MemberAccountException('商品信息未加载');
    final domain = kind.domain;
    _setError(domain, null);
    _setPhase(domain, StorePurchasePhase.purchasing);
    try {
      final started = await _activeStore.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: applicationUserNameProvider?.call(kind),
        ),
      );
      if (!started) throw const MemberAccountException('无法启动商店购买');
    } catch (error) {
      if (_isCancellation(error)) {
        _setPhase(domain, StorePurchasePhase.canceled);
        return;
      }
      _setError(domain, error);
      _setPhase(domain, StorePurchasePhase.failed);
      rethrow;
    }
  }

  Future<void> purchase({bool trial = false}) => purchaseKind(
    trial ? StoreProductKind.readerTrial : StoreProductKind.premiumLifetime,
  );

  Future<void> restoreDomain(StorePurchaseDomain domain) async {
    if (_restoreSession != null) {
      throw const MemberAccountException('另一项商店恢复正在进行，请稍候');
    }
    _ensureListening();
    final kinds = _productIds.keys
        .where(
          (kind) =>
              kind.domain == domain || kind == StoreProductKind.legacyBundle,
        )
        .toSet();
    if (kinds.isEmpty) throw const MemberAccountException('商品尚未配置');
    final accountId = domain == StorePurchaseDomain.premium
        ? _requireAccountId()
        : null;
    final session = _RestoreSession(domain: domain, kinds: kinds);
    _restoreSession = session;
    _setError(domain, null);
    _setPhase(domain, StorePurchasePhase.restoring);
    try {
      final expected = await _activeStore.restorePurchases(
        productIds: {
          for (final entry in _productIds.entries)
            if (kinds.contains(entry.key)) entry.value,
        },
        applicationUserName: applicationUserNameProvider?.call(kinds.first),
      );
      await session.wait(expected, restoreDeliveryTimeout);
      if (accountId != null) _ensureSameAccount(accountId);
      if (session.error != null) throw session.error!;
      _setPhase(
        domain,
        session.verified
            ? StorePurchasePhase.restored
            : session.revoked
            ? StorePurchasePhase.revoked
            : session.pending
            ? StorePurchasePhase.pending
            : StorePurchasePhase.nothingToRestore,
      );
    } catch (error) {
      if (_isCancellation(error)) {
        _setPhase(domain, StorePurchasePhase.canceled);
      } else {
        _setError(domain, error);
        _setPhase(domain, StorePurchasePhase.failed);
        rethrow;
      }
    } finally {
      if (identical(_restoreSession, session)) _restoreSession = null;
    }
  }

  Future<void> restore() => restoreDomain(StorePurchaseDomain.premium);

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final kind = _kindForProduct(purchase.productID);
      if (kind == null) continue;
      _restoreSession?.observe(purchase.purchaseID);
      final domain =
          kind == StoreProductKind.legacyBundle &&
              _restoreSession?.domain == StorePurchaseDomain.premium
          ? StorePurchaseDomain.premium
          : kind.domain;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setPhase(domain, StorePurchasePhase.pending);
          if (!usesAppleBilling &&
              purchase.verificationData.serverVerificationData.isNotEmpty) {
            unawaited(_process(kind, purchase, domainOverride: domain));
          }
        case PurchaseStatus.canceled:
          _setError(domain, null);
          _setPhase(domain, StorePurchasePhase.canceled);
        case PurchaseStatus.error:
          _setError(domain, purchase.error?.message ?? '商店购买未完成');
          _setPhase(domain, StorePurchasePhase.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final transaction = _process(kind, purchase, domainOverride: domain);
          _restoreSession?.track(kind, purchase.purchaseID, transaction);
          unawaited(transaction);
      }
    }
  }

  Future<bool> _process(
    StoreProductKind kind,
    PurchaseDetails purchase, {
    StorePurchaseDomain? domainOverride,
  }) {
    final key =
        '${kind.name}:${purchase.purchaseID ?? purchase.transactionDate ?? purchase.verificationData.serverVerificationData}';
    final existing = _inFlight[key];
    if (existing != null) {
      if (_inFlightStates[key] == purchase.status) return existing;
      return existing.then(
        (_) => _process(kind, purchase, domainOverride: domainOverride),
      );
    }
    final domain = domainOverride ?? kind.domain;
    final restoreSession = _restoreSession?.domain == domain
        ? _restoreSession
        : null;
    late final Future<bool> transaction;
    transaction =
        (() async {
          final accountId = domain == StorePurchaseDomain.premium
              ? accountIdProvider()
              : null;
          _setPhase(domain, StorePurchasePhase.verifying);
          try {
            if (domain == StorePurchaseDomain.premium) {
              if (accountId == null) {
                throw const MemberAccountException('请先登录账号');
              }
              _ensureSameAccount(accountId);
            }
            final result = await _verify(kind, purchase, accountId);
            if (accountId != null) _ensureSameAccount(accountId);
            if (result.pending) {
              restoreSession?.pending = true;
              _setPhase(domain, StorePurchasePhase.pending);
              return true;
            }
            if (!result.authorized && !result.revoked && !result.testPurchase) {
              throw const MemberAccountException('商店购买尚未生效，请重试');
            }
            if (purchase.pendingCompletePurchase) {
              await _activeStore.completePurchase(purchase);
            }
            restoreSession
              ?..verified |= result.authorized
              ..revoked |= result.revoked;
            _setError(domain, null);
            _setPhase(
              domain,
              result.revoked
                  ? StorePurchasePhase.revoked
                  : result.testPurchase
                  ? StorePurchasePhase.testVerified
                  : purchase.status == PurchaseStatus.restored
                  ? StorePurchasePhase.restored
                  : StorePurchasePhase.purchased,
            );
            return true;
          } catch (error) {
            restoreSession?.error = error;
            _setError(domain, error);
            _setPhase(domain, StorePurchasePhase.failed);
            return false;
          }
        })().whenComplete(() {
          if (identical(_inFlight[key], transaction)) {
            _inFlight.remove(key);
            _inFlightStates.remove(key);
          }
        });
    _inFlight[key] = transaction;
    _inFlightStates[key] = purchase.status;
    return transaction;
  }

  StoreProductKind? _kindForProduct(String productId) {
    for (final entry in _productIds.entries) {
      if (entry.value == productId) return entry.key;
    }
    return null;
  }

  void _handleStreamError(Object error, StackTrace _) {
    final domain = _restoreSession?.domain;
    if (domain != null) {
      _restoreSession?.error = error;
      _setError(domain, error);
      _setPhase(domain, StorePurchasePhase.failed);
      return;
    }
    for (final target in StorePurchaseDomain.values) {
      if (busyFor(target)) {
        _setError(target, error);
        _setPhase(target, StorePurchasePhase.failed);
      }
    }
  }

  String _requireAccountId() {
    final id = accountIdProvider();
    if (id == null || !_uuidPattern.hasMatch(id)) {
      throw const MemberAccountException('请先登录账号');
    }
    return id;
  }

  void _ensureSameAccount(String expected) {
    if (accountIdProvider() != expected) {
      throw const MemberAccountException('账号已切换，请重新验证购买');
    }
  }

  bool _isCancellation(Object error) =>
      error is PlatformException && error.code == 'purchase_cancelled';
  void _setPhase(StorePurchaseDomain domain, StorePurchasePhase value) {
    if (_disposed || _phases[domain] == value) return;
    _phases[domain] = value;
    notifyListeners();
  }

  void _setError(StorePurchaseDomain domain, Object? error) {
    if (_disposed) return;
    final value = error == null
        ? null
        : error is MemberAccountException
        ? error.message
        : error is PlatformException
        ? (error.message ?? '商店操作暂未完成，请重试')
        : error.toString();
    if (_errors[domain] == value) return;
    _errors[domain] = value;
    notifyListeners();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

class _RestoreSession {
  _RestoreSession({required this.domain, required this.kinds});
  final StorePurchaseDomain domain;
  final Set<StoreProductKind> kinds;
  final Map<String, Future<bool>> _transactions = {};
  final Set<String> _arrivals = {};
  bool verified = false;
  bool revoked = false;
  bool pending = false;
  Object? error;
  void observe(String? id) {
    if (id != null && id.isNotEmpty) _arrivals.add(id);
  }

  void track(StoreProductKind kind, String? id, Future<bool> transaction) {
    if (!kinds.contains(kind)) return;
    _transactions[id ?? '${kind.name}:${_transactions.length}'] = transaction;
  }

  Future<void> wait(Set<String>? expectedIds, Duration timeout) async {
    if (expectedIds != null && expectedIds.isEmpty) return;
    if (expectedIds == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await Future.wait(_transactions.values);
      return;
    }
    final deadline = DateTime.now().add(timeout);
    while (!expectedIds.every(_arrivals.contains)) {
      if (DateTime.now().isAfter(deadline)) {
        throw const MemberAccountException('等待商店恢复记录超时');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await Future.wait(_transactions.values);
  }
}
