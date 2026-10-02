// Opt-in contract probe for a user-supplied Wenku-compatible source export:
// SOURCE_WENKU_PATH=/absolute/wenku.json flutter test --no-pub \
//   tool/source_wenku_contract_probe_test.dart --reporter expanded
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
  final path = Platform.environment['SOURCE_WENKU_PATH'];
  if (path == null || path.trim().isEmpty) {
    throw ArgumentError('SOURCE_WENKU_PATH must point to the source export.');
  }
  final imported = parseReadingSources(File(path).readAsStringSync());
  if (imported.errors.isNotEmpty || imported.sources.length != 1) {
    throw FormatException(
      'Expected one valid source: errors=${imported.errors.length}, '
      'sources=${imported.sources.length}.',
    );
  }

  test('original source completes the synthetic reading chain', () async {
    final config = imported.sources.single;
    final transport = _WenkuContractTransport();
    final runtime = SourceRuntime(
      transport: transport,
      loginSessionStore: _MemorySessionStore(),
    );
    addTearDown(runtime.close);
    final source = config.toRegisteredSource(enabled: true);

    final search = await runtime.search(source, '无职转生');
    expect(search.items, isNotEmpty);
    final match = search.items.firstWhere((book) => book.title == '无职转生');
    expect(match.author, '测试作者');
    expect(match.categories, containsAll(['奇幻', '冒险', '连载']));

    final book = await runtime.getBook(
      source,
      match.id,
      sourceVariables: match.sourceVariables,
    );
    expect(book.title, '无职转生');
    expect(book.author, '测试作者');
    expect(book.categories, containsAll(['奇幻', '冒险']));
    expect(book.latestChapter, '第二章');

    final chapters = await runtime.getChapters(
      source,
      book.id,
      sourceVariables: book.sourceVariables,
    );
    expect(chapters.map((chapter) => chapter.title), ['第一章', '第二章']);
    expect(
      chapters.map((chapter) => chapter.title),
      isNot(contains('第一卷')),
      reason: 'the source isVolume rule must filter volume rows',
    );

    final content = await runtime.getChapterContent(
      source,
      bookId: book.id,
      chapterId: chapters.first.id,
      sourceVariables: book.sourceVariables,
    );
    expect(content.content, contains('合成正文第一段'));
    expect(content.content, isNot(contains('本文来自')));

    expect(
      transport.requests
          .where((request) => request.url.path.endsWith('search.php'))
          .map((request) => request.url.toString()),
      containsAll([
        '${config.url}/modules/article/search.php?searchtype=articlename&searchkey=%CE%DE%D6%B0%D7%AA%C9%FA&page=1',
        '${config.url}/modules/article/search.php?searchtype=author&searchkey=%CE%DE%D6%B0%D7%AA%C9%FA&page=1',
      ]),
    );
    expect(
      transport.requests
          .where((request) => request.url.path.endsWith('search.php'))
          .every((request) => request.charset == 'gbk'),
      isTrue,
    );
  });
}

class _WenkuContractTransport implements SourceTransport {
  final requests = <SourceRequestTemplate>[];

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    requests.add(request);
    final path = request.url.path;
    final body = switch (path) {
      '/modules/article/search.php' => _searchHtml,
      '/book/1.htm' => _detailHtml,
      '/book/1/toc.htm' => _catalogHtml,
      '/book/1/1.htm' => _contentHtml,
      '/book/1/2.htm' => _contentHtml,
      _ => throw StateError('Missing synthetic response for ${request.url}'),
    };
    return SourceResponse(body: body, finalUri: request.url);
  }
}

const _searchHtml = '''
<div id="content"><table><tbody><tr><td>
  <div class="book-item">
    <div class="cover"><img src="/cover.jpg"></div>
    <div class="meta"><b><a href="/book/1.htm" title="无职转生"></a></b>
      <p>小说作者:测试作者/分类:轻小说</p>
      <p>更新:今天</p><p><span>奇幻 冒险</span></p>
      <p>作品简介: 合成简介</p><p>连载</p>
    </div>
  </div>
</td></tr></tbody></table></div>
''';

const _detailHtml = '''
<div id="content">
  <div><i></i><i></i><i></i><div><div><div><div><img src="/cover.jpg"></div><div><span>作品Tags：奇幻 冒险</span></div></div></div></div></div>
  <table><tbody>
    <tr><td><table><tbody><tr><td><b>无职转生</b></td></tr></tbody></table></td></tr>
    <tr><td>状态</td><td>小说作者：测试作者</td><td></td><td></td><td>全文长度：12345字</td></tr>
  </tbody></table>
  <table><tbody><tr><td>章节</td><td><span>一</span><span>二</span><span>三</span><span><a>第二章</a></span></td></tr></tbody></table>
  <div><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>合成简介</span></div>
  <a href="/book/1/toc.htm">小说目录</a>
</div>
''';

const _catalogHtml = '''
<table class="css"><tbody><tr>
  <td>第一卷</td>
  <td><a href="/book/1/1.htm">第一章</a></td>
  <td><a href="/book/1/2.htm">第二章</a></td>
</tr></tbody></table>
''';

const _contentHtml = '''
<div id="content"><p>合成正文第一段。</p><p>本文来自测试水印</p></div>
''';

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
