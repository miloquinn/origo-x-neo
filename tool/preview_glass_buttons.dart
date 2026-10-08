import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/image/image_reader_chrome.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_top_bar.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

// flutter run -d B747AC4A-A940-4BBC-A2BB-DE72F5EDE816 \
//   --enable-impeller --no-pub -t tool/preview_glass_buttons.dart \
//   --dart-define=PREVIEW_CAPTURE=true
const _captureEnabled = bool.fromEnvironment('PREVIEW_CAPTURE');
const _captureSet = String.fromEnvironment(
  'PREVIEW_CAPTURE_SET',
  defaultValue: 'controls',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlassButtonsPreviewApp());
}

class GlassButtonsPreviewApp extends StatefulWidget {
  const GlassButtonsPreviewApp({super.key});

  @override
  State<GlassButtonsPreviewApp> createState() => _GlassButtonsPreviewAppState();
}

class _GlassButtonsPreviewAppState extends State<GlassButtonsPreviewApp> {
  final _previewBoundaryKey = GlobalKey();
  final _standaloneButtonKey = GlobalKey();
  var _mode = _PreviewMode.liquid;
  var _dark = false;
  var _liquidOpacity = 0.0;
  var _reduceMotion = false;
  var _textScale = 1.0;
  var _scene = _PreviewScene.controls;
  var _readerWidth = 390.0;
  var _captureStarted = false;

  @override
  void initState() {
    super.initState();
    _syncGlassConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_captureEnabled && !_captureStarted) {
        _captureStarted = true;
        unawaited(_captureSequence());
      }
    });
  }

  void _syncGlassConfig() {
    GlassEffectConfig.setGlassStyle(_mode.glassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(_liquidOpacity);
    GlassEffectConfig.setDisableAllGlassEffects(_mode == _PreviewMode.off);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: _reduceMotion);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _dark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B62E8),
      brightness: brightness,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        UiStyleThemeExtension(
          style: _mode == _PreviewMode.off
              ? AppUiStyle.material3
              : AppUiStyle.glass,
          glassStyle: _mode.glassStyle,
          liquidGlassOpacity: _liquidOpacity,
        ),
      ],
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            disableAnimations: _reduceMotion,
            textScaler: TextScaler.linear(_textScale),
          ),
          child: RepaintBoundary(key: _previewBoundaryKey, child: child!),
        );
      },
      home: _scene == _PreviewScene.reader
          ? _ReaderControlsPreviewPage(mode: _mode, readerWidth: _readerWidth)
          : _GlassButtonsPreviewPage(
              mode: _mode,
              liquidOpacity: _liquidOpacity,
              standaloneButtonKey: _standaloneButtonKey,
            ),
    );
  }

  Future<void> _captureSequence() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/shared-glass-buttons-previews',
    );
    try {
      await directory.create(recursive: true);
      stdout.writeln(
        '[glass-buttons-preview] capture-start '
        'shader-supported=${ui.ImageFilter.isShaderFilterSupported} '
        'directory=${directory.path}',
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      if (_captureSet.trim().toLowerCase() == 'reader') {
        await _captureReaderSequence(directory);
        stdout.writeln('[glass-buttons-preview] capture-complete');
        return;
      }

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0,
      );
      await _captureRoot(directory, 'liquid-light-opacity-0-rest');
      final center = _standaloneButtonCenter();
      _dispatchPointer(
        PointerDownEvent(
          pointer: 41,
          position: center,
          kind: PointerDeviceKind.touch,
          buttons: kPrimaryButton,
        ),
      );
      await _waitForMotion(const Duration(milliseconds: 220));
      await _captureRoot(directory, 'liquid-light-opacity-0-pressed');

      const pull = Offset(16, 7);
      _dispatchPointer(
        PointerMoveEvent(
          pointer: 41,
          position: center + pull,
          delta: pull,
          kind: PointerDeviceKind.touch,
          buttons: kPrimaryButton,
        ),
      );
      await _waitForMotion(const Duration(milliseconds: 150));
      await _captureRoot(directory, 'liquid-light-opacity-0-pulled');
      _dispatchPointer(
        PointerUpEvent(
          pointer: 41,
          position: center + pull,
          kind: PointerDeviceKind.touch,
        ),
      );
      await _waitForMotion(const Duration(milliseconds: 1100));
      await _captureRoot(directory, 'liquid-light-opacity-0-released');

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
      );
      await _captureRoot(directory, 'liquid-light-opacity-0.5-rest');
      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 1,
      );
      await _captureRoot(directory, 'liquid-light-opacity-1-rest');
      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: true,
        liquidOpacity: 0,
      );
      await _captureRoot(directory, 'liquid-dark-opacity-0-rest');

      await _setCaptureState(mode: _PreviewMode.frosted, dark: false);
      await _captureRoot(directory, 'frosted-light-rest');
      await _setCaptureState(mode: _PreviewMode.frosted, dark: true);
      await _captureRoot(directory, 'frosted-dark-rest');
      await _setCaptureState(mode: _PreviewMode.off, dark: false);
      await _captureRoot(directory, 'off-light-rest');

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
        reduceMotion: true,
      );
      final reducedCenter = _standaloneButtonCenter();
      _dispatchPointer(
        PointerDownEvent(
          pointer: 42,
          position: reducedCenter,
          kind: PointerDeviceKind.touch,
          buttons: kPrimaryButton,
        ),
      );
      await _waitForMotion(const Duration(milliseconds: 220));
      await _captureRoot(directory, 'liquid-light-reduced-motion-pressed');
      _dispatchPointer(
        PointerUpEvent(
          pointer: 42,
          position: reducedCenter,
          kind: PointerDeviceKind.touch,
        ),
      );

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
        reduceMotion: false,
        textScale: 1.8,
      );
      await _captureRoot(directory, 'liquid-light-large-text-rest');
      stdout.writeln('[glass-buttons-preview] capture-complete');
    } catch (error, stackTrace) {
      stdout.writeln('[glass-buttons-preview] capture-failed error=$error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'shared glass buttons preview capture',
        ),
      );
    }
  }

  Future<void> _captureReaderSequence(Directory directory) async {
    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.reader,
      readerWidth: 390,
    );
    await _captureRoot(directory, 'reader-liquid-wide-rest');

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.reader,
      readerWidth: 320,
    );
    await _captureRoot(directory, 'reader-liquid-narrow-320-rest');

    await _setCaptureState(
      mode: _PreviewMode.frosted,
      dark: false,
      scene: _PreviewScene.reader,
      readerWidth: 320,
    );
    await _captureRoot(directory, 'reader-frosted-narrow-320-rest');

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      textScale: 1.8,
      scene: _PreviewScene.reader,
      readerWidth: 320,
    );
    await _captureRoot(directory, 'reader-liquid-narrow-320-large-text');

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.reader,
      readerWidth: 320,
    );
    final moreCenter = _elementCenter(const ValueKey('reader-selection-more'));
    _dispatchPointer(
      PointerDownEvent(
        pointer: 51,
        position: moreCenter,
        kind: PointerDeviceKind.touch,
        buttons: kPrimaryButton,
      ),
    );
    await _waitForMotion(const Duration(milliseconds: 180));
    await _captureRoot(
      directory,
      'reader-selection-liquid-narrow-320-more-pressed',
    );
    _dispatchPointer(
      PointerCancelEvent(
        pointer: 51,
        position: moreCenter,
        kind: PointerDeviceKind.touch,
      ),
    );

    // Dispose the held tooltip/gesture state, then use a fresh short tap for
    // the route so the capture proves the real popup path rather than a mock.
    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.controls,
    );
    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.reader,
      readerWidth: 320,
    );
    final freshMoreCenter = _elementCenter(
      const ValueKey('reader-selection-more'),
    );
    _dispatchPointer(
      PointerDownEvent(
        pointer: 52,
        position: freshMoreCenter,
        kind: PointerDeviceKind.touch,
        buttons: kPrimaryButton,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    _dispatchPointer(
      PointerUpEvent(
        pointer: 52,
        position: freshMoreCenter,
        kind: PointerDeviceKind.touch,
      ),
    );
    await _waitForMotion(const Duration(milliseconds: 650));
    await _captureRoot(
      directory,
      'reader-selection-liquid-narrow-320-menu-open',
    );

    const dismissPosition = Offset(12, 210);
    _dispatchPointer(
      const PointerDownEvent(
        pointer: 53,
        position: dismissPosition,
        kind: PointerDeviceKind.touch,
        buttons: kPrimaryButton,
      ),
    );
    _dispatchPointer(
      const PointerUpEvent(
        pointer: 53,
        position: dismissPosition,
        kind: PointerDeviceKind.touch,
      ),
    );
    await _waitForMotion(const Duration(milliseconds: 800));
    await _captureRoot(
      directory,
      'reader-selection-liquid-narrow-320-menu-dismissed',
    );
  }

  Future<void> _setCaptureState({
    required _PreviewMode mode,
    required bool dark,
    double liquidOpacity = 0,
    bool reduceMotion = false,
    double textScale = 1,
    _PreviewScene scene = _PreviewScene.controls,
    double readerWidth = 390,
  }) async {
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _dark = dark;
      _liquidOpacity = liquidOpacity.clamp(0.0, 1.0).toDouble();
      _reduceMotion = reduceMotion;
      _textScale = textScale;
      _scene = scene;
      _readerWidth = readerWidth;
      _syncGlassConfig();
    });
    stdout.writeln(
      '[glass-buttons-preview] stage=${mode.name} '
      'brightness=${dark ? 'dark' : 'light'} '
      'liquid-opacity=${_liquidOpacity.toStringAsFixed(2)} '
      'reduce-motion=$reduceMotion text-scale=$textScale '
      'scene=${scene.name} reader-width=$readerWidth',
    );
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    await WidgetsBinding.instance.endOfFrame;
  }

  Offset _standaloneButtonCenter() {
    final context = _standaloneButtonKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw StateError('Standalone glass button is unavailable');
    }
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  Offset _elementCenter(Key key) {
    Element? match;
    void visit(Element element) {
      if (match != null) return;
      if (element.widget.key == key) {
        match = element;
        return;
      }
      element.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) throw StateError('Preview element tree is unavailable');
    visit(root);
    final renderObject = match?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw StateError('Element with key $key is unavailable');
    }
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  void _dispatchPointer(PointerEvent event) {
    GestureBinding.instance.handlePointerEvent(event);
  }

  Future<void> _waitForMotion(Duration duration) async {
    await Future<void>.delayed(duration);
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _captureRoot(Directory directory, String name) async {
    if (!mounted) return;
    final context = _previewBoundaryKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (context == null || renderObject is! RenderRepaintBoundary) {
      throw StateError('Preview RepaintBoundary is unavailable');
    }
    final pixelRatio = View.of(context).devicePixelRatio;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding returned no bytes');
      final file = File('${directory.path}/$name.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      stdout.writeln(
        '[glass-buttons-preview] captured=${file.path} '
        'size=${image.width}x${image.height} pixel-ratio=$pixelRatio',
      );
    } finally {
      image.dispose();
    }
  }
}

class _ReaderControlsPreviewPage extends StatelessWidget {
  const _ReaderControlsPreviewPage({
    required this.mode,
    required this.readerWidth,
  });

  final _PreviewMode mode;
  final double readerWidth;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    const palette = ReaderThemes.pureBlack;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _StatusChip(label: '${mode.label} · 应用浅色')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusChip(
                        label: '阅读器深色 · ${readerWidth.round()}px',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: SizedBox(
                      width: readerWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child: CustomPaint(
                                  painter: _ComicPagePainter(),
                                ),
                              ),
                              ImageReaderChrome(
                                palette: palette,
                                visible: true,
                                title: '第四章 · 云海尽头的机械城',
                                pageIndex: 36,
                                pageCount: 128,
                                directionIcon: Icons.swap_horiz_rounded,
                                directionLabel: '从左向右',
                                onBack: () {},
                                onPageSelected: (_) {},
                                onDirection: () {},
                                onSettings: () {},
                                onTableOfContents: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: SizedBox(
                      width: readerWidth,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(
                                painter: _DensePatternPainter(),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 14,
                              right: 14,
                              child: Text(
                                '选中文本 · 复制已禁用 · 更多菜单',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            ReaderSelectionToolbar(
                              palette: palette,
                              anchors: TextSelectionToolbarAnchors(
                                primaryAnchor: Offset(readerWidth / 2, 126),
                                secondaryAnchor: Offset(readerWidth / 2, 68),
                              ),
                              onHighlight: () {},
                              onNote: () {},
                              onCopy: null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButtonsPreviewPage extends StatelessWidget {
  const _GlassButtonsPreviewPage({
    required this.mode,
    required this.liquidOpacity,
    required this.standaloneButtonKey,
  });

  final _PreviewMode mode;
  final double liquidOpacity;
  final GlobalKey standaloneButtonKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Positioned.fill(
            child: ColoredBox(
              color: scheme.surface.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.18
                    : 0.08,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, topInset + 78, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusLine(mode: mode, opacity: liquidOpacity),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: _FixturePanel(
                    title: '48 · 独立玻璃按钮（可拉伸）',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GlassIconButton(
                          key: standaloneButtonKey,
                          dimension: 48,
                          iconSize: 28,
                          onPressed: () {},
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const SizedBox(width: 34),
                        GlassIconButton(
                          dimension: 48,
                          iconSize: 27,
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: _FixturePanel(
                    title: '44 · 书库工具与文字胶囊',
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        GlassToolbarButton(
                          icon: Icons.search_rounded,
                          tooltip: '搜索',
                          blurBackground: true,
                          onPressed: () {},
                        ),
                        GlassToolbarButton(
                          icon: Icons.filter_alt_rounded,
                          tooltip: '筛选已启用',
                          highlighted: true,
                          blurBackground: true,
                          onPressed: () {},
                        ),
                        GlassToolbarButton(
                          icon: Icons.file_download_outlined,
                          tooltip: '不可用',
                          blurBackground: true,
                          onPressed: null,
                        ),
                        GlassTextButton(
                          tooltip: '切换范围',
                          blurBackground: true,
                          onPressed: () {},
                          child: const Text('本周 · 7 天'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: _FixturePanel(
                    title: '44 · 阅读器深色配色（应用保持当前主题）',
                    child: ReaderControlBar(
                      palette: ReaderThemes.pureBlack,
                      isTopBar: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ReaderControlIconButton(
                              palette: ReaderThemes.pureBlack,
                              tooltip: '目录',
                              icon: Icons.menu_book_rounded,
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            ReaderControlIconButton(
                              palette: ReaderThemes.pureBlack,
                              tooltip: '朗读',
                              icon: Icons.headphones_rounded,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: GlassTopBar(
              title: '共享弹簧玻璃按钮',
              centerTitle: true,
              titleFontSize: 20,
              leading: FloatingSubpageAction(
                icon: Icons.arrow_back_ios_new_rounded,
                iconSize: 28,
                tooltip: '返回',
                onPressed: () {},
              ),
              trailing: FloatingSubpageAction(
                icon: Icons.more_horiz_rounded,
                iconSize: 28,
                tooltip: '更多',
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.mode, required this.opacity});

  final _PreviewMode mode;
  final double opacity;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _StatusChip(label: mode.label),
      const SizedBox(width: 8),
      _StatusChip(label: '液态浓度 ${(opacity * 100).round()}%'),
      const Spacer(),
      _StatusChip(
        label: MediaQuery.disableAnimationsOf(context) ? '减弱动态' : '完整弹簧',
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    ),
  );
}

class _FixturePanel extends StatelessWidget {
  const _FixturePanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(26),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _DensePatternPainter()),
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
            ),
          ),
        ),
        Center(
          child: Padding(padding: const EdgeInsets.only(top: 26), child: child),
        ),
      ],
    ),
  );
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFF5C7A),
      Color(0xFFFFC857),
      Color(0xFF00C2A8),
      Color(0xFF507DFF),
      Color(0xFF9B5DE5),
    ];
    const stripeHeight = 36.0;
    for (var y = 0.0; y < size.height; y += stripeHeight) {
      final index = (y / stripeHeight).floor();
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripeHeight),
        Paint()..color = colors[index % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ComicPagePainter extends CustomPainter {
  const _ComicPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF26354A), Color(0xFF744C78), Color(0xFFE69769)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 2;
    for (var index = -2; index < 12; index++) {
      final x = index * 48.0;
      canvas.drawLine(Offset(x, 0), Offset(x + 210, size.height), linePaint);
    }
    final panelPaint = Paint()..color = Colors.black.withValues(alpha: 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28, size.height * 0.28, size.width - 56, 132),
        const Radius.circular(22),
      ),
      panelPaint,
    );
    final title = TextPainter(
      text: const TextSpan(
        text: 'ORIGO\nCOMIC',
        style: TextStyle(
          color: Colors.white,
          fontSize: 38,
          height: 0.95,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width - 72);
    title.paint(
      canvas,
      Offset((size.width - title.width) / 2, size.height * 0.32),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DensePatternPainter extends CustomPainter {
  const _DensePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFF84F82),
      Color(0xFFFFCF4A),
      Color(0xFF36D9C4),
      Color(0xFF4E78FF),
    ];
    const cell = 15.0;
    for (var row = 0; row * cell < size.height; row++) {
      for (var column = 0; column * cell < size.width; column++) {
        canvas.drawRect(
          Rect.fromLTWH(column * cell, row * cell, cell, cell),
          Paint()..color = colors[(row + column) % colors.length],
        );
      }
    }
    final labelPaint = TextPainter(
      text: const TextSpan(
        text: 'ORIGO  GLASS  ORIGO  GLASS',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 20);
    for (var y = 52.0; y < size.height; y += 54) {
      labelPaint.paint(canvas, Offset(10, y));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _PreviewMode {
  frosted('毛玻璃', GlassStyle.frosted),
  liquid('液态玻璃', GlassStyle.liquid),
  off('玻璃关闭', GlassStyle.frosted);

  const _PreviewMode(this.label, this.glassStyle);

  final String label;
  final GlassStyle glassStyle;
}

enum _PreviewScene { controls, reader }
