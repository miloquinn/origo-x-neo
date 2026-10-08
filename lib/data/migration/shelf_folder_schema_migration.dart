// 文件说明：嵌套书架 v28 数据库迁移。
// 技术要点：可重复执行的建表、nullable 外键和归属查询索引。

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ShelfFolderSchemaMigration {
  const ShelfFolderSchemaMigration._();

  static const int migrationVersion = 28;

  static Future<void> migrate(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shelf_folders(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES shelf_folders(id) ON DELETE SET NULL
      )
    ''');

    final bookColumns = (await db.rawQuery(
      'PRAGMA table_info(books)',
    )).map((row) => row['name'] as String).toSet();
    if (!bookColumns.contains('shelf_folder_id')) {
      await db.execute(
        'ALTER TABLE books ADD COLUMN shelf_folder_id TEXT '
        'REFERENCES shelf_folders(id) ON DELETE SET NULL',
      );
    }

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_shelf_folders_parent_created
      ON shelf_folders(parent_id, created_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_books_shelf_folder
      ON books(shelf_folder_id)
    ''');
  }
}
