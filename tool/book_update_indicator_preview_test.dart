import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/source_book_update_info.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/widgets/book_update_indicator.dart';
import 'package:xxread/widgets/generated_book_cover.dart';

void main() {
  testWidgets('render known and unknown cover updates', (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('BadgePreview');
      font.addFont(
        File(
          '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final output = Directory(
      Platform.environment['BADGE_PREVIEW_DIR'] ??
          'build/previews/online-update-badge',
    );
    await tester.runAsync(() => output.create(recursive: true));
    for (final scenario in [
      (name: 'light', width: 390.0, brightness: Brightness.light, scale: 1.0),
      (name: 'dark', width: 390.0, brightness: Brightness.dark, scale: 1.0),
      (
        name: 'narrow-large',
        width: 320.0,
        brightness: Brightness.light,
        scale: 2.0,
      ),
      (
        name: 'small-cover-large-count',
        width: 252.0,
        brightness: Brightness.light,
        scale: 2.0,
      ),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(scenario.width, 500);
      final theme = ThemeData(
        brightness: scenario.brightness,
        colorSchemeSeed: const Color(0xff396953),
        fontFamily: 'BadgePreview',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: RepaintBoundary(key: const Key('capture'), child: child!),
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 14,
                runSpacing: 18,
                children: [
                  for (final sample in [
                    (
                      title: '山海之间',
                      count: 1,
                      status: SourceBookCheckStatus.available,
                    ),
                    (
                      title: '长安纪事',
                      count: 12,
                      status: SourceBookCheckStatus.available,
                    ),
                    (
                      title: '星河旅人',
                      count: 128,
                      status: SourceBookCheckStatus.available,
                    ),
                    (
                      title: '烟雨江南',
                      count: 0,
                      status: SourceBookCheckStatus.available,
                    ),
                    (
                      title: '远山来信',
                      count: 2,
                      status: SourceBookCheckStatus.failed,
                    ),
                    (
                      title: '海边日记',
                      count: 0,
                      status: SourceBookCheckStatus.current,
                    ),
                  ])
                    SizedBox(
                      width: (scenario.width - 60) / 3,
                      height: (scenario.width - 60) / 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BookUpdateIndicator(
                          book: _book(
                            sample.title,
                            sample.status,
                            scenario.name == 'small-cover-large-count' &&
                                    sample.count == 128
                                ? 123456
                                : sample.count,
                          ),
                          child: GeneratedBookCover(
                            title: sample.title,
                            author: '开元阅读',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario.name);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${scenario.name}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}

Book _book(String title, SourceBookCheckStatus status, int count) {
  final book = Book(
    title: title,
    filePath: '',
    format: 'source',
    storageType: 'online',
    sourceBookJson: '{}',
  );
  return book.copyWith(
    sourceBookJson: SourceBookUpdateInfo(
      status: status,
      newChapterCount: count,
    ).encodeInto(book),
  );
}
