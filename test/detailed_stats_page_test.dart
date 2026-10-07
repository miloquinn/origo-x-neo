import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reading_stats/detailed_stats_page.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/services/core/database_service.dart';
import 'package:xxread/widgets/elastic_pill_navigation_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/gradient_top_backdrop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporary;
  late Database database;
  final previewDirectory = Platform.environment['STATS_SCREENSHOT_DIR'];
  final previewFont = Platform.environment['STATS_PREVIEW_FONT'];
  setUpAll(() async {
    if (previewDirectory != null && previewFont != null) {
      final font = FontLoader('StatsPreview');
      font.addFont(File(previewFont).readAsBytes().then(ByteData.sublistView));
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
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
    final boundaryKey = GlobalKey();
    if (previewDirectory != null) {
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
    }
    Future<void> capture(String name) async {
      if (previewDirectory == null) return;
      await tester.runAsync(() async {
        final image =
            await (boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(previewDirectory).create(recursive: true);
        await File(
          '$previewDirectory/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1976D2),
          fontFamily: previewDirectory != null && previewFont != null
              ? 'StatsPreview'
              : 'SourceHanSerifCN',
        ),
        builder: (context, child) =>
            RepaintBoundary(key: boundaryKey, child: child!),
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
    expect(find.byType(ElasticPillNavigationBar), findsOneWidget);

    final buttons = find.byType(FloatingPillNavigationButton);
    final lens = find.byKey(const ValueKey('home-navigation-selection-lens'));
    final navigationBounds = tester.getRect(navigation);
    final restingLensSize = tester.getSize(lens);
    var gesture = await tester.startGesture(tester.getCenter(buttons.first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getSize(lens).width, greaterThan(restingLensSize.width));
    expect(tester.getRect(navigation), navigationBounds);
    await capture('stats-navigation-pressed');
    await gesture.moveTo(tester.getCenter(buttons.at(2)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      tester.getCenter(lens).dx,
      closeTo(tester.getCenter(buttons.at(2)).dx, 8),
    );
    expect(
      tester.widget<FloatingPillNavigationButton>(buttons.first).isSelected,
      isTrue,
    );
    await capture('stats-navigation-dragged');
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.text('阅读总览'), findsOneWidget);
    expect(
      tester.getCenter(lens).dx,
      closeTo(tester.getCenter(buttons.first).dx, 0.1),
    );

    gesture = await tester.startGesture(tester.getCenter(buttons.first));
    await gesture.moveTo(tester.getCenter(buttons.at(2)));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester.widget<FloatingPillNavigationButton>(buttons.at(2)).isSelected,
      isTrue,
    );
    expect(find.text('书籍数量'), findsWidgets);
    expect(tester.getRect(navigation), navigationBounds);
    await tester.tap(buttons.first);
    await tester.pumpAndSettle();

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
      final selectedIndex = ['阅读趋势分析', '书籍数量', '阅读成就'].indexOf(pageTitle) + 1;
      expect(
        tester
            .widget<ElasticPillNavigationBar>(
              find.byType(ElasticPillNavigationBar),
            )
            .selectedIndex,
        selectedIndex,
      );
    }

    for (var i = 0; i < 3; i++) {
      await tester.fling(find.byType(PageView), const Offset(360, 0), 1000);
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(find.text('阅读总览'), findsOneWidget);
    expect(tester.takeException(), isNull);

    for (final size in [const Size(1194, 834), const Size(834, 1194)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getBottomLeft(navigation).dy, lessThan(size.height));
      await tester.tap(buttons.at(3));
      await tester.pumpAndSettle();
      expect(find.text('阅读成就'), findsWidgets);
      expect(
        tester.getCenter(lens).dx,
        closeTo(tester.getCenter(buttons.at(3)).dx, 0.1),
      );
      await capture('stats-tablet-${size.width.toInt()}');
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();
    }

    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('stats-floating-tabs'))).width,
      lessThanOrEqualTo(320),
    );
    debugDisableShadows = true;
  });
}
