import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/pages/book_sources/controllers/book_sources_controller.dart';

void main() {
  test(
    'single-source layout preserves a valid source and prefers categories',
    () async {
      final first = _source('first');
      final second = _source('second');
      final gateway = _Gateway();
      final controller = BookSourcesController(
        gateway: gateway,
        registry: _Registry([
          Future.value([first, second]),
        ]),
      );
      addTearDown(controller.close);

      controller.setListLayout(true);
      await controller.load();
      await controller.changeSourceScope(second.id);
      controller.setSourceLayout(true);
      await _waitUntil(
        () =>
            controller.state.selectedCategory?.source.id == second.id &&
            !controller.state.loadingCategoryBooks,
      );

      expect(controller.sourceLayout, isTrue);
      expect(controller.state.listLayout, isFalse);
      expect(controller.state.selectedSourceId, second.id);
      expect(controller.state.section, BookSourcesSection.categories);
      expect(
        controller.state.caches[BookSourcesSection.categories]!.categories!.map(
          (category) => category.source.id,
        ),
        everyElement(second.id),
      );
      expect(gateway.categorySourceIds.last, second.id);
      expect(gateway.browseSourceIds.last, second.id);

      controller.setSourceLayout(false);
      expect(controller.sourceLayout, isFalse);
      expect(controller.state.selectedSourceId, second.id);
    },
  );

  test('single-source layout clears hidden organization filters', () async {
    final favorite = _source(
      'favorite',
    ).copyWith(isFavorite: true, groups: ['saved']);
    final other = _source('other');
    final controller = BookSourcesController(
      gateway: _Gateway(),
      registry: _Registry([
        Future.value([favorite, other]),
      ]),
    );
    addTearDown(controller.close);

    await controller.load();
    await controller.changeOrganizationScope(
      favoritesOnly: true,
      group: 'saved',
    );
    expect(controller.state.organizedDiscoverySources, [favorite]);

    controller.setSourceLayout(true);

    expect(controller.state.favoritesOnly, isFalse);
    expect(controller.state.selectedGroup, isNull);
    expect(controller.state.organizedDiscoverySources, [favorite, other]);
    await controller.changeSourceScope(other.id);
    expect(controller.state.selectedSourceId, other.id);
  });

  test(
    'leaving single-source layout lets an active section load finish',
    () async {
      final categories = Completer<List<BookSourceCategory>>();
      final source = _source('source');
      final controller = BookSourcesController(
        gateway: _Gateway(categoryResults: {source.id: categories.future}),
        registry: _Registry([
          Future.value([source]),
        ]),
      );
      addTearDown(controller.close);

      controller.setSourceLayout(true);
      final load = controller.load();
      await _waitUntil(
        () =>
            controller.state.caches[BookSourcesSection.categories]?.loading ==
            true,
      );
      controller.setSourceLayout(false);
      categories.complete([
        const BookSourceCategory(id: 'category', name: 'Category'),
      ]);
      await load;
      await _waitUntil(() => !controller.state.loadingCategoryBooks);

      expect(controller.sourceLayout, isFalse);
      expect(
        controller.state.caches[BookSourcesSection.categories]?.complete,
        isTrue,
      );
      expect(controller.state.selectedCategory?.source.id, source.id);
    },
  );

  test(
    'source removal reloads a valid source and ignores stale category work',
    () async {
      final staleCategories = Completer<List<BookSourceCategory>>();
      final a = _source('a');
      final b = _source('b');
      final gateway = _Gateway(categoryResults: {a.id: staleCategories.future});
      final controller = BookSourcesController(
        gateway: gateway,
        registry: _Registry([
          Future.value([a, b]),
          Future.value([b]),
          Future.value([b]),
        ]),
      );
      addTearDown(controller.close);

      controller.setSourceLayout(true);
      final initialLoad = controller.load();
      await _waitUntil(() => gateway.categorySourceIds.contains(a.id));
      await controller.refreshSourceMetadata();

      expect(controller.state.selectedSourceId, b.id);
      expect(controller.state.section, BookSourcesSection.categories);
      expect(
        controller.state.caches[BookSourcesSection.categories]!.categories!.map(
          (category) => category.source.id,
        ),
        everyElement(b.id),
      );

      staleCategories.complete([
        const BookSourceCategory(id: 'stale', name: 'Stale'),
      ]);
      await initialLoad;
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.selectedSourceId, b.id);
      expect(
        controller.state.caches[BookSourcesSection.categories]!.categories!.map(
          (category) => category.source.id,
        ),
        everyElement(b.id),
      );
      expect(controller.state.selectedCategory?.source.id, b.id);
    },
  );

  test(
    'organization metadata cannot leave single-source layout aggregated',
    () async {
      final a = _source('a').copyWith(isFavorite: true);
      final b = _source('b').copyWith(isFavorite: true);
      final gateway = _Gateway();
      final controller = BookSourcesController(
        gateway: gateway,
        registry: _Registry([
          Future.value([a, b]),
          Future.value([a, b.copyWith(isFavorite: false)]),
        ]),
      );
      addTearDown(controller.close);

      controller.setSourceLayout(true);
      await controller.load();
      await controller.changeOrganizationScope(favoritesOnly: true);
      await controller.changeSourceScope(b.id);
      await controller.refreshSourceMetadata();
      await _waitUntil(
        () =>
            controller.state.selectedCategory?.source.id == a.id &&
            !controller.state.loadingCategoryBooks,
      );

      expect(controller.sourceLayout, isTrue);
      expect(controller.state.selectedSourceId, a.id);
      expect(controller.state.scopedSourcesFor(controller.state.section), [a]);
      expect(
        controller.state.caches[BookSourcesSection.categories]!.categories!.map(
          (category) => category.source.id,
        ),
        everyElement(a.id),
      );
    },
  );

  test(
    'removed source menu snapshots cannot select a stale category',
    () async {
      final a = _source('a');
      final b = _source('b');
      final gateway = _Gateway();
      final controller = BookSourcesController(
        gateway: gateway,
        registry: _Registry([
          Future.value([a, b]),
          Future.value([b]),
          Future.value([b]),
        ]),
      );
      addTearDown(controller.close);

      controller.setSourceLayout(true);
      await controller.load();
      await _waitUntil(
        () =>
            controller.state.selectedCategory?.source.id == a.id &&
            !controller.state.loadingCategoryBooks,
      );
      final staleCategory = controller.state.selectedCategory!;

      await controller.refreshSourceMetadata();
      await _waitUntil(
        () =>
            controller.state.selectedCategory?.source.id == b.id &&
            !controller.state.loadingCategoryBooks,
      );
      final currentCategory = controller.state.selectedCategory;
      final browseCount = gateway.browseSourceIds.length;

      await controller.selectCategory(staleCategory);

      expect(controller.state.selectedSourceId, b.id);
      expect(controller.state.selectedCategory, same(currentCategory));
      expect(gateway.browseSourceIds, hasLength(browseCount));
    },
  );

  test(
    'single-source layout falls back for limited and empty sources',
    () async {
      final recommendedOnly = _source(
        'recommended',
        capabilities: const {'discover'},
      );
      final gateway = _Gateway();
      final controller = BookSourcesController(
        gateway: gateway,
        registry: _Registry([
          Future.value([recommendedOnly]),
        ]),
      );
      addTearDown(controller.close);

      controller.setSourceLayout(true);
      await controller.load();

      expect(controller.state.selectedSourceId, recommendedOnly.id);
      expect(controller.state.section, BookSourcesSection.recommended);
      expect(gateway.discoverySourceIds, [recommendedOnly.id]);

      final emptyController = BookSourcesController(
        gateway: _Gateway(),
        registry: _Registry([Future.value(const [])]),
      );
      addTearDown(emptyController.close);
      emptyController.setSourceLayout(true);
      await emptyController.load();

      expect(emptyController.state.selectedSourceId, isNull);
      expect(emptyController.state.availableSections, isEmpty);
      expect(
        emptyController.state.caches[BookSourcesSection.recommended]!.shelves,
        isEmpty,
      );
    },
  );
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for controller state');
}

class _Registry extends BookSourceRegistry {
  _Registry(this.loads);

  final List<Future<List<RegisteredBookSource>>> loads;
  var _index = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<String>> loadGroups() async => const [];

  @override
  Future<List<RegisteredBookSource>> loadRunnableInBackground() =>
      loads[_index++];
}

class _Gateway extends BookSourceClient {
  _Gateway({this.categoryResults = const {}});

  final Map<String, Future<List<BookSourceCategory>>> categoryResults;
  final List<String> categorySourceIds = [];
  final List<String> discoverySourceIds = [];
  final List<String> browseSourceIds = [];

  @override
  Future<BookSourceDiscoveryPage> getDiscovery(
    RegisteredBookSource source, {
    void Function(BookSourceDiscoveryPage)? onCached,
  }) async {
    discoverySourceIds.add(source.id);
    return BookSourceDiscoveryPage(
      sections: [
        BookSourceDiscoverySection(
          id: source.id,
          title: source.name,
          items: [_book(source.id)],
        ),
      ],
    );
  }

  @override
  Future<List<BookSourceCategory>> getCategories(
    RegisteredBookSource source, {
    void Function(List<BookSourceCategory>)? onCached,
  }) {
    categorySourceIds.add(source.id);
    return categoryResults[source.id] ??
        Future.value([
          BookSourceCategory(id: '${source.id}-category', name: source.name),
        ]);
  }

  @override
  Future<BookSourceSearchPage> browse(
    RegisteredBookSource source, {
    String? category,
    String sort = 'latest',
    int page = 1,
    int pageSize = 20,
    void Function(BookSourceSearchPage)? onCached,
  }) async {
    browseSourceIds.add(source.id);
    return BookSourceSearchPage(
      items: [_book('${source.id}-$page')],
      page: page,
      pageSize: 1,
      total: 1,
      hasMore: false,
    );
  }
}

RegisteredBookSource _source(
  String id, {
  Set<String> capabilities = const {'discover', 'categories', 'browse'},
}) => RegisteredBookSource(
  id: id,
  name: id,
  description: '',
  manifestUrl: Uri.parse('https://example.org/$id/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/$id/api/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: capabilities,
  enabled: true,
  addedAt: DateTime.utc(2026, 10, 10),
  sourceProtocol: BookSourceProtocolKind.orsp,
);

BookSourceBook _book(String id) => BookSourceBook(
  id: id,
  title: id,
  author: 'Author',
  description: '',
  categories: const [],
);
