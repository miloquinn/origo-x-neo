@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/data/migration/shelf_folder_schema_migration.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/home/widgets/home_page_wrappers.dart';
import 'package:xxread/pages/library/library_folder_name_dialog.dart';
import 'package:xxread/pages/library/library_grid_book_details.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/library/library_event_bus_service.dart';
import 'package:xxread/services/library/shelf_folder_dao.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory supportDirectory;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'library_shelf_widgets_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => supportDirectory.path,
    );
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('cover grid shows only direct books and child folders', (
    tester,
  ) async {
    await _expectScopedLayout(tester, LibraryLayoutMode.grid);
  });

  testWidgets('card list keeps direct books and folders navigable', (
    tester,
  ) async {
    await _expectScopedLayout(tester, LibraryLayoutMode.card);
  });

  testWidgets('nested back restores parent search and exits selection first', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    late ShelfFolder parent;
    late ShelfFolder child;
    await tester.runAsync(() async {
      parent = await fixture.dao.create('Fiction');
      child = await fixture.dao.create('Classics', parentId: parent.id);
      await fixture.addBook('Root Alpha');
      await fixture.addBook('Root Beta');
      await fixture.addBook('Child Alpha', folderId: parent.id);
      await fixture.addBook('Child Beta', folderId: parent.id);
      await fixture.addBook('Deep Book', folderId: child.id);
    });
    await fixture.mount(tester);

    fixture.controller.toggleSearch();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_gridTitles(tester), ['Root Alpha']);

    await _enterFolder(tester, parent);
    expect(fixture.controller.folderName.value, 'Fiction');
    expect(find.byType(TextField), findsNothing);
    expect(_gridTitles(tester), containsAll(['Child Alpha', 'Child Beta']));
    expect(_gridTitles(tester), isNot(contains('Root Alpha')));

    fixture.controller.toggleSearch();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'deep');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_gridTitles(tester), isEmpty);
    await _enterFolder(tester, child);
    expect(fixture.controller.folderName.value, 'Classics');
    expect(find.byType(TextField), findsNothing);
    expect(_gridTitles(tester), ['Deep Book']);

    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fixture.controller.selection.value.isActive, isFalse);
    expect(fixture.controller.folderName.value, 'Classics');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(fixture.controller.folderName.value, 'Fiction');
    expect(_searchText(tester), 'deep');
    expect(_gridTitles(tester), isEmpty);

    await tester.tap(find.byKey(const ValueKey('library-back-to-parent')));
    await tester.pumpAndSettle();
    expect(fixture.controller.folderName.value, isNull);
    expect(_searchText(tester), 'alpha');
    expect(_gridTitles(tester), ['Root Alpha']);
    expect(find.byKey(const ValueKey('library-back-to-parent')), findsNothing);
  });

  testWidgets('select all follows directory and current search scope', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    late ShelfFolder parent;
    await tester.runAsync(() async {
      parent = await fixture.dao.create('Nested Shelf');
      final child = await fixture.dao.create('Deep Shelf', parentId: parent.id);
      await fixture.addBook('Root First');
      await fixture.addBook('Root Second');
      await fixture.addBook('Child First', folderId: parent.id);
      await fixture.addBook('Child Second', folderId: parent.id);
      await fixture.addBook('Deep First', folderId: child.id);
    });
    await fixture.mount(tester);

    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 2);
    fixture.controller.exitSelection();
    await tester.pump();
    await _enterFolder(tester, parent);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 2);

    fixture.controller.toggleSearch();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 150));
    expect(fixture.controller.selection.value.isActive, isFalse);
    expect(fixture.controller.selection.value.selectedCount, 0);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 1);
    expect(_gridTitles(tester), ['Child First']);

    fixture.controller.goUp();
    await tester.pumpAndSettle();
    expect(fixture.controller.selection.value.isActive, isFalse);
    expect(fixture.controller.folderName.value, isNull);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 2);
  });

  testWidgets('cached shelf leaves back handling to the active home tab', (
    tester,
  ) async {
    final activeDestination = ValueNotifier(HomeNavigationDestination.library);
    addTearDown(activeDestination.dispose);
    final fixture = await _ShelfFixture.open(tester);
    final folder = (await tester.runAsync(
      () => fixture.dao.create('Cached Shelf'),
    ))!;
    await tester.runAsync(
      () => fixture.addBook('Cached Book', folderId: folder.id),
    );
    await fixture.mount(tester, activeDestination: activeDestination);
    await _enterFolder(tester, folder);
    fixture.controller.selectAllVisible();
    await tester.pump();
    final shelfScope = find.byWidgetPredicate((widget) => widget is PopScope);
    expect(tester.widget<PopScope>(shelfScope).canPop, isFalse);

    for (final destination in [
      HomeNavigationDestination.settings,
      HomeNavigationDestination.home,
    ]) {
      activeDestination.value = destination;
      await tester.pump();
      final scope = tester.widget<PopScope>(shelfScope);
      expect(scope.canPop, isTrue);
      scope.onPopInvokedWithResult?.call(false, null);
      await tester.pump();
      expect(fixture.controller.folderName.value, 'Cached Shelf');
      expect(fixture.controller.selection.value.isActive, isTrue);
      expect(fixture.controller.selection.value.selectedCount, 1);
    }

    activeDestination.value = HomeNavigationDestination.library;
    await tester.pump();
    expect(tester.widget<PopScope>(shelfScope).canPop, isFalse);
    expect(fixture.controller.folderName.value, 'Cached Shelf');
  });

  testWidgets('selected books persist in a folder with at most nine previews', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    final ids = <int>{};
    await tester.runAsync(() async {
      for (var index = 0; index < 12; index++) {
        ids.add(await fixture.addBook('Book $index'));
      }
    });
    await fixture.mount(tester);
    await tester.longPress(_gridBookTile(ids.first));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选择多本'));
    await tester.pumpAndSettle();
    expect(fixture.controller.selection.value.selectedCount, 1);
    await tester.tap(_gridBookTile(ids.elementAt(1)));
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 2);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 12);

    unawaited(fixture.controller.createFolderFromSelected());
    await tester.pumpAndSettle();
    await _saveFolder(tester, 'Collected Books');
    final folders = (await tester.runAsync(fixture.dao.getAll))!;
    final created = folders.single;
    expect(created.name, 'Collected Books');
    expect(created.parentId, isNull);
    expect(fixture.controller.selection.value.isActive, isFalse);
    expect(find.byType(LibraryGridBookDetails), findsNothing);
    expect(_itemCount(tester), 1);
    expect(_folderTile(created), findsOneWidget);
    expect(
      find.descendant(of: _folderTile(created), matching: find.text('12 本书')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'folder-preview-${created.id}-',
            ),
      ),
      findsNWidgets(9),
    );
    final savedBooks = (await tester.runAsync(fixture.books))!;
    expect(savedBooks.map((book) => book.id).toSet(), ids);
    expect(
      savedBooks.every((book) => book.shelfFolderId == created.id),
      isTrue,
    );

    await _enterFolder(tester, created);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 12);
    expect(_itemCount(tester), 12);
  });

  testWidgets('local folder creation applies one library reload', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    await tester.runAsync(() async {
      await fixture.addBook('First');
      await fixture.addBook('Second');
      await fixture.addBook('Third');
    });
    await fixture.mount(tester);
    expect(fixture.libraryLoadCount, 1);

    fixture.controller.selectAllVisible();
    await tester.pump();
    unawaited(fixture.controller.createFolderFromSelected());
    await tester.pumpAndSettle();
    await _saveFolder(tester, 'One Reload');
    expect(fixture.libraryLoadCount, 2);
  });

  testWidgets('local book move applies one library reload', (tester) async {
    final fixture = await _ShelfFixture.open(tester);
    late ShelfFolder folder;
    await tester.runAsync(() async {
      folder = await fixture.dao.create('Move Target');
      await fixture.addBook('First');
      await fixture.addBook('Second');
      await fixture.addBook('Third');
    });
    await fixture.mount(tester);
    expect(fixture.libraryLoadCount, 1);

    fixture.controller.selectAllVisible();
    await tester.pump();
    unawaited(fixture.controller.moveSelected());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text(folder.name),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('library-folder-move-here')));
    await _pumpUntil(
      tester,
      () => !fixture.controller.selection.value.isActive,
      'move to folder finishes with one reload',
    );
    expect(fixture.libraryLoadCount, 2);
  });

  testWidgets(
    'a newly filled folder can return and accept input around a reload',
    (tester) async {
      final fixture = await _ShelfFixture.open(tester);
      await tester.runAsync(() async {
        await fixture.addBook('Alpha');
        await fixture.addBook('Beta');
        await fixture.addBook('Gamma');
      });
      await fixture.mount(tester);
      fixture.controller.selectAllVisible();
      await tester.pump();
      unawaited(fixture.controller.createFolderFromSelected());
      await tester.pumpAndSettle();
      await _saveFolder(tester, 'Quick Return', settleAfter: Duration.zero);

      final folder = (await tester.runAsync(fixture.dao.getAll))!.single;
      await _enterFolder(tester, folder);
      final reloadGate = Completer<void>();
      fixture.blockNextLibraryLoad = reloadGate;
      LibraryEventBus().notifyLibraryChanged();
      await tester.pump(const Duration(milliseconds: 110));
      await _pumpUntil(
        tester,
        () => fixture.blockNextLibraryLoad == null,
        'the reload overlaps folder return',
        settleAfter: Duration.zero,
      );

      await tester.tap(find.byKey(const ValueKey('library-back-to-parent')));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      reloadGate.complete();
      await tester.pumpAndSettle();

      expect(fixture.controller.folderName.value, isNull);
      expect(_folderTile(folder).hitTestable(), findsOneWidget);
      await tester.tap(_folderTile(folder));
      await tester.pumpAndSettle();
      expect(fixture.controller.folderName.value, 'Quick Return');
    },
  );

  testWidgets('an external event during a local reload is applied afterward', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    await tester.runAsync(() => fixture.addBook('External Event'));
    await fixture.mount(tester);
    final initialLoads = fixture.libraryLoadCount;
    final localReloadGate = Completer<void>();
    fixture.blockNextLibraryLoad = localReloadGate;

    fixture.controller.selectAllVisible();
    await tester.pump();
    unawaited(fixture.controller.createFolderFromSelected());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('library-folder-name')),
      'External Event Folder',
    );
    await tester.tap(find.byKey(const ValueKey('library-folder-save')));
    await _pumpUntil(
      tester,
      () => fixture.blockNextLibraryLoad == null,
      'the local mutation reload starts',
      settleAfter: Duration.zero,
    );
    expect(fixture.libraryLoadCount, initialLoads + 1);

    LibraryEventBus().notifyLibraryChanged();
    await tester.pump(const Duration(milliseconds: 110));
    await _pumpUntil(
      tester,
      () => fixture.libraryLoadCount == initialLoads + 2,
      'the external event starts a second reload',
      settleAfter: Duration.zero,
    );
    localReloadGate.complete();
    await _pumpUntil(
      tester,
      () => find.byType(LibraryFolderNameDialog).evaluate().isEmpty,
      'the local folder save finishes',
    );
    expect(fixture.libraryLoadCount, initialLoads + 2);
  });

  testWidgets('an empty child shelf can create another nested shelf', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    final parent = (await tester.runAsync(
      () => fixture.dao.create('Empty Parent'),
    ))!;
    await fixture.mount(tester);
    await _enterFolder(tester, parent);
    expect(
      find.byKey(const ValueKey('library-create-empty-folder')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('library-create-empty-folder')));
    await tester.pumpAndSettle();
    await _saveFolder(tester, 'Nested Empty');
    final folders = (await tester.runAsync(fixture.dao.getAll))!;
    final child = folders.singleWhere(
      (folder) => folder.name == 'Nested Empty',
    );
    expect(child.parentId, parent.id);
    expect(fixture.controller.folderName.value, 'Empty Parent');
    expect(_folderTile(child), findsOneWidget);
    await _enterFolder(tester, child);
    expect(fixture.controller.folderName.value, 'Nested Empty');

    unawaited(fixture.controller.showAddMenu());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(ListTile), matching: find.text('新建分组')),
    );
    await tester.pumpAndSettle();
    await _saveFolder(tester, 'Third Level');
    final updated = (await tester.runAsync(fixture.dao.getAll))!;
    final grandchild = updated.singleWhere(
      (folder) => folder.name == 'Third Level',
    );
    expect(grandchild.parentId, child.id);
    expect(_folderTile(grandchild), findsOneWidget);
  });

  testWidgets('selected books move into an existing folder and back to root', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester);
    late ShelfFolder target;
    await tester.runAsync(() async {
      target = await fixture.dao.create('Destination');
      await fixture.addBook('Moving Book');
      await fixture.addBook('Existing Book', folderId: target.id);
    });
    await fixture.mount(tester);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 1);

    unawaited(fixture.controller.moveSelected());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Destination'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('library-folder-move-here')));
    await _pumpUntil(
      tester,
      () => !fixture.controller.selection.value.isActive,
      'move into existing folder finishes',
    );
    expect(find.byType(LibraryGridBookDetails), findsNothing);
    final movedBooks = (await tester.runAsync(fixture.books))!;
    expect(movedBooks.every((book) => book.shelfFolderId == target.id), isTrue);

    await _enterFolder(tester, target);
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.selectedCount, 2);
    unawaited(fixture.controller.moveSelected());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('library-folder-move-here')));
    await _pumpUntil(
      tester,
      () => !fixture.controller.selection.value.isActive,
      'move to root finishes',
    );
    final rootedBooks = (await tester.runAsync(fixture.books))!;
    expect(rootedBooks.every((book) => book.shelfFolderId == null), isTrue);
    fixture.controller.goUp();
    await tester.pumpAndSettle();
    expect(_gridTitles(tester), containsAll(['Moving Book', 'Existing Book']));
  });

  testWidgets('failed name save retains draft and selection for a retry', (
    tester,
  ) async {
    final fixture = await _ShelfFixture.open(tester, failFirstCreate: true);
    await tester.runAsync(() => fixture.addBook('Retry Book'));
    await fixture.mount(tester);
    fixture.controller.selectAllVisible();
    await tester.pump();
    unawaited(fixture.controller.createFolderFromSelected());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('library-folder-name')),
      '  Retained Name  ',
    );
    await tester.tap(find.byKey(const ValueKey('library-folder-save')));
    await _pumpUntil(
      tester,
      () => find.text('无法更新分组，请重试。').evaluate().isNotEmpty,
      'failed save leaves an actionable retry',
    );
    expect(find.byType(LibraryFolderNameDialog), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('library-folder-name')),
    );
    expect(field.controller!.text, '  Retained Name  ');
    expect(field.enabled, isTrue);
    expect(fixture.controller.selection.value.selectedCount, 1);
    expect(fixture.controller.folderName.value, isNull);
    expect((await tester.runAsync(fixture.dao.getAll))!, isEmpty);

    await tester.tap(find.byKey(const ValueKey('library-folder-save')));
    await _pumpUntil(
      tester,
      () => find.byType(LibraryFolderNameDialog).evaluate().isEmpty,
      'retry persists the folder',
    );
    expect(
      (await tester.runAsync(fixture.dao.getAll))!.single.name,
      'Retained Name',
    );
    expect(fixture.controller.selection.value.isActive, isFalse);
    expect(find.byType(LibraryGridBookDetails), findsNothing);
  });
}

Future<void> _expectScopedLayout(
  WidgetTester tester,
  LibraryLayoutMode mode,
) async {
  final fixture = await _ShelfFixture.open(tester, mode: mode);
  late ShelfFolder parent;
  late ShelfFolder child;
  await tester.runAsync(() async {
    parent = await fixture.dao.create('Parent Shelf');
    child = await fixture.dao.create('Child Shelf', parentId: parent.id);
    await fixture.addBook('Direct Root');
    await fixture.addBook('Direct Parent', folderId: parent.id);
    await fixture.addBook('Direct Child', folderId: child.id);
  });
  await fixture.mount(tester);
  expect(_itemCount(tester), 2);
  expect(_folderTile(parent), findsOneWidget);
  expect(_folderTile(child), findsNothing);
  expect(find.text('Direct Root'), findsWidgets);
  expect(fixture.controller.folderName.value, isNull);
  if (mode == LibraryLayoutMode.grid) {
    expect(_gridTitles(tester), ['Direct Root']);
  } else {
    expect(_verticalList(), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.horizontal,
      ),
      findsOneWidget,
    );
    expect(find.byType(LibraryGridBookDetails), findsNothing);
  }

  await _enterFolder(tester, parent);
  expect(_itemCount(tester), 2);
  expect(_folderTile(child), findsOneWidget);
  expect(_folderTile(parent), findsNothing);
  expect(find.text('Direct Root'), findsNothing);
  expect(find.text('Direct Parent'), findsWidgets);
  expect(fixture.controller.folderName.value, 'Parent Shelf');
  expect(find.byKey(const ValueKey('library-back-to-parent')), findsOneWidget);
  if (mode == LibraryLayoutMode.grid) {
    expect(_gridTitles(tester), ['Direct Parent']);
  }
}

Finder _folderTile(ShelfFolder folder) =>
    find.byKey(ValueKey('library-folder-${folder.id}'));

Finder _gridBookTile(int id) => find
    .ancestor(
      of: find.byWidgetPredicate(
        (widget) => widget is LibraryGridBookDetails && widget.book.id == id,
      ),
      matching: find.byType(InkWell),
    )
    .first;

Future<void> _enterFolder(WidgetTester tester, ShelfFolder folder) async {
  await tester.tap(_folderTile(folder));
  await tester.pumpAndSettle();
}

List<String> _gridTitles(WidgetTester tester) => tester
    .widgetList<LibraryGridBookDetails>(find.byType(LibraryGridBookDetails))
    .map((details) => details.book.title)
    .toList();

String _searchText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

int _itemCount(WidgetTester tester) {
  final grid = find.byKey(const ValueKey('library-cover-grid'));
  final delegate = grid.evaluate().isNotEmpty
      ? tester.widget<GridView>(grid).childrenDelegate
      : tester.widget<ListView>(_verticalList()).childrenDelegate;
  return (delegate as SliverChildBuilderDelegate).childCount!;
}

Finder _verticalList() => find.byWidgetPredicate(
  (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
);

Future<void> _saveFolder(
  WidgetTester tester,
  String name, {
  Duration settleAfter = const Duration(milliseconds: 300),
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('library-folder-name')),
    name,
  );
  await tester.tap(find.byKey(const ValueKey('library-folder-save')));
  await _pumpUntil(
    tester,
    () => find.byType(LibraryFolderNameDialog).evaluate().isEmpty,
    'folder save finishes',
    settleAfter: settleAfter,
  );
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() ready,
  String reason, {
  Duration settleAfter = const Duration(milliseconds: 300),
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (ready()) {
      if (settleAfter > Duration.zero) await tester.pump(settleAfter);
      return;
    }
  }
  expect(ready(), isTrue, reason: reason);
}

class _ShelfFixture {
  _ShelfFixture(this.database, this.dao, this.settings);

  final Database database;
  final ShelfFolderDao dao;
  final AppSettingsNotifier settings;
  final controller = LibraryPageController();
  int libraryLoadCount = 0;
  Completer<void>? blockNextLibraryLoad;

  static Future<_ShelfFixture> open(
    WidgetTester tester, {
    LibraryLayoutMode mode = LibraryLayoutMode.grid,
    bool failFirstCreate = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final fixture = (await tester.runAsync(() async {
      sqfliteFfiInit();
      final database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await database.execute('PRAGMA foreign_keys = ON');
      await database.execute('''
        CREATE TABLE books(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          author TEXT,
          filePath TEXT NOT NULL,
          format TEXT NOT NULL,
          importDate INTEGER NOT NULL,
          reading_progress REAL,
          storage_type TEXT
        )
      ''');
      await ShelfFolderSchemaMigration.migrate(database);
      final settings = AppSettingsNotifier();
      if (!settings.isInitialized) {
        final initialized = Completer<void>();
        void changed() {
          if (settings.isInitialized && !initialized.isCompleted) {
            initialized.complete();
          }
        }

        settings.addListener(changed);
        changed();
        await initialized.future;
        settings.removeListener(changed);
      }
      await settings.setLibraryLayoutMode(mode);
      final dao = failFirstCreate
          ? _FailFirstCreateDao(database)
          : ShelfFolderDao(database: () async => database);
      return _ShelfFixture(database, dao, settings);
    }))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      fixture.controller.dispose();
      fixture.settings.dispose();
      await tester.runAsync(fixture.database.close);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    return fixture;
  }

  Future<int> addBook(String title, {String? folderId}) =>
      database.insert('books', {
        'title': title,
        'author': 'Fixture Author',
        'filePath': '/fixtures/$title.epub',
        'format': 'epub',
        'importDate': DateTime.utc(2026, 10, 8).millisecondsSinceEpoch,
        'reading_progress': 0.25,
        'storage_type': 'local',
        'shelf_folder_id': folderId,
      });

  Future<List<Book>> books() async => (await database.query(
    'books',
    orderBy: 'id ASC',
  )).map(Book.fromMap).toList(growable: false);

  Future<List<Book>> loadBooks() async {
    libraryLoadCount++;
    final gate = blockNextLibraryLoad;
    blockNextLibraryLoad = null;
    if (gate != null) await gate.future;
    return books();
  }

  Future<void> mount(
    WidgetTester tester, {
    ValueNotifier<HomeNavigationDestination>? activeDestination,
  }) async {
    final library = LibraryPage(
      controller: controller,
      folderDao: dao,
      foldersLoader: dao.getAll,
      booksLoader: loadBooks,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          home: activeDestination == null
              ? library
              : ValueListenableBuilder<HomeNavigationDestination>(
                  valueListenable: activeDestination,
                  child: library,
                  builder: (_, destination, child) => HomeTabFocusScope(
                    activeDestination: destination,
                    child: child!,
                  ),
                ),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
      'library finishes loading the fixture',
    );
  }
}

class _FailFirstCreateDao extends ShelfFolderDao {
  _FailFirstCreateDao(Database database)
    : super(database: () async => database);

  var _failed = false;

  @override
  Future<ShelfFolder> create(
    String name, {
    String? parentId,
    Set<int> bookIds = const {},
  }) async {
    if (!_failed) {
      _failed = true;
      throw StateError('Simulated transient write failure');
    }
    return super.create(name, parentId: parentId, bookIds: bookIds);
  }
}
