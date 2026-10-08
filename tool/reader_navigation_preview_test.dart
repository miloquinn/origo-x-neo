import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';

void main() {
  testWidgets('capture reader navigation previews', (tester) async {
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'ReaderNavigationPreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });

    for (final scenario in [
      (name: 'light', size: const Size(390, 844), scale: 1.0, dark: false),
      (name: 'dark', size: const Size(390, 844), scale: 1.0, dark: true),
      (name: 'narrow', size: const Size(320, 568), scale: 1.5, dark: true),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      const padding = FakeViewPadding(top: 24, bottom: 20);
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      final palette = scenario.dark ? ReaderThemes.night : ReaderThemes.day;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            fontFamily: 'ReaderNavigationPreview',
            useMaterial3: true,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: RepaintBoundary(
              key: const Key('readerNavigationPreview'),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: ReaderNavigationSheet(
              palette: palette,
              chapters: const [
                ReaderNavigationChapter(title: '序章 远方的灯火', index: 0),
                ReaderNavigationChapter(title: '第一部 雨中的城市', index: 1),
                ReaderNavigationChapter(title: '第一章 清晨的来信', index: 2, depth: 1),
                ReaderNavigationChapter(title: '一段尚未结束的旅程', index: 2, depth: 2),
                ReaderNavigationChapter(title: '第二章 穿过旧城区', index: 3, depth: 1),
                ReaderNavigationChapter(title: '第三章 雨夜重逢', index: 4, depth: 1),
                ReaderNavigationChapter(title: '第二部 山海之间', index: 5),
                ReaderNavigationChapter(title: '第四章 从此刻出发', index: 6, depth: 1),
              ],
              currentChapterIndex: 3,
              bookmarks: const [],
              onChapterSelected: (_) {},
              onBookmarkSelected: (_) {},
              onBookmarkDeleted: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('readerNavigationPreview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('/tmp/origo-reader-navigation-${scenario.name}.png');
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
