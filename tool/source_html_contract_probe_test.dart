// Opt-in contract probe for a user-supplied HTML/FlutterJSBridge source:
// SOURCE_HTML_PATH=/absolute/source.json flutter test --no-pub \
//   tool/source_html_contract_probe_test.dart --reporter expanded
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
  final path = Platform.environment['SOURCE_HTML_PATH'];
  if (path == null || path.trim().isEmpty) {
    throw ArgumentError('SOURCE_HTML_PATH must point to the source export.');
  }
  final imported = parseReadingSources(File(path).readAsStringSync());
  if (imported.errors.isNotEmpty || imported.sources.length != 1) {
    throw FormatException(
      'Expected one valid source: errors=${imported.errors.length}, '
      'sources=${imported.sources.length}.',
    );
  }

  test('original HTML source completes the synthetic reading chain', () async {
    final config = imported.sources.single;
    expect(config.runnableCapabilities, {
      'search',
      'detail',
      'catalog',
      'content',
    });
    final transport = _HtmlContractTransport();
    final runtime = SourceRuntime(
      transport: transport,
      loginSessionStore: _MemorySessionStore(),
    );
    addTearDown(runtime.close);
    final source = config.toRegisteredSource(enabled: true);

    final search = await runtime.search(source, '测试');
    expect(search.items.single.title, '原始聚合测试书');

    final book = await runtime.getBook(source, search.items.single.id);
    expect(book.author, '测试作者');

    final chapters = await runtime.getChapters(source, book.id);
    expect(chapters.single.title, '第一章');

    final content = await runtime.getChapterContent(
      source,
      bookId: book.id,
      chapterId: chapters.single.id,
    );
    expect(content.content, contains('原始聚合正文'));
    expect(
      transport.requests.map((request) => request.url.path),
      containsAll(['/search', '/detail', '/catalog', '/content']),
    );
  });
}

class _HtmlContractTransport implements SourceTransport, SourceCookieTransport {
  final requests = <SourceRequestTemplate>[];
  final _cookies = <String, String>{};

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    requests.add(request);
    final body = switch (request.url.path) {
      '/static/source_config/gyks.html' => "let localVersion = '26.9.26'",
      '/search' => jsonEncode({
        'data': [
          {
            'book_id': 'book-1',
            'book_name': '原始聚合测试书',
            'author': '测试作者',
            'status': '连载',
            'score': '9.0',
            'tags': '测试',
            'thumb_url': 'https://img.test/cover.jpg',
            'abstract': '简介',
            'word_number': '1000',
            'tab': '小说',
            'source': '测试源',
            'latest_chapter_title': '第一章',
          },
        ],
      }),
      '/detail' => jsonEncode({
        'data': {
          'book_id': 'book-1',
          'book_name': '原始聚合测试书',
          'author': '测试作者',
          'status': '连载',
          'score': '9.0',
          'tags': '测试',
          'thumb_url': 'https://img.test/cover.jpg',
          'abstract': '简介',
          'word_number': '1000',
          'tab': '小说',
          'source': '测试源',
          'latest_chapter_title': '第一章',
          'last_chapter_update_time': '今天',
        },
      }),
      '/catalog' => jsonEncode({
        'data': [
          {
            'title': '第一章',
            'item_id': 'chapter-1',
            'source': '测试源',
            'first_pass_time': 1700000000,
          },
        ],
      }),
      '/content' => jsonEncode({'content': '<p>原始聚合正文</p>', 'msg': ''}),
      _ => jsonEncode({'data': [], 'content': ''}),
    };
    return SourceResponse(body: body, finalUri: request.url);
  }

  @override
  String scriptCookieHeader(String jarKey, Uri uri) => _cookies[jarKey] ?? '';

  @override
  void setScriptCookies(String jarKey, Uri uri, String cookieHeader) {
    _cookies[jarKey] = cookieHeader;
  }

  @override
  void removeScriptCookies(String jarKey, Uri uri) {
    _cookies.remove(jarKey);
  }
}

class _MemorySessionStore implements SourceLoginSessionStore {
  final values = <String, SourceLoginSession>{};

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      values[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    values[sourceId] = session;
  }

  @override
  Future<void> clear(String sourceId) async => values.remove(sourceId);
}
