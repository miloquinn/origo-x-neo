import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/book_source_paragraph_action.dart';
import '../protocol/book_source_protocol.dart';
import '../../core/reader/reader_text_characters.dart';
import 'book_source_text_paginator.dart';

const _bookSourceBlockTags = {'p', 'div', 'li', 'blockquote'};

/// Matches the opening of any HTML tag (`<p`, `</br`, `<img`, …) without
/// requiring a closing `>`. Plain-text bodies never legitimately contain this
/// sequence, so the presence of a tag opener is enough to route the payload
/// through the HTML extraction path.
final _htmlTagOpener = RegExp(r'</?[a-z][a-z0-9]*', caseSensitive: false);

/// Converts a source payload into canonical chapter text.
///
/// This adapter owns source-specific HTML extraction and repeated remote page
/// marker cleanup. It deliberately does not inject indentation or paragraph
/// spacing; those are display settings applied later by the shared reader
/// text pipeline.
///
/// The parsing path is chosen by inspecting the content itself, not the
/// declared `contentType`. Source declarations are unreliable in the wild:
/// plain text is frequently labelled `text/html` and well-formed HTML
/// occasionally arrives as `text/plain`. Probing the content routes each
/// payload through the semantically correct path so the shared layout layer
/// always receives properly paragraph-separated text, which is the only
/// signal it can use to apply first-line indentation.
String readableBookSourceChapterText(
  BookSourceChapterContent content, {
  String fallbackTitle = '',
}) => readableBookSourceChapterProjection(
  content,
  fallbackTitle: fallbackTitle,
).text;

BookSourceChapterProjection readableBookSourceChapterProjection(
  BookSourceChapterContent content, {
  String fallbackTitle = '',
}) {
  final chapterTitles = <String>{
    if (content.title.trim().isNotEmpty) content.title,
    if (fallbackTitle.trim().isNotEmpty) fallbackTitle,
  };

  final extracted = _looksLikeHtml(content.content)
      ? _extractHtmlParagraphs(content)
      : _ExtractedChapter(
          paragraphs: _extractPlainTextParagraphs(
            content.content,
          ).map(_ExtractedParagraph.new).toList(growable: false),
        );

  final cleaned = _removeRepeatedSourcePageMarkerParagraphs(
    extracted.paragraphs,
  );
  final body = _removeRepeatedLeadingChapterTitle(cleaned, chapterTitles);
  return _projectParagraphs(body);
}

bool isImageOnlyBookSourceChapter(BookSourceChapterContent content) =>
    content.images.isNotEmpty &&
    readableBookSourceChapterText(content).trim().isEmpty;

/// Normalizes chapters whose parsing cost is large enough to disturb reader
/// frames on a background isolate. Short plain-text chapters stay local to
/// avoid paying isolate startup and message-copy overhead.
Future<String> readableBookSourceChapterTextAsync(
  BookSourceChapterContent content, {
  String fallbackTitle = '',
}) {
  final shouldUseWorker =
      _looksLikeHtml(content.content) || content.content.length >= 64 * 1024;
  if (!shouldUseWorker) {
    return Future<String>.value(
      readableBookSourceChapterText(content, fallbackTitle: fallbackTitle),
    );
  }
  return compute(
    _readableBookSourceChapterTextInBackground,
    <String, String>{
      'bookId': content.bookId,
      'chapterId': content.chapterId,
      'title': content.title,
      'content': content.content,
      'contentType': content.contentType,
      'fallbackTitle': fallbackTitle,
    },
    debugLabel: 'normalize book-source chapter',
  ).onError(
    (_, _) =>
        readableBookSourceChapterText(content, fallbackTitle: fallbackTitle),
  );
}

Future<BookSourceChapterProjection> readableBookSourceChapterProjectionAsync(
  BookSourceChapterContent content, {
  String fallbackTitle = '',
}) {
  final shouldUseWorker =
      _looksLikeHtml(content.content) || content.content.length >= 64 * 1024;
  if (!shouldUseWorker) {
    return Future<BookSourceChapterProjection>.value(
      readableBookSourceChapterProjection(
        content,
        fallbackTitle: fallbackTitle,
      ),
    );
  }
  return compute(
    _readableBookSourceChapterProjectionInBackground,
    <String, String>{
      'bookId': content.bookId,
      'chapterId': content.chapterId,
      'title': content.title,
      'content': content.content,
      'contentType': content.contentType,
      'fallbackTitle': fallbackTitle,
    },
    debugLabel: 'project book-source chapter',
  ).onError(
    (_, _) => readableBookSourceChapterProjection(
      content,
      fallbackTitle: fallbackTitle,
    ),
  );
}

String _readableBookSourceChapterTextInBackground(Map<String, String> values) =>
    readableBookSourceChapterText(
      BookSourceChapterContent(
        bookId: values['bookId']!,
        chapterId: values['chapterId']!,
        title: values['title']!,
        content: values['content']!,
        contentType: values['contentType']!,
      ),
      fallbackTitle: values['fallbackTitle']!,
    );

BookSourceChapterProjection _readableBookSourceChapterProjectionInBackground(
  Map<String, String> values,
) => readableBookSourceChapterProjection(
  BookSourceChapterContent(
    bookId: values['bookId']!,
    chapterId: values['chapterId']!,
    title: values['title']!,
    content: values['content']!,
    contentType: values['contentType']!,
  ),
  fallbackTitle: values['fallbackTitle']!,
);

bool _looksLikeHtml(String content) => _htmlTagOpener.hasMatch(content);

/// Preserves the source's own line structure: BOM is stripped and every hard
/// Unicode line break is folded to a canonical paragraph boundary, while
/// leading whitespace and blank lines remain available to downstream logic.
List<String> _extractPlainTextParagraphs(String raw) {
  final normalized = raw.replaceFirst('\uFEFF', '');
  return splitReaderTextLines(normalized);
}

/// Walks the parsed fragment and emits one canonical paragraph per block
/// boundary, `<br>`, or literal newline found inside a text node. Runs of
/// non-newline whitespace inside a segment are collapsed into a single
/// space.
_ExtractedChapter _extractHtmlParagraphs(BookSourceChapterContent content) {
  final marked = _markParagraphActions(
    content.content.replaceFirst('\uFEFF', ''),
    content,
  );
  final fragment = html_parser.parseFragment(marked.html);
  final paragraphs = <_ExtractedParagraph>[];
  final segment = StringBuffer();
  final segmentActions = <_PendingParagraphAction>[];

  void flush() {
    final text = segment.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) {
      paragraphs.add(_ExtractedParagraph(text, actions: [...segmentActions]));
    } else if (segmentActions.isNotEmpty && paragraphs.isNotEmpty) {
      paragraphs.last.actions.addAll(segmentActions);
    }
    segment.clear();
    segmentActions.clear();
  }

  void walk(Iterable<dom.Node> nodes) {
    for (final child in nodes) {
      if (child is dom.Element) {
        if (_bookSourceBlockTags.contains(child.localName)) {
          flush();
          walk(child.nodes);
          flush();
          continue;
        }
        if (child.localName == 'br') {
          flush();
          continue;
        }
        if (child.localName == 'origo-paragraph-action') {
          final marker = int.tryParse(child.attributes['data-marker'] ?? '');
          if (marker != null && marker < marked.actions.length) {
            segmentActions.add(marked.actions[marker]);
          }
          continue;
        }
        walk(child.nodes);
      } else if (child is dom.Text) {
        // A literal newline inside a text node is the common shape for
        // sources that dump mostly-plain paragraphs inside a wrapping tag
        // (e.g. a chapter with one stray inline `<img>`/`<b>` and every
        // other paragraph separated only by `\n`). Treat it like an
        // implicit `<br>` so those paragraphs still get split instead of
        // being silently glued together by the `\s+` collapse in flush().
        final lines = splitReaderTextLines(child.data);
        for (var i = 0; i < lines.length; i++) {
          if (i > 0) flush();
          segment.write(lines[i]);
        }
      }
    }
  }

  walk(fragment.nodes);
  flush();
  // Degenerate payloads (image-only chapters, unclosed tags, comments) may
  // yield no extractable text; fall back to whatever the fragment exposes as
  // plain text so the reader never renders a blank page.
  if (paragraphs.isEmpty) {
    final fallback = fragment.text?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return _ExtractedChapter(
        paragraphs: <_ExtractedParagraph>[_ExtractedParagraph(fallback)],
      );
    }
  }
  return _ExtractedChapter(paragraphs: paragraphs);
}

List<_ExtractedParagraph> _removeRepeatedLeadingChapterTitle(
  List<_ExtractedParagraph> values,
  Set<String> chapterTitles,
) {
  final titleKeys = chapterTitles
      .map(_chapterTitleKey)
      .where((value) => value.isNotEmpty)
      .toSet();
  if (values.isEmpty || titleKeys.isEmpty) return values;
  final firstContentIndex = values.indexWhere(
    (value) => value.text.trim().isNotEmpty,
  );
  if (firstContentIndex < 0 ||
      !titleKeys.contains(_chapterTitleKey(values[firstContentIndex].text))) {
    return values;
  }
  var bodyStart = firstContentIndex + 1;
  while (bodyStart < values.length && values[bodyStart].text.trim().isEmpty) {
    bodyStart++;
  }
  return values.sublist(bodyStart);
}

String _chapterTitleKey(String value) => value
    .replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<_ExtractedParagraph> _removeRepeatedSourcePageMarkerParagraphs(
  List<_ExtractedParagraph> paragraphs,
) {
  final keptTexts = removeRepeatedSourcePageMarkers(
    paragraphs.map((paragraph) => paragraph.text),
  );
  if (keptTexts.length == paragraphs.length) return paragraphs;
  final markersByTotal = <int, List<(int index, int page)>>{};
  final markerPattern = RegExp(r'^\s*(\d{1,4})\s*/\s*(\d{1,4})\s*$');
  for (var index = 0; index < paragraphs.length; index++) {
    final match = markerPattern.firstMatch(paragraphs[index].text);
    if (match == null) continue;
    final page = int.parse(match.group(1)!);
    final total = int.parse(match.group(2)!);
    if (total < 3 || page < 1 || page > total) continue;
    markersByTotal.putIfAbsent(total, () => []).add((index, page));
  }
  final removed = <int>{};
  for (final markers in markersByTotal.values) {
    if (markers.map((marker) => marker.$2).toSet().length >= 3) {
      removed.addAll(markers.map((marker) => marker.$1));
    }
  }
  return <_ExtractedParagraph>[
    for (var index = 0; index < paragraphs.length; index++)
      if (!removed.contains(index)) paragraphs[index],
  ];
}

BookSourceChapterProjection _projectParagraphs(
  List<_ExtractedParagraph> paragraphs,
) {
  final text = StringBuffer();
  final actions = <BookSourceParagraphAction>[];
  for (var index = 0; index < paragraphs.length; index++) {
    if (index > 0) text.write('\n');
    final paragraph = paragraphs[index];
    final start = text.length;
    text.write(paragraph.text);
    final end = text.length;
    for (final action in paragraph.actions) {
      actions.add(
        BookSourceParagraphAction(
          id: action.id,
          startOffset: start,
          endOffset: end,
          imageSource: action.imageSource,
          script: action.script,
          paragraphText: paragraph.text,
        ),
      );
    }
  }
  return BookSourceChapterProjection(
    text: text.toString(),
    actions: List<BookSourceParagraphAction>.unmodifiable(actions),
  );
}

_MarkedHtml _markParagraphActions(
  String raw,
  BookSourceChapterContent content,
) {
  final output = StringBuffer();
  final actions = <_PendingParagraphAction>[];
  var cursor = 0;
  final opener = RegExp(r'<img\b', caseSensitive: false);
  while (cursor < raw.length) {
    final match = opener.firstMatch(raw.substring(cursor));
    if (match == null) {
      output.write(raw.substring(cursor));
      break;
    }
    final tagStart = cursor + match.start;
    output.write(raw.substring(cursor, tagStart));
    final parsed = _parseActionImage(raw, tagStart);
    if (parsed == null) {
      output.write(raw.substring(tagStart, tagStart + match.end - match.start));
      cursor = tagStart + match.end - match.start;
      continue;
    }
    final marker = actions.length;
    actions.add(
      _PendingParagraphAction(
        id: '${content.bookId}:${content.chapterId}:$marker',
        imageSource: parsed.imageSource,
        script: parsed.script,
      ),
    );
    output.write(
      '<origo-paragraph-action data-marker="$marker"></origo-paragraph-action>',
    );
    cursor = parsed.tagEnd;
  }
  return _MarkedHtml(output.toString(), actions);
}

_ParsedActionImage? _parseActionImage(String raw, int tagStart) {
  final srcMatch = RegExp(
    r'''\bsrc\s*=\s*(["'])''',
    caseSensitive: false,
  ).firstMatch(raw.substring(tagStart));
  if (srcMatch == null) return null;
  final quote = srcMatch.group(1)!;
  final valueStart = tagStart + srcMatch.end;
  final firstTagClose = raw.indexOf('>', tagStart);
  if (firstTagClose >= 0 && valueStart > firstTagClose) return null;
  final separator = RegExp(r',\s*\{').firstMatch(raw.substring(valueStart));
  if (separator == null) return null;
  final firstClosingQuote = raw.indexOf(quote, valueStart);
  if (firstClosingQuote >= 0 &&
      firstClosingQuote < valueStart + separator.start) {
    return null;
  }
  final jsonStart = valueStart + separator.end - 1;
  final jsonEnd = _balancedJsonObjectEnd(raw, jsonStart);
  if (jsonEnd == null) return null;
  final decoded = _decodeImageOptions(raw.substring(jsonStart, jsonEnd));
  if (decoded == null || '${decoded['style']}'.toLowerCase() != 'text') {
    return null;
  }
  final script = decoded['click'];
  if (script is! String || script.trim().isEmpty) return null;
  var tagEnd = jsonEnd;
  if (tagEnd < raw.length && raw[tagEnd] == quote) tagEnd++;
  final close = raw.indexOf('>', tagEnd);
  if (close < 0) return null;
  return _ParsedActionImage(
    imageSource: _decodeHtmlText(raw.substring(valueStart, jsonEnd)),
    script: script,
    tagEnd: close + 1,
  );
}

int? _balancedJsonObjectEnd(String raw, int start) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var index = start; index < raw.length; index++) {
    final character = raw[index];
    final quoteEntityLength = _htmlQuoteEntityLength(raw, index);
    if (quoteEntityLength > 0) {
      if (inString && escaped) {
        escaped = false;
      } else {
        inString = !inString;
      }
      index += quoteEntityLength - 1;
      continue;
    }
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else if (character == '"') {
        inString = false;
      }
      continue;
    }
    if (character == '"') {
      inString = true;
    } else if (character == '{') {
      depth++;
    } else if (character == '}' && --depth == 0) {
      return index + 1;
    }
  }
  return null;
}

int _htmlQuoteEntityLength(String value, int index) {
  for (final entity in const <String>['&quot;', '&#34;', '&#x22;', '&#X22;']) {
    if (value.startsWith(entity, index)) return entity.length;
  }
  return 0;
}

Map<String, dynamic>? _decodeImageOptions(String value) {
  for (final candidate in <String>[value, _decodeHtmlText(value)]) {
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Try the entity-decoded representation next.
    }
  }
  return null;
}

String _decodeHtmlText(String value) =>
    html_parser
        .parseFragment(value.replaceAll('<', '&lt;').replaceAll('>', '&gt;'))
        .text ??
    value;

class _ExtractedChapter {
  const _ExtractedChapter({required this.paragraphs});

  final List<_ExtractedParagraph> paragraphs;
}

class _ExtractedParagraph {
  _ExtractedParagraph(this.text, {List<_PendingParagraphAction>? actions})
    : actions = actions ?? <_PendingParagraphAction>[];

  final String text;
  final List<_PendingParagraphAction> actions;
}

class _PendingParagraphAction {
  const _PendingParagraphAction({
    required this.id,
    required this.imageSource,
    required this.script,
  });

  final String id;
  final String imageSource;
  final String script;
}

class _MarkedHtml {
  const _MarkedHtml(this.html, this.actions);

  final String html;
  final List<_PendingParagraphAction> actions;
}

class _ParsedActionImage {
  const _ParsedActionImage({
    required this.imageSource,
    required this.script,
    required this.tagEnd,
  });

  final String imageSource;
  final String script;
  final int tagEnd;
}
