// flutter test --no-pub tool/preview_theme_controls.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_image_provider.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/app_menu.dart';
import 'package:xxread/widgets/app_skin_artwork.dart';
import 'package:xxread/widgets/app_skin_icon.dart';
import 'package:xxread/widgets/glass_adjustment_slider.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_top_bar.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';

const _captureKey = ValueKey('theme-controls-preview-capture');
const _fixtureKey = ValueKey('theme-controls-preview-fixture');
const _menuKey = ValueKey('theme-controls-preview-menu');
const _outputDirectory = 'build/theme-market/coverage-preview';

bool _fontsLoaded = false;

typedef _PreviewCase = ({
  String name,
  String skin,
  Brightness brightness,
  Size size,
  double textScale,
});

const _cases = <_PreviewCase>[
  (
    name: 'phone-original-light-large',
    skin: 'original',
    brightness: Brightness.light,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-original-dark-large',
    skin: 'original',
    brightness: Brightness.dark,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-tidal-light-large',
    skin: 'tidal',
    brightness: Brightness.light,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-tidal-dark-large',
    skin: 'tidal',
    brightness: Brightness.dark,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-botanical-light-large',
    skin: 'botanical',
    brightness: Brightness.light,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-botanical-dark-large',
    skin: 'botanical',
    brightness: Brightness.dark,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-celestial-light-large',
    skin: 'celestial',
    brightness: Brightness.light,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'phone-celestial-dark-large',
    skin: 'celestial',
    brightness: Brightness.dark,
    size: Size(320, 1000),
    textScale: 1.45,
  ),
  (
    name: 'tablet-tidal-light',
    skin: 'tidal',
    brightness: Brightness.light,
    size: Size(900, 720),
    textScale: 1,
  ),
  (
    name: 'tablet-celestial-dark',
    skin: 'celestial',
    brightness: Brightness.dark,
    size: Size(900, 720),
    textScale: 1,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture unified themed control coverage', (tester) async {
    await _loadFonts(tester);
    debugPrint('theme-controls-preview: fonts-loaded');
    final output = Directory(_outputDirectory);
    await tester.runAsync(() => output.create(recursive: true));
    final captures = <Map<String, Object>>[];

    for (final preview in _cases) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = preview.size;
      debugPrint('theme-controls-preview: pump ${preview.name}');
      await tester.pumpWidget(_PreviewApp(preview: preview));
      debugPrint('theme-controls-preview: widget ${preview.name}');
      await _precacheVisibleSkin(tester);
      await tester.pump();
      debugPrint('theme-controls-preview: ready ${preview.name}');
      expect(tester.takeException(), isNull, reason: preview.name);

      for (final key in const [
        ValueKey('preview-top-back'),
        ValueKey('preview-top-search'),
        ValueKey('preview-reader-back'),
        ValueKey('preview-reader-play'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
        expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
      }
      expect(find.text('阅读控制覆盖'), findsOneWidget);
      expect(find.text('自动翻页速度'), findsOneWidget);
      captures.add(await _capture(tester, '${preview.name}-controls.png'));

      await tester.tap(find.byKey(_menuKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: '${preview.name} menu');
      expect(find.text('搜索书内内容'), findsOneWidget);
      expect(find.text('导出阅读笔记'), findsOneWidget);
      expect(find.text('恢复阅读设置'), findsOneWidget);
      captures.add(await _capture(tester, '${preview.name}-menu.png'));

      await tester.tapAt(Offset(12, preview.size.height - 12));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
    }

    final receipt = {
      'renderer': 'flutter-test',
      'fonts': ['Hiragino Sans GB', 'MaterialIcons'],
      'caseCount': _cases.length,
      'captureCount': captures.length,
      'cases': [
        for (final preview in _cases)
          {
            'name': preview.name,
            'skin': preview.skin,
            'brightness': preview.brightness.name,
            'width': preview.size.width,
            'height': preview.size.height,
            'textScale': preview.textScale,
          },
      ],
      'captures': captures,
      'assertions': {
        'minimumHitTarget': 44,
        'labelsPresent': true,
        'menuLabelsPresent': true,
        'overflowExceptions': 0,
      },
    };
    await tester.runAsync(
      () => File(
        '${output.path}/receipt.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(receipt)),
    );
    tester.view.reset();
  });
}

class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.preview});

  final _PreviewCase preview;

  @override
  Widget build(BuildContext context) {
    final preset = switch (preview.skin) {
      'botanical' => AppThemes.findColorPreset('forest')!,
      'celestial' => AppThemes.findColorPreset('violet')!,
      'tidal' => AppThemes.findColorPreset('blue')!,
      _ => AppThemes.findColorPreset('graphite')!,
    };
    final scheme = preview.brightness == Brightness.dark
        ? preset.theme.darkColorScheme
        : preset.theme.lightColorScheme;
    final skin = AppSkinCatalog.builtIn.resolve(preview.skin);
    final readerPalette = preview.brightness == Brightness.dark
        ? ReaderThemes.navy
        : ReaderThemes.day;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'ThemeControlsPreview',
      extensions: [
        AppSkinTheme(skin: skin),
        const UiStyleThemeExtension(
          style: AppUiStyle.glass,
          glassStyle: GlassStyle.liquid,
          liquidGlassOpacity: 0.5,
        ),
      ],
    );
    final theme = readerPalette
        .toThemeData(parentTheme: base)
        .copyWith(
          textTheme: base.textTheme.apply(
            bodyColor: readerPalette.text,
            displayColor: readerPalette.text,
          ),
        );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: preview.size,
          padding: const EdgeInsets.only(top: 32, bottom: 18),
          viewPadding: const EdgeInsets.only(top: 32, bottom: 18),
          textScaler: TextScaler.linear(preview.textScale),
          disableAnimations: true,
        ),
        child: RepaintBoundary(key: _captureKey, child: child!),
      ),
      home: _ControlCoverage(palette: readerPalette, skinId: preview.skin),
    );
  }
}

class _ControlCoverage extends StatelessWidget {
  const _ControlCoverage({required this.palette, required this.skinId});

  final ReaderThemePalette palette;
  final String skinId;

  @override
  Widget build(BuildContext context) {
    const pageShape = RoundedRectangleBorder();
    return Scaffold(
      key: _fixtureKey,
      body: AppSkinArtwork(
        slot: AppSkinArtworkSlot.pageBackground,
        shape: pageShape,
        child: Column(
          children: [
            GlassTopBar(
              title: '阅读控制覆盖',
              centerTitle: true,
              titleFontSize: 21,
              leading: GlassToolbarButton(
                key: const ValueKey('preview-top-back'),
                icon: Icons.arrow_back_rounded,
                tooltip: '返回',
                onPressed: () {},
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassToolbarButton(
                    key: const ValueKey('preview-top-search'),
                    icon: Icons.search_rounded,
                    tooltip: '搜索',
                    onPressed: () {},
                  ),
                  const SizedBox(width: 6),
                  AppPopupMenuButton<String>(
                    key: _menuKey,
                    tooltip: '更多',
                    buttonStyle: AppMenuButtonStyle.circular,
                    icon: const Icon(Icons.more_horiz_rounded),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'search',
                        child: ListTile(
                          leading: Icon(Icons.search_rounded),
                          title: Text('搜索书内内容'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'note',
                        child: ListTile(
                          leading: Icon(Icons.note_alt_rounded),
                          title: Text('导出阅读笔记'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'sync',
                        child: ListTile(
                          leading: Icon(Icons.cloud_sync_rounded),
                          title: Text('同步阅读进度'),
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'restore',
                        child: ListTile(
                          leading: Icon(Icons.restore_rounded),
                          title: Text('恢复阅读设置'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionLabel('标题栏与阅读浮层 · $skinId'),
                    const SizedBox(height: 8),
                    ReaderControlBar(
                      palette: palette,
                      isTopBar: true,
                      child: SizedBox(
                        height: 58,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: Row(
                            children: [
                              ReaderControlIconButton(
                                key: const ValueKey('preview-reader-back'),
                                palette: palette,
                                onPressed: () {},
                                tooltip: '返回',
                                icon: Icons.arrow_back_rounded,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '第十二章 · 星河与长夜',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              ReaderControlIconButton(
                                palette: palette,
                                onPressed: () {},
                                tooltip: '书签',
                                icon: Icons.bookmark_rounded,
                                selected: true,
                              ),
                              ReaderControlIconButton(
                                palette: palette,
                                onPressed: () {},
                                tooltip: '目录',
                                icon: Icons.menu_book_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ReaderControlBar(
                      palette: palette,
                      isTopBar: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 7,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ReaderControlIconButton(
                              palette: palette,
                              onPressed: () {},
                              tooltip: '上一页',
                              icon: Icons.skip_previous_rounded,
                            ),
                            ReaderControlIconButton(
                              key: const ValueKey('preview-reader-play'),
                              palette: palette,
                              onPressed: () {},
                              tooltip: '播放',
                              icon: Icons.play_arrow_rounded,
                              selected: true,
                            ),
                            ReaderControlIconButton(
                              palette: palette,
                              onPressed: () {},
                              tooltip: '暂停',
                              icon: Icons.pause_rounded,
                            ),
                            ReaderControlIconButton(
                              palette: palette,
                              onPressed: () {},
                              tooltip: '下一页',
                              icon: Icons.skip_next_rounded,
                            ),
                            ReaderControlIconButton(
                              palette: palette,
                              onPressed: () {},
                              tooltip: '朗读',
                              icon: Icons.record_voice_over_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('自动翻页滑条'),
                    const SizedBox(height: 8),
                    GlassAdjustmentSlider(
                      label: '自动翻页速度',
                      value: 30,
                      valueLabel: '30 秒 / 屏',
                      min: 10,
                      max: 90,
                      divisions: 8,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('常用操作'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final item in const [
                          (Icons.format_list_bulleted_rounded, '目录'),
                          (Icons.highlight_rounded, '高亮'),
                          (Icons.note_alt_rounded, '笔记'),
                          (Icons.font_download_rounded, '字体'),
                          (Icons.image_rounded, '背景'),
                          (Icons.sync_rounded, '同步'),
                        ])
                          GlassTextButton(
                            onPressed: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppSkinIcon.adapt(Icon(item.$1, size: 20)),
                                const SizedBox(width: 7),
                                Text(item.$2),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

Future<void> _loadFonts(WidgetTester tester) {
  if (_fontsLoaded) return Future<void>.value();
  return tester.runAsync(() async {
    final chinese = await File(
      '/System/Library/Fonts/Hiragino Sans GB.ttc',
    ).readAsBytes();
    await (FontLoader(
      'ThemeControlsPreview',
    )..addFont(Future.value(ByteData.sublistView(chinese)))).load();
    final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
    final icons = await File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    _fontsLoaded = true;
  });
}

Future<void> _precacheVisibleSkin(WidgetTester tester) async {
  final context = tester.element(find.byKey(_fixtureKey));
  final skin = AppSkinTheme.of(context).skin;
  if (skin.id == AppSkin.originalId) return;
  final brightness = Theme.of(context).brightness;
  const slots = <AppSkinIconSlot>{
    AppSkinIconSlot.back,
    AppSkinIconSlot.search,
    AppSkinIconSlot.more,
    AppSkinIconSlot.bookmark,
    AppSkinIconSlot.catalog,
    AppSkinIconSlot.previous,
    AppSkinIconSlot.play,
    AppSkinIconSlot.pause,
    AppSkinIconSlot.next,
    AppSkinIconSlot.readAloud,
    AppSkinIconSlot.remove,
    AppSkinIconSlot.add,
    AppSkinIconSlot.highlight,
    AppSkinIconSlot.note,
    AppSkinIconSlot.font,
    AppSkinIconSlot.image,
    AppSkinIconSlot.sync,
    AppSkinIconSlot.restore,
    AppSkinIconSlot.check,
  };
  final providers = <ImageProvider<Object>>{
    for (final slot in slots)
      for (final selected in const [false, true])
        if (skin.icons[slot]?.resolve(selected) case final asset?)
          appSkinImageProvider(asset, brightness),
    for (final artwork in skin.artwork.values)
      appSkinImageProvider(artwork, brightness),
  };
  await tester.runAsync(
    () => Future.wait([
      for (final provider in providers) precacheImage(provider, context),
    ]),
  );
}

Future<Map<String, Object>> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    final output = File('$_outputDirectory/$name');
    await output.writeAsBytes(bytes);
    final result = <String, Object>{
      'file': name,
      'width': image.width,
      'height': image.height,
      'sha256': sha256.convert(bytes).toString(),
    };
    image.dispose();
    return result;
  });
  return result!;
}
