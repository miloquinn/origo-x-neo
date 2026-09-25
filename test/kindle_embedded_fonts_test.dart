import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xxread/services/books/kindle_embedded_fonts.dart';

void main() {
  test('resolves CSS fallback lists to the embedded KF8 FONT resource', () {
    final bytes = Uint8List.fromList(<int>[0, 1, 2, 3]);
    final styles = KindleEmbeddedFonts.fromCss(
      <String>[
        '@font-face { font-family: "jj"; src: url(kindle:embed:001O) }',
        '@font-face { font-family: "missing"; src: url(kindle:embed:001P) }',
      ],
      <int, Uint8List>{55: bytes},
    );

    final family = styles.resolve('"DK-SONGTI", "jj", serif');
    expect(family, startsWith('kindle_'));
    expect(styles.bytesByFamily[family], same(bytes));
    expect(styles.resolve('"DK-SONGTI", serif'), 'serif');
    expect(styles.resolve('"missing", serif'), 'serif');

    final document = html_parser.parse(
      '<body class="book"><p class="body">Text</p>'
      '<p class="other" style="font-family: sans-serif">Other</p></body>',
    );
    final rules = <String, String>{
      '.book': 'font-family: "jj", serif',
      '.body': 'font-family: "DK-SONGTI", "jj", serif',
    };
    expect(styles.forElement(document.querySelector('.body')!, rules), family);
    expect(
      styles.forElement(document.querySelector('.other')!, rules),
      'sans-serif',
    );
  });
}
