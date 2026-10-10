import 'replace_rule_execution.dart';

const int replaceRuleMaximumOutputCharacters = 16 * 1024 * 1024;
const int replaceRuleMaximumExpansionRatio = 32;

final RegExp _inlineFlags = RegExp(r'\(\?([ims]+)\)');
final RegExp _scopeSeparator = RegExp(r'[;,\n]');

bool isUnsupportedReplaceRuleReplacement(
  String replacement, {
  required bool isRegex,
}) => isRegex && replacement.trimLeft().startsWith('@js:');

class PreparedReplaceRule {
  PreparedReplaceRule(ReplaceRuleExecutionRule rule)
    : source = rule,
      pattern = rule.isRegex ? compileReplaceRulePattern(rule.pattern) : null;

  final ReplaceRuleExecutionRule source;
  final RegExp? pattern;

  bool appliesTo(
    ReplaceRuleTarget target,
    String bookTitle,
    String? sourceName, [
    String? sourceUrl,
  ]) {
    if (!source.enabled) return false;
    if (target == ReplaceRuleTarget.title
        ? !source.scopeTitle
        : !source.scopeContent) {
      return false;
    }
    return replaceRuleMatchesScope(source, bookTitle, sourceName, sourceUrl);
  }

  String apply(String input) {
    if (source.isRegex) {
      return input.replaceAllMapped(
        pattern!,
        (match) => expandReplaceRuleReplacement(source.replacement, match),
      );
    }
    return input.replaceAll(source.pattern, source.replacement);
  }

  ReplaceRuleMappedText applyWithRanges(
    String input,
    List<ReplaceRuleTextRange> ranges,
  ) {
    final matches = source.isRegex
        ? pattern!.allMatches(input)
        : source.pattern.allMatches(input);
    return applyReplaceRuleMatches(
      input,
      ranges,
      matches,
      (match) => source.isRegex
          ? expandReplaceRuleReplacement(source.replacement, match)
          : source.replacement,
    );
  }
}

class ReplaceRuleMappedText {
  const ReplaceRuleMappedText(this.text, this.ranges);

  final String text;
  final List<ReplaceRuleTextRange> ranges;
}

ReplaceRuleMappedText normalizeReplaceRuleContentWithRanges(
  String input,
  List<ReplaceRuleTextRange> ranges,
) {
  final edits = <_ReplaceRuleTextEdit>[];
  var lineStart = 0;
  for (final separator in RegExp(r'\r?\n').allMatches(input)) {
    _addTrimEdits(input, lineStart, separator.start, edits);
    if (separator.end - separator.start == 2) {
      edits.add(_ReplaceRuleTextEdit(separator.start, separator.start + 1, ''));
    }
    lineStart = separator.end;
  }
  _addTrimEdits(input, lineStart, input.length, edits);
  return _applyReplaceRuleEdits(input, ranges, edits);
}

ReplaceRuleMappedText applyReplaceRuleMatches(
  String input,
  List<ReplaceRuleTextRange> ranges,
  Iterable<Match> matches,
  String Function(Match match) replacement,
) {
  final edits = <_ReplaceRuleTextEdit>[
    for (final match in matches)
      _ReplaceRuleTextEdit(match.start, match.end, replacement(match)),
  ];
  return _applyReplaceRuleEdits(input, ranges, edits);
}

void _addTrimEdits(
  String input,
  int start,
  int end,
  List<_ReplaceRuleTextEdit> edits,
) {
  final line = input.substring(start, end);
  final leading = line.length - line.trimLeft().length;
  final trailing = line.length - line.trimRight().length;
  if (leading > 0) edits.add(_ReplaceRuleTextEdit(start, start + leading, ''));
  final trailingStart = end - trailing;
  if (trailing > 0 && trailingStart >= start + leading) {
    edits.add(_ReplaceRuleTextEdit(trailingStart, end, ''));
  }
}

ReplaceRuleMappedText _applyReplaceRuleEdits(
  String input,
  List<ReplaceRuleTextRange> ranges,
  List<_ReplaceRuleTextEdit> edits,
) {
  if (edits.isEmpty) return ReplaceRuleMappedText(input, ranges);
  final output = StringBuffer();
  var cursor = 0;
  for (final edit in edits) {
    output
      ..write(input.substring(cursor, edit.start))
      ..write(edit.replacement);
    cursor = edit.end;
  }
  output.write(input.substring(cursor));
  final mapped = <ReplaceRuleTextRange>[];
  for (final range in ranges) {
    final start = _mapReplaceRuleBoundary(
      range.startOffset,
      edits,
      isStart: true,
    );
    final end = _mapReplaceRuleBoundary(range.endOffset, edits, isStart: false);
    if (end > start) {
      mapped.add(range.copyWith(startOffset: start, endOffset: end));
    }
  }
  return ReplaceRuleMappedText(output.toString(), mapped);
}

int _mapReplaceRuleBoundary(
  int offset,
  List<_ReplaceRuleTextEdit> edits, {
  required bool isStart,
}) {
  var delta = 0;
  for (final edit in edits) {
    final replacementStart = edit.start + delta;
    if (edit.start == edit.end && offset == edit.start) {
      return replacementStart;
    }
    if (offset < edit.start || (!isStart && offset == edit.start)) {
      return offset + delta;
    }
    if (offset < edit.end) {
      return isStart
          ? replacementStart
          : replacementStart + edit.replacement.length;
    }
    delta += edit.replacement.length - (edit.end - edit.start);
  }
  return offset + delta;
}

class _ReplaceRuleTextEdit {
  const _ReplaceRuleTextEdit(this.start, this.end, this.replacement);

  final int start;
  final int end;
  final String replacement;
}

List<PreparedReplaceRule> prepareReplaceRules(
  Iterable<ReplaceRuleExecutionRule> rules,
) {
  final ordered = rules.where((rule) => rule.enabled).toList(growable: false)
    ..sort((left, right) => left.order.compareTo(right.order));
  return ordered.map(PreparedReplaceRule.new).toList(growable: false);
}

bool replaceRuleMatchesScope(
  ReplaceRuleExecutionRule rule,
  String title,
  String? source, [
  String? sourceUrl,
]) {
  return replaceRuleScopeMatches(
    scope: rule.scope,
    excludeScope: rule.excludeScope,
    title: title,
    sourceName: source,
    sourceUrl: sourceUrl,
  );
}

bool replaceRuleScopeMatches({
  required String scope,
  required String excludeScope,
  required String title,
  String? sourceName,
  String? sourceUrl,
}) {
  final fields = <String>[title, sourceName ?? '', sourceUrl ?? '']
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  bool contains(String value) => value
      .split(_scopeSeparator)
      .map((item) => item.trim().toLowerCase())
      .where((item) => item.isNotEmpty)
      .any(
        (token) => fields.any(
          (field) => field.contains(token) || token.contains(field),
        ),
      );
  if (contains(excludeScope)) return false;
  return scope.trim().isEmpty || contains(scope);
}

String expandReplaceRuleReplacement(String replacement, Match match) {
  final output = StringBuffer();
  for (var index = 0; index < replacement.length; index++) {
    final character = replacement[index];
    if (character == r'\' && index + 1 < replacement.length) {
      output.write(replacement[++index]);
      continue;
    }
    if (character != r'$' || index + 1 >= replacement.length) {
      output.write(character);
      continue;
    }
    if (replacement[index + 1] == '{') {
      final end = replacement.indexOf('}', index + 2);
      if (end > index + 2 && match is RegExpMatch) {
        final name = replacement.substring(index + 2, end);
        try {
          output.write(match.namedGroup(name) ?? '');
          index = end;
          continue;
        } on ArgumentError {
          // Preserve an unknown named reference as literal text.
        }
      }
      output.write(character);
      continue;
    }
    final first = replacement.codeUnitAt(index + 1) - 48;
    if (first < 0 || first > 9 || first > match.groupCount) {
      output.write(character);
      continue;
    }
    var group = first;
    var cursor = index + 2;
    while (cursor < replacement.length) {
      final digit = replacement.codeUnitAt(cursor) - 48;
      if (digit < 0 || digit > 9) break;
      final candidate = group * 10 + digit;
      if (candidate > match.groupCount) break;
      group = candidate;
      cursor++;
    }
    output.write(match.group(group) ?? '');
    index = cursor - 1;
  }
  return output.toString();
}

RegExp compileReplaceRulePattern(String pattern) {
  var source = _replaceJavaPosixPunctuation(
    _expandJavaQuotedRegexLiterals(pattern),
  );
  var caseSensitive = true;
  var multiLine = false;
  var dotAll = false;
  // Reading-source JVM rules commonly place flags at the beginning or after an
  // alternation. Preserve the historical Origo X behavior: promote every
  // supported inline flag to the complete Dart expression.
  source = source.replaceAllMapped(_inlineFlags, (match) {
    final flags = match.group(1)!;
    if (flags.contains('i')) caseSensitive = false;
    if (flags.contains('m')) multiLine = true;
    if (flags.contains('s')) dotAll = true;
    return '';
  });
  source = replaceRuleHorizontalWhitespace(source);
  return RegExp(
    source,
    caseSensitive: caseSensitive,
    multiLine: multiLine,
    dotAll: dotAll,
    unicode: RegExp(r'\\[pP]\{').hasMatch(source) || source.contains(r'\u{'),
  );
}

String _replaceJavaPosixPunctuation(String source) {
  const ranges = r'\x21-\x2f\x3a-\x40\x5b-\x60\x7b-\x7e';
  final output = StringBuffer();
  var inClass = false;
  for (var index = 0; index < source.length; index++) {
    if (source.startsWith(r'\p{Punct}', index)) {
      output.write(inClass ? ranges : '[$ranges]');
      index += r'\p{Punct}'.length - 1;
      continue;
    }
    if (source.startsWith(r'\P{Punct}', index)) {
      if (inClass) {
        throw const FormatException(
          r'\P{Punct} inside a character class is unsupported.',
        );
      }
      output.write('[^$ranges]');
      index += r'\P{Punct}'.length - 1;
      continue;
    }
    final character = source[index];
    if (character == r'\' && index + 1 < source.length) {
      output
        ..write(character)
        ..write(source[++index]);
      continue;
    }
    if (character == '[') inClass = true;
    if (character == ']' && inClass) inClass = false;
    output.write(character);
  }
  return output.toString();
}

String _expandJavaQuotedRegexLiterals(String source) {
  final output = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (source[index] != r'\' ||
        index + 1 >= source.length ||
        source[index + 1] != 'Q') {
      if (source[index] == r'\' && index + 1 < source.length) {
        output
          ..write(source[index])
          ..write(source[++index]);
      } else {
        output.write(source[index]);
      }
      continue;
    }
    final literalStart = index + 2;
    var literalEnd = source.length;
    for (var cursor = literalStart; cursor + 1 < source.length; cursor++) {
      if (source[cursor] == r'\' && source[cursor + 1] == 'E') {
        literalEnd = cursor;
        break;
      }
    }
    output.write(RegExp.escape(source.substring(literalStart, literalEnd)));
    if (literalEnd == source.length) break;
    index = literalEnd + 1;
  }
  return output.toString();
}

String replaceRuleHorizontalWhitespace(String source) {
  final output = StringBuffer();
  var inClass = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (character == r'\' && index + 1 < source.length) {
      final escaped = source[index + 1];
      if (escaped == 'h') {
        output.write(
          inClass
              ? r'\t\x20\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000'
              : r'[\t\x20\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000]',
        );
        index++;
        continue;
      }
      if (escaped == 'H') {
        output.write(
          inClass
              ? r'\u0000-\u0008\u000a-\u001f\u0021-\u009f\u00a1-\u167f\u1681-\u180d\u180f-\u1fff\u200b-\u202e\u2030-\u205e\u2060-\u2fff\u3001-\u{10ffff}'
              : r'[^\t\x20\u00a0\u1680\u180e\u2000-\u200a\u202f\u205f\u3000]',
        );
        index++;
        continue;
      }
      output
        ..write(character)
        ..write(escaped);
      index++;
      continue;
    }
    if (character == '[') inClass = true;
    if (character == ']' && inClass) inClass = false;
    output.write(character);
  }
  return output.toString();
}

int replaceRuleOutputCharacterLimit(Iterable<String> inputs) {
  final inputCharacters = inputs.fold<int>(
    0,
    (sum, value) => sum + value.length,
  );
  if (inputCharacters == 0) return 1024 * 1024;
  return (inputCharacters * replaceRuleMaximumExpansionRatio).clamp(
    1024 * 1024,
    replaceRuleMaximumOutputCharacters,
  );
}
