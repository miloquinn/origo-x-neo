import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'source_browser_session.dart';

class SourceScriptCacheEntry {
  const SourceScriptCacheEntry({required this.value, this.expiresAt});

  final Object? value;
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => {
    'value': value,
    'expiresAt': expiresAt?.millisecondsSinceEpoch,
  };

  factory SourceScriptCacheEntry.fromJson(Object? value) {
    if (value is! Map) return const SourceScriptCacheEntry(value: null);
    final expiresAt = switch (value['expiresAt']) {
      final num milliseconds => DateTime.fromMillisecondsSinceEpoch(
        milliseconds.toInt(),
      ),
      _ => null,
    };
    return SourceScriptCacheEntry(value: value['value'], expiresAt: expiresAt);
  }
}

class SourceLoginSession {
  const SourceLoginSession({
    this.loginInfo = const {},
    this.loginHeaders = const {},
    this.rawLoginHeader,
    this.sourceVariable = '',
    this.scriptCache = const {},
    this.browserSession = const SourceBrowserSession(),
  });

  final Map<String, String> loginInfo;
  final Map<String, String> loginHeaders;
  // Legado allows an opaque token here as well as a JSON header object.
  // Only loginHeaders is sent automatically; the raw value is script storage.
  final String? rawLoginHeader;
  final String sourceVariable;
  final Map<String, SourceScriptCacheEntry> scriptCache;
  final SourceBrowserSession browserSession;

  Map<String, Object?> toJson() => {
    'loginInfo': loginInfo,
    'loginHeaders': loginHeaders,
    'rawLoginHeader': rawLoginHeader,
    'sourceVariable': sourceVariable,
    'scriptCache': {
      for (final entry in scriptCache.entries) entry.key: entry.value.toJson(),
    },
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
      sourceVariable: value['sourceVariable'] is String
          ? value['sourceVariable'] as String
          : '',
      scriptCache: _scriptCache(value['scriptCache']),
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

Map<String, SourceScriptCacheEntry> _scriptCache(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries)
      '${entry.key}': SourceScriptCacheEntry.fromJson(entry.value),
  });
}
