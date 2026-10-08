import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

// flutter run -t tool/preview_liquid_glass.dart \
//   --dart-define=PREVIEW_GLASS_STYLE=liquid \
//   --dart-define=PREVIEW_DARK=false \
//   --dart-define=PREVIEW_TEXT_SCALE=1.0 \
//   --dart-define=PREVIEW_CAPTURE=true
const _initialStyle = String.fromEnvironment(
  'PREVIEW_GLASS_STYLE',
  defaultValue: 'liquid',
);
const _initialDark = bool.fromEnvironment('PREVIEW_DARK');
const _captureEnabled = bool.fromEnvironment('PREVIEW_CAPTURE');
const _initialTextScale = String.fromEnvironment(
  'PREVIEW_TEXT_SCALE',
  defaultValue: '1.0',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LiquidGlassPreviewApp());
}

class LiquidGlassPreviewApp extends StatefulWidget {
  const LiquidGlassPreviewApp({super.key});

  @override
  State<LiquidGlassPreviewApp> createState() => _LiquidGlassPreviewAppState();
}

class _LiquidGlassPreviewAppState extends State<LiquidGlassPreviewApp> {
  final _previewBoundaryKey = GlobalKey();
  late _PreviewGlassMode _mode;
  double _navigationOffsetX = 0;
  bool _captureStarted = false;

  @override
  void initState() {
    super.initState();
    _mode = _PreviewGlassMode.fromEnvironment(_initialStyle);
    _syncGlassConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_captureEnabled && !_captureStarted) {
        _captureStarted = true;
        unawaited(_captureSequence());
      }
    });
  }

  void _setMode(_PreviewGlassMode mode) {
    setState(() {
      _mode = mode;
      _syncGlassConfig();
    });
  }

  void _syncGlassConfig() {
    GlassEffectConfig.setGlassStyle(_mode.glassStyle);
    GlassEffectConfig.setDisableAllGlassEffects(_mode == _PreviewGlassMode.off);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _initialDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5067D9),
      brightness: brightness,
    );
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [
        UiStyleThemeExtension(
          style: _mode == _PreviewGlassMode.off
              ? AppUiStyle.material3
              : AppUiStyle.glass,
          glassStyle: _mode.glassStyle,
        ),
      ],
    );
    final textScale = double.tryParse(_initialTextScale) ?? 1;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale.clamp(0.8, 2.0).toDouble()),
        ),
        child: RepaintBoundary(key: _previewBoundaryKey, child: child!),
      ),
      home: _PreviewPage(
        mode: _mode,
        navigationOffsetX: _navigationOffsetX,
        onModeChanged: _setMode,
      ),
    );
  }

  Future<void> _captureSequence() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/liquid-glass-previews',
    );
    try {
      await directory.create(recursive: true);
      stdout.writeln(
        '[liquid-glass-preview] capture-start '
        'shader-supported=${ui.ImageFilter.isShaderFilterSupported} '
        'directory=${directory.path}',
      );
      await Future<void>.delayed(const Duration(seconds: 2));

      for (final mode in _PreviewGlassMode.values) {
        await _setCaptureState(mode: mode);
        await _captureRoot(directory, mode.name);
        if (mode == _PreviewGlassMode.liquid) {
          await _setCaptureState(mode: mode, navigationOffsetX: 20);
          await _captureRoot(directory, 'liquid-navigation-moving');
          await _setCaptureState(mode: mode, navigationOffsetX: 0);
        }
      }
      stdout.writeln('[liquid-glass-preview] capture-complete');
    } catch (error, stackTrace) {
      stdout.writeln('[liquid-glass-preview] capture-failed error=$error');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'liquid glass preview capture',
        ),
      );
    }
  }

  Future<void> _setCaptureState({
    required _PreviewGlassMode mode,
    double navigationOffsetX = 0,
  }) async {
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _navigationOffsetX = navigationOffsetX;
      _syncGlassConfig();
    });
    stdout.writeln(
      '[liquid-glass-preview] stage=${mode.name} '
      'navigation-offset-x=$navigationOffsetX',
    );
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(seconds: 1));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _captureRoot(Directory directory, String name) async {
    if (!mounted) return;
    final renderObject = _previewBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Preview RepaintBoundary is unavailable');
    }
    final pixelRatio = View.of(
      _previewBoundaryKey.currentContext!,
    ).devicePixelRatio;
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding returned no bytes');
      final brightness = _initialDark ? 'dark' : 'light';
      final file = File('${directory.path}/$brightness-$name.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      stdout.writeln(
        '[liquid-glass-preview] captured=${file.path} '
        'size=${image.width}x${image.height} pixel-ratio=$pixelRatio',
      );
    } finally {
      image.dispose();
    }
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({
    required this.mode,
    required this.navigationOffsetX,
    required this.onModeChanged,
  });

  final _PreviewGlassMode mode;
  final double navigationOffsetX;
  final ValueChanged<_PreviewGlassMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.brightness == Brightness.dark
        ? ReaderThemes.night
        : ReaderThemes.day;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 12.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '玻璃表面实验室',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '真实背景折射预览 · 无账户、网络或 Provider 依赖',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in _PreviewGlassMode.values)
                        ChoiceChip(
                          label: Text(value.label),
                          selected: value == mode,
                          onSelected: (_) => onModeChanged(value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: '当前：${mode.label}'),
                      _StatusChip(
                        label: ui.ImageFilter.isShaderFilterSupported
                            ? 'Shader：支持'
                            : 'Shader：轻模糊回退',
                      ),
                      _StatusChip(
                        label: theme.brightness == Brightness.dark
                            ? '深色模式'
                            : '浅色模式',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _PatternStage(
                    title: '共享导航胶囊',
                    colors: const [
                      Color(0xFFFF6B6B),
                      Color(0xFFFFC857),
                      Color(0xFF5FD1A8),
                    ],
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth
                            .clamp(0.0, 350.0)
                            .toDouble();
                        return Transform.translate(
                          offset: Offset(navigationOffsetX, 0),
                          child: RepaintBoundary(
                            key: const ValueKey(
                              'liquid-preview-navigation-boundary',
                            ),
                            child: FloatingPillNavigationSurface(
                              width: width,
                              height: 64,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: const [
                                  _NavigationItem(
                                    icon: Icons.library_books_rounded,
                                    label: '书架',
                                    selected: true,
                                  ),
                                  _NavigationItem(
                                    icon: Icons.explore_rounded,
                                    label: '发现',
                                  ),
                                  _NavigationItem(
                                    icon: Icons.person_rounded,
                                    label: '我的',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PatternStage(
                    title: '圆形与胶囊控件',
                    colors: const [
                      Color(0xFF4D96FF),
                      Color(0xFF9B5DE5),
                      Color(0xFFFF6FB5),
                    ],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: 54,
                          child: GlassControlSurface(
                            shape: const CircleBorder(),
                            color: theme.colorScheme.secondaryContainer,
                            child: const Icon(Icons.auto_awesome_rounded),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          height: 54,
                          child: GlassControlSurface(
                            emphasized: true,
                            color: theme.colorScheme.primaryContainer,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 22),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune_rounded),
                                  SizedBox(width: 8),
                                  Text('阅读设置'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PatternStage(
                    title: '阅读控制栏',
                    colors: const [
                      Color(0xFFFF8A5B),
                      Color(0xFF00B4D8),
                      Color(0xFF80B918),
                    ],
                    child: ReaderControlBar(
                      palette: palette,
                      isTopBar: false,
                      child: SizedBox(
                        height: 58,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final icon in [
                              Icons.format_size_rounded,
                              Icons.menu_book_rounded,
                              Icons.headphones_rounded,
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Icon(icon, color: palette.text),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PatternStage extends StatelessWidget {
  const _PatternStage({
    required this.title,
    required this.colors,
    required this.child,
  });

  final String title;
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 178,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var index = 0; index < 6; index++)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 7,
                              color: colors[index % colors.length],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${index + 1} · ORIGO GLASS',
                            style: TextStyle(
                              color: onSurface.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 14,
            child: Text(
              title,
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(top: 22), child: child),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

enum _PreviewGlassMode {
  frosted('毛玻璃', GlassStyle.frosted),
  liquid('液态玻璃', GlassStyle.liquid),
  off('关闭', GlassStyle.frosted);

  const _PreviewGlassMode(this.label, this.glassStyle);

  final String label;
  final GlassStyle glassStyle;

  static _PreviewGlassMode fromEnvironment(String value) {
    return switch (value.trim().toLowerCase()) {
      'frosted' => frosted,
      'off' || 'disabled' => off,
      _ => liquid,
    };
  }
}
