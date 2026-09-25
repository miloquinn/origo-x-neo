import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/core/reader/reader_desktop_resize_controller.dart';

void main() {
  testWidgets('keeps pagination size stable until desktop resize settles', (
    tester,
  ) async {
    final controller = ReaderDesktopResizeController();
    addTearDown(controller.dispose);
    var settledCount = 0;

    Size resolve(Size size) => controller.resolve(
      size,
      enabled: true,
      onSettled: () => settledCount += 1,
    );

    expect(resolve(const Size(1200, 800)), const Size(1200, 800));
    expect(resolve(const Size(1180, 800)), const Size(1200, 800));
    await tester.pump(const Duration(milliseconds: 100));
    expect(resolve(const Size(1120, 760)), const Size(1200, 800));
    await tester.pump(const Duration(milliseconds: 139));
    expect(settledCount, 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(settledCount, 1);
    expect(resolve(const Size(1120, 760)), const Size(1120, 760));
  });

  testWidgets('uses live size when desktop stabilization is disabled', (
    tester,
  ) async {
    final controller = ReaderDesktopResizeController();
    addTearDown(controller.dispose);

    expect(
      controller.resolve(
        const Size(900, 600),
        enabled: false,
        onSettled: () {},
      ),
      const Size(900, 600),
    );
    expect(
      controller.resolve(
        const Size(700, 500),
        enabled: false,
        onSettled: () {},
      ),
      const Size(700, 500),
    );
  });
}
