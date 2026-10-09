import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/reader_selection_toolbar.dart';

// Simulator-only component preview. No library, account or network fixtures.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final _boundary = GlobalKey();
  var _glass = GlassStyle.frosted;
  var _dark = false;
  var _off = false;
  var _width = 390.0;
  var _scale = 1.0;
  var _locale = const Locale('zh');
  var _scene = 'frosted-light';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    GlassEffectConfig.setGlassStyle(_glass);
    GlassEffectConfig.setLiquidGlassOpacity(0.5);
    GlassEffectConfig.setDisableAllGlassEffects(_off);
    final palette = _dark ? ReaderThemes.pureBlack : ReaderThemes.day;
    final theme = palette.toThemeData().copyWith(
      extensions: [
        UiStyleThemeExtension(
          style: _off ? AppUiStyle.material3 : AppUiStyle.glass,
          glassStyle: _glass,
          liquidGlassOpacity: 0.5,
        ),
      ],
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox(
              width: _width,
              height: 520,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.zero,
                    textScaler: TextScaler.linear(_scale),
                  ),
                  child: ColoredBox(
                    color: palette.background,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 28,
                          right: 28,
                          top: 24,
                          child: Text(
                            '选中文字 · 组件预览',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 28,
                          right: 28,
                          top: 65,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: '窗外的树影随着风轻轻摇动。\n\n'),
                                TextSpan(
                                  text: '阅读是片刻的宁静，\n也是通往远方的路。',
                                  style: TextStyle(
                                    backgroundColor: const Color(
                                      0xFF3295FF,
                                    ).withValues(alpha: 0.22),
                                  ),
                                ),
                                const TextSpan(
                                  text: '\n\n把喜欢的句子留下，让每一次重读都有新的发现。',
                                ),
                              ],
                            ),
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 22,
                              height: 1.85,
                              color: palette.text,
                            ),
                          ),
                        ),
                        ReaderSelectionToolbar(
                          key: ValueKey(_scene),
                          palette: palette,
                          anchors: TextSelectionToolbarAnchors(
                            primaryAnchor: Offset(_width / 2, 157),
                            secondaryAnchor: Offset(_width / 2, 275),
                          ),
                          onCopy: () {},
                          onHighlight: () {},
                          onNote: () {},
                          onSearch: () {},
                          onPurify: () {},
                          onAskAi: () {},
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
      '${Directory.systemTemp.path}/reader-selection-toolbar-previews',
    );
    await directory.create(recursive: true);
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'kind': 'simulator component preview',
      }),
    );
    debugPrint(
      'toolbar-preview shader-supported=${ui.ImageFilter.isShaderFilterSupported} directory=${directory.path}',
    );
    for (final scene in [
      'frosted-light',
      'liquid-light',
      'liquid-dark',
      'liquid-more',
      'narrow-large-text',
      'english-large-text',
      'solid-light',
    ]) {
      if (!mounted) return;
      setState(() {
        _scene = scene;
        _glass = scene.startsWith('frosted')
            ? GlassStyle.frosted
            : GlassStyle.liquid;
        _dark = scene.endsWith('dark');
        _off = scene.startsWith('solid');
        _width = scene.contains('large-text') ? 320 : 390;
        _scale = scene.contains('large-text') ? 2 : 1;
        _locale = scene.startsWith('english')
            ? const Locale('en')
            : const Locale('zh');
      });
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (scene == 'liquid-more' || scene.startsWith('english')) {
        await _tapMore();
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${directory.path}/$scene.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
      debugPrint('toolbar-preview captured=$scene');
    }
    debugPrint('toolbar-preview complete');
  }

  Future<void> _tapMore() async {
    Element? target;
    void visit(Element element) {
      if (element.widget.key == const ValueKey('reader-selection-more')) {
        target = element;
      }
      element.visitChildren(visit);
    }

    visit(WidgetsBinding.instance.rootElement!);
    final box = target!.findRenderObject()! as RenderBox;
    final position = box.localToGlobal(box.size.center(Offset.zero));
    final binding = GestureBinding.instance;
    binding.handlePointerEvent(
      PointerDownEvent(pointer: 51, position: position),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    binding.handlePointerEvent(PointerUpEvent(pointer: 51, position: position));
  }
}
