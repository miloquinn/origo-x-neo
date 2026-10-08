import 'dart:math' as math;

import 'package:xxread/core/reader/canonical_locator.dart';

TextAnchor captureReaderReplacementAnchor(String text, int offset) {
  final start = offset.clamp(0, text.length);
  final end = math.min(text.length, start + 72);
  return TextAnchor.create(
    quote: text.substring(start, end),
    prefix: text.substring(math.max(0, start - 48), start),
    suffix: text.substring(end, math.min(text.length, end + 48)),
    startOffsetUtf16: start,
    lengthUtf16: end - start,
    offsetHint: start,
  );
}

/// Keeps the visible excerpt in view when a rule removes text before it.
/// Context distinguishes repeated excerpts; progression is a final fallback
/// when the visible passage itself has been entirely replaced.
int resolveReaderReplacementAnchor(
  TextAnchor anchor,
  String text, {
  required int previousTextLength,
}) {
  if (text.isEmpty) return 0;
  final hint = anchor.startOffsetUtf16 ?? anchor.offsetHint ?? 0;
  final normalized = StringBuffer();
  final offsets = <int>[];
  var inWhitespace = false;
  for (var index = 0; index < text.length; index++) {
    final character = text[index];
    final whitespace = character.trim().isEmpty;
    if (whitespace) {
      if (inWhitespace) continue;
      normalized.write(' ');
    } else {
      normalized.write(character);
    }
    offsets.add(index);
    inWhitespace = whitespace;
  }
  final haystack = normalized.toString();

  int? find(String quote, {bool atEnd = false}) {
    quote = quote.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (quote.isEmpty) return null;
    int? best;
    var bestContext = -1;
    var bestDistance = 1 << 62;
    var from = 0;
    while (from <= haystack.length - quote.length) {
      final match = haystack.indexOf(quote, from);
      if (match < 0) break;
      final end = match + quote.length;
      final offset = atEnd
          ? (end < offsets.length ? offsets[end] : text.length)
          : offsets[match];
      var context = 0;
      final prefix = anchor.prefix?.replaceAll(RegExp(r'\s+'), ' ').trim();
      final suffix = anchor.suffix?.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (prefix != null &&
          haystack.substring(0, match).trimRight().endsWith(prefix)) {
        context++;
      }
      if (suffix != null &&
          haystack.substring(end).trimLeft().startsWith(suffix)) {
        context++;
      }
      final distance = (offset - hint).abs();
      if (context > bestContext ||
          (context == bestContext && distance < bestDistance)) {
        best = offset;
        bestContext = context;
        bestDistance = distance;
      }
      from = match + 1;
    }
    return best;
  }

  final quoteOffset = find(anchor.quote);
  if (quoteOffset != null) return quoteOffset;
  final suffixOffset = find(anchor.suffix ?? '');
  if (suffixOffset != null) return suffixOffset;
  final prefixEnd = find(anchor.prefix ?? '', atEnd: true);
  if (prefixEnd != null) return prefixEnd;
  if (previousTextLength <= 0) return hint.clamp(0, text.length);
  return (text.length * hint / previousTextLength).round().clamp(
    0,
    text.length,
  );
}
