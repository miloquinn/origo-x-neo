// 文件说明：书架手动顺序和真实最近阅读时间的 v29 数据库迁移。
// 技术要点：nullable 默认兼容、幂等列迁移、只使用真实阅读会话回填。

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ShelfOrganizationSchemaMigration {
  const ShelfOrganizationSchemaMigration._();

  static const int migrationVersion = 29;

  static Future<void> migrate(DatabaseExecutor db) async {
    final bookColumns = await _columns(db, 'books');
    for (final column in ['shelf_sort_index', 'last_read_at']) {
      if (!bookColumns.contains(column)) {
        await db.execute('ALTER TABLE books ADD COLUMN $column INTEGER');
      }
    }
    final folderColumns = await _columns(db, 'shelf_folders');
    if (!folderColumns.contains('sort_index')) {
      await db.execute(
        'ALTER TABLE shelf_folders ADD COLUMN sort_index INTEGER',
      );
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_last_read '
      'ON books(last_read_at DESC)',
    );

    final sessionColumns = await _columns(db, 'reading_sessions');
    if (!sessionColumns.containsAll({'bookId', 'endTimeMs'})) return;
    final validSession = [
      "typeof(endTimeMs) = 'integer'",
      'endTimeMs > 0',
      if (sessionColumns.contains('startTimeMs')) 'endTimeMs > startTimeMs',
      if (sessionColumns.contains('durationInSeconds')) 'durationInSeconds > 0',
    ].join(' AND ');
    final latestSession =
        '''
      (SELECT MAX(endTimeMs) FROM reading_sessions
       WHERE bookId = books.id AND $validSession)
    ''';
    await db.execute('''
      UPDATE books SET last_read_at = $latestSession
      WHERE $latestSession IS NOT NULL
        AND (last_read_at IS NULL OR last_read_at < $latestSession)
    ''');
  }

  static Future<Set<String>> _columns(
    DatabaseExecutor db,
    String table,
  ) async => (await db.rawQuery(
    'PRAGMA table_info($table)',
  )).map((row) => row['name']! as String).toSet();
}
