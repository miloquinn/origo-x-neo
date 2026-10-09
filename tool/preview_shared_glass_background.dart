import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_selection_toolbar.dart';
import 'package:xxread/widgets/side_toast.dart';

// Real-renderer fixture; runs independently from production accounts/books.
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
  var _index = 0;
  static const _scenes = [
    'frosted-light',
    'liquid-light',
    'liquid-dark',
    'solid-light',
    'high-contrast',
    'liquid-opaque',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final liquid = scene.startsWith('liquid');
    final dark = scene == 'liquid-dark';
    final off = scene == 'solid-light';
    final highContrast = scene == 'high-contrast';
    final opacity = scene == 'liquid-opaque' ? 1.0 : 0.5;
    final style = liquid ? GlassStyle.liquid : GlassStyle.frosted;
    GlassEffectConfig.setGlassStyle(style);
    GlassEffectConfig.setDisableAllGlassEffects(off);
    final palette = dark ? ReaderThemes.pureBlack : ReaderThemes.day;
    return RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        navigatorKey: _navigator,
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: palette.toThemeData().copyWith(
          extensions: [
            UiStyleThemeExtension(
              style: off ? AppUiStyle.material3 : AppUiStyle.glass,
              glassStyle: style,
              liquidGlassOpacity: opacity,
            ),
          ],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(highContrast: highContrast),
          child: child!,
        ),
        home: Scaffold(
          key: _sceneContext,
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: 390,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _Backdrop(palette.background, palette.accent),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 54, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '共用玻璃背景',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            scene,
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FloatingPillNavigationSurface(
                            width: 342,
                            height: 56,
                            child: Row(
                              children: [
                                for (final label in ['书库', '发现', '设置'])
                                  Expanded(child: Center(child: Text(label))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ReaderControlBar(
                            palette: palette,
                            isTopBar: false,
                            child: SizedBox(
                              height: 54,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (final icon in [
                                    Icons.arrow_back_rounded,
                                    Icons.bookmark_border_rounded,
                                    Icons.search_rounded,
                                    Icons.settings_rounded,
                                  ])
                                    ReaderControlIconButton(
                                      palette: palette,
                                      onPressed: () {},
                                      tooltip: '阅读操作',
                                      icon: icon,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          PillInputSurface(
                            elevated: true,
                            fillColor: palette.surface,
                            borderColor: palette.border,
                            shadowColor: palette.shadow,
                            brightness: palette.brightness,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              child: Text('记录此刻的想法…'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 118,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 10,
                                  top: 84,
                                  child: Text(
                                    '阅读是片刻的宁静，也是通往远方的路。',
                                    style: TextStyle(
                                      color: palette.text,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                ReaderSelectionToolbar(
                                  palette: palette,
                                  anchors: const TextSelectionToolbarAnchors(
                                    primaryAnchor: Offset(171, 74),
                                  ),
                                  onCopy: () {},
                                  onHighlight: () {},
                                  onNote: () {},
                                  onSearch: () {},
                                ),
                              ],
                            ),
                          ),
                          GlassSurface(
                            role: GlassSurfaceRole.panel,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            color: palette.surface,
                            outlineColor: palette.border,
                            shadowColor: palette.shadow,
                            brightness: palette.brightness,
                            child: const Padding(
                              padding: EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '书籍操作面板',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text('统一染色、描边、高光与效果降级'),
                                  SizedBox(height: 12),
                                  Text('外形和操作仍归专属组件维护'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              GlassSurface(
                                role: GlassSurfaceRole.floating,
                                shape: const RoundedRectangleBorder(),
                                child: const SizedBox(
                                  width: 80,
                                  height: 64,
                                  child: Center(child: Text('侧栏')),
                                ),
                              ),
                              const Spacer(),
                              GlassIconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.add),
                              ),
                              const SizedBox(width: 12),
                              GlassSurface(
                                role: GlassSurfaceRole.floating,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                ),
                                color: palette.accent,
                                child: FloatingActionButton(
                                  onPressed: () {},
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  heroTag: null,
                                  child: Icon(
                                    Icons.add,
                                    color: palette.onAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
      '${Directory.systemTemp.path}/shared-glass-background-previews',
    );
    await directory.create(recursive: true);
    for (var i = 0; i < _scenes.length; i++) {
      if (!mounted) return;
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      final context = _sceneContext.currentContext!;
      if (!context.mounted) return;
      showSideToast(context, '材质共用，外形独立', duration: const Duration(minutes: 1));
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final screenshot = await boundary.toImage(pixelRatio: 2);
      final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      screenshot.dispose();
      await File(
        '${directory.path}/${_scenes[i]}.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    }
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': 'ios',
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'scenes': _scenes,
        'kind': 'actual Flutter component preview',
      }),
    );
    debugPrint('SHARED_GLASS_PREVIEWS_COMPLETE ${directory.path}');
  }
}

class _Backdrop extends CustomPainter {
  const _Backdrop(this.base, this.accent);
  final Color base;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final p = Paint()..color = accent.withValues(alpha: .09);
    for (var y = 40.0; y < size.height; y += 110) {
      canvas.drawCircle(Offset(size.width - 20, y), 85, p);
      canvas.drawRect(Rect.fromLTWH(12, y + 20, 130, 12), p);
    }
  }

  @override
  bool shouldRepaint(_Backdrop old) => old.base != base || old.accent != accent;
}
