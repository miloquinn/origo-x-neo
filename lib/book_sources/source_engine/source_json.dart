import 'dart:convert';

/// Decodes declarative source data using the tolerant syntax found in exports.
///
/// The strict path is unchanged. Legacy declarations may use single quotes,
/// unquoted keys, comments or trailing commas. This lexer only normalizes data;
/// expressions, function calls and other JavaScript still fail JSON decoding.
Object? decodeSourceJson(String input) {
  final text = input.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
  try {
    return jsonDecode(text);
  } on FormatException {
    return jsonDecode(_normalize(text));
  }
}

String _normalize(String text) {
  final tokens = <String>[];
  var index = 0;
  while (index < text.length) {
    final char = text[index];
    if (char.trim().isEmpty) {
      index++;
      continue;
    }
    if (text.startsWith('//', index)) {
      final end = text.indexOf('\n', index + 2);
      index = end < 0 ? text.length : end + 1;
      continue;
    }
    if (text.startsWith('/*', index)) {
      final end = text.indexOf('*/', index + 2);
      if (end < 0) throw const FormatException('Unclosed source comment.');
      index = end + 2;
      continue;
    }
    if (char == '"' || char == "'") {
      final quote = char;
      final token = StringBuffer('"');
      var closed = false;
      index++;
      while (index < text.length) {
        final next = text[index++];
        if (next == quote) {
          closed = true;
          break;
        }
        if (next == r'\') {
          if (index == text.length) break;
          final escaped = text[index++];
          if (escaped == "'") {
            token.write("'");
          } else {
            token.write(r'\');
            token.write(escaped);
          }
        } else if (next == '"') {
          token.write(r'\"');
        } else {
          token.write(next);
        }
      }
      if (!closed) throw const FormatException('Unclosed source string.');
      token.write('"');
      tokens.add(token.toString());
      continue;
    }
    if ('{}[]:,'.contains(char)) {
      tokens.add(char);
      index++;
      continue;
    }
    final start = index++;
    while (index < text.length &&
        text[index].trim().isNotEmpty &&
        !'{}[]:,"\'/'.contains(text[index])) {
      index++;
    }
    tokens.add(text.substring(start, index));
  }

  final output = StringBuffer();
  final keyPattern = RegExp(r'^[\w$.-]+$');
  for (var index = 0; index < tokens.length; index++) {
    final token = tokens[index];
    final next = index + 1 < tokens.length ? tokens[index + 1] : null;
    if (token == ',' && (next == '}' || next == ']')) continue;
    final previous = index > 0 ? tokens[index - 1] : null;
    output.write(
      next == ':' &&
              (previous == '{' || previous == ',') &&
              keyPattern.hasMatch(token)
          ? jsonEncode(token)
          : token,
    );
    output.write(' ');
  }
  return output.toString();
}
