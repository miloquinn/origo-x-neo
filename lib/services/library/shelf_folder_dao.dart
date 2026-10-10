// 文件说明：嵌套书架文件夹 DAO，原子维护目录和书籍归属。
// 技术要点：事务、引用校验、循环检测、解散提升和事件通知。

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/services/core/database_service.dart';
import 'package:xxread/services/library/library_event_bus_service.dart';

class ShelfFolderDao {
  ShelfFolderDao({Future<Database> Function()? database})
    : _databaseProvider = database ?? (() => DatabaseService().database);

  final Future<Database> Function() _databaseProvider;
  static const int _bookBatchSize = 500;

  Future<List<ShelfFolder>> getAll() async {
    final db = await _databaseProvider();
    final rows = await db.query(
      'shelf_folders',
      orderBy: 'created_at ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(ShelfFolder.fromMap).toList(growable: false);
  }

  Future<ShelfFolder> create(
    String name, {
    String? parentId,
    Set<int> bookIds = const {},
  }) async {
    final normalizedName = _validatedName(name);
    final db = await _databaseProvider();
    final folder = await db.transaction((txn) async {
      if (parentId != null) await _requireFolder(txn, parentId);
      await _requireBooks(txn, bookIds);

      final folder = ShelfFolder(
        id: const Uuid().v4(),
        name: normalizedName,
        parentId: parentId,
        createdAt: DateTime.now(),
      );
      await txn.insert('shelf_folders', folder.toMap());
      await _updateBooks(txn, bookIds, folder.id);
      return folder;
    });
    _notifyChanged();
    return folder;
  }

  Future<void> rename(String id, String name) async {
    final normalizedName = _validatedName(name);
    final db = await _databaseProvider();
    final updated = await db.update(
      'shelf_folders',
      {'name': normalizedName},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated != 1) throw StateError('书架文件夹不存在');
    _notifyChanged();
  }

  Future<void> moveBooks(Set<int> bookIds, String? folderId) async {
    if (bookIds.isEmpty) return;
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      if (folderId != null) await _requireFolder(txn, folderId);
      await _requireBooks(txn, bookIds);
      await _updateBooks(txn, bookIds, folderId);
    });
    _notifyChanged();
  }

  Future<void> moveFolder(String id, String? parentId) async {
    if (id == parentId) throw ArgumentError('文件夹不能移入自身');
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final folder = await _requireFolder(txn, id);
      if (folder['parent_id'] == parentId) return;
      if (parentId != null) {
        await _requireFolder(txn, parentId);
        final descendants = await txn.rawQuery(
          '''
          WITH RECURSIVE descendants(id) AS (
            SELECT id FROM shelf_folders WHERE parent_id = ?
            UNION ALL
            SELECT folder.id
            FROM shelf_folders folder
            JOIN descendants ON folder.parent_id = descendants.id
          )
          SELECT id FROM descendants WHERE id = ? LIMIT 1
          ''',
          [id, parentId],
        );
        if (descendants.isNotEmpty) {
          throw ArgumentError('文件夹不能移入自己的子目录');
        }
      }
      await txn.update(
        'shelf_folders',
        {'parent_id': parentId, 'sort_index': null},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    _notifyChanged();
  }

  Future<void> dissolve(String id) async {
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final folder = await _requireFolder(txn, id);
      final parentId = folder['parent_id'] as String?;
      await txn.update(
        'books',
        {'shelf_folder_id': parentId, 'shelf_sort_index': null},
        where: 'shelf_folder_id = ?',
        whereArgs: [id],
      );
      await txn.update(
        'shelf_folders',
        {'parent_id': parentId, 'sort_index': null},
        where: 'parent_id = ?',
        whereArgs: [id],
      );
      await txn.delete('shelf_folders', where: 'id = ?', whereArgs: [id]);
    });
    _notifyChanged();
  }

  /// Persist one complete sibling sequence. Membership is verified inside the
  /// transaction so a stale drag cannot reorder items in a different folder.
  Future<void> reorder(
    String? parentId,
    List<({int? bookId, String? folderId})> entries,
  ) async {
    final keys = <String>{};
    for (final entry in entries) {
      if ((entry.bookId == null) == (entry.folderId == null) ||
          entry.bookId != null && entry.bookId! <= 0 ||
          entry.folderId != null && entry.folderId!.isEmpty) {
        throw ArgumentError('每个排序项必须引用一本书或一个文件夹');
      }
      final key = entry.bookId != null
          ? 'book:${entry.bookId}'
          : 'folder:${entry.folderId}';
      if (!keys.add(key)) throw ArgumentError('排序项不能重复');
    }
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      if (parentId != null) await _requireFolder(txn, parentId);
      final siblings = <String>{
        for (final row in await txn.query(
          'books',
          columns: const ['id'],
          where: 'shelf_folder_id IS ?',
          whereArgs: [parentId],
        ))
          'book:${row['id']}',
        for (final row in await txn.query(
          'shelf_folders',
          columns: const ['id'],
          where: 'parent_id IS ?',
          whereArgs: [parentId],
        ))
          'folder:${row['id']}',
      };
      if (siblings.length != keys.length || !siblings.containsAll(keys)) {
        throw StateError('书架内容已变化，请重新整理顺序');
      }
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        await txn.update(
          entry.bookId != null ? 'books' : 'shelf_folders',
          {entry.bookId != null ? 'shelf_sort_index' : 'sort_index': index},
          where: 'id = ?',
          whereArgs: [entry.bookId ?? entry.folderId],
        );
      }
    });
    _notifyChanged();
  }

  String _validatedName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError('文件夹名称不能为空');
    if (normalized.runes.length > 60) {
      throw ArgumentError('文件夹名称不能超过 60 个字符');
    }
    return normalized;
  }

  Future<Map<String, Object?>> _requireFolder(
    DatabaseExecutor db,
    String id,
  ) async {
    final rows = await db.query(
      'shelf_folders',
      columns: const ['id', 'parent_id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('书架文件夹不存在');
    return rows.single;
  }

  Future<void> _requireBooks(DatabaseExecutor db, Set<int> bookIds) async {
    if (bookIds.isEmpty) return;
    final ids = bookIds.toList(growable: false);
    var existingCount = 0;
    for (var start = 0; start < ids.length; start += _bookBatchSize) {
      final end = start + _bookBatchSize < ids.length
          ? start + _bookBatchSize
          : ids.length;
      final chunk = ids.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM books WHERE id IN ($placeholders)',
        chunk,
      );
      existingCount += rows.single['count'] as int;
    }
    if (existingCount != ids.length) {
      throw StateError('所选书籍不存在');
    }
  }

  Future<void> _updateBooks(
    DatabaseExecutor db,
    Set<int> bookIds,
    String? folderId,
  ) async {
    if (bookIds.isEmpty) return;
    final ids = bookIds.toList(growable: false);
    for (var start = 0; start < ids.length; start += _bookBatchSize) {
      final end = start + _bookBatchSize < ids.length
          ? start + _bookBatchSize
          : ids.length;
      final chunk = ids.sublist(start, end);
      final placeholders = List.filled(chunk.length, '?').join(',');
      await db.rawUpdate(
        'UPDATE books SET shelf_folder_id = ?, shelf_sort_index = NULL '
        'WHERE id IN ($placeholders) AND shelf_folder_id IS NOT ?',
        [folderId, ...chunk, folderId],
      );
    }
  }

  void _notifyChanged() => LibraryEventBus().notifyLibraryChanged();
}
