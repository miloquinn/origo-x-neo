import 'package:flutter/services.dart';
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
