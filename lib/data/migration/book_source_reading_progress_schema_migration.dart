import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class BookSourceReadingProgressSchemaMigration {
  static const int migrationVersion = 27;

  static Future<void> migrate(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS book_source_reading_progress(
        source_id TEXT NOT NULL,
        source_book_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        chapter_index INTEGER NOT NULL,
        chapter_progress REAL NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (source_id, source_book_id)
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_book_source_progress_updated_at
      ON book_source_reading_progress(updated_at DESC)
    ''');
  }
}
