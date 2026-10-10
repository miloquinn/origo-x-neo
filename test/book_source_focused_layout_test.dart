import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/book_sources/book_sources_page.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'third layout cycles and restores while unknown preferences fall back',
    () async {
      final controller = BookSourcesPageController();
      await controller.initialize();
      await controller.toggleLayout();
      expect(controller.layout.value, BookSourceDiscoverLayout.list);
      await controller.toggleLayout();
      expect(controller.layout.value, BookSourceDiscoverLayout.source);
      final restored = BookSourcesPageController();
      await restored.initialize();
      expect(restored.layout.value, BookSourceDiscoverLayout.source);
      await controller.toggleLayout();
      expect(controller.layout.value, BookSourceDiscoverLayout.standard);
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        BookSourcesPageController.preferenceKey,
        'future',
      );
      final fallback = BookSourcesPageController();
      await fallback.initialize();
      expect(fallback.layout.value, BookSourceDiscoverLayout.standard);
      controller.dispose();
      restored.dispose();
      fallback.dispose();
    },
  );

  testWidgets(
    'layout cycling immediately rebuilds source and standard controls',
    (tester) async {
      final layout = BookSourcesPageController();
      addTearDown(layout.dispose);
      await _openPage(tester, count: 2, layout: layout);
      expect(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
        findsOneWidget,
      );
      await layout.toggleLayout();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('bookSourceDiscoverScopeControl')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bookSourceOrganizationAll')),
        findsOneWidget,
      );
      await layout.toggleLayout();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceListLayoutDirectory')),
        findsOneWidget,
      );
      await layout.toggleLayout();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('bookSourceListLayoutDirectory')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'search switches one source and both pickers reach the panel edge',
    (tester) async {
      final client = await _openPage(tester, count: 80);
      expect(client.categorySources, ['source-000']);
      expect(
        find.byKey(const Key('bookSourceDiscoverScopeControl')),
        findsNothing,
      );
      expect(find.byKey(const Key('bookSourceOrganizationAll')), findsNothing);
      expect(find.text('源000 / 分类000'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
      );
      await tester.pumpAndSettle();
      final sourceList = find.byKey(const Key('bookSourceDiscoverySourceList'));
      _expectEdge(tester, sourceList);
      expect(
        find.byKey(const Key('bookSourceDiscoveryPick-source-079')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const Key('bookSourceDiscoverySourceSearch')),
        ' 源079 ',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceDiscoveryPick-source-000')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const Key('bookSourceDiscoveryPick-source-079')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassBottomSheetSurface), findsNothing);
      expect(client.categorySources, ['source-000', 'source-079']);
      expect(find.text('源079 / 分类000'), findsOneWidget);
      expect(find.text('源000 / 分类000'), findsNothing);

      await tester.tap(find.byKey(const Key('bookSourceCategoryPickerButton')));
      await tester.pumpAndSettle();
      final categoryList = find.byKey(const Key('bookSourceCategoryLazyList'));
      _expectEdge(tester, categoryList);
      final scrollable = find.descendant(
        of: categoryList,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('bookSourceCategory-source-079-category-059')),
        260,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      final last = find.byKey(
        const Key('bookSourceCategory-source-079-category-059'),
      );
      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(_panelRect(tester).bottom - 26),
      );
      await tester.tap(last);
      await tester.pumpAndSettle();
      expect(find.text('源079 / 分类059'), findsOneWidget);
      expect(
        find.byKey(
          const Key('bookSourceDiscoveryChannel-source-079-category-059'),
        ),
        findsOneWidget,
      );
      expect(client.browsed.last, ('source-079', 'category-059'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'narrow large text search stays usable with keyboard and dismissal',
    (tester) async {
      final client = await _openPage(
        tester,
        count: 2,
        width: 320,
        textScale: 1.6,
      );
      await tester.tap(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
      );
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      tester.view.padding = const FakeViewPadding(top: 47);
      await tester.enterText(
        find.byKey(const Key('bookSourceDiscoverySourceSearch')),
        'absent',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceDiscoverySourceList')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const Key('bookSourceDiscoverySourceSearch')),
        '源001',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('bookSourceDiscoveryPick-source-001')),
      );
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      await tester.pumpAndSettle();
      expect(client.categorySources.last, 'source-001');
      await tester.tap(
        find.byKey(const Key('bookSourceDiscoverySourceSelector')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(GlassBottomSheetSurface.dragHandleKey));
      await tester.pumpAndSettle();
      expect(find.text('源001 / 分类000'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'empty source library keeps a disabled selector and no requests',
    (tester) async {
      final client = await _openPage(tester, count: 0);
      expect(
        tester
            .widget<TextButton>(
              find.byKey(const Key('bookSourceDiscoverySourceSelector')),
            )
            .onPressed,
        isNull,
      );
      expect(client.categorySources, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}

Rect _panelRect(WidgetTester tester) => tester.getRect(
  find.byWidgetPredicate(
    (widget) => widget is GlassSurface && widget.role == GlassSurfaceRole.panel,
  ),
);

void _expectEdge(WidgetTester tester, Finder list) {
  expect(find.byType(GlassBottomSheetSurface), findsOneWidget);
  final panel = _panelRect(tester);
  expect(tester.getRect(list).bottom, panel.bottom);
  expect(tester.view.physicalSize.height - panel.bottom, 8);
  expect(panel.height, closeTo(tester.view.physicalSize.height * .55, 1));
}

Future<_Client> _openPage(
  WidgetTester tester, {
  required int count,
  double width = 390,
  double textScale = 1,
  BookSourcesPageController? layout,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.reset);
  final sources = List.generate(
    count,
    (index) => RegisteredBookSource(
      id: 'source-${index.toString().padLeft(3, '0')}',
      name: '源${index.toString().padLeft(3, '0')}',
      description: '',
      manifestUrl: Uri.parse('https://example.org/$index.json'),
      apiBaseUrl: Uri.parse('https://example.org/api/$index/'),
      protocolVersion: '1.0',
      languages: const ['zh-CN'],
      capabilities: const {'categories', 'browse'},
      enabled: true,
      addedAt: DateTime.utc(2026, 10, 10),
    ),
  );
  SharedPreferences.setMockInitialValues({
    BookSourcesPageController.preferenceKey: 'source',
    'origo_x_book_sources_v1': jsonEncode(
      sources.map((source) => source.toJson()).toList(),
    ),
  });
  final client = _Client();
  addTearDown(client.close);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: BookSourcesPage(
          client: client,
          registry: _Registry(sources),
          controller: layout,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return client;
}

class _Client extends BookSourceClient {
  final categorySources = <String>[];
  final browsed = <(String, String?)>[];

  @override
  Future<List<BookSourceCategory>> getCategories(
    RegisteredBookSource source, {
    void Function(List<BookSourceCategory>)? onCached,
  }) async {
    categorySources.add(source.id);
    return List.generate(
      60,
      (index) => BookSourceCategory(
        id: 'category-${index.toString().padLeft(3, '0')}',
        name: '分类${index.toString().padLeft(3, '0')}',
      ),
    );
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
    browsed.add((source.id, category));
    return BookSourceSearchPage(
      items: [
        BookSourceBook(
          id: '$category-book',
          title: '${source.name} / 分类${category?.split('-').last}',
          author: '测试作者',
          description: '验证书源与分类的选择结果',
          categories: const [],
        ),
      ],
      page: page,
      pageSize: pageSize,
      hasMore: false,
    );
  }
}

class _Registry extends BookSourceRegistry {
  _Registry(this.sources);
  final List<RegisteredBookSource> sources;
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<List<RegisteredBookSource>> loadRunnableInBackground() async =>
      sources;
}
