import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/app_distribution.dart';
import '../core/legacy_reader_access.dart';
import '../reading/reading_account_scope.dart';
import 'account_auth_callback_bridge.dart';
import 'account_api_client.dart';
import '../activities/activity.dart';
import 'account_avatar_cache.dart';
import 'account_models.dart';
import 'account_summary_cache.dart';
import 'account_token_store.dart';
import 'store_purchase_service.dart';
import 'avatar_image_processor.dart';
import 'google_native_sign_in.dart';
import 'membership_cache.dart';
import 'offline_reader_license.dart';

class MemberAccountController extends ChangeNotifier {
  Future<List<AppActivity>> loadActivities() => _api.activities(
    channel: AppDistribution.usesStoreBilling ? 'store' : 'official',
  );

  Uri activityDetailUri(
    AppActivity activity, {
    required String locale,
    bool dark = false,
  }) => activity.detailUri(
    _api.baseUri,
    channel: AppDistribution.usesStoreBilling ? 'store' : 'official',
    locale: locale,
    dark: dark,
  );

  MemberAccountController({
    MemberAccountApiClient? api,
    AccountAvatarCache? avatarCache,
    MemberAccountSummaryCache? summaryCache,
    MemberMembershipCache? membershipCache,
    OfflineReaderLicenseStore? offlineReaderLicenseStore,
    ReaderInstallationCredentialStore? readerCredentialStore,
    ReaderAccessCache? readerAccessCache,
    PendingDeviceAuthorizationStore? pendingAuthorizationStore,
    AccountAuthCallbackBridge? authCallbackBridge,
    GoogleNativeSignInClient? googleNativeSignIn,
    PurchaseStore? purchaseStore,
    ReadingAccountScope? readingScope,
    bool? networkAllowed,
    this.membershipRetryDelay = const Duration(seconds: 30),
    this.accountSyncInterval = const Duration(minutes: 5),
  }) : _api =
           api ??
           MemberAccountApiClient(
             offlineReaderLicenseStore: offlineReaderLicenseStore,
             readerCredentialStore: readerCredentialStore,
           ),
       _networkAllowed = networkAllowed ?? true,
       _readingScope = readingScope ?? ReadingAccountScope.instance,
       _avatarCache = avatarCache ?? AccountAvatarCache.instance,
       _summaryCache = summaryCache ?? const MemberAccountSummaryCache(),
       _membershipCache = membershipCache ?? const MemberMembershipCache(),
       _readerCredentialStore =
           readerCredentialStore ?? const ReaderInstallationCredentialStore(),
       _readerAccessCache = readerAccessCache ?? const ReaderAccessCache(),
       _pendingAuthorizationStore =
           pendingAuthorizationStore ?? SecurePendingDeviceAuthorizationStore(),
       _authCallbackBridge = authCallbackBridge ?? AccountAuthCallbackBridge() {
    _api.setNetworkAllowed(_networkAllowed);
    _googleNativeSignIn =
        googleNativeSignIn ?? GoogleNativeSignInService.instance;
    _apiSessionSubscription = _api.sessionInvalidations.listen((_) {
      if (_disposed) return;
      _authenticationGeneration++;
      _clearAccountReaderState();
      _user = null;
      _pendingSession = null;
      _resetMembershipSync();
      _membership = null;
      _summary = null;
      _referral = null;
      _mfaStatus = null;
      unawaited(_readingScope.setOwner(null));
      unawaited(_clearSummary());
      unawaited(_clearMembershipCache());
      notifyListeners();
    });
    _storePurchase = StorePurchaseService(
      usesAppleBilling: !AppDistribution.usesGoogleBilling,
      store: purchaseStore,
      accountIdProvider: () => _user?.id,
      applicationUserNameProvider: (kind) {
        if (!AppDistribution.usesGoogleBilling) {
          return _user?.id;
        }
        final source = _user?.id;
        return source == null
            ? null
            : sha256.convert(utf8.encode(source)).toString();
      },
      verify: (kind, purchase, accountId) async {
        final verification = purchase.verificationData.serverVerificationData;
        if (kind.domain == StorePurchaseDomain.reader) {
          if (accountId == null || _user?.id != accountId) {
            throw const MemberAccountException('请先登录 Origo 账号');
          }
          final request = ++_accountReaderRequest;
          final result = AppDistribution.usesGoogleBilling
              ? await _api.submitAccountReaderGooglePurchase(
                  verification,
                  restore: purchase.status == PurchaseStatus.restored,
                )
              : await _api.submitAccountReaderApplePurchase(
                  verification,
                  restore: purchase.status == PurchaseStatus.restored,
                );
          if (_user?.id != accountId || request != _accountReaderRequest) {
            throw const MemberAccountException('账号或权益已变化，请重新恢复购买');
          }
          final readerAuthorized = result.testPurchase
              ? _acceptSandboxReaderResult(
                  result,
                  accountId: accountId,
                  kind: kind,
                )
              : await _acceptProductionReaderResult(
                  result,
                  accountRequest: request,
                );
          var legacyPremiumAuthorized = true;
          if (kind == StoreProductKind.legacyBundle) {
            final owner = _user!.id;
            final legacyMembership = AppDistribution.usesGoogleBilling
                ? await _api.submitGooglePurchase(verification)
                : await _api.submitApplePurchase(
                    productId: purchase.productID,
                    verificationData: verification,
                    purchaseId: purchase.purchaseID,
                    transactionDate: purchase.transactionDate,
                  );
            if (_user?.id != owner) {
              throw const MemberAccountException('账号已切换，请重新验证购买');
            }
            _checkMembershipOwner(legacyMembership, owner);
            if (legacyMembership.testPurchase) {
              legacyPremiumAuthorized = _acceptSandboxPremiumResult(
                legacyMembership,
                accountId: owner,
                kind: StoreProductKind.premiumBundle,
              );
            } else {
              _membership = legacyMembership;
              await _persistMembership();
              legacyPremiumAuthorized = legacyMembership.hasActivePremium;
            }
          }
          return StorePurchaseVerification(
            authorized: readerAuthorized && legacyPremiumAuthorized,
            pending: result.purchaseStatus == 'pending',
            revoked: result.purchaseStatus == 'revoked',
            testPurchase: result.testPurchase,
          );
        }
        if (accountId == null || _user?.id != accountId) {
          throw const MemberAccountException('请先登录账号');
        }
        final membership = AppDistribution.usesGoogleBilling
            ? await _api.submitPremiumGooglePurchase(
                verification,
                restore: purchase.status == PurchaseStatus.restored,
              )
            : await _api.submitPremiumApplePurchase(
                verification,
                restore: purchase.status == PurchaseStatus.restored,
              );
        if (_user?.id != accountId) {
          throw const MemberAccountException('账号已切换，请重新验证购买');
        }
        _checkMembershipOwner(membership, accountId);
        if (membership.testPurchase) {
          final authorized = _acceptSandboxPremiumResult(
            membership,
            accountId: accountId,
            kind: kind,
          );
          notifyListeners();
          return StorePurchaseVerification(
            authorized: authorized,
            pending: membership.purchaseStatus == 'pending',
            revoked: membership.purchaseStatus == 'revoked',
            testPurchase: true,
          );
        }
        _resetMembershipSync();
        _membership = membership;
        await _persistMembership();
        _updateSummaryFromAccount();
        unawaited(_persistSummary());
        notifyListeners();
        return StorePurchaseVerification(
          authorized: membership.hasActivePremium,
          pending: membership.purchaseStatus == 'pending',
          revoked: membership.purchaseStatus == 'revoked',
          testPurchase: membership.testPurchase,
        );
      },
    );
    _configureStoreProducts();
    _storePurchase.addListener(_notifyStorePurchase);
  }

  static const appleProductId = 'com.niki.xxread.premium.lifetime.v2';
  static const legacyAppleBundleProductId = 'com.niki.xxread.premium.lifetime';
  static const appleReaderProductId = 'com.niki.xxread.reader.lifetime';
  static const appleReaderTrialProductId = 'com.niki.xxread.reader.trial14d';
  static const googleReaderProductId = 'origo_x_reader_lifetime';
  static const googlePremiumProductId = 'origo_x_premium_lifetime';

  final MemberAccountApiClient _api;
  late final StreamSubscription<void> _apiSessionSubscription;
  final ReadingAccountScope _readingScope;
  MemberAccountApiClient get readingApi => _api;
  final AccountAvatarCache _avatarCache;
  final MemberAccountSummaryCache _summaryCache;
  final MemberMembershipCache _membershipCache;
  final ReaderInstallationCredentialStore _readerCredentialStore;
  final ReaderAccessCache _readerAccessCache;
  ReaderInstallationCredential? _readerCredential;
  ReaderAccessSnapshot? _readerAccess;
  ReaderOfflineAttestation? _readerAttestation;
  ReaderOfflineAttestation? _accountReaderAttestation;
  String? _offlineReaderAccountId;
  int _accountReaderRequest = 0;
  String? _sandboxAccessAccountId;
  StoreTestAccess? _sandboxReaderAccess;
  StoreTestAccess? _sandboxPremiumAccess;
  StoreProductKind? _sandboxPremiumProductKind;
  final PendingDeviceAuthorizationStore _pendingAuthorizationStore;
  final AccountAuthCallbackBridge _authCallbackBridge;
  late final GoogleNativeSignInClient _googleNativeSignIn;
  late final StorePurchaseService _storePurchase;

  final Duration membershipRetryDelay;
  final Duration accountSyncInterval;
  DateTime? _lastAccountSync;
  CachedMemberMembership? _cachedMembership;
  Timer? _membershipRetry;
  bool _membershipSyncFailed = false;
  int _membershipRequest = 0;
  int _referralRequest = 0;
  bool _networkAllowed;
  int _networkGeneration = 0;
  bool _disposed = false;
  void _notifyStorePurchase() {
    if (!_disposed) notifyListeners();
  }

  Future<void>? _synchronizing;
  bool get membershipSyncFailed => _membershipSyncFailed;

  bool get networkAllowed => _networkAllowed;

  void setNetworkAllowed(bool value) {
    if (_disposed || value == _networkAllowed) return;
    _networkAllowed = value;
    _networkGeneration++;
    _api.setNetworkAllowed(value);
    if (value) return;
    _membershipRetry?.cancel();
    _membershipRetry = null;
    _membershipRequest++;
    _referralRequest++;
    _accountReaderRequest++;
    _synchronizing = null;
  }

  bool _isLegalConsentRequired(Object error) =>
      error is MemberAccountException && error.isLegalConsentRequired;

  int _captureNetworkGeneration() {
    final generation = _networkGeneration;
    _requireNetworkAllowed(generation);
    return generation;
  }

  void _requireNetworkAllowed([int? generation]) {
    if (!_networkAllowed ||
        (generation != null && generation != _networkGeneration)) {
      throw const MemberAccountException(
        '请先同意最新协议',
        code: MemberAccountException.legalConsentRequiredCode,
      );
    }
  }

  bool _isRetryableMembershipError(Object error) =>
      error is MemberAccountException &&
      (error.isTransientNetworkFailure ||
          error.statusCode == 429 ||
          (error.statusCode != null && error.statusCode! >= 500));

  void _resetMembershipSync() {
    _lastAccountSync = null;
    _membershipRequest++;
    _membershipRetry?.cancel();
    _membershipSyncFailed = false;
  }

  void _scheduleMembershipRetry(String? accountId) {
    if (_disposed || !_networkAllowed) return;
    _membershipRetry?.cancel();
    _membershipRetry = Timer(membershipRetryDelay, () async {
      if (_disposed || !_networkAllowed || _user?.id != accountId) return;
      if (_loading) {
        _scheduleMembershipRetry(accountId);
        return;
      }
      try {
        await synchronize(force: true);
      } catch (_) {
        // The refresh records failure and schedules another transient retry.
      }
    });
  }

  /// Reconcile the account without opening StoreKit or requiring a page visit.
  /// Callers may share this operation; temporary failures schedule recovery.
  Future<void> synchronize({bool force = false}) {
    if (_disposed || !_networkAllowed) return Future<void>.value();
    final networkGeneration = _captureNetworkGeneration();
    final active = _synchronizing;
    if (active != null) return active;
    final lastSync = _lastAccountSync;
    if (!force &&
        !_membershipSyncFailed &&
        lastSync != null &&
        DateTime.now().difference(lastSync) < accountSyncInterval) {
      return Future<void>.value();
    }
    if (_loading || _storePurchase.busy) {
      _scheduleMembershipRetry(_user?.id);
      return Future<void>.value();
    }
    late final Future<void> operation;
    operation =
        (() async {
          try {
            if (_user == null) {
              await initialize(force: true);
              _requireNetworkAllowed(networkGeneration);
            } else {
              await Future.wait<void>([
                loadMembership(),
                refreshReaderAccess(),
              ]);
              _requireNetworkAllowed(networkGeneration);
              _lastAccountSync = DateTime.now();
            }
          } catch (error) {
            if (_isRetryableMembershipError(error)) {
              _scheduleMembershipRetry(_user?.id);
            }
            // Public explicit actions still throw; background lifecycle sync reports
            // state through this controller and must not become an unhandled error.
          }
        })().whenComplete(() {
          if (identical(_synchronizing, operation)) _synchronizing = null;
        });
    _synchronizing = operation;
    return operation;
  }

  void _checkMembershipOwner(MemberMembership membership, String accountId) {
    if (membership.userId != null && membership.userId != accountId) {
      throw const MemberAccountException('会员权益账号不匹配，请重新登录');
    }
  }

  bool _initialized = false;
  bool _loading = false;
  MemberUser? _user;
  MemberSession? _pendingSession;
  MemberAuthConfig? _authConfig;
  MemberMembershipConfig? _membershipConfig;
  MemberMembership? _membershipValue;
  Timer? _membershipExpiryTimer;
  MemberMembership? get _membership => _membershipValue;
  set _membership(MemberMembership? value) {
    _membershipValue = value;
    _scheduleMembershipExpiry();
  }

  void _scheduleMembershipExpiry() {
    _membershipExpiryTimer?.cancel();
    final value = _membershipValue ?? _cachedMembership?.membership;
    final expirations = <DateTime>[
      ?value?.premiumExpiresAt,
      ?value?.storeTrial?.expiresAt,
      ?_sandboxReaderAccess?.expiresAt,
      ?_sandboxPremiumAccess?.expiresAt,
      ?_readerAccess?.trialExpiresAt,
      ?_accountReaderAttestation?.validUntil,
      ?_accountReaderAttestation?.trialExpiresAt,
      ?_readerAttestation?.validUntil,
      ?_readerAttestation?.trialExpiresAt,
      for (final grant in value?.entitlements ?? <MemberEntitlement>[])
        if (grant.featureKey == 'store_reader' && grant.expiresAt != null)
          grant.expiresAt!,
    ].where((expiry) => expiry.isAfter(DateTime.now())).toList()..sort();
    final expiresAt = expirations.firstOrNull;
    if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
      _membershipExpiryTimer = Timer(expiresAt.difference(DateTime.now()), () {
        if (!_disposed) {
          _scheduleMembershipExpiry();
          notifyListeners();
        }
      });
    }
  }

  MemberAccountSummary? _summary;
  MemberReferral? _referral;
  MemberMfaStatus? _mfaStatus;
  String? _error;
  DeviceAuthorization? _pendingDeviceAuthorization;
  StreamSubscription<Uri>? _authCallbackSubscription;
  Completer<void>? _authCallbackSignal;
  Future<void>? _callbackCompletion;
  Future<DeviceAuthorization>? _deviceAuthorizationBegin;
  Future<bool>? _deviceAuthorizationPoll;
  String? _deviceAuthorizationPollCode;
  Future<void>? _deviceAuthorizationCancellation;
  int _deviceAuthorizationGeneration = 0;
  int _authenticationGeneration = 0;

  bool get initialized => _initialized;
  bool get loading => _loading || _deviceAuthorizationCancellation != null;
  bool get isAuthenticated => _user != null;
  bool get mfaRequired => _pendingSession?.mfaRequired == true;
  MemberUser? get user => _user;
  MemberUser? get pendingUser => _pendingSession?.user;
  MemberAuthConfig? get authConfig => _authConfig;
  MemberAuthProviders get providers {
    final configured = _authConfig?.providers ?? const MemberAuthProviders();
    if (!usesNativeGoogleLogin || configured.google) return configured;
    return MemberAuthProviders(
      google: true,
      github: configured.github,
      apple: configured.apple,
      passkey: configured.passkey,
    );
  }

  bool get usesNativeGoogleLogin =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) &&
      (_authConfig?.googleNative.enabled ?? false);

  /// The app invokes Apple's native credential API only on iOS. Desktop
  /// distributions use the server-backed browser OAuth flow.
  bool get usesNativeAppleSignIn =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  MemberMembershipConfig? get membershipConfig => _membershipConfig;
  MemberMembership? get membership => _membership;

  /// Last known status for UI only. Purchasing and feature gates still use the
  /// authenticated, server-verified membership or a signed offline license.
  MemberMembership? get membershipForDisplay {
    if (_membership != null) return _membership;
    final cached = _cachedMembership;
    final owner = _user?.id ?? _summary?.userId;
    if (mfaRequired || cached == null || owner != cached.userId) return null;
    return cached.membership;
  }

  bool get premiumForDisplay =>
      hasPremiumAccess || membershipForDisplay?.hasActivePremium == true;

  /// Premium access is valid only for the currently authenticated account.
  /// A previously server-verified, account-bound snapshot may be used while a
  /// fresh server reconciliation is in flight; the summary cache alone never
  /// grants access.
  bool get hasPremiumAccess =>
      _user != null &&
      (_membership?.hasActivePremium == true || _hasSandboxPremiumAccess);
  bool get hasActiveStoreTrial => hasActiveReaderTrial;

  bool get hasAdvancedSourceAccess =>
      hasPremiumAccess ||
      (_membership == null &&
          _accountReaderAttestationIsCurrent &&
          _accountReaderAttestation!.readerUnlocked &&
          _accountReaderAttestation!.derivedFromPremium);
  bool get storeBillingReady => AppDistribution.usesGoogleBilling
      ? membershipConfig?.googleBillingEnabled == true
      : !AppDistribution.usesAppleBilling ||
            membershipConfig?.appleBillingEnabled == true;
  bool get hasStoreReaderEntitlement =>
      _user != null && _membership?.hasStoreReaderEntitlement == true;
  bool get _hasPermanentStoreReaderEntitlement =>
      _user != null &&
      (_membership?.entitlements.any(
            (entry) =>
                entry.featureKey == 'store_reader' &&
                entry.status == 'active' &&
                entry.expiresAt == null,
          ) ??
          false);
  bool get hasReaderAccess =>
      !AppDistribution.readerLicenseRequired || _hasLicensedReaderAccess;
  ReaderAccessSnapshot? get readerAccess => _readerAccess;
  bool get hasPermanentReaderAccess =>
      !AppDistribution.isStore ||
      (_membership?.hasActivePremium == true &&
          _membership?.premiumExpiresAt == null) ||
      _hasPermanentStoreReaderEntitlement ||
      _hasSandboxPermanentReaderAccess ||
      (_accountReaderAttestationIsCurrent &&
          _accountReaderAttestation!.readerUnlocked &&
          _accountReaderAttestation!.permanent) ||
      (_readerAttestationIsCurrent &&
          _readerAttestation!.readerUnlocked &&
          _readerAttestation!.trialExpiresAt == null);
  bool get hasActiveReaderTrial =>
      AppDistribution.isStore &&
      (_hasSandboxReaderTrial ||
          (_accountReaderAttestationIsCurrent &&
              _accountReaderAttestation!.trialExpiresAt?.isAfter(
                    DateTime.now(),
                  ) ==
                  true) ||
          (_readerAttestationIsCurrent &&
              _readerAttestation?.trialExpiresAt?.isAfter(DateTime.now()) ==
                  true));
  DateTime? get readerTrialExpiresAt =>
      _accountReaderAttestation?.trialExpiresAt ??
      (_hasSandboxReaderTrial ? _sandboxReaderAccess?.expiresAt : null) ??
      _readerAccess?.trialExpiresAt ??
      _readerAttestation?.trialExpiresAt;
  bool get canStartStoreTrial => canStartReaderTrial;
  bool get canStartReaderTrial =>
      AppDistribution.isStore &&
      AppDistribution.readerLicenseRequired &&
      !_hasLicensedReaderAccess &&
      _readerAccess?.trialStartedAt == null &&
      _readerAccess?.trialExpiresAt == null &&
      membershipConfig?.storeTrialEnabled == true &&
      (AppDistribution.usesGoogleBilling
          ? true
          : membershipConfig?.readerAppleTrialProductId?.isNotEmpty == true);

  /// Only paid/granted account rights qualify for the discounted upgrade.
  /// Direct-build free access and old device licenses do not qualify.
  bool get hasAccountReaderUpgradeEligibility =>
      isAuthenticated && _hasReaderUpgradeBase;

  bool get canPurchaseStorePremium =>
      AppDistribution.isStore &&
      isAuthenticated &&
      hasAccountReaderUpgradeEligibility &&
      !hasPremiumAccess;
  MemberAccountSummary? get summary => _summary;
  MemberReferral? get referral => _referral;
  MemberMfaStatus? get mfaStatus => _mfaStatus;
  String? get error => _error;
  StorePurchaseService get storePurchase => _storePurchase;
  ProductDetails? get readerLifetimeProduct =>
      _storePurchase.productFor(StoreProductKind.readerLifetime);
  ProductDetails? get readerTrialProduct =>
      _storePurchase.productFor(StoreProductKind.readerTrial);
  ProductDetails? get premiumLifetimeProduct =>
      _storePurchase.productFor(StoreProductKind.premiumLifetime);
  ProductDetails? get premiumBundleProduct =>
      _storePurchase.productFor(StoreProductKind.premiumBundle);
  StorePurchasePhase get readerPurchasePhase =>
      _storePurchase.phaseFor(StorePurchaseDomain.reader);
  bool get readerPurchaseLoading =>
      _storePurchase.busyFor(StorePurchaseDomain.reader);
  String? get readerPurchaseError =>
      _storePurchase.errorFor(StorePurchaseDomain.reader);
  StorePurchasePhase get premiumPurchasePhase =>
      _storePurchase.phaseFor(StorePurchaseDomain.premium);
  bool get premiumPurchaseLoading =>
      _storePurchase.busyFor(StorePurchaseDomain.premium);
  String? get premiumPurchaseError =>
      _storePurchase.errorFor(StorePurchaseDomain.premium);

  bool get _readerAttestationGrantsAccess {
    final value = _readerAttestation;
    if (value == null || !value.validUntil.isAfter(DateTime.now())) {
      return false;
    }
    return value.readerUnlocked ||
        value.trialExpiresAt?.isAfter(DateTime.now()) == true;
  }

  bool get _accountReaderAttestationIsCurrent {
    final value = _accountReaderAttestation;
    if (value == null || !value.validUntil.isAfter(DateTime.now())) {
      return false;
    }
    final owner = _user?.id ?? _offlineReaderAccountId;
    return owner != null && value.accountId == owner;
  }

  void _clearAccountReaderState() {
    _accountReaderRequest++;
    _accountReaderAttestation = null;
    _offlineReaderAccountId = null;
    _clearSandboxAccess();
    // Legacy anonymous licenses retain their original installation semantics.
    if (_readerAccess?.channel == 'account') _readerAccess = null;
    unawaited(_queueAccountReaderCache(_readerAccessCache.clearAccount));
  }

  Future<void> _accountReaderCacheOperation = Future<void>.value();

  Future<void> _queueAccountReaderCache(Future<void> Function() operation) {
    final next = _accountReaderCacheOperation.then((_) => operation());
    _accountReaderCacheOperation = next.catchError((Object _) {});
    return _accountReaderCacheOperation;
  }

  bool get _readerAttestationIsCurrent =>
      _readerAttestation?.validUntil.isAfter(DateTime.now()) == true;

  bool get _hasLicensedReaderAccess =>
      LegacyReaderAccess.allowed ||
      hasPremiumAccess ||
      hasStoreReaderEntitlement ||
      (_accountReaderAttestationIsCurrent &&
          (_accountReaderAttestation!.readerUnlocked ||
              _accountReaderAttestation!.trialExpiresAt?.isAfter(
                    DateTime.now(),
                  ) ==
                  true)) ||
      _readerAttestationGrantsAccess;

  bool get _sandboxAccessBelongsToCurrentAccount =>
      _user != null && _sandboxAccessAccountId == _user!.id;

  bool get _hasSandboxDirectReaderLifetime =>
      _sandboxAccessBelongsToCurrentAccount &&
      _sandboxReaderAccess?.isReaderLifetime == true;

  bool get _hasSandboxReaderTrial =>
      _sandboxAccessBelongsToCurrentAccount &&
      _sandboxReaderAccess?.isReaderTrial == true;

  bool get _hasSandboxPremiumAccess =>
      _sandboxAccessBelongsToCurrentAccount &&
      _sandboxPremiumAccess?.isPremium == true &&
      (_sandboxPremiumProductKind == StoreProductKind.premiumBundle ||
          (_sandboxPremiumProductKind == StoreProductKind.premiumLifetime &&
              _hasReaderUpgradeBase));

  bool get _hasReaderUpgradeBase =>
      _hasPermanentStoreReaderEntitlement ||
      _hasSandboxDirectReaderLifetime ||
      (_accountReaderAttestationIsCurrent &&
          _accountReaderAttestation!.readerUnlocked &&
          _accountReaderAttestation!.upgradeEligible);

  bool get _hasSandboxBundleReaderAccess =>
      _hasSandboxPremiumAccess &&
      _sandboxPremiumProductKind == StoreProductKind.premiumBundle;

  bool get _hasSandboxPermanentReaderAccess =>
      _hasSandboxDirectReaderLifetime || _hasSandboxBundleReaderAccess;

  void _clearSandboxAccess() {
    _sandboxAccessAccountId = null;
    _sandboxReaderAccess = null;
    _sandboxPremiumAccess = null;
    _sandboxPremiumProductKind = null;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> initialize({bool force = false}) async {
    if (_disposed || !_networkAllowed) return;
    if (_loading) return;
    if (_initialized && !force) return;
    final networkGeneration = _captureNetworkGeneration();
    var consentInterrupted = false;
    try {
      await _run(() async {
        await _restorePendingDeviceAuthorization();
        _requireNetworkAllowed(networkGeneration);
        unawaited(_initializeAuthCallbackBridge());
        _summary = await _summaryCache.load();
        final sessionBinding = await _api.offlineReaderSessionBinding();
        _requireNetworkAllowed(networkGeneration);
        if (sessionBinding == null) {
          await _clearSummary();
          await _clearMembershipCache();
        } else {
          final cached = await _membershipCache.load();
          _requireNetworkAllowed(networkGeneration);
          _cachedMembership =
              cached?.userId == _summary?.userId &&
                  (cached?.membership.userId == null ||
                      cached?.membership.userId == cached?.userId)
              ? cached
              : null;
        }
        if (AppDistribution.isStore) {
          try {
            _readerCredential = await _readerCredentialStore.getOrCreate();
            _requireNetworkAllowed(networkGeneration);
            _accountReaderAttestation = await _readerAccessCache.loadAccount(
              credential: _readerCredential!,
              sessionBinding: sessionBinding,
            );
            _requireNetworkAllowed(networkGeneration);
            _offlineReaderAccountId = _accountReaderAttestation?.accountId;
            _readerAttestation = await _readerAccessCache.load(
              credential: _readerCredential!,
              channel: _readerChannel,
            );
            _requireNetworkAllowed(networkGeneration);
          } catch (error) {
            if (_isLegalConsentRequired(error)) rethrow;
            // A current server status is preferred; a still-valid opaque
            // attestation keeps the reader available during a network outage.
          }
        }
        _scheduleMembershipExpiry();
        _initialized = true;
        notifyListeners();
        MemberAccountException? deferred;
        var accountSynchronized = false;
        Future<void> loadConfigs() async {
          try {
            final configs = await Future.wait<Object?>([
              _api.authConfig(),
              _api.membershipConfig(),
            ]);
            _requireNetworkAllowed(networkGeneration);
            _authConfig = configs[0] as MemberAuthConfig;
            _membershipConfig = configs[1] as MemberMembershipConfig;
            _configureStoreProducts();
            _listenForStoreTransactions();
            notifyListeners();
          } on MemberAccountException catch (error) {
            if (!_isRetryableMembershipError(error)) rethrow;
            deferred ??= error;
          }
        }

        Future<void> restoreAccount() async {
          try {
            final session = await _api.restoreSession();
            _requireNetworkAllowed(networkGeneration);
            _acceptSession(session);
            if (session.mfaRequired) {
              await _clearSummary();
              await _clearMembershipCache();
              accountSynchronized = true;
            } else {
              accountSynchronized = await _loadAccountValues(
                networkGeneration: networkGeneration,
                initializePurchases: false,
              );
              _requireNetworkAllowed(networkGeneration);
              await _persistSummary();
            }
          } on MemberAccountException catch (error) {
            if (error.statusCode == 401) {
              _clearAccountReaderState();
              _user = null;
              _pendingSession = null;
              _resetMembershipSync();
              _membership = null;
              _mfaStatus = null;
              await _clearSummary();
              await _clearMembershipCache();
              // Anonymous store reader rights are independent from login.
              try {
                await refreshReaderAccess();
                accountSynchronized = true;
              } on MemberAccountException catch (readerError) {
                if (readerError.isLegalConsentRequired) rethrow;
                if (_isRetryableMembershipError(readerError)) {
                  _scheduleMembershipRetry(null);
                }
              }
            } else if (_isRetryableMembershipError(error)) {
              deferred ??= error;
            } else {
              rethrow;
            }
          }
        }

        // Account recovery never waits for provider configuration, referral
        // data, or StoreKit product metadata to begin fetching membership.
        await Future.wait<void>([loadConfigs(), restoreAccount()]);
        _requireNetworkAllowed(networkGeneration);
        if (deferred != null) throw deferred!;
        if (accountSynchronized && !_membershipSyncFailed) {
          _lastAccountSync = DateTime.now();
        }
      });
    } catch (error) {
      if (_isLegalConsentRequired(error)) {
        consentInterrupted = true;
        return;
      }
      if (_isRetryableMembershipError(error)) {
        _membershipSyncFailed = true;
        _scheduleMembershipRetry(_user?.id);
      }
      if (error is! MemberAccountException ||
          !_isRetryableMembershipError(error)) {
        _clearAccountReaderState();
        _user = null;
        _pendingSession = null;
        _resetMembershipSync();
        _membership = null;
        _mfaStatus = null;
        await _clearMembershipCache();
      }
      rethrow;
    } finally {
      // The account center must remain usable after a network failure. A
      // spinner-only page with no retry is how users get stuck unable to
      // sign in with or without a proxy.
      if (!consentInterrupted) _initialized = true;
      notifyListeners();
    }
  }

  Future<void> loginPassword(String email, String password) =>
      _authenticate(() => _api.loginPassword(email, password));

  Future<void> loginPasskey() {
    final generation = _beginAuthenticationIntent();
    return _run(() async {
      final begin = await _api.beginPasskeyLogin();
      final options = AuthenticateRequestType.fromJson(
        Map<String, dynamic>.from(begin['public_key'] as Map),
        preferImmediatelyAvailableCredentials: false,
      );
      final credential = await PasskeyAuthenticator().authenticate(options);
      final session = await _api.finishPasskeyLogin(
        challengeId: begin['challenge_id'] as String,
        credential: credential.toJson(),
      );
      _checkAuthenticationGeneration(generation);
      _acceptAuthenticatedSession(session);
      await _loadAccountValues();
      await _persistSummary();
    });
  }

  Future<void> loginWithApple() => _authenticate(() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw const MemberAccountException('Apple 未返回身份令牌');
    }
    final authorizationCode = credential.authorizationCode;
    if (authorizationCode.isEmpty) {
      throw const MemberAccountException('Apple 未返回授权码，请重新使用 Apple 登录');
    }
    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ');
    return _api.loginApple(
      identityToken: identityToken,
      authorizationCode: authorizationCode,
      fullName: fullName.isEmpty ? null : fullName,
    );
  });

  /// Returns false only when the user closes Google's native account chooser.
  Future<bool> loginWithGoogleNative() => _runValue(() async {
    final config = _authConfig?.googleNative;
    if (!usesNativeGoogleLogin || config == null) {
      throw const MemberAccountException(
        'Google 原生登录尚未启用',
        code: 'google_native_disabled',
      );
    }
    final generation = _beginAuthenticationIntent();
    final identityToken = await _googleNativeSignIn.authenticate(
      config,
      platform: defaultTargetPlatform,
    );
    if (identityToken == null) return false;
    _checkAuthenticationGeneration(generation);
    final session = await _api.loginGoogle(identityToken);
    _checkAuthenticationGeneration(generation);
    _acceptSession(session);
    if (!session.mfaRequired) {
      await _loadAccountValues();
      await _persistSummary();
    } else {
      await _clearSummary();
      await _clearMembershipCache();
    }
    return true;
  });

  Future<MemberEmailChallenge> requestCode(
    String email,
    MemberEmailCodePurpose purpose,
  ) => _runValue(() => _api.requestCode(email, purpose));

  Future<void> verifyEmailCode({
    required String email,
    required String challengeId,
    required String code,
  }) => _authenticate(
    () => _api.verifyEmailCode(
      email: email,
      challengeId: challengeId,
      code: code,
    ),
  );

  Future<void> bindProviderEmail({
    required String bindingToken,
    required String email,
    required String challengeId,
    required String code,
  }) => _authenticate(
    () => _api.bindProviderEmail(
      bindingToken: bindingToken,
      email: email,
      challengeId: challengeId,
      code: code,
    ),
  );

  Future<void> registerPassword({
    required String email,
    required String challengeId,
    required String code,
    required String username,
    required String password,
    String? displayName,
  }) => _authenticate(
    () => _api.registerPassword(
      email: email,
      challengeId: challengeId,
      code: code,
      username: username,
      displayName: displayName,
      password: password,
    ),
  );

  Future<void> resetPassword({
    required String email,
    required String challengeId,
    required String code,
    required String password,
  }) => _authenticate(
    () => _api.resetPassword(
      email: email,
      challengeId: challengeId,
      code: code,
      password: password,
    ),
  );

  Future<MemberEmailChangeChallenge> requestEmailChangeCode(String newEmail) =>
      _runValue(() async {
        final owner = _user?.id;
        if (owner == null) throw const MemberAccountException('请先登录 Origo 账号');
        final challenge = await _api.requestEmailChangeCode(newEmail);
        if (_user?.id != owner) {
          throw const MemberAccountException('账号已切换，请重新发起邮箱验证');
        }
        return challenge;
      });

  Future<void> changeEmail({
    required String newEmail,
    required String newChallengeId,
    required String newCode,
    String? currentChallengeId,
    String? currentCode,
    String? currentPassword,
  }) => _run(() async {
    final owner = _user?.id;
    if (owner == null) throw const MemberAccountException('请先登录 Origo 账号');
    final session = await _api.changeEmail(
      newEmail: newEmail,
      currentChallengeId: currentChallengeId,
      currentCode: currentCode,
      currentPassword: currentPassword,
      newChallengeId: newChallengeId,
      newCode: newCode,
    );
    if (_user?.id != owner || session.user.id != owner) {
      throw const MemberAccountException('账号已切换，请重新发起邮箱验证');
    }
    _acceptAuthenticatedSession(session);
    await _persistSummary();
  });

  Future<MemberEmailChallenge> requestPasswordChangeCode() =>
      _runValue(_api.requestPasswordChangeCode);

  Future<void> changePassword({
    required String challengeId,
    required String code,
    required String password,
  }) => _run(() async {
    final session = await _api.changePassword(
      challengeId: challengeId,
      code: code,
      password: password,
    );
    _acceptAuthenticatedSession(session);
    await _persistSummary();
  });

  Future<void> loadMfaStatus() => _run(() async {
    _mfaStatus = await _api.mfaStatus();
  });

  Future<MemberEmailChallenge> requestMfaSetupCode() =>
      _runValue(_api.requestMfaSetupCode);

  Future<MemberMfaSetup> setupMfa({
    required String challengeId,
    required String code,
  }) => _runValue(() => _api.setupMfa(challengeId: challengeId, code: code));

  Future<MemberMfaConfirmation> confirmMfa(String code) async {
    final confirmation = await _runValue(() => _api.confirmMfa(code));
    _mfaStatus = MemberMfaStatus(
      enabled: confirmation.enabled,
      recoveryCodesRemaining: confirmation.recoveryCodes.length,
    );
    notifyListeners();
    return confirmation;
  }

  Future<void> disableMfa(String code) => _run(() async {
    await _api.disableMfa(code);
    _mfaStatus = const MemberMfaStatus(enabled: false);
  });

  Future<void> verifyMfa(String code) => _run(() async {
    final pending = _pendingSession;
    if (pending == null || !pending.mfaRequired) {
      throw const MemberAccountException('没有待验证的双重验证登录');
    }
    final session = await _api.verifyMfa(
      code: code,
      pendingAccessToken: pending.accessToken,
    );
    _acceptAuthenticatedSession(session);
    await _loadAccountValues();
    await _persistSummary();
  });

  Future<DeviceAuthorization> beginExternalLogin(
    MemberExternalAuthMethod method,
  ) async {
    _beginAuthenticationIntent();
    final cancellation = _deviceAuthorizationCancellation;
    if (cancellation != null) await cancellation;
    final generation = ++_deviceAuthorizationGeneration;
    late final Future<DeviceAuthorization> operation;
    operation = _runValue(() async {
      await _initializeAuthCallbackBridge();
      final authorization = await _api.beginExternalLogin(method);
      if (generation != _deviceAuthorizationGeneration) {
        throw const MemberAccountException(
          '授权已取消',
          code: 'authorization_cancelled',
        );
      }
      _pendingDeviceAuthorization = authorization;
      _authCallbackSignal = Completer<void>();
      await _pendingAuthorizationStore.save(
        jsonEncode(_deviceAuthorizationJson(authorization)),
      );
      if (generation != _deviceAuthorizationGeneration) {
        throw const MemberAccountException(
          '授权已取消',
          code: 'authorization_cancelled',
        );
      }
      return authorization;
    });
    _deviceAuthorizationBegin = operation;
    try {
      return await operation;
    } finally {
      if (identical(_deviceAuthorizationBegin, operation)) {
        _deviceAuthorizationBegin = null;
      }
    }
  }

  Future<void> _initializeAuthCallbackBridge() async {
    if (_authCallbackSubscription != null) return;
    try {
      _authCallbackSubscription = _authCallbackBridge.callbacks.listen(
        _handleAuthCallback,
      );
      await _authCallbackBridge.initialize();
    } catch (_) {
      await _authCallbackSubscription?.cancel();
      _authCallbackSubscription = null;
      // Polling remains the compatibility fallback on unsupported hosts.
    }
  }

  DeviceAuthorization? get pendingDeviceAuthorization =>
      _pendingDeviceAuthorization;

  /// Cancels the active device authorization and invalidates every async result
  /// that belongs to it. The returned future completes only after an already
  /// issued begin/poll/callback has stopped and any session it wrote is cleared,
  /// so callers may safely start a different authorization afterward.
  Future<void> cancelPendingDeviceAuthorization() {
    final active = _deviceAuthorizationCancellation;
    if (active != null) return active;
    final begin = _deviceAuthorizationBegin;
    final poll = _deviceAuthorizationPoll;
    final callback = _callbackCompletion;
    final hadActiveAuthorization =
        _pendingDeviceAuthorization != null ||
        begin != null ||
        poll != null ||
        callback != null;
    final generation = ++_deviceAuthorizationGeneration;
    final signal = _authCallbackSignal;
    _pendingDeviceAuthorization = null;
    _authCallbackSignal = null;
    _deviceAuthorizationPoll = null;
    _deviceAuthorizationPollCode = null;
    if (signal != null && !signal.isCompleted) signal.complete();

    late final Future<void> operation;
    operation = (() async {
      await Future.wait<void>([
        if (begin != null) begin.then<void>((_) {}, onError: (_) {}),
        if (poll != null) poll.then<void>((_) {}, onError: (_) {}),
        if (callback != null) callback.then<void>((_) {}, onError: (_) {}),
      ]);
      if (generation != _deviceAuthorizationGeneration) return;
      await _pendingAuthorizationStore.clear();
      if (!hadActiveAuthorization) return;
      await _api.clearLocalSession();
      await _readingScope.setOwner(null);
      _user = null;
      _pendingSession = null;
      _resetMembershipSync();
      _membership = null;
      _summary = null;
      _referral = null;
      _mfaStatus = null;
      _error = null;
      await _clearSummary();
      await _clearMembershipCache();
      if (!_disposed) notifyListeners();
    })();
    _deviceAuthorizationCancellation = operation;
    if (!_disposed) notifyListeners();
    return operation.whenComplete(() {
      if (identical(_deviceAuthorizationCancellation, operation)) {
        _deviceAuthorizationCancellation = null;
        if (!_disposed) notifyListeners();
      }
    });
  }

  Future<void> waitForAuthCallback(Duration timeout) async {
    final signal = _authCallbackSignal ??= Completer<void>();
    try {
      await signal.future.timeout(timeout);
    } on TimeoutException {
      // Normal polling remains the fallback when the browser cannot deep-link.
    }
  }

  Future<bool> pollDeviceAuthorization(
    DeviceAuthorization authorization,
  ) async {
    final activePoll = _deviceAuthorizationPoll;
    if (activePoll != null) {
      if (_deviceAuthorizationPollCode == authorization.deviceCode) {
        return activePoll;
      }
      return _pollDeviceAuthorization(authorization);
    }
    if ((isAuthenticated || mfaRequired) &&
        _pendingDeviceAuthorization == null) {
      return true;
    }
    final pending = _pendingDeviceAuthorization;
    if (pending == null || pending.deviceCode != authorization.deviceCode) {
      return false;
    }

    final generation = _deviceAuthorizationGeneration;
    final poll = _pollDeviceAuthorizationRecovering(authorization, generation);
    _deviceAuthorizationPoll = poll;
    _deviceAuthorizationPollCode = authorization.deviceCode;
    try {
      return await poll;
    } finally {
      if (identical(_deviceAuthorizationPoll, poll)) {
        _deviceAuthorizationPoll = null;
        _deviceAuthorizationPollCode = null;
      }
    }
  }

  Future<bool> _pollDeviceAuthorizationRecovering(
    DeviceAuthorization authorization,
    int generation,
  ) async {
    try {
      return await _pollDeviceAuthorization(authorization, generation);
    } on MemberAccountException catch (error) {
      // A newer authentication intent rejects the old poll at the API token
      // boundary. Cancellation owns that result, just as it owns a late
      // successful response, so it must not escape into the next login.
      if (_disposed || generation != _deviceAuthorizationGeneration) {
        return false;
      }
      if (error.code != 'network_timeout' &&
          error.code != 'network_unavailable') {
        rethrow;
      }
      clearError();
      return false;
    }
  }

  Future<bool> _pollDeviceAuthorization(
    DeviceAuthorization authorization, [
    int? expectedGeneration,
  ]) async {
    final generation = expectedGeneration ?? _deviceAuthorizationGeneration;
    var completed = false;
    await _run(() async {
      final session = await _api.pollDeviceAuthorization(authorization);
      if (session == null) return;
      if (generation != _deviceAuthorizationGeneration ||
          _pendingDeviceAuthorization?.deviceCode != authorization.deviceCode) {
        return;
      }
      _acceptSession(session);
      if (session.mfaRequired) {
        await _clearSummary();
        await _clearMembershipCache();
      } else {
        await _loadAccountValues();
        await _persistSummary();
      }
      if (generation != _deviceAuthorizationGeneration) return;
      completed = true;
      _pendingDeviceAuthorization = null;
      _authCallbackSignal = null;
      await _pendingAuthorizationStore.clear();
    });
    return completed;
  }

  void _handleAuthCallback(Uri uri) {
    if (uri.path != '/device' || uri.queryParameters['status'] != 'success') {
      return;
    }
    final code = uri.queryParameters['device_code']?.toUpperCase();
    final pending = _pendingDeviceAuthorization;
    if (pending == null || (code != null && code != pending.userCode)) return;
    final signal = _authCallbackSignal ??= Completer<void>();
    if (!signal.isCompleted) signal.complete();
    if (_callbackCompletion != null) return;
    final generation = _deviceAuthorizationGeneration;
    late final Future<void> operation;
    operation = _completePendingAuthorizationFromCallback(generation);
    _callbackCompletion = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_callbackCompletion, operation)) {
          _callbackCompletion = null;
        }
      }),
    );
  }

  Future<void> _completePendingAuthorizationFromCallback(int generation) async {
    try {
      while (_loading && generation == _deviceAuthorizationGeneration) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (generation != _deviceAuthorizationGeneration) return;
      final authorization = _pendingDeviceAuthorization;
      if (authorization == null || isAuthenticated || mfaRequired) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (generation != _deviceAuthorizationGeneration) return;
      await pollDeviceAuthorization(authorization);
    } catch (_) {
      // The account page polling loop remains the final fallback.
    }
  }

  Future<void> _restorePendingDeviceAuthorization() async {
    final generation = _deviceAuthorizationGeneration;
    final payload = await _pendingAuthorizationStore.read();
    if (generation != _deviceAuthorizationGeneration ||
        payload == null ||
        payload.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final authorization = DeviceAuthorization.fromJson(
        MemberExternalAuthMethod.values.byName(decoded['method'] as String),
        decoded,
        baseUri: _api.baseUri,
      );
      if (generation != _deviceAuthorizationGeneration) return;
      _pendingDeviceAuthorization = authorization;
      _authCallbackSignal = Completer<void>();
    } catch (_) {
      if (generation == _deviceAuthorizationGeneration) {
        await _pendingAuthorizationStore.clear();
      }
    }
  }

  Map<String, Object?> _deviceAuthorizationJson(DeviceAuthorization value) => {
    'method': value.method.name,
    'device_code': value.deviceCode,
    'user_code': value.userCode,
    'verification_uri': value.verificationUri.toString(),
    'verification_uri_complete': value.verificationUriComplete?.toString(),
    'expires_in': value.expiresIn,
    'interval': value.interval,
  };

  Future<void> updateProfile({required String username, String? displayName}) =>
      _run(() async {
        _user = await _api.updateProfile(
          username: username,
          displayName: displayName,
        );
        _updateSummaryFromAccount();
        await _persistSummary();
      });

  Future<void> uploadAvatar(AvatarUploadData upload) => _run(() async {
    final previousUrl = _avatarUri(_user?.avatarUrl);
    final updated = await _api.uploadAvatar(upload);
    final updatedUrl = _avatarUri(updated.avatarUrl);
    await _evictAvatar(previousUrl);
    if (updatedUrl != previousUrl) await _evictAvatar(updatedUrl);
    _user = updated;
    _updateSummaryFromAccount();
    await _persistSummary();
  });

  Future<void> deleteAvatar() => _run(() async {
    final previousUrl = _avatarUri(_user?.avatarUrl);
    await _api.deleteAvatar();
    final updated = await _api.currentUser();
    await _evictAvatar(previousUrl);
    final updatedUrl = _avatarUri(updated.avatarUrl);
    if (updatedUrl != previousUrl) await _evictAvatar(updatedUrl);
    _user = updated;
    _updateSummaryFromAccount();
    await _persistSummary();
  });

  Future<void> loadMembership() => _run(() async {
    await _loadMembershipValue();
    await _persistSummary();
  });

  Future<void> purchaseStorePremium() => _purchasePremium(bundle: false);

  Future<void> purchaseStorePremiumBundle() => _purchasePremium(bundle: true);

  Future<void> _purchasePremium({required bool bundle}) async {
    final owner = _user?.id;
    if (owner == null) throw const MemberAccountException('请先登录 Origo 账号');
    await loadMembership();
    if (_user?.id != owner || _membership == null) {
      throw const MemberAccountException('账号已切换，请重新验证会员权益');
    }
    if (hasPremiumAccess || _membership!.purchaseAllowed == false) return;
    await refreshReaderAccess();
    if (_user?.id != owner) throw const MemberAccountException('账号已切换，请重试');
    if (!bundle && !hasAccountReaderUpgradeEligibility) {
      throw const MemberAccountException(
        '探元升级价仅适用于已永久拥有 Origo 开卷的账号；你也可以选择完整探元方案',
      );
    }
    if (bundle && hasAccountReaderUpgradeEligibility) {
      throw const MemberAccountException('你已拥有 Origo 开卷，请选择探元升级方案');
    }
    final config = await _api.membershipConfig();
    if (_user?.id != owner) throw const MemberAccountException('账号已切换，请重试');
    _membershipConfig = config;
    _configureStoreProducts();
    if (!storeBillingReady) {
      throw const MemberAccountException('商店购买暂未开放，请稍后重试');
    }
    await _storePurchase.purchaseKind(
      bundle
          ? StoreProductKind.premiumBundle
          : StoreProductKind.premiumLifetime,
    );
  }

  Future<void> restoreStorePurchases() async {
    // Sandbox rights are intentionally memory-only. After an app restart the
    // explicit restore action must reconstruct Read before choosing the
    // matching Explore full-price or upgrade path.
    await restoreReaderPurchases();
    await _restoreStorePremiumPurchasesOnly();
  }

  Future<void> purchaseReaderLifetime() async {
    if (!AppDistribution.isStore) return;
    final owner = _user?.id;
    if (owner == null) throw const MemberAccountException('请先登录 Origo 账号');
    await refreshReaderAccess();
    if (_user?.id != owner) throw const MemberAccountException('账号已切换，请重试');
    if (hasPermanentReaderAccess) return;
    final config = await _api.membershipConfig();
    if (_user?.id != owner) throw const MemberAccountException('账号已切换，请重试');
    _membershipConfig = config;
    _configureStoreProducts();
    await _storePurchase.purchaseKind(StoreProductKind.readerLifetime);
  }

  Future<void> restoreReaderPurchases() async {
    if (!AppDistribution.isStore) return;
    final owner = _user?.id;
    if (owner == null) throw const MemberAccountException('请先登录 Origo 账号');
    final config = await _api.membershipConfig();
    if (_user?.id != owner) throw const MemberAccountException('账号已切换，请重试');
    _membershipConfig = config;
    _configureStoreProducts();
    await _storePurchase.restoreDomain(StorePurchaseDomain.reader);
  }

  Future<void> restoreStorePremiumPurchases() async {
    await restoreStorePurchases();
  }

  Future<void> _restoreStorePremiumPurchasesOnly() async {
    if (_user == null) throw const MemberAccountException('请先登录账号');
    _configureStoreProducts();
    await _storePurchase.restoreDomain(StorePurchaseDomain.premium);
  }

  Future<void> loadStoreProducts() async {
    if (!AppDistribution.usesStoreBilling) return;
    _membershipConfig = await _api.membershipConfig();
    _configureStoreProducts();
    notifyListeners();
    if (!storeBillingReady) return;
    await _storePurchase.initialize();
  }

  Future<void> initializeStorePurchases() async {
    _configureStoreProducts();
    if (!storeBillingReady) return;
    await _storePurchase.initialize();
  }

  void _listenForStoreTransactions() {
    if (_networkAllowed &&
        AppDistribution.usesStoreBilling &&
        storeBillingReady &&
        _user != null) {
      try {
        _storePurchase.listenForTransactions();
      } catch (_) {
        // Billing availability must not invalidate a recovered account.
        // Explicit purchase and restore actions can retry the store bridge.
      }
    }
  }

  void _configureStoreProducts() {
    _storePurchase.configureProductIds(
      readerLifetime: AppDistribution.usesGoogleBilling
          ? membershipConfig?.readerGoogleProductId ?? googleReaderProductId
          : membershipConfig?.readerAppleProductId ?? appleReaderProductId,
      readerTrial: AppDistribution.usesAppleBilling
          ? membershipConfig?.readerAppleTrialProductId ??
                appleReaderTrialProductId
          : null,
      premiumLifetime: AppDistribution.usesGoogleBilling
          ? membershipConfig?.premiumGoogleProductId ?? googlePremiumProductId
          : membershipConfig?.premiumAppleProductId ?? appleProductId,
      premiumBundle: AppDistribution.usesGoogleBilling
          ? membershipConfig?.premiumFullGoogleProductId
          : membershipConfig?.premiumFullAppleProductId,
      legacyBundle: AppDistribution.usesAppleBilling
          ? membershipConfig?.legacyAppleProductIds.firstOrNull ??
                legacyAppleBundleProductId
          : membershipConfig?.legacyGoogleProductId ?? 'origo_x_lifetime',
    );
  }

  String get _readerChannel =>
      AppDistribution.usesGoogleBilling ? 'google_play' : 'apple';

  Future<void> refreshReaderAccess() async {
    final owner = _user?.id;
    if (owner == null) {
      if (!AppDistribution.isStore) return;
      final result = await _api.readerStatus(_readerChannel);
      if (_user != null) return;
      await _acceptReaderResult(result);
      return;
    }
    final request = ++_accountReaderRequest;
    final result = await _api.accountReaderStatus();
    if (_user?.id != owner || request != _accountReaderRequest) return;
    await _acceptReaderResult(result, accountRequest: request);
  }

  Future<bool> _acceptProductionReaderResult(
    ReaderAccessResult result, {
    required int accountRequest,
  }) async {
    await _acceptReaderResult(result, accountRequest: accountRequest);
    return hasPermanentReaderAccess || hasActiveReaderTrial;
  }

  bool _acceptSandboxReaderResult(
    ReaderAccessResult result, {
    required String accountId,
    required StoreProductKind kind,
  }) {
    if (result.purchaseStatus == 'pending') return false;
    if (_sandboxAccessAccountId != null &&
        _sandboxAccessAccountId != accountId) {
      _clearSandboxAccess();
    }
    _sandboxAccessAccountId = accountId;
    if (result.purchaseStatus == 'revoked') {
      _sandboxReaderAccess = null;
      _scheduleMembershipExpiry();
      notifyListeners();
      return false;
    }
    if (result.purchaseStatus != 'active') return false;
    final grant = result.testAccess;
    final authorized = switch (kind) {
      StoreProductKind.readerLifetime => grant?.isReaderLifetime == true,
      StoreProductKind.readerTrial => grant?.isReaderTrial == true,
      StoreProductKind.legacyBundle =>
        grant?.reader == true && grant?.isActive == true,
      StoreProductKind.premiumLifetime ||
      StoreProductKind.premiumBundle => false,
    };
    _sandboxReaderAccess = authorized ? grant : null;
    _scheduleMembershipExpiry();
    notifyListeners();
    return authorized;
  }

  bool _acceptSandboxPremiumResult(
    MemberMembership membership, {
    required String accountId,
    required StoreProductKind kind,
  }) {
    if (membership.purchaseStatus == 'pending') return false;
    if (_sandboxAccessAccountId != null &&
        _sandboxAccessAccountId != accountId) {
      _clearSandboxAccess();
    }
    _sandboxAccessAccountId = accountId;
    if (membership.purchaseStatus == 'revoked') {
      _sandboxPremiumAccess = null;
      _sandboxPremiumProductKind = null;
      _scheduleMembershipExpiry();
      return false;
    }
    if (membership.purchaseStatus != 'active') return false;
    final grant = membership.testAccess;
    final authorized =
        (kind == StoreProductKind.premiumLifetime ||
            kind == StoreProductKind.premiumBundle) &&
        grant?.isPremium == true;
    _sandboxPremiumAccess = authorized ? grant : null;
    _sandboxPremiumProductKind = authorized ? kind : null;
    _scheduleMembershipExpiry();
    return authorized && _hasSandboxPremiumAccess;
  }

  Future<void> _acceptReaderResult(
    ReaderAccessResult result, {
    int? accountRequest,
  }) async {
    final credential = _readerCredential ??= await _readerCredentialStore
        .getOrCreate();
    final attestation = result.offlineLicense;
    if (attestation.version == 2) {
      final owner = _user?.id;
      final request = accountRequest ?? _accountReaderRequest;
      if (owner == null ||
          attestation.accountId != owner ||
          attestation.subjectType != 'account' ||
          attestation.channel != 'account' ||
          attestation.installationKeyHash != credential.hash) {
        throw const MemberAccountException('购买权益与当前 Origo 账号不匹配');
      }
      final binding = await _api.offlineReaderSessionBinding();
      if (_user?.id != owner || request != _accountReaderRequest) {
        throw const MemberAccountException('账号已切换，请重新验证购买');
      }
      _accountReaderAttestation = attestation;
      _offlineReaderAccountId = owner;
      _readerAccess = result.readerAccess;
      if (binding != null) {
        await _queueAccountReaderCache(() async {
          if (_user?.id != owner || request != _accountReaderRequest) return;
          await _readerAccessCache.saveAccount(
            attestation,
            sessionBinding: binding,
          );
        });
      }
      _scheduleMembershipExpiry();
      notifyListeners();
      return;
    }
    if (attestation.installationKeyHash != credential.hash ||
        attestation.channel != _readerChannel ||
        attestation.version != 1) {
      throw const MemberAccountException('基础版购买凭据与当前安装不匹配');
    }
    // Test transactions carry diagnostic metadata only. The server response
    // and attestation describe Production account rights, never test grants.
    _readerAccess = result.readerAccess;
    _readerAttestation = attestation;
    await _readerAccessCache.save(attestation);
    _scheduleMembershipExpiry();
    notifyListeners();
  }

  Future<void> startReaderTrial() async {
    if (!AppDistribution.isStore) {
      throw const MemberAccountException('试用仅适用于商店版');
    }
    if (_user == null) throw const MemberAccountException('请先登录 Origo 账号');
    if (_hasLicensedReaderAccess) return;
    if (!canStartStoreTrial) {
      throw const MemberAccountException('当前设备无法开始新的应用试用');
    }
    if (AppDistribution.usesAppleBilling) {
      final owner = _user!.id;
      final config = await _api.membershipConfig();
      if (_user?.id != owner) {
        throw const MemberAccountException('账号已切换，请重试');
      }
      _membershipConfig = config;
      _configureStoreProducts();
      await _storePurchase.purchaseKind(StoreProductKind.readerTrial);
      return;
    }
    await _run(() async {
      final owner = _user!.id;
      final request = ++_accountReaderRequest;
      final result = await _api.startAccountReaderTrial(_readerChannel);
      if (_user?.id != owner || request != _accountReaderRequest) {
        throw const MemberAccountException('账号已切换，请重试');
      }
      await _acceptReaderResult(result, accountRequest: request);
    });
  }

  Future<void> loadReferral() => _run(_loadReferralValue);

  Future<void> redeemMembership(String code) => _run(() async {
    final accountId = _user?.id;
    if (accountId == null) {
      throw const MemberAccountException('请先登录 Origo 账号');
    }
    final membership = await _api.redeemMembership(
      code,
      expectedUserId: accountId,
    );
    if (_user?.id != accountId) {
      throw const MemberAccountException('账号已切换，请重新验证会员权益');
    }
    final referralOwner = _user!;
    _checkMembershipOwner(membership, accountId);
    _resetMembershipSync();
    _membership = membership;
    await _persistMembership();
    _updateSummaryFromAccount();
    await _persistSummary();
    unawaited(_refreshReferralAfterRedemption(referralOwner));
  });

  Future<void> _refreshReferralAfterRedemption(MemberUser owner) async {
    if (_disposed || !identical(_user, owner)) return;
    final request = ++_referralRequest;
    try {
      final referral = await _api.referral();
      if (_disposed ||
          !identical(_user, owner) ||
          request != _referralRequest) {
        return;
      }
      _referral = referral;
      notifyListeners();
    } catch (_) {
      // The code is already consumed and membership accepted. A supplementary
      // referral refresh must not turn a successful redemption into a retry or
      // discard the last verified referral state.
    }
  }

  Future<void> bindReferral(String code) => _run(() async {
    final owner = _user;
    if (owner == null) {
      throw const MemberAccountException('请先登录 Origo 账号');
    }
    final request = ++_referralRequest;
    final referral = await _api.bindReferral(code, expectedUserId: owner.id);
    if (_disposed || !identical(_user, owner) || request != _referralRequest) {
      throw const MemberAccountException('账号已切换，请重试');
    }
    _referral = referral;
  });

  Future<MemberAccountDeletionPreview> accountDeletionPreview() =>
      _runValue(_api.accountDeletionPreview);

  Future<MemberEmailChallenge> requestAccountDeletionCode() =>
      _runValue(_api.requestAccountDeletionCode);

  /// 注销成功后本地状态必须和退出登录一样彻底清空，否则界面仍会显示已删除的账号。
  Future<bool> deleteAccount({
    required String challengeId,
    required String code,
    required String confirmation,
    String? mfaCode,
  }) => _runValue(() async {
    final appleManualRevocationRequired = await _api.deleteAccount(
      challengeId: challengeId,
      code: code,
      confirmation: confirmation,
      mfaCode: mfaCode,
    );
    _clearAccountReaderState();
    await _readingScope.setOwner(null);
    _resetMembershipSync();
    _user = null;
    _pendingSession = null;
    _membership = null;
    _referral = null;
    _mfaStatus = null;
    notifyListeners();
    await _clearSummary();
    await _clearMembershipCache();
    try {
      await _api.clearLocalSession();
    } catch (_) {
      _error = '账号已注销，但本地登录信息清理失败，请重新打开应用后重试';
    }
    return appleManualRevocationRequired;
  });

  Future<void> logout() {
    _beginAuthenticationIntent();
    return _run(() async {
      _clearAccountReaderState();
      _user = null;
      _membership = null;
      notifyListeners();
      await _readingScope.setOwner(null);
      try {
        await _api.logout();
      } finally {
        _user = null;
        _pendingSession = null;
        _resetMembershipSync();
        _membership = null;
        _referral = null;
        _mfaStatus = null;
        notifyListeners();
        await _clearSummary();
        await _clearMembershipCache();
      }
    });
  }

  @override
  void dispose() {
    _membershipExpiryTimer?.cancel();
    unawaited(_apiSessionSubscription.cancel());
    _disposed = true;
    _beginAuthenticationIntent();
    _resetMembershipSync();
    _storePurchase.dispose();
    super.dispose();
  }

  Future<void> _authenticate(Future<MemberSession> Function() action) {
    final generation = _beginAuthenticationIntent();
    return _run(() async {
      final session = await action();
      _checkAuthenticationGeneration(generation);
      _acceptSession(session);
      if (!session.mfaRequired) {
        await _loadAccountValues();
        await _persistSummary();
      } else {
        await _clearSummary();
        await _clearMembershipCache();
      }
    });
  }

  int _beginAuthenticationIntent() {
    _referralRequest++;
    _api.invalidatePendingAuthentication();
    return ++_authenticationGeneration;
  }

  void _checkAuthenticationGeneration(int generation) {
    if (_disposed || generation != _authenticationGeneration) {
      throw const MemberAccountException(
        '登录账号已变化，请重新操作',
        code: 'session_changed',
      );
    }
  }

  void _acceptSession(MemberSession session) {
    if (session.mfaRequired) {
      _clearAccountReaderState();
      _pendingSession = session;
      _user = null;
      _resetMembershipSync();
      _membership = null;
      _summary = null;
      _referral = null;
      _mfaStatus = null;
      notifyListeners();
      return;
    }
    _acceptAuthenticatedSession(session);
  }

  void _acceptAuthenticatedSession(MemberSession session) {
    unawaited(_readingScope.setOwner(session.user.id));
    final accountChanged = _user?.id != session.user.id;
    if (accountChanged) {
      if (_offlineReaderAccountId != session.user.id) {
        _clearAccountReaderState();
      }
      _resetMembershipSync();
      _membership = null;
      if (_summary?.userId != session.user.id) {
        _summary = null;
        _cachedMembership = null;
      }
      _referralRequest++;
      _referral = null;
    }
    _pendingSession = null;
    _user = session.user;
    _listenForStoreTransactions();
    _updateSummaryFromAccount();
    if (accountChanged) notifyListeners();
  }

  void _updateSummaryFromAccount() {
    final user = _user;
    if (user == null) return;
    final cachedPremium = _summary?.userId == user.id
        ? _summary!.premium
        : false;
    _summary = MemberAccountSummary.fromAccount(
      user,
      premium: _membership?.premium ?? cachedPremium,
    );
  }

  Future<void> _persistSummary() async {
    _updateSummaryFromAccount();
    final summary = _summary;
    if (summary == null) return;
    try {
      await _summaryCache.save(summary);
    } catch (_) {
      // The account remains usable if a best-effort UI cache cannot be saved.
    }
  }

  Future<void> _clearSummary() async {
    _summary = null;
    try {
      await _summaryCache.clear();
    } catch (_) {
      // Authentication state is authoritative even if cache cleanup fails.
    }
  }

  Future<void> _persistMembership() async {
    final accountId = _user?.id;
    final membership = _membership;
    if (accountId == null || membership == null) return;
    try {
      await _membershipCache.save(accountId, membership);
    } catch (_) {
      // A verified in-memory membership remains usable if persistence fails.
    }
  }

  Future<void> _clearMembershipCache() async {
    _cachedMembership = null;
    _scheduleMembershipExpiry();
    try {
      await _membershipCache.clear();
    } catch (_) {
      // Cleared authentication state cannot be authorized by a stale cache.
    }
  }

  Uri? _avatarUri(String? value) {
    if (value == null || value.isEmpty) return null;
    return Uri.tryParse(value);
  }

  Future<void> _evictAvatar(Uri? uri) async {
    if (uri == null) return;
    try {
      await _avatarCache.evict(uri);
    } catch (_) {
      // Cache invalidation must not turn a completed account update into an
      // error. A changed URL still causes the avatar widget to reload.
    }
  }

  Future<void> _loadMembershipValue() async {
    final accountId = _user?.id;
    if (accountId == null) return;
    final request = ++_membershipRequest;
    _membershipRetry?.cancel();
    try {
      final membership = await _api.membership();
      if (_disposed ||
          _user?.id != accountId ||
          request != _membershipRequest) {
        return;
      }
      _checkMembershipOwner(membership, accountId);
      _membership = membership;
      _membershipSyncFailed = false;
      await _persistMembership();
    } catch (error) {
      if (_disposed ||
          _user?.id != accountId ||
          request != _membershipRequest) {
        rethrow;
      }
      if (_isLegalConsentRequired(error)) rethrow;
      _membershipSyncFailed = true;
      if (_isRetryableMembershipError(error)) {
        // Keep only this session's server-verified grant; never trust UI cache.
        _scheduleMembershipRetry(accountId);
      } else {
        _membership = null;
        await _clearMembershipCache();
      }
      _updateSummaryFromAccount();
      notifyListeners();
      rethrow;
    }
    _updateSummaryFromAccount();
    notifyListeners();
  }

  Future<void> _loadReferralValue() async {
    final owner = _user;
    if (owner == null) return;
    final request = ++_referralRequest;
    late final MemberReferral referral;
    try {
      // The authenticated profile includes this inviter's locked campaign rules.
      // Public campaign revisions only apply to participants without that lock.
      referral = await _api.referral();
    } catch (error) {
      if (_isLegalConsentRequired(error)) rethrow;
      if (!_disposed &&
          identical(_user, owner) &&
          request == _referralRequest) {
        _referral = null;
      }
      rethrow;
    }
    if (_disposed || !identical(_user, owner) || request != _referralRequest) {
      return;
    }
    _referral = referral;
  }

  Future<bool> _loadAccountValues({
    int? networkGeneration,
    bool initializePurchases = true,
  }) async {
    _requireNetworkAllowed(networkGeneration);
    Future<bool> supplementary(
      Future<void> Function() action, {
      bool retry = false,
    }) async {
      try {
        await action();
      } on MemberAccountException catch (error) {
        if (error.isLegalConsentRequired) rethrow;
        if (retry && _isRetryableMembershipError(error)) {
          _scheduleMembershipRetry(_user?.id);
        }
        // The authenticated session remains usable when supplementary
        // membership, reader, or referral endpoints temporarily fail.
        return false;
      }
      _requireNetworkAllowed(networkGeneration);
      return true;
    }

    final results = await Future.wait<bool>([
      supplementary(_loadMembershipValue),
      supplementary(refreshReaderAccess, retry: true),
      supplementary(_loadReferralValue),
    ]);
    _requireNetworkAllowed(networkGeneration);
    if (initializePurchases && AppDistribution.usesStoreBilling) {
      try {
        await initializeStorePurchases();
      } catch (error) {
        if (_isLegalConsentRequired(error)) rethrow;
        // Explicit account actions may prepare billing independently.
      }
      _requireNetworkAllowed(networkGeneration);
    }
    return results[0] && results[1];
  }

  Future<void> _run(Future<void> Function() action) async {
    final cancellation = _deviceAuthorizationCancellation;
    if (cancellation != null) await cancellation;
    if (_loading) {
      throw const MemberAccountException('账号操作正在进行，请稍候');
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on MemberAccountException catch (error) {
      if (!error.isLegalConsentRequired) _error = error.message;
      rethrow;
    } catch (_) {
      const error = MemberAccountException('账号操作失败，请稍后再试');
      _error = error.message;
      throw error;
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<T> _runValue<T>(Future<T> Function() action) async {
    T? value;
    await _run(() async {
      value = await action();
    });
    return value as T;
  }
}
