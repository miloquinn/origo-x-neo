import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'account_api_client.dart';
import 'account_models.dart';

abstract interface class GoogleNativeSignInClient {
  Future<String?> authenticate(
    GoogleNativeAuthConfig config, {
    required TargetPlatform platform,
  });
}

/// Narrow SDK boundary so account-flow tests do not invoke platform channels.
@visibleForTesting
abstract interface class GoogleNativeSignInSdk {
  Future<void> initialize({String? clientId, String? serverClientId});

  Future<void> signOut();

  Future<String?> authenticate();
}

class GoogleNativeSignInService implements GoogleNativeSignInClient {
  GoogleNativeSignInService({GoogleNativeSignInSdk? sdk})
    : _sdk = sdk ?? _GoogleNativeSignInSdk();

  static final GoogleNativeSignInService instance = GoogleNativeSignInService();

  final GoogleNativeSignInSdk _sdk;
  _GoogleInitialization? _configuration;
  Future<void>? _initialization;

  @override
  Future<String?> authenticate(
    GoogleNativeAuthConfig config, {
    required TargetPlatform platform,
  }) async {
    final initialization = _validatedConfiguration(config, platform);
    final configured = _configuration;
    if (configured != null && configured != initialization) {
      throw const MemberAccountException(
        'Google 登录配置已更新，请重启应用后再试',
        code: 'google_configuration_changed',
      );
    }
    _configuration ??= initialization;
    _initialization ??= _sdk.initialize(
      clientId: initialization.clientId,
      serverClientId: initialization.serverClientId,
    );
    try {
      await _initialization;
      // The native SDKs keep a current account. Signing out before the explicit
      // action makes every tap interactive and permits choosing another account.
      await _sdk.signOut();
      final token = (await _sdk.authenticate())?.trim();
      if (token == null || token.isEmpty) {
        throw const MemberAccountException(
          'Google 未返回身份令牌，请重新登录',
          code: 'google_identity_token_missing',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      final detail = error.description?.trim();
      throw MemberAccountException(
        detail == null || detail.isEmpty
            ? 'Google 登录失败，请检查应用配置后重试'
            : 'Google 登录失败：$detail',
        code: 'google_sign_in_failed',
      );
    }
  }

  _GoogleInitialization _validatedConfiguration(
    GoogleNativeAuthConfig config,
    TargetPlatform platform,
  ) {
    if (!config.enabled) {
      throw const MemberAccountException(
        'Google 原生登录尚未启用',
        code: 'google_native_disabled',
      );
    }
    final serverClientId = config.serverClientId?.trim();
    if (serverClientId == null || serverClientId.isEmpty) {
      throw const MemberAccountException(
        'Google 登录缺少服务器客户端配置',
        code: 'google_configuration_invalid',
      );
    }
    final iosClientId = config.iosClientId?.trim();
    if (platform == TargetPlatform.iOS &&
        (iosClientId == null || iosClientId.isEmpty)) {
      throw const MemberAccountException(
        'Google 登录缺少 iOS 客户端配置',
        code: 'google_configuration_invalid',
      );
    }
    return _GoogleInitialization(
      clientId: platform == TargetPlatform.iOS ? iosClientId : null,
      serverClientId: serverClientId,
    );
  }
}

class _GoogleNativeSignInSdk implements GoogleNativeSignInSdk {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  Future<void> initialize({String? clientId, String? serverClientId}) =>
      _googleSignIn.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

  @override
  Future<void> signOut() => _googleSignIn.signOut();

  @override
  Future<String?> authenticate() async =>
      (await _googleSignIn.authenticate()).authentication.idToken;
}

class _GoogleInitialization {
  const _GoogleInitialization({this.clientId, required this.serverClientId});

  final String? clientId;
  final String serverClientId;

  @override
  bool operator ==(Object other) =>
      other is _GoogleInitialization &&
      other.clientId == clientId &&
      other.serverClientId == serverClientId;

  @override
  int get hashCode => Object.hash(clientId, serverClientId);
}
