import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:html/dom.dart' as html_dom;

/// Resolves KF8 CSS font aliases to FONT records embedded in the book.
/// Unavailable local/system faces are left to the reader's selected fallback.
class KindleEmbeddedFonts {
  KindleEmbeddedFonts._(this.familyByAlias, this.bytesByFamily);

  final Map<String, String> familyByAlias;
  final Map<String, Uint8List> bytesByFamily;

  factory KindleEmbeddedFonts.fromCss(
    Iterable<String> cssSources,
    Map<int, Uint8List> fontBytesByBlockIndex,
  ) {
    final aliases = <String, String>{};
    final fonts = <String, Uint8List>{};
    final facePattern = RegExp(
      r'@font-face\s*\{([^{}]*)\}',
      caseSensitive: false,
      dotAll: true,
    );
    final resourcePattern = RegExp(
      r'kindle:embed:([0-9a-v]+)',
      caseSensitive: false,
    );
    for (final source in cssSources) {
      for (final face in facePattern.allMatches(source)) {
        final declarations = face.group(1) ?? '';
        final alias = _cssProperty(declarations, 'font-family');
        final resource = resourcePattern.firstMatch(
          _cssProperty(declarations, 'src') ?? '',
        );
        if (alias == null || resource == null) continue;
        final blockIndex = int.tryParse(resource.group(1)!, radix: 32);
        final bytes = blockIndex == null
            ? null
            : fontBytesByBlockIndex[blockIndex - 1];
        if (bytes == null) continue;
        final family = 'kindle_${sha1.convert(bytes)}';
        aliases[_normalizeFamily(alias)] = family;
        fonts[family] = bytes;
      }
    }
    return KindleEmbeddedFonts._(aliases, fonts);
  }

  String? resolve(String? cssFamilyList) {
    if (cssFamilyList == null) return null;
    final candidates = cssFamilyList.split(',').map(_normalizeFamily).toList();
    for (final candidate in candidates) {
      final family = familyByAlias[candidate];
      if (family != null) return family;
    }
    for (final candidate in candidates) {
      if (_serifFamilies.contains(candidate)) return 'serif';
      if (_sansFamilies.contains(candidate)) return 'sans-serif';
      if (candidate == 'monospace') return 'monospace';
    }
    return null;
  }

  /// Applies the nearest CSS font declaration, including inherited body style.
  String? forElement(html_dom.Element element, Map<String, String> cssRules) {
    html_dom.Element? current = element;
    while (current != null) {
      final sources = <String?>[
        cssRules[current.localName?.toLowerCase()],
        for (final className in current.classes)
          cssRules['.${className.toLowerCase()}'],
        current.attributes['style'],
      ];
      for (final source in sources.reversed) {
        if (source == null) continue;
        final familyList = _fontFamilyPattern.firstMatch(source)?.group(1);
        if (familyList != null) return resolve(familyList);
      }
      current = current.parent;
    }
    return null;
  }
}

final RegExp _fontFamilyPattern = RegExp(
  r'font-family\s*:\s*([^;]+)',
  caseSensitive: false,
);

const Set<String> _serifFamilies = <String>{
  'serif',
  'songti',
  'songti sc',
  'songti tc',
  '宋体',
  '明体',
  '明朝',
  'mincho',
  'dk-songti',
};

const Set<String> _sansFamilies = <String>{
  'sans-serif',
  'heiti',
  'heiti sc',
  'heiti tc',
  '黑体',
  '细黑体',
  '微软雅黑',
  'dk-heiti',
};

String _normalizeFamily(String value) => value
    .trim()
    .replaceAll(RegExp(r'''^['"]|['"]$'''), '')
    .trim()
    .toLowerCase();

String? _cssProperty(String declarations, String property) {
  for (final declaration in declarations.split(';')) {
    final separator = declaration.indexOf(':');
    if (separator < 0) continue;
    if (declaration.substring(0, separator).trim().toLowerCase() == property) {
      return declaration.substring(separator + 1).trim();
    }
  }
  return null;
}
