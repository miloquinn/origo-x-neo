import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/data/migration/shelf_folder_schema_migration.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/library/shelf_folder_dao.dart';

void main() {
  late Database database;
  late ShelfFolderDao dao;

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await database.execute('PRAGMA foreign_keys = ON');
    await database.execute('''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        filePath TEXT NOT NULL,
        format TEXT NOT NULL,
        currentPage INTEGER DEFAULT 0,
        totalPages INTEGER DEFAULT 1,
        reading_progress REAL,
        importDate INTEGER NOT NULL,
        file_modified_time INTEGER,
        content_hash TEXT,
        cover_image_path TEXT,
        text_encoding TEXT,
        last_canonical_locator TEXT,
        last_rendered_locator TEXT,
        layout_signature TEXT,
        storage_type TEXT,
        source_id TEXT,
        source_book_id TEXT,
        source_json TEXT,
        source_book_json TEXT,
        source_kind TEXT,
        source_locator TEXT,
        source_modified_time INTEGER
      )
    ''');
    await ShelfFolderSchemaMigration.migrate(database);
    dao = ShelfFolderDao(database: () async => database);
  });

  tearDown(() => database.close());

  Future<int> addBook(String title) => database.insert('books', {
    'title': title,
    'filePath': '/$title.epub',
    'format': 'epub',
    'importDate': DateTime.utc(2026, 10, 8).millisecondsSinceEpoch,
    'storage_type': 'local',
  });

  Future<List<int>> addBooks(int count) => database.transaction((txn) async {
    final ids = <int>[];
    for (var index = 0; index < count; index++) {
      ids.add(
        await txn.insert('books', {
          'title': 'Book $index',
          'filePath': '/book-$index.epub',
          'format': 'epub',
          'importDate': DateTime.utc(2026, 10, 8).millisecondsSinceEpoch,
          'storage_type': 'local',
        }),
      );
    }
    return ids;
  });

  Future<String?> folderOf(int bookId) async =>
      (await database.query(
            'books',
            columns: const ['shelf_folder_id'],
            where: 'id = ?',
            whereArgs: [bookId],
          )).single['shelf_folder_id']
          as String?;

  test(
    'v28 migration is idempotent and installs foreign keys and indexes',
    () async {
      await ShelfFolderSchemaMigration.migrate(database);

      final columns = await database.rawQuery('PRAGMA table_info(books)');
      expect(columns.map((row) => row['name']), contains('shelf_folder_id'));

      final folderForeignKeys = await database.rawQuery(
        'PRAGMA foreign_key_list(shelf_folders)',
      );
      expect(
        folderForeignKeys,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['from'] == 'parent_id' &&
                row['table'] == 'shelf_folders' &&
                row['on_delete'] == 'SET NULL',
          ),
        ),
      );
      final bookForeignKeys = await database.rawQuery(
        'PRAGMA foreign_key_list(books)',
      );
      expect(
        bookForeignKeys,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['from'] == 'shelf_folder_id' &&
                row['table'] == 'shelf_folders' &&
                row['on_delete'] == 'SET NULL',
          ),
        ),
      );

      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      expect(
        indexes.map((row) => row['name']),
        containsAll({
          'idx_shelf_folders_parent_created',
          'idx_books_shelf_folder',
        }),
      );
    },
  );

  test('book maps preserve membership and copyWith clears it explicitly', () {
    final book = Book(
      title: 'Book',
      filePath: '/book.epub',
      format: 'epub',
      importDate: DateTime.utc(2026, 10, 8),
      shelfFolderId: 'folder-id',
    );

    expect(Book.fromMap(book.toMap()).shelfFolderId, 'folder-id');
    expect(book.copyWith(title: 'Renamed').shelfFolderId, 'folder-id');
    expect(book.copyWith(clearShelfFolder: true).shelfFolderId, isNull);
    expect(
      Book.fromMap({...book.toMap()}..remove('shelf_folder_id')).shelfFolderId,
      isNull,
    );
  });

  test('book summary reads preserve folder membership', () async {
    final folder = await dao.create('Folder');
    final bookId = await addBook('Book');
    await dao.moveBooks({bookId}, folder.id);
    final bookDao = BookDao(
      database: () async => database,
      documentsDirectory: () async => Directory('/'),
    );

    expect((await bookDao.getAllBooks()).single.shelfFolderId, folder.id);
  });

  test('create trims name and atomically moves every selected book', () async {
    final first = await addBook('First');
    final second = await addBook('Second');

    final folder = await dao.create('  小说  ', bookIds: {first, second});

    expect(folder.name, '小说');
    expect(folder.parentId, isNull);
    expect(await folderOf(first), folder.id);
    expect(await folderOf(second), folder.id);
    expect((await dao.getAll()).single.id, folder.id);
  });

  test(
    'create moves more than SQLite parameter limit in one transaction',
    () async {
      final bookIds = await addBooks(1100);

      final folder = await dao.create('Large folder', bookIds: bookIds.toSet());

      final result = await database.rawQuery(
        'SELECT COUNT(*) AS count FROM books WHERE shelf_folder_id = ?',
        [folder.id],
      );
      expect(result.single['count'], 1100);
    },
  );

  test(
    'missing book in final batch rolls back a large create and move',
    () async {
      final bookIds = await addBooks(1100);
      final requestedIds = <int>{...bookIds, 999999};

      await expectLater(
        dao.create('Must roll back', bookIds: requestedIds),
        throwsA(isA<StateError>()),
      );

      expect(await dao.getAll(), isEmpty);
      final result = await database.rawQuery(
        'SELECT COUNT(*) AS count FROM books WHERE shelf_folder_id IS NOT NULL',
      );
      expect(result.single['count'], 0);
    },
  );

  test(
    'create rejects invalid input without leaving a folder or moving books',
    () async {
      final bookId = await addBook('Present');

      await expectLater(
        dao.create('Group', bookIds: {bookId, 999}),
        throwsA(isA<StateError>()),
      );
      expect(await dao.getAll(), isEmpty);
      expect(await folderOf(bookId), isNull);
      await expectLater(dao.create('   '), throwsA(isA<ArgumentError>()));
      await expectLater(
        dao.create(List.filled(61, '书').join()),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  test(
    'move operations validate references and reject hierarchy cycles',
    () async {
      final bookId = await addBook('Book');
      final parent = await dao.create('Parent');
      final child = await dao.create('Child', parentId: parent.id);
      final grandchild = await dao.create('Grandchild', parentId: child.id);

      await dao.moveBooks({bookId}, grandchild.id);
      expect(await folderOf(bookId), grandchild.id);
      await dao.moveBooks({bookId}, null);
      expect(await folderOf(bookId), isNull);

      await expectLater(
        dao.moveFolder(parent.id, grandchild.id),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        dao.moveFolder(parent.id, parent.id),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        dao.moveBooks({bookId}, 'missing'),
        throwsA(isA<StateError>()),
      );

      final folders = {
        for (final folder in await dao.getAll()) folder.id: folder,
      };
      expect(folders[parent.id]!.parentId, isNull);
      expect(folders[child.id]!.parentId, parent.id);
      expect(folders[grandchild.id]!.parentId, child.id);
    },
  );

  test(
    'dissolve promotes direct books and children to the original parent',
    () async {
      final parent = await dao.create('Parent');
      final dissolved = await dao.create('Dissolved', parentId: parent.id);
      final child = await dao.create('Child', parentId: dissolved.id);
      final bookId = await addBook('Book');
      await dao.moveBooks({bookId}, dissolved.id);

      await dao.dissolve(dissolved.id);

      expect(await folderOf(bookId), parent.id);
      final folders = {
        for (final folder in await dao.getAll()) folder.id: folder,
      };
      expect(folders, isNot(contains(dissolved.id)));
      expect(folders[child.id]!.parentId, parent.id);
    },
  );

  test(
    'deleting a referenced folder clears parent and book membership',
    () async {
      final parent = await dao.create('Parent');
      final child = await dao.create('Child', parentId: parent.id);
      final bookId = await addBook('Book');
      await dao.moveBooks({bookId}, parent.id);

      await database.delete(
        'shelf_folders',
        where: 'id = ?',
        whereArgs: [parent.id],
      );

      expect(await folderOf(bookId), isNull);
      expect(
        (await dao.getAll())
            .singleWhere((item) => item.id == child.id)
            .parentId,
        isNull,
      );
    },
  );
}
