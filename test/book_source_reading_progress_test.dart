import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xxread/book_sources/services/book_source_reading_progress.dart';
import 'package:xxread/data/migration/book_source_reading_progress_schema_migration.dart';

void main() {
  late Database database;
  late BookSourceReadingProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    database = await openDatabase(inMemoryDatabasePath);
    await BookSourceReadingProgressSchemaMigration.migrate(database);
    store = BookSourceReadingProgressStore(database: () async => database);
  });

  tearDown(() => database.close());

  test(
    'persists chapter identity and normalized in-chapter progress',
    () async {
      final progress = BookSourceReadingProgress(
        chapterId: 'chapter-25',
        chapterIndex: 24,
        chapterProgress: 0.42,
        updatedAt: DateTime.utc(2026, 7, 12),
      );

      await store.save(
        sourceId: 'source-a',
        bookId: 'book-a',
        progress: progress,
      );
      final restored = await store.load(sourceId: 'source-a', bookId: 'book-a');

      expect(restored?.chapterId, 'chapter-25');
      expect(restored?.chapterIndex, 24);
      expect(restored?.chapterProgress, closeTo(0.42, 0.001));
      expect(await store.load(sourceId: 'source-a', bookId: 'book-b'), isNull);
    },
  );

  test('migrates legacy preferences once and keeps the newest record', () async {
    const sourceId = 'legacy/source';
    const bookId = 'legacy book';
    final legacy = BookSourceReadingProgress(
      chapterId: 'legacy-9',
      chapterIndex: 9,
      chapterProgress: 0.7,
      updatedAt: DateTime.utc(2026, 9, 24),
    );
    final prefs = await SharedPreferences.getInstance();
    final legacyKey =
        'book_source_reading_progress_v1:${Uri.encodeComponent(sourceId)}:${Uri.encodeComponent(bookId)}';
    await prefs.setString(legacyKey, jsonEncode(legacy.toJson()));

    final first = await store.load(sourceId: sourceId, bookId: bookId);
    final second = await store.load(sourceId: sourceId, bookId: bookId);

    expect(first?.chapterId, 'legacy-9');
    expect(second?.chapterId, 'legacy-9');
    expect(prefs.containsKey(legacyKey), isFalse);
    final rows = await database.query('book_source_reading_progress');
    expect(rows, hasLength(1));
  });

  test('an older legacy record cannot overwrite newer SQLite progress', () async {
    const sourceId = 'source-a';
    const bookId = 'book-a';
    final current = BookSourceReadingProgress(
      chapterId: 'newer',
      chapterIndex: 12,
      chapterProgress: 0.2,
      updatedAt: DateTime.utc(2026, 9, 24),
    );
    await store.save(sourceId: sourceId, bookId: bookId, progress: current);
    final prefs = await SharedPreferences.getInstance();
    final legacyKey =
        'book_source_reading_progress_v1:${Uri.encodeComponent(sourceId)}:${Uri.encodeComponent(bookId)}';
    await prefs.setString(
      legacyKey,
      jsonEncode(
        BookSourceReadingProgress(
          chapterId: 'older',
          chapterIndex: 2,
          chapterProgress: 0.9,
          updatedAt: DateTime.utc(2025),
        ).toJson(),
      ),
    );

    final restored = await store.load(sourceId: sourceId, bookId: bookId);

    expect(restored?.chapterId, 'newer');
    expect(prefs.containsKey(legacyKey), isFalse);
  });
}
