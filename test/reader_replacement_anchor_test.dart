import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/pages/reader/reader_replacement_anchor.dart';

void main() {
  test('removed leading text keeps the same visible paragraph', () {
    final advertisements = List.filled(30, '广告一行\n').join();
    const passage = '已经读到的实际段落。\n后续正文继续。';
    final before = '$advertisements$passage';
    final anchor = captureReaderReplacementAnchor(
      before,
      advertisements.length,
    );

    final offset = resolveReaderReplacementAnchor(
      anchor,
      passage,
      previousTextLength: before.length,
    );

    expect(offset, 0);
    expect(passage.substring(offset), startsWith('已经读到'));
  });

  test('context selects the same passage among duplicate excerpts', () {
    final quote = List.filled(80, '重复').join();
    final leading = List.filled(200, '广告').join();
    final before = '$leading第一处\n$quote\n甲后文\n第二处\n$quote\n乙后文';
    final oldOffset = before.lastIndexOf(quote);
    final after = before.substring(leading.length);

    final offset = resolveReaderReplacementAnchor(
      captureReaderReplacementAnchor(before, oldOffset),
      after,
      previousTextLength: before.length,
    );

    expect(offset, after.lastIndexOf(quote));
  });

  test('anchor accepts whitespace changes without changing the passage', () {
    const before = '广告广告\n实际段落\n\n后续正文';
    const after = '实际段落  后续正文';
    final offset = resolveReaderReplacementAnchor(
      captureReaderReplacementAnchor(before, before.indexOf('实际')),
      after,
      previousTextLength: before.length,
    );

    expect(offset, 0);
  });

  test('a removed visible excerpt falls forward to its retained suffix', () {
    final removed = List.filled(72, '广').join();
    final before = '前面正文$removed后续段落';
    const after = '前面正文后续段落';
    final offset = resolveReaderReplacementAnchor(
      captureReaderReplacementAnchor(before, 4),
      after,
      previousTextLength: before.length,
    );

    expect(offset, 4);
    expect(after.substring(offset), '后续段落');
  });
}
