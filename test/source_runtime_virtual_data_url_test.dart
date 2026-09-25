import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('typed local book and chapter URLs keep their options in JS baseUrl', () async {
    final source = ReadingSourceConfig.fromJson(const {
      'bookSourceName': 'Virtual URL contract',
      'bookSourceUrl': 'https://api.test',
      'bookSourceType': 0,
      'searchUrl': 'https://api.test/search?q={{key}}',
      'ruleSearch': {
        'bookList': 'data[*]',
        'name': 'title',
        'bookUrl':
            'id\n@js:`data:;base64,\${java.base64Encode(result)},{"type":"novel"}`',
      },
      'ruleBookInfo': {
        'init':
            '@js:JSON.stringify({name:"Test book",book_id:java.hexDecodeToString(result),type:JSON.parse(baseUrl.slice(baseUrl.indexOf("{"))).type})',
        'name': 'name',
        'tocUrl':
            'book_id\n@js:`data:;base64,\${java.base64Encode(result)},{"type":"\${java.getString("type")}"}`',
      },
      'ruleToc': {
        'chapterList':
            '@js:[{title:"Chapter one",url:`data:;base64,\${java.base64Encode("c1")},{"type":"\${JSON.parse(baseUrl.slice(baseUrl.indexOf("{"))).type}","bookId":"\${java.hexDecodeToString(result)}"}`}]',
        'chapterName': 'title',
        'chapterUrl': 'url',
      },
      'ruleContent': {
        'content':
            '@js:`\${JSON.parse(baseUrl.slice(baseUrl.indexOf("{"))).type}:\${JSON.parse(baseUrl.slice(baseUrl.indexOf("{"))).bookId}:\${java.hexDecodeToString(result)}`',
      },
    }).toRegisteredSource();
    final transport = _VirtualTransport();
    final runtime = SourceRuntime(
      transport: transport,
      loginSessionStore: _MemorySessionStore(),
    );
    addTearDown(runtime.close);

    final result = await runtime.search(source, 'test');
    final book = await runtime.getBook(source, result.items.single.id);
    final chapters = await runtime.getChapters(source, book.id);
    final content = await runtime.getChapterContent(
      source,
      bookId: book.id,
      chapterId: chapters.single.id,
    );

    expect(book.title, 'Test book');
    expect(chapters.single.title, 'Chapter one');
    expect(content.content, 'novel:42:c1');
    expect(transport.networkUrls, ['https://api.test/search?q=test']);
  });
}

class _VirtualTransport implements SourceTransport {
  final networkUrls = <String>[];

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    if (request.syntheticBody != null) {
      return SourceResponse(
        body: request.syntheticBody!,
        finalUri: request.url,
      );
    }
    networkUrls.add(request.url.toString());
    return SourceResponse(
      body: '{"data":[{"id":"42","title":"Test book"}]}',
      finalUri: request.url,
    );
  }
}

class _MemorySessionStore implements SourceLoginSessionStore {
  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {}

  @override
  Future<void> clear(String sourceId) async {}
}
