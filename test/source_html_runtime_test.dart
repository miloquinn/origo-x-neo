import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_script_engine.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('HTML source capabilities come from its callable contract', () {
    final source = _source();

    expect(source.runnableCapabilities, {
      'search',
      'detail',
      'catalog',
      'content',
    });
    expect(
      const SourceCompatibilityScanner().scan(source).level,
      SourceCompatibilityLevel.supported,
    );
  });

  test(
    'HTML source runs search, detail, catalog, and content via one bridge',
    () async {
      final transport = _HtmlTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final source = _source().toRegisteredSource(enabled: true);

      final search = await runtime.search(source, '银河');
      expect(search.items.single.title, '银河书');
      expect(search.items.single.id, '/book/1');

      final book = await runtime.getBook(source, search.items.single.id);
      expect(book.author, '作者');
      expect(book.sourceVariables['htmlTocUrl'], '{"book":1}');

      final chapters = await runtime.getChapters(source, book.id);
      expect(chapters.single.title, '第一章');

      final content = await runtime.getChapterContent(
        source,
        bookId: book.id,
        chapterId: chapters.single.id,
      );
      expect(content.contentType, 'text/html');
      expect(content.content, '<p>正文</p>');

      expect(transport.requests.map((request) => request.url.path), [
        '/search',
        '/info',
        '/catalog',
        '/content',
      ]);
      expect(transport.cookies.values, contains('sid=bridge'));
    },
  );

  test('HTML bridge removes LoginInfo from the shared login session', () async {
    final evaluator = QuickJsSourceScriptEvaluator();
    addTearDown(evaluator.dispose);
    Map<String, String>? written;

    final result = await evaluator.evaluateAsync(
      r'''
(async () => {
  await window.flutter_inappwebview.callHandler('cache.remove', 'LoginInfo');
  return await window.flutter_inappwebview.callHandler('cache.get', 'LoginInfo');
})()
''',
      SourceScriptContext(
        source: _source(),
        loginInfo: const {'Email': 'saved@example.test'},
        loginInfoWriter: (value) => written = value,
        htmlBridge: true,
      ),
    );

    expect(result, '{}');
    expect(written, isEmpty);
  });

  test(
    'cancelled HTML promise is isolated and the next source still runs',
    () async {
      final evaluator = QuickJsSourceScriptEvaluator();
      final runtime = SourceRuntime(
        transport: _HtmlTransport(),
        scriptEvaluator: evaluator,
      );
      addTearDown(runtime.close);
      final cancellation = BookDownloadCancellation();
      final pending = runtime.search(
        _hangingSource().toRegisteredSource(enabled: true),
        'wait',
        cancellation: cancellation,
      );
      final recoveredFuture = runtime.search(
        _source().toRegisteredSource(enabled: true),
        '银河',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      cancellation.cancel();

      await expectLater(
        pending,
        throwsA(isA<BookDownloadCancelledException>()),
      );
      expect(evaluator.isDisposed, isFalse);

      final recovered = await recoveredFuture;
      expect(recovered.items.single.title, '银河书');
    },
  );

  for (final expectation in const [
    (count: 0, hasMore: false),
    (count: 10, hasMore: true),
    (count: 20, hasMore: true),
    (count: 21, hasMore: true),
  ]) {
    test(
      'HTML search keeps remote page of ${expectation.count} items',
      () async {
        final runtime = SourceRuntime(
          transport: _HtmlTransport(searchCount: expectation.count),
        );
        addTearDown(runtime.close);

        final page = await runtime.search(
          _source().toRegisteredSource(enabled: true),
          '银河',
          pageSize: 20,
        );

        expect(page.items, hasLength(expectation.count));
        expect(page.hasMore, expectation.hasMore);
      },
    );
  }
}

ReadingSourceConfig _hangingSource() => ReadingSourceConfig.fromJson({
  'bookSourceName': 'HTML hanging fixture',
  'bookSourceUrl': 'https://hanging-source.test',
  'html': '''
<script>
async function search() { return await new Promise(() => {}); }
async function info() { return '{}'; }
async function chapter() { return '[]'; }
async function content() { return 'never'; }
</script>
''',
});

ReadingSourceConfig _source() => ReadingSourceConfig.fromJson({
  'bookSourceName': 'HTML bridge fixture',
  'bookSourceUrl': 'https://html-source.test',
  'html': r'''
<!doctype html><html><body>
<script src="https://ignored.test/analytics.js"></script>
<script>
class FlutterJSBridge {
  async call(name, ...args) {
    return await window.flutter_inappwebview.callHandler(name, ...args);
  }
}
const bridge = new FlutterJSBridge();
const cache = {
  get: key => bridge.call('cache.get', key),
  set: (key, value) => bridge.call('cache.set', key, value)
};
const cookie = {
  get: url => bridge.call('cookie.get', url),
  set: (url, value) => bridge.call('cookie.set', url, value)
};
const http = {
  get: async url => {
    const response = await bridge.call('http', 'get', url, '', '{}', true, '');
    return JSON.parse(response.data);
  }
};
async function search(key, page, env) {
  await cache.set('last-query', key);
  await cookie.set('https://html-source.test', 'sid=bridge');
  const data = await http.get('/search?q=' + encodeURIComponent(key));
  return JSON.stringify(data);
}
async function info(bookurl) {
  const data = await http.get('/info?id=' + encodeURIComponent(bookurl));
  data.name += await cache.get('last-query') === '银河' ? '' : '-missing-cache';
  return JSON.stringify(data);
}
async function chapter(tocUrl, bookurl) {
  return JSON.stringify(await http.get('/catalog?toc=' + encodeURIComponent(tocUrl)));
}
async function content(chapterId, bookurl) {
  return (await http.get('/content?id=' + encodeURIComponent(chapterId))).content;
}
</script>
</body></html>
''',
});

class _HtmlTransport implements SourceTransport, SourceCookieTransport {
  _HtmlTransport({this.searchCount = 1});

  final int searchCount;
  final List<SourceRequestTemplate> requests = [];
  final Map<String, String> _cookies = {};
  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    requests.add(request);
    final body = switch (request.url.path) {
      '/search' => jsonEncode(
        List.generate(
          searchCount,
          (index) => {
            'bookUrl': '/book/${index + 1}',
            'name': index == 0 ? '银河书' : '银河书 $index',
            'author': '作者',
            'coverUrl': '/cover.jpg',
            'type': 0,
          },
        ),
      ),
      '/info' => jsonEncode({
        'bookUrl': '/book/1',
        'name': '银河书',
        'author': '作者',
        'intro': '@html:<p>简介</p>',
        'tocUrl': '{"book":1}',
        'type': 0,
      }),
      '/catalog' => jsonEncode([
        {'name': '第一章', 'chapterId': '{"chapter":1}', 'index': 0},
      ]),
      '/content' => jsonEncode({'content': '<p>正文</p>'}),
      _ => throw StateError('Unexpected HTML request ${request.url}'),
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
