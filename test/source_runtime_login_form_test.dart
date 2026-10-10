import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'token action persists form updates across runtime recreation',
    () async {
      final config = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Shared token form',
        'bookSourceUrl': 'https://books.test',
        'loginUi': r'''[
        {name: '设置', type: 'button', style: {layout_flexBasisPercent: 1}},
        {'name': '作者', 'type': 'text'},
        {'name': ' Token ', 'type': 'text'},
        {name: '获取', type: 'button', action: 'acquire()',
         style: {layout_flexBasisPercent: 0.4}},
        {name: '查询', type: 'button', action: 'check()'},
      ]''',
        'loginUrl': r'''
        function acquire() {
          var response = JSON.parse(java.ajax('/session'));
          result[' Token '] = response.token;
          source.setVariable(response.token);
          source.putLoginInfo(JSON.stringify(result));
          java.longToast('Token saved');
        }
        function check() {
          var response = JSON.parse(java.ajax('/check'));
          java.longToast(response.message);
        }
      ''',
        'header': '@js: JSON.stringify({"X-Token": source.getVariable()})',
        'searchUrl': '/search?q={{key}}',
        'ruleSearch': {
          'bookList': 'data[*]',
          'name': 'title',
          'bookUrl': 'url',
        },
      });
      final source = config.toRegisteredSource(enabled: true);
      final store = _SessionStore();
      final transport = _Transport();
      var runtime = SourceRuntime(
        transport: transport,
        loginSessionStore: store,
      );
      final fields = await runtime.loadLoginFields(source);
      expect(fields.first.isSectionHeading, isTrue);
      expect(fields[3].flexBasisPercent, 0.4);
      expect(
        await runtime.login(source, const {
          '作者': 'author',
          ' Token ': '',
        }, action: 'acquire()'),
        'Token saved',
      );
      expect((await store.read(source.id)).sourceVariable, 'fixture-token');
      expect((await store.read(source.id)).loginInfo, {
        '作者': 'author',
        ' Token ': 'fixture-token',
      });
      runtime.close();
      runtime = SourceRuntime(transport: transport, loginSessionStore: store);
      addTearDown(runtime.close);

      final restored = await runtime.loadLoginFields(source);
      expect(restored[2].name, ' Token ');
      expect(restored[2].defaultValue, 'fixture-token');
      await runtime.login(source, {
        for (final field in restored)
          if (!field.isButton) field.name: field.defaultValue ?? '',
      }, action: 'check()');
      final page = await runtime.search(source, 'sample');
      expect(page.items.single.title, 'Book');
      expect(transport.requests.last.headers['X-Token'], 'fixture-token');
      expect(
        (await store.read(source.id)).loginInfo[' Token '],
        'fixture-token',
      );
    },
  );

  test('script-generated form changes are flushed before returning', () async {
    final source = ReadingSourceConfig.fromJson({
      'bookSourceName': 'Generated form',
      'bookSourceUrl': 'https://books.test',
      'loginUrl': 'function login() {}',
      'loginUi': '''@js:
        source.setVariable('generated-state');
        JSON.stringify([{name: 'account', type: 'text', default: 'guest'}]);
      ''',
    }).toRegisteredSource(enabled: true);
    final store = _SessionStore();
    final runtime = SourceRuntime(loginSessionStore: store);
    addTearDown(runtime.close);

    final fields = await runtime.loadLoginFields(source);
    expect(fields.single.defaultValue, 'guest');
    expect((await store.read(source.id)).sourceVariable, 'generated-state');
  });

  test(
    'exact field keys retain values saved under legacy trimmed names',
    () async {
      final source = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Legacy form',
        'bookSourceUrl': 'https://books.test',
        'loginUrl': 'function login() {}',
        'loginUi': '[{"name": " Token ", "type": "text"}]',
      }).toRegisteredSource(enabled: true);
      final runtime = SourceRuntime(loginSessionStore: _SessionStore());
      addTearDown(runtime.close);
      await runtime.saveLoginSession(
        source,
        loginInfo: const {'Token': 'legacy'},
      );

      expect(
        (await runtime.loadLoginFields(source)).single.defaultValue,
        'legacy',
      );
      await runtime.saveLoginSession(
        source,
        loginInfo: const {'Token': 'legacy', ' Token ': 'exact'},
      );
      expect(
        (await runtime.loadLoginFields(source)).single.defaultValue,
        'exact',
      );
    },
  );

  test(
    'invalid form reports a bounded error without declaration contents',
    () async {
      final source = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Invalid form',
        'bookSourceUrl': 'https://books.test',
        'loginUrl': 'function login() {}',
        'loginUi': '[{name: "fixture-secret", default: getToken()}]',
      }).toRegisteredSource(enabled: true);
      final runtime = SourceRuntime(loginSessionStore: _SessionStore());
      addTearDown(runtime.close);

      await expectLater(
        runtime.loadLoginFields(source),
        throwsA(
          isA<BookSourceProtocolException>().having(
            (error) => error.message,
            'message',
            'This source defines an invalid login form.',
          ),
        ),
      );
    },
  );
}

class _SessionStore implements SourceLoginSessionStore {
  final _sessions = <String, SourceLoginSession>{};
  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      _sessions[sourceId] ?? const SourceLoginSession();
  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    _sessions[sourceId] = session;
  }

  @override
  Future<void> clear(String sourceId) async => _sessions.remove(sourceId);
}

class _Transport implements SourceTransport {
  final requests = <SourceRequestTemplate>[];
  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    requests.add(request);
    return SourceResponse(
      body: jsonEncode(switch (request.url.path) {
        '/session' => {'token': 'fixture-token'},
        '/check' => {'message': 'Token valid'},
        '/search' => {
          'data': [
            {'title': 'Book', 'url': '/book/1'},
          ],
        },
        _ => throw StateError('Unexpected fixture request.'),
      }),
      finalUri: request.url,
      statusCode: 200,
    );
  }
}
