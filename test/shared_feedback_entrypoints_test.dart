import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production feedback uses the shared toast entrypoint', () {
    final violations = <String>[];
    final rawSnackBar = RegExp(r'\bSnackBar\s*\(');
    final messengerSnackBar = RegExp(r'\.showSnackBar\s*\(');

    for (final file in _dartFiles(Directory('lib'))) {
      final source = file.readAsStringSync();
      if (rawSnackBar.hasMatch(source) || messengerSnackBar.hasMatch(source)) {
        violations.add(file.path.replaceAll('\\', '/'));
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Production feedback must use showSideToast so every visual mode '
          'shares one presentation contract:\n${violations.join('\n')}',
    );
  });
}

Iterable<File> _dartFiles(Directory directory) => directory
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'));
