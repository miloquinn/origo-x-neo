import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_runtime_login.dart';

void main() {
  test(
    'public reading keeps in-memory session when secure storage is unavailable',
    () async {
      final manager = SourceRuntimeSessionManager(_MissingPluginStore(), null);
      final source = ReadingSourceConfig.fromJson(const {
        'bookSourceName': 'Public source',
        'bookSourceUrl': 'https://books.test',
      });

      await manager.ensure(source);
      manager.updateInfo(source, const {'token': 'memory-only'});

      await manager.flush(source);

      expect(manager.current(source).loginInfo, {'token': 'memory-only'});
    },
  );

  test(
    'explicit login persistence still reports unavailable secure storage',
    () async {
      final manager = SourceRuntimeSessionManager(_MissingPluginStore(), null);
      final source = ReadingSourceConfig.fromJson(const {
        'bookSourceName': 'Login source',
        'bookSourceUrl': 'https://books.test',
      });

      await expectLater(
        manager.save(source, loginInfo: const {'token': 'must-persist'}),
        throwsA(isA<MissingPluginException>()),
      );
    },
  );

  test('pre-rename session keys migrate to the current prefix on read', () async {
    const sourceId = 'https://books.test/login';
    const legacyKey = 'open_reading.source_session.$sourceId';
    const currentKey = 'origo_x.source_session.$sourceId';
    final stored =
        jsonEncode(const SourceLoginSession(loginInfo: {'token': 'legacy'})
            .toJson());
    FlutterSecureStorage.setMockInitialValues({legacyKey: stored});
    final store = SecureSourceLoginSessionStore();
    final secure = const FlutterSecureStorage();

    final restored = await store.read(sourceId);

    expect(restored.loginInfo, {'token': 'legacy'});
    expect(await secure.read(key: currentKey), stored);
    expect(await secure.read(key: legacyKey), isNull);
  });

  test('clearing a session also removes the legacy pre-rename key', () async {
    const sourceId = 'https://books.test/login';
    const legacyKey = 'open_reading.source_session.$sourceId';
    final stored =
        jsonEncode(const SourceLoginSession(loginInfo: {'token': 'legacy'})
            .toJson());
    FlutterSecureStorage.setMockInitialValues({legacyKey: stored});
    final store = SecureSourceLoginSessionStore();
    final secure = const FlutterSecureStorage();

    await store.clear(sourceId);

    expect(await secure.read(key: legacyKey), isNull);
    expect(
      await store.read(sourceId),
      const SourceLoginSession(),
    );
  });
}

class _MissingPluginStore implements SourceLoginSessionStore {
  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    throw MissingPluginException('secure storage is unavailable');
  }

  @override
  Future<void> clear(String sourceId) async {}
}
