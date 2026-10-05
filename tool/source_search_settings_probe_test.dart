// Explicit private-input probe; source definitions stay outside the repo.
// SOURCE_FILE=/absolute/source.json SOURCE_SEARCH_ORIGIN=https://api.example
// flutter test --no-pub tool/source_search_settings_probe_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final source = parseReadingSources(
    File(env['SOURCE_FILE']!).readAsStringSync(),
  ).sources.single.toRegisteredSource(enabled: true);
  final origin = Uri.parse(env['SOURCE_SEARCH_ORIGIN']!);
  final cases = [
    (
      name: 'unset settings',
      variable: '',
      query: '西游记',
      tab: '小说',
      selected: '全部',
    ),
    (
      name: 'empty settings object',
      variable: '{}',
      query: '西游记',
      tab: '小说',
      selected: '全部',
    ),
    (
      name: 'legacy partial settings',
      variable: '{"media":"小说","source":"番茄"}',
      query: '西游记',
      tab: '小说',
      selected: '番茄',
    ),
    (
      name: 'null settings',
      variable: 'null',
      query: '西游记',
      tab: '小说',
      selected: '全部',
    ),
    (
      name: 'array settings',
      variable: '[]',
      query: '西游记',
      tab: '小说',
      selected: '全部',
    ),
    (
      name: 'source override and pagination',
      variable: '{}',
      query: '西游记@番茄',
      tab: '小说',
      selected: '番茄',
    ),
    (
      name: 'novel prefix',
      variable: '{}',
      query: 'x:西游记',
      tab: '小说',
      selected: '全部',
    ),
    (
      name: 'comic prefix',
      variable: '{}',
      query: 'm：西游记',
      tab: '漫画',
      selected: '全部',
    ),
    (
      name: 'audio prefix',
      variable: '{}',
      query: 't:西游记',
      tab: '听书',
      selected: '全部',
    ),
    (
      name: 'drama prefix',
      variable: '{}',
      query: 'd:西游记',
      tab: '短剧',
      selected: '全部',
    ),
    (
      name: 'reserved keyword characters',
      variable: '{}',
      query: 'A&B+ #一/二?@番茄',
      tab: '小说',
      selected: '番茄',
    ),
  ];
  for (final sample in cases) {
    test('search request: ${sample.name}', () async {
      final transport = _SearchTransport();
      final runtime = SourceRuntime(
        transport: transport,
        loginSessionStore: _Store(),
      );
      addTearDown(runtime.close);
      await runtime.login(
        source,
        const {},
        action: 'source.setVariable(${jsonEncode(sample.variable)});',
      );
      final result = await runtime.search(source, sample.query, page: 2);
      expect(result.items, hasLength(1));
      final request = transport.requests.single;
      expect(request.url.origin, origin.origin);
      expect(request.url.path, '/search');
      expect(request.url.fragment, isEmpty);
      expect(request.url.queryParameters, {
        'title': sample.name == 'reserved keyword characters'
            ? 'A&B+ #一/二?'
            : '西游记',
        'tab': sample.tab,
        'source': sample.selected,
        'page': '2',
        'disabled_sources': '0',
      });
    });
  }
  test(
    'configured server and explicit disabled settings remain intact',
    () async {
      final transport = _SearchTransport();
      final runtime = SourceRuntime(
        transport: transport,
        loginSessionStore: _Store(),
      );
      addTearDown(runtime.close);
      final settings = {
        'server': 'https://fixture.test',
        'tab': '漫画',
        'sources': '甲&乙',
        'fqpara': 'off',
        'fqcommunity': 'off',
        'pstyle': '3',
        'disabled_sources': '1',
      };
      final encoded = jsonEncode(settings);
      final configured = await runtime.login(
        source,
        const {},
        action:
            'source.setVariable(${jsonEncode(encoded)}); java.toast(JSON.stringify(getArguments(source.getVariable())));',
      );
      expect(jsonDecode(configured!), containsPair('fqpara', 'off'));
      expect(jsonDecode(configured), containsPair('fqcommunity', 'off'));
      expect(jsonDecode(configured), containsPair('pstyle', '3'));
      await runtime.search(source, '西游记');
      final request = transport.requests.single;
      expect(request.url.origin, 'https://fixture.test');
      expect(request.url.queryParameters['tab'], '漫画');
      expect(request.url.queryParameters['source'], '甲&乙');
      expect(request.url.queryParameters['disabled_sources'], '1');
    },
  );
}

class _SearchTransport implements SourceTransport {
  final requests = <SourceRequestTemplate>[];

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    requests.add(request);
    return SourceResponse(
      finalUri: request.url,
      body: jsonEncode({
        'data': [
          {
            'book_id': 'fixture',
            'book_name': '合成图书',
            'author': '合成作者',
            'source': 'fixture',
            'tab': '小说',
            'tags': '合成分类',
          },
        ],
      }),
    );
  }
}

class _Store implements SourceLoginSessionStore {
  SourceLoginSession _session = const SourceLoginSession();
  @override
  Future<SourceLoginSession> read(String sourceId) async => _session;
  @override
  Future<void> write(String sourceId, SourceLoginSession session) async =>
      _session = session;
  @override
  Future<void> clear(String sourceId) async =>
      _session = const SourceLoginSession();
}
