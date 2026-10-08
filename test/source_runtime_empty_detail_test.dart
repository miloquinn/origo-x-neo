import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('search metadata and catalog enable details with empty info rules', () {
    final source = ReadingSourceConfig.fromJson(_source());
    expect(source.runnableCapabilities, contains('detail'));
    expect(source.toRegisteredSource().capabilities, contains('detail'));

    final missingTitle = _source()..['ruleSearch'] = {'bookList': 'books[*]'};
    expect(
      ReadingSourceConfig.fromJson(missingTitle).runnableCapabilities,
      isNot(contains('detail')),
    );
  });

  test(
    'empty details preserve search metadata through catalog and content',
    () async {
      final source = ReadingSourceConfig.fromJson(
        _source(),
      ).toRegisteredSource();
      final transport = _FixtureTransport();
      final runtime = SourceRuntime(
        transport: transport,
        loginSessionStore: _MemorySessionStore(),
      );
      addTearDown(runtime.close);

      final search = await runtime.search(source, 'test');
      final initial = search.items.single;
      final book = await runtime.getBook(source, initial.id);
      expect(book.title, initial.title);
      expect(book.author, initial.author);
      expect(book.description, initial.description);
      expect(book.coverUrl, initial.coverUrl);
      expect(book.coverHeaders, initial.coverHeaders);
      expect(book.coverHeaders['X-Cover'], 'fixture');
      expect(book.categories, ['Fantasy', 'Ongoing']);

      final chapters = await runtime.getChapters(source, book.id);
      final content = await runtime.getChapterContent(
        source,
        bookId: book.id,
        chapterId: chapters.single.id,
      );
      expect(content.content, 'Search author:Chapter body');
      expect(transport.networkPaths, ['/search', '/book/1']);
    },
  );

  test(
    'detail rules override metadata and receive text before kind suffix JS',
    () async {
      final raw = _source()
        ..['ruleBookInfo'] = {
          'author': 'detail.author',
          'intro': 'detail.intro',
          'coverUrl': 'detail.cover',
          'kind':
              '{{\$.detail.kind[0]}}\n{{\$.detail.kind[1]}}\n@js:result.replace(/Ongoing/g,"Complete")',
        };
      final runtime = SourceRuntime(
        transport: _FixtureTransport(),
        loginSessionStore: _MemorySessionStore(),
      );
      addTearDown(runtime.close);
      final source = ReadingSourceConfig.fromJson(raw).toRegisteredSource();
      final search = await runtime.search(source, 'test');
      final book = await runtime.getBook(source, search.items.single.id);
      expect(book.author, 'Detail author');
      expect(book.description, 'Detail description');
      expect(book.coverUrl, Uri.parse('https://api.test/detail.jpg'));
      expect(book.categories, ['Adventure', 'Complete']);
    },
  );

  test('kind selector lists retain arrays before suffix JavaScript', () async {
    final raw = _source()
      ..['ruleBookInfo'] = {
        'kind':
            'detail.kind[*]\n@js:result.filter(value => value !== "Ongoing")',
      };
    final runtime = SourceRuntime(
      transport: _FixtureTransport(),
      loginSessionStore: _MemorySessionStore(),
    );
    addTearDown(runtime.close);
    final source = ReadingSourceConfig.fromJson(raw).toRegisteredSource();
    final search = await runtime.search(source, 'test');
    final book = await runtime.getBook(source, search.items.single.id);
    expect(book.categories, ['Adventure']);
  });
}

Map<String, dynamic> _source() => {
  'bookSourceName': 'Empty detail fixture',
  'bookSourceUrl': 'https://api.test',
  'searchUrl': '/search',
  'ruleSearch': {
    'bookList': 'books[*]',
    'name': 'title',
    'bookUrl': 'url',
    'author': 'author',
    'intro': 'intro',
    'coverUrl': 'cover',
    'kind': 'kind[*]',
  },
  'ruleBookInfo': <String, dynamic>{},
  'ruleToc': {
    'chapterList': 'chapters[*]',
    'chapterName': 'title',
    'chapterUrl': 'url',
  },
  'ruleContent': {
    'content': '@js:book.author + ":" + java.hexDecodeToString(result)',
  },
};

class _FixtureTransport implements SourceTransport {
  final networkPaths = <String>[];

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
    networkPaths.add(request.url.path);
    final body = request.url.path == '/search'
        ? {
            'books': [
              {
                'title': 'Search title',
                'url': '/book/1',
                'author': 'Search author',
                'intro': 'Search description',
                'cover': '/cover.jpg,{"headers":{"X-Cover":"fixture"}}',
                'kind': ['Fantasy', 'Ongoing'],
              },
            ],
          }
        : {
            'detail': {
              'author': 'Detail author',
              'intro': 'Detail description',
              'cover': '/detail.jpg',
              'kind': ['Adventure', 'Ongoing'],
            },
            'chapters': [
              {
                'title': 'Chapter one',
                'url':
                    'data:;base64,${base64Encode(utf8.encode('Chapter body'))},{"type":"novel"}',
              },
            ],
          };
    return SourceResponse(body: jsonEncode(body), finalUri: request.url);
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
