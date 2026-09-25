import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/l10n/app_localizations_zh.dart';
import 'package:xxread/pages/reader/book_source/book_source_reader_page.dart';

void main() {
  testWidgets('reports completion only after readable content is available', (
    tester,
  ) async {
    const active = true;
    var readable = false;
    var readyCount = 0;
    var errorCount = 0;
    final handoff = BookSourceChangeReaderHandoff(
      isActive: () => active,
      hasReadableContent: () => readable,
      loadError: () => null,
      onReady: () => readyCount++,
      onLoadError: () => errorCount++,
      pollInterval: const Duration(milliseconds: 10),
    )..start();
    addTearDown(handoff.dispose);

    await tester.pump(const Duration(milliseconds: 30));
    expect(readyCount, 0);

    readable = true;
    await tester.pump(const Duration(milliseconds: 10));
    expect(readyCount, 1);

    await tester.pump(const Duration(milliseconds: 30));
    expect(readyCount, 1);
    expect(errorCount, 0);
  });

  testWidgets('reports one failure per retry attempt before succeeding', (
    tester,
  ) async {
    Object? error = StateError('first failure');
    var readable = false;
    var readyCount = 0;
    var errorCount = 0;
    final handoff = BookSourceChangeReaderHandoff(
      isActive: () => true,
      hasReadableContent: () => readable,
      loadError: () => error,
      onReady: () => readyCount++,
      onLoadError: () => errorCount++,
      pollInterval: const Duration(milliseconds: 10),
    )..start();
    addTearDown(handoff.dispose);

    await tester.pump(const Duration(milliseconds: 30));
    expect(errorCount, 1);
    expect(readyCount, 0);

    error = null;
    await tester.pump(const Duration(milliseconds: 10));
    error = StateError('second failure');
    await tester.pump(const Duration(milliseconds: 10));
    expect(errorCount, 2);

    error = null;
    readable = true;
    await tester.pump(const Duration(milliseconds: 10));
    expect(readyCount, 1);
  });

  testWidgets('stops observing when the replacement reader closes', (
    tester,
  ) async {
    var active = true;
    var readable = false;
    var readyCount = 0;
    var errorCount = 0;
    final handoff = BookSourceChangeReaderHandoff(
      isActive: () => active,
      hasReadableContent: () => readable,
      loadError: () => null,
      onReady: () => readyCount++,
      onLoadError: () => errorCount++,
      pollInterval: const Duration(milliseconds: 10),
    )..start();
    addTearDown(handoff.dispose);

    active = false;
    await tester.pump(const Duration(milliseconds: 10));
    readable = true;
    await tester.pump(const Duration(milliseconds: 30));

    expect(readyCount, 0);
    expect(errorCount, 0);
  });

  test(
    'open failure copy explains recovery without exposing the exception',
    () {
      const rawError = 'StateError: socket exploded';
      final message = AppLocalizationsZh().bookSourceChangeReaderOpenFailed;

      expect(message, '来源已切换，但新章节暂时打不开。请重试或返回书架。');
      expect(message, isNot(contains(rawError)));
    },
  );
}
