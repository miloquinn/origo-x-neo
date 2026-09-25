import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reading_stats/detailed_stats_page.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/services/core/database_service.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/gradient_top_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporary;
  late Database database;
  setUpAll(() async {
    temporary = await Directory.systemTemp.createTemp('reading_stats_widget_');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => temporary.path,
        );
    // Open SQLite outside the widget fake clock and use a private directory;
    // this suite must not share a persistent /tmp database with reader tests.
    database = await DatabaseService().database;
  });
  tearDownAll(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  testWidgets('reading stats tabs render without mobile overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1976D2),
          fontFamily: 'SourceHanSerifCN',
        ),
        home: const DetailedStatsPage(),
      ),
    );

    // Each awaited SQLite operation may resume in the widget fake clock.
    // Pump between real I/O turns rather than assuming a single sleep drains
    // every chained query (additional schema work exposed that assumption).
    for (
      var attempt = 0;
      attempt < 100 && find.byType(PageView).evaluate().isEmpty;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(find.text('详细统计'), findsOneWidget);
    expect(find.text('账号统计与排行榜'), findsNothing);
    expect(find.text('总览'), findsOneWidget);
    expect(find.text('阅读总览'), findsOneWidget);
    final hero = find.byKey(const ValueKey('stats-overview-hero'));
    final firstStat = find.byKey(const ValueKey('stats-overview-stat-0'));
    expect(
      tester.getTopLeft(firstStat).dy - tester.getBottomLeft(hero).dy,
      closeTo(20, 0.1),
    );
    expect(find.byType(FloatingPillNavigationSurface), findsOneWidget);
    expect(find.byType(GradientTopBackdrop), findsOneWidget);
    final header = find.byKey(const ValueKey('floating-subpage-header'));
    final navigation = find.byKey(const ValueKey('stats-floating-tabs'));
    expect(header, findsOneWidget);
    expect(
      tester.getTopLeft(navigation).dy,
      greaterThan(tester.getBottomLeft(header).dy),
    );
    expect(tester.getBottomLeft(navigation).dy, lessThan(915));

    await tester.tap(find.byType(FloatingPillNavigationButton).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('阅读趋势分析'), findsWidgets);
    expect(
      tester
          .widget<FloatingPillNavigationButton>(
            find.byType(FloatingPillNavigationButton).at(1),
          )
          .isSelected,
      isTrue,
    );
    await tester.tap(find.byType(FloatingPillNavigationButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('阅读总览'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final pageTitle in ['阅读趋势分析', '书籍数量', '阅读成就']) {
      await tester.fling(find.byType(PageView), const Offset(-360, 0), 1000);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(pageTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    }

    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(PageView), const Offset(360, 0), 1000);
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(find.text('阅读总览'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('stats-floating-tabs'))).width,
      lessThanOrEqualTo(320),
    );
  });
}
