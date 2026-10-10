import 'package:flutter/foundation.dart';

import 'reader_settings.dart';

/// Catalog-relative progress; it does not require loading other chapters.
@immutable
class ReaderProgressPosition {
  const ReaderProgressPosition({
    required this.chapterIndex,
    required this.chapterCount,
    required this.chapterProgress,
  });

  final int chapterIndex;
  final int chapterCount;
  final double chapterProgress;

  bool get available => chapterCount > 0;
  int get boundedChapterIndex =>
      available ? chapterIndex.clamp(0, chapterCount - 1) : 0;
  bool get hasPreviousChapter => available && boundedChapterIndex > 0;
  bool get hasNextChapter =>
      available && boundedChapterIndex < chapterCount - 1;

  double valueFor(ReaderProgressScope scope) {
    if (!available) return 0;
    final progress = _bounded(chapterProgress);
    return switch (scope) {
      ReaderProgressScope.book =>
        (boundedChapterIndex + progress) / chapterCount,
      ReaderProgressScope.chapter => progress,
    };
  }

  ReaderProgressTarget? targetFor(ReaderProgressScope scope, double value) {
    if (!available) return null;
    final fraction = _bounded(value);
    if (scope == ReaderProgressScope.chapter) {
      return ReaderProgressTarget(boundedChapterIndex, fraction);
    }
    // 100% means the end of the last chapter, not a nonexistent next chapter.
    if (fraction == 1) return ReaderProgressTarget(chapterCount - 1, 1);
    final scaled = fraction * chapterCount;
    final index = scaled.floor();
    return ReaderProgressTarget(index, scaled - index);
  }

  static double _bounded(double value) =>
      value.isFinite ? value.clamp(0.0, 1.0) : 0;
}

@immutable
class ReaderProgressTarget {
  const ReaderProgressTarget(this.chapterIndex, this.chapterProgress);

  final int chapterIndex;
  final double chapterProgress;
}
