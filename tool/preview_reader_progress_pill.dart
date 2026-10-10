import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/core/reader/reader_progress_position.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_progress_pill.dart';
import 'package:xxread/widgets/reader_theme_background.dart';

// Uses production chrome and progress widgets; it does not load user books.
void main() => runApp(createReaderProgressPreview());

Widget createReaderProgressPreview({String? fontFamily}) =>
    _PreviewApp(fontFamily: fontFamily);

class _PreviewApp extends StatefulWidget {
  const _PreviewApp({this.fontFamily});

  final String? fontFamily;

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final _boundary = GlobalKey();
  var _scene = 'frosted-light';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    final dark = _scene.contains('dark');
    final off = _scene.startsWith('solid');
    final large = _scene.contains('large');
    final glass = _scene.startsWith('frosted')
        ? GlassStyle.frosted
        : GlassStyle.liquid;
    final palette = dark ? ReaderThemes.night : ReaderThemes.day;
    GlassEffectConfig.setGlassStyle(glass);
    GlassEffectConfig.setDisableAllGlassEffects(off);
    GlassEffectConfig.setLiquidGlassOpacity(.5);
    final baseTheme = palette.toThemeData();
    final theme = baseTheme.copyWith(
      textTheme: widget.fontFamily == null
          ? baseTheme.textTheme
          : baseTheme.textTheme.apply(fontFamily: widget.fontFamily),
      extensions: [
        UiStyleThemeExtension(
          style: off ? AppUiStyle.material3 : AppUiStyle.glass,
          glassStyle: glass,
          liquidGlassOpacity: .5,
        ),
      ],
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox(
              width: large ? 320 : 390,
              height: 680,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(large ? 320 : 390, 680),
                    padding: const EdgeInsets.only(bottom: 28),
                    viewPadding: const EdgeInsets.only(bottom: 28),
                    disableAnimations: large,
                    textScaler: TextScaler.linear(large ? 2.5 : 1),
                  ),
                  child: ReaderThemeBackground(
                    palette: palette,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 110, 30, 0),
                          child: Text(
                            '阳光从窗边落下来，在书页上停了一会儿。\n\n'
                            '她把书翻到昨天的地方，窗外的风声渐渐安静下来。'
                            '每一行文字都像一条小路，通往尚未见过的风景。\n\n'
                            '屋里的钟还在慢慢走，阅读却让时间有了另一种速度。'
                            '她读完这一页，又轻轻翻过一页。\n\n'
                            '故事仍在继续。',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: palette.text,
                              fontSize: 19,
                              height: 1.9,
                            ),
                          ),
                        ),
                        ReaderChromeOverlay(
                          palette: palette,
                          visible: true,
                          title: '第五十章 · 窗边的书',
                          statusBottom: 0,
                          statusBuilder: (_, _, _) => const SizedBox.shrink(),
                          onBack: () {},
                          onBookmark: () {},
                          onTableOfContents: () {},
                          onSettings: () {},
                          onSearch: () {},
                          searchTooltip: '搜索',
                          onReadAloud: () {},
                          readAloudTooltip: '听书',
                          onAskAi: () {},
                          askAiTooltip: 'AI',
                          backTooltip: '返回',
                          bookmarkTooltip: '书签',
                          tableOfContentsTooltip: '目录',
                          settingsTooltip: '设置',
                          bookmarked: false,
                          progressBar: ReaderProgressPill(
                            palette: palette,
                            position: const ReaderProgressPosition(
                              chapterIndex: 49,
                              chapterCount: 100,
                              chapterProgress: .5,
                            ),
                            scope: _scene.contains('chapter')
                                ? ReaderProgressScope.chapter
                                : ReaderProgressScope.book,
                            onSeek: (_) {},
                            onPreviousChapter: () {},
                            onNextChapter: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/reader-progress-pill-previews',
    );
    await directory.create(recursive: true);
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'kind': 'native production-component preview',
      }),
    );
    for (final scene in [
      'frosted-light',
      'frosted-dark',
      'liquid-light',
      'liquid-dark',
      'solid-light',
      'solid-dark',
      'liquid-chapter-large',
    ]) {
      if (!mounted) return;
      setState(() => _scene = scene);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final screenshot = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await screenshot.toByteData(
          format: ui.ImageByteFormat.png,
        );
        await File(
          '${directory.path}/$scene.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        screenshot.dispose();
      }
      debugPrint(
        'progress-preview captured=$scene directory=${directory.path}',
      );
    }
    debugPrint('progress-preview complete');
  }
}
