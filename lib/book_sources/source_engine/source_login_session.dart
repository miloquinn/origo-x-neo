import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'source_browser_session.dart';

class SourceLoginSession {
  const SourceLoginSession({
    this.loginInfo = const {},
    this.loginHeaders = const {},
    this.rawLoginHeader,
    this.browserSession = const SourceBrowserSession(),
  });

  final Map<String, String> loginInfo;
  final Map<String, String> loginHeaders;
  // Legado allows an opaque token here as well as a JSON header object.
  // Only loginHeaders is sent automatically; the raw value is script storage.
  final String? rawLoginHeader;
  final SourceBrowserSession browserSession;

  Map<String, Object?> toJson() => {
    'loginInfo': loginInfo,
    'loginHeaders': loginHeaders,
    'rawLoginHeader': rawLoginHeader,
    'browserSession': browserSession.toJson(),
  };

  factory SourceLoginSession.fromJson(Object? value) {
    if (value is! Map) return const SourceLoginSession();
    return SourceLoginSession(
      loginInfo: _stringMap(value['loginInfo']),
      loginHeaders: _stringMap(value['loginHeaders']),
      rawLoginHeader: value['rawLoginHeader'] is String
          ? value['rawLoginHeader'] as String
          : null,
      browserSession: SourceBrowserSession.fromJson(value['browserSession']),
    );
  }
}

abstract interface class SourceLoginSessionStore {
  Future<SourceLoginSession> read(String sourceId);

  Future<void> write(String sourceId, SourceLoginSession session);

  Future<void> clear(String sourceId);
}

class SecureSourceLoginSessionStore implements SourceLoginSessionStore {
  SecureSourceLoginSessionStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _prefix = 'origo_x.source_session.';
  // Sessions saved before the Origo X rename live under this prefix; read()
  // migrates them lazily and clear() must drop them too, otherwise a logout
  // would resurrect the pre-rename login on the next read.
  static const _legacyPrefix = 'open_reading.source_session.';
  final FlutterSecureStorage _storage;

  String _key(String sourceId) => '$_prefix$sourceId';
  String _legacyKey(String sourceId) => '$_legacyPrefix$sourceId';

  @override
  Future<SourceLoginSession> read(String sourceId) async {
    var raw = await _storage.read(key: _key(sourceId));
    if (raw == null) {
      final legacy = await _storage.read(key: _legacyKey(sourceId));
      if (legacy != null && legacy.trim().isNotEmpty) {
        await _storage.write(key: _key(sourceId), value: legacy);
        await _storage.delete(key: _legacyKey(sourceId));
        raw = legacy;
      }
    }
    if (raw == null || raw.trim().isEmpty) return const SourceLoginSession();
    try {
      return SourceLoginSession.fromJson(jsonDecode(raw));
    } on FormatException {
      return const SourceLoginSession();
    }
  }

  @override
  Future<void> write(String sourceId, SourceLoginSession session) {
    return _storage.write(
      key: _key(sourceId),
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear(String sourceId) async {
    await _storage.delete(key: _key(sourceId));
    await _storage.delete(key: _legacyKey(sourceId));
  }
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries) '${entry.key}': '${entry.value ?? ''}',
  });
}
