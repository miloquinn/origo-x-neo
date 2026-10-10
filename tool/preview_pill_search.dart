import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/ai/ai_page.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/pages/home/home_shell_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_pill_navigation_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';
import 'package:xxread/widgets/reader_ai_panel.dart';

// flutter run --no-pub --enable-impeller \
//   -d B747AC4A-A940-4BBC-A2BB-DE72F5EDE816 \
//   -t tool/preview_pill_search.dart \
//   --dart-define=PREVIEW_CAPTURE=true
const _captureEnabled = bool.fromEnvironment('PREVIEW_CAPTURE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PillSearchPreviewApp());
}

class PillSearchPreviewApp extends StatefulWidget {
  const PillSearchPreviewApp({super.key});

  @override
  State<PillSearchPreviewApp> createState() => _PillSearchPreviewAppState();
}

class _PillSearchPreviewAppState extends State<PillSearchPreviewApp> {
  final _previewBoundaryKey = GlobalKey();
  final _emptyController = TextEditingController();
  final _filledController = TextEditingController(text: '月亮与六便士');
  final _countController = TextEditingController(text: '科幻短篇');
  final _resubmitController = TextEditingController(text: '第 37 章 海边');
  final _captureManifest = <Map<String, Object?>>[];
  final _globalAiHistoryStore = AiChatHistoryStore();
  final _readerAiHistoryStore = AiChatHistoryStore();
  final _aiPageController = AiPageController();
  final _aiService = const _PreviewAiService();

  var _mode = _PreviewMode.liquid;
  var _dark = false;
  var _liquidOpacity = 0.5;
  var _textScale = 1.0;
  var _direction = TextDirection.ltr;
  var _contentWidth = 390.0;
  var _readerPalette = false;
  var _scene = _PreviewScene.search;
  var _selectedNavigationIndex = 1;
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
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _dark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F5DD8),
      brightness: brightness,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        extensions: [
          UiStyleThemeExtension(
            style: AppUiStyle.glass,
            glassStyle: _mode.glassStyle,
            liquidGlassOpacity: _liquidOpacity,
          ),
        ],
      ),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(_textScale)),
          child: RepaintBoundary(key: _previewBoundaryKey, child: child!),
        );
      },
      home: Directionality(
        textDirection: _direction,
        child: switch (_scene) {
          _PreviewScene.search => _PillSearchPreviewPage(
            mode: _mode,
            liquidOpacity: _liquidOpacity,
            contentWidth: _contentWidth,
            readerPalette: _readerPalette,
            emptyController: _emptyController,
            filledController: _filledController,
            countController: _countController,
            resubmitController: _resubmitController,
            selectedNavigationIndex: _selectedNavigationIndex,
            onNavigationSelected: (index) {
              setState(() => _selectedNavigationIndex = index);
            },
          ),
          _PreviewScene.globalAi => _GlobalAiPreviewScene(
            key: const ValueKey('global-ai-preview-scene'),
            contentWidth: _contentWidth,
            historyStore: _globalAiHistoryStore,
            controller: _aiPageController,
            aiService: _aiService,
          ),
          _PreviewScene.readerAi => _ReaderAiPreviewScene(
            key: const ValueKey('reader-ai-preview-scene'),
            historyStore: _readerAiHistoryStore,
            aiService: _aiService,
          ),
        },
      ),
    );
  }

  Future<void> _captureSequence() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/pill-search-previews',
    );
    try {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      await directory.create(recursive: true);
      _log({
        'event': 'capture-start',
        'directory': directory.path,
        'shaderSupported': ui.ImageFilter.isShaderFilterSupported,
      });
      await Future<void>.delayed(const Duration(seconds: 2));

      for (final dark in [false, true]) {
        for (final opacity in [0.0, 0.5, 1.0]) {
          await _setCaptureState(
            mode: _PreviewMode.liquid,
            dark: dark,
            liquidOpacity: opacity,
          );
          await _captureRoot(
            directory,
            'liquid-${dark ? 'dark' : 'light'}-opacity-${_number(opacity)}',
          );
        }
      }

      await _setCaptureState(mode: _PreviewMode.frosted, dark: false);
      await _captureRoot(directory, 'frosted-light');
      await _setCaptureState(mode: _PreviewMode.frosted, dark: true);
      await _captureRoot(directory, 'frosted-dark');
      await _setCaptureState(mode: _PreviewMode.off, dark: false);
      await _captureRoot(directory, 'glass-off-light');

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
        contentWidth: 320,
        textScale: 2,
      );
      await _captureRoot(directory, 'liquid-light-narrow-320-text-2');

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
        direction: TextDirection.rtl,
      );
      await _captureRoot(directory, 'liquid-light-rtl');

      await _setCaptureState(
        mode: _PreviewMode.liquid,
        dark: false,
        liquidOpacity: 0.5,
        readerPalette: true,
      );
      await _captureRoot(directory, 'liquid-reader-dark-palette-light-app');

      await _captureAiSequence(directory);

      final manifest = File('${directory.path}/manifest.json');
      await manifest.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'shaderSupported': ui.ImageFilter.isShaderFilterSupported,
          'captureCount': _captureManifest.length,
          'captures': _captureManifest,
        }),
        flush: true,
      );
      _log({
        'event': 'capture-complete',
        'captureCount': _captureManifest.length,
        'manifest': manifest.path,
      });
    } catch (error, stackTrace) {
      _log({'event': 'capture-failed', 'error': '$error'});
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'pill search preview capture',
        ),
      );
    }
  }

  Future<void> _captureAiSequence(Directory directory) async {
    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.globalAi,
    );
    _setNativeFieldText(const ValueKey('ai-page-input'), '');
    await _settleFieldEdit();
    await _captureRoot(directory, 'ai-global-liquid-light-empty');

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      textScale: 2,
      contentWidth: 320,
      scene: _PreviewScene.globalAi,
    );
    _setNativeFieldText(
      const ValueKey('ai-page-input'),
      '请结合本章内容解释人物的选择，\n并列出两个关键转折。',
    );
    await _settleFieldEdit();
    await _captureRoot(
      directory,
      'ai-global-liquid-light-narrow-320-text-2-multiline',
    );

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: true,
      liquidOpacity: 0.5,
      scene: _PreviewScene.globalAi,
    );
    _setNativeFieldText(const ValueKey('ai-page-input'), '概括当前章节的核心冲突');
    await _settleFieldEdit();
    await _captureRoot(directory, 'ai-global-liquid-dark-filled');

    await _setCaptureState(
      mode: _PreviewMode.frosted,
      dark: false,
      scene: _PreviewScene.globalAi,
    );
    _setNativeFieldText(const ValueKey('ai-page-input'), '分析这一段的伏笔');
    await _settleFieldEdit();
    await _captureRoot(directory, 'ai-global-frosted-light-filled');

    await _setCaptureState(
      mode: _PreviewMode.liquid,
      dark: false,
      liquidOpacity: 0.5,
      scene: _PreviewScene.readerAi,
    );
    _setNativeFieldText(const ValueKey('reader-ai-input'), '这段文字和上一章有什么呼应？');
    await _settleFieldEdit();
    await _captureRoot(
      directory,
      'ai-reader-liquid-dark-palette-light-app-filled',
    );

    await _setCaptureState(
      mode: _PreviewMode.off,
      dark: false,
      scene: _PreviewScene.readerAi,
    );
    _setNativeFieldText(const ValueKey('reader-ai-input'), '解释作者在这里使用的意象');
    await _settleFieldEdit();
    await _captureRoot(
      directory,
      'ai-reader-glass-off-dark-palette-light-app-filled',
    );
  }

  Future<void> _setCaptureState({
    required _PreviewMode mode,
    required bool dark,
    double liquidOpacity = 0.5,
    double textScale = 1,
    TextDirection direction = TextDirection.ltr,
    double contentWidth = 390,
    bool readerPalette = false,
    _PreviewScene scene = _PreviewScene.search,
  }) async {
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _dark = dark;
      _liquidOpacity = liquidOpacity.clamp(0.0, 1.0).toDouble();
      _textScale = textScale;
      _direction = direction;
      _contentWidth = contentWidth;
      _readerPalette = readerPalette;
      _scene = scene;
      _syncGlassConfig();
    });
    _log({
      'event': 'stage',
      'mode': mode.name,
      'brightness': dark ? 'dark' : 'light',
      'liquidOpacity': _liquidOpacity,
      'textScale': textScale,
      'direction': direction.name,
      'contentWidth': contentWidth,
      'readerPalette': readerPalette,
      'scene': scene.name,
    });
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 650));
    await WidgetsBinding.instance.endOfFrame;
  }

  void _setNativeFieldText(Key key, String text) {
    Element? match;
    void visit(Element element) {
      if (match != null) return;
      if (element.widget.key == key && element.widget is TextField) {
        match = element;
        return;
      }
      element.visitChildElements(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) throw StateError('Preview element tree is unavailable');
    visit(root);
    final field = match?.widget;
    if (field is! TextField || field.controller == null) {
      throw StateError('Native TextField with key $key is unavailable');
    }
    field.controller!.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _settleFieldEdit() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 350));
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
      final entry = <String, Object?>{
        'name': name,
        'path': file.path,
        'width': image.width,
        'height': image.height,
        'pixelRatio': pixelRatio,
        'shaderSupported': ui.ImageFilter.isShaderFilterSupported,
      };
      _captureManifest.add(entry);
      _log({'event': 'captured', ...entry});
    } finally {
      image.dispose();
    }
  }

  void _log(Map<String, Object?> value) => stdout.writeln(jsonEncode(value));

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  void dispose() {
    _emptyController.dispose();
    _filledController.dispose();
    _countController.dispose();
    _resubmitController.dispose();
    _globalAiHistoryStore.dispose();
    _readerAiHistoryStore.dispose();
    super.dispose();
  }
}

class _GlobalAiPreviewScene extends StatelessWidget {
  const _GlobalAiPreviewScene({
    super.key,
    required this.contentWidth,
    required this.historyStore,
    required this.controller,
    required this.aiService,
  });

  final double contentWidth;
  final AiChatHistoryStore historyStore;
  final AiPageController controller;
  final ConfigurableAIService aiService;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final metrics = HomeMobileChromeMetrics.fromMediaQuery(mediaQuery);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Center(
            child: SizedBox(
              width: contentWidth.clamp(0.0, mediaQuery.size.width),
              height: mediaQuery.size.height,
              child: ClipRect(
                child: HomeMobileChromeScope(
                  metrics: metrics,
                  child: NavigationContext(
                    useRailNavigation: false,
                    child: AiPage(
                      historyStore: historyStore,
                      controller: controller,
                      aiService: aiService,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderAiPreviewScene extends StatelessWidget {
  const _ReaderAiPreviewScene({
    super.key,
    required this.historyStore,
    required this.aiService,
  });

  static const _meta = AIRequestMeta(
    bookId: 'preview-book',
    chapterId: 'preview-chapter',
    pageIndex: 37,
  );

  final AiChatHistoryStore historyStore;
  final ConfigurableAIService aiService;

  @override
  Widget build(BuildContext context) {
    const palette = ReaderThemes.pureBlack;
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Positioned.fill(
            child: ColoredBox(
              color: palette.background.withValues(alpha: 0.72),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: ReaderAiPanel(
                  palette: palette,
                  meta: _meta,
                  pageText: '潮水退去后，旧灯塔的影子仍横在海面上。',
                  bookTitle: '玻璃海岸',
                  aiService: aiService,
                  historyStore: historyStore,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewAiService implements ConfigurableAIService {
  const _PreviewAiService();

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async =>
      AIProviderSettings.defaults(
        AIProviderType.openai,
      ).copyWith(apiKey: 'preview-local-key');

  @override
  Future<void> saveSettings(AIProviderSettings settings) async {}

  @override
  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  }) async => '本地预览回答';

  @override
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  }) async => '本地预览回答';

  @override
  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  }) async => '本地预览回答';
}

class _PillSearchPreviewPage extends StatelessWidget {
  const _PillSearchPreviewPage({
    required this.mode,
    required this.liquidOpacity,
    required this.contentWidth,
    required this.readerPalette,
    required this.emptyController,
    required this.filledController,
    required this.countController,
    required this.resubmitController,
    required this.selectedNavigationIndex,
    required this.onNavigationSelected,
  });

  final _PreviewMode mode;
  final double liquidOpacity;
  final double contentWidth;
  final bool readerPalette;
  final TextEditingController emptyController;
  final TextEditingController filledController;
  final TextEditingController countController;
  final TextEditingController resubmitController;
  final int selectedNavigationIndex;
  final ValueChanged<int> onNavigationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = readerPalette
        ? const _SearchPalette(
            fill: Color(0xE617171A),
            foreground: Colors.white,
            hint: Color(0xB3FFFFFF),
            accent: Color(0xFFFFCC4D),
            border: Color(0x66FFFFFF),
            brightness: Brightness.dark,
          )
        : const _SearchPalette();
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
          Positioned.fill(
            child: ColoredBox(
              color: scheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.10 : 0.04,
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = contentWidth.clamp(
                  0.0,
                  constraints.maxWidth - 24.0,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PreviewHeader(
                            mode: mode,
                            liquidOpacity: liquidOpacity,
                            readerPalette: readerPalette,
                          ),
                          const SizedBox(height: 14),
                          _SearchFixture(
                            label: '空白 · 原生输入框',
                            child: PillSearchField(
                              key: const ValueKey('pill-search-empty'),
                              textFieldKey: const ValueKey(
                                'pill-search-empty-field',
                              ),
                              controller: emptyController,
                              hintText: '搜索书名、作者或标签',
                              onChanged: (_) {},
                              onSubmitted: (_) {},
                              fillColor: palette.fill,
                              foregroundColor: palette.foreground,
                              hintColor: palette.hint,
                              accentColor: palette.accent,
                              borderColor: palette.border,
                              brightness: palette.brightness,
                            ),
                          ),
                          const SizedBox(height: 11),
                          _SearchFixture(
                            label: '已有内容 · 清除按钮',
                            child: PillSearchField(
                              key: const ValueKey('pill-search-filled'),
                              textFieldKey: const ValueKey(
                                'pill-search-filled-field',
                              ),
                              clearButtonKey: const ValueKey(
                                'pill-search-filled-clear',
                              ),
                              controller: filledController,
                              hintText: '搜索书籍',
                              clearTooltip: '清除书籍搜索',
                              onChanged: (_) {},
                              onSubmitted: (_) {},
                              fillColor: palette.fill,
                              foregroundColor: palette.foreground,
                              hintColor: palette.hint,
                              accentColor: palette.accent,
                              borderColor: palette.border,
                              brightness: palette.brightness,
                            ),
                          ),
                          const SizedBox(height: 11),
                          _SearchFixture(
                            label: '匹配计数 · 清除按钮',
                            child: PillSearchField(
                              key: const ValueKey('pill-search-count'),
                              textFieldKey: const ValueKey(
                                'pill-search-count-field',
                              ),
                              clearButtonKey: const ValueKey(
                                'pill-search-count-clear',
                              ),
                              controller: countController,
                              hintText: '在当前书中查找',
                              clearTooltip: '清除正文搜索',
                              trailing: const Padding(
                                padding: EdgeInsetsDirectional.only(end: 4),
                                child: Text('12 / 128'),
                              ),
                              onChanged: (_) {},
                              onSubmitted: (_) {},
                              fillColor: palette.fill,
                              foregroundColor: palette.foreground,
                              hintColor: palette.hint,
                              accentColor: palette.accent,
                              borderColor: palette.border,
                              brightness: palette.brightness,
                            ),
                          ),
                          const SizedBox(height: 11),
                          _SearchFixture(
                            label: '再次提交 · 始终保留尾部操作',
                            child: PillSearchField(
                              key: const ValueKey('pill-search-resubmit'),
                              textFieldKey: const ValueKey(
                                'pill-search-resubmit-field',
                              ),
                              controller: resubmitController,
                              hintText: '跳转章节',
                              showClearButton: false,
                              trailing: IconButton(
                                key: const ValueKey(
                                  'pill-search-resubmit-action',
                                ),
                                tooltip: '再次搜索',
                                onPressed: () {},
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                              onChanged: (_) {},
                              onSubmitted: (_) {},
                              fillColor: palette.fill,
                              foregroundColor: palette.foreground,
                              hintColor: palette.hint,
                              accentColor: palette.accent,
                              borderColor: palette.border,
                              brightness: palette.brightness,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: FloatingPillNavigationSurface(
                              width: width.clamp(260.0, 340.0),
                              height: 66,
                              child: ElasticPillNavigationBar(
                                selectedIndex: selectedNavigationIndex,
                                onSelected: onNavigationSelected,
                                children: const [
                                  _NavigationIcon(
                                    icon: Icons.home_outlined,
                                    label: '首页',
                                  ),
                                  _NavigationIcon(
                                    icon: Icons.library_books_rounded,
                                    label: '书库',
                                  ),
                                  _NavigationIcon(
                                    icon: Icons.explore_outlined,
                                    label: '发现',
                                  ),
                                  _NavigationIcon(
                                    icon: Icons.person_outline_rounded,
                                    label: '我的',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.mode,
    required this.liquidOpacity,
    required this.readerPalette,
  });

  final _PreviewMode mode;
  final double liquidOpacity;
  final bool readerPalette;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'PillSearchField · 生产组件',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            readerPalette
                ? '阅读器深色'
                : mode == _PreviewMode.liquid
                ? '${mode.label} ${(liquidOpacity * 100).round()}%'
                : mode.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    ),
  );
}

class _SearchFixture extends StatelessWidget {
  const _SearchFixture({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, bottom: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            shadows: const [Shadow(color: Colors.white, blurRadius: 7)],
          ),
        ),
      ),
      child,
    ],
  );
}

class _NavigationIcon extends StatelessWidget {
  const _NavigationIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Center(child: Icon(icon, size: 25)),
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
    const stripeHeight = 34.0;
    for (var y = 0.0; y < size.height; y += stripeHeight) {
      final index = (y / stripeHeight).floor();
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, stripeHeight),
        Paint()..color = colors[index % colors.length],
      );
    }
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 2;
    for (var x = -size.height; x < size.width; x += 48) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SearchPalette {
  const _SearchPalette({
    this.fill,
    this.foreground,
    this.hint,
    this.accent,
    this.border,
    this.brightness,
  });

  final Color? fill;
  final Color? foreground;
  final Color? hint;
  final Color? accent;
  final Color? border;
  final Brightness? brightness;
}

enum _PreviewMode {
  frosted('毛玻璃', GlassStyle.frosted),
  liquid('液态玻璃', GlassStyle.liquid),
  off('玻璃关闭', GlassStyle.frosted);

  const _PreviewMode(this.label, this.glassStyle);

  final String label;
  final GlassStyle glassStyle;
}

enum _PreviewScene { search, globalAi, readerAi }
