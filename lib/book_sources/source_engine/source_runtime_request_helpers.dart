part of 'source_runtime_requests.dart';

Map<String, String> requestVariables(
  Map<String, Object?> state,
  Map<String, String> variables,
) => <String, String>{
  for (final entry in state.entries)
    if (entry.value != null) entry.key: '${entry.value}',
  ...variables,
};

String? decodeSourceDataTarget(String value) {
  final optionsStart = value.lastIndexOf(RegExp(r',\s*\{'));
  final dataPart = optionsStart < 0 ? value : value.substring(0, optionsStart);
  if (!dataPart.startsWith('data:')) return null;
  final comma = dataPart.indexOf(',');
  if (comma < 0) return null;
  final metadata = dataPart.substring(0, comma).toLowerCase();
  final payload = dataPart.substring(comma + 1);
  try {
    // A typed data request carries local bytes even when those bytes happen
    // to contain an HTTP URL. Reuse the request parser's type contract before
    // considering the legacy untyped URL-wrapper behavior.
    if (optionsStart >= 0) {
      try {
        if (SourceRequestTemplate.parse(value, baseUri: Uri()).syntheticBody !=
            null) {
          return null;
        }
      } on BookSourceProtocolException {
        // Untyped data wrappers are not request targets until decoded below.
      }
    }
    final decoded = metadata.contains(';base64')
        ? utf8.decode(base64Decode(payload), allowMalformed: true)
        : Uri.decodeComponent(payload);
    final uri = Uri.tryParse(decoded.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return optionsStart < 0
        ? decoded.trim()
        : '$decoded${value.substring(optionsStart)}';
  } on Object {
    return null;
  }
}

String? _decodeInteractionHtml(String value) {
  final comma = value.indexOf(',');
  if (comma < 0) return null;
  final metadata = value.substring(0, comma).toLowerCase();
  final payload = value.substring(comma + 1);
  try {
    return metadata.contains(';base64')
        ? utf8.decode(base64Decode(payload), allowMalformed: true)
        : Uri.decodeComponent(payload);
  } on Object {
    return null;
  }
}

Map<String, String> _responseStringMap(
  Object? value,
  Map<String, String> fallback,
) {
  if (value is! Map) return fallback;
  return {
    for (final entry in value.entries) '${entry.key}': '${entry.value ?? ''}',
  };
}

Future<String> _replaceAsync(
  String input,
  RegExp pattern,
  Future<String> Function(RegExpMatch match) replacement,
) async {
  final output = StringBuffer();
  var offset = 0;
  for (final match in pattern.allMatches(input)) {
    output.write(input.substring(offset, match.start));
    output.write(await replacement(match));
    offset = match.end;
  }
  output.write(input.substring(offset));
  return output.toString();
}

bool _isDeclarativeVariable(String expression, Map<String, String> variables) {
  if (variables.containsKey(expression)) return true;
  final arithmetic = RegExp(
    r'^([A-Za-z_]\w*)\s*[+-]\s*\d+$',
  ).firstMatch(expression);
  return arithmetic != null && variables.containsKey(arithmetic.group(1));
}

String _scriptText(Object? value) => switch (value) {
  null => '',
  String text => text,
  Map _ || List _ => jsonEncode(value),
  _ => '$value',
};
