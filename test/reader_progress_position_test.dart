import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_progress_position.dart';
import 'package:xxread/core/reader/reader_settings.dart';

void main() {
  test('full book advances smoothly through chapter 50 of 100', () {
    const middle = ReaderProgressPosition(
      chapterIndex: 49,
      chapterCount: 100,
      chapterProgress: .5,
    );
    expect(middle.valueFor(ReaderProgressScope.book), .495);
    expect(middle.valueFor(ReaderProgressScope.chapter), .5);
    final target = middle.targetFor(ReaderProgressScope.book, .5)!;
    expect(target.chapterIndex, 50);
    expect(target.chapterProgress, 0);
  });

  test('chapter seeking stays in the current chapter', () {
    const position = ReaderProgressPosition(
      chapterIndex: 49,
      chapterCount: 100,
      chapterProgress: .5,
    );
    final target = position.targetFor(ReaderProgressScope.chapter, .75)!;
    expect(target.chapterIndex, 49);
    expect(target.chapterProgress, .75);
  });

  test('book seek preserves chapter-local progress at either endpoint', () {
    const position = ReaderProgressPosition(
      chapterIndex: 2,
      chapterCount: 4,
      chapterProgress: .5,
    );
    final start = position.targetFor(ReaderProgressScope.book, 0)!;
    final middle = position.targetFor(ReaderProgressScope.book, .375)!;
    final end = position.targetFor(ReaderProgressScope.book, 1)!;
    expect((start.chapterIndex, start.chapterProgress), (0, 0));
    expect((middle.chapterIndex, middle.chapterProgress), (1, .5));
    expect((end.chapterIndex, end.chapterProgress), (3, 1));
  });

  test('empty catalog disables navigation and has no seek target', () {
    const empty = ReaderProgressPosition(
      chapterIndex: 0,
      chapterCount: 0,
      chapterProgress: .5,
    );
    expect(empty.available, isFalse);
    expect(empty.hasPreviousChapter, isFalse);
    expect(empty.hasNextChapter, isFalse);
    expect(empty.valueFor(ReaderProgressScope.book), 0);
    expect(empty.targetFor(ReaderProgressScope.book, .5), isNull);
  });

  test('single chapter can seek but has no chapter buttons', () {
    const single = ReaderProgressPosition(
      chapterIndex: 0,
      chapterCount: 1,
      chapterProgress: .6,
    );
    expect(single.valueFor(ReaderProgressScope.book), .6);
    expect(single.hasPreviousChapter, isFalse);
    expect(single.hasNextChapter, isFalse);
  });

  test('invalid values and catalog shrink never escape valid bounds', () {
    const position = ReaderProgressPosition(
      chapterIndex: 99,
      chapterCount: 3,
      chapterProgress: double.nan,
    );
    expect(position.valueFor(ReaderProgressScope.chapter), 0);
    expect(position.hasNextChapter, isFalse);
    expect(
      position
          .targetFor(ReaderProgressScope.chapter, double.infinity)!
          .chapterIndex,
      2,
    );
    expect(position.targetFor(ReaderProgressScope.book, 2)!.chapterProgress, 1);
    expect(position.targetFor(ReaderProgressScope.book, -2)!.chapterIndex, 0);
  });
}
