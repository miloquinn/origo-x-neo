import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/services/icloud/icloud_sync_controller.dart';
import 'package:xxread/services/icloud/icloud_sync_models.dart';
import 'package:xxread/services/icloud/icloud_sync_store.dart';
import 'package:xxread/services/icloud/icloud_sync_transport.dart';
import 'package:xxread/data/migration/shelf_organization_schema_migration.dart';
import 'support/icloud_v1_legacy_store.dart' as legacy;

void main() {
  late Directory sandbox;

  setUp(() async {
    sqfliteFfiInit();
    sandbox = await Directory.systemTemp.createTemp('icloud-store-');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test(
    'actual v1 store relays organization and upgrade capture adopts it once',
    () async {
      final first = await _replica('new-source');
      final old = await _replica('legacy-relay', organization: false);
      final target = await _replica('new-target');
      addTearDown(first.close);
      addTearDown(old.close);
      addTearDown(target.close);
      final body = File('${first.documents.path}/book.txt')
        ..writeAsStringSync('body');
      await first.database.insert('shelf_folders', {
        'id': 'folder',
        'name': 'Folder',
        'parent_id': null,
        'created_at': 1,
        'sort_index': 1,
      });
      await first.database.insert('books', {
        ..._book(filePath: body.path),
        'shelf_sort_index': 0,
        'last_read_at': 5000,
      });
      final preferences = await SharedPreferences.getInstance();
      final source = DefaultICloudSyncStore(
        database: first.database,
        documents: first.documents,
        preferences: preferences,
      );
      final snapshot = await source.capture();
      final oldStore = legacy.DefaultICloudSyncStore(
        database: old.database,
        documents: old.documents,
        preferences: preferences,
      );
      expect(
        await oldStore.apply(_records(snapshot.values), snapshot.assets),
        isTrue,
      );
      final oldColumns = (await old.database.rawQuery(
        'PRAGMA table_info(books)',
      )).map((row) => row['name']);
      expect(oldColumns, isNot(contains('shelf_sort_index')));
      expect(oldColumns, isNot(contains('last_read_at')));
      final relay = await oldStore.capture();
      final organizationKeys = snapshot.values.keys
          .where((key) => key.startsWith('setting:library_organization_v1_'))
          .toList();
      for (final key in organizationKeys) {
        expect(relay.values[key], snapshot.values[key]);
      }
      final newTarget = DefaultICloudSyncStore(
        database: target.database,
        documents: target.documents,
        preferences: preferences,
      );
      await newTarget.apply(_records(relay.values), relay.assets);
      expect(
        (await target.database.query('books')).single['shelf_sort_index'],
        0,
      );
      expect(
        (await target.database.query('books')).single['last_read_at'],
        5000,
      );
      expect(
        (await target.database.query('shelf_folders')).single['sort_index'],
        1,
      );

      // Simulate the old installation upgrading its DB before the controller's
      // very first capture. No null rank or null recency may replace the relay.
      await ShelfOrganizationSchemaMigration.migrate(old.database);
      final upgraded = DefaultICloudSyncStore(
        database: old.database,
        documents: old.documents,
        preferences: preferences,
      );
      final firstCapture = await upgraded.capture();
      for (final key in organizationKeys) {
        expect(firstCapture.values[key], snapshot.values[key]);
        expect(
          preferences.containsKey(key.substring('setting:'.length)),
          isFalse,
        );
      }
      await old.database.update('books', {
        'shelf_sort_index': 9,
        'last_read_at': 9000,
      });
      final bookKey = organizationKeys.singleWhere(
        (key) =>
            (jsonDecode(snapshot.values[key]!['value']! as String)
                as Map)['kind'] ==
            'book',
      );
      // A retained/retried legacy preference must never replay over a new edit.
      await preferences.setString(
        bookKey.substring('setting:'.length),
        snapshot.values[bookKey]!['value']! as String,
      );
      final nextCapture = await upgraded.capture();
      final metadata =
          jsonDecode(nextCapture.values[bookKey]!['value']! as String) as Map;
      expect(metadata['sortIndex'], 9);
      expect(metadata['lastReadAt'], 9000);
      await old.database.delete('books');
      await old.database.delete('shelf_folders');
      for (final key in organizationKeys) {
        await preferences.setString(
          key.substring('setting:'.length),
          snapshot.values[key]!['value']! as String,
        );
      }
      final withoutOwners = await upgraded.capture();
      expect(
        withoutOwners.values.keys.where(
          (key) => key.startsWith('setting:library_organization_v1_'),
        ),
        isEmpty,
      );
      expect(
        preferences.getKeys().where(
          (key) => key.startsWith('library_organization_v1_'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'organization fields survive stable-id transfer and recency is monotonic',
    () async {
      final first = await _replica('organization-source');
      final second = await _replica('organization-target');
      addTearDown(first.close);
      addTearDown(second.close);
      final body = File('${first.documents.path}/book.txt')
        ..writeAsStringSync('body');
      await first.database.insert('shelf_folders', {
        'id': 'folder',
        'name': 'Folder',
        'parent_id': null,
        'created_at': 1,
        'sort_index': 1,
      });
      await first.database.insert('books', {
        ..._book(filePath: body.path),
        'shelf_sort_index': 0,
        'last_read_at': 5000,
      });
      final preferences = await SharedPreferences.getInstance();
      final source = DefaultICloudSyncStore(
        database: first.database,
        documents: first.documents,
        preferences: preferences,
      );
      final target = DefaultICloudSyncStore(
        database: second.database,
        documents: second.documents,
        preferences: preferences,
      );
      final snapshot = await source.capture();
      await target.apply(_records(snapshot.values), snapshot.assets);
      final restored = (await second.database.query('books')).single;
      expect(restored['shelf_sort_index'], 0);
      expect(restored['last_read_at'], 5000);
      expect(
        (await second.database.query('shelf_folders')).single['sort_index'],
        1,
      );
      await second.database.update('books', {
        'last_read_at': 9000,
        'last_rendered_locator': 'keep-local-rendered',
        'layout_signature': 'keep-local-layout',
      });
      final progressKey = snapshot.values.keys.singleWhere(
        (key) => key.startsWith('progress:'),
      );
      final progress = snapshot.values[progressKey]!;
      await target.apply({
        progressKey: _record(progressKey, progress),
      }, const {});
      final current = (await second.database.query('books')).single;
      expect(current['last_read_at'], 9000);
      expect(current['last_rendered_locator'], 'keep-local-rendered');
      expect(current['layout_signature'], 'keep-local-layout');
      final organizationKey = snapshot.values.keys.singleWhere(
        (key) =>
            key.startsWith('setting:library_organization_v1_') &&
            (jsonDecode(snapshot.values[key]!['value']! as String)
                    as Map)['kind'] ==
                'book',
      );
      await target.apply({
        organizationKey: _record(
          organizationKey,
          snapshot.values[organizationKey]!,
        ),
      }, const {});
      expect(
        (await second.database.query('books')).single['last_read_at'],
        9000,
      );

      await target.apply({
        progressKey: _record(progressKey, {
          ...progress,
          'row': {...Map<String, Object?>.from(progress['row']! as Map)}
            ..remove('last_read_at'),
        }),
      }, const {});
      expect(
        (await second.database.query('books')).single['last_read_at'],
        9000,
      );
      await second.database.update('books', {'shelf_sort_index': 6});
      final relay = snapshot.values[organizationKey]!;
      final metadata =
          Map<String, Object?>.from(
              jsonDecode(relay['value']! as String) as Map,
            )
            ..['parent'] = 'a-different-parent'
            ..['lastReadAt'] = 12000;
      await target.apply({
        organizationKey: _record(organizationKey, {
          ...relay,
          'value': jsonEncode(metadata),
        }),
      }, const {});
      final afterRelay = (await second.database.query('books')).single;
      expect(afterRelay['shelf_sort_index'], 6);
      expect(afterRelay['last_read_at'], 12000);
      await target.apply({
        organizationKey: _record(organizationKey, {
          ...relay,
          'value': jsonEncode({...metadata, 'parent': null, 'sortIndex': null}),
        }),
      }, const {});
      expect(
        (await second.database.query('books')).single['shelf_sort_index'],
        isNull,
      );
    },
  );

  test(
    'organization validators reject invalid ranks and reading timestamps',
    () async {
      final replica = await _replica('invalid-organization');
      addTearDown(replica.close);
      final store = DefaultICloudSyncStore(
        database: replica.database,
        documents: replica.documents,
        preferences: await SharedPreferences.getInstance(),
      );

      final metadata = <String, Object?>{
        'kind': 'book',
        'identity': 'x',
        'parent': null,
        'sortIndex': 0,
        'lastReadAt': 5000,
      };
      final key =
          'library_organization_v1_${sha256.convert(utf8.encode('book\u0000x'))}';
      Future<bool> applyMetadata(Map<String, Object?> value) => store.apply({
        'setting:$key': _record('setting:$key', {
          'kind': 'setting',
          'label': 'Book',
          'key': key,
          'value': jsonEncode(value),
        }),
      }, const {});
      for (final rank in [-1, 1.5, '0']) {
        await expectLater(
          applyMetadata({...metadata, 'sortIndex': rank}),
          throwsFormatException,
        );

        await expectLater(
          store.apply({
            'folder:x': _record('folder:x', {
              'kind': 'folder',
              'label': 'Folder',
              'id': 'x',
              'row': {
                'id': 'x',
                'name': 'Folder',
                'parent_id': null,
                'created_at': 1,
                'sort_index': rank,
              },
            }),
          }, const {}),
          throwsFormatException,
        );
        await expectLater(
          store.apply({
            'book:x': _record('book:x', {
              'kind': 'book',
              'label': 'Book',
              'uid': 'x',
              'row': {..._portableBook(), 'shelf_sort_index': rank},
            }),
          }, const {}),
          throwsFormatException,
        );
      }
      for (final timestamp in [-1, 0, 1.5, '5000']) {
        await expectLater(
          applyMetadata({...metadata, 'lastReadAt': timestamp}),
          throwsFormatException,
        );

        await expectLater(
          store.apply({
            'progress:x': _record('progress:x', {
              'kind': 'progress',
              'label': 'Book',
              'uid': 'x',
              'row': {
                'reading_progress': .5,
                'last_canonical_locator': null,
                'last_read_at': timestamp,
              },
            }),
          }, const {}),
          throwsFormatException,
        );
      }
      expect(await replica.database.query('books'), isEmpty);
      expect(await replica.database.query('shelf_folders'), isEmpty);
    },
  );

  test(
    'two replicas map stable ids and transfer body, cover, and sidecar',
    () async {
      final first = await _replica('first');
      final second = await _replica('second');
      addTearDown(first.close);
      addTearDown(second.close);
      final body = File('${first.documents.path}/books/story.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('第一章\n正文');
      File('${first.documents.path}/covers/story.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3, 4]);
      File(
        '${body.path}.openreading-source.json',
      ).writeAsStringSync('{"source":"test"}');
      final bookId = await first.database.insert(
        'books',
        _book(filePath: 'books/story.txt', coverPath: 'covers/story.png'),
      );
      await first.database.insert('shelf_folders', {
        'id': 'parent',
        'name': 'Parent',
        'parent_id': null,
        'created_at': 1,
      });
      await first.database.update(
        'books',
        {'shelf_folder_id': 'parent'},
        where: 'id = ?',
        whereArgs: [bookId],
      );
      await first.database.insert('bookmarks', {
        'bookId': bookId,
        'pageNumber': 3,
        'note': 'mark',
        'createDate': 1,
        'anchor_key': 'chapter:1:20',
      });
      await first.database.insert('book_notes', {
        'annotation_id': 'annotation-1',
        'book_id': bookId,
        'content': 'quote',
        'cfi': 'epubcfi(/6/2)',
        'chapter': 'One',
        'type': 'highlight',
        'color': 'ffee00',
        'update_time': '2026-10-10T00:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('reader_font_size', 19);
      await prefs.setString('account_token', 'must-not-sync');

      final source = DefaultICloudSyncStore(
        database: first.database,
        documents: first.documents,
        preferences: prefs,
      );
      final snapshot = await source.capture();
      expect(
        snapshot.values.keys,
        containsAll([
          'folder:parent',
          'note:annotation-1',
          'setting:reader_font_size',
        ]),
      );
      expect(snapshot.values.keys, isNot(contains('setting:account_token')));
      expect(snapshot.values['setting:reader_font_size']!['label'], '阅读字号');

      final records = _records(snapshot.values);
      final target = DefaultICloudSyncStore(
        database: second.database,
        documents: second.documents,
        preferences: prefs,
      );
      File('${second.documents.path}/unrelated.txt').writeAsStringSync('other');
      await second.database.insert('books', {
        ..._book(filePath: '${second.documents.path}/unrelated.txt'),
        'title': 'Unrelated',
      });
      expect(await target.apply(records, snapshot.assets), isTrue);
      final restored = (await second.database.query(
        'books',
        where: 'title = ?',
        whereArgs: ['Story'],
      )).single;
      expect(restored['id'], isNot(bookId));
      expect(
        File(restored['filePath'] as String).readAsStringSync(),
        contains('正文'),
      );
      expect(File(restored['cover_image_path'] as String).readAsBytesSync(), [
        1,
        2,
        3,
        4,
      ]);
      expect(
        File(
          '${restored['filePath']}.openreading-source.json',
        ).readAsStringSync(),
        contains('test'),
      );
      final recaptured = await target.capture();
      final syncedBookKey = snapshot.values.keys.singleWhere(
        (key) => key.startsWith('book:'),
      );
      expect(recaptured.values[syncedBookKey], snapshot.values[syncedBookKey]);
      expect(
        (await second.database.query('bookmarks')).single['bookId'],
        restored['id'],
      );
      expect(
        (await second.database.query('book_notes')).single['book_id'],
        restored['id'],
      );
    },
  );

  test(
    'progress and individual bookmark changes preserve unrelated bookmarks',
    () async {
      final replica = await _replica('progress');
      addTearDown(replica.close);
      final body = File('${replica.documents.path}/book.txt')
        ..writeAsStringSync('body');
      final id = await replica.database.insert(
        'books',
        _book(filePath: body.path),
      );
      await replica.database.insert('sync_local_state', {
        'key': 'frozen_book_uid:$id',
        'value': 'book-1',
      });
      await replica.database.insert('bookmarks', {
        'bookId': id,
        'pageNumber': 99,
        'note': 'local-only',
        'createDate': 9,
      });
      await replica.database.insert('reader_pagination_cache', {
        'cache_identity': 'local:$id',
        'book_id': id,
        'book_revision': 'r',
        'layout_fingerprint': 'l',
        'chapter_index': 0,
        'payload': Uint8List.fromList([1]),
        'updated_at': 1,
      });
      final store = DefaultICloudSyncStore(
        database: replica.database,
        documents: replica.documents,
        preferences: await SharedPreferences.getInstance(),
      );
      final records = <String, ICloudRecord>{
        'progress:book-1': _record('progress:book-1', {
          'kind': 'progress',
          'label': 'Story',
          'uid': 'book-1',
          'row': {
            'reading_progress': .4,
            'last_canonical_locator': '{"format":"txt"}',
          },
        }),
        'bookmark:book-1:remote': _record('bookmark:book-1:remote', {
          'kind': 'bookmark',
          'label': 'remote',
          'uid': 'book-1',
          'bookmarkId': 'remote',
          'row': {'pageNumber': 4, 'note': 'remote', 'createDate': 4},
        }),
      };
      await store.apply(records, const {});
      final bookmarks = await replica.database.query('bookmarks');
      expect(
        bookmarks.map((e) => e['note']),
        containsAll(['local-only', 'remote']),
      );
      expect(
        (await replica.database.query('books')).single['reading_progress'],
        .4,
      );
      expect((await replica.database.query('books')).single['currentPage'], 0);
      expect(await replica.database.query('reader_pagination_cache'), isEmpty);
    },
  );

  test(
    'folder deletion promotes direct children and books to its previous parent',
    () async {
      final replica = await _replica('folders');
      addTearDown(replica.close);
      final body = File('${replica.documents.path}/keep.txt')
        ..writeAsStringSync('keep');
      final id = await replica.database.insert(
        'books',
        _book(filePath: body.path),
      );
      await replica.database.insert('sync_local_state', {
        'key': 'frozen_book_uid:$id',
        'value': 'book-1',
      });
      final store = DefaultICloudSyncStore(
        database: replica.database,
        documents: replica.documents,
        preferences: await SharedPreferences.getInstance(),
      );
      await store.apply({
        'folder:grandparent': _record('folder:grandparent', {
          'kind': 'folder',
          'label': 'Grandparent',
          'id': 'grandparent',
          'row': {
            'id': 'grandparent',
            'name': 'Grandparent',
            'parent_id': null,
            'created_at': 1,
          },
        }),
        'folder:child': _record('folder:child', {
          'kind': 'folder',
          'label': 'Child',
          'id': 'child',
          'row': {
            'id': 'child',
            'name': 'Child',
            'parent_id': 'parent',
            'created_at': 2,
          },
        }),
        'folder:parent': _record('folder:parent', {
          'kind': 'folder',
          'label': 'Parent',
          'id': 'parent',
          'row': {
            'id': 'parent',
            'name': 'Parent',
            'parent_id': 'grandparent',
            'created_at': 1,
          },
        }),
      }, const {});
      await replica.database.update(
        'books',
        {'shelf_folder_id': 'parent'},
        where: 'id = ?',
        whereArgs: [id],
      );
      final snapshot = await store.capture();
      final bookKey = snapshot.values.keys.singleWhere(
        (key) => key.startsWith('book:'),
      );
      final promotedBook = Map<String, Object?>.from(snapshot.values[bookKey]!);
      promotedBook['row'] = Map<String, Object?>.from(
        promotedBook['row']! as Map,
      )..['shelf_folder_id'] = 'grandparent';
      await store.apply({
        'folder:child': _record('folder:child', {
          'kind': 'folder',
          'label': 'Child',
          'id': 'child',
          'row': {
            'id': 'child',
            'name': 'Child',
            'parent_id': 'grandparent',
            'created_at': 2,
          },
        }),
        bookKey: _record(bookKey, promotedBook),
        'folder:parent': _tombstone('folder:parent'),
      }, snapshot.assets);
      expect(
        (await replica.database.query(
          'shelf_folders',
          where: 'id = ?',
          whereArgs: ['child'],
        )).single['parent_id'],
        'grandparent',
      );
      expect(
        (await replica.database.query(
          'books',
          where: 'id = ?',
          whereArgs: [id],
        )).single['shelf_folder_id'],
        'grandparent',
      );
      await store.apply({bookKey: _tombstone(bookKey)}, const {});
      expect(await replica.database.query('books'), isEmpty);
      expect(body.existsSync(), isTrue);
    },
  );

  test(
    'captured bookmark binding updates and tombstones the local row',
    () async {
      final replica = await _replica('bookmark-binding');
      addTearDown(replica.close);
      final body = File('${replica.documents.path}/book.txt')
        ..writeAsStringSync('body');
      final id = await replica.database.insert(
        'books',
        _book(filePath: body.path),
      );
      await replica.database.insert('bookmarks', {
        'bookId': id,
        'pageNumber': 1,
        'note': 'before',
        'createDate': 1,
        'anchor_key': 'same-anchor',
      });
      final store = DefaultICloudSyncStore(
        database: replica.database,
        documents: replica.documents,
        preferences: await SharedPreferences.getInstance(),
      );
      final snapshot = await store.capture();
      final key = snapshot.values.keys.singleWhere(
        (candidate) => candidate.startsWith('bookmark:'),
      );
      final changed = Map<String, Object?>.from(snapshot.values[key]!);
      changed['row'] = {
        ...Map<String, Object?>.from(changed['row']! as Map),
        'note': 'after',
      };
      await store.apply({key: _record(key, changed)}, const {});
      expect(await replica.database.query('bookmarks'), hasLength(1));
      expect(
        (await replica.database.query('bookmarks')).single['note'],
        'after',
      );
      await store.apply({key: _tombstone(key)}, const {});
      expect(await replica.database.query('bookmarks'), isEmpty);
    },
  );

  test('online books accept source format and sync chapter progress', () async {
    final first = await _replica('online-first');
    final second = await _replica('online-second');
    addTearDown(first.close);
    addTearDown(second.close);
    final id = await first.database.insert('books', {
      ..._book(filePath: ''),
      'format': 'source',
      'storage_type': 'online',
      'source_id': 'source-a',
      'source_book_id': 'serial-a',
    });
    await first.database.insert('book_source_reading_progress', {
      'source_id': 'source-a',
      'source_book_id': 'serial-a',
      'chapter_id': 'chapter-8',
      'chapter_index': 8,
      'chapter_progress': .25,
      'updated_at': 8,
    });
    await first.database.insert('sync_local_state', {
      'key': 'frozen_book_uid:$id',
      'value': 'source:source-a:serial-a',
    });
    final prefs = await SharedPreferences.getInstance();
    final source = DefaultICloudSyncStore(
      database: first.database,
      documents: first.documents,
      preferences: prefs,
    );
    final snapshot = await source.capture();
    final target = DefaultICloudSyncStore(
      database: second.database,
      documents: second.documents,
      preferences: prefs,
    );
    await target.apply(_records(snapshot.values), snapshot.assets);
    expect((await second.database.query('books')).single['format'], 'source');
    expect(
      (await second.database.query(
        'book_source_reading_progress',
      )).single['chapter_id'],
      'chapter-8',
    );
    final progressKey = snapshot.values.keys.singleWhere(
      (key) => key.startsWith('progress:'),
    );
    final withoutSource = Map<String, Object?>.from(
      snapshot.values[progressKey]!,
    )..remove('sourceProgress');
    await target.apply({
      progressKey: _record(progressKey, withoutSource),
    }, const {});
    expect(
      await second.database.query('book_source_reading_progress'),
      isEmpty,
    );
    expect((await target.capture()).values[progressKey], withoutSource);
  });

  test(
    'malformed schema, unsafe names, and corrupt assets leave database unchanged',
    () async {
      final replica = await _replica('rollback');
      addTearDown(replica.close);
      final store = DefaultICloudSyncStore(
        database: replica.database,
        documents: replica.documents,
        preferences: await SharedPreferences.getInstance(),
      );
      final before = await replica.database.query('books');
      await expectLater(
        store.apply({
          'book:x': _record('book:x', {
            'kind': 'book',
            'label': 'Bad',
            'uid': 'x',
            'row': {
              ..._book(filePath: '')..remove('filePath'),
              'unexpected': 'DROP TABLE books',
            },
          }),
        }, const {}),
        throwsFormatException,
      );
      await expectLater(
        store.apply({
          'book:x': _record('book:x', {
            'kind': 'book',
            'label': 'Bad',
            'uid': 'x',
            'row': _portableBook(),
            'file': List.filled(64, '0').join(),
            'fileName': '../escape.txt',
          }),
        }, const {}),
        throwsFormatException,
      );
      final corrupt = File('${replica.documents.path}/corrupt')
        ..writeAsStringSync('wrong');
      final hash = sha256.convert('right'.codeUnits).toString();
      await expectLater(
        store.apply(
          {
            'book:x': _record('book:x', {
              'kind': 'book',
              'label': 'Bad',
              'uid': 'x',
              'row': _portableBook(),
              'file': hash,
              'fileName': 'safe.txt',
            }),
          },
          {hash: corrupt.path},
        ),
        throwsFormatException,
      );
      expect(await replica.database.query('books'), before);
    },
  );

  test(
    'real stores settle two-controller transfer, merge, and conflict flow',
    () async {
      final first = await _replica('engine-first');
      final second = await _replica('engine-second');
      addTearDown(first.close);
      addTearDown(second.close);
      final body = File('${first.documents.path}/books/中文书名.markdown')
        ..createSync(recursive: true)
        ..writeAsStringSync('正文');
      await first.database.insert('shelf_folders', {
        'id': 'folder-a',
        'name': 'Folder',
        'parent_id': null,
        'created_at': 1,
      });
      final firstBookId = await first.database.insert('books', {
        ..._book(filePath: body.path),
        'format': 'md',
        'shelf_folder_id': 'folder-a',
        'last_canonical_locator': '{"chapterId":"start"}',
      });
      await first.database.insert('bookmarks', {
        'bookId': firstBookId,
        'pageNumber': 1,
        'note': 'initial',
        'createDate': 1,
        'anchor_key': 'initial',
      });

      final preferences = await SharedPreferences.getInstance();
      final cloud = _MemoryCloudTransport();
      final firstStore = DefaultICloudSyncStore(
        database: first.database,
        documents: first.documents,
        preferences: preferences,
      );
      final firstController = ICloudSyncController(
        store: firstStore,
        transport: cloud,
        documents: first.documents,
        preferences: preferences,
        supported: true,
      );
      addTearDown(firstController.dispose);
      await firstController.initialize();
      await firstController.setEnabled(true);
      final firstValues = (await firstStore.capture()).values;

      await preferences.setBool('icloud_sync_enabled_v1', false);
      await preferences.setString(
        'icloud_sync_device_v1',
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      );
      final secondStore = DefaultICloudSyncStore(
        database: second.database,
        documents: second.documents,
        preferences: preferences,
      );
      final secondController = ICloudSyncController(
        store: secondStore,
        transport: cloud,
        documents: second.documents,
        preferences: preferences,
        supported: true,
      );
      addTearDown(secondController.dispose);
      await secondController.initialize();
      await secondController.setEnabled(true);
      expect(
        secondController.error,
        isNull,
        reason: 'status=${secondController.status}',
      );

      final secondValues = (await secondStore.capture()).values;
      for (final entry in firstValues.entries) {
        expect(secondValues[entry.key], entry.value, reason: entry.key);
      }
      final secondBook = (await second.database.query('books')).single;
      final uid =
          (await second.database.query(
                'sync_local_state',
                where: 'key = ?',
                whereArgs: ['frozen_book_uid:${secondBook['id']}'],
              )).single['value']
              as String;

      await second.database.update(
        'books',
        {
          'reading_progress': .25,
          'last_canonical_locator': '{"chapterId":"remote"}',
        },
        where: 'id = ?',
        whereArgs: [secondBook['id']],
      );
      await secondController.synchronize();
      await firstController.synchronize();
      expect(
        (await first.database.query('books')).single['reading_progress'],
        .25,
      );

      await first.database.insert('bookmarks', {
        'bookId': firstBookId,
        'pageNumber': 2,
        'note': 'first-offline',
        'createDate': 2,
        'anchor_key': 'first-offline',
      });
      await second.database.insert('bookmarks', {
        'bookId': secondBook['id'],
        'pageNumber': 3,
        'note': 'second-offline',
        'createDate': 3,
        'anchor_key': 'second-offline',
      });
      await firstController.synchronize();
      await secondController.synchronize();
      await firstController.synchronize();
      expect(
        (await first.database.query('bookmarks')).map((row) => row['note']),
        containsAll(['first-offline', 'second-offline']),
      );
      expect(
        (await second.database.query('bookmarks')).map((row) => row['note']),
        containsAll(['first-offline', 'second-offline']),
      );

      await first.database.update(
        'books',
        {'last_canonical_locator': '{"chapterId":"first-choice"}'},
        where: 'id = ?',
        whereArgs: [firstBookId],
      );
      await second.database.update(
        'books',
        {'last_canonical_locator': '{"chapterId":"second-choice"}'},
        where: 'id = ?',
        whereArgs: [secondBook['id']],
      );
      await firstController.synchronize();
      await secondController.synchronize();
      final conflict = secondController.conflicts.singleWhere(
        (item) => item.key == 'progress:$uid',
      );
      final firstChoice = conflict.versions.singleWhere(
        (record) =>
            (record.value!['row'] as Map)['last_canonical_locator'] ==
            '{"chapterId":"first-choice"}',
      );
      await secondController.resolveConflict(conflict.key, firstChoice);
      await firstController.synchronize();
      await secondController.synchronize();
      expect(firstController.conflicts, isEmpty);
      expect(secondController.conflicts, isEmpty);
      expect(
        (await first.database.query('books')).single['last_canonical_locator'],
        '{"chapterId":"first-choice"}',
      );
      expect(
        (await second.database.query('books')).single['last_canonical_locator'],
        '{"chapterId":"first-choice"}',
      );

      // A deletion racing with live dependent edits becomes one aggregate
      // choice. Nothing on the live replica is removed before that choice.
      final firstRestoredBook = (await first.database.query('books')).single;
      await first.database.delete(
        'books',
        where: 'id = ?',
        whereArgs: [firstRestoredBook['id']],
      );
      await second.database.update(
        'books',
        {
          'reading_progress': .5,
          'last_canonical_locator': '{"chapterId":"keep-book"}',
        },
        where: 'id = ?',
        whereArgs: [secondBook['id']],
      );
      await second.database.insert('bookmarks', {
        'bookId': secondBook['id'],
        'pageNumber': 4,
        'note': 'keep-bookmark',
        'createDate': 4,
        'anchor_key': 'keep-bookmark',
      });
      await second.database.insert('book_notes', {
        'annotation_id': 'keep-note',
        'book_id': secondBook['id'],
        'content': 'keep note',
        'cfi': 'epubcfi(/6/4)',
        'chapter': 'Keep',
        'type': 'highlight',
        'color': 'ffee00',
        'update_time': '2026-10-10T01:00:00.000Z',
      });
      await firstController.synchronize();
      await secondController.synchronize();
      final keepConflict = secondController.conflicts.singleWhere(
        (item) => item.key == 'book:$uid',
      );
      expect(await second.database.query('books'), hasLength(1));
      expect(
        (await second.database.query('bookmarks')).map((row) => row['note']),
        contains('keep-bookmark'),
      );
      expect(
        (await second.database.query(
          'book_notes',
        )).map((row) => row['annotation_id']),
        contains('keep-note'),
      );
      await secondController.resolveConflict(
        keepConflict.key,
        keepConflict.versions.singleWhere((record) => record.value != null),
      );
      await firstController.synchronize();
      await secondController.synchronize();
      expect(firstController.conflicts, isEmpty);
      expect(secondController.conflicts, isEmpty);
      expect(await first.database.query('books'), hasLength(1));
      expect(
        (await first.database.query('bookmarks')).map((row) => row['note']),
        contains('keep-bookmark'),
      );
      expect(
        (await first.database.query(
          'book_notes',
        )).map((row) => row['annotation_id']),
        contains('keep-note'),
      );

      // Repeat the race and choose deletion. The aggregate tombstones must
      // settle both replicas without leaving orphan dependent records.
      final firstKeptBook = (await first.database.query('books')).single;
      final secondKeptBook = (await second.database.query('books')).single;
      await first.database.delete(
        'books',
        where: 'id = ?',
        whereArgs: [firstKeptBook['id']],
      );
      await second.database.update(
        'books',
        {
          'reading_progress': .75,
          'last_canonical_locator': '{"chapterId":"delete-book"}',
        },
        where: 'id = ?',
        whereArgs: [secondKeptBook['id']],
      );
      await second.database.insert('bookmarks', {
        'bookId': secondKeptBook['id'],
        'pageNumber': 5,
        'note': 'delete-bookmark',
        'createDate': 5,
        'anchor_key': 'delete-bookmark',
      });
      await second.database.insert('book_notes', {
        'annotation_id': 'delete-note',
        'book_id': secondKeptBook['id'],
        'content': 'delete note',
        'cfi': 'epubcfi(/6/6)',
        'chapter': 'Delete',
        'type': 'highlight',
        'color': 'ffee00',
        'update_time': '2026-10-10T02:00:00.000Z',
      });
      await firstController.synchronize();
      await secondController.synchronize();
      final deleteConflict = secondController.conflicts.singleWhere(
        (item) => item.key == 'book:$uid',
      );
      expect(await second.database.query('books'), hasLength(1));
      expect(
        (await second.database.query('bookmarks')).map((row) => row['note']),
        contains('delete-bookmark'),
      );
      expect(
        (await second.database.query(
          'book_notes',
        )).map((row) => row['annotation_id']),
        contains('delete-note'),
      );
      await secondController.resolveConflict(
        deleteConflict.key,
        deleteConflict.versions.singleWhere((record) => record.value == null),
      );
      await firstController.synchronize();
      await secondController.synchronize();
      expect(firstController.conflicts, isEmpty);
      expect(secondController.conflicts, isEmpty);
      for (final replica in [first, second]) {
        expect(await replica.database.query('books'), isEmpty);
        expect(await replica.database.query('bookmarks'), isEmpty);
        expect(await replica.database.query('book_notes'), isEmpty);
        expect(
          await replica.database.query('book_source_reading_progress'),
          isEmpty,
        );
      }
    },
  );
}

Map<String, ICloudRecord> _records(Map<String, Map<String, Object?>> values) =>
    {
      for (final entry in values.entries)
        entry.key: _record(entry.key, entry.value),
    };

ICloudRecord _record(String key, Map<String, Object?> value) => ICloudRecord(
  key: key,
  value: value,
  clock: const {'device': 1},
  device: 'device',
  modifiedAt: 1,
);
ICloudRecord _tombstone(String key) => ICloudRecord(
  key: key,
  value: null,
  clock: const {'device': 1},
  device: 'device',
  modifiedAt: 1,
);

Map<String, Object?> _book({required String filePath, String? coverPath}) => {
  'title': 'Story',
  'author': 'Author',
  'filePath': filePath,
  'format': 'txt',
  'currentPage': 0,
  'totalPages': 10,
  'reading_progress': 0.0,
  'importDate': 1,
  'cover_image_path': coverPath,
  'storage_type': 'local',
};

Map<String, Object?> _portableBook() => {
  'title': 'Story',
  'author': 'Author',
  'format': 'txt',
  'importDate': 1,
  'storage_type': 'local',
};

Future<_Replica> _replica(String name, {bool organization = true}) async {
  final root = Directory(
    '${Directory.systemTemp.path}/icloud-store-$name-${DateTime.now().microsecondsSinceEpoch}',
  )..createSync(recursive: true);
  final database = await databaseFactoryFfi.openDatabase(
    '${root.path}/db.sqlite',
    options: OpenDatabaseOptions(
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    ),
  );
  await database.execute('''CREATE TABLE shelf_folders(
    id TEXT PRIMARY KEY, name TEXT NOT NULL, parent_id TEXT,
    created_at INTEGER NOT NULL,
    FOREIGN KEY(parent_id) REFERENCES shelf_folders(id) ON DELETE SET NULL)''');
  await database.execute(
    '''CREATE TABLE books(
    id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, author TEXT,
    filePath TEXT NOT NULL, format TEXT NOT NULL, currentPage INTEGER DEFAULT 0,
    totalPages INTEGER DEFAULT 1, reading_progress REAL, importDate INTEGER NOT NULL,
    content_hash TEXT, table_of_contents TEXT, cover_image_path TEXT, text_encoding TEXT,
    last_canonical_locator TEXT, last_rendered_locator TEXT, layout_signature TEXT,
    storage_type TEXT NOT NULL DEFAULT 'local', source_id TEXT, source_book_id TEXT,
    source_json TEXT, source_book_json TEXT, source_kind TEXT, source_locator TEXT,
    source_modified_time INTEGER, shelf_folder_id TEXT,
    FOREIGN KEY(shelf_folder_id) REFERENCES shelf_folders(id) ON DELETE SET NULL)''',
  );
  if (organization) await ShelfOrganizationSchemaMigration.migrate(database);
  await database.execute('''CREATE TABLE bookmarks(
    id INTEGER PRIMARY KEY AUTOINCREMENT, bookId INTEGER NOT NULL, pageNumber INTEGER NOT NULL,
    note TEXT, createDate INTEGER NOT NULL, cfi TEXT, canonical_locator TEXT,
    anchor_key TEXT, chapter_index INTEGER, chapter_title TEXT, excerpt TEXT,
    FOREIGN KEY(bookId) REFERENCES books(id) ON DELETE CASCADE)''');
  await database.execute('''CREATE TABLE book_notes(
    id INTEGER PRIMARY KEY AUTOINCREMENT, annotation_id TEXT NOT NULL UNIQUE,
    book_id INTEGER NOT NULL, content TEXT NOT NULL, cfi TEXT NOT NULL,
    canonical_locator TEXT, payload_json TEXT, chapter TEXT NOT NULL, type TEXT NOT NULL,
    color TEXT NOT NULL, reader_note TEXT, page_number INTEGER, start_offset INTEGER,
    end_offset INTEGER, create_time TEXT, update_time TEXT NOT NULL,
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE)''');
  await database.execute('''CREATE TABLE book_source_reading_progress(
    source_id TEXT NOT NULL, source_book_id TEXT NOT NULL, chapter_id TEXT NOT NULL,
    chapter_index INTEGER NOT NULL, chapter_progress REAL NOT NULL, updated_at INTEGER NOT NULL,
    PRIMARY KEY(source_id, source_book_id))''');
  await database.execute('''CREATE TABLE reader_pagination_cache(
    cache_identity TEXT NOT NULL, book_id INTEGER, book_revision TEXT NOT NULL,
    layout_fingerprint TEXT NOT NULL, chapter_index INTEGER NOT NULL, payload BLOB NOT NULL,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY(cache_identity, book_revision, layout_fingerprint),
    FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE)''');
  await database.execute(
    'CREATE TABLE sync_local_state(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
  final documents = Directory('${root.path}/Documents')..createSync();
  return _Replica(database, documents, root);
}

class _Replica {
  const _Replica(this.database, this.documents, this.root);
  final Database database;
  final Directory documents;
  final Directory root;
  Future<void> close() async {
    await database.close();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

class _MemoryCloudTransport implements ICloudSyncTransport {
  final Map<String, List<int>> files = {};

  @override
  Future<ICloudTransportStatus> status() async => const ICloudTransportStatus(
    available: true,
    accountId: 'integration-account',
    deviceName: 'Integration device',
  );

  @override
  Future<List<ICloudRemoteFile>> list({required String accountId}) async =>
      files.entries
          .map(
            (entry) => ICloudRemoteFile(
              path: entry.key,
              bytes: entry.value.length,
              uploaded: true,
            ),
          )
          .toList();

  @override
  Future<String> read({
    required String path,
    required String destinationPath,
    required String accountId,
  }) async {
    final destination = File(destinationPath);
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(files[path]!, flush: true);
    return destination.path;
  }

  @override
  Future<ICloudWriteResult> write({
    required String path,
    required String sourcePath,
    required String accountId,
  }) async {
    files[path] = await File(sourcePath).readAsBytes();
    return const ICloudWriteResult(uploaded: true);
  }
}
