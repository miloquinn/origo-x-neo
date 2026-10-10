import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';
import 'package:xxread/pages/book_sources/sourced_book_details_page.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/services/library/download_task_controller.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/generated_book_cover.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/library_book_info_sheet.dart';

const _outputFolder = 'book-details-preview';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedAppearance = _SavedAppearance.read(preferences);
  await _writeAppearance(
    preferences,
    brightness: Brightness.light,
    style: AppUiStyle.glass,
    glassStyle: GlassStyle.liquid,
  );
  final theme = ThemeNotifier();
  await theme.reloadFromPreferences();
  runApp(
    _Preview(
      theme: theme,
      preferences: preferences,
      savedAppearance: savedAppearance,
    ),
  );
}

class _SavedAppearance {
  const _SavedAppearance({
    required this.isDarkMode,
    required this.uiStyle,
    required this.glassStyle,
    required this.liquidGlassOpacity,
  });

  factory _SavedAppearance.read(SharedPreferences preferences) =>
      _SavedAppearance(
        isDarkMode: preferences.getBool('isDarkMode'),
        uiStyle: preferences.getString('ui_style_mode'),
        glassStyle: preferences.getString('glass_style_mode'),
        liquidGlassOpacity: preferences.getDouble('liquid_glass_opacity'),
      );

  final bool? isDarkMode;
  final String? uiStyle;
  final String? glassStyle;
  final double? liquidGlassOpacity;

  Future<void> restore(SharedPreferences preferences) async {
    await _restorePreference(preferences, 'isDarkMode', isDarkMode);
    await _restorePreference(preferences, 'ui_style_mode', uiStyle);
    await _restorePreference(preferences, 'glass_style_mode', glassStyle);
    await _restorePreference(
      preferences,
      'liquid_glass_opacity',
      liquidGlassOpacity,
    );
  }
}

class _PreviewScene {
  const _PreviewScene({
    required this.name,
    this.brightness = Brightness.light,
    this.style = AppUiStyle.glass,
    this.glassStyle = GlassStyle.liquid,
    this.size = const Size(390, 844),
    this.padding = const EdgeInsets.only(top: 44, bottom: 34),
    this.textScale = 1,
    this.manyTags = false,
    this.expandTags = false,
    this.localSheet = false,
    this.landscape = false,
  });

  final String name;
  final Brightness brightness;
  final AppUiStyle style;
  final GlassStyle glassStyle;
  final Size size;
  final EdgeInsets padding;
  final double textScale;
  final bool manyTags;
  final bool expandTags;
  final bool localSheet;
  final bool landscape;

  bool get isLiquid =>
      style == AppUiStyle.glass && glassStyle == GlassStyle.liquid;
}

const _scenes = <_PreviewScene>[
  _PreviewScene(name: 'online-liquid-light'),
  _PreviewScene(name: 'online-liquid-dark', brightness: Brightness.dark),
  _PreviewScene(name: 'online-frosted-light', glassStyle: GlassStyle.frosted),
  _PreviewScene(name: 'online-solid-light', style: AppUiStyle.material3),
  _PreviewScene(name: 'online-24-tags-collapsed', manyTags: true),
  _PreviewScene(
    name: 'online-24-tags-expanded',
    manyTags: true,
    expandTags: true,
  ),
  _PreviewScene(
    name: 'online-narrow-320x740-text-1.6',
    size: Size(320, 740),
    textScale: 1.6,
  ),
  _PreviewScene(
    name: 'online-landscape-844x390',
    size: Size(844, 390),
    padding: EdgeInsets.only(left: 47, right: 47, bottom: 21),
    landscape: true,
  ),
  _PreviewScene(name: 'local-info-liquid-light', localSheet: true),
  _PreviewScene(
    name: 'local-info-liquid-dark',
    brightness: Brightness.dark,
    localSheet: true,
  ),
];

class _Preview extends StatefulWidget {
  const _Preview({
    required this.theme,
    required this.preferences,
    required this.savedAppearance,
  });

  final ThemeNotifier theme;
  final SharedPreferences preferences;
  final _SavedAppearance savedAppearance;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  var _navigator = GlobalKey<NavigatorState>();
  var _sceneContext = GlobalKey();
  final _gateway = _PreviewGateway();
  final _shelf = _PreviewShelfService();
  final _downloads = DownloadTaskController();
  final _geometry = <String, Object?>{};
  var _sceneIndex = 0;

  _PreviewScene get _scene => _scenes[_sceneIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        _capture().catchError((Object error, StackTrace stack) {
          debugPrint(
            'BOOK_DETAILS_PREVIEW_FAILED scene=${_scene.name} '
            'error=$error\n$stack',
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    widget.theme.dispose();
    _downloads.dispose();
    _shelf.close();
    _gateway.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return ColoredBox(
      color: const Color(0xFF111419),
      child: Center(
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: RepaintBoundary(
            key: _boundary,
            child: SizedBox.fromSize(
              size: scene.size,
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider<ThemeNotifier>.value(
                    value: widget.theme,
                  ),
                  ChangeNotifierProvider<DownloadTaskController>.value(
                    value: _downloads,
                  ),
                ],
                child: Consumer<ThemeNotifier>(
                  builder: (context, theme, _) => MaterialApp(
                    key: ValueKey(scene.name),
                    navigatorKey: _navigator,
                    debugShowCheckedModeBanner: false,
                    locale: const Locale('zh'),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    theme: _themeData(theme, Brightness.light),
                    darkTheme: _themeData(theme, Brightness.dark),
                    themeMode: theme.themeMode,
                    scrollBehavior: const MaterialScrollBehavior().copyWith(
                      physics: const BouncingScrollPhysics(),
                    ),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: scene.size,
                        padding: scene.padding,
                        viewPadding: scene.padding,
                        viewInsets: EdgeInsets.zero,
                        textScaler: TextScaler.linear(scene.textScale),
                      ),
                      child: child!,
                    ),
                    home: Builder(
                      key: _sceneContext,
                      builder: (_) => SourcedBookDetailsPage(
                        result: SourcedBook(
                          source: _source,
                          book: scene.manyTags ? _manyTagsBook : _onlineBook,
                        ),
                        gateway: _gateway
                          ..book = scene.manyTags ? _manyTagsBook : _onlineBook,
                        shelfService: _shelf,
                        onRead: (_, _) async {},
                        onDownloadContinuesInBackground: () {},
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

  ThemeData _themeData(ThemeNotifier theme, Brightness brightness) {
    final scheme = brightness == Brightness.dark
        ? theme.currentAppTheme.darkColorScheme
        : theme.currentAppTheme.lightColorScheme;
    final solid = theme.uiStyle == AppUiStyle.material3;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: solid
          ? scheme.surfaceContainerLow
          : scheme.surface.withValues(
              alpha: brightness == Brightness.dark ? 0.82 : 0.9,
            ),
      dialogTheme: DialogThemeData(
        backgroundColor: solid
            ? scheme.surfaceContainerHigh
            : scheme.surface.withValues(
                alpha: brightness == Brightness.dark ? 0.9 : 0.96,
              ),
      ),
      fontFamilyFallback: FontCatalog.appFallbacks(null),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: solid ? scheme.surface : Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: solid ? 0.32 : 0.18),
        thickness: 0.7,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSkinTheme(skin: theme.currentSkin),
        UiStyleThemeExtension(
          style: theme.uiStyle,
          glassStyle: theme.glassStyle,
          liquidGlassOpacity: theme.liquidGlassOpacity,
        ),
      ],
    );
  }

  Future<void> _capture() async {
    final output = Directory('${Directory.systemTemp.path}/$_outputFolder');
    await output.create(recursive: true);
    for (var index = 0; index < _scenes.length; index++) {
      if (!mounted) return;
      final scene = _scenes[index];
      await SystemChrome.setPreferredOrientations([
        scene.landscape
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _writeAppearance(
        widget.preferences,
        brightness: scene.brightness,
        style: scene.style,
        glassStyle: scene.glassStyle,
      );
      await widget.theme.reloadFromPreferences();
      if (!mounted) return;
      setState(() {
        _sceneIndex = index;
        _navigator = GlobalKey<NavigatorState>();
        _sceneContext = GlobalKey();
      });
      await _settle(scene.isLiquid ? 12 : 5);

      if (scene.localSheet) {
        _showLocalBookSheet();
        await _settle(scene.isLiquid ? 12 : 7);
      }
      if (scene.expandTags) {
        _pressButtonByKey(const ValueKey('book-details-tags-toggle'));
        await _settle(8);
        final expanded = _measure(scene);
        if (!(expanded['tagVisibleLabels']! as List<String>).contains(
          '分类标签 24',
        )) {
          throw StateError(
            'The production tag expansion did not reveal tag 24',
          );
        }
      }

      _geometry[scene.name] = _measure(scene);
      await _snapshot(output, scene.name);
      if (scene.localSheet && _navigator.currentState?.canPop() == true) {
        _navigator.currentState!.pop();
        await _settle(5);
      }
    }
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final liquidEntries = _geometry.entries
        .where((entry) {
          final scene = _scenes.firstWhere((item) => item.name == entry.key);
          return scene.isLiquid;
        })
        .map((entry) => entry.value as Map<String, Object?>)
        .toList(growable: false);
    final allLiquidShadersReady = liquidEntries.every(
      (entry) =>
          (entry['nativeImpeller'] as Map<String, Object?>)['shaderReady'] ==
          true,
    );
    final context = <String, Object?>{
      'platform': Platform.operatingSystem,
      'nativeRenderer': 'iOS Impeller shader-filter path',
      'simulatorViewport':
          (_geometry[_scenes.first.name]!
              as Map<String, Object?>)['hostLogicalSize'],
      'capturePixelRatio': 2,
      'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
      'shaderReady': allLiquidShadersReady,
      'outputDirectory': output.path,
      'scenes': _scenes.map((scene) => scene.name).toList(growable: false),
      'kind':
          'native production SourcedBookDetailsPage and LibraryBookInfoSheet routes',
      'themeContract': const {
        'provider': 'ThemeNotifier',
        'storage': 'SharedPreferences',
        'uiStyleKey': 'ui_style_mode',
        'glassStyleKey': 'glass_style_mode',
      },
      'geometry': _geometry,
    };
    await File(
      '${output.path}/render-context.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(context));
    await widget.savedAppearance.restore(widget.preferences);
    debugPrint(
      'BOOK_DETAILS_PREVIEW_COMPLETE directory=${output.path} '
      'context=${output.path}/render-context.json '
      'shaderReady=$allLiquidShadersReady',
    );
  }

  void _showLocalBookSheet() {
    final context = _sceneContext.currentContext!;
    unawaited(
      showGlassBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        builder: (_) => LibraryBookInfoSheet(
          book: _localBook,
          cover: const GeneratedBookCover(title: '潮汐与群山', author: '顾远舟'),
          sourceBook: _localSourceBook,
          sourceLabel: '本地书库 · EPUB',
        ),
      ),
    );
  }

  Future<void> _settle(int frames) async {
    for (var frame = 0; frame < frames; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  void _pressButtonByKey(Key key) {
    final element = _findElement(key);
    if (element?.widget case final ButtonStyleButton button
        when button.onPressed != null) {
      button.onPressed!();
    } else {
      throw StateError('Preview target is missing: $key');
    }
  }

  Future<void> _snapshot(Directory output, String name) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed for $name');
      await File(
        '${output.path}/$name.png',
      ).writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  Map<String, Object?> _measure(_PreviewScene scene) {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final tagsElement = _findElement(const ValueKey('book-details-tags'));
    final tagRects = <({String label, Rect rect})>[];
    if (tagsElement != null) {
      void collect(Element element) {
        final widget = element.widget;
        if (widget is Tooltip) {
          final renderObject = element.renderObject;
          if (renderObject is RenderBox && renderObject.hasSize) {
            tagRects.add((
              label: widget.message ?? '',
              rect: _rect(renderObject, boundary),
            ));
          }
        }
        element.visitChildElements(collect);
      }

      tagsElement.visitChildElements(collect);
    }

    final panelRects = <Rect>[];
    void collectPanels(Element element) {
      if (element.widget case GlassSurface(role: GlassSurfaceRole.panel)) {
        if (element.renderObject case final RenderBox box when box.hasSize) {
          panelRects.add(_rect(box, boundary));
        }
      }
      element.visitChildElements(collectPanels);
    }

    (_boundary.currentContext! as Element).visitChildElements(collectPanels);
    panelRects.sort(
      (a, b) => (b.width * b.height).compareTo(a.width * a.height),
    );

    var liquidBackdropCount = 0;
    void inspectRenderTree(RenderObject object) {
      if (object.runtimeType.toString() == '_RenderLiquidBackdrop') {
        liquidBackdropCount++;
      }
      object.visitChildren(inspectRenderTree);
    }

    inspectRenderTree(boundary);
    final media = MediaQuery.of(_sceneContext.currentContext!);
    final view = View.of(_sceneContext.currentContext!);
    final hostLogicalSize = view.physicalSize / view.devicePixelRatio;
    final rowTops = <double>[];
    for (final item in tagRects) {
      if (!rowTops.any((top) => (top - item.rect.top).abs() < 2)) {
        rowTops.add(item.rect.top);
      }
    }
    rowTops.sort();
    return <String, Object?>{
      'logicalSize': {'width': scene.size.width, 'height': scene.size.height},
      'hostLogicalSize': {
        'width': hostLogicalSize.width,
        'height': hostLogicalSize.height,
      },
      'brightness': scene.brightness.name,
      'uiStyle': scene.style.storageValue,
      'glassStyle': scene.glassStyle.storageValue,
      'textScale': scene.textScale,
      'safeArea': {
        'left': media.padding.left,
        'top': media.padding.top,
        'right': media.padding.right,
        'bottom': media.padding.bottom,
      },
      'cover': _keyRect(const ValueKey('book-details-cover'), boundary),
      'title': _keyRect(const ValueKey('book-details-title'), boundary),
      'tags': _keyRect(const ValueKey('book-details-tags'), boundary),
      'tagDistinctRowCount': rowTops.length,
      'tagVisibleLabels': tagRects.map((item) => item.label).toList(),
      'tagToggle': _keyRect(
        const ValueKey('book-details-tags-toggle'),
        boundary,
      ),
      'readButton': _keyRect(const Key('bookSourceReadButton'), boundary),
      'scrollViewport': _keyRect(
        const Key('bookSourceDetailsScroll'),
        boundary,
      ),
      'floatingActions': _keyRect(
        const Key('bookSourceFloatingActions'),
        boundary,
      ),
      'readButtonHasGlassAncestor':
          _findElement(
            const Key('bookSourceReadButton'),
          )?.findAncestorWidgetOfExactType<GlassSurface>() !=
          null,
      'sheetScroll': _keyRect(const Key('library-book-info-scroll'), boundary),
      'sheetPanel': panelRects.isEmpty ? null : _rectJson(panelRects.first),
      'panelCount': panelRects.length,
      'nativeImpeller': {
        'platform': Platform.operatingSystem,
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'liquidBackdropRenderObjectCount': liquidBackdropCount,
        'shaderReady': scene.isLiquid
            ? ui.ImageFilter.isShaderFilterSupported && liquidBackdropCount > 0
            : null,
        'evidence':
            'A native _RenderLiquidBackdrop exists only after the production fragment shader has loaded.',
      },
    };
  }

  Element? _findElement(Key key) {
    Element? result;
    void visit(Element element) {
      if (result != null) return;
      if (element.widget.key == key) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(_boundary.currentContext! as Element);
    return result;
  }

  Map<String, double>? _keyRect(Key key, RenderBox boundary) {
    final element = _findElement(key);
    if (element?.renderObject case final RenderBox box when box.hasSize) {
      return _rectJson(_rect(box, boundary));
    }
    return null;
  }

  Rect _rect(RenderBox box, RenderBox boundary) {
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
}

Future<void> _writeAppearance(
  SharedPreferences preferences, {
  required Brightness brightness,
  required AppUiStyle style,
  required GlassStyle glassStyle,
}) async {
  await preferences.setBool('isDarkMode', brightness == Brightness.dark);
  await preferences.setString('ui_style_mode', style.storageValue);
  await preferences.setString('glass_style_mode', glassStyle.storageValue);
  await preferences.setDouble('liquid_glass_opacity', 0.5);
  GlassEffectConfig.setDisableAllGlassEffects(style == AppUiStyle.material3);
  GlassEffectConfig.setGlassStyle(glassStyle);
  GlassEffectConfig.setLiquidGlassOpacity(0.5);
}

Future<void> _restorePreference(
  SharedPreferences preferences,
  String key,
  Object? value,
) async {
  if (value == null) {
    await preferences.remove(key);
  } else if (value is bool) {
    await preferences.setBool(key, value);
  } else if (value is String) {
    await preferences.setString(key, value);
  } else if (value is double) {
    await preferences.setDouble(key, value);
  }
}

final _source = RegisteredBookSource(
  id: 'book-details-preview-source',
  name: '山海书屋',
  description: '仅用于本机原生视觉验收',
  manifestUrl: Uri.parse('https://preview.invalid/source.json'),
  apiBaseUrl: Uri.parse('https://preview.invalid/api/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: const {'search'},
  enabled: true,
  addedAt: DateTime.utc(2026, 10, 10),
);

const _onlineBook = BookSourceBook(
  id: 'book-details-preview-online',
  title: '山海之间',
  author: '林间客',
  description:
      '一封来自故乡的信，让远行多年的游子重新踏上归途。\n\n'
      '沿着旧时的山路，他走过晨雾中的村落、海边的灯塔，也慢慢找回那些被岁月遗忘的名字。'
      '这是关于相遇、告别与重新出发的故事。',
  categories: ['文学', '旅行', '成长', '治愈'],
  status: '连载中',
  latestChapter: '第二十四章 · 风从海上来',
);

final _manyTagsBook = BookSourceBook(
  id: 'book-details-preview-many-tags',
  title: '山海之间',
  author: '林间客',
  description: _onlineBook.description,
  categories: List<String>.generate(24, (index) => '分类标签 ${index + 1}'),
  latestChapter: _onlineBook.latestChapter,
);

final _localBook = Book(
  id: 702,
  title: '潮汐与群山',
  author: '顾远舟',
  filePath: '/preview/潮汐与群山.epub',
  format: 'epub',
  currentPage: 186,
  totalPages: 428,
  readingProgress: 0.435,
  importDate: DateTime.utc(2026, 10, 10),
);

const _localSourceBook = BookSourceBook(
  id: 'book-details-preview-local',
  title: '潮汐与群山',
  author: '顾远舟',
  description: '一本保存在本地书库的旅行随笔。作者沿海岸线北上，在潮汐、旧城与山脉之间记录普通人的生活。',
  status: '已完结',
  categories: ['随笔', '自然', '旅行', '摄影'],
);

class _PreviewGateway extends BookSourceClient {
  BookSourceBook book = _onlineBook;

  @override
  Future<BookSourceBook> getBook(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async => book;
}

class _PreviewShelfService extends BookSourceShelfService {
  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) async => null;
}
