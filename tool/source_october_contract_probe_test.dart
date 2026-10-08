// Opt-in probe: SOURCE_SAMPLE_PATHS='["/absolute/source.json", ...]' flutter test
// --no-pub tool/source_october_contract_probe_test.dart --reporter expanded
// Source exports remain private local inputs; all responses are synthetic.
import 'dart:convert';
import 'dart:io';

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
  final paths =
      jsonDecode(Platform.environment['SOURCE_SAMPLE_PATHS'] ?? '[]') as List;
  if (paths.isEmpty) throw ArgumentError('SOURCE_SAMPLE_PATHS is required.');
  for (final path in paths.cast<String>()) {
    final parsed = parseReadingSources(File(path).readAsStringSync());
    if (parsed.errors.isNotEmpty) {
      throw FormatException('Source import failed.');
    }
    for (final config in parsed.sources) {
      test('original rules with synthetic responses: ${config.name}', () async {
        // Explicit opt-in Flutter probe, outside the hermetic test directory.
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        final transport = _SampleTransport();
        final runtime = SourceRuntime(
          transport: transport,
          loginSessionStore: _MemoryStore(),
        );
        addTearDown(runtime.close);
        final source = config.toRegisteredSource(enabled: true);
        expect(
          source.capabilities,
          containsAll(['search', 'detail', 'catalog', 'content']),
        );
        final search = await runtime.search(source, '合成图书');
        final match = search.items.single;
        expect(match.title, '合成图书');
        final book = await runtime.getBook(
          source,
          match.id,
          sourceVariables: match.sourceVariables,
        );
        expect(book.title, '合成图书');
        expect(book.author, contains('合成作者'));
        expect(book.description, contains('合成简介'));
        expect(book.categories, contains('悬疑'));
        final chapters = await runtime.getChapters(
          source,
          book.id,
          sourceVariables: book.sourceVariables,
        );
        expect(chapters.single.title, '第一章');
        final content = await runtime.getChapterContent(
          source,
          bookId: book.id,
          chapterId: chapters.single.id,
          sourceVariables: book.sourceVariables,
        );
        expect(content.content, contains('合成正文第一段'));
        expect(content.content, contains('第二段必须保留'));
      });
    }
  }
}

class _SampleTransport implements SourceTransport {
  final paths = <String>[];
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
    paths.add(request.url.path);
    final path = request.url.path;
    late Object response;
    if (path.endsWith('/search.php')) {
      final family = path.contains('/qimao/') ? 'qimao' : 'shuqi';
      response = {
        'data': {
          'books': [
            {
              'name': '合成图书',
              'author': '合成作者',
              'intro': '合成简介',
              'mmfl': '悬疑',
              'src': 'https://fixture.test/cover.jpg',
              'url': 'https://fixture.test/$family/book?qm_id=42',
            },
          ],
        },
      };
    } else if (path.endsWith('/book')) {
      response = {
        'data': {
          'lists': [
            {
              'title': '第一章',
              'url': 'https://fixture.test/content?chapterId=42-c1',
            },
          ],
        },
      };
    } else if (path == '/content') {
      response = {
        'data': {'content': '<p>合成正文第一段</p><p>第二段必须保留</p>'},
      };
    } else if (path.endsWith('/search/page/v1/')) {
      expect(request.method, SourceRequestMethod.post);
      expect(jsonDecode(request.body!)['query'], '合成图书');
      expect(
        request.headers.keys.map((key) => key.toLowerCase()),
        containsAll(['x-argus', 'x-ladon', 'x-khronos', 'x-ss-stub']),
      );
      response = {
        'data': {
          'search_data': [
            {
              'books': [
                {
                  'book_name': '合成图书',
                  'book_id': '42',
                  'author': '合成作者',
                  'serial_count': 1,
                  'thumb_url': 'https://fixture.test/cover.jpg',
                  'abstract': '合成简介',
                  'tags': '悬疑',
                },
              ],
            },
          ],
        },
      };
    } else if (path.endsWith('/multi-detail/v/')) {
      response = {
        'data': [
          {
            'book_name': '合成图书',
            'book_id': '42',
            'author': '合成作者',
            'thumb_url': 'https://fixture.test/cover.jpg',
            'original_book_name': '合成图书',
            'abstract': '合成简介',
            'category': '悬疑',
            'score': '9.5',
            'creation_status': 1,
            'book_search_visible': true,
          },
        ],
      };
    } else if (path.endsWith('/directory/detail')) {
      expect(request.url.queryParameters['bookId'], '42');
      response = {
        'data': {
          'chapterListWithVolume': [
            [
              {'title': '第一章', 'itemId': '12345678'},
            ],
          ],
        },
      };
    } else if (path == '/list') {
      response = {};
    } else if (path == '/i12345678/info/v2/') {
      response = {
        'data': {'content': '<p>合成正文第一段</p><p>第二段必须保留</p>'},
      };
    } else if (path.endsWith('/qmdlsj.php')) {
      response = {
        'data': {
          'chapters': [
            {'bubbles': []},
          ],
        },
      };
    } else {
      throw StateError('Unexpected synthetic request path: $path');
    }
    return SourceResponse(body: jsonEncode(response), finalUri: request.url);
  }
}

class _MemoryStore implements SourceLoginSessionStore {
  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      const SourceLoginSession();
  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {}
  @override
  Future<void> clear(String sourceId) async {}
}
