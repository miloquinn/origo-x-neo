import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/scripting/source_script_engine.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  test(
    'official source cache keys share the persisted login session contract',
    () async {
      final store = _SecureMemoryStore();
      final source = _source();
      final registered = source.toRegisteredSource(enabled: true);
      var runtime = _runtime(store);
      addTearDown(() => runtime.close());

      expect(
        await runtime.login(
          registered,
          const {'邮箱': 'reader@example.test', '密码': 'test-only'},
          action: r'''
var info = JSON.parse(source.getLoginInfo());
info['密钥'] = 'persisted-key';
putEncryptedLoginInfo(JSON.stringify(info));
if (JSON.parse(source.getLoginInfo())['密钥'] !== 'persisted-key') {
  throw new Error('encrypted cache write was not published');
}
source.putVariable('{"server":"configured.test"}');
source.put('cursor', 'page-2');
source.putLoginHeader('opaque-header');
java.toast('canonical-ready');
''',
        ),
        'canonical-ready',
      );
      expect(store.value.loginInfo['密钥'], 'persisted-key');
      expect(store.value.sourceVariable, '{"server":"configured.test"}');
      expect(store.value.rawLoginHeader, 'opaque-header');

      runtime.close();
      runtime = _runtime(store);
      expect(
        await runtime.login(
          registered,
          const {},
          action: r'''
var encrypted = cache.get('userInfo_' + source.getKey());
var decrypted = java.createSymmetricCrypto('AES', java.androidId())
  .decryptStr(encrypted);
decrypted = String(decrypted).split(String.fromCharCode(0)).join('');
var info = JSON.parse(decrypted);
if (info['密钥'] !== 'persisted-key' ||
    JSON.parse(source.getLoginInfo())['密钥'] !== 'persisted-key' ||
    source.getVariable() !== '{"server":"configured.test"}' ||
    source.get('cursor') !== 'page-2' ||
    source.getLoginHeader() !== 'opaque-header') {
  throw new Error('canonical session cache was not restored');
}
java.toast('canonical-restored');
''',
        ),
        'canonical-restored',
      );

      await runtime.saveLoginSession(
        registered,
        loginInfo: const {
          '邮箱': 'updated@example.test',
          '密码': 'updated-only',
          '密钥': 'native-key',
        },
      );
      expect(
        await runtime.login(
          registered,
          const {},
          action: r'''
var encrypted = cache.get('userInfo_' + source.getKey());
var decrypted = java.createSymmetricCrypto('AES', java.androidId())
  .decryptStr(encrypted);
decrypted = String(decrypted).split(String.fromCharCode(0)).join('');
if (JSON.parse(decrypted)['密钥'] !== 'native-key' ||
    JSON.parse(source.getLoginInfo())['密钥'] !== 'native-key') {
  throw new Error('native session update was shadowed by stale cache');
}
java.toast('native-authoritative');
''',
        ),
        'native-authoritative',
      );

      expect(
        await runtime.login(
          registered,
          const {},
          action: r'''
cache.delete('userInfo_' + source.getKey());
cache.delete('sourceVariable_' + source.getKey());
cache.delete('loginHeader_' + source.getKey());
cache.delete('v_' + source.getKey() + '_cursor');
var clearedInfo = JSON.parse(source.getLoginInfo());
if (Object.prototype.hasOwnProperty.call(clearedInfo, '密钥') ||
    source.getVariable() !== '' || source.getLoginHeader() !== '' ||
    source.get('cursor') !== '') {
  throw new Error('canonical cache delete was not authoritative');
}
if (source.putLoginInfo('{"temporary":"value"}') !== true ||
    source.removeLoginInfo() !== true || source.getLoginInfo() !== '{}') {
  throw new Error('official login info methods are incomplete');
}
java.toast('canonical-cleared');
''',
        ),
        'canonical-cleared',
      );
      runtime.close();

      runtime = _runtime(store);
      expect(
        await runtime.login(
          registered,
          const {},
          action: r'''
var restoredClearedInfo = JSON.parse(source.getLoginInfo());
if (Object.prototype.hasOwnProperty.call(restoredClearedInfo, '密钥') ||
    source.getVariable() !== '' || source.getLoginHeader() !== '' ||
    source.get('cursor') !== '') {
  throw new Error('cleared canonical values returned after restart: ' +
    JSON.stringify([source.getLoginInfo(), source.getVariable(),
      source.getLoginHeader(), source.get('cursor')]));
}
java.toast('clear-restored');
''',
        ),
        'clear-restored',
      );
    },
  );

  test('owned empty login session replaces stale evaluator state', () {
    final evaluator = QuickJsSourceScriptEvaluator();
    addTearDown(evaluator.dispose);
    final source = _source();

    expect(
      evaluator.evaluate(
        "source.putLoginInfo('{\"stale\":\"value\"}')",
        SourceScriptContext(source: source),
      ),
      isTrue,
    );

    var written = const <String, String>{'unexpected': 'value'};
    var cache = const <String, SourceScriptCacheEntry>{};
    expect(
      evaluator.evaluate(
        'source.getLoginInfo()',
        SourceScriptContext(
          source: source,
          loginInfo: const {},
          loginInfoWriter: (value) => written = value,
          persistentCacheReader: () => cache,
          persistentCacheWriter: (value) => cache = value,
        ),
      ),
      '{}',
    );
    expect(written, isEmpty);
    expect(cache, isEmpty);
  });

  test('reserved source cache keys retain explicit expiry semantics', () async {
    final store = _SecureMemoryStore();
    final source = _source();
    final registered = source.toRegisteredSource(enabled: true);
    var runtime = _runtime(store);
    addTearDown(() => runtime.close());

    expect(
      await runtime.login(
        registered,
        const {},
        action: r'''
cache.put('sourceVariable_' + source.getKey(), 'temporary', 1);
java.toast(source.getVariable());
''',
      ),
      'temporary',
    );
    runtime.close();
    await Future<void>.delayed(const Duration(milliseconds: 1100));

    runtime = _runtime(store);
    expect(
      await runtime.login(
        registered,
        const {},
        action:
            "java.toast(source.getVariable() === '' ? 'expired' : 'stale');",
      ),
      'expired',
    );
  });

  test(
    'reserved source cache keys expire during the same invocation',
    () async {
      final store = _SecureMemoryStore();
      final runtime = _runtime(store);
      addTearDown(runtime.close);
      final registered = _source().toRegisteredSource(enabled: true);

      expect(
        await runtime.login(
          registered,
          const {},
          action: r'''
var key = java.androidId();
var encrypted = Packages.android.util.Base64.encodeToString(
  java.createSymmetricCrypto('AES', key).encrypt('{"密钥":"temporary"}'), 2
);
cache.put('sourceVariable_' + source.getKey(), 'temporary', 1);
cache.put('userInfo_' + source.getKey(), encrypted, 1);
cache.put('loginHeader_' + source.getKey(), '{"X-Temporary":"value"}', 1);
var deadline = Date.now() + 1100;
while (Date.now() < deadline) {}
var headerMap = source.getLoginHeaderMap();
if (source.getVariable() !== '' || source.getLoginInfo() !== '{}' ||
    source.getLoginHeader() !== '' || headerMap.size() !== 0 ||
    cache.get('sourceVariable_' + source.getKey()) !== null ||
    cache.get('userInfo_' + source.getKey()) !== null ||
    cache.get('loginHeader_' + source.getKey()) !== null) {
  throw new Error('expired canonical value fell back to invocation state');
}
java.toast('same-invocation-expired');
''',
        ),
        'same-invocation-expired',
      );
      expect(store.value.sourceVariable, isEmpty);
      expect(store.value.loginInfo, isEmpty);
      expect(store.value.rawLoginHeader, isEmpty);
    },
  );
}

ReadingSourceConfig _source() => ReadingSourceConfig.fromJson({
  'bookSourceName': 'Canonical session cache fixture',
  'bookSourceUrl': 'https://books.test',
  'loginUi': [
    {'name': '邮箱', 'type': 'text'},
    {'name': '密码', 'type': 'password'},
  ],
  'loginUrl': r'''
function putEncryptedLoginInfo(info) {
  var key = java.androidId();
  var encoded = Packages.android.util.Base64.encodeToString(
    java.createSymmetricCrypto('AES', key).encrypt(info), 2
  );
  cache.put('userInfo_' + source.getKey(), encoded);
  return true;
}
function login() {}
''',
});

SourceRuntime _runtime(_SecureMemoryStore store) =>
    SourceRuntime(loginSessionStore: store, transport: const _Transport());

class _SecureMemoryStore implements SourceLoginSessionStore {
  SourceLoginSession value = const SourceLoginSession();

  @override
  Future<SourceLoginSession> read(String sourceId) async => value;

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    value = SourceLoginSession.fromJson(
      jsonDecode(jsonEncode(session.toJson())),
    );
  }

  @override
  Future<void> clear(String sourceId) async {
    value = const SourceLoginSession();
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
