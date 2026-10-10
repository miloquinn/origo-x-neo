import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/book_sources/services/book_source_registry_storage.dart';
import 'package:xxread/services/backup/backup_archive.dart';
import 'package:xxread/services/backup/backup_selection.dart';
import 'package:xxread/services/backup/webdav_backup_controller.dart';
import 'package:xxread/services/sync/secure_sync_config.dart';
import 'package:xxread/services/sync/sync_models.dart';
import 'support/local_webdav_server.dart';
import 'package:xxread/data/migration/shelf_organization_schema_migration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
  HttpOverrides.global = null;
  tearDownAll(() => HttpOverrides.global = previousOverrides);
  late Directory documents;
  late Database db;
  late BackupArchive archive;
  late SharedPreferences prefs;
  late _Sources sources;
  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await db.setVersion(25);
    await db.execute(
      'CREATE TABLE books(id INTEGER PRIMARY KEY, title TEXT NOT NULL, filePath TEXT NOT NULL, currentPage INTEGER, reading_progress REAL, last_canonical_locator TEXT, cover_image_path TEXT, storage_type TEXT)',
    );
    await db.execute(
      'CREATE TABLE book_notes(id INTEGER PRIMARY KEY, book_id INTEGER REFERENCES books(id), content TEXT, payload_json TEXT)',
    );
    await db.execute(
      'CREATE TABLE bookmarks(id INTEGER PRIMARY KEY, bookId INTEGER REFERENCES books(id), pageNumber INTEGER)',
    );
    await db.execute(
      'CREATE TABLE reading_stats(id INTEGER PRIMARY KEY, durationInSeconds INTEGER)',
    );
    await db.execute(
      'CREATE TABLE reading_sessions(id INTEGER PRIMARY KEY, bookId INTEGER, durationInSeconds INTEGER)',
    );
    documents = await Directory.systemTemp.createTemp('backup-test-');
    await Directory('${documents.path}/books').create();
    await File('${documents.path}/books/book.txt').writeAsString('原始正文\n第二章');
    await File(
      '${documents.path}/books/book.txt.openreading-source.json',
    ).writeAsString('{"chapters":[]}');
    await db.insert('books', {
      'id': 1,
      'title': '书',
      'filePath': 'books/book.txt',
      'currentPage': 4,
      'reading_progress': 0.4,
      'last_canonical_locator': 'chapter-4',
    });
    await db.insert('book_notes', {
      'id': 1,
      'book_id': 1,
      'content': '笔记',
      'payload_json': '{"strokes":[1,2]}',
    });
    await db.insert('bookmarks', {'id': 1, 'bookId': 1, 'pageNumber': 4});
    await db.insert('reading_stats', {'id': 1, 'durationInSeconds': 123});
    await db.insert('reading_sessions', {
      'id': 1,
      'bookId': 1,
      'durationInSeconds': 123,
    });
    await db.execute(
      'CREATE TABLE sync_local_state(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
    await db.insert('sync_local_state', {
      'key': 'frozen_book_uid:1',
      'value': 'original-stable-identity',
    });
    SharedPreferences.setMockInitialValues({
      'reader_font_size': 22.0,
      'reader_replace_rules_v1': '[]',
      'account_token': 'local-only',
      'webdav_sync_configuration_v1': 'local-only',
      'reader_aloud_cloud_profiles_v1': 'local-only',
    });
    prefs = await SharedPreferences.getInstance();
    sources = _Sources();
    archive = BackupArchive(
      database: db,
      documents: documents,
      preferences: prefs,
      sources: sources,
    );
  });
  tearDown(() async {
    await db.close();
    await documents.delete(recursive: true);
  });

  Future<File> snapshot() async {
    final file = File('${documents.path}/snapshot.zip');
    await archive.create(file);
    return file;
  }

  const folderA = '10000000-0000-4000-8000-000000000001';
  const folderB = '10000000-0000-4000-8000-000000000002';
  const folderC = '10000000-0000-4000-8000-000000000003';
  const folderD = '10000000-0000-7000-8000-000000000004';

  Future<void> enableFolders() async {
    await db.execute(
      'CREATE TABLE shelf_folders(id TEXT PRIMARY KEY, name TEXT NOT NULL, parent_id TEXT REFERENCES shelf_folders(id) ON DELETE SET NULL, created_at INTEGER NOT NULL)',
    );
    await db.execute(
      'ALTER TABLE books ADD COLUMN shelf_folder_id TEXT REFERENCES shelf_folders(id) ON DELETE SET NULL',
    );
    await db.setVersion(28);
  }

  Future<void> addFolder(String id, {String? parent, String name = '同名'}) =>
      db.insert('shelf_folders', {
        'id': id,
        'name': name,
        'parent_id': parent,
        'created_at': 123,
      });

  test(
    'schema 29 preserves organization fields in a backup round trip',
    () async {
      await enableFolders();
      await ShelfOrganizationSchemaMigration.migrate(db);
      await db.setVersion(29);
      await addFolder(folderA);
      await db.update('shelf_folders', {'sort_index': 1});
      await db.update('books', {'shelf_sort_index': 0, 'last_read_at': 5000});
      final zip = await snapshot();
      await db.update('shelf_folders', {'sort_index': 8});
      await db.update('books', {'shelf_sort_index': 7, 'last_read_at': 9000});
      final checked = await archive.validate(zip);
      await archive.restore(checked);
      expect((await db.query('shelf_folders')).single['sort_index'], 1);
      final book = (await db.query('books')).single;
      expect(book['shelf_sort_index'], 0);
      expect(book['last_read_at'], 5000);
      await checked.directory.delete(recursive: true);
    },
  );

  for (final schema in [25, 26, 27, 28]) {
    test('schema 29 accepts existing schema $schema backups', () async {
      if (schema == 28) await enableFolders();
      await db.setVersion(schema);
      final zip = await snapshot();
      if (schema != 28) await enableFolders();
      await ShelfOrganizationSchemaMigration.migrate(db);
      await db.setVersion(29);
      final checked = await archive.validate(zip);
      await archive.restore(checked);
      final book = (await db.query('books')).single;
      expect(book['shelf_sort_index'], isNull);
      expect(book['last_read_at'], isNull);
      await checked.directory.delete(recursive: true);
    });
  }

  Future<File> editManifest(
    File zip,
    void Function(Map<String, dynamic>) edit,
  ) async {
    final decoded = ZipDecoder().decodeBytes(await zip.readAsBytes());
    final data =
        jsonDecode(
              utf8.decode(
                decoded.findFile('backup.json')!.content as List<int>,
              ),
            )
            as Map<String, dynamic>;
    edit(data);
    final updated = Archive();
    for (final entry in decoded.files) {
      if (entry.name != 'backup.json') updated.addFile(entry);
    }
    final manifest = utf8.encode(jsonEncode(data));
    updated.addFile(ArchiveFile('backup.json', manifest.length, manifest));
    final result = File('${documents.path}/edited.zip');
    await result.writeAsBytes(ZipEncoder().encode(updated)!);
    return result;
  }

  test(
    'full restore retains nested and empty folders in parent order',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await addFolder(folderB, parent: folderA);
      await addFolder(folderC, parent: folderB);
      await addFolder(folderD);
      await db.update('books', {'shelf_folder_id': folderC});
      final zip = await editManifest(await snapshot(), (data) {
        data['tables']['shelf_folders'] =
            (data['tables']['shelf_folders'] as List).reversed.toList();
      });
      await db.update('shelf_folders', {'name': 'changed'});
      await db.update('books', {'shelf_folder_id': null});
      final checked = await archive.validate(zip);
      await archive.restore(checked);
      expect(await db.query('shelf_folders'), hasLength(4));
      expect(
        (await db.query(
          'shelf_folders',
          where: 'id = ?',
          whereArgs: [folderC],
        )).single['parent_id'],
        folderB,
      );
      expect(
        (await db.query('shelf_folders')).every((row) => row['name'] == '同名'),
        isTrue,
      );
      expect((await db.query('books')).single['shelf_folder_id'], folderC);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await checked.directory.delete(recursive: true);
    },
  );

  test('valid Unicode folder names survive a backup round trip', () async {
    await enableFolders();
    final name = '😀' * 60;
    await addFolder(folderA, name: name);
    await db.update('books', {'shelf_folder_id': folderA});
    final checked = await archive.validate(await snapshot());
    await db.update('shelf_folders', {'name': 'changed'});
    await archive.restore(checked);
    expect((await db.query('shelf_folders')).single['name'], name);
    expect((await db.query('books')).single['shelf_folder_id'], folderA);
    await checked.directory.delete(recursive: true);
  });

  test('metadata-only backup retains folder graph and memberships', () async {
    await enableFolders();
    await addFolder(folderA);
    await addFolder(folderB, parent: folderA);
    await addFolder(folderC);
    await db.update('books', {'shelf_folder_id': folderB});
    final zip = File('${documents.path}/metadata-folders.zip');
    await archive.create(zip, selection: const BackupSelection());
    final checked = await archive.validate(zip);
    expect(checked.data['files'], isEmpty);
    expect(checked.data['tables']['shelf_folders'], hasLength(3));
    await db.update('books', {'shelf_folder_id': null});
    await archive.restore(checked);
    expect((await db.query('books')).single['shelf_folder_id'], folderB);
    expect((await db.query('books')).single['filePath'], 'books/book.txt');
    await checked.directory.delete(recursive: true);
  });

  test(
    'reading-unselected backup and restore leave folders unchanged',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await db.update('books', {'shelf_folder_id': folderA});
      final zip = File('${documents.path}/settings-folders.zip');
      await archive.create(
        zip,
        selection: const BackupSelection(
          reading: false,
          statistics: false,
          sources: false,
        ),
      );
      final checked = await archive.validate(zip);
      expect(checked.data['tables']['shelf_folders'], isEmpty);
      await db.update('shelf_folders', {'name': 'keep local'});
      await archive.restore(checked);
      expect((await db.query('shelf_folders')).single['name'], 'keep local');
      expect((await db.query('books')).single['shelf_folder_id'], folderA);
      await checked.directory.delete(recursive: true);
    },
  );

  test(
    'selected restore remaps book IDs and keeps stable folder IDs',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await addFolder(folderB, parent: folderA);
      await db.update('books', {'shelf_folder_id': folderB});
      final zip = File('${documents.path}/portable-folders.zip');
      await archive.create(
        zip,
        selection: const BackupSelection(bookIds: {1}, statistics: false),
      );
      await db.delete('book_notes');
      await db.delete('bookmarks');
      await db.delete('books');
      await db.delete('sync_local_state');
      await db.update('shelf_folders', {'name': 'local folder'});
      await db.insert('books', {
        'id': 1,
        'title': 'Other',
        'filePath': 'books/other.txt',
        'shelf_folder_id': folderA,
      });
      for (var count = 0; count < 2; count++) {
        final checked = await archive.validate(zip);
        await archive.restore(checked, selection: const RestoreSelection());
        await checked.directory.delete(recursive: true);
      }
      expect(await db.query('books'), hasLength(2));
      expect(await db.query('shelf_folders'), hasLength(2));
      final restored = (await db.query('books', where: 'id != 1')).single;
      expect(restored['shelf_folder_id'], folderB);
      expect((await db.query('book_notes')).single['book_id'], restored['id']);
      expect(
        (await db.query('books', where: 'id = 1')).single['shelf_folder_id'],
        folderA,
      );
      expect(
        (await db.query(
          'shelf_folders',
        )).every((row) => row['name'] == 'local folder'),
        isTrue,
      );
    },
  );

  test('folder overwrite preserves unrelated book memberships', () async {
    await enableFolders();
    await addFolder(folderA, name: 'archived parent');
    await addFolder(folderB, parent: folderA);
    await addFolder(folderC);
    await addFolder(folderD, parent: folderB);
    await db.update('books', {'shelf_folder_id': folderB});
    final zip = File('${documents.path}/folder-overwrite.zip');
    await archive.create(zip, selection: const BackupSelection());
    await db.update(
      'shelf_folders',
      {'name': 'local parent', 'parent_id': folderC},
      where: 'id = ?',
      whereArgs: [folderA],
    );
    await db.update(
      'shelf_folders',
      {'parent_id': null},
      where: 'id = ?',
      whereArgs: [folderB],
    );
    await db.delete('shelf_folders', where: 'id = ?', whereArgs: [folderD]);
    await db.update('books', {'shelf_folder_id': null});
    await db.insert('books', {
      'id': 2,
      'title': 'Unrelated',
      'filePath': 'books/other.txt',
      'shelf_folder_id': folderA,
    });
    final first = await archive.validate(zip);
    await archive.restore(first, selection: const RestoreSelection());
    expect(
      (await db.query(
        'shelf_folders',
        where: 'id = ?',
        whereArgs: [folderA],
      )).single['name'],
      'local parent',
    );
    expect(
      (await db.query('books', where: 'id = 1')).single['shelf_folder_id'],
      isNull,
    );
    expect(await db.query('shelf_folders'), hasLength(4));
    await first.directory.delete(recursive: true);
    final second = await archive.validate(zip);
    await archive.restore(
      second,
      selection: const RestoreSelection(
        files: false,
        statistics: false,
        sources: false,
        settings: false,
        overwrite: true,
      ),
    );
    final parent = (await db.query(
      'shelf_folders',
      where: 'id = ?',
      whereArgs: [folderA],
    )).single;
    expect(parent['name'], 'archived parent');
    expect(parent['parent_id'], isNull);
    expect(
      (await db.query(
        'shelf_folders',
        where: 'id = ?',
        whereArgs: [folderB],
      )).single['parent_id'],
      folderA,
    );
    expect(
      (await db.query('books', where: 'id = 1')).single['shelf_folder_id'],
      folderB,
    );
    expect(
      (await db.query('books', where: 'id = 2')).single['shelf_folder_id'],
      folderA,
    );
    await second.directory.delete(recursive: true);
  });

  test(
    'explicit null membership clears a folder on selected overwrite',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await db.update('books', {'shelf_folder_id': folderA});
      final zip = File('${documents.path}/root-membership.zip');
      await archive.create(zip, selection: const BackupSelection());
      final edited = await editManifest(zip, (data) {
        (data['tables']['books'] as List).single['shelf_folder_id'] = null;
      });
      final checked = await archive.validate(edited);
      await archive.restore(
        checked,
        selection: const RestoreSelection(overwrite: true),
      );
      expect((await db.query('books')).single['shelf_folder_id'], isNull);
      await checked.directory.delete(recursive: true);
    },
  );

  for (final schema in [25, 26, 27]) {
    for (final version in [1, 2]) {
      test(
        'legacy v$version schema $schema preserves missing membership',
        () async {
          await db.setVersion(schema);
          final zip = File('${documents.path}/legacy.zip');
          await archive.create(
            zip,
            selection: version == 2 ? const BackupSelection() : null,
          );
          await enableFolders();
          await addFolder(folderA);
          await db.update('books', {
            'shelf_folder_id': folderA,
            'currentPage': 88,
          });
          final checked = await archive.validate(zip);
          expect(checked.data['tables']['shelf_folders'], isEmpty);
          expect(
            (checked.data['tables']['books'] as List).single.containsKey(
              'shelf_folder_id',
            ),
            isFalse,
          );
          // v1 fixtures already carry the same stable identity as the local book.
          await archive.restore(
            checked,
            selection: const RestoreSelection(
              files: false,
              statistics: false,
              sources: false,
              settings: false,
              overwrite: true,
            ),
          );
          final book = (await db.query('books')).single;
          expect(book['shelf_folder_id'], folderA);
          expect(book['currentPage'], 4);
          await checked.directory.delete(recursive: true);
        },
      );
    }
  }

  test(
    'legacy full restore creates root books and removes local folders',
    () async {
      final zip = await snapshot();
      await enableFolders();
      await addFolder(folderA);
      await db.update('books', {'shelf_folder_id': folderA});
      final checked = await archive.validate(zip);
      await archive.restore(checked);
      expect(await db.query('shelf_folders'), isEmpty);
      expect((await db.query('books')).single['shelf_folder_id'], isNull);
      await checked.directory.delete(recursive: true);
    },
  );

  test('legacy selected restore creates new books at root', () async {
    final zip = File('${documents.path}/legacy-new-book.zip');
    await archive.create(zip, selection: const BackupSelection());
    await enableFolders();
    await addFolder(folderA);
    await db.delete('book_notes');
    await db.delete('bookmarks');
    await db.delete('books');
    await db.delete('sync_local_state');
    await db.insert('books', {
      'id': 1,
      'title': 'Unrelated',
      'filePath': 'books/other.txt',
      'shelf_folder_id': folderA,
    });
    final checked = await archive.validate(zip);
    await archive.restore(checked, selection: const RestoreSelection());
    expect(
      (await db.query('books', where: 'id != 1')).single['shelf_folder_id'],
      isNull,
    );
    expect(
      (await db.query('books', where: 'id = 1')).single['shelf_folder_id'],
      folderA,
    );
    await checked.directory.delete(recursive: true);
  });

  test(
    'invalid folder archives are rejected without local mutations',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await addFolder(folderB, parent: folderA);
      await db.update('books', {'shelf_folder_id': folderB});
      final zip = await snapshot();
      final cases = <String, void Function(Map<String, dynamic>)>{
        'duplicate IDs': (data) {
          final rows = data['tables']['shelf_folders'] as List;
          rows.add(Map<String, dynamic>.from(rows.first as Map));
        },
        'invalid UUID': (data) =>
            data['tables']['shelf_folders'][0]['id'] = 'bad',
        'blank name': (data) =>
            data['tables']['shelf_folders'][0]['name'] = ' ',
        'invalid timestamp': (data) =>
            data['tables']['shelf_folders'][0]['created_at'] = 1.5,
        'missing parent': (data) =>
            data['tables']['shelf_folders'][0]['parent_id'] = folderC,
        'self parent': (data) =>
            data['tables']['shelf_folders'][0]['parent_id'] = folderA,
        'cycle': (data) =>
            data['tables']['shelf_folders'][0]['parent_id'] = folderB,
        'dangling membership': (data) =>
            data['tables']['books'][0]['shelf_folder_id'] = folderC,
        'unknown column': (data) =>
            data['tables']['shelf_folders'][0]['extra'] = 'bad',
        'missing folder table': (data) =>
            (data['tables'] as Map).remove('shelf_folders'),
        'invalid folder table': (data) => data['tables']['shelf_folders'] = {},
        'future schema': (data) => data['schema'] = 29,
        'unknown legacy schema': (data) => data['schema'] = 24,
      };
      for (final entry in cases.entries) {
        final edited = await editManifest(zip, entry.value);
        await expectLater(
          archive.validate(edited),
          throwsA(isA<FormatException>()),
          reason: entry.key,
        );
      }
      expect(await db.query('shelf_folders'), hasLength(2));
      expect((await db.query('books')).single['shelf_folder_id'], folderB);
    },
  );

  test('selected restore rejects a cyclic merged local hierarchy', () async {
    await enableFolders();
    await addFolder(folderA);
    await addFolder(folderB, parent: folderA);
    final zip = File('${documents.path}/merged-cycle.zip');
    await archive.create(zip, selection: const BackupSelection());
    final checked = await archive.validate(zip);
    await db.update(
      'shelf_folders',
      {'parent_id': folderB},
      where: 'id = ?',
      whereArgs: [folderA],
    );
    await db.update('books', {'currentPage': 88});
    await expectLater(
      archive.restore(checked, selection: const RestoreSelection()),
      throwsA(isA<FormatException>()),
    );
    expect((await db.query('books')).single['currentPage'], 88);
    expect(prefs.getDouble('reader_font_size'), 22);
    await checked.directory.delete(recursive: true);
  });

  test(
    'failed full restore rolls back folder metadata and memberships',
    () async {
      await enableFolders();
      await addFolder(folderA);
      await db.update('books', {'shelf_folder_id': folderA});
      final checked = await archive.validate(await snapshot());
      (checked.data['tables']['book_notes'] as List).first['book_id'] = 999;
      await db.update('shelf_folders', {'name': 'keep local'});
      await db.update('books', {'shelf_folder_id': null, 'currentPage': 88});
      await expectLater(archive.restore(checked), throwsA(anything));
      expect((await db.query('shelf_folders')).single['name'], 'keep local');
      expect((await db.query('books')).single['shelf_folder_id'], isNull);
      expect((await db.query('books')).single['currentPage'], 88);
      expect(prefs.getDouble('reader_font_size'), 22);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      await checked.directory.delete(recursive: true);
    },
  );

  test('fast packing streams progress and omits database caches', () async {
    await db.execute('ALTER TABLE books ADD COLUMN cached_content TEXT');
    await db.update('books', {'cached_content': 'x' * (1024 * 1024)});
    await File(
      '${documents.path}/books/book.txt',
    ).writeAsString('a' * (8 * 1024 * 1024));
    final zip = File('${documents.path}/fast.zip');
    final updates = <int>[];
    final watch = Stopwatch()..start();
    await archive.create(
      zip,
      selection: const BackupSelection(bookIds: {1}),
      onProgress: (done, total) => updates.add(done),
    );
    watch.stop();
    // Intermediate updates occur before the complete book has been packed.
    expect(updates.any((v) => v > 0 && v < updates.last), isTrue);
    final checked = await archive.validate(zip);
    expect(
      (checked.data['tables']['books'] as List).single['cached_content'],
      isNull,
    );
    expect(
      await File('${checked.directory.path}/books/1.txt').length(),
      8 * 1024 * 1024,
    );
    // Diagnostic only: never turn host speed into a flaky correctness assertion.
    debugPrint('8 MiB fast ZIP: ${watch.elapsedMilliseconds} ms');
    await checked.directory.delete(recursive: true);
  });

  test(
    'restore choices preserve existing data unless overwrite is enabled',
    () async {
      final zip = File('${documents.path}/restore-options.zip');
      await archive.create(zip, selection: const BackupSelection(bookIds: {1}));
      await db.update('books', {'currentPage': 88});
      await prefs.setDouble('reader_font_size', 44);
      await db.update('book_notes', {'content': 'keep current'});
      final first = await archive.validate(zip);
      await archive.restore(first, selection: const RestoreSelection());
      expect((await db.query('books')).single['currentPage'], 88);
      expect((await db.query('book_notes')).single['content'], 'keep current');
      expect(prefs.getDouble('reader_font_size'), 44);
      await first.directory.delete(recursive: true);
      final second = await archive.validate(zip);
      await archive.restore(
        second,
        selection: const RestoreSelection(
          reading: false,
          statistics: false,
          sources: false,
          settings: true,
          overwrite: true,
        ),
      );
      expect(prefs.getDouble('reader_font_size'), 22);
      expect((await db.query('books')).single['currentPage'], 88);
      await second.directory.delete(recursive: true);
      final third = await archive.validate(zip);
      await archive.restore(
        third,
        selection: const RestoreSelection(
          files: false,
          statistics: false,
          sources: false,
          settings: false,
          overwrite: true,
        ),
      );
      expect((await db.query('books')).single['currentPage'], 4);
      expect((await db.query('books')).single['filePath'], 'books/book.txt');
      await third.directory.delete(recursive: true);
    },
  );

  test(
    'selection excludes large unselected files and preserves omitted categories',
    () async {
      final huge = File('${documents.path}/books/huge.bin');
      final handle = await huge.open(mode: FileMode.write);
      await handle.truncate(3 * 1024 * 1024 * 1024);
      await handle.close();
      await db.insert('books', {
        'id': 2,
        'title': 'Large',
        'filePath': 'books/huge.bin',
        'currentPage': 7,
      });
      final inventory = await archive.inventory();
      expect(
        inventory.singleWhere((b) => b.id == 2).bytes,
        3 * 1024 * 1024 * 1024,
      );
      final zip = File('${documents.path}/selected.zip');
      final packed = <int>[];
      await archive.create(
        zip,
        selection: const BackupSelection(
          bookIds: {1},
          sources: false,
          settings: false,
          statistics: false,
        ),
        onProgress: (done, total) {
          packed.add(done);
        },
      );
      expect(await zip.length(), lessThan(100000));
      expect(packed, isNotEmpty);
      final checked = await archive.validate(zip);
      expect((checked.data['files'] as Map).keys, contains('books/1.txt'));
      expect(
        (checked.data['files'] as Map).keys.any(
          (k) => k.toString().contains('2.bin'),
        ),
        isFalse,
      );
      await db.update('books', {'currentPage': 99}, where: 'id = 1');
      await db.insert('books', {
        'id': 3,
        'title': 'Unrelated',
        'filePath': 'books/other.txt',
      });
      await prefs.setDouble('reader_font_size', 33);
      sources.raw = '{"version":2,"sources":[],"groups":["keep"]}';
      await db.update('reading_stats', {'durationInSeconds': 999});
      await archive.restore(checked);
      expect(
        (await db.query('books', where: 'id = 1')).single['currentPage'],
        4,
      );
      expect(
        (await db.query('books', where: 'id = 2')).single['filePath'],
        'books/huge.bin',
      );
      expect(
        (await db.query('books', where: 'id = 3')).single['title'],
        'Unrelated',
      );
      expect(prefs.getDouble('reader_font_size'), 33);
      expect(sources.raw, contains('keep'));
      expect(
        (await db.query('reading_stats')).single['durationInSeconds'],
        999,
      );
      await checked.directory.delete(recursive: true);
    },
  );

  test(
    'metadata-only default excludes files and tolerates unavailable originals',
    () async {
      await File('${documents.path}/books/book.txt').delete();
      final zip = File('${documents.path}/metadata.zip');
      await archive.create(zip, selection: const BackupSelection());
      final checked = await archive.validate(zip);
      expect(checked.data['files'], isEmpty);
      await db.update('books', {'currentPage': 88});
      await archive.restore(checked);
      expect((await db.query('books')).single['currentPage'], 4);
      expect((await db.query('books')).single['filePath'], 'books/book.txt');
      await checked.directory.delete(recursive: true);
    },
  );

  test(
    'selected restore remaps colliding book and note IDs on another library',
    () async {
      final zip = File('${documents.path}/portable.zip');
      await archive.create(
        zip,
        selection: const BackupSelection(bookIds: {1}, statistics: false),
      );
      final checked = await archive.validate(zip);
      await db.delete('book_notes');
      await db.delete('bookmarks');
      await db.delete('books');
      await db.delete('sync_local_state');
      await db.insert('books', {
        'id': 1,
        'title': 'Other',
        'filePath': 'books/other.txt',
      });
      await db.insert('book_notes', {'id': 1, 'book_id': 1, 'content': 'Keep'});
      await archive.restore(checked);
      final restored = (await db.query('books', where: 'id != 1')).single;
      expect(
        (await db.query('books', where: 'id = 1')).single['title'],
        'Other',
      );
      expect(
        (await db.query('book_notes', where: 'book_id = 1')).single['content'],
        'Keep',
      );
      expect(
        (await db.query(
          'book_notes',
          where: 'book_id = ?',
          whereArgs: [restored['id']],
        )).single['payload_json'],
        '{"strokes":[1,2]}',
      );
      // Repeating the same snapshot updates the same book rather than duplicating it.
      final again = await archive.validate(zip);
      await archive.restore(again);
      expect(await db.query('books'), hasLength(2));
      await checked.directory.delete(recursive: true);
      await again.directory.delete(recursive: true);
    },
  );

  test(
    'settings-only restore leaves the entire library and sources unchanged',
    () async {
      final zip = File('${documents.path}/settings.zip');
      await archive.create(
        zip,
        selection: const BackupSelection(
          reading: false,
          statistics: false,
          sources: false,
        ),
      );
      final checked = await archive.validate(zip);
      expect((checked.data['tables'] as Map)['books'], isEmpty);
      await db.update('books', {'currentPage': 77});
      await prefs.setDouble('reader_font_size', 44);
      await archive.restore(checked);
      expect((await db.query('books')).single['currentPage'], 77);
      expect(prefs.getDouble('reader_font_size'), 22);
      expect(await db.query('book_notes'), hasLength(1));
      await checked.directory.delete(recursive: true);
    },
  );

  test(
    'ZIP restores books, progress, notes, sources and settings with portable paths',
    () async {
      final zip = await snapshot();
      await db.update('books', {'currentPage': 9});
      await db.delete('book_notes');
      await prefs.setDouble('reader_font_size', 12);
      await prefs.setString('reader_new_setting', 'remove-me');
      sources.raw = '{"version":2,"sources":[],"groups":["changed"]}';
      final checked = await archive.validate(zip);
      try {
        await archive.restore(checked);
      } finally {
        await checked.directory.delete(recursive: true);
      }
      final book = (await db.query('books')).single;
      expect(book['currentPage'], 4);
      expect(
        (await db.query('sync_local_state')).single['value'],
        'original-stable-identity',
      );
      expect(book['last_canonical_locator'], 'chapter-4');
      expect(book['filePath'], startsWith('books/restored-'));
      expect(
        await File('${documents.path}/${book['filePath']}').readAsString(),
        '原始正文\n第二章',
      );
      expect(
        await File(
          '${documents.path}/${book['filePath']}.openreading-source.json',
        ).exists(),
        isTrue,
      );
      expect(
        (await db.query('book_notes')).single['payload_json'],
        '{"strokes":[1,2]}',
      );
      expect((await db.query('bookmarks')).single['pageNumber'], 4);
      expect(
        (await db.query('reading_stats')).single['durationInSeconds'],
        123,
      );
      expect(prefs.getDouble('reader_font_size'), 22);
      expect(prefs.containsKey('reader_new_setting'), isFalse);
      expect(prefs.getString('account_token'), 'local-only');
      expect(sources.raw, contains('收藏'));
      expect(await File('${documents.path}/books/book.txt').exists(), isTrue);
    },
  );
  test(
    'online bookshelf and online progress restore without local files',
    () async {
      await db.insert('books', {
        'id': 2,
        'title': '在线书',
        'filePath': '',
        'storage_type': 'online',
        'currentPage': 12,
      });
      await prefs.setString('source_reading_progress_book', '{"chapter":12}');
      final zip = await snapshot();
      await db.delete('books', where: 'id = 2');
      final checked = await archive.validate(zip);
      await archive.restore(checked);
      expect(
        (await db.query('books', where: 'id = 2')).single['currentPage'],
        12,
      );
      expect((await db.query('books', where: 'id = 2')).single['filePath'], '');
      await checked.directory.delete(recursive: true);
    },
  );
  for (final committed in [false, true]) {
    test(
      'interrupted restore repairs settings according to SQLite commit $committed',
      () async {
        await db.execute(
          'CREATE TABLE backup_restore_commit(id TEXT PRIMARY KEY)',
        );
        if (committed) {
          await db.insert('backup_restore_commit', {'id': 'operation'});
        }
        final journal = File('${documents.path}/backups/restore-pending.json');
        await journal.parent.create();
        await journal.writeAsString(
          jsonEncode({
            'id': 'operation',
            'before': {
              'preferences': {'reader_font_size': 12.0},
              'sources': sources.raw,
            },
            'after': {
              'preferences': {'reader_font_size': 22.0},
              'sources': sources.raw,
            },
          }),
        );
        await archive.recoverInterruptedRestore();
        expect(prefs.getDouble('reader_font_size'), committed ? 22.0 : 12.0);
        expect(await journal.exists(), isFalse);
      },
    );
  }
  test('restore works in a different documents directory', () async {
    final zip = await snapshot();
    final second = await Directory.systemTemp.createTemp('backup-second-');
    addTearDown(() => second.delete(recursive: true));
    final target = BackupArchive(
      database: db,
      documents: second,
      preferences: prefs,
      sources: sources,
    );
    final checked = await target.validate(zip);
    await target.restore(checked);
    await checked.directory.delete(recursive: true);
    final row = (await db.query('books')).single;
    expect(await File('${second.path}/${row['filePath']}').exists(), isTrue);
  });
  test(
    'corrupt and traversal archives are rejected without changing local data',
    () async {
      final zip = await snapshot();
      for (final name in [
        '../escape.txt',
        'books/../../escape.txt',
        'books/evil',
      ]) {
        final contents = ZipDecoder().decodeBytes(await zip.readAsBytes());
        contents.addFile(ArchiveFile(name, 3, [1, 2, 3]));
        final corrupt = File('${documents.path}/corrupt.zip');
        await corrupt.writeAsBytes(ZipEncoder().encode(contents)!);
        await expectLater(
          archive.validate(corrupt),
          throwsA(isA<FormatException>()),
        );
        expect((await db.query('books')).single['currentPage'], 4);
      }
    },
  );
  test(
    'foreign-key failure rolls back all database rows and leaves settings intact',
    () async {
      final zip = await snapshot();
      final checked = await archive.validate(zip);
      (checked.data['tables']['book_notes'] as List).first['book_id'] = 999;
      await db.update('books', {'currentPage': 8});
      await expectLater(archive.restore(checked), throwsA(anything));
      expect((await db.query('books')).single['currentPage'], 8);
      expect((await db.query('book_notes')).single['content'], '笔记');
      expect(prefs.getDouble('reader_font_size'), 22);
      await checked.directory.delete(recursive: true);
    },
  );
  test(
    'missing books fail backup instead of silently producing an incomplete ZIP',
    () async {
      await File('${documents.path}/books/book.txt').delete();
      await expectLater(snapshot(), throwsA(isA<FileSystemException>()));
    },
  );
  test(
    'secrets and connection settings are absent from the ZIP manifest',
    () async {
      final zip = await snapshot();
      final decoded = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final manifest = utf8.decode(
        decoded.findFile('backup.json')!.content as List<int>,
      );
      expect(manifest, isNot(contains('local-only')));
    },
  );
  test(
    'real DAV without ETags or OPTIONS keeps snapshots and restores an earlier one',
    () async {
      final server = await LocalWebDavServer.start();
      addTearDown(server.close);
      server.rejectHead = true;
      server.rejectOptions = true;
      final controller = WebDavBackupController(
        configStore: SecureSyncConfigStore(
          secretStorage: _Secrets(),
          preferences: _Preferences(),
        ),
        archiveFactory: () async => archive,
      );
      addTearDown(controller.dispose);
      final draft = WebDavSyncConfigDraft(
        serverUrl: server.url,
        username: 'reader',
        password: 'secret',
        allowInsecurePrivateHttp: true,
      );
      expect((await controller.testConnection(draft)).success, isTrue);
      await controller.configure(draft);
      await controller.prepareDefaultBookSelection();
      expect(controller.selection.bookIds, contains(1));
      expect(
        server.puts,
        1,
      ); // Connection probe only: configuration never backs up.
      final stages = <String>{};
      var sawUploadBytes = false;
      controller.addListener(() {
        stages.add(controller.stage);
        if (controller.stage == 'uploading' && controller.completedBytes > 0) {
          sawUploadBytes = true;
        }
      });
      await controller.backup();
      expect(
        stages,
        containsAll(['packing', 'verifying', 'uploading', 'finishing']),
      );
      expect(sawUploadBytes, isTrue);
      expect(controller.bytesPerSecond, 0);
      expect(controller.stage, isEmpty);
      await db.update('books', {'currentPage': 8});
      await controller.backup();
      await controller.refresh();
      expect(controller.backups, hasLength(2));
      controller.setSelection(const BackupSelection());
      await controller.prepareDefaultBookSelection();
      expect(controller.selection.bookIds, isEmpty);
      await File('${documents.path}/books/book.txt').delete();
      controller.restoreSelection = const RestoreSelection(overwrite: true);
      await controller.restore(controller.backups.last);
      expect((await db.query('books')).single['currentPage'], 4);
      final restoredBookPath =
          (await db.query('books')).single['filePath'] as String;
      expect(
        await File('${documents.path}/$restoredBookPath').readAsString(),
        '原始正文\n第二章',
      );
      expect(await File(controller.recoveryPath!).exists(), isTrue);
      expect(
        server.requests.any(
          (r) =>
              r.startsWith('OPTIONS') ||
              r.startsWith('MOVE') ||
              r.startsWith('HEAD'),
        ),
        isFalse,
      );
      final incomplete = File(
        '${server.root.path}/OrigoX/backups/origo-x-123-abcdef.zip',
      );
      await incomplete.writeAsString('partial');
      await controller.refresh();
      expect(controller.backups, hasLength(2));
      server.failNextPut = true;
      await expectLater(controller.backup(), throwsA(isA<WebDavSyncFailure>()));
      expect(controller.busy, isFalse);
      await controller.refresh();
      expect(controller.backups, hasLength(2));
    },
  );
}

class _Sources implements BookSourceRegistryStorage {
  String raw =
      '{"version":2,"sources":[{"id":"source1","name":"书源","manifestUrl":"https://example.test/manifest","apiBaseUrl":"https://example.test/api","protocolVersion":"1.0"}],"groups":["收藏"]}';
  @override
  Future<String?> read() async => raw;
  @override
  Future<bool> write(String value) async {
    raw = value;
    return true;
  }
}

class _Secrets implements SyncSecretStorage {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}

class _Preferences implements SyncPreferences {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }
}
