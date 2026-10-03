import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/pages/book_sources/controllers/book_sources_state.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';

const _runBenchmark = bool.fromEnvironment('BOOK_SOURCES_STATE_BENCHMARK');

void main() {
  test('constructor defensively freezes every exposed collection', () {
    final source = _source('source');
    final category = _category(source, 0);
    final sourcedBook = _book(source);
    final sources = <RegisteredBookSource>[source];
    final sectionSources = <BookSourcesSection, List<RegisteredBookSource>>{
      BookSourcesSection.categories: <RegisteredBookSource>[source],
    };
    final discoverySources = <RegisteredBookSource>[source];
    final caches = <BookSourcesSection, BookSourcesSectionCache>{
      BookSourcesSection.categories: BookSourcesSectionCache.categories([
        category,
      ]),
    };
    final categoryBooks = <SourcedBook>[sourcedBook];
    final channels = <String, List<SourcedBookCategory>>{
      source.id: <SourcedBookCategory>[category],
    };
    final loadingSources = <String>{source.id};
    final errors = <String, Object>{source.id: StateError('failed')};

    final state = BookSourcesState(
      sources: sources,
      sectionSources: sectionSources,
      discoverySources: discoverySources,
      caches: caches,
      categoryBooks: categoryBooks,
      listChannelsBySource: channels,
      loadingListChannelSources: loadingSources,
      listChannelErrors: errors,
    );

    sources.clear();
    sectionSources[BookSourcesSection.categories]!.clear();
    sectionSources.clear();
    discoverySources.clear();
    caches.clear();
    categoryBooks.clear();
    channels[source.id]!.clear();
    channels.clear();
    loadingSources.clear();
    errors.clear();

    expect(state.sources, [source]);
    expect(state.sectionSources[BookSourcesSection.categories], [source]);
    expect(state.discoverySources, [source]);
    expect(state.caches, hasLength(1));
    expect(state.categoryBooks, [sourcedBook]);
    expect(state.listChannelsBySource[source.id], [category]);
    expect(state.loadingListChannelSources, {source.id});
    expect(state.listChannelErrors, hasLength(1));

    expect(() => state.sources.clear(), throwsUnsupportedError);
    expect(() => state.sectionSources.clear(), throwsUnsupportedError);
    expect(
      () => state.sectionSources[BookSourcesSection.categories]!.clear(),
      throwsUnsupportedError,
    );
    expect(() => state.discoverySources.clear(), throwsUnsupportedError);
    expect(() => state.caches.clear(), throwsUnsupportedError);
    expect(() => state.categoryBooks.clear(), throwsUnsupportedError);
    expect(() => state.listChannelsBySource.clear(), throwsUnsupportedError);
    expect(
      () => state.listChannelsBySource[source.id]!.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => state.loadingListChannelSources.clear(),
      throwsUnsupportedError,
    );
    expect(() => state.listChannelErrors.clear(), throwsUnsupportedError);
  });

  test('query updates reuse untouched giant frozen collections', () {
    final state = _largeState(sourceCount: 2000, channelsPerSource: 50);

    final updated = state.copyWith(listSourceQuery: 'science');

    expect(updated.sources, same(state.sources));
    expect(updated.sectionSources, same(state.sectionSources));
    expect(updated.discoverySources, same(state.discoverySources));
    expect(updated.caches, same(state.caches));
    expect(updated.categoryBooks, same(state.categoryBooks));
    expect(updated.listChannelsBySource, same(state.listChannelsBySource));
    expect(
      updated.loadingListChannelSources,
      same(state.loadingListChannelSources),
    );
    expect(updated.listChannelErrors, same(state.listChannelErrors));
  });

  test('replacing one channel list reuses untouched frozen lists', () {
    final sourceA = _source('a');
    final sourceB = _source('b');
    final state = BookSourcesState(
      listChannelsBySource: {
        sourceA.id: [_category(sourceA, 0)],
        sourceB.id: [_category(sourceB, 0)],
      },
    );
    final replacement = <SourcedBookCategory>[
      _category(sourceA, 1),
      _category(sourceA, 2),
    ];

    final updated = state.copyWith(
      listChannelsBySource: {
        ...state.listChannelsBySource,
        sourceA.id: replacement,
      },
    );

    expect(
      updated.listChannelsBySource,
      isNot(same(state.listChannelsBySource)),
    );
    expect(updated.listChannelsBySource[sourceA.id], isNot(same(replacement)));
    expect(
      updated.listChannelsBySource[sourceB.id],
      same(state.listChannelsBySource[sourceB.id]),
    );
    replacement.clear();
    expect(updated.listChannelsBySource[sourceA.id], hasLength(2));
    expect(
      () => updated.listChannelsBySource[sourceA.id]!.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'benchmark 200 query-only updates on 2000 sources x 50 channels',
    () {
      var state = _largeState(sourceCount: 2000, channelsPerSource: 50);
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < 200; index++) {
        state = state.copyWith(listSourceQuery: 'query-$index');
      }
      stopwatch.stop();
      // Opt-in diagnostic only. Performance is protected by identity tests,
      // not by a machine-dependent timing threshold.
      // ignore: avoid_print
      print(
        'BOOK_SOURCES_STATE_BENCHMARK_MS=${stopwatch.elapsedMicroseconds / 1000}',
      );
      expect(state.listSourceQuery, 'query-199');
    },
    skip: !_runBenchmark,
  );
}

BookSourcesState _largeState({
  required int sourceCount,
  required int channelsPerSource,
}) {
  final sources = List.generate(
    sourceCount,
    (index) => _source('source-$index'),
    growable: false,
  );
  return BookSourcesState(
    sources: sources,
    sectionSources: {BookSourcesSection.categories: sources},
    discoverySources: sources,
    listChannelsBySource: {
      for (final source in sources)
        source.id: List.generate(
          channelsPerSource,
          (index) => _category(source, index),
          growable: false,
        ),
    },
  );
}

RegisteredBookSource _source(String id) => RegisteredBookSource(
  id: id,
  name: 'Source $id',
  description: '',
  manifestUrl: Uri.parse('https://example.org/$id/manifest.json'),
  apiBaseUrl: Uri.parse('https://example.org/$id/'),
  protocolVersion: '1.1',
  languages: const ['en'],
  capabilities: const {'categories'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);

SourcedBookCategory _category(RegisteredBookSource source, int index) =>
    SourcedBookCategory(
      source: source,
      id: 'category-$index',
      name: 'Category $index',
    );

SourcedBook _book(RegisteredBookSource source) => SourcedBook(
  source: source,
  book: const BookSourceBook(
    id: 'book',
    title: 'Book',
    author: 'Author',
    description: '',
    categories: [],
  ),
);
