part of 'book_source_change_service.dart';

class BookSourceChangePosition {
  const BookSourceChangePosition({
    required this.chapterIndex,
    required this.chapterProgress,
    required this.chapterTitle,
    required this.chapterCount,
  });

  final int chapterIndex;
  final double chapterProgress;
  final String chapterTitle;
  final int chapterCount;
}

class BookSourceChangeCandidate {
  const BookSourceChangeCandidate({
    required this.source,
    required this.book,
    required this.authorMatches,
  });

  final RegisteredBookSource source;
  final BookSourceBook book;
  final bool authorMatches;
}

class BookSourceChangeSearchEvent {
  const BookSourceChangeSearchEvent({
    required this.source,
    required this.completed,
    this.candidates = const [],
    this.error,
  });

  final RegisteredBookSource source;
  final int completed;
  final List<BookSourceChangeCandidate> candidates;
  final Object? error;
}

enum BookSourceChangeValidationStage { detail, catalog, content }

enum BookSourceChapterMappingConfidence {
  exactTitle,
  chapterNumber,
  proportional,
  start,
  manual,
}

class BookSourceChangeTimeoutException implements Exception {
  const BookSourceChangeTimeoutException(this.timeout);

  final Duration timeout;

  @override
  String toString() => 'Book source change timed out after $timeout.';
}

class ValidatedBookSourceChange {
  const ValidatedBookSourceChange({
    required this.candidate,
    required this.book,
    required this.chapters,
    required this.chapterIndex,
    required this.chapterProgress,
    required this.responseTime,
    this.mappingConfidence = BookSourceChapterMappingConfidence.proportional,
  });

  final BookSourceChangeCandidate candidate;
  final BookSourceBook book;
  final List<BookSourceChapter> chapters;
  final int chapterIndex;
  final double chapterProgress;
  final Duration responseTime;
  final BookSourceChapterMappingConfidence mappingConfidence;

  BookSourceChapter get chapter => chapters[chapterIndex];
}

class BookSourceChangeResult {
  const BookSourceChangeResult({
    required this.source,
    required this.book,
    required this.chapterIndex,
    required this.chapterProgress,
    required this.chapterCount,
    this.shelfBook,
  });

  final RegisteredBookSource source;
  final BookSourceBook book;
  final int chapterIndex;
  final double chapterProgress;
  final int chapterCount;
  final Book? shelfBook;
}

class BookSourceChangeConflict implements Exception {
  const BookSourceChangeConflict();

  @override
  String toString() => 'The selected source version is already on the shelf.';
}
