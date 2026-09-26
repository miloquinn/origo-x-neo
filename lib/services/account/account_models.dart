enum MemberEmailCodePurpose { login, registration, passwordReset }

extension MemberEmailCodePurposeValue on MemberEmailCodePurpose {
  String get apiValue => switch (this) {
    MemberEmailCodePurpose.login => 'login',
    MemberEmailCodePurpose.registration => 'registration',
    MemberEmailCodePurpose.passwordReset => 'password_reset',
  };
}

enum MemberExternalAuthMethod { google, github, apple, passkey }

extension MemberExternalAuthMethodValue on MemberExternalAuthMethod {
  String get apiValue => name;
}

class MemberUser {
  const MemberUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    required this.username,
    required this.effectiveName,
    required this.authMethods,
    required this.createdAt,
    this.displayName,
    this.avatarUrl,
    this.emailIsRelay = false,
  });

  factory MemberUser.fromJson(Map<String, dynamic> json, {Uri? baseUri}) {
    final rawAvatar = json['avatar_url'] as String?;
    final email = json['email'] as String;
    final username = json['username'] as String?;
    final effectiveName =
        json['effective_name'] as String? ??
        json['display_name'] as String? ??
        username ??
        email.split('@').first;
    return MemberUser(
      id: json['id'] as String,
      email: email,
      emailVerified: json['email_verified'] as bool? ?? true,
      // Email-code login can create an account before a username is chosen.
      // Keep the client model non-null by using the server's display fallback.
      username: username ?? effectiveName,
      displayName: json['display_name'] as String?,
      effectiveName: effectiveName,
      avatarUrl: _absoluteUrl(rawAvatar, baseUri),
      authMethods: List<String>.unmodifiable(
        (json['auth_methods'] as List? ?? const []).whereType<String>(),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      emailIsRelay: json['email_is_relay'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final bool emailVerified;

  /// Apple 隐藏邮箱（@privaterelay.appleid.com）可能收不到验证码邮件。
  final bool emailIsRelay;

  final String username;
  final String? displayName;
  final String effectiveName;
  final String? avatarUrl;
  final List<String> authMethods;
  final DateTime createdAt;
}

class MemberAuthProviders {
  const MemberAuthProviders({
    this.google = false,
    this.github = false,
    this.apple = false,
    this.passkey = false,
  });

  factory MemberAuthProviders.fromJson(Map<String, dynamic> json) =>
      MemberAuthProviders(
        google: json['google'] as bool? ?? false,
        github: json['github'] as bool? ?? false,
        apple: json['apple'] as bool? ?? false,
        passkey: json['passkey'] as bool? ?? false,
      );

  final bool google;
  final bool github;
  final bool apple;
  final bool passkey;

  bool supports(MemberExternalAuthMethod method) => switch (method) {
    MemberExternalAuthMethod.google => google,
    MemberExternalAuthMethod.github => github,
    MemberExternalAuthMethod.apple => apple,
    MemberExternalAuthMethod.passkey => passkey,
  };
}

class MemberAuthConfig {
  const MemberAuthConfig({
    required this.providers,
    required this.usernameMinLength,
    required this.usernameMaxLength,
    required this.passwordMinLength,
    required this.passwordMaxLength,
    this.usernamePattern,
  });

  factory MemberAuthConfig.fromJson(Map<String, dynamic> json) {
    final username = _map(json['username']);
    final password = _map(json['password']);
    return MemberAuthConfig(
      providers: MemberAuthProviders.fromJson(_map(json['providers'])),
      usernamePattern: username['pattern'] as String?,
      usernameMinLength: username['min_length'] as int? ?? 3,
      usernameMaxLength: username['max_length'] as int? ?? 30,
      passwordMinLength: password['min_length'] as int? ?? 12,
      passwordMaxLength: password['max_length'] as int? ?? 128,
    );
  }

  final MemberAuthProviders providers;
  final String? usernamePattern;
  final int usernameMinLength;
  final int usernameMaxLength;
  final int passwordMinLength;
  final int passwordMaxLength;
}

class MemberSession {
  const MemberSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
    required this.user,
    this.mfaRequired = false,
  });

  factory MemberSession.fromJson(Map<String, dynamic> json, {Uri? baseUri}) =>
      MemberSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        accessExpiresIn: json['access_expires_in'] as int,
        refreshExpiresIn: json['refresh_expires_in'] as int,
        user: MemberUser.fromJson(_map(json['user']), baseUri: baseUri),
        mfaRequired: json['mfa_required'] as bool? ?? false,
      );

  final String accessToken;
  final String refreshToken;
  final int accessExpiresIn;
  final int refreshExpiresIn;
  final MemberUser user;
  final bool mfaRequired;
}

class MemberEmailChallenge {
  const MemberEmailChallenge({
    required this.id,
    required this.expiresIn,
    required this.message,
  });

  factory MemberEmailChallenge.fromJson(Map<String, dynamic> json) =>
      MemberEmailChallenge(
        id: json['challenge_id'] as String,
        expiresIn: json['expires_in'] as int,
        message: json['message'] as String? ?? '验证码已发送',
      );

  final String id;
  final int expiresIn;
  final String message;
}

class MemberEmailChangeChallenge {
  const MemberEmailChangeChallenge({
    required this.newChallengeId,
    required this.expiresIn,
    this.currentChallengeId,
    this.currentCodeRequired = true,
  });

  factory MemberEmailChangeChallenge.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    return MemberEmailChangeChallenge(
      currentChallengeId: current == null
          ? null
          : _map(current)['challenge_id'] as String,
      currentCodeRequired: json['current_code_required'] as bool? ?? true,
      newChallengeId: _map(json['new'])['challenge_id'] as String,
      expiresIn: _map(json['new'])['expires_in'] as int,
    );
  }

  /// Apple 隐藏邮箱收不到当前侧验证码，服务端不下发该验证码。
  final String? currentChallengeId;

  final bool currentCodeRequired;
  final String newChallengeId;
  final int expiresIn;
}

class MemberMfaStatus {
  const MemberMfaStatus({
    required this.enabled,
    this.recoveryCodesRemaining = 0,
  });

  factory MemberMfaStatus.fromJson(Map<String, dynamic> json) =>
      MemberMfaStatus(
        enabled: json['enabled'] as bool? ?? false,
        recoveryCodesRemaining: json['recovery_codes_remaining'] as int? ?? 0,
      );

  final bool enabled;
  final int recoveryCodesRemaining;
}

/// 注销前的账号快照：告诉用户这次删除到底会带走什么。
class MemberAccountDeletionPreview {
  const MemberAccountDeletionPreview({
    required this.email,
    required this.createdAt,
    required this.confirmationPhrase,
    required this.deletable,
    required this.premium,
    required this.applePurchase,
    required this.mfaRequired,
    this.username,
    this.blockedReason,
    this.sessions = 0,
    this.passkeys = 0,
    this.oauthIdentities = 0,
    this.invitedMembers = 0,
    this.redemptions = 0,
  });

  factory MemberAccountDeletionPreview.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['counts']);
    return MemberAccountDeletionPreview(
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      confirmationPhrase: json['confirmation_phrase'] as String,
      deletable: json['deletable'] as bool? ?? false,
      premium: json['premium'] as bool? ?? false,
      applePurchase: json['apple_purchase'] as bool? ?? false,
      mfaRequired: json['mfa_required'] as bool? ?? false,
      username: json['username'] as String?,
      blockedReason: json['blocked_reason'] as String?,
      sessions: counts['sessions'] as int? ?? 0,
      passkeys: counts['passkeys'] as int? ?? 0,
      oauthIdentities: counts['oauth_identities'] as int? ?? 0,
      invitedMembers: counts['invited_members'] as int? ?? 0,
      redemptions: counts['redemptions'] as int? ?? 0,
    );
  }

  final String email;
  final DateTime createdAt;
  final String confirmationPhrase;
  final bool deletable;
  final bool premium;
  final bool applePurchase;
  final bool mfaRequired;
  final String? username;
  final String? blockedReason;
  final int sessions;
  final int passkeys;
  final int oauthIdentities;
  final int invitedMembers;
  final int redemptions;
}

class MemberMfaSetup {
  const MemberMfaSetup({required this.secret, required this.otpauthUri});

  factory MemberMfaSetup.fromJson(Map<String, dynamic> json) => MemberMfaSetup(
    secret: json['secret'] as String,
    otpauthUri: Uri.parse(json['otpauth_uri'] as String),
  );

  final String secret;
  final Uri otpauthUri;
}

class MemberMfaConfirmation {
  const MemberMfaConfirmation({
    required this.enabled,
    required this.recoveryCodes,
  });

  factory MemberMfaConfirmation.fromJson(Map<String, dynamic> json) =>
      MemberMfaConfirmation(
        enabled: json['enabled'] as bool? ?? true,
        recoveryCodes: List<String>.unmodifiable(
          (json['recovery_codes'] as List? ?? const []).whereType<String>(),
        ),
      );

  final bool enabled;
  final List<String> recoveryCodes;
}

class DeviceAuthorization {
  const DeviceAuthorization({
    required this.method,
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
    this.verificationUriComplete,
  });

  factory DeviceAuthorization.fromJson(
    MemberExternalAuthMethod method,
    Map<String, dynamic> json, {
    Uri? baseUri,
  }) {
    final verification =
        json['verification_uri'] as String? ??
        json['verification_url'] as String? ??
        json['authorization_url'] as String?;
    if (verification == null) {
      throw const FormatException('Missing device verification URL');
    }
    return DeviceAuthorization(
      method: method,
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String? ?? '',
      verificationUri: Uri.parse(_absoluteUrl(verification, baseUri)!),
      verificationUriComplete: switch (json['verification_uri_complete']
          as String?) {
        final value? => Uri.parse(_absoluteUrl(value, baseUri)!),
        null => null,
      },
      expiresIn: json['expires_in'] as int? ?? 600,
      interval: json['interval'] as int? ?? 5,
    );
  }

  final MemberExternalAuthMethod method;
  final String deviceCode;
  final String userCode;
  final Uri verificationUri;
  final Uri? verificationUriComplete;
  final int expiresIn;
  final int interval;
}

class MemberMembershipConfig {
  const MemberMembershipConfig({
    required this.product,
    required this.features,
    this.purchaseUrl,
    this.appleProductId,
    this.googleProductId,
    this.appleTrialProductId,
    this.storeTrialDays = 14,
    this.storeTrialEnabled = false,
    this.googleBillingEnabled = false,
    this.appleBillingEnabled = false,
    this.readerGoogleProductId,
    this.readerAppleProductId,
    this.readerAppleTrialProductId,
    this.premiumGoogleProductId,
    this.premiumAppleProductId,
    this.legacyGoogleProductId,
    this.legacyAppleProductIds = const [],
  });

  factory MemberMembershipConfig.fromJson(
    Map<String, dynamic> json, {
    Uri? baseUri,
  }) => MemberMembershipConfig(
    product: json['product'] as String,
    purchaseUrl: _absoluteUrl(json['purchase_url'] as String?, baseUri),
    appleProductId: json['apple_product_id'] as String?,
    googleProductId: json['google_product_id'] as String?,
    appleTrialProductId: json['apple_trial_product_id'] as String?,
    storeTrialDays:
        json['reader_trial_days'] as int? ??
        json['store_trial_days'] as int? ??
        14,
    storeTrialEnabled:
        json['reader_trial_enabled'] as bool? ??
        json['store_trial_enabled'] as bool? ??
        false,
    googleBillingEnabled: json['google_billing_enabled'] as bool? ?? false,
    appleBillingEnabled: json['apple_billing_enabled'] as bool? ?? false,
    readerGoogleProductId:
        json['reader_google_product_id'] as String? ??
        json['google_reader_product_id'] as String?,
    readerAppleProductId:
        json['reader_apple_product_id'] as String? ??
        json['apple_reader_product_id'] as String?,
    readerAppleTrialProductId:
        json['reader_apple_trial_product_id'] as String? ??
        json['apple_reader_trial_product_id'] as String? ??
        json['apple_trial_product_id'] as String?,
    premiumGoogleProductId:
        json['premium_google_product_id'] as String? ??
        json['google_product_id'] as String?,
    premiumAppleProductId:
        json['premium_apple_product_id'] as String? ??
        json['apple_product_id'] as String?,
    legacyGoogleProductId: json['legacy_google_product_id'] as String?,
    legacyAppleProductIds: List<String>.unmodifiable(
      (json['legacy_apple_product_ids'] as List? ?? const [])
          .whereType<String>(),
    ),
    features: List<String>.unmodifiable(
      (json['features'] as List? ?? const []).whereType<String>(),
    ),
  );

  final String product;
  final String? purchaseUrl;
  final String? appleProductId;
  final String? googleProductId;
  final String? appleTrialProductId;
  final int storeTrialDays;
  final bool storeTrialEnabled;
  final bool googleBillingEnabled;
  final bool appleBillingEnabled;
  final String? readerGoogleProductId;
  final String? readerAppleProductId;
  final String? readerAppleTrialProductId;
  final String? premiumGoogleProductId;
  final String? premiumAppleProductId;
  final String? legacyGoogleProductId;
  final List<String> legacyAppleProductIds;
  final List<String> features;
}

enum ReaderAccessKind { locked, trial, lifetime }

class ReaderAccessSnapshot {
  const ReaderAccessSnapshot({
    required this.unlocked,
    required this.trialActive,
    required this.access,
    required this.channel,
    this.trialStartedAt,
    this.trialExpiresAt,
  });

  factory ReaderAccessSnapshot.fromJson(Map<String, dynamic> json) =>
      ReaderAccessSnapshot(
        unlocked: json['unlocked'] as bool? ?? false,
        trialActive: json['trial_active'] as bool? ?? false,
        access: switch (json['access']) {
          'trial' => ReaderAccessKind.trial,
          'lifetime' => ReaderAccessKind.lifetime,
          _ => ReaderAccessKind.locked,
        },
        channel: json['channel'] as String?,
        trialStartedAt: _optionalDate(json['trial_started_at']),
        trialExpiresAt: _optionalDate(json['trial_expires_at']),
      );

  final bool unlocked;
  final bool trialActive;
  final ReaderAccessKind access;
  final String? channel;
  final DateTime? trialStartedAt;
  final DateTime? trialExpiresAt;

  bool get hasPermanentAccess =>
      unlocked && access == ReaderAccessKind.lifetime;

  bool isTrialActiveAt(DateTime now) =>
      trialActive &&
      access == ReaderAccessKind.trial &&
      trialExpiresAt?.isAfter(now) == true;
}

class ReaderOfflineAttestation {
  const ReaderOfflineAttestation({
    required this.version,
    required this.issuedAt,
    required this.validUntil,
    required this.readerUnlocked,
    required this.installationKeyHash,
    required this.channel,
    required this.signature,
    this.trialExpiresAt,
  });

  factory ReaderOfflineAttestation.fromJson(Map<String, dynamic> json) =>
      ReaderOfflineAttestation(
        version: json['version'] as int,
        issuedAt: DateTime.parse(json['issued_at'] as String),
        validUntil: DateTime.parse(json['valid_until'] as String),
        readerUnlocked: json['reader_unlocked'] as bool? ?? false,
        trialExpiresAt: _optionalDate(json['trial_expires_at']),
        installationKeyHash: json['installation_key_hash'] as String,
        channel: json['channel'] as String,
        signature: json['signature'] as String,
      );

  final int version;
  final DateTime issuedAt;
  final DateTime validUntil;
  final bool readerUnlocked;
  final DateTime? trialExpiresAt;
  final String installationKeyHash;
  final String channel;
  final String signature;

  Map<String, Object?> toJson() => {
    'version': version,
    'issued_at': issuedAt.toIso8601String(),
    'valid_until': validUntil.toIso8601String(),
    'reader_unlocked': readerUnlocked,
    'trial_expires_at': trialExpiresAt?.toIso8601String(),
    'installation_key_hash': installationKeyHash,
    'channel': channel,
    'signature': signature,
  };
}

/// Ephemeral access returned only after a live sandbox receipt verification.
/// Never serialize this grant into the production entitlement cache.
class StoreTestAccess {
  const StoreTestAccess({
    required this.kind,
    required this.reader,
    required this.premium,
    this.expiresAt,
  });

  factory StoreTestAccess.fromJson(Map<String, dynamic> json) =>
      StoreTestAccess(
        kind: json['kind'] as String? ?? '',
        reader: json['reader'] as bool? ?? false,
        premium: json['premium'] as bool? ?? false,
        expiresAt: _optionalDate(json['expires_at']),
      );

  final String kind;
  final bool reader;
  final bool premium;
  final DateTime? expiresAt;
  bool get isActive => expiresAt == null || expiresAt!.isAfter(DateTime.now());
  bool get isReaderLifetime => reader && isActive && kind == 'reader_lifetime';
  bool get isReaderTrial =>
      reader && kind == 'reader_trial' && expiresAt != null && isActive;
  bool get isPremium => premium && isActive && kind == 'premium_lifetime';
}

class ReaderAccessResult {
  const ReaderAccessResult({
    required this.readerAccess,
    required this.offlineLicense,
    this.applied,
    this.testPurchase = false,
    this.testAccess,
    this.purchaseStatus = 'active',
  });

  factory ReaderAccessResult.fromJson(Map<String, dynamic> json) =>
      ReaderAccessResult(
        readerAccess: ReaderAccessSnapshot.fromJson(
          _map(json['reader_access']),
        ),
        offlineLicense: ReaderOfflineAttestation.fromJson(
          _map(json['offline_license']),
        ),
        applied: json['applied'] as bool?,
        testPurchase: json['test_purchase'] as bool? ?? false,
        testAccess: json['test_access'] is Map
            ? StoreTestAccess.fromJson(_map(json['test_access']))
            : null,
        purchaseStatus: _storePurchaseStatus(json['purchase_status']),
      );

  final ReaderAccessSnapshot readerAccess;
  final ReaderOfflineAttestation offlineLicense;
  final bool? applied;
  final bool testPurchase;
  final StoreTestAccess? testAccess;
  final String purchaseStatus;
}

/// An account-bound store evaluation, separate from purchased Premium.
class MemberStoreTrial {
  const MemberStoreTrial({
    required this.startedAt,
    required this.expiresAt,
    required this.channel,
  });

  factory MemberStoreTrial.fromJson(Map<String, dynamic> json) =>
      MemberStoreTrial(
        startedAt: DateTime.parse(json['started_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        channel: json['channel'] as String,
      );

  final DateTime startedAt;
  final DateTime expiresAt;
  final String channel;

  bool isActiveAt(DateTime now) =>
      {'google_play', 'apple'}.contains(channel) &&
      !startedAt.isAfter(now) &&
      expiresAt.isAfter(startedAt) &&
      expiresAt.isAfter(now);

  Map<String, Object> toJson() => {
    'started_at': startedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'channel': channel,
  };
}

class MemberEntitlement {
  const MemberEntitlement({
    required this.featureKey,
    required this.source,
    required this.status,
    required this.grantedAt,
    this.expiresAt,
  });

  factory MemberEntitlement.fromJson(Map<String, dynamic> json) =>
      MemberEntitlement(
        featureKey: json['feature_key'] as String,
        source: json['source'] as String,
        status: json['status'] as String,
        grantedAt: DateTime.parse(json['granted_at'] as String),
        expiresAt: switch (json['expires_at'] as String?) {
          final value? => DateTime.parse(value),
          null => null,
        },
      );

  final String featureKey;
  final String source;
  final String status;
  final DateTime grantedAt;
  final DateTime? expiresAt;
}

class MemberMembership {
  const MemberMembership({
    required bool premium,
    required this.features,
    required this.entitlements,
    this.redeemed,
    this.testPurchase = false,
    this.testAccess,
    this.purchaseStatus = 'active',
    this.userId,
    this.purchaseAllowed,
    this.storeTrial,
    this.testAccessExpiresAt,
    // Preserve the public premium argument while checking expiry in the getter.
  }) : _premium = premium; // ignore: prefer_initializing_formals

  factory MemberMembership.fromJson(Map<String, dynamic> json) =>
      MemberMembership(
        premium: json['premium'] as bool? ?? false,
        userId: json['user_id'] as String?,
        purchaseAllowed: json['purchase_allowed'] as bool?,
        testPurchase: json['test_purchase'] as bool? ?? false,
        testAccess: json['test_access'] is Map
            ? StoreTestAccess.fromJson(_map(json['test_access']))
            : null,
        testAccessExpiresAt: switch (json['test_access_expires_at']) {
          final String value => DateTime.parse(value),
          _ => null,
        },
        purchaseStatus: _storePurchaseStatus(json['purchase_status']),
        storeTrial: switch (json['store_trial']) {
          final Map value => MemberStoreTrial.fromJson(
            value.cast<String, dynamic>(),
          ),
          _ => null,
        },
        features: Map<String, bool>.unmodifiable(
          _map(
            json['features'],
          ).map((key, value) => MapEntry(key, value as bool? ?? false)),
        ),
        entitlements: List<MemberEntitlement>.unmodifiable(
          (json['entitlements'] as List? ?? const []).whereType<Map>().map(
            (item) => MemberEntitlement.fromJson(item.cast<String, dynamic>()),
          ),
        ),
        redeemed: json['redeemed'] as bool?,
      );

  bool get hasActivePremium =>
      _premium && (entitlements.isEmpty || activePremiumSources.isNotEmpty);

  DateTime? get premiumExpiresAt {
    final active = entitlements.where(
      (entry) => entry.featureKey == 'premium' && entry.status == 'active',
    );
    if (active.isEmpty || active.any((entry) => entry.expiresAt == null)) {
      return null;
    }
    return active
        .map((entry) => entry.expiresAt!)
        .reduce((latest, value) => value.isAfter(latest) ? value : latest);
  }

  Set<String> get activePremiumSources => entitlements
      .where(
        (entry) =>
            entry.featureKey == 'premium' &&
            entry.status == 'active' &&
            (entry.expiresAt == null ||
                entry.expiresAt!.isAfter(DateTime.now())),
      )
      .map((entry) => entry.source)
      .toSet();

  bool get hasStoreReaderEntitlement => entitlements.any(
    (entry) =>
        entry.featureKey == 'store_reader' &&
        entry.status == 'active' &&
        (entry.expiresAt == null || entry.expiresAt!.isAfter(DateTime.now())),
  );

  final String? userId;
  final bool? purchaseAllowed;
  final bool _premium;
  bool get premium => hasActivePremium;
  final bool testPurchase;
  final StoreTestAccess? testAccess;
  final String purchaseStatus;
  final Map<String, bool> features;
  final List<MemberEntitlement> entitlements;
  final bool? redeemed;
  final MemberStoreTrial? storeTrial;
  final DateTime? testAccessExpiresAt;
}

String _storePurchaseStatus(Object? value) => switch (value) {
  null || 'active' => 'active',
  'revoked' => 'revoked',
  'pending' => 'pending',
  _ => throw const FormatException('invalid store purchase status'),
};

class MemberReferralInviter {
  const MemberReferralInviter({
    required this.code,
    required this.name,
    required this.status,
  });

  factory MemberReferralInviter.fromJson(Map<String, dynamic> json) =>
      MemberReferralInviter(
        code: json['code'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
      );

  final String code;
  final String name;
  final String status;
}

class MemberReferral {
  const MemberReferral({
    required this.inviteCode,
    required this.inviteUrl,
    required this.invitedCount,
    required this.rewardedCount,
    required this.recentInvites,
    this.inviter,
  });

  factory MemberReferral.fromJson(Map<String, dynamic> json) {
    final inviter = _map(json['inviter']);
    final stats = _map(json['stats']);
    return MemberReferral(
      inviteCode: json['invite_code'] as String,
      inviteUrl: Uri.parse(json['invite_url'] as String),
      inviter: inviter.isEmpty ? null : MemberReferralInviter.fromJson(inviter),
      invitedCount: stats['invited'] as int? ?? 0,
      rewardedCount: stats['rewarded'] as int? ?? 0,
      recentInvites: List<MemberReferralInvite>.unmodifiable(
        (json['recent_invites'] as List? ?? const []).whereType<Map>().map(
          (item) => MemberReferralInvite.fromJson(item.cast<String, dynamic>()),
        ),
      ),
    );
  }

  final String inviteCode;
  final Uri inviteUrl;
  final MemberReferralInviter? inviter;
  final int invitedCount;
  final int rewardedCount;
  final List<MemberReferralInvite> recentInvites;
}

class MemberReferralInvite {
  const MemberReferralInvite({
    required this.name,
    required this.status,
    required this.boundAt,
    this.rewardedAt,
  });

  factory MemberReferralInvite.fromJson(Map<String, dynamic> json) =>
      MemberReferralInvite(
        name: json['name'] as String,
        status: json['status'] as String,
        boundAt: DateTime.parse(json['bound_at'] as String),
        rewardedAt: json['rewarded_at'] == null
            ? null
            : DateTime.parse(json['rewarded_at'] as String),
      );

  final String name;
  final String status;
  final DateTime boundAt;
  final DateTime? rewardedAt;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

DateTime? _optionalDate(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.parse(value) : null;

String? _absoluteUrl(String? value, Uri? baseUri) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.parse(value);
  return (uri.isAbsolute || baseUri == null ? uri : baseUri.resolveUri(uri))
      .toString();
}
