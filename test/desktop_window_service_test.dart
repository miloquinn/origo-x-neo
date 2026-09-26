import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/services/core/desktop_window_service.dart';
import 'package:xxread/utils/book_open_transition.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('unset preference defaults close request to the library', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('library')),
      ),
    );
    final route = BookOpenTransition.createRoute<void>(
      (_) => const Scaffold(body: Text('reader')),
    );
    navigatorKey.currentState!.push(route);
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final handled = await DesktopWindowService.handleCloseRequest(
      navigator: navigatorKey.currentState,
      preferences: preferences,
    );

    expect(handled, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('library'), findsOneWidget);
    expect(find.text('reader'), findsNothing);
  });

  testWidgets(
    'close request remains an app close when preference is disabled',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('library')),
        ),
      );
      final route = BookOpenTransition.createRoute<void>(
        (_) => const Scaffold(body: Text('reader')),
      );
      navigatorKey.currentState!.push(route);
      await tester.pumpAndSettle();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(
        DesktopWindowService.closeReaderToLibraryPreferenceKey,
        false,
      );

      final handled = await DesktopWindowService.handleCloseRequest(
        navigator: navigatorKey.currentState,
        preferences: preferences,
      );

      expect(handled, isFalse);
      expect(find.text('reader'), findsOneWidget);
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
    },
  );
}
