import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

import '../protocol/book_source_protocol.dart';

/// The callable surface exposed by HTML-backed reading sources.
///
/// These sources embed their implementation in inline `<script>` elements
/// and return JSON from a small set of conventional functions. Keeping the
/// contract here lets import, compatibility scanning, and execution agree on
/// the same capabilities without recognizing individual source names.
class SourceHtmlContract {
  SourceHtmlContract._(this.script, this.functions);

  static final SourceHtmlContract _empty = SourceHtmlContract._('', const {});
  static final Map<String, SourceHtmlContract> _cache = {};
  static const int _maxCachedDocuments = 8;
  static const int _maxCachedCharacters = 1000000;
  static int _cachedCharacters = 0;

  factory SourceHtmlContract.parse(Object? html) {
    final source = html is String ? html.trim() : '';
    if (source.isEmpty) return _empty;
    final cached = _cache.remove(source);
    if (cached != null) {
      _cache[source] = cached;
      return cached;
    }
    final document = html_parser.parse(source);
    final scripts = document
        .querySelectorAll('script')
        .where((element) => element.attributes['src']?.trim().isEmpty ?? true)
        .map((element) => element.text)
        .where((script) => script.trim().isNotEmpty)
        .join('\n');
    final functions = <String>{};
    for (final match in RegExp(
      r'(?:^|[;{}]\s*)\s*(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\(',
      multiLine: true,
    ).allMatches(scripts)) {
      functions.add(match.group(1)!);
    }
    final parsed = SourceHtmlContract._(scripts, Set.unmodifiable(functions));
    if (source.length <= _maxCachedCharacters) {
      while (_cache.isNotEmpty &&
          (_cache.length >= _maxCachedDocuments ||
              _cachedCharacters + source.length > _maxCachedCharacters)) {
        final oldest = _cache.keys.first;
        _cachedCharacters -= oldest.length;
        _cache.remove(oldest);
      }
      _cache[source] = parsed;
      _cachedCharacters += source.length;
    }
    return parsed;
  }

  final String script;
  final Set<String> functions;

  bool get isSource => script.isNotEmpty && functions.isNotEmpty;
  bool supports(String name) => functions.contains(name);

  Set<String> get capabilities => <String>{
    if (supports('search')) 'search',
    if (supports('info')) 'detail',
    if (supports('chapter')) 'catalog',
    if (supports('content')) 'content',
  };

  String invoke(String function, List<Object?> arguments) {
    if (!supports(function)) {
      throw BookSourceProtocolException(
        'HTML source does not define the $function function.',
      );
    }
    return '''
$script
if (typeof $function !== 'function') {
  throw new Error(${jsonEncode('HTML source does not define $function.')});
}
$function(...${jsonEncode(arguments)})
''';
  }
}
