import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_models.dart';

class ReaderInstallationCredential {
  const ReaderInstallationCredential(this.value);

  final String value;
  String get hash => sha256.convert(utf8.encode(value)).toString();
}

/// Stable anonymous identity used only for reader licensing. It deliberately
/// survives Origo account logout and account switches.
class ReaderInstallationCredentialStore {
  const ReaderInstallationCredentialStore({
    this._storage = const FlutterSecureStorage(),
  });

  static const storageKey = 'origo_x.reader.installation_key.v1';
  final FlutterSecureStorage _storage;

  Future<ReaderInstallationCredential> getOrCreate() async {
    final existing = await _storage.read(key: storageKey);
    if (existing != null && _hasAtLeast32Bytes(existing)) {
      return ReaderInstallationCredential(existing);
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final value = base64UrlEncode(bytes).replaceAll('=', '');
    await _storage.write(key: storageKey, value: value);
    return ReaderInstallationCredential(value);
  }

  bool _hasAtLeast32Bytes(String value) {
    try {
      final padding = '=' * ((4 - value.length % 4) % 4);
      return base64Url.decode('$value$padding').length >= 32;
    } catch (_) {
      return false;
    }
  }
}

/// Stores an opaque server attestation after a successful HTTPS response.
/// The signature is never "verified" with a client-side secret. Local use is
/// limited by the installation hash, channel, and server-provided validity.
class ReaderAccessCache {
  const ReaderAccessCache({this._storage = const FlutterSecureStorage()});

  static const storageKey = 'origo_x.reader.offline_attestation.v1';
  final FlutterSecureStorage _storage;

  Future<ReaderOfflineAttestation?> load({
    required ReaderInstallationCredential credential,
    required String channel,
    DateTime? now,
  }) async {
    try {
      final encoded = await _storage.read(key: storageKey);
      if (encoded == null) return null;
      final value = ReaderOfflineAttestation.fromJson(
        (jsonDecode(encoded) as Map).cast<String, dynamic>(),
      );
      final instant = now ?? DateTime.now();
      if (value.version != 1 ||
          value.installationKeyHash != credential.hash ||
          value.channel != channel ||
          !value.validUntil.isAfter(instant)) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ReaderOfflineAttestation value) =>
      _storage.write(key: storageKey, value: jsonEncode(value.toJson()));

  Future<void> clear() => _storage.delete(key: storageKey);
}

/// A previously verified reading license bound to the current secure session.
/// It grants offline reading only, not authentication or Premium source access.
class OfflineReaderLicense {
  const OfflineReaderLicense({required this.userId, this.expiresAt});

  final String userId;
  final DateTime? expiresAt;
  bool get active => expiresAt == null || expiresAt!.isAfter(DateTime.now());
}

class OfflineReaderLicenseStore {
  const OfflineReaderLicenseStore({
    this._storage = const FlutterSecureStorage(),
  });

  static const storageKey = 'origo_x.account.offline_reader_license';
  final FlutterSecureStorage _storage;

  Future<OfflineReaderLicense?> load(String? sessionBinding) async {
    if (sessionBinding == null) return null;
    try {
      final encoded = await _storage.read(key: storageKey);
      if (encoded == null) return null;
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      if (data['session_binding'] != sessionBinding) return null;
      return OfflineReaderLicense(
        userId: data['user_id'] as String,
        expiresAt: data['expires_at'] == null
            ? null
            : DateTime.parse(data['expires_at'] as String),
      );
    } catch (_) {
      // Missing secure storage or malformed data cannot grant a license.
      return null;
    }
  }

  Future<void> save(OfflineReaderLicense license, String binding) =>
      _storage.write(
        key: storageKey,
        value: jsonEncode({
          'user_id': license.userId,
          'session_binding': binding,
          'expires_at': license.expiresAt?.toIso8601String(),
        }),
      );

  /// Moves a license to a rotated secure-session binding without allowing it
  /// to cross account boundaries.
  Future<bool> rebind({
    required String oldBinding,
    required String newBinding,
    required String expectedUserId,
  }) async {
    try {
      final encoded = await _storage.read(key: storageKey);
      if (encoded == null) return false;
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      if (data['session_binding'] != oldBinding ||
          data['user_id'] != expectedUserId) {
        return false;
      }
      await _storage.write(
        key: storageKey,
        value: jsonEncode({...data, 'session_binding': newBinding}),
      );
      return true;
    } catch (_) {
      // Missing secure storage or malformed data cannot migrate a license.
      return false;
    }
  }

  Future<void> clear() => _storage.delete(key: storageKey);
}
