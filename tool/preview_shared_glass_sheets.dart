import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_settings_controls.dart';

// Native renderer fixture: shared modal route and production reader controls.
void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _navigator = GlobalKey<NavigatorState>();
  final _sceneContext = GlobalKey();
  final _topBar = GlobalKey();
  final _bottomBar = GlobalKey();
  var _index = 0;
  var _fontSize = 20.0;
  var _lineHeight = 1.8;
  var _letterSpacing = 0.0;

  static const _scenes = [
    'liquid-light',
    'liquid-night',
    'liquid-black',
    'liquid-navy',
    'liquid-parchment',
    'frosted-light',
    'frosted-dark',
    'solid-light',
    'solid-dark',
    'high-contrast',
    'liquid-large-text',
    'liquid-compact',
    'liquid-actions',
    'chrome-liquid-light',
    'chrome-liquid-night',
    'chrome-liquid-black',
    'chrome-frosted-light',
    'chrome-solid-light',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  ReaderThemePalette get _palette => switch (_scenes[_index]) {
    'liquid-black' || 'chrome-liquid-black' => ReaderThemes.pureBlack,
    'liquid-navy' => ReaderThemes.navy,
    'liquid-parchment' => ReaderThemes.parchment,
    'liquid-night' ||
    'chrome-liquid-night' ||
    'frosted-dark' ||
    'solid-dark' => ReaderThemes.night,
    _ => ReaderThemes.day,
  };

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final palette = _palette;
    final off = scene.contains('solid');
    final frosted = scene.contains('frosted');
    final highContrast = scene == 'high-contrast';
    final large = scene == 'liquid-large-text';
    final compact = scene == 'liquid-compact';
    final style = frosted ? GlassStyle.frosted : GlassStyle.liquid;
    GlassEffectConfig.setGlassStyle(style);
    GlassEffectConfig.setDisableAllGlassEffects(off);
    final theme = palette.toThemeData().copyWith(
      extensions: [
        UiStyleThemeExtension(
          style: off ? AppUiStyle.material3 : AppUiStyle.glass,
          glassStyle: style,
          liquidGlassOpacity: 0.5,
        ),
      ],
    );
    final size = Size(large ? 320 : 390, compact ? 380 : 844);
    return Center(
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: size,
          child: MaterialApp(
            navigatorKey: _navigator,
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: size,
                padding: const EdgeInsets.only(top: 44, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
                viewInsets: EdgeInsets.zero,
                highContrast: highContrast,
                disableAnimations: large,
                textScaler: TextScaler.linear(large ? 2.4 : 1),
              ),
              child: child!,
            ),
            home: Scaffold(
              key: _sceneContext,
              backgroundColor: palette.background,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _Backdrop(palette.background, palette.accent),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 112, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '第一章 · 窗外的风',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          if (!compact)
                            Text(
                              '午后的光落在书页上，风从窗边轻轻经过。'
                              '翻过这一页，远方的故事才刚刚开始。',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ReaderChromeOverlay(
                    palette: palette,
                    visible: true,
                    title: '片刻的宁静',
                    topKey: _topBar,
                    bottomKey: _bottomBar,
                    statusBottom: 8,
                    statusBuilder: (context, style, key) =>
                        Text('12 / 86', style: style, key: key),
                    onBack: () {},
                    onBookmark: () {},
                    onTableOfContents: () {},
                    onSettings: () {},
                    onSearch: () {},
                    onReadAloud: () {},
                    onAskAi: () {},
                    onBookSettings: () {},
                    backTooltip: '返回',
                    bookmarkTooltip: '书签',
                    tableOfContentsTooltip: '目录',
                    settingsTooltip: '阅读设置',
                    searchTooltip: '搜索',
                    readAloudTooltip: '朗读',
                    askAiTooltip: '问 AI',
                    bookmarked: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settings(BuildContext context) => ReaderSettingsSheetFrame(
    palette: _palette,
    child: StatefulBuilder(
      builder: (context, update) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('阅读设置', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('文字与版式', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ReaderSettingSlider(
            label: '字号',
            valueLabel: _fontSize.toStringAsFixed(0),
            value: _fontSize,
            min: 12,
            max: 72,
            divisions: 60,
            onChanged: (value) => update(() => _fontSize = value),
          ),
          const SizedBox(height: 20),
          ReaderSettingSlider(
            label: '行距',
            valueLabel: _lineHeight.toStringAsFixed(1),
            value: _lineHeight,
            min: 1.2,
            max: 4,
            divisions: 28,
            onChanged: (value) => update(() => _lineHeight = value),
          ),
          const SizedBox(height: 20),
          ReaderSettingSlider(
            label: '字距',
            valueLabel: _letterSpacing.toStringAsFixed(1),
            value: _letterSpacing,
            min: 0,
            max: 6,
            divisions: 60,
            onChanged: (value) => update(() => _letterSpacing = value),
          ),
        ],
      ),
    ),
  );

  Widget _actions(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('书籍操作', style: Theme.of(context).textTheme.titleLarge),
            subtitle: const Text('片刻的宁静'),
          ),
          for (final action in const [
            (Icons.folder_outlined, '移入文件夹'),
            (Icons.download_outlined, '下载本书'),
            (Icons.info_outline_rounded, '书籍详情'),
          ])
            ListTile(
              leading: Icon(action.$1),
              title: Text(action.$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    ),
  );

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/shared-glass-sheets-previews',
    );
    await directory.create(recursive: true);
    for (var i = 0; i < _scenes.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final context = _sceneContext.currentContext!;
      if (!context.mounted) return;
      if (_scenes[i].startsWith('chrome-')) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        await _snapshot(directory, _scenes[i]);
        if (_scenes[i] == 'chrome-liquid-light') {
          await _captureMotion(directory, _topBar, 'title', 81);
          await _captureMotion(directory, _bottomBar, 'controls', 82);
        }
        continue;
      }
      unawaited(
        showGlassBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: _palette.surface,
          builder: _scenes[i] == 'liquid-actions' ? _actions : _settings,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 650));
      await _snapshot(directory, _scenes[i]);
      _navigator.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': 'ios',
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'scenes': _scenes,
        'kind': 'actual shared modal route and production reader controls',
      }),
    );
    debugPrint('SHARED_SHEETS_PREVIEWS_COMPLETE ${directory.path}');
  }

  Future<void> _snapshot(Directory directory, String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final screenshot = await boundary.toImage(pixelRatio: 2);
    final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    screenshot.dispose();
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  }

  Future<void> _captureMotion(
    Directory directory,
    GlobalKey key,
    String name,
    int pointer,
  ) async {
    RenderBox? box;
    void findBar(Element element) {
      if (element.widget is ReaderControlBar) {
        box = element.findRenderObject()! as RenderBox;
      } else {
        element.visitChildElements(findBar);
      }
    }

    (key.currentContext! as Element).visitChildElements(findBar);
    final origin = box!.localToGlobal(box!.size.center(Offset.zero));
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        pointer: pointer,
        position: origin,
        buttons: kPrimaryButton,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await _snapshot(directory, 'chrome-$name-pressed');
    final position = origin + const Offset(90, 32);
    GestureBinding.instance.handlePointerEvent(
      PointerMoveEvent(
        pointer: pointer,
        position: position,
        delta: const Offset(90, 32),
        buttons: kPrimaryButton,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await _snapshot(directory, 'chrome-$name-dragged');
    GestureBinding.instance.handlePointerEvent(
      PointerUpEvent(pointer: pointer, position: position),
    );
    await Future<void>.delayed(const Duration(milliseconds: 850));
    await _snapshot(directory, 'chrome-$name-settled');
  }
}

class _Backdrop extends CustomPainter {
  const _Backdrop(this.base, this.accent);

  final Color base;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()..color = accent.withValues(alpha: 0.10);
    for (var y = 60.0; y < size.height; y += 170) {
      canvas.drawCircle(Offset(size.width - 18, y), 100, paint);
    }
  }

  @override
  bool shouldRepaint(_Backdrop old) => old.base != base || old.accent != accent;
}
