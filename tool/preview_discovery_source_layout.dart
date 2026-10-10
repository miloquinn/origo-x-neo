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
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/book_sources/source_engine/source_explore.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/book_sources_page.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_surface.dart';

// Native renderer fixture for the production discovery source layout.
// It uses only the in-memory registry/client below and never reads or writes
// the user's real book sources, account, shelf or device installation.
//
// flutter run -d <simulator> -t tool/preview_discovery_source_layout.dart --no-pub
const _outputFolder = 'discovery-source-layout-preview';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final savedAppearance = _SavedAppearance.read(preferences);
  final savedLayout = preferences.getString(
    BookSourcesPageController.preferenceKey,
  );
  await _writeAppearance(preferences, Brightness.light);
  await preferences.setString(
    BookSourcesPageController.preferenceKey,
    BookSourceDiscoverLayout.source.name,
  );
  final theme = ThemeNotifier();
  await theme.reloadFromPreferences();
  runApp(
    _Preview(
      theme: theme,
      preferences: preferences,
      savedAppearance: savedAppearance,
      savedLayout: savedLayout,
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

class _Scene {
  const _Scene({
    required this.name,
    this.brightness = Brightness.light,
    this.size = const Size(390, 844),
    this.textScale = 1,
    this.keyboardInset = 0,
  });

  final String name;
  final Brightness brightness;
  final Size size;
  final double textScale;
  final double keyboardInset;
}

const _mainLight = _Scene(name: 'main-liquid-light');
const _mainDark = _Scene(name: 'main-liquid-dark', brightness: Brightness.dark);
const _mainNarrow = _Scene(
  name: 'main-narrow-320x740-text-1.6',
  size: Size(320, 740),
  textScale: 1.6,
);
const _legadoMain = _Scene(name: 'main-legado-categories-only');
const _sourceMenu = _Scene(name: 'source-menu-liquid-light');
const _sourceFiltered = _Scene(name: 'source-menu-search-filtered');
const _sourceKeyboard = _Scene(
  name: 'source-menu-narrow-320x740-text-1.6-keyboard-inset',
  size: Size(320, 740),
  textScale: 1.6,
  keyboardInset: 264,
);
const _categoryMenu = _Scene(name: 'category-menu-liquid-light');
const _categoryEnd = _Scene(name: 'category-menu-list-end');
const _categoryKeyboard = _Scene(
  name: 'category-menu-narrow-320x740-text-1.6-keyboard-inset',
  size: Size(320, 740),
  textScale: 1.6,
  keyboardInset: 264,
);

class _Preview extends StatefulWidget {
  const _Preview({
    required this.theme,
    required this.preferences,
    required this.savedAppearance,
    required this.savedLayout,
  });

  final ThemeNotifier theme;
  final SharedPreferences preferences;
  final _SavedAppearance savedAppearance;
  final String? savedLayout;

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _pageContext = GlobalKey();
  final _registry = _PreviewRegistry();
  final _client = _PreviewClient();
  final _shelf = _PreviewShelfService();
  final _geometry = <String, Object?>{};
  var _navigator = GlobalKey<NavigatorState>();
  final _controller = BookSourcesPageController();
  var _scene = _mainLight;

  @override
  void initState() {
    super.initState();
    _controller.layout.value = BookSourceDiscoverLayout.source;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        _capture().catchError((Object error, StackTrace stack) {
          debugPrint('DISCOVERY_SOURCE_PREVIEW_FAILED error=$error\n$stack');
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _client.close();
    _shelf.close();
    widget.theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              size: _scene.size,
              child: ChangeNotifierProvider<ThemeNotifier>.value(
                value: widget.theme,
                child: Consumer<ThemeNotifier>(
                  builder: (context, theme, _) => MaterialApp(
                    key: ValueKey(
                      '${_scene.name}-${_scene.brightness.name}-${_scene.size}',
                    ),
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
                    builder: (context, child) {
                      const safeArea = EdgeInsets.only(top: 44, bottom: 34);
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: _scene.size,
                          padding: safeArea.copyWith(
                            bottom: _scene.keyboardInset > 0 ? 0 : 34,
                          ),
                          viewPadding: safeArea,
                          viewInsets: EdgeInsets.only(
                            bottom: _scene.keyboardInset,
                          ),
                          textScaler: TextScaler.linear(_scene.textScale),
                        ),
                        child: child!,
                      );
                    },
                    home: Builder(
                      key: _pageContext,
                      builder: (context) {
                        final media = MediaQuery.of(context);
                        final chrome = HomeMobileChromeMetrics(
                          systemTopInset: media.viewPadding.top,
                          systemBottomInset: media.viewPadding.bottom,
                          floatingNavHeight: 0,
                          floatingNavBottomGap: 0,
                          keyboardVisible: media.viewInsets.bottom > 0,
                        );
                        return Scaffold(
                          key: const Key('discoverySourcePreviewScaffold'),
                          extendBody: true,
                          resizeToAvoidBottomInset: false,
                          body: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: PageStyleHelper.backgroundGradient(
                                context,
                              ),
                            ),
                            child: HomeMobileChromeScope(
                              metrics: chrome,
                              child: Stack(
                                children: [
                                  BookSourcesPage(
                                    key: ValueKey('page-${_scene.name}'),
                                    client: _client,
                                    shelfService: _shelf,
                                    controller: _controller,
                                    registry: _registry,
                                  ),
                                  Positioned(
                                    left: 18,
                                    top: media.viewPadding.top + 8,
                                    child: Text(
                                      '发现',
                                      key: const Key(
                                        'discoverySourcePreviewTitle',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
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
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: scheme.surface.withValues(
        alpha: brightness == Brightness.dark ? 0.82 : 0.9,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface.withValues(
          alpha: brightness == Brightness.dark ? 0.9 : 0.96,
        ),
      ),
      fontFamilyFallback: FontCatalog.appFallbacks(null),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.18),
        thickness: 0.7,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppSkinTheme(skin: theme.currentSkin),
        UiStyleThemeExtension(
          style: AppUiStyle.glass,
          glassStyle: GlassStyle.liquid,
          liquidGlassOpacity: theme.liquidGlassOpacity,
        ),
      ],
    );
  }

  Future<void> _capture() async {
    final output = Directory('${Directory.systemTemp.path}/$_outputFolder');
    await output.create(recursive: true);
    final readingCatalog = parseSourceExploreCatalog(
      _readingSource().sourceConfig!,
    );
    if (!readingCatalog.canBrowse) {
      throw StateError(
        'Reading source explore catalog is invalid: ${readingCatalog.error}',
      );
    }

    await _showScene(_mainLight);
    await _captureScene(output, _mainLight, kind: 'main');
    await _showScene(_mainDark);
    await _captureScene(output, _mainDark, kind: 'main');
    await _showScene(_mainNarrow);
    await _captureScene(output, _mainNarrow, kind: 'main');

    await _showScene(_legadoMain);
    _pressByKey(const Key('bookSourceDiscoverySourceSelector'));
    await _settle(8);
    _pressByKey(const Key('bookSourceDiscoveryPick-$_readingSourceId'));
    await _settle(10);
    _assertLegadoMain();
    await _captureScene(output, _legadoMain, kind: 'legado-main');

    _pressByKey(const Key('bookSourceDiscoverySourceSelector'));
    await _settle(8);
    _pressByKey(const Key('bookSourceDiscoveryPick-preview-mountain'));
    await _settle(8);

    await _showScene(_sourceMenu);
    _pressByKey(const Key('bookSourceDiscoverySourceSelector'));
    await _settle(10);
    await _captureScene(output, _sourceMenu, kind: 'source-menu');

    _setTextField(const Key('bookSourceDiscoverySourceSearch'), '星河');
    await _settle(6);
    await _captureScene(output, _sourceFiltered, kind: 'source-menu');
    _navigator.currentState!.pop();
    await _settle(5);

    await _showScene(_categoryMenu);
    _pressByKey(const Key('bookSourceCategoryPickerButton'));
    await _settle(10);
    await _captureScene(output, _categoryMenu, kind: 'category-menu');

    _scrollListToEnd(const Key('bookSourceCategoryLazyList'));
    await _settle(6);
    await _captureScene(output, _categoryEnd, kind: 'category-menu');
    _navigator.currentState!.pop();
    await _settle(5);

    await _showScene(_sourceKeyboard);
    _pressByKey(const Key('bookSourceDiscoverySourceSelector'));
    await _settle(8);
    _setTextField(const Key('bookSourceDiscoverySourceSearch'), '古典');
    await _settle(5);
    await _captureScene(output, _sourceKeyboard, kind: 'source-menu');
    _navigator.currentState!.pop();
    await _settle(5);

    await _showScene(_categoryKeyboard);
    _pressByKey(const Key('bookSourceCategoryPickerButton'));
    await _settle(8);
    _focusTextField(const Key('bookSourceCategorySearchField'));
    await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    await _settle(8);
    await _captureScene(output, _categoryKeyboard, kind: 'category-menu');

    final entries = _geometry.values.cast<Map<String, Object?>>();
    final liquidEntries = entries.where((entry) => entry['brightness'] != null);
    final shaderReady = liquidEntries.every(
      (entry) =>
          (entry['nativeImpeller'] as Map<String, Object?>)['shaderReady'] ==
          true,
    );
    final context = <String, Object?>{
      'platform': Platform.operatingSystem,
      'nativeRenderer': 'iOS Impeller shader-filter path',
      'capturePixelRatio': 2,
      'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
      'shaderReady': shaderReady,
      'outputDirectory': output.path,
      'kind':
          'production BookSourcesPage source layout and shared glass bottom sheets',
      'dataBoundary':
          'in-memory custom BookSourceRegistry, BookSourceClient and shelf stub',
      'readingSourceExploreCatalog': {
        'valid': readingCatalog.canBrowse,
        'entries': readingCatalog.entries
            .map((entry) => entry.title)
            .toList(growable: false),
      },
      'scenes': _geometry.keys.toList(growable: false),
      'geometry': _geometry,
    };
    await File(
      '${output.path}/render-context.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(context));

    await widget.savedAppearance.restore(widget.preferences);
    if (widget.savedLayout == null) {
      await widget.preferences.remove(BookSourcesPageController.preferenceKey);
    } else {
      await widget.preferences.setString(
        BookSourcesPageController.preferenceKey,
        widget.savedLayout!,
      );
    }
    debugPrint(
      'DISCOVERY_SOURCE_PREVIEWS_COMPLETE directory=${output.path} '
      'context=${output.path}/render-context.json shaderReady=$shaderReady '
      'keyboardScene=${_categoryKeyboard.name}',
    );
  }

  Future<void> _showScene(_Scene scene) async {
    if (_navigator.currentState?.canPop() == true) {
      _navigator.currentState!.popUntil((route) => route.isFirst);
      await _settle(4);
    }
    await _writeAppearance(widget.preferences, scene.brightness);
    await widget.theme.reloadFromPreferences();
    if (!mounted) return;
    setState(() {
      _scene = scene;
      _navigator = GlobalKey<NavigatorState>();
    });
    await _settle(14);
    if (_findElement(const Key('bookSourceDiscoverySourceSelector')) == null) {
      throw StateError('Source layout did not become ready for ${scene.name}');
    }
  }

  Future<void> _captureScene(
    Directory output,
    _Scene scene, {
    required String kind,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    final measurement = _measure(scene, kind);
    if (kind == 'source-menu' || kind == 'category-menu') {
      final scrollbarKey = kind == 'source-menu'
          ? 'sourceScrollbar'
          : 'categoryScrollbar';
      if (measurement[scrollbarKey] == null) {
        throw StateError('$kind persistent scrollbar is missing');
      }
      if (measurement['closeButtonCount'] != 0) {
        throw StateError('$kind unexpectedly shows a close button');
      }
      final searchKey = kind == 'source-menu'
          ? 'sourceSearch'
          : 'categorySearch';
      if (measurement[searchKey] == null) {
        throw StateError('$kind inline search field is missing');
      }
    }
    _geometry[scene.name] = measurement;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding failed: ${scene.name}');
      await File(
        '${output.path}/${scene.name}.png',
      ).writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }

  Map<String, Object?> _measure(_Scene scene, String kind) {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final panels = <Rect>[];
    var liquidBackdropCount = 0;
    void inspectElement(Element element) {
      if (element.widget case GlassSurface(role: GlassSurfaceRole.panel)) {
        if (element.renderObject case final RenderBox box when box.hasSize) {
          panels.add(_rect(box, boundary));
        }
      }
      element.visitChildElements(inspectElement);
    }

    void inspectRenderTree(RenderObject object) {
      if (object.runtimeType.toString() == '_RenderLiquidBackdrop') {
        liquidBackdropCount++;
      }
      object.visitChildren(inspectRenderTree);
    }

    inspectElement(_boundary.currentContext! as Element);
    inspectRenderTree(boundary);
    panels.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
    final largestPanel = panels.isEmpty ? null : panels.first;
    final viewport = _keyRect(
      const Key('bookSourceDiscoverScrollView'),
      boundary,
    );
    final pageBottomGap = viewport == null
        ? null
        : scene.size.height - (viewport['bottom'] ?? scene.size.height);
    final sheetBottomGap = largestPanel == null
        ? null
        : scene.size.height - largestPanel.bottom;
    final sectionTrack = _keyRect(
      const Key('bookSourceSectionTrackSurface'),
      boundary,
    );
    final categoryStrip = _keyRect(
      const Key('bookSourceDiscoveryChannels'),
      boundary,
    );
    final categoryPickerButton = _keyRect(
      const Key('bookSourceCategoryPickerButton'),
      boundary,
    );
    return <String, Object?>{
      'kind': kind,
      'logicalSize': {'width': scene.size.width, 'height': scene.size.height},
      'brightness': scene.brightness.name,
      'textScale': scene.textScale,
      'keyboardInset': scene.keyboardInset,
      'sourceSelector': _keyRect(
        const Key('bookSourceDiscoverySourceSelector'),
        boundary,
      ),
      'categoryStrip': categoryStrip,
      'categoryPickerButton': categoryPickerButton,
      'sectionTrack': sectionTrack,
      'sectionTrackPresent': sectionTrack != null,
      'categoryControlsPresent':
          categoryStrip != null && categoryPickerButton != null,
      'readingSourceLabelVisible': _visibleTextContaining('旧梦书源').isNotEmpty,
      'sourceSearch': _keyRect(
        const Key('bookSourceDiscoverySourceSearch'),
        boundary,
      ),
      'sourceList': _keyRect(
        const Key('bookSourceDiscoverySourceList'),
        boundary,
      ),
      'sourceScrollbar': _keyRect(
        const Key('bookSourceDiscoverySourceScrollbar'),
        boundary,
      ),
      'categorySearch': _keyRect(
        const Key('bookSourceCategorySearchField'),
        boundary,
      ),
      'categoryTitle': _keyRect(
        const Key('bookSourceCategoryPickerTitle'),
        boundary,
      ),
      'categoryList': _keyRect(
        const Key('bookSourceCategoryLazyList'),
        boundary,
      ),
      'categoryScrollbar': _keyRect(
        const Key('bookSourceCategoryScrollbar'),
        boundary,
      ),
      'closeButtonCount': _visibleIconButtonCount(Icons.close_rounded),
      'scrollViewport': viewport,
      'viewportToBottom': pageBottomGap,
      'sheetPanel': largestPanel == null ? null : _rectJson(largestPanel),
      'sheetPanelToBottom': sheetBottomGap,
      'panelCount': panels.length,
      'visibleSourceNames': _visibleTextContaining('书屋'),
      'nativeImpeller': {
        'shaderFilterSupported': ui.ImageFilter.isShaderFilterSupported,
        'liquidBackdropRenderObjectCount': liquidBackdropCount,
        'shaderReady':
            ui.ImageFilter.isShaderFilterSupported && liquidBackdropCount > 0,
      },
    };
  }

  void _assertLegadoMain() {
    if (_visibleTextContaining('旧梦书源').isEmpty) {
      throw StateError('Reading source was not selected for Legado preview');
    }
    if (_findElement(const Key('bookSourceSectionTrackSurface')) != null) {
      throw StateError('Section track must be absent for a reading source');
    }
    if (_findElement(const Key('bookSourceDiscoveryChannels')) == null ||
        _findElement(const Key('bookSourceCategoryPickerButton')) == null) {
      throw StateError('Reading source category controls are missing');
    }
  }

  List<String> _visibleTextContaining(String fragment) {
    final values = <String>[];
    void visit(Element element) {
      if (element.widget case Text(
        data: final value?,
      ) when value.contains(fragment)) {
        if (element.renderObject case final RenderBox box
            when box.hasSize && box.attached) {
          values.add(value);
        }
      }
      element.visitChildElements(visit);
    }

    visit(_boundary.currentContext! as Element);
    return values;
  }

  int _visibleIconButtonCount(IconData icon) {
    var count = 0;
    void visit(Element element) {
      if (element.widget case IconButton(
        icon: Icon(icon: final value),
      ) when value == icon) {
        if (element.renderObject case final RenderBox box
            when box.hasSize && box.attached) {
          count++;
        }
      }
      element.visitChildElements(visit);
    }

    visit(_boundary.currentContext! as Element);
    return count;
  }

  void _pressByKey(Key key) {
    final target = _findElement(key);
    if (target == null) throw StateError('Preview target is missing: $key');
    VoidCallback? callback;
    void visit(Element element) {
      if (callback != null) return;
      switch (element.widget) {
        case ButtonStyleButton(onPressed: final action?):
          callback = action;
        case IconButton(onPressed: final action?):
          callback = action;
        case ListTile(onTap: final action?):
          callback = action;
        case InkWell(onTap: final action?):
          callback = action;
        default:
          element.visitChildElements(visit);
      }
    }

    visit(target);
    if (callback == null) throw StateError('No enabled action below $key');
    callback!();
  }

  void _setTextField(Key key, String value) {
    final element = _findElement(key);
    if (element?.widget case final TextField field) {
      field.controller!.text = value;
      field.onChanged?.call(value);
      return;
    }
    throw StateError('Text field is missing: $key');
  }

  void _focusTextField(Key key) {
    final element = _findElement(key);
    if (element?.widget case final TextField field) {
      field.focusNode?.requestFocus();
      return;
    }
    throw StateError('Text field is missing: $key');
  }

  void _scrollListToEnd(Key key) {
    final target = _findElement(key);
    if (target == null) throw StateError('List is missing: $key');
    ScrollableState? scrollable;
    void visit(Element element) {
      if (scrollable != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        scrollable = element.state as ScrollableState;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(target);
    final position = scrollable?.position;
    if (position == null) throw StateError('Scrollable is missing below $key');
    position.jumpTo(position.maxScrollExtent);
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

  Future<void> _settle(int frames) async {
    for (var frame = 0; frame < frames; frame++) {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }
}

Future<void> _writeAppearance(
  SharedPreferences preferences,
  Brightness brightness,
) async {
  await preferences.setBool('isDarkMode', brightness == Brightness.dark);
  await preferences.setString('ui_style_mode', AppUiStyle.glass.storageValue);
  await preferences.setString(
    'glass_style_mode',
    GlassStyle.liquid.storageValue,
  );
  await preferences.setDouble('liquid_glass_opacity', 0.5);
  GlassEffectConfig.setDisableAllGlassEffects(false);
  GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
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

class _PreviewRegistry extends BookSourceRegistry {
  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<String>> loadGroups() async => const ['精选', '古典'];

  @override
  Future<List<RegisteredBookSource>> loadRunnableInBackground() async =>
      _sources;
}

class _PreviewClient extends BookSourceClient {
  @override
  Future<BookSourceDiscoveryPage> getDiscovery(
    RegisteredBookSource source, {
    void Function(BookSourceDiscoveryPage)? onCached,
  }) async => BookSourceDiscoveryPage(
    sections: [
      BookSourceDiscoverySection(
        id: '${source.id}-featured',
        title: '${source.name}精选',
        items: _books(source.id).take(6).toList(growable: false),
      ),
    ],
  );

  @override
  Future<List<BookSourceCategory>> getCategories(
    RegisteredBookSource source, {
    void Function(List<BookSourceCategory>)? onCached,
  }) async => List.generate(
    24,
    (index) => BookSourceCategory(
      id: '${source.id}-category-${index + 1}',
      name: _categoryNames[index % _categoryNames.length],
    ),
  );

  @override
  Future<BookSourceSearchPage> browse(
    RegisteredBookSource source, {
    String? category,
    String sort = 'latest',
    int page = 1,
    int pageSize = 20,
    void Function(BookSourceSearchPage)? onCached,
  }) async => BookSourceSearchPage(
    items: _books('${source.id}-${category ?? 'all'}'),
    page: page,
    pageSize: pageSize,
    total: 8,
    hasMore: false,
  );
}

class _PreviewShelfService extends BookSourceShelfService {
  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) async => null;
}

final _sources = <RegisteredBookSource>[
  _source('mountain', '山海书屋', '仙侠 · 玄幻 · 都市', const ['精选']),
  _readingSource(),
  _source('stars', '星河书屋', '科幻与未来世界', const ['精选']),
  _source('classic', '古典长篇书屋', '古典文学与历史演义', const ['古典']),
  _source('ink', '墨香阅读', '出版文学与人文社科', const ['古典']),
  _source('rain', '听雨小说', '悬疑 · 推理 · 社会派', const ['精选']),
  _source('harbor', '灯塔书库', '旅行、随笔与治愈故事', const ['精选']),
  _source('forest', '林间故事集', '童话与短篇小说', const ['古典']),
  _source('long', '名字很长但仍需保持单行稳定的演示书源', '排版压力测试', const ['精选']),
];

const _readingSourceId = 'preview-legado';

RegisteredBookSource _readingSource() => RegisteredBookSource(
  id: _readingSourceId,
  name: '旧梦书源',
  description: '阅读源探索目录演示',
  manifestUrl: Uri.parse('https://legado.preview.invalid/source.json'),
  apiBaseUrl: Uri.parse('https://legado.preview.invalid/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: const {'search', 'discover', 'categories', 'browse'},
  enabled: true,
  groups: const ['古典'],
  addedAt: DateTime.utc(2026, 10, 10),
  sourceProtocol: BookSourceProtocolKind.readingSource,
  sourceConfig: const {
    'bookSourceName': '旧梦书源',
    'bookSourceUrl': 'https://legado.preview.invalid/',
    'exploreUrl':
        '古典文学::https://legado.preview.invalid/explore/classics\n'
        '现代文学::https://legado.preview.invalid/explore/modern',
    'ruleExplore': {'bookList': '.book-item'},
  },
);

RegisteredBookSource _source(
  String id,
  String name,
  String description,
  List<String> groups,
) => RegisteredBookSource(
  id: 'preview-$id',
  name: name,
  description: description,
  manifestUrl: Uri.parse('https://$id.preview.invalid/source.json'),
  apiBaseUrl: Uri.parse('https://$id.preview.invalid/api/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: const {'discover', 'categories', 'browse'},
  enabled: true,
  groups: groups,
  addedAt: DateTime.utc(2026, 10, 10),
  sourceProtocol: BookSourceProtocolKind.orsp,
);

const _categoryNames = <String>[
  '全部作品',
  '玄幻奇幻',
  '武侠仙侠',
  '都市生活',
  '历史军事',
  '科幻未来',
  '悬疑推理',
  '古典文学',
  '现代文学',
  '青春校园',
  '浪漫言情',
  '游戏竞技',
];

List<BookSourceBook> _books(String scope) => List.generate(
  8,
  (index) => BookSourceBook(
    id: '$scope-book-${index + 1}',
    title: const [
      '山海之间',
      '长夜灯塔',
      '星河来信',
      '故园风物志',
      '雾中列车',
      '春山可望',
      '人间草木',
      '潮汐与群山',
    ][index],
    author: const ['林间客', '顾远舟', '沈星遥', '江南旧雨'][index % 4],
    description: '固定演示内容，用于验证生产发现页的排版、滚动和玻璃层级。',
    categories: [_categoryNames[index % _categoryNames.length]],
    status: index.isEven ? '连载中' : '已完结',
    latestChapter: '第 ${24 + index} 章 · 风从海上来',
  ),
);
