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
import 'package:xxread/widgets/side_toast.dart';

// Native renderer fixture for the production root-overlay side toast.
void main() => runApp(const _Preview());

class _ToastScene {
  const _ToastScene({
    required this.name,
    required this.style,
    required this.brightness,
    required this.kind,
    required this.message,
    this.width = 390,
    this.textScale = 1,
    this.actionLabel,
  });

  final String name;
  final AppUiStyle style;
  final Brightness brightness;
  final SideToastKind kind;
  final String message;
  final double width;
  final double textScale;
  final String? actionLabel;

  GlassStyle get glassStyle =>
      name.startsWith('frosted') ? GlassStyle.frosted : GlassStyle.liquid;
}

class _Preview extends StatefulWidget {
  const _Preview();

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _sceneContext = GlobalKey();
  var _index = 0;

  static const _scenes = [
    _ToastScene(
      name: 'solid-light',
      style: AppUiStyle.material3,
      brightness: Brightness.light,
      kind: SideToastKind.success,
      message: '已记录推荐反馈',
    ),
    _ToastScene(
      name: 'solid-dark',
      style: AppUiStyle.material3,
      brightness: Brightness.dark,
      kind: SideToastKind.info,
      message: '已保存到阅读历史',
    ),
    _ToastScene(
      name: 'frosted-light',
      style: AppUiStyle.glass,
      brightness: Brightness.light,
      kind: SideToastKind.warning,
      message: '暂时无法加载更多推荐',
    ),
    _ToastScene(
      name: 'frosted-dark',
      style: AppUiStyle.glass,
      brightness: Brightness.dark,
      kind: SideToastKind.success,
      message: '已调整推荐偏好',
    ),
    _ToastScene(
      name: 'liquid-light',
      style: AppUiStyle.glass,
      brightness: Brightness.light,
      kind: SideToastKind.info,
      message: '正在为你更新阅读建议',
    ),
    _ToastScene(
      name: 'liquid-dark',
      style: AppUiStyle.glass,
      brightness: Brightness.dark,
      kind: SideToastKind.error,
      message: '反馈提交失败，请稍后重试',
    ),
    _ToastScene(
      name: 'liquid-large-text-action-320',
      style: AppUiStyle.glass,
      brightness: Brightness.light,
      kind: SideToastKind.warning,
      message: '网络波动，本次反馈尚未提交',
      width: 320,
      textScale: 1.65,
      actionLabel: '重试',
    ),
    _ToastScene(
      name: 'liquid-long-error-320',
      style: AppUiStyle.glass,
      brightness: Brightness.dark,
      kind: SideToastKind.error,
      message: '暂时无法记录这次推荐反馈，阅读内容不受影响，请检查网络后重试',
      width: 320,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final palette = scene.brightness == Brightness.dark
        ? ReaderThemes.night
        : ReaderThemes.day;
    final glassDisabled = scene.style == AppUiStyle.material3;
    GlassEffectConfig.setGlassStyle(scene.glassStyle);
    GlassEffectConfig.setDisableAllGlassEffects(glassDisabled);
    final theme = palette.toThemeData().copyWith(
      extensions: [
        UiStyleThemeExtension(
          style: scene.style,
          glassStyle: scene.glassStyle,
          liquidGlassOpacity: 0.5,
        ),
      ],
    );
    final size = Size(scene.width, 844);

    return Center(
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: size,
          child: MaterialApp(
            key: ValueKey(scene.name),
            themeAnimationDuration: Duration.zero,
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
                textScaler: TextScaler.linear(scene.textScale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: _AiRecommendationsPage(key: _sceneContext, palette: palette),
          ),
        ),
      ),
    );
  }

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/side-toast-previews',
    );
    await directory.create(recursive: true);
    for (var i = 0; i < _scenes.length; i++) {
      if (!mounted) return;
      hideSideToast();
      setState(() => _index = i);
      await WidgetsBinding.instance.endOfFrame;
      final context = _sceneContext.currentContext!;
      if (!context.mounted) return;
      final scene = _scenes[i];
      showSideToast(
        context,
        scene.message,
        kind: scene.kind,
        duration: const Duration(minutes: 1),
        actionLabel: scene.actionLabel,
        onAction: scene.actionLabel == null ? null : () {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 450));
      await _snapshot(directory, scene.name);
    }
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'scenes': _scenes.map((scene) => scene.name).toList(),
        'kind': 'production showSideToast root overlay',
      }),
    );
    debugPrint('SIDE_TOAST_PREVIEWS_COMPLETE ${directory.path}');
  }

  Future<void> _snapshot(Directory directory, String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  }
}

class _AiRecommendationsPage extends StatelessWidget {
  const _AiRecommendationsPage({super.key, required this.palette});

  final ReaderThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AiBackdrop(palette.background, palette.accent),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI 阅读助手',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.history_rounded),
                        tooltip: '历史记录',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('为你推荐', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        _RecommendationCard(
                          title: '斗破苍穹',
                          source: '天蚕土豆 · 35小说网手机版',
                          reason: '你正在读《神通者》，这部成名作也有紧凑的成长线。',
                        ),
                        SizedBox(height: 12),
                        _RecommendationCard(
                          title: '本宫来自现代经济学院',
                          source: '贝乐子珠珠乐 · 35小说网手机版',
                          reason: '穿越题材融合经济学元素，适合接着上一本的阅读节奏。',
                        ),
                        SizedBox(height: 12),
                        _RecommendationCard(
                          title: '寒门崛起，我靠种田打猎发家致富',
                          source: '何半仙儿 · 35小说网手机版',
                          reason: '种田经营叠加历史背景，叙事偏写实，可以换个口味。',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 58,
                    padding: const EdgeInsets.only(left: 17, right: 7),
                    decoration: BoxDecoration(
                      color: palette.controlBar,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(29),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: palette.text),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '就本书内容提问…',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: palette.accent,
                          foregroundColor: palette.onAccent,
                          child: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.source,
    required this.reason,
  });

  final String title;
  final String source;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 9),
          Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.tonal(onPressed: () {}, child: const Text('查看书籍')),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_alt_outlined),
                tooltip: '喜欢',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.thumb_down_alt_outlined),
                tooltip: '不喜欢',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiBackdrop extends CustomPainter {
  const _AiBackdrop(this.base, this.accent);

  final Color base;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()..color = accent.withValues(alpha: 0.09);
    canvas.drawCircle(Offset(size.width + 18, 180), 150, paint);
    canvas.drawCircle(Offset(-34, size.height - 120), 120, paint);
  }

  @override
  bool shouldRepaint(_AiBackdrop old) =>
      old.base != base || old.accent != accent;
}
