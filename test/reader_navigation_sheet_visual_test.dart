import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';

// Set ORIGO_NAV_PREVIEW_DIR to capture the actual shared widget. Liquid glass
// uses its normal software-renderer fallback here; these are layout previews.
void main() {
  for (final scene in _scenes) {
    testWidgets('navigation half sheet layout ${scene.name}', (tester) async {
      tester.view.physicalSize = Size(scene.width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      GlassEffectConfig.setGlassStyle(scene.glass);
      GlassEffectConfig.setDisableAllGlassEffects(scene.solid);
      addTearDown(() {
        GlassEffectConfig.setGlassStyle(defaultGlassStyle);
        GlassEffectConfig.setDisableAllGlassEffects(false);
      });
      final output = Platform.environment['ORIGO_NAV_PREVIEW_DIR'];
      if (output != null) await tester.runAsync(_loadPreviewFonts);
      final boundary = GlobalKey();
      await tester.pumpWidget(_host(scene, boundary, preview: output != null));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
      expect(find.text('目录'), findsOneWidget);
      expect(find.text('书签'), findsOneWidget);
      expect(find.text('笔记'), findsOneWidget);
      expect(find.text('阅读导航'), findsNothing);
      expect(find.byTooltip('关闭'), findsNothing);
      final list = tester.getRect(find.byType(ListView).first);
      expect(
        list.height,
        greaterThanOrEqualTo(scene.textScale > 1 ? 200 : 250),
        reason: 'A half-height menu must leave most of its height for entries.',
      );
      expect(
        find.descendant(
          of: find.byType(ReaderNavigationSheet),
          matching: find.text('第一章 清晨的来信'),
        ),
        findsOneWidget,
      );

      if (output != null) {
        await _capture(tester, boundary, scene, output, list);
      }
      await tester.tap(
        find.byKey(const ValueKey('reader-navigation-search-toggle')),
      );
      await tester.pumpAndSettle();
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('reader-navigation-search-field')),
        findsOneWidget,
      );
      expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
      if (output != null) {
        await _capture(
          tester,
          boundary,
          scene,
          output,
          tester.getRect(find.byType(ListView).first),
          searchExpanded: true,
        );
      }
    });
  }
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  _Scene scene,
  String output,
  Rect list, {
  bool searchExpanded = false,
}) async {
  final name = '${scene.name}${searchExpanded ? '-search' : ''}';
  final metrics = <String, Object?>{
    'scene': name,
    'renderer': 'flutter_test software renderer',
    'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
    'logicalSize': [scene.width, 844],
    'sheetHeight': 430,
    'textScale': scene.textScale,
    'brightness': scene.dark ? 'dark' : 'light',
    'uiStyle': scene.solid ? 'material3' : 'glass',
    'glassStyle': scene.glass.name,
    'searchExpanded': searchExpanded,
    'keyboardVisible': false,
    'catalogViewport': {
      'top': list.top,
      'height': list.height,
      'width': list.width,
    },
  };
  await tester.runAsync(() async {
    final directory = Directory(output);
    await directory.create(recursive: true);
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
    await File(
      '$output/$name.render-context.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(metrics));
  });
}

const _scenes = [
  _Scene('solid-light', solid: true),
  _Scene('solid-dark', solid: true, dark: true),
  _Scene('frosted-light', glass: GlassStyle.frosted),
  _Scene('frosted-dark', glass: GlassStyle.frosted, dark: true),
  _Scene('liquid-light'),
  _Scene('liquid-dark', dark: true),
  _Scene('liquid-large-text-320', width: 320, textScale: 1.5),
];

class _Scene {
  const _Scene(
    this.name, {
    this.solid = false,
    this.dark = false,
    this.glass = GlassStyle.liquid,
    this.width = 390,
    this.textScale = 1,
  });

  final String name;
  final bool solid;
  final bool dark;
  final GlassStyle glass;
  final double width;
  final double textScale;
}

Widget _host(_Scene scene, GlobalKey boundary, {required bool preview}) {
  final palette = scene.dark ? ReaderThemes.night : ReaderThemes.day;
  final paletteTheme = palette.toThemeData();
  final theme = paletteTheme.copyWith(
    textTheme: preview
        ? paletteTheme.textTheme.apply(fontFamily: 'NavigationPreview')
        : paletteTheme.textTheme,
    extensions: [
      UiStyleThemeExtension(
        style: scene.solid ? AppUiStyle.material3 : AppUiStyle.glass,
        glassStyle: scene.glass,
      ),
    ],
  );
  return MaterialApp(
    key: ValueKey(scene.name),
    theme: theme,
    themeAnimationDuration: Duration.zero,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scene.textScale)),
      child: RepaintBoundary(key: boundary, child: child!),
    ),
    home: Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 66, 26, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('第一章 清晨的来信', style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                Text(
                  '天刚亮的时候，旧城还没有醒来。\n\n'
                  '沿着河岸向前，晨风吹过细长的树影。'
                  '他放慢了脚步，读着信封上熟悉的名字。\n\n'
                  '远处传来第一声钟响，新的旅程从这里开始。',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: .30)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 430,
              child: ReaderNavigationSheet(
                palette: palette,
                chapters: List.generate(
                  18,
                  (index) => ReaderNavigationChapter(
                    title: switch (index) {
                      0 => '第一部 · 出发',
                      1 => '第一章 清晨的来信',
                      2 => '第二章 穿过旧城区',
                      3 => '第三章 雨夜重逢',
                      4 => '第四章 山谷里的灯火',
                      5 => '第五章 回到风起的地方',
                      _ => '第$index章 继续向远方前行',
                    },
                    index: index,
                    depth: index == 0 ? 0 : 1,
                  ),
                ),
                currentChapterIndex: 1,
                bookmarks: const [],
                onChapterSelected: (_) {},
                onBookmarkSelected: (_) {},
                onBookmarkDeleted: (_) {},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _loadPreviewFonts() async {
  final font = File('/System/Library/Fonts/Hiragino Sans GB.ttc');
  if (await font.exists()) {
    final bytes = await font.readAsBytes();
    await (FontLoader(
      'NavigationPreview',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (await icons.exists()) {
    final bytes = await icons.readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}
