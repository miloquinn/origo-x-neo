// Frozen v1 iCloud Store from 4f2eec6c15211318bf4179827064f91b2b19e58f.
// Original SHA256: c171c8e3289ba27e0c956ff5216a356ee8eb8f304a30552f6f790a7e1ea1a10c
// Only imports were made package-relative for this self-contained compatibility fixture.
// Keep the parser, capture and apply contracts unchanged: tests exercise the actual old reader.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:xxread/core/reader/canonical_locator.dart';
import 'package:xxread/services/books/book_storage_paths.dart';
import 'package:xxread/services/sync/book_sync_identity.dart';
import 'package:xxread/services/icloud/icloud_sync_models.dart';

/// SQLite, preferences, and local-file boundary for iCloud sync.
///
/// Cloud values contain stable identities and portable metadata only. Local
/// integer keys, paths, rendered locations, and derived caches never leave the
/// device.
class DefaultICloudSyncStore implements ICloudSyncStore {
  DefaultICloudSyncStore({
    required this.database,
    required this.documents,
    required this.preferences,
  });

  final Database database;
  final Directory documents;
  final SharedPreferences preferences;

  static const _stateTable = 'sync_local_state';
  static const _bodyStatePrefix = 'icloud_asset:file:';
  static const _coverStatePrefix = 'icloud_asset:cover:';
  static const _sidecarStatePrefix = 'icloud_asset:sidecar:';
  static const _bookmarkStatePrefix = 'icloud_bookmark:';
  static const _hashStatePrefix = 'icloud_hash:';

  static const _bookColumns = <String>{
    'title',
    'author',
    'format',
    'importDate',
    'content_hash',
    'table_of_contents',
    'text_encoding',
    'storage_type',
    'source_id',
    'source_book_id',
    'source_json',
    'source_book_json',
    'source_kind',
    'source_locator',
    'source_modified_time',
    'shelf_folder_id',
  };
  static const _progressColumns = <String>{
    'reading_progress',
    'last_canonical_locator',
  };
  static const _bookmarkColumns = <String>{
    'pageNumber',
    'note',
    'createDate',
    'cfi',
    'canonical_locator',
    'anchor_key',
    'chapter_index',
    'chapter_title',
    'excerpt',
  };
  static const _noteColumns = <String>{
    'content',
    'cfi',
    'canonical_locator',
    'payload_json',
    'chapter',
    'type',
    'color',
    'reader_note',
    'page_number',
    'start_offset',
    'end_offset',
    'create_time',
    'update_time',
  };
  static const _sourceProgressColumns = <String>{
    'source_id',
    'source_book_id',
    'chapter_id',
    'chapter_index',
    'chapter_progress',
  };

  @override
  Future<ICloudLocalSnapshot> capture() async {
    await _ensureStateTable(database);
    final values = <String, Map<String, Object?>>{};
    final assets = <String, String>{};
    final paths = BookStoragePaths(documents.path);
    // Freeze identities before taking the short metadata snapshot. First-time
    // identity assignment may hash a book and must not hold a SQLite lock.
    for (final raw in await database.query('books')) {
      final row = Map<String, Object?>.from(raw);
      await stableBookUidForMap(database, {
        ...row,
        if (row['filePath'] is String)
          'filePath': paths.decode(row['filePath']! as String),
      });
    }
    for (final raw in await database.query('bookmarks')) {
      final row = Map<String, Object?>.from(raw);
      if ((row['anchor_key'] as String?)?.trim().isEmpty != false) {
        final id = _requiredInt(row, 'id');
        final key = '$_bookmarkStatePrefix$id';
        if (await _stateValue(database, key) == null) {
          await _putState(database, key, const Uuid().v4());
        }
      }
    }
    final snapshot = await _captureDatabaseRows();
    final bookRows = snapshot['books']!;
    final uidById = <int, String>{
      for (final state in snapshot['identities']!)
        int.parse(
          (state['key'] as String).substring('frozen_book_uid:'.length),
        ): state['value'] as String,
    };
    final sourceProgressByKey = <String, Map<String, Object?>>{
      for (final row in snapshot['sourceProgress']!)
        '${row['source_id']}\u0000${row['source_book_id']}': row,
    };

    for (final raw in bookRows) {
      final row = Map<String, Object?>.from(raw);
      final id = _requiredInt(row, 'id');
      final uid = uidById[id];
      if (uid == null) {
        throw StateError('Book identity changed during iCloud capture');
      }
      final title = _requiredString(row, 'title');
      final storageType = (row['storage_type'] as String?) ?? 'local';
      final value = <String, Object?>{
        'kind': 'book',
        'label': title,
        'uid': uid,
        'row': {
          for (final key in _bookColumns)
            if (row.containsKey(key)) key: row[key],
        },
      };
      if (storageType != 'online') {
        final bodyPath = paths.decode(_requiredString(row, 'filePath'));
        final body = await _captureAsset(
          uid: uid,
          role: 'file',
          path: bodyPath,
          cloudName: _bodyCloudName(bodyPath, row['format'] as String),
          required: true,
          assets: assets,
        );
        value.addAll(body);
        final coverRaw = row['cover_image_path'];
        if (coverRaw is String && coverRaw.isNotEmpty) {
          value.addAll(
            await _captureAsset(
              uid: uid,
              role: 'cover',
              path: paths.decode(coverRaw),
              cloudName: _coverCloudName(paths.decode(coverRaw)),
              required: false,
              assets: assets,
            ),
          );
        }
        value.addAll(
          await _captureAsset(
            uid: uid,
            role: 'sidecar',
            path: '$bodyPath.openreading-source.json',
            cloudName:
                '${_bodyCloudName(bodyPath, row['format'] as String)}.openreading-source.json',
            required: false,
            assets: assets,
          ),
        );
      }
      values['book:$uid'] = value;
      final progress = <String, Object?>{
        for (final key in _progressColumns)
          if (row.containsKey(key)) key: row[key],
      };
      Map<String, Object?>? sourceProgress;
      final sourceId = row['source_id'];
      final sourceBookId = row['source_book_id'];
      if (sourceId is String &&
          sourceId.isNotEmpty &&
          sourceBookId is String &&
          sourceBookId.isNotEmpty) {
        final rawSource = sourceProgressByKey['$sourceId\u0000$sourceBookId'];
        if (rawSource != null) {
          sourceProgress = {
            for (final key in _sourceProgressColumns) key: rawSource[key],
          };
        }
      }
      values['progress:$uid'] = {
        'kind': 'progress',
        'label': title,
        'uid': uid,
        'row': progress,
        'sourceProgress': ?sourceProgress,
      };
    }

    if (snapshot['folders']!.isNotEmpty) {
      for (final raw in snapshot['folders']!) {
        final row = Map<String, Object?>.from(raw);
        final id = _requiredString(row, 'id');
        values['folder:$id'] = {
          'kind': 'folder',
          'label': _requiredString(row, 'name'),
          'id': id,
          'row': row,
        };
      }
    }
    for (final raw in snapshot['bookmarks']!) {
      final row = Map<String, Object?>.from(raw);
      final bookId = _requiredInt(row, 'bookId');
      final uid = uidById[bookId];
      if (uid == null) throw const FormatException('Bookmark has no book');
      final anchor = await _bookmarkIdentity(row, uid);
      await _putState(
        database,
        'icloud_bookmark_remote:$uid:$anchor',
        '${row['id']}',
      );
      values['bookmark:$uid:$anchor'] = {
        'kind': 'bookmark',
        'label': (row['note'] as String?)?.trim().isNotEmpty == true
            ? row['note']
            : 'Bookmark',
        'uid': uid,
        'bookmarkId': anchor,
        'row': {
          for (final key in _bookmarkColumns)
            if (row.containsKey(key)) key: row[key],
        },
      };
    }
    for (final raw in snapshot['notes']!) {
      final row = Map<String, Object?>.from(raw);
      final uid = uidById[_requiredInt(row, 'book_id')];
      if (uid == null) throw const FormatException('Annotation has no book');
      final annotationId = _requiredString(row, 'annotation_id');
      values['note:$annotationId'] = {
        'kind': 'note',
        'label': (row['reader_note'] as String?)?.trim().isNotEmpty == true
            ? row['reader_note']
            : 'Note',
        'uid': uid,
        'annotationId': annotationId,
        'row': {
          for (final key in _noteColumns)
            if (row.containsKey(key)) key: row[key],
        },
      };
    }
    if (!await _databaseRowsUnchanged(snapshot)) {
      throw StateError('Library changed during iCloud capture; retry');
    }
    for (final key in preferences.getKeys()) {
      final value = preferences.get(key);
      if (!_portablePreference(key, value)) continue;
      if (!_isPreferenceValue(value)) continue;
      values['setting:$key'] = {
        'kind': 'setting',
        'label': _settingLabel(key),
        'key': key,
        'value': value,
      };
    }
    return ICloudLocalSnapshot(values, assets);
  }

  Future<Map<String, List<Map<String, Object?>>>> _captureDatabaseRows() =>
      database.transaction((tx) async {
        final hasFolders = await _tableExists(tx, 'shelf_folders');
        final hasSourceProgress = await _tableExists(
          tx,
          'book_source_reading_progress',
        );
        return <String, List<Map<String, Object?>>>{
          'books': await tx.query('books'),
          'folders': hasFolders ? await tx.query('shelf_folders') : const [],
          'bookmarks': await tx.query('bookmarks'),
          'notes': await tx.query('book_notes'),
          'sourceProgress': hasSourceProgress
              ? await tx.query('book_source_reading_progress')
              : const [],
          'identities': await tx.query(
            _stateTable,
            where: 'key LIKE ?',
            whereArgs: ['frozen_book_uid:%'],
          ),
        };
      });

  Future<bool> _databaseRowsUnchanged(
    Map<String, List<Map<String, Object?>>> before,
  ) async {
    final after = await _captureDatabaseRows();
    for (final key in before.keys) {
      if (syncCanonicalJson(before[key]) != syncCanonicalJson(after[key])) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<bool> apply(
    Map<String, ICloudRecord> records,
    Map<String, String> assets,
  ) async {
    await _ensureStateTable(database);
    final parsed = <_Incoming>[];
    for (final entry in records.entries) {
      if (entry.key != entry.value.key) {
        throw const FormatException('Record key mismatch');
      }
      parsed.add(_validateIncoming(entry.value));
    }
    await _validateFolderGraph(parsed);
    final verifiedAssets = await _verifyAssets(parsed, assets);
    final preferenceBefore = <String, Object?>{};
    for (final item in parsed.where((e) => e.kind == 'setting')) {
      preferenceBefore[item.identity] = preferences.get(item.identity);
    }
    var changed = false;
    try {
      await database.transaction((tx) async {
        final uidToId = await _bookIdsByUid(tx);
        for (final item in await _orderedFolderUpserts(tx, parsed)) {
          changed = await _upsertFolder(tx, item) || changed;
        }
        for (final item in parsed.where((e) => e.kind == 'book')) {
          changed =
              await _applyBook(tx, item, uidToId, verifiedAssets) || changed;
        }
        for (final item in parsed.where((e) => e.kind == 'progress')) {
          changed = await _applyProgress(tx, item, uidToId) || changed;
        }
        for (final item in parsed.where((e) => e.kind == 'bookmark')) {
          changed = await _applyBookmark(tx, item, uidToId) || changed;
        }
        for (final item in parsed.where((e) => e.kind == 'note')) {
          changed = await _applyNote(tx, item, uidToId) || changed;
        }
        for (final item in parsed.where(
          (e) => e.kind == 'folder' && e.deleted,
        )) {
          changed =
              (await tx.delete(
                    'shelf_folders',
                    where: 'id = ?',
                    whereArgs: [item.identity],
                  )) >
                  0 ||
              changed;
        }
        if ((await tx.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
          throw const FormatException('Invalid iCloud references');
        }
      });
      for (final item in parsed.where((e) => e.kind == 'setting')) {
        changed = await _applySetting(item) || changed;
      }
      return changed;
    } catch (_) {
      for (final entry in preferenceBefore.entries) {
        await _writePreference(entry.key, entry.value);
      }
      rethrow;
    }
  }

  Future<Map<String, Object?>> _captureAsset({
    required String uid,
    required String role,
    required String path,
    required String cloudName,
    required bool required,
    required Map<String, String> assets,
  }) async {
    final file = File(path);
    final stateKey =
        '${switch (role) {
          'file' => _bodyStatePrefix,
          'cover' => _coverStatePrefix,
          _ => _sidecarStatePrefix,
        }}$uid';
    if (!await file.exists()) {
      final known = await _stateValue(database, stateKey);
      if (known != null && _isHash(known)) return {role: known};
      if (required) {
        throw FileSystemException(
          'Local book file is unavailable for iCloud sync',
          path,
        );
      }
      return const {};
    }
    final digest = await _hashStableFile(file);
    await _putState(database, stateKey, digest);
    assets[digest] = file.path;
    return {role: digest, '${role}Name': cloudName};
  }

  Future<String> _hashStableFile(File file) async {
    final before = await file.stat();
    final cacheKey = '$_hashStatePrefix${file.absolute.path}';
    final cachedRaw = await _stateValue(database, cacheKey);
    if (cachedRaw != null) {
      try {
        final cached = jsonDecode(cachedRaw) as Map;
        if (cached['size'] == before.size &&
            cached['mtime'] == before.modified.millisecondsSinceEpoch &&
            cached['hash'] is String &&
            _isHash(cached['hash'] as String)) {
          return cached['hash'] as String;
        }
      } catch (_) {}
    }
    final digest = (await sha256.bind(file.openRead()).first).toString();
    final after = await file.stat();
    if (before.size != after.size || before.modified != after.modified) {
      throw FileSystemException(
        'File changed while iCloud was reading it',
        file.path,
      );
    }
    await _putState(
      database,
      cacheKey,
      jsonEncode({
        'size': after.size,
        'mtime': after.modified.millisecondsSinceEpoch,
        'hash': digest,
      }),
    );
    return digest;
  }

  Future<String> _bookmarkIdentity(Map<String, Object?> row, String uid) async {
    final anchor = row['anchor_key'] as String?;
    if (anchor != null && anchor.trim().isNotEmpty) {
      return 'anchor-${sha256.convert(utf8.encode('$uid\u0000$anchor'))}';
    }
    final id = _requiredInt(row, 'id');
    final key = '$_bookmarkStatePrefix$id';
    final existing = await _stateValue(database, key);
    if (existing != null && existing.isNotEmpty) return existing;
    final assigned = const Uuid().v4();
    await _putState(database, key, assigned);
    return assigned;
  }

  _Incoming _validateIncoming(ICloudRecord record) {
    final value = record.value;
    final prefix = record.key.split(':').first;
    if (!const {
      'book',
      'progress',
      'folder',
      'bookmark',
      'note',
      'setting',
    }.contains(prefix)) {
      throw const FormatException('Unsupported iCloud record kind');
    }
    if (!record.key.startsWith('$prefix:') ||
        record.key.length == prefix.length + 1) {
      throw const FormatException('Invalid iCloud record key');
    }
    if (value == null) {
      final identity = record.key.substring(prefix.length + 1);
      if (prefix == 'setting' && !_portablePreference(identity)) {
        throw const FormatException('Invalid setting tombstone');
      }
      return _Incoming(prefix, identity, null);
    }
    if (value['kind'] != prefix ||
        value['label'] is! String ||
        (value['label'] as String).isEmpty) {
      throw const FormatException('Invalid iCloud record envelope');
    }
    switch (prefix) {
      case 'book':
        _exactKeys(value, const {
          'kind',
          'label',
          'uid',
          'row',
          'file',
          'fileName',
          'cover',
          'coverName',
          'sidecar',
          'sidecarName',
        });
        final uid = _requiredString(value, 'uid');
        if (record.key != 'book:$uid') {
          throw const FormatException('Invalid book key');
        }
        final row = _validatedRow(value['row'], _bookColumns);
        _validateBookRow(row);
        for (final role in const ['file', 'cover', 'sidecar']) {
          final hash = value[role];
          if (hash != null && (hash is! String || !_isHash(hash))) {
            throw const FormatException('Invalid asset hash');
          }
          final name = value['${role}Name'];
          if (name != null && !_safeFileName(name)) {
            throw const FormatException('Invalid asset name');
          }
        }
        return _Incoming(prefix, uid, Map<String, Object?>.from(value));
      case 'progress':
        _exactKeys(value, const {
          'kind',
          'label',
          'uid',
          'row',
          'sourceProgress',
        });
        final uid = _requiredString(value, 'uid');
        if (record.key != 'progress:$uid') {
          throw const FormatException('Invalid progress key');
        }
        final row = _validatedRow(value['row'], _progressColumns);
        _validateProgressRow(row);
        if (value['sourceProgress'] != null) {
          final source = _validatedRow(
            value['sourceProgress'],
            _sourceProgressColumns,
          );
          _validateSourceProgress(source);
        }
        return _Incoming(prefix, uid, Map<String, Object?>.from(value));
      case 'folder':
        _exactKeys(value, const {'kind', 'label', 'id', 'row'});
        final id = _requiredString(value, 'id');
        if (record.key != 'folder:$id') {
          throw const FormatException('Invalid folder key');
        }
        final row = _validatedRow(value['row'], const {
          'id',
          'name',
          'parent_id',
          'created_at',
        });
        if (row['id'] != id ||
            row['name'] is! String ||
            row['created_at'] is! int ||
            (row['parent_id'] != null && row['parent_id'] is! String)) {
          throw const FormatException('Invalid folder');
        }
        return _Incoming(prefix, id, Map<String, Object?>.from(value));
      case 'bookmark':
        _exactKeys(value, const {'kind', 'label', 'uid', 'bookmarkId', 'row'});
        final uid = _requiredString(value, 'uid');
        final bookmarkId = _requiredString(value, 'bookmarkId');
        if (record.key != 'bookmark:$uid:$bookmarkId') {
          throw const FormatException('Invalid bookmark key');
        }
        final row = _validatedRow(value['row'], _bookmarkColumns);
        if (row['pageNumber'] is! int || row['createDate'] is! int) {
          throw const FormatException('Invalid bookmark');
        }
        _validateOptionalTypes(row, const {
          'note': String,
          'cfi': String,
          'canonical_locator': String,
          'anchor_key': String,
          'chapter_index': int,
          'chapter_title': String,
          'excerpt': String,
        });
        return _Incoming(
          prefix,
          '$uid:$bookmarkId',
          Map<String, Object?>.from(value),
        );
      case 'note':
        _exactKeys(value, const {
          'kind',
          'label',
          'uid',
          'annotationId',
          'row',
        });
        final annotationId = _requiredString(value, 'annotationId');
        _requiredString(value, 'uid');
        if (record.key != 'note:$annotationId') {
          throw const FormatException('Invalid note key');
        }
        final row = _validatedRow(value['row'], _noteColumns);
        for (final key in const [
          'content',
          'cfi',
          'chapter',
          'type',
          'color',
          'update_time',
        ]) {
          _requiredString(row, key);
        }
        _validateOptionalTypes(row, const {
          'canonical_locator': String,
          'payload_json': String,
          'reader_note': String,
          'page_number': int,
          'start_offset': int,
          'end_offset': int,
          'create_time': String,
        });
        return _Incoming(
          prefix,
          annotationId,
          Map<String, Object?>.from(value),
        );
      case 'setting':
        _exactKeys(value, const {'kind', 'label', 'key', 'value'});
        final key = _requiredString(value, 'key');
        if (record.key != 'setting:$key' ||
            !_portablePreference(key) ||
            !_isPreferenceValue(value['value'])) {
          throw const FormatException('Invalid setting');
        }
        return _Incoming(prefix, key, Map<String, Object?>.from(value));
    }
    throw const FormatException('Unsupported iCloud record');
  }

  void _validateBookRow(Map<String, Object?> row) {
    _requiredString(row, 'title');
    final format = _requiredString(row, 'format').toLowerCase();
    final storageType = row['storage_type'];
    final nativeFormat =
        BookFormat.values.map((e) => e.name).contains(format) &&
        format != 'unknown';
    final onlineFormat =
        storageType == 'online' && (format == 'source' || format == 'online');
    if (!nativeFormat && !onlineFormat) {
      throw const FormatException('Unsupported book format');
    }
    if (row['importDate'] is! int ||
        (storageType != 'local' && storageType != 'online')) {
      throw const FormatException('Invalid book metadata');
    }
    for (final entry in row.entries) {
      final stringColumn = const {
        'title',
        'author',
        'format',
        'content_hash',
        'table_of_contents',
        'text_encoding',
        'storage_type',
        'source_id',
        'source_book_id',
        'source_json',
        'source_book_json',
        'source_kind',
        'source_locator',
        'shelf_folder_id',
      }.contains(entry.key);
      final intColumn = const {
        'importDate',
        'source_modified_time',
      }.contains(entry.key);
      if (entry.value != null &&
          !((stringColumn && entry.value is String) ||
              (intColumn && entry.value is int))) {
        throw const FormatException('Invalid book metadata type');
      }
    }
  }

  void _validateProgressRow(Map<String, Object?> row) {
    final progress = row['reading_progress'];
    if ((progress != null &&
            (progress is! num ||
                !progress.isFinite ||
                progress < 0 ||
                progress > 1)) ||
        (row['last_canonical_locator'] != null &&
            row['last_canonical_locator'] is! String)) {
      throw const FormatException('Invalid reading progress');
    }
  }

  void _validateSourceProgress(Map<String, Object?> row) {
    for (final key in const ['source_id', 'source_book_id', 'chapter_id']) {
      _requiredString(row, key);
    }
    final progress = row['chapter_progress'];
    if (row['chapter_index'] is! int ||
        progress is! num ||
        !progress.isFinite ||
        progress < 0 ||
        progress > 1) {
      throw const FormatException('Invalid source progress');
    }
  }

  Future<void> _validateFolderGraph(List<_Incoming> incoming) async {
    if (!await _tableExists(database, 'shelf_folders')) return;
    final parents = <String, String?>{
      for (final row in await database.query('shelf_folders'))
        row['id'] as String: row['parent_id'] as String?,
    };
    for (final item in incoming.where((e) => e.kind == 'folder')) {
      if (item.deleted) {
        parents.remove(item.identity);
        continue;
      }
      final row = Map<String, Object?>.from(item.value!['row'] as Map);
      parents[item.identity] = row['parent_id'] as String?;
    }
    final deleted = incoming
        .where((item) => item.kind == 'folder' && item.deleted)
        .map((item) => item.identity)
        .toSet();
    for (final entry in parents.entries.toList()) {
      if (deleted.contains(entry.value)) parents[entry.key] = null;
    }
    for (final entry in parents.entries) {
      final seen = <String>{};
      String? id = entry.key;
      while (id != null) {
        if (!seen.add(id)) throw const FormatException('Cyclic iCloud folders');
        final parent = parents[id];
        if (parent != null && !parents.containsKey(parent)) {
          throw const FormatException('Missing parent folder');
        }
        id = parent;
      }
    }
  }

  Future<List<_Incoming>> _orderedFolderUpserts(
    DatabaseExecutor tx,
    List<_Incoming> incoming,
  ) async {
    final items = <String, _Incoming>{
      for (final item in incoming.where(
        (item) => item.kind == 'folder' && !item.deleted,
      ))
        item.identity: item,
    };
    if (items.isEmpty) return const [];
    final existing = <String>{
      for (final row in await tx.query('shelf_folders', columns: ['id']))
        row['id']! as String,
    };
    final ordered = <_Incoming>[];
    final pending = Map<String, _Incoming>.from(items);
    while (pending.isNotEmpty) {
      final ready = pending.values.where((item) {
        final row = item.value!['row'] as Map;
        final parent = row['parent_id'] as String?;
        return parent == null || existing.contains(parent);
      }).toList();
      if (ready.isEmpty) throw const FormatException('Cyclic iCloud folders');
      for (final item in ready) {
        ordered.add(item);
        existing.add(item.identity);
        pending.remove(item.identity);
      }
    }
    return ordered;
  }

  Future<Map<String, File>> _verifyAssets(
    List<_Incoming> parsed,
    Map<String, String> supplied,
  ) async {
    final required = <String>{};
    for (final item in parsed.where((e) => e.kind == 'book' && !e.deleted)) {
      for (final role in const ['file', 'cover', 'sidecar']) {
        final hash = item.value![role];
        if (hash is String && supplied.containsKey(hash)) required.add(hash);
      }
    }
    final result = <String, File>{};
    for (final hash in required) {
      final path = supplied[hash]!;
      final file = File(path);
      if (!await file.exists() ||
          (await sha256.bind(file.openRead()).first).toString() != hash) {
        throw const FormatException('Corrupted iCloud asset');
      }
      result[hash] = file;
    }
    return result;
  }

  Future<Map<String, int>> _bookIdsByUid(DatabaseExecutor tx) async {
    final result = <String, int>{};
    for (final row in await tx.query(
      _stateTable,
      where: 'key LIKE ?',
      whereArgs: ['frozen_book_uid:%'],
    )) {
      final id = int.tryParse(
        (row['key'] as String).substring('frozen_book_uid:'.length),
      );
      if (id != null) result[row['value'] as String] = id;
    }
    return result;
  }

  Future<bool> _upsertFolder(DatabaseExecutor tx, _Incoming item) async {
    final row = Map<String, Object?>.from(item.value!['row'] as Map);
    final existing = await tx.query(
      'shelf_folders',
      where: 'id = ?',
      whereArgs: [item.identity],
      limit: 1,
    );
    if (existing.isNotEmpty &&
        syncCanonicalJson(existing.single) == syncCanonicalJson(row)) {
      return false;
    }
    if (existing.isEmpty) {
      await tx.insert('shelf_folders', row);
    } else {
      await tx.update(
        'shelf_folders',
        Map.of(row)..remove('id'),
        where: 'id = ?',
        whereArgs: [item.identity],
      );
    }
    return true;
  }

  Future<bool> _applyBook(
    DatabaseExecutor tx,
    _Incoming item,
    Map<String, int> uidToId,
    Map<String, File> verified,
  ) async {
    final existingId = uidToId[item.identity];
    if (item.deleted) {
      if (existingId == null) return false;
      await tx.delete('books', where: 'id = ?', whereArgs: [existingId]);
      await tx.delete(
        _stateTable,
        where: 'key = ?',
        whereArgs: ['frozen_book_uid:$existingId'],
      );
      uidToId.remove(item.identity);
      return true;
    }
    final value = item.value!;
    final row = Map<String, Object?>.from(value['row'] as Map);
    final existing = existingId == null
        ? <Map<String, Object?>>[]
        : await tx.query(
            'books',
            where: 'id = ?',
            whereArgs: [existingId],
            limit: 1,
          );
    final online = row['storage_type'] == 'online';
    if (online) {
      row['filePath'] = existing.isEmpty ? '' : existing.single['filePath'];
      row['cover_image_path'] = existing.isEmpty
          ? null
          : existing.single['cover_image_path'];
    } else {
      row['filePath'] = await _materializeAsset(
        tx,
        item.identity,
        'file',
        value,
        verified,
        existing.isEmpty ? null : existing.single['filePath'] as String?,
      );
      row['cover_image_path'] = await _materializeAsset(
        tx,
        item.identity,
        'cover',
        value,
        verified,
        existing.isEmpty
            ? null
            : existing.single['cover_image_path'] as String?,
      );
      await _materializeAsset(
        tx,
        item.identity,
        'sidecar',
        value,
        verified,
        null,
        bodyPath: row['filePath'] as String?,
      );
    }
    if (existing.isNotEmpty) {
      for (final key in const [
        'currentPage',
        'totalPages',
        'reading_progress',
        'last_canonical_locator',
        'last_rendered_locator',
        'layout_signature',
      ]) {
        row[key] = existing.single[key];
      }
      await tx.update('books', row, where: 'id = ?', whereArgs: [existingId]);
      return true;
    }
    row.addAll({
      'currentPage': 0,
      'reading_progress': null,
      'last_canonical_locator': null,
      'last_rendered_locator': null,
      'layout_signature': null,
    });
    final id = await tx.insert('books', row);
    await freezeBookUid(tx, id, item.identity);
    uidToId[item.identity] = id;
    return true;
  }

  Future<String?> _materializeAsset(
    DatabaseExecutor tx,
    String uid,
    String role,
    Map<String, Object?> value,
    Map<String, File> verified,
    String? existingPath, {
    String? bodyPath,
  }) async {
    final hash = value[role] as String?;
    if (hash == null) return role == 'file' ? existingPath : null;
    final statePrefix = switch (role) {
      'file' => _bodyStatePrefix,
      'cover' => _coverStatePrefix,
      _ => _sidecarStatePrefix,
    };
    final known = await _stateValue(tx, '$statePrefix$uid');
    if (verified[hash] == null) {
      if (known == hash &&
          role != 'sidecar' &&
          existingPath != null &&
          await File(existingPath).exists()) {
        return existingPath;
      }
      if (known == hash &&
          role == 'sidecar' &&
          bodyPath != null &&
          await File('$bodyPath.openreading-source.json').exists()) {
        return '$bodyPath.openreading-source.json';
      }
      throw const FormatException('Required iCloud asset is unavailable');
    }
    final format = value['row'] is Map
        ? (value['row'] as Map)['format'] as String?
        : null;
    final extension = role == 'file'
        ? '.$format'
        : role == 'sidecar'
        ? '.openreading-source.json'
        : _validatedImageExtension(value['coverName'] as String?);
    final base = _safeStem((value['${role}Name'] as String?) ?? role);
    final directory = Directory(p.join(documents.path, 'icloud-books', hash));
    await directory.create(recursive: true);
    final destination = role == 'sidecar' && bodyPath != null
        ? File('$bodyPath.openreading-source.json')
        : File(p.join(directory.path, '$base$extension'));
    if (!await destination.exists()) {
      await verified[hash]!.copy(destination.path);
    }
    if ((await sha256.bind(destination.openRead()).first).toString() != hash) {
      throw const FormatException('Corrupted materialized iCloud asset');
    }
    await _putState(tx, '$statePrefix$uid', hash);
    return destination.path;
  }

  Future<bool> _applyProgress(
    DatabaseExecutor tx,
    _Incoming item,
    Map<String, int> uidToId,
  ) async {
    final id = uidToId[item.identity];
    if (id == null) {
      if (item.deleted) return false;
      throw const FormatException('Progress references unknown book');
    }
    if (item.deleted) return false;
    final row = Map<String, Object?>.from(item.value!['row'] as Map);
    final current = (await tx.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).single;
    final changed = _progressColumns.any((key) => current[key] != row[key]);
    if (changed) {
      await tx.update(
        'books',
        {...row, 'last_rendered_locator': null, 'layout_signature': null},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (await _tableExists(tx, 'reader_pagination_cache')) {
        await tx.delete(
          'reader_pagination_cache',
          where: 'book_id = ?',
          whereArgs: [id],
        );
      }
    }
    final source = item.value!['sourceProgress'];
    var sourceChanged = false;
    if (source is Map &&
        await _tableExists(tx, 'book_source_reading_progress')) {
      await tx.insert(
        'book_source_reading_progress',
        {
          ...Map<String, Object?>.from(source),
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      sourceChanged = true;
    } else if (await _tableExists(tx, 'book_source_reading_progress')) {
      final book = (await tx.query(
        'books',
        columns: ['source_id', 'source_book_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      )).single;
      final sourceId = book['source_id'];
      final sourceBookId = book['source_book_id'];
      if (sourceId is String && sourceBookId is String) {
        sourceChanged =
            await tx.delete(
              'book_source_reading_progress',
              where: 'source_id = ? AND source_book_id = ?',
              whereArgs: [sourceId, sourceBookId],
            ) >
            0;
      }
    }
    return changed || sourceChanged;
  }

  Future<bool> _applyBookmark(
    DatabaseExecutor tx,
    _Incoming item,
    Map<String, int> uidToId,
  ) async {
    final split = item.identity.lastIndexOf(':');
    final uid = item.identity.substring(0, split);
    final stable = item.identity.substring(split + 1);
    final stateKey = 'icloud_bookmark_remote:$uid:$stable';
    final localRaw = await _stateValue(tx, stateKey);
    final localId = int.tryParse(localRaw ?? '');
    if (item.deleted) {
      if (localId == null) return false;
      await tx.delete('bookmarks', where: 'id = ?', whereArgs: [localId]);
      await tx.delete(_stateTable, where: 'key = ?', whereArgs: [stateKey]);
      return true;
    }
    final bookId = uidToId[uid];
    if (bookId == null) {
      throw const FormatException('Bookmark references unknown book');
    }
    final row = Map<String, Object?>.from(item.value!['row'] as Map)
      ..['bookId'] = bookId;
    if (localId != null &&
        (await tx.query(
          'bookmarks',
          where: 'id = ?',
          whereArgs: [localId],
          limit: 1,
        )).isNotEmpty) {
      await tx.update('bookmarks', row, where: 'id = ?', whereArgs: [localId]);
    } else {
      final id = await tx.insert('bookmarks', row);
      await _putState(tx, stateKey, '$id');
      await _putState(tx, '$_bookmarkStatePrefix$id', stable);
    }
    return true;
  }

  Future<bool> _applyNote(
    DatabaseExecutor tx,
    _Incoming item,
    Map<String, int> uidToId,
  ) async {
    if (item.deleted) {
      return (await tx.delete(
            'book_notes',
            where: 'annotation_id = ?',
            whereArgs: [item.identity],
          )) >
          0;
    }
    final uid = _requiredString(item.value!, 'uid');
    final bookId = uidToId[uid];
    if (bookId == null) {
      throw const FormatException('Note references unknown book');
    }
    final row = Map<String, Object?>.from(item.value!['row'] as Map)
      ..['annotation_id'] = item.identity
      ..['book_id'] = bookId;
    final existing = await tx.query(
      'book_notes',
      columns: ['id'],
      where: 'annotation_id = ?',
      whereArgs: [item.identity],
      limit: 1,
    );
    if (existing.isEmpty) {
      await tx.insert('book_notes', row);
    } else {
      await tx.update(
        'book_notes',
        row,
        where: 'annotation_id = ?',
        whereArgs: [item.identity],
      );
    }
    return true;
  }

  Future<bool> _applySetting(_Incoming item) async {
    final before = preferences.get(item.identity);
    if (item.deleted) {
      if (before == null) return false;
      if (!await preferences.remove(item.identity)) {
        throw StateError('Could not remove synced setting');
      }
      return true;
    }
    final value = item.value!['value'];
    if (syncCanonicalJson(before) == syncCanonicalJson(value)) return false;
    if (!await _writePreference(item.identity, value)) {
      throw StateError('Could not save synced setting');
    }
    return true;
  }

  Future<bool> _writePreference(String key, Object? value) => switch (value) {
    null => preferences.remove(key),
    String v => preferences.setString(key, v),
    bool v => preferences.setBool(key, v),
    int v => preferences.setInt(key, v),
    double v => preferences.setDouble(key, v),
    List v => preferences.setStringList(key, v.cast<String>()),
    _ => Future.value(false),
  };

  static bool _portablePreference(String key, [Object? value]) {
    if (value is String &&
        (value.startsWith('file:') ||
            value.startsWith('content:') ||
            p.posix.isAbsolute(value) ||
            p.windows.isAbsolute(value))) {
      return false;
    }
    if (RegExp(
      r'icloud|webdav|sync|account|member|token|password|secret|api.?key|cookie|permission|agreement|privacy|credential|session|ai_|reader_aloud_cloud|cache|file|path|custom.*font|font_(?:id|family)|background.*(?:image|path)|book_source|progress|current.?page|resume|last.?read|book.?id|appThemePackageSelection',
      caseSensitive: false,
    ).hasMatch(key)) {
      return false;
    }
    const explicit = <String>{
      'isDarkMode',
      'ui_style_mode',
      'glass_style_mode',
      'liquid_glass_opacity',
      'appAccentColorV2',
      'appColorPresetIdV1',
      'appSkinIdV1',
      'appTheme',
      'customAccentColor',
      'globalAccentColor',
      'last_preset_app_theme',
      'app_text_scale_level_v1',
      'app_locale',
      'language',
      'hide_home_navigation_labels_v1',
      'home_navigation_order_v1',
      'home_navigation_hidden_v1',
      'customize_home_navigation_size_v1',
      'home_navigation_height_v1',
      'home_navigation_horizontal_margin_v1',
      'enableAnimations',
      'enableFullscreen',
      'enableVolumeKeyTurn',
      'enableAutoSave',
      'enableAutoExtractCover',
      'keepScreenOn',
      'reader_aloud_follow_page_turns',
      'reader_aloud_presentation',
      'reader_aloud_tap_to_seek',
    };
    if (explicit.contains(key)) return true;
    return RegExp(
      r'^(native_reader_|library_|shelf_|bookshelf_|reader_(?:font_size|font_weight|line_height|letter_spacing|theme|page_mode|tap|margin|brightness|text|paragraph|chapter|scroll|pull))',
      caseSensitive: false,
    ).hasMatch(key);
  }

  static String _settingLabel(String key) {
    final normalized = key.toLowerCase();
    if (normalized.contains('font') && normalized.contains('size')) {
      return '阅读字号';
    }
    if (normalized.contains('line') && normalized.contains('height')) {
      return '阅读行距';
    }
    if (normalized.contains('theme') ||
        normalized.contains('skin') ||
        normalized.contains('palette')) {
      return '外观主题';
    }
    if (normalized.contains('navigation') || normalized.contains('page_turn')) {
      return '阅读导航';
    }
    if (normalized.contains('library') || normalized.contains('shelf')) {
      return '书架设置';
    }
    if (normalized.contains('language') || normalized.contains('locale')) {
      return '应用语言';
    }
    return '阅读与应用设置';
  }

  static bool _isPreferenceValue(Object? value) =>
      value is String ||
      value is bool ||
      value is int ||
      value is double ||
      value is List<String>;
  static bool _isHash(String value) =>
      RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  static bool _safeFileName(Object? value) =>
      value is String &&
      value.isNotEmpty &&
      value == p.basename(value) &&
      !value.contains(RegExp(r'[/\\\x00]'));
  static String _safeStem(String value) {
    final stem = p
        .basenameWithoutExtension(value)
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return stem.isEmpty ? 'book' : stem.substring(0, stem.length.clamp(0, 80));
  }

  static String _validatedImageExtension(String? name) {
    final ext = p.extension(name ?? '').toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(ext)
        ? ext
        : '.img';
  }

  static String _bodyCloudName(String path, String format) =>
      '${_safeStem(p.basename(path))}.${format.toLowerCase()}';

  static String _coverCloudName(String path) =>
      '${_safeStem(p.basename(path))}${_validatedImageExtension(path)}';

  static Map<String, Object?> _validatedRow(Object? raw, Set<String> allowed) {
    if (raw is! Map ||
        raw.keys.any((key) => key is! String || !allowed.contains(key))) {
      throw const FormatException('Invalid iCloud row schema');
    }
    return Map<String, Object?>.from(raw);
  }

  static void _validateOptionalTypes(
    Map<String, Object?> row,
    Map<String, Type> types,
  ) {
    for (final entry in types.entries) {
      final value = row[entry.key];
      if (value == null) continue;
      if ((entry.value == String && value is! String) ||
          (entry.value == int && value is! int)) {
        throw FormatException('Invalid ${entry.key}');
      }
    }
  }

  static void _exactKeys(Map<String, Object?> value, Set<String> allowed) {
    if (value.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Unknown iCloud field');
    }
  }

  static String _requiredString(Map row, String key) {
    final value = row[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }

  static int _requiredInt(Map row, String key) {
    final value = row[key];
    if (value is! int) throw FormatException('Invalid $key');
    return value;
  }

  static Future<void> _ensureStateTable(DatabaseExecutor db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $_stateTable(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
  static Future<bool> _tableExists(DatabaseExecutor db, String table) async =>
      (await db.rawQuery(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      )).isNotEmpty;
  static Future<String?> _stateValue(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      _stateTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['value'] as String?;
  }

  static Future<void> _putState(
    DatabaseExecutor db,
    String key,
    String value,
  ) => db.insert(_stateTable, {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

class _Incoming {
  const _Incoming(this.kind, this.identity, this.value);
  final String kind;
  final String identity;
  final Map<String, Object?>? value;
  bool get deleted => value == null;
}
