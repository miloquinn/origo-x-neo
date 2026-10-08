import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/welcome_preview.dart';

void main() {
  testWidgets(
    'skip opens compact terms and only an explicit agreement completes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const WelcomePreviewApp());
      await _pumpUntilWelcomePage(tester, 0);
      final controller = tester
          .widget<PageView>(find.byKey(const Key('welcomePager')))
          .controller!;

      await tester.tap(find.byKey(const Key('welcomeSkip')));
      await _pumpUntilWelcomePage(tester, 3);
      expect(controller.page, 3);
      expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('同意并开始阅读'), findsOneWidget);
      expect(find.text('故事，从这里开始。'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.text('故事，从这里开始。'),
        findsNothing,
        reason: 'A navigation key must not consent.',
      );

      await tester.tap(find.byKey(const Key('welcomeBack')));
      await _pumpUntilWelcomePage(tester, 2);
      expect(controller.page, 2);
      expect(
        tester
            .widget<PageView>(find.byKey(const Key('welcomePager')))
            .controller,
        same(controller),
      );
      await tester.tap(find.byKey(const Key('welcomeNext')));
      await _pumpUntilWelcomePage(tester, 3);
      expect(controller.page, 3);
      await tester.tap(find.byKey(const Key('welcomeNext')));
      await tester.pump();
      expect(find.text('故事，从这里开始。'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'userAgreementAccepted',
        ),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact consent fits narrow screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const WelcomePreviewApp());
    await _pumpUntilWelcomePage(tester, 0);
    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await _pumpUntilWelcomePage(tester, 3);
    expect(find.text('同意并开始阅读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilWelcomePage(WidgetTester tester, int targetPage) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    final pager = find.byKey(const Key('welcomePager'));
    if (pager.evaluate().isEmpty) continue;
    final controller = tester.widget<PageView>(pager).controller;
    if (controller?.hasClients != true) continue;
    final page = controller!.page;
    if (page != null && (page - targetPage).abs() < 0.001) return;
  }
  fail('Timed out waiting for welcome page $targetPage.');
}
