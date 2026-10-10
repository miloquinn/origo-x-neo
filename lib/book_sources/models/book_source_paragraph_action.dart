class BookSourceParagraphAction {
  const BookSourceParagraphAction({
    required this.id,
    required this.startOffset,
    required this.endOffset,
    required this.imageSource,
    required this.script,
    this.paragraphText = '',
  });

  final String id;
  final int startOffset;
  final int endOffset;
  final String imageSource;
  final String script;
  final String paragraphText;

  BookSourceParagraphAction copyWith({int? startOffset, int? endOffset}) =>
      BookSourceParagraphAction(
        id: id,
        startOffset: startOffset ?? this.startOffset,
        endOffset: endOffset ?? this.endOffset,
        imageSource: imageSource,
        script: script,
        paragraphText: paragraphText,
      );
}

class BookSourceChapterProjection {
  const BookSourceChapterProjection({
    required this.text,
    this.actions = const <BookSourceParagraphAction>[],
  });

  final String text;
  final List<BookSourceParagraphAction> actions;
}
