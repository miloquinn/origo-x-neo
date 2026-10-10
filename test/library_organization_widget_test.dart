@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/pages/library/library_reorderable_item.dart';
import 'package:xxread/services/core/app_settings_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory support;
  const paths = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() async {
    support = await Directory.systemTemp.createTemp('library_organization_');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      paths,
      (_) async => support.path,
    );
  });
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(paths, null);
    await support.delete(recursive: true);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final layout in LibraryLayoutMode.values) {
    testWidgets(
      '${layout.name}: drags a book ahead of a folder and persists complete siblings',
      (tester) async {
        final fixture = _Fixture();
        await fixture.mount(tester, layout: layout);
        await fixture.startReordering(tester);
        expect(fixture.controller.reordering.value, isTrue);
        await _drag(tester, 'book:1', 'folder:fiction');
        expect(fixture.saved.single, [
          (bookId: 1, folderId: null),
          (bookId: null, folderId: 'fiction'),
          (bookId: 2, folderId: null),
        ]);
        expect(_keys(tester), ['book:1', 'folder:fiction', 'book:2']);
        await tester.tap(find.byKey(const ValueKey('library-reorder-done')));
        await tester.pump();
        expect(fixture.controller.reordering.value, isFalse);
        await fixture.unmount(tester);
      },
    );
  }

  testWidgets(
    'reordering clears search so hidden siblings retain explicit ranks',
    (tester) async {
      final fixture = _Fixture();
      await fixture.mount(tester);
      fixture.controller.toggleSearch();
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Beta'), findsNothing);
      await fixture.startReordering(tester);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Beta'), findsWidgets);
      await _drag(tester, 'book:1', 'book:2');
      expect(fixture.saved.single.length, 3);
      await fixture.unmount(tester);
    },
  );

  testWidgets(
    'stationary edge drag resolves the visible target after recycling',
    (tester) async {
      final fixture = _Fixture()
        ..folders = []
        ..books = List.generate(
          60,
          (index) => Book(
            id: index + 1,
            title: 'Book ${index + 1}',
            filePath: '/book-$index.epub',
            format: 'EPUB',
            importDate: DateTime.utc(
              2026,
              10,
              10,
            ).subtract(Duration(days: index)),
          ),
        );
      await fixture.mount(tester, size: const Size(412, 600));
      await fixture.startReordering(tester);
      final source = find.byKey(const ValueKey('library-drag-book:1'));
      final destination = Offset(tester.getCenter(source).dx, 572);
      final gesture = await tester.startGesture(tester.getCenter(source));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(destination);
      for (var i = 0; i < 220; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        source,
        findsNothing,
        reason: 'source must have left the sliver cache',
      );
      String? target;
      for (var attempt = 0; attempt < 30 && target == null; attempt++) {
        for (final element in find.byType(LibraryReorderableItem).evaluate()) {
          if (tester
              .getRect(find.byWidget(element.widget))
              .contains(destination)) {
            target = (element.widget as LibraryReorderableItem).entry.key;
            break;
          }
        }
        if (target == null) await tester.pump(const Duration(milliseconds: 16));
      }
      expect(target, isNotNull);
      final targetId = int.parse(target!.split(':').last);
      expect(targetId, greaterThan(6));
      await gesture.up();
      await tester.pumpAndSettle();
      final ids = fixture.saved.single.map((entry) => entry.bookId).toList();
      final expected = List.generate(60, (index) => index + 1);
      expected.insert(targetId - 1, expected.removeAt(0));
      expect(ids, expected);
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('library-cover-grid')),
      );
      final stopped = grid.controller!.offset;
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        grid.controller!.offset,
        stopped,
        reason: 'release stops auto-scroll',
      );
      await fixture.unmount(tester);
    },
  );

  testWidgets('failed save leaves order intact and exits with system back', (
    tester,
  ) async {
    final fixture = _Fixture(failSave: true);
    await fixture.mount(tester);
    await fixture.startReordering(tester);
    await _drag(tester, 'book:1', 'folder:fiction');
    expect(_keys(tester), ['folder:fiction', 'book:1', 'book:2']);
    expect(find.text('无法保存书库顺序，请重试'), findsWidgets);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fixture.controller.reordering.value, isFalse);
    await fixture.unmount(tester);
  });

  testWidgets('sort menu changes order without erasing manual positions', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester);
    await fixture.startReordering(tester);
    await _drag(tester, 'book:1', 'folder:fiction');
    fixture.controller.finishReordering();
    await tester.pump();
    unawaited(fixture.controller.showOrganizationMenu());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-sort-progress')));
    await tester.pumpAndSettle();
    expect(_keys(tester), ['folder:fiction', 'book:2', 'book:1']);
    unawaited(fixture.controller.showOrganizationMenu());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-sort-manual')));
    await tester.pumpAndSettle();
    expect(_keys(tester), ['book:1', 'folder:fiction', 'book:2']);
    expect(fixture.saved.length, 1);
    await fixture.unmount(tester);
  });

  testWidgets('organization sheet and drag mode fit 320px with large text', (
    tester,
  ) async {
    final fixture = _Fixture();
    await fixture.mount(tester, size: const Size(320, 720), textScale: 1.3);
    await fixture.startReordering(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('library-reorder-done')), findsOneWidget);
    await fixture.unmount(tester);
  });
}

List<String> _keys(WidgetTester tester) =>
    tester
        .widgetList<KeyedSubtree>(find.byType(KeyedSubtree))
        .map((widget) => widget.key)
        .whereType<ValueKey<String>>()
        .map((key) => key.value)
        .where((key) => key.startsWith('library-entry-'))
        .map((key) => key.substring('library-entry-'.length))
        .toList()
      ..addAll(
        tester
            .widgetList<LibraryReorderableItem>(
              find.byType(LibraryReorderableItem),
            )
            .map((widget) => widget.entry.key),
      );

Future<void> _drag(WidgetTester tester, String from, String to) async {
  final source = find.byKey(ValueKey('library-drag-$from'));
  final target = find.byKey(ValueKey('library-drag-$to'));
  final destination = tester.getCenter(target);
  final gesture = await tester.startGesture(tester.getCenter(source));
  await tester.pump(const Duration(milliseconds: 600));
  await gesture.moveTo(destination);
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}

class _Fixture {
  _Fixture({this.failSave = false});
  final bool failSave;
  final controller = LibraryPageController();
  late AppSettingsNotifier settings;
  final saved = <List<({int? bookId, String? folderId})>>[];
  List<Book> books = [
    Book(
      id: 1,
      title: 'Alpha',
      filePath: '/alpha.epub',
      format: 'EPUB',
      importDate: DateTime.utc(2026, 10, 10),
      readingProgress: .2,
    ),
    Book(
      id: 2,
      title: 'Beta',
      filePath: '/beta.epub',
      format: 'EPUB',
      importDate: DateTime.utc(2026, 10, 9),
      readingProgress: .8,
    ),
  ];
  List<ShelfFolder> folders = [
    ShelfFolder(
      id: 'fiction',
      name: 'Fiction',
      parentId: null,
      createdAt: DateTime.utc(2026, 10, 8),
    ),
  ];

  Future<void> mount(
    WidgetTester tester, {
    LibraryLayoutMode layout = LibraryLayoutMode.grid,
    Size size = const Size(412, 915),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.runAsync(() async {
      settings = AppSettingsNotifier();
      for (var i = 0; i < 100 && !settings.isInitialized; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await settings.setLibraryLayoutMode(layout);
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: LibraryPage(
            controller: controller,
            booksLoader: () async => books,
            foldersLoader: () async => folders,
            reorderSaver: (parent, entries) async {
              if (failSave) throw StateError('write failed');
              saved.add(entries);
              final ranks = {
                for (var i = 0; i < entries.length; i++) entries[i]: i,
              };
              books = books
                  .map(
                    (book) => book.copyWith(
                      shelfSortIndex: ranks[(bookId: book.id, folderId: null)],
                    ),
                  )
                  .toList();
              folders = folders
                  .map(
                    (folder) => ShelfFolder(
                      id: folder.id,
                      name: folder.name,
                      parentId: folder.parentId,
                      createdAt: folder.createdAt,
                      sortIndex: ranks[(bookId: null, folderId: folder.id)],
                    ),
                  )
                  .toList();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startReordering(WidgetTester tester) async {
    unawaited(controller.showOrganizationMenu());
    await tester.pumpAndSettle();
    expect(find.text('整理书库'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-start-reordering')));
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
    settings.dispose();
    await tester.binding.setSurfaceSize(null);
  }
}
