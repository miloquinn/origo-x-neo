import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../services/core/database_service.dart';

class BookSourceReadingProgress {
  final String chapterId;
  final int chapterIndex;
  final double chapterProgress;
  final DateTime updatedAt;

  const BookSourceReadingProgress({
    required this.chapterId,
    required this.chapterIndex,
    required this.chapterProgress,
    required this.updatedAt,
  });

  factory BookSourceReadingProgress.fromJson(Map<String, dynamic> json) {
    return BookSourceReadingProgress(
      chapterId: (json['chapterId'] as String?)?.trim() ?? '',
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
      chapterProgress: ((json['chapterProgress'] as num?)?.toDouble() ?? 0)
          .clamp(0, 1),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  factory BookSourceReadingProgress.fromRow(Map<String, Object?> row) {
    return BookSourceReadingProgress(
      chapterId: (row['chapter_id'] as String?) ?? '',
      chapterIndex: (row['chapter_index'] as num?)?.toInt() ?? 0,
      chapterProgress: ((row['chapter_progress'] as num?)?.toDouble() ?? 0)
          .clamp(0, 1),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (row['updated_at'] as num?)?.toInt() ?? 0,
        isUtc: true,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'chapterId': chapterId,
    'chapterIndex': chapterIndex,
    'chapterProgress': chapterProgress.clamp(0, 1),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class BookSourceReadingProgressStore {
  static const _legacyPrefix = 'book_source_reading_progress_v1';

  const BookSourceReadingProgressStore({Future<Database> Function()? database})
    : _databaseProvider = database;

  final Future<Database> Function()? _databaseProvider;

  Future<Database> get _database =>
      (_databaseProvider ?? (() => DatabaseService().database))();

  Future<BookSourceReadingProgress?> load({
    required String sourceId,
    required String bookId,
  }) async {
    final db = await _database;
    final rows = await db.query(
      'book_source_reading_progress',
      where: 'source_id = ? AND source_book_id = ?',
      whereArgs: [sourceId, bookId],
      limit: 1,
    );
    final persisted = rows.isEmpty
        ? null
        : BookSourceReadingProgress.fromRow(rows.single);
    final legacy = await _loadLegacy(sourceId: sourceId, bookId: bookId);
    if (legacy == null) return persisted;

    await db.transaction((txn) async {
      await saveWithExecutor(
        txn,
        sourceId: sourceId,
        bookId: bookId,
        progress: legacy,
      );
    });
    await _removeLegacy(sourceId: sourceId, bookId: bookId);
    if (persisted != null && persisted.updatedAt.isAfter(legacy.updatedAt)) {
      return persisted;
    }
    return legacy;
  }

  Future<void> save({
    required String sourceId,
    required String bookId,
    required BookSourceReadingProgress progress,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      await saveWithExecutor(
        txn,
        sourceId: sourceId,
        bookId: bookId,
        progress: progress,
      );
    });
    await _removeLegacy(sourceId: sourceId, bookId: bookId);
  }

  Future<void> delete({
    required String sourceId,
    required String bookId,
  }) async {
    final db = await _database;
    await db.delete(
      'book_source_reading_progress',
      where: 'source_id = ? AND source_book_id = ?',
      whereArgs: [sourceId, bookId],
    );
    await _removeLegacy(sourceId: sourceId, bookId: bookId);
  }

  static Future<void> saveWithExecutor(
    DatabaseExecutor db, {
    required String sourceId,
    required String bookId,
    required BookSourceReadingProgress progress,
  }) async {
    await db.rawInsert(
      '''
      INSERT INTO book_source_reading_progress(
        source_id,
        source_book_id,
        chapter_id,
        chapter_index,
        chapter_progress,
        updated_at
      ) VALUES(?, ?, ?, ?, ?, ?)
      ON CONFLICT(source_id, source_book_id) DO UPDATE SET
        chapter_id = excluded.chapter_id,
        chapter_index = excluded.chapter_index,
        chapter_progress = excluded.chapter_progress,
        updated_at = excluded.updated_at
      WHERE excluded.updated_at >= book_source_reading_progress.updated_at
      ''',
      [
        sourceId,
        bookId,
        progress.chapterId,
        progress.chapterIndex,
        progress.chapterProgress.clamp(0, 1),
        progress.updatedAt.toUtc().millisecondsSinceEpoch,
      ],
    );
  }

  Future<BookSourceReadingProgress?> _loadLegacy({
    required String sourceId,
    required String bookId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_legacyKey(sourceId, bookId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return BookSourceReadingProgress.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _removeLegacy({
    required String sourceId,
    required String bookId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey(sourceId, bookId));
  }

  String _legacyKey(String sourceId, String bookId) =>
      '$_legacyPrefix:${Uri.encodeComponent(sourceId)}:${Uri.encodeComponent(bookId)}';
}
