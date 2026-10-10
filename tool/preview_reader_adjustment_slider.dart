import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/core/reader/reader_margin_settings.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/reader_settings_controls.dart';

// Simulator component fixture; all adjustment controls are production widgets.
void main() => runApp(const _PreviewApp());

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  final _boundary = GlobalKey();
  var _scene = 'frosted-light';
  var _fontSize = 19.0;
  var _fontWeight = 400;
  var _lineHeight = 1.75;
  var _horizontalMargin = 18.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    final dark = _scene.contains('dark');
    final off = _scene.startsWith('solid');
    final glass = _scene.startsWith('frosted')
        ? GlassStyle.frosted
        : GlassStyle.liquid;
    final large = _scene.contains('large-text');
    final landscape = _scene.contains('landscape');
    final palette = dark ? ReaderThemes.night : ReaderThemes.day;
    GlassEffectConfig.setGlassStyle(glass);
    GlassEffectConfig.setDisableAllGlassEffects(off);
    GlassEffectConfig.setLiquidGlassOpacity(.5);
    final theme = palette.toThemeData().copyWith(
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
              width: landscape
                  ? 720
                  : large
                  ? 320
                  : 375,
              height: landscape ? 380 : 660,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.zero,
                    disableAnimations: large,
                    textScaler: TextScaler.linear(large ? 2.5 : 1),
                  ),
                  child: Material(
                    color: palette.surface,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('文字与版式', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 24),
                          ReaderSettingSlider(
                            label: '字号',
                            value: _fontSize,
                            valueLabel: _fontSize.round().toString(),
                            min: ReaderSettings.minFontSize,
                            max: ReaderSettings.maxFontSize,
                            divisions: 60,
                            onChanged: (value) =>
                                setState(() => _fontSize = value),
                          ),
                          const SizedBox(height: 8),
                          ReaderFontWeightControl(
                            label: '字重',
                            value: _fontWeight,
                            valueLabels: const ['细体', '常规', '中等', '半粗', '粗体'],
                            hint: '使用当前书籍字体，实时预览字重。',
                            previewText: '阅读让日子慢下来，也让想象走得更远。',
                            onChanged: (value) =>
                                setState(() => _fontWeight = value),
                            onChangeEnd: (_) {},
                          ),
                          const SizedBox(height: 8),
                          ReaderSettingSlider(
                            label: '行高',
                            value: _lineHeight,
                            valueLabel: _lineHeight.toStringAsFixed(1),
                            min: ReaderSettings.minLineHeight,
                            max: ReaderSettings.maxLineHeight,
                            divisions: 28,
                            onChanged: (value) =>
                                setState(() => _lineHeight = value),
                          ),
                          const SizedBox(height: 8),
                          ReaderSettingSlider(
                            label: '左右边距',
                            value: _horizontalMargin,
                            valueLabel: _horizontalMargin.round().toString(),
                            min: ReaderMarginSettings.horizontalMin,
                            max: ReaderMarginSettings.horizontalMax,
                            divisions: 96,
                            onChanged: (value) =>
                                setState(() => _horizontalMargin = value),
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
      ),
    );
  }

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/reader-adjustment-previews',
    );
    await directory.create(recursive: true);
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'kind': 'simulator production-component preview',
      }),
    );
    for (final scene in [
      'frosted-light',
      'frosted-dark',
      'liquid-light',
      'liquid-dark',
      'solid-light',
      'liquid-large-text',
      'liquid-landscape',
    ]) {
      if (!mounted) return;
      setState(() => _scene = scene);
      await Future<void>.delayed(const Duration(milliseconds: 1000));
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
      debugPrint(
        'adjustment-preview captured=$scene directory=${directory.path}',
      );
    }
    debugPrint('adjustment-preview complete');
  }
}
