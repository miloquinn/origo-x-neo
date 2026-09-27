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
      await tester.pumpAndSettle();
      final controller = tester
          .widget<PageView>(find.byKey(const Key('welcomePager')))
          .controller!;

      await tester.tap(find.byKey(const Key('welcomeSkip')));
      await tester.pumpAndSettle();
      expect(controller.page, 3);
      expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('同意并开始阅读'), findsOneWidget);
      expect(find.text('故事，从这里开始。'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        find.text('故事，从这里开始。'),
        findsNothing,
        reason: 'A navigation key must not consent.',
      );

      await tester.tap(find.byKey(const Key('welcomeBack')));
      await tester.pumpAndSettle();
      expect(controller.page, 2);
      expect(
        tester
            .widget<PageView>(find.byKey(const Key('welcomePager')))
            .controller,
        same(controller),
      );
      await tester.tap(find.byKey(const Key('welcomeNext')));
      await tester.pumpAndSettle();
      expect(controller.page, 3);
      await tester.tap(find.byKey(const Key('welcomeNext')));
      await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await tester.pumpAndSettle();
    expect(find.text('同意并开始阅读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
