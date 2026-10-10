import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_login_ui.dart';

void main() {
  test('accepts mixed quotes without changing action or field keys', () {
    final fields = parseSourceLoginFields(r'''[
      {"name": " 手动Token ", "type": "text", "default": "saved"},
      {'name': '源作者', 'type': 'text', 'default': 'O\'Brien'},
      {'name': '获取Token', 'type': 'button',
       'action': "setToken('a,b');", 'style': {'layout_flexBasisPercent': 0.27}}
    ]''');

    expect(fields.map((field) => field.name), [' 手动Token ', '源作者', '获取Token']);
    expect(fields[1].defaultValue, "O'Brien");
    expect(fields[2].action, "setToken('a,b');");
    expect(fields[2].flexBasisPercent, 0.27);
  });

  test('accepts declarative comments, unquoted keys and trailing commas', () {
    final fields = parseSourceLoginFields(r'''[
      // URL and comment markers inside quoted values remain literal.
      {name: 'endpoint', type: 'text', default: 'https://books.test/a/*b*/',},
      /* A section heading has no action. */
      {name: '设置', type: 'button',},
    ]''');

    expect(fields.map((field) => field.name), ['endpoint', '设置']);
    expect(fields.first.defaultValue, 'https://books.test/a/*b*/');
    expect(fields.last.isSectionHeading, isTrue);
  });

  test('strict arrays and already decoded values keep existing defaults', () {
    final fields = parseSourceLoginFields([
      {'name': 'password', 'type': 'PASSWORD', 'default': 'secret'},
      {
        'name': 'choice',
        'type': 'select',
        'chars': ['one', 'two'],
      },
      {'name': '  ', 'type': 'text'},
    ]);
    expect(fields.map((field) => field.type), ['password', 'select']);
    expect(fields.first.defaultValue, 'secret');
    expect(fields.last.chars, ['one', 'two']);
  });

  test('malformed declarations report errors instead of hiding the form', () {
    for (final raw in [
      '[{name: "account"',
      '[{name: "account", default: getToken()}]',
      '/* unfinished',
    ]) {
      expect(() => parseSourceLoginFields(raw), throwsFormatException);
    }
  });
}
