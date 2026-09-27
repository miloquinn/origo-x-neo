import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/onboarding/reading_welcome_page.dart';

void main() {
  testWidgets('welcome inherits app accent, brightness and font', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: brightness,
        ),
        fontFamily: 'AppSelectedFont',
      );
      await tester.pumpWidget(_host(onComplete: () {}, theme: theme));
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('welcomeNext')),
      );
      final heading = tester.widget<Text>(find.text('一本书，\n一个新世界。'));
      expect(scaffold.backgroundColor, theme.colorScheme.surface);
      expect(
        button.style!.backgroundColor!.resolve({}),
        theme.colorScheme.primary,
      );
      expect(heading.style!.fontFamily, 'AppSelectedFont');
      expect(heading.style!.color, theme.colorScheme.onSurface);
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('next and back controls move between welcome chapters', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onComplete: () {}));

    expect(_currentPage(tester), closeTo(0, 0.001));
    expect(find.byKey(const Key('welcomeBack')), findsNothing);

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();

    expect(_currentPage(tester), closeTo(1, 0.001));
    expect(find.byKey(const Key('welcomeBack')), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcomeBack')));
    await tester.pumpAndSettle();

    expect(_currentPage(tester), closeTo(0, 0.001));
    expect(find.byKey(const Key('welcomeBack')), findsNothing);
  });

  testWidgets('welcome progress follows a drag and returns with the gesture', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onComplete: () {}));

    final pager = find.byKey(const Key('welcomePager'));
    final gesture = await tester.startGesture(tester.getCenter(pager));
    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();

    expect(_currentPage(tester), greaterThan(0));
    expect(_currentPage(tester), lessThan(1));

    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_currentPage(tester), closeTo(0, 0.001));
  });

  testWidgets('skip completes the welcome flow exactly once', (tester) async {
    var completionCount = 0;
    await tester.pumpWidget(_host(onComplete: () => completionCount += 1));

    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await tester.pump();

    expect(completionCount, 1);
  });

  testWidgets('last chapter next control completes the flow exactly once', (
    tester,
  ) async {
    var completionCount = 0;
    await tester.pumpWidget(_host(onComplete: () => completionCount += 1));

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();
    expect(_currentPage(tester), closeTo(2, 0.001));

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pump();

    expect(completionCount, 1);
  });

  testWidgets('all welcome chapters fit a narrow screen with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(onComplete: () {}, textScaler: const TextScaler.linear(1.5)),
    );
    expect(find.text('一本书，\n一个新世界。'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();
    expect(find.text('把时间，\n留给阅读。'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();
    expect(find.text('你的书，\n自成天地。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion changes chapters in one frame', (tester) async {
    await tester.pumpWidget(_host(onComplete: () {}, disableAnimations: true));

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pump();

    expect(_currentPage(tester), closeTo(1, 0.001));
  });
}

Widget _host({
  required VoidCallback onComplete,
  ThemeData? theme,
  bool disableAnimations = false,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    theme: theme,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations, textScaler: textScaler),
      child: child!,
    ),
    home: ReadingWelcomePage(onComplete: onComplete),
  );
}

double _currentPage(WidgetTester tester) {
  final pageView = tester.widget<PageView>(
    find.byKey(const Key('welcomePager')),
  );
  return pageView.controller!.page!;
}
