import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/bookmark.dart';
import 'package:xxread/pages/settings/app_text_size_sheet.dart';
import 'package:xxread/pages/settings/font_selection_sheet.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_settings_controls.dart';
import 'package:xxread/widgets/glass_surface.dart';

const _geometryOnly = bool.fromEnvironment('ORIGO_SHEET_GEOMETRY_PREVIEW');
const _edgePreview = bool.fromEnvironment('ORIGO_SHEET_EDGE_PREVIEW');
const _appTextScaleKey = 'app_text_scale_level_v1';
const _appFontKey = 'app_font_id_v2';

// Native renderer fixture: shared modal route and production reader controls.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedSettings = _SavedSettings(
    appTextScaleLevel: preferences.getInt(_appTextScaleKey),
    appFontId: preferences.getString(_appFontKey),
  );
  await preferences.setInt(
    _appTextScaleKey,
    AppSettingsNotifier.defaultAppTextScaleLevel,
  );
  await preferences.setString(_appFontKey, FontCatalog.systemId);
  final settings = AppSettingsNotifier();
  if (!settings.isInitialized) {
    final initialized = Completer<void>();
    void listener() {
      if (settings.isInitialized && !initialized.isCompleted) {
        initialized.complete();
      }
    }

    settings.addListener(listener);
    listener();
    await initialized.future;
    settings.removeListener(listener);
  }
  runApp(
    _Preview(
      settings: settings,
      preferences: preferences,
      savedSettings: savedSettings,
    ),
  );
}

class _SavedSettings {
  const _SavedSettings({this.appTextScaleLevel, this.appFontId});

  final int? appTextScaleLevel;
  final String? appFontId;

  Future<void> restore(SharedPreferences preferences) async {
    if (appTextScaleLevel == null) {
      await preferences.remove(_appTextScaleKey);
    } else {
      await preferences.setInt(_appTextScaleKey, appTextScaleLevel!);
    }
    if (appFontId == null) {
      await preferences.remove(_appFontKey);
    } else {
      await preferences.setString(_appFontKey, appFontId!);
    }
  }
}

class _Preview extends StatefulWidget {
  const _Preview({
    required this.settings,
    required this.preferences,
    required this.savedSettings,
  });

  final AppSettingsNotifier settings;
  final SharedPreferences preferences;
  final _SavedSettings savedSettings;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  var _navigator = GlobalKey<NavigatorState>();
  var _sceneContext = GlobalKey();
  final _topBar = GlobalKey();
  final _bottomBar = GlobalKey();
  var _index = 0;
  var _fontSize = 20.0;
  var _lineHeight = 1.8;
  var _letterSpacing = 0.0;

  final _geometry = <String, Object>{};

  static const _scenes = _edgePreview
      ? [
          'liquid-light',
          'liquid-night',
          'frosted-light',
          'solid-light',
          'narrow-large',
          'landscape',
          'scrolled-end',
          'font-selection-end',
          'app-text-size-end',
          'reader-navigation-catalog-end',
          'reader-navigation-bookmarks-end',
        ]
      : _geometryOnly
      ? [
          'liquid-light',
          'liquid-night',
          'frosted-light',
          'solid-light',
          'geometry-android',
          'geometry-landscape',
          'geometry-compact',
          'high-contrast',
        ]
      : [
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

  @override
  void dispose() {
    widget.settings.dispose();
    super.dispose();
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
    final edgeNarrowLarge = _edgePreview && scene == 'narrow-large';
    final large = scene == 'liquid-large-text' || edgeNarrowLarge;
    final compact = scene == 'liquid-compact';
    final androidGeometry = scene == 'geometry-android';
    final landscapeGeometry =
        scene == 'geometry-landscape' || (_edgePreview && scene == 'landscape');
    final narrowGeometry = scene == 'geometry-compact';
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
    final size = androidGeometry
        ? const Size(412, 915)
        : landscapeGeometry
        ? const Size(844, 390)
        : edgeNarrowLarge
        ? const Size(320, 740)
        : narrowGeometry
        ? const Size(320, 650)
        : Size(large ? 320 : 390, compact ? 380 : 844);
    final padding = androidGeometry
        ? const EdgeInsets.only(top: 24, bottom: 24)
        : landscapeGeometry
        ? const EdgeInsets.only(left: 47, right: 47, bottom: 21)
        : const EdgeInsets.only(top: 44, bottom: 34);
    return Center(
      child: RepaintBoundary(
        key: _boundary,
        child: SizedBox.fromSize(
          size: size,
          child: ChangeNotifierProvider<AppSettingsNotifier>.value(
            value: widget.settings,
            child: MaterialApp(
              key: ValueKey(_edgePreview ? scene : 'shared-sheet-preview'),
              navigatorKey: _navigator,
              debugShowCheckedModeBanner: false,
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(
                      size: size,
                      padding: padding,
                      viewPadding: padding,
                      viewInsets: EdgeInsets.zero,
                      highContrast: highContrast,
                      disableAnimations: large,
                      textScaler: TextScaler.linear(
                        edgeNarrowLarge ? 1.6 : (large ? 2.4 : 1),
                      ),
                    )
                    .applyDisplayCornerRadii(
                      androidGeometry ? BorderRadius.circular(64) : null,
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
            key: const ValueKey('shared-sheet-edge-last-slider'),
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

  static const _firstChapterTitle = '第 1 章 · 风从窗边经过';
  static const _lastChapterTitle = '第 36 章 · 归途';
  static const _firstBookmarkTitle = '书签 1 · 风从窗边经过';
  static const _lastBookmarkTitle = '书签 14 · 灯火仍在';

  late final List<ReaderNavigationChapter> _navigationChapters = List.generate(
    36,
    (index) => ReaderNavigationChapter(
      id: 'chapter-$index',
      index: index,
      depth: index == 0 || index % 6 == 0 ? 0 : 1,
      title: index == 0
          ? _firstChapterTitle
          : index == 35
          ? _lastChapterTitle
          : '第 ${index + 1} 章 · 本地章节 ${index + 1}',
    ),
    growable: false,
  );
  late final ReaderNavigationCatalog _navigationCatalog =
      ReaderNavigationCatalog(_navigationChapters);

  late final List<Bookmark> _navigationBookmarks = List.generate(
    14,
    (index) => Bookmark(
      id: index + 1,
      bookId: 1,
      pageNumber: index,
      anchorKey: 'bookmark-$index',
      chapterIndex: index,
      chapterTitle: index == 0
          ? _firstBookmarkTitle
          : index == 13
          ? _lastBookmarkTitle
          : '第 ${index + 1} 章 · 书签 ${index + 1}',
      excerpt: '固定本地书签摘录 ${index + 1}，用于验证真实列表末项与安全区。',
      createDate: DateTime.utc(2026, 10, index + 1),
    ),
    growable: false,
  );

  String _menuKind(String scene) => switch (scene) {
    'font-selection-end' => 'font-selection',
    'app-text-size-end' => 'app-text-size',
    'reader-navigation-catalog-end' => 'reader-navigation-catalog',
    'reader-navigation-bookmarks-end' => 'reader-navigation-bookmarks',
    _ => 'reader-settings',
  };

  bool _builderOwnsSurface(String scene) =>
      _menuKind(scene) == 'reader-settings';

  Widget _edgeMenu(BuildContext context, String scene) => switch (_menuKind(
    scene,
  )) {
    'font-selection' => FontSelectionSheet(
      settings: widget.settings,
      domain: FontDomain.app,
      title: '应用字体',
      description: '选择界面使用的字体。',
    ),
    'app-text-size' => const AppTextSizeSheet(),
    'reader-navigation-catalog' || 'reader-navigation-bookmarks' => SizedBox(
      height:
          MediaQuery.sizeOf(context).height * 0.86 -
          GlassBottomSheetSurface.dragHandleExtent,
      child: ReaderNavigationSheet(
        palette: _palette,
        chapters: _navigationChapters,
        catalog: _navigationCatalog,
        currentChapterIndex: 0,
        currentNavigationPosition: 0,
        bookmarks: _navigationBookmarks,
        currentAnchorKey: _navigationBookmarks.first.anchorKey,
        onChapterSelected: (_) {},
        onBookmarkSelected: (_) {},
        onBookmarkDeleted: (_) {},
      ),
    ),
    _ => _settings(context),
  };

  Future<void> _capture() async {
    final directory = Directory(
      '${Directory.systemTemp.path}/${_edgePreview
          ? 'shared-sheet-edge-preview'
          : _geometryOnly
          ? 'sheet-geometry-previews'
          : 'shared-glass-sheets-previews'}',
    );
    await directory.create(recursive: true);
    for (var i = 0; i < _scenes.length; i++) {
      if (!mounted) return;
      if (_geometryOnly || _edgePreview) {
        await SystemChrome.setPreferredOrientations([
          _scenes[i] == 'geometry-landscape' || _scenes[i] == 'landscape'
              ? DeviceOrientation.landscapeLeft
              : DeviceOrientation.portraitUp,
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      setState(() {
        _index = i;
        if (_edgePreview) {
          _navigator = GlobalKey<NavigatorState>();
          _sceneContext = GlobalKey();
        }
      });
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
          backgroundColor:
              _edgePreview && _menuKind(_scenes[i]) == 'font-selection'
              ? Colors.transparent
              : _palette.surface,
          builderOwnsSurface: _edgePreview && _builderOwnsSurface(_scenes[i]),
          builder: _edgePreview
              ? (context) => _edgeMenu(context, _scenes[i])
              : _scenes[i] == 'liquid-actions'
              ? _actions
              : _settings,
        ),
      );
      await Future<void>.delayed(
        Duration(milliseconds: _edgePreview ? 1100 : 650),
      );
      if (_edgePreview && _scenes[i] == 'reader-navigation-bookmarks-end') {
        await _activateNavigationTab(1);
      }
      if (_edgePreview && _scenes[i].endsWith('-end')) {
        await _settleMenuScrollAtEnd(_scenes[i]);
      }
      await _snapshot(directory, _scenes[i]);
      _navigator.currentState!.pop();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final shaderReady =
        !_edgePreview ||
        _geometry.entries.every((entry) {
          final value = entry.value as Map<String, Object?>;
          if (value['uiStyle'] == 'material3' ||
              value['glassStyle'] != 'liquid') {
            return true;
          }
          return (value['nativeImpeller']
                  as Map<String, Object?>)['shaderReady'] ==
              true;
        });
    await File('${directory.path}/render-context.json').writeAsString(
      jsonEncode({
        'platform': 'ios',
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        if (_edgePreview) 'shaderReady': shaderReady,
        'scenes': _scenes,
        'kind': _edgePreview
            ? 'edge-to-edge production ReaderSettingsSheetFrame on native shared modal route'
            : 'actual shared modal route and production reader controls',
        if (_edgePreview)
          'coverage':
              'production ReaderSettingsSheetFrame, FontSelectionSheet, '
              'AppTextSizeSheet, and ReaderNavigationSheet consumers',
        if (_edgePreview) 'nativeDefine': 'ORIGO_SHEET_EDGE_PREVIEW=true',
        if (_edgePreview)
          'menuKinds': {for (final scene in _scenes) scene: _menuKind(scene)},
        'geometry': _geometry,
        'androidGeometryIsSimulatedOnIos': _geometryOnly,
      }),
    );
    await widget.savedSettings.restore(widget.preferences);
    if (_edgePreview) {
      debugPrint(
        'SHARED_SHEET_EDGE_PREVIEW_COMPLETE directory=${directory.path} '
        'context=${directory.path}/render-context.json shaderReady=$shaderReady',
      );
    } else {
      debugPrint('SHARED_SHEETS_PREVIEWS_COMPLETE ${directory.path}');
    }
  }

  Future<void> _snapshot(Directory directory, String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    if (_geometryOnly || _edgePreview) {
      final panels = <({GlassSurface widget, RenderBox box})>[];
      void visit(Element element) {
        final widget = element.widget;
        if (widget is GlassSurface && widget.role == GlassSurfaceRole.panel) {
          final box = element.findRenderObject()! as RenderBox;
          if (box.hasSize) panels.add((widget: widget, box: box));
        }
        element.visitChildElements(visit);
      }

      (_navigator.currentContext! as Element).visitChildElements(visit);
      panels.sort(
        (a, b) => (b.box.size.width * b.box.size.height).compareTo(
          a.box.size.width * a.box.size.height,
        ),
      );
      final panel = panels.first;
      final panelRect = _localRect(panel.box, boundary);
      if (_edgePreview) {
        _geometry[name] = _edgeGeometry(
          name: name,
          boundary: boundary,
          panel: panel.widget,
          panelRect: panelRect,
        );
      } else {
        _geometry[name] = {
          'left': panelRect.left,
          'right': boundary.size.width - panelRect.right,
          'bottom': boundary.size.height - panelRect.bottom,
          'panelWidth': panelRect.width,
          'shape': panel.widget.shape.runtimeType.toString(),
          'radius': (panel.widget.shape as RoundedSuperellipseBorder)
              .borderRadius
              .resolve(TextDirection.ltr)
              .topLeft
              .x,
        };
      }
    }
    final screenshot = await boundary.toImage(pixelRatio: 2);
    final data = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    screenshot.dispose();
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(data!.buffer.asUint8List());
  }

  ScrollPosition? _settingsScrollPosition() {
    ScrollPosition? result;
    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement &&
          element.widget is Scrollable &&
          element.state is ScrollableState) {
        result = (element.state as ScrollableState).position;
        return;
      }
      element.visitChildElements(visit);
    }

    (_navigator.currentContext! as Element).visitChildElements(visit);
    return result;
  }

  Future<void> _activateNavigationTab(int index) async {
    TabBar? tabs;
    void visit(Element element) {
      if (tabs != null) return;
      if (element.widget case final TabBar tabBar) {
        tabs = tabBar;
        return;
      }
      element.visitChildElements(visit);
    }

    (_navigator.currentContext! as Element).visitChildElements(visit);
    final controller = tabs?.controller;
    if (controller == null) {
      throw StateError('Reader navigation TabBar controller is unavailable');
    }
    controller.animateTo(index);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _settleMenuScrollAtEnd(String scene) async {
    const tolerance = 0.5;
    const stableExtentTolerance = 0.1;
    ScrollPosition? position;
    for (var attempt = 0; attempt < 12; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      position = _menuScrollPosition(scene);
      if (position != null &&
          position.hasContentDimensions &&
          !position.isScrollingNotifier.value) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    if (position == null ||
        !position.hasContentDimensions ||
        position.isScrollingNotifier.value) {
      throw StateError(
        '${_menuKind(scene)} initial scroll did not become idle',
      );
    }

    double? previousMaxExtent;
    for (var attempt = 0; attempt < 8; attempt++) {
      position = _menuScrollPosition(scene);
      if (position == null || !position.hasContentDimensions) {
        throw StateError('${_menuKind(scene)} scroll position was detached');
      }
      position.jumpTo(position.maxScrollExtent);
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 140));
      await WidgetsBinding.instance.endOfFrame;

      position = _menuScrollPosition(scene);
      if (position == null || !position.hasContentDimensions) continue;
      final maxExtent = position.maxScrollExtent;
      final delta = (position.pixels - maxExtent).abs();
      final extentStable =
          previousMaxExtent != null &&
          (maxExtent - previousMaxExtent).abs() <= stableExtentTolerance;
      previousMaxExtent = maxExtent;
      if (delta > tolerance ||
          !extentStable ||
          position.isScrollingNotifier.value) {
        continue;
      }

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await WidgetsBinding.instance.endOfFrame;
      final verified = _menuScrollPosition(scene);
      if (verified != null &&
          verified.hasContentDimensions &&
          !verified.isScrollingNotifier.value &&
          (verified.pixels - verified.maxScrollExtent).abs() <= tolerance &&
          (verified.maxScrollExtent - maxExtent).abs() <=
              stableExtentTolerance) {
        return;
      }
    }

    position = _menuScrollPosition(scene);
    throw StateError(
      '${_menuKind(scene)} did not settle at scroll end: '
      'pixels=${position?.pixels} max=${position?.maxScrollExtent}',
    );
  }

  ScrollPosition? _menuScrollPosition(String scene) {
    if (_menuKind(scene) == 'reader-settings') {
      return _settingsScrollPosition();
    }
    final anchor = switch (_menuKind(scene)) {
      'font-selection' => _findElementByKey(
        const ValueKey<String>('font-option-system'),
      ),
      'app-text-size' => _findElementByKey(
        const ValueKey<String>('app-text-size-0'),
      ),
      'reader-navigation-catalog' =>
        _findTextElement(_firstChapterTitle) ??
            _findTextElement(_lastChapterTitle),
      'reader-navigation-bookmarks' =>
        _findTextElement(_firstBookmarkTitle) ??
            _findTextElement(_lastBookmarkTitle),
      _ => null,
    };
    return anchor == null ? null : Scrollable.maybeOf(anchor)?.position;
  }

  Element? _findElementByKey(Key key) {
    Element? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget.key == key) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    (_navigator.currentContext! as Element).visitChildElements(visit);
    return result;
  }

  Element? _findTextElement(String text) {
    Element? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget case Text(data: final String data) when data == text) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    (_navigator.currentContext! as Element).visitChildElements(visit);
    return result;
  }

  Map<String, Object?> _edgeGeometry({
    required String name,
    required RenderBox boundary,
    required GlassSurface panel,
    required Rect panelRect,
  }) {
    if (_menuKind(name) != 'reader-settings') {
      return _productionMenuEdgeGeometry(
        name: name,
        boundary: boundary,
        panel: panel,
        panelRect: panelRect,
      );
    }
    Element? scrollView;
    Element? lastSlider;
    var liquidBackdropCount = 0;
    void visit(Element element) {
      if (scrollView == null && element.widget is SingleChildScrollView) {
        scrollView = element;
      }
      if (element.widget.key ==
          const ValueKey('shared-sheet-edge-last-slider')) {
        lastSlider = element;
      }
      element.visitChildElements(visit);
    }

    (_navigator.currentContext! as Element).visitChildElements(visit);
    void inspectRenderTree(RenderObject object) {
      if (object.runtimeType.toString() == '_RenderLiquidBackdrop') {
        liquidBackdropCount++;
      }
      object.visitChildren(inspectRenderTree);
    }

    inspectRenderTree(boundary);
    final scrollBox = scrollView!.findRenderObject()! as RenderBox;
    final scrollRect = _localRect(scrollBox, boundary);
    final sliderBox = lastSlider!.findRenderObject()! as RenderBox;
    final sliderRect = _localRect(sliderBox, boundary);
    final decreaseRect = _descendantKeyRect(
      lastSlider!,
      const ValueKey('glass-adjustment-decrease'),
      boundary,
    );
    final increaseRect = _descendantKeyRect(
      lastSlider!,
      const ValueKey('glass-adjustment-increase'),
      boundary,
    );
    final position = _settingsScrollPosition();
    final glassStyle = name.contains('frosted')
        ? GlassStyle.frosted
        : GlassStyle.liquid;
    final materialStyle = name.contains('solid');
    final interactiveBottoms = [
      if (decreaseRect != null) decreaseRect.bottom,
      if (increaseRect != null) increaseRect.bottom,
    ];
    final controlBottom = interactiveBottoms.isEmpty
        ? sliderRect.bottom
        : interactiveBottoms.reduce((a, b) => a > b ? a : b);
    final view = View.of(_sceneContext.currentContext!);
    final hostLogicalSize = view.physicalSize / view.devicePixelRatio;
    return {
      'menuKind': 'reader-settings',
      'logicalSize': {
        'width': boundary.size.width,
        'height': boundary.size.height,
      },
      'hostLogicalSize': {
        'width': hostLogicalSize.width,
        'height': hostLogicalSize.height,
      },
      'uiStyle': materialStyle ? 'material3' : 'glass',
      'glassStyle': glassStyle.storageValue,
      'panel': _rectJson(panelRect),
      'exterior': {
        'left': panelRect.left,
        'right': boundary.size.width - panelRect.right,
        'bottom': boundary.size.height - panelRect.bottom,
      },
      'shape': panel.shape.runtimeType.toString(),
      'radius': (panel.shape as RoundedSuperellipseBorder).borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x,
      'scrollViewport': _rectJson(scrollRect),
      'originalBodyScrollViewport': _rectJson(scrollRect),
      'scrollViewportBottom': scrollRect.bottom,
      'originalBodyScrollViewportBottom': scrollRect.bottom,
      'glassSurfaceBottom': panelRect.bottom,
      'viewportToGlassBottom': panelRect.bottom - scrollRect.bottom,
      'scrollPosition': {
        'pixels': position?.pixels,
        'maxScrollExtent': position?.maxScrollExtent,
        'atEnd': position == null
            ? false
            : (position.maxScrollExtent - position.pixels).abs() < 0.5,
      },
      'lastSlider': _rectJson(sliderRect),
      'lastSliderDecrease': decreaseRect == null
          ? null
          : _rectJson(decreaseRect),
      'lastSliderIncrease': increaseRect == null
          ? null
          : _rectJson(increaseRect),
      'lastSliderVisibleInViewport': scrollRect.overlaps(sliderRect),
      'decreaseVisibleInViewport':
          decreaseRect != null && scrollRect.overlaps(decreaseRect),
      'increaseVisibleInViewport':
          increaseRect != null && scrollRect.overlaps(increaseRect),
      'remainingSafeClearance': panelRect.bottom - controlBottom,
      'lastSliderToGlassBottom': panelRect.bottom - sliderRect.bottom,
      'decreaseToGlassBottom': decreaseRect == null
          ? null
          : panelRect.bottom - decreaseRect.bottom,
      'increaseToGlassBottom': increaseRect == null
          ? null
          : panelRect.bottom - increaseRect.bottom,
      'nativeImpeller': {
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'liquidBackdropRenderObjectCount': liquidBackdropCount,
        'shaderReady': materialStyle || glassStyle != GlassStyle.liquid
            ? null
            : ui.ImageFilter.isShaderFilterSupported && liquidBackdropCount > 0,
      },
    };
  }

  Map<String, Object?> _productionMenuEdgeGeometry({
    required String name,
    required RenderBox boundary,
    required GlassSurface panel,
    required Rect panelRect,
  }) {
    final menuKind = _menuKind(name);
    final lastLabel = switch (menuKind) {
      'font-selection' => 'font-option-jetbrains_mono',
      'app-text-size' => 'app-text-size-4',
      'reader-navigation-catalog' => _lastChapterTitle,
      'reader-navigation-bookmarks' => _lastBookmarkTitle,
      _ => throw StateError('Unsupported production menu scene: $name'),
    };
    final lastItem = switch (menuKind) {
      'font-selection' => _findElementByKey(
        const ValueKey<String>('font-option-jetbrains_mono'),
      ),
      'app-text-size' => _findElementByKey(
        const ValueKey<String>('app-text-size-4'),
      ),
      'reader-navigation-catalog' => _findTextElement(_lastChapterTitle),
      'reader-navigation-bookmarks' => _findTextElement(_lastBookmarkTitle),
      _ => null,
    };
    if (lastItem == null) {
      throw StateError('$menuKind last item is unavailable after scrolling');
    }
    final scrollable = Scrollable.maybeOf(lastItem);
    if (scrollable == null || !scrollable.position.hasContentDimensions) {
      throw StateError('$menuKind Scrollable is unavailable');
    }
    final scrollBox = scrollable.context.findRenderObject()! as RenderBox;
    final lastItemBox = lastItem.findRenderObject()! as RenderBox;
    final scrollRect = _localRect(scrollBox, boundary);
    final lastItemRect = _localRect(lastItemBox, boundary);
    var liquidBackdropCount = 0;
    void inspectRenderTree(RenderObject object) {
      if (object.runtimeType.toString() == '_RenderLiquidBackdrop') {
        liquidBackdropCount++;
      }
      object.visitChildren(inspectRenderTree);
    }

    inspectRenderTree(boundary);
    final view = View.of(_sceneContext.currentContext!);
    final hostLogicalSize = view.physicalSize / view.devicePixelRatio;
    final position = scrollable.position;
    return {
      'menuKind': menuKind,
      'logicalSize': {
        'width': boundary.size.width,
        'height': boundary.size.height,
      },
      'hostLogicalSize': {
        'width': hostLogicalSize.width,
        'height': hostLogicalSize.height,
      },
      'uiStyle': 'glass',
      'glassStyle': GlassStyle.liquid.storageValue,
      'panel': _rectJson(panelRect),
      'exterior': {
        'left': panelRect.left,
        'right': boundary.size.width - panelRect.right,
        'bottom': boundary.size.height - panelRect.bottom,
      },
      'shape': panel.shape.runtimeType.toString(),
      'radius': (panel.shape as RoundedSuperellipseBorder).borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x,
      'scrollViewport': _rectJson(scrollRect),
      'scrollViewportBottom': scrollRect.bottom,
      'glassSurfaceBottom': panelRect.bottom,
      'viewportToGlassBottom': panelRect.bottom - scrollRect.bottom,
      'scrollPosition': {
        'pixels': position.pixels,
        'maxScrollExtent': position.maxScrollExtent,
        'atEnd': (position.maxScrollExtent - position.pixels).abs() < 0.5,
      },
      'lastItem': {
        'label': lastLabel,
        'bounds': _rectJson(lastItemRect),
        'visibleInViewport': scrollRect.overlaps(lastItemRect),
        'toGlassBottom': panelRect.bottom - lastItemRect.bottom,
      },
      'remainingSafeClearance': panelRect.bottom - lastItemRect.bottom,
      'nativeImpeller': {
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'liquidBackdropRenderObjectCount': liquidBackdropCount,
        'shaderReady':
            ui.ImageFilter.isShaderFilterSupported && liquidBackdropCount > 0,
      },
    };
  }

  Rect? _descendantKeyRect(Element root, Key key, RenderBox boundary) {
    Rect? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget.key == key) {
        final box = element.findRenderObject()! as RenderBox;
        if (box.hasSize) result = _localRect(box, boundary);
        return;
      }
      element.visitChildElements(visit);
    }

    root.visitChildElements(visit);
    return result;
  }

  Rect _localRect(RenderBox box, RenderBox boundary) {
    final topLeft = boundary.globalToLocal(box.localToGlobal(Offset.zero));
    return topLeft & box.size;
  }

  Map<String, double> _rectJson(Rect rect) => {
    'left': rect.left,
    'top': rect.top,
    'width': rect.width,
    'height': rect.height,
    'right': rect.right,
    'bottom': rect.bottom,
  };

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
