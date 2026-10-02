import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/data/migration/book_source_reading_progress_schema_migration.dart';

/// Uses the production SQLite store without a process-global app database or
/// a background isolate that cannot advance inside widget tests' fake clock.
class BookSourceProgressTestFixture {
  BookSourceProgressTestFixture._(this.database)
    : store = BookSourceReadingProgressStore(database: () async => database);

  final Database database;
  final BookSourceReadingProgressStore store;

  static Future<BookSourceProgressTestFixture> create() async {
    sqfliteFfiInit();
    final database = await databaseFactoryFfiNoIsolate.openDatabase(
      inMemoryDatabasePath,
    );
    await BookSourceReadingProgressSchemaMigration.migrate(database);
    return BookSourceProgressTestFixture._(database);
  }

  Future<void> close() => database.close();
}
