import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_runtime_requests.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('typed URL payloads stay local while untyped URL wrappers fetch', () {
    const wrapped = 'data:;base64,aHR0cHM6Ly9hcGkudGVzdC9jb250ZW50';
    expect(decodeSourceDataTarget(wrapped), 'https://api.test/content');
    expect(decodeSourceDataTarget('$wrapped,{"type":"novel"}'), isNull);
    expect(
      decodeSourceDataTarget('$wrapped,{"type":""}'),
      'https://api.test/content,{"type":""}',
    );
    expect(
      decodeSourceDataTarget('$wrapped,{"headers":{"X-Test":"fixture"}}'),
      'https://api.test/content,{"headers":{"X-Test":"fixture"}}',
    );
  });

  test('untyped IDs and bytes are local payloads, including an empty type', () {
    for (final options in ['', ',{"type":""}', ',{"bookId":"42"}']) {
      final target = 'data:;base64,NDI=$options';
      final request = SourceRequestTemplate.parse(target, baseUri: Uri());
      expect(request.syntheticBody, '3432');
      expect(decodeSourceDataTarget(target), isNull);
    }
    expect(
      SourceRequestTemplate.parse(
        'data:text/plain,%E4%B9%A6',
        baseUri: Uri(),
      ).syntheticBody,
      'e4b9a6',
    );
    expect(
      SourceRequestTemplate.parse(
        'data:;base64,/w==',
        baseUri: Uri(),
      ).syntheticBody,
      'ff',
    );
  });

  test('data JSON payload delimiters stay distinct from trailing options', () {
    for (final payload in [
      '{"id":42}',
      '[{"id":42},{"id":43}]',
      '{"note":"literal,{options}","data":[{"id":42},{"id":43}]}',
    ]) {
      for (final options in ['', ',{"type":"","bookId":"42"}']) {
        final request = SourceRequestTemplate.parse(
          'data:application/json,$payload$options',
          baseUri: Uri(),
        );
        expect(
          request.syntheticBody,
          utf8
              .encode(payload)
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(),
        );
      }
    }
    const wrapped = 'data:;base64,aHR0cHM6Ly9hcGkudGVzdC9jb250ZW50';
    const options =
        ',{"headers":{"X-Test":"value,{"},"body":[{"id":1},{"id":2}]}';
    expect(
      decodeSourceDataTarget('$wrapped$options'),
      'https://api.test/content$options',
    );
  });

  for (final type in ['novel', '']) {
    test('local book/chapter options survive the full chain (type=$type)', () async {
      final source = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Virtual URL contract',
        'bookSourceUrl': 'https://api.test',
        'bookSourceType': 0,
        'searchUrl': 'https://api.test/search?q={{key}}',
        'ruleSearch': {
          'bookList': 'data[*]',
          'name': 'title',
          'bookUrl':
              'id\n@js:`data:;base64,\${java.base64Encode(result)},{"type":"$type"}`',
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
      expect(content.content, '$type:42:c1');
      expect(transport.networkUrls, ['https://api.test/search?q=test']);
    });
  }
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
