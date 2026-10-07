import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  test('persistent cache survives runtime recreation', () async {
    final store = _Store();
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());

    await _action(runtime, _source(), "cache.put('key', 'saved');");
    runtime.close();

    runtime = _runtime(store);
    expect(
      await _action(
        runtime,
        _source(),
        "java.toast(String(cache.get('key')));",
      ),
      'saved',
    );
  });

  test('persistent cache expiry uses an absolute deadline', () async {
    final store = _Store();
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());

    await _action(runtime, _source(), "cache.put('ttl', 'saved', 1);");
    runtime.close();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    runtime = _runtime(store);
    expect(
      await _action(
        runtime,
        _source(),
        "java.toast(String(cache.get('ttl')));",
      ),
      'null',
    );
  });

  test('memory cache stays evaluator-local', () async {
    final store = _Store();
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());

    await _action(runtime, _source(), "cache.putMemory('key', 'memory');");
    runtime.close();

    runtime = _runtime(store);
    expect(
      await _action(
        runtime,
        _source(),
        "java.toast(String(cache.getFromMemory('key')));",
      ),
      'null',
    );
  });

  test('session clear is authoritative over stale evaluator cache', () async {
    final store = _Store();
    final source = _source();
    final runtime = _runtime(store);
    addTearDown(runtime.close);

    await _action(runtime, source, "cache.put('key', 'stale');");
    await runtime.clearLoginSession(source.toRegisteredSource(enabled: true));

    expect(
      await _action(runtime, source, "java.toast(String(cache.get('key')));"),
      'null',
    );
  });

  test('persistent cache stays isolated by source', () async {
    final store = _Store();
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());
    final first = _source(url: 'https://first.test');
    final second = _source(url: 'https://second.test');

    await _action(runtime, first, "cache.put('shared', 'first');");
    await _action(runtime, second, "cache.put('shared', 'second');");
    runtime.close();

    runtime = _runtime(store);
    expect(
      await _action(runtime, first, "java.toast(String(cache.get('shared')));"),
      'first',
    );
    expect(
      await _action(
        runtime,
        second,
        "java.toast(String(cache.get('shared')));",
      ),
      'second',
    );
  });

  test('cache writes survive a network replay', () async {
    final store = _Store();
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());
    final source = _source();

    expect(
      await _action(runtime, source, r'''
if (cache.get('before-network') == null) {
  cache.put('before-network', 'saved');
  java.ajax('/ping');
}
java.toast(String(cache.get('before-network')));
'''),
      'saved',
    );
    runtime.close();

    runtime = _runtime(store);
    expect(
      await _action(
        runtime,
        source,
        "java.toast(String(cache.get('before-network')));",
      ),
      'saved',
    );
  });
}

ReadingSourceConfig _source({String url = 'https://books.test'}) =>
    ReadingSourceConfig.fromJson({
      'bookSourceName': 'Persistent cache fixture',
      'bookSourceUrl': url,
      'loginUrl': 'function login() {}',
    });

Future<String?> _action(
  SourceRuntime runtime,
  ReadingSourceConfig source,
  String action,
) => runtime.login(
  source.toRegisteredSource(enabled: true),
  const {},
  action: action,
);

SourceRuntime _runtime(_Store store) =>
    SourceRuntime(loginSessionStore: store, transport: const _Transport());

class _Store implements SourceLoginSessionStore {
  final Map<String, SourceLoginSession> values = {};

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      values[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    values[sourceId] = SourceLoginSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())),
    );
  }

  @override
  Future<void> clear(String sourceId) async {
    values.remove(sourceId);
  }
}

class _Transport implements SourceTransport {
  const _Transport();

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async => SourceResponse(finalUri: request.url, body: '{}');
}
