import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/data/migration/book_storage_path_migration.dart';
import 'package:xxread/data/migration/book_source_reading_progress_schema_migration.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/sync/book_sync_identity.dart';

void main() {
  late Database database;
  late BookDao dao;
  late String root;
  const oldIosRoot =
      '/private/var/mobile/Containers/Data/Application/11111111-1111-1111-1111-111111111111/Documents';

  setUp(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    root = '/current-container/Documents';
    await database.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY, title TEXT, author TEXT, filePath TEXT,
        format TEXT, currentPage INTEGER, totalPages INTEGER,
        reading_progress REAL, importDate INTEGER, cached_content TEXT,
        cached_pages TEXT, file_modified_time INTEGER, content_hash TEXT,
        table_of_contents TEXT, cover_image_path TEXT, text_encoding TEXT,
        last_canonical_locator TEXT, last_rendered_locator TEXT,
        layout_signature TEXT, storage_type TEXT, source_id TEXT,
        source_book_id TEXT, source_json TEXT, source_book_json TEXT,
        source_kind TEXT, source_locator TEXT, source_modified_time INTEGER
      )
    ''');
    await BookSourceReadingProgressSchemaMigration.migrate(database);

    dao = BookDao(
      database: () async => database,
      documentsDirectory: () async => Directory(root),
    );
  });
  tearDown(() => database.close());

  Book book({String? filePath, String? coverPath, String hash = 'hash'}) =>
      Book(
        title: 'Book',
        filePath: filePath ?? '$root/books/nested/book.epub',
        format: 'epub',
        coverImagePath: coverPath ?? '$root/covers/custom_1.png',
        contentHash: hash,
        currentPage: 4,
        totalPages: 10,
        readingProgress: 0.4,
        sourceId: 'source',
        sourceBookId: 'source-book',
        sourceKind: 'file',
        sourceLocator: 'original-user-source',
      );

  Future<Map<String, Object?>> stored(int id) async =>
      (await database.query('books', where: 'id = ?', whereArgs: [id])).single;

  test(
    'binding preserves progress and cover changes made during source lookup',
    () async {
      final id = await dao.insertBook(book());
      final original = (await dao.getBookById(id))!;
      await dao.updateBookProgress(id, 8, readingProgress: 0.8);
      await dao.updateBookCoverPath(id, '$root/covers/custom_new.png');
      final rebound = await dao.updateSourceBinding(
        original,
        original.copyWith(
          sourceId: 'new-source',
          sourceBookId: 'new-book',
          sourceJson: '{}',
          sourceBookJson: '{}',
          coverImagePath: '$root/covers/source_new.png',
        ),
      );
      expect(rebound.sourceId, 'new-source');
      expect(rebound.currentPage, 8);
      expect(rebound.progress, 0.8);
      expect(rebound.coverImagePath, '$root/covers/custom_new.png');
      expect(rebound.filePath, original.filePath);
      expect(rebound.contentHash, original.contentHash);
      await expectLater(
        dao.updateSourceBinding(original, original),
        throwsA(isA<BookSourceBindingConflictException>()),
      );
      expect((await dao.getBookById(id))!.sourceId, 'new-source');
    },
  );

  test('binding and new source position commit in one transaction', () async {
    final id = await dao.insertBook(
      book(filePath: '').copyWith(format: 'source', storageType: 'online'),
    );
    await database.update(
      'books',
      {
        'last_canonical_locator': '{"chapterId":"old-chapter"}',
        'last_rendered_locator': '{"page":2}',
        'layout_signature': 'old-layout',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final original = (await dao.getBookById(id))!;
    final replacement = original.copyWith(
      sourceId: 'replacement-source',
      sourceBookId: 'replacement-book',
      sourceJson: '{}',
      sourceBookJson: '{}',
      currentPage: 3000,
      totalPages: 10000,
      readingProgress: 0.3,
    );
    final progress = BookSourceReadingProgress(
      chapterId: 'chapter-3',
      chapterIndex: 3,
      chapterProgress: 0,
      updatedAt: DateTime.utc(2026, 9, 24),
    );
    await BookSourceReadingProgressStore.saveWithExecutor(
      database,
      sourceId: original.sourceId!,
      bookId: original.sourceBookId!,
      progress: BookSourceReadingProgress(
        chapterId: 'old-chapter',
        chapterIndex: 8,
        chapterProgress: 0.5,
        updatedAt: DateTime.utc(2026, 9, 23),
      ),
    );

    final rebound = await dao.updateSourceBindingWithProgress(
      original,
      replacement,
      progress: progress,
    );

    expect(rebound.sourceId, 'replacement-source');
    final rows = await database.query('book_source_reading_progress');
    expect(rows, hasLength(2));
    expect(
      rows.singleWhere(
        (row) => row['source_id'] == 'replacement-source',
      )['chapter_id'],
      'chapter-3',
    );
    expect(
      rows.singleWhere(
        (row) => row['source_id'] == original.sourceId,
      )['chapter_id'],
      'old-chapter',
    );
    expect((await dao.getBookById(id))?.sourceBookId, 'replacement-book');
    final storedBook = await stored(id);
    expect(storedBook['last_canonical_locator'], isNull);
    expect(storedBook['last_rendered_locator'], isNull);
    expect(storedBook['layout_signature'], isNull);
  });

  test('progress write failure rolls back the source binding', () async {
    final id = await dao.insertBook(
      book(filePath: '').copyWith(format: 'source', storageType: 'online'),
    );
    final original = (await dao.getBookById(id))!;
    await database.execute('DROP TABLE book_source_reading_progress');

    await expectLater(
      dao.updateSourceBindingWithProgress(
        original,
        original.copyWith(
          sourceId: 'replacement-source',
          sourceBookId: 'replacement-book',
        ),
        progress: BookSourceReadingProgress(
          chapterId: 'chapter-3',
          chapterIndex: 3,
          chapterProgress: 0,
          updatedAt: DateTime.utc(2026, 9, 24),
        ),
      ),
      throwsA(anything),
    );

    expect((await dao.getBookById(id))?.sourceId, original.sourceId);
    expect((await dao.getBookById(id))?.sourceBookId, original.sourceBookId);
  });

  test(
    'online progress changing during validation aborts the binding',
    () async {
      final id = await dao.insertBook(
        book(filePath: '').copyWith(format: 'source', storageType: 'online'),
      );
      final original = (await dao.getBookById(id))!;
      await dao.updateBookProgress(id, 7000, readingProgress: 0.7);

      await expectLater(
        dao.updateSourceBindingWithProgress(
          original,
          original.copyWith(
            sourceId: 'replacement-source',
            sourceBookId: 'replacement-book',
          ),
          progress: BookSourceReadingProgress(
            chapterId: 'chapter-3',
            chapterIndex: 3,
            chapterProgress: 0,
            updatedAt: DateTime.utc(2026, 9, 24),
          ),
        ),
        throwsA(
          isA<BookSourceBindingConflictException>().having(
            (error) => error.reason,
            'reason',
            BookSourceBindingConflictReason.readingPositionChanged,
          ),
        ),
      );

      final unchanged = await dao.getBookById(id);
      expect(unchanged?.sourceId, original.sourceId);
      expect(unchanged?.currentPage, 7000);
      expect(await database.query('book_source_reading_progress'), isEmpty);
    },
  );

  test('target identity conflict is detected inside the transaction', () async {
    final originalId = await dao.insertBook(book(hash: 'original'));
    final original = (await dao.getBookById(originalId))!;
    await dao.insertBook(
      book(hash: 'target').copyWith(
        sourceId: 'replacement-source',
        sourceBookId: 'replacement-book',
      ),
    );

    await expectLater(
      dao.updateSourceBinding(
        original,
        original.copyWith(
          sourceId: 'replacement-source',
          sourceBookId: 'replacement-book',
        ),
      ),
      throwsA(
        isA<BookSourceBindingConflictException>().having(
          (error) => error.reason,
          'reason',
          BookSourceBindingConflictReason.targetAlreadyBound,
        ),
      ),
    );

    expect((await dao.getBookById(originalId))?.sourceId, original.sourceId);
  });

  test('late source cover cannot overwrite a newer custom cover', () async {
    final id = await dao.insertBook(book());
    final original = (await dao.getBookById(id))!;
    await dao.updateBookCoverPath(id, '$root/covers/user-new.png');

    final applied = await dao.updateBookCoverPathIfSource(
      bookId: id,
      sourceId: original.sourceId!,
      sourceBookId: original.sourceBookId!,
      expectedCoverImagePath: original.coverImagePath,
      coverImagePath: '$root/covers/late-source.png',
    );

    expect(applied, isFalse);
    expect(
      (await dao.getBookById(id))?.coverImagePath,
      '$root/covers/user-new.png',
    );
  });

  test(
    'new records stay relative across repeated sandbox relocation',
    () async {
      final id = await dao.insertBook(book());
      expect((await stored(id))['filePath'], 'books/nested/book.epub');
      expect((await stored(id))['cover_image_path'], 'covers/custom_1.png');
      for (final nextRoot in ['/second/Documents', '/third/Documents']) {
        root = nextRoot;
        final loaded = (await dao.getAllBooks()).single;
        expect(loaded.filePath, '$root/books/nested/book.epub');
        expect(loaded.coverImagePath, '$root/covers/custom_1.png');
        expect(loaded.progress, 0.4);
        expect(loaded.sourceLocator, 'original-user-source');
        expect((await stored(id))['cover_image_path'], 'covers/custom_1.png');
      }
    },
  );

  test(
    'cloud import freezes its supplied identity before later edits',
    () async {
      final importerDao = BookDao(
        database: () async => database,
        documentsDirectory: () async => Directory(root),
        importedBookUid: 'cloud:opaque-identity',
      );
      final inserted = await importerDao.insertIfAbsentByHash(book());
      final id = inserted.book.id!;
      expect(
        await stableBookUidForMap(database, await stored(id)),
        'cloud:opaque-identity',
      );
      await dao.updateBook(inserted.book.copyWith(contentHash: 'edited'));
      expect(
        await stableBookUidForMap(database, await stored(id)),
        'cloud:opaque-identity',
      );
    },
  );

  test(
    'duplicate cloud import never reassigns an existing book identity',
    () async {
      final id = await dao.insertBook(book());
      final identity = await stableBookUidForMap(database, await stored(id));
      final importerDao = BookDao(
        database: () async => database,
        documentsDirectory: () async => Directory(root),
        importedBookUid: 'different-cloud-book',
      );
      final existing = await importerDao.insertIfAbsentByHash(book());
      expect(existing.book.id, id);
      expect(await dao.getBooksCount(), 1);
      expect(await stableBookUidForMap(database, await stored(id)), identity);
    },
  );

  test('all DAO read entrypoints resolve managed paths', () async {
    final id = await dao.insertBook(book());
    root = '/relocated/Documents';
    final reads = <Book?>[
      await dao.getBookById(id),
      await dao.getBookByHash('hash'),
      await dao.getBookBySource(
        sourceId: 'source',
        sourceBookId: 'source-book',
      ),
      await dao.getBookBySourceLocator(
        sourceKind: 'file',
        sourceLocator: 'original-user-source',
      ),
      await dao.getBookByFilePath('$root/books/nested/book.epub'),
      (await dao.getBooksByIds([id, id, 999])).single,
      (await dao.getRecentlyReadBooks()).single,
      (await dao.insertIfAbsentByHash(book())).book,
    ];
    for (final loaded in reads) {
      expect(loaded, isNotNull);
      expect(loaded!.filePath, '$root/books/nested/book.epub');
      expect(loaded.coverImagePath, '$root/covers/custom_1.png');
    }
    expect(await dao.getBooksCount(), 1);
  });

  test('full update and individual path writes remain relative', () async {
    final id = await dao.insertBook(book());
    await dao.updateBook(
      (await dao.getBookById(id))!.copyWith(title: 'Renamed'),
    );
    expect((await stored(id))['cover_image_path'], 'covers/custom_1.png');
    await dao.updateBookFilePath(id, '$root/books/replaced.epub');
    await dao.updateBookCoverPath(id, '$root/covers/replaced.png');
    expect((await stored(id))['filePath'], 'books/replaced.epub');
    expect((await stored(id))['cover_image_path'], 'covers/replaced.png');
    await dao.updateBookCoverPath(id, null);
    expect((await stored(id))['cover_image_path'], isNull);
    final inserted = await dao.insertIfAbsentByHash(book(hash: 'another'));
    expect(
      (await stored(inserted.book.id!))['filePath'],
      'books/nested/book.epub',
    );
  });

  test(
    'legacy paths migrate without files, repeat safely, and preserve metadata',
    () async {
      final legacy = book(
        filePath: '$oldIosRoot/books/nested/book.epub',
        coverPath: '$oldIosRoot/covers/custom_1.png',
      );
      final id = await database.insert('books', legacy.toMap());
      // Compatibility decoding also covers old rows restored after schema migration.
      expect(
        (await dao.getBookById(id))!.coverImagePath,
        '$root/covers/custom_1.png',
      );
      await database.transaction(
        (txn) => BookStoragePathMigration.migrate(txn, root),
      );
      final migrated = await stored(id);
      expect(migrated['filePath'], 'books/nested/book.epub');
      expect(migrated['cover_image_path'], 'covers/custom_1.png');
      expect(migrated['currentPage'], 4);
      expect(migrated['source_locator'], 'original-user-source');
      root = '/upgraded-again/Documents';
      await BookStoragePathMigration.migrate(database, root);
      expect(await stored(id), migrated);
      expect(
        (await dao.getBookById(id))!.filePath,
        '$root/books/nested/book.epub',
      );
    },
  );

  test('external paths and URI-backed books are never relocated', () async {
    for (final external in [
      '/user/Documents/books/external.epub',
      'content://provider/books/1',
      'web-book://1',
      'https://example.com/book.epub',
    ]) {
      final id = await dao.insertBook(
        book(filePath: external, coverPath: '/user/cover.png'),
      );
      expect((await stored(id))['filePath'], external);
      expect((await dao.getBookById(id))!.filePath, external);
    }
    final before = await database.query('books');
    await BookStoragePathMigration.migrate(database, root);
    expect(await database.query('books'), before);
  });
}
