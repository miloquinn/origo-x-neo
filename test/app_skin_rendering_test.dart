import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/pages/home/widgets/home_navigation_item.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/app_skin_artwork.dart';
import 'package:xxread/widgets/app_skin_icon.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

const _home = 'assets/test-skins/home.png';
const _homeSelected = 'assets/test-skins/home-selected.png';
const _homeSelectedDark = 'assets/test-skins/home-selected-dark.png';
const _library = 'assets/test-skins/library.png';
const _navigation = 'assets/test-skins/navigation.png';
const _background = 'assets/test-skins/background.png';
const _broken = 'assets/test-skins/broken.png';

final _tinyPng = Uint8List.fromList(const <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

final class _SkinAssetBundle extends CachingAssetBundle {
  _SkinAssetBundle({this.brokenPaths = const {}});

  final Set<String> brokenPaths;

  static const _paths = <String>{
    _home,
    _homeSelected,
    _homeSelectedDark,
    _library,
    _navigation,
    _background,
    _broken,
  };

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final path in _paths)
          path: <Object>[
            <String, Object>{'asset': path},
          ],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    if (!_paths.contains(key)) throw FlutterError('Missing test asset: $key');
    final bytes = brokenPaths.contains(key)
        ? Uint8List.fromList(const [0x01, 0x02, 0x03])
        : _tinyPng;
    return ByteData.sublistView(bytes);
  }
}

AppSkin _skin({
  Map<AppSkinIconSlot, AppSkinIconAssets> icons = const {},
  Map<AppSkinArtworkSlot, AppSkinImage> artwork = const {},
}) => AppSkin(id: 'test-skin', icons: icons, artwork: artwork);

Widget _host({
  required Widget child,
  required AppSkin skin,
  Brightness brightness = Brightness.light,
  AppUiStyle uiStyle = AppUiStyle.glass,
  GlassStyle glassStyle = GlassStyle.frosted,
  bool highContrast = false,
  AssetBundle? bundle,
}) {
  return DefaultAssetBundle(
    bundle: bundle ?? _SkinAssetBundle(),
    child: MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        extensions: [
          AppSkinTheme(skin: skin),
          UiStyleThemeExtension(
            style: uiStyle,
            glassStyle: glassStyle,
            liquidGlassOpacity: 0.6,
          ),
        ],
      ),
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: true,
          highContrast: highContrast,
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

String _assetPath(Image image) => (image.image as AssetImage).assetName;

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setLiquidGlassOpacity(0.6);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(defaultLiquidGlassOpacity);
    GlassEffectConfig.applyPerformanceMode(reduceEffects: false);
    imageCache.clear();
    imageCache.clearLiveImages();
  });

  testWidgets('skin icon resolves selected and dark variants', (tester) async {
    final skin = _skin(
      icons: {
        AppSkinIconSlot.home: AppSkinIconAssets(
          normal: AppSkinImage(asset: _home),
          selected: AppSkinImage(
            asset: _homeSelected,
            darkAsset: _homeSelectedDark,
          ),
        ),
      },
    );

    await tester.pumpWidget(
      _host(
        skin: skin,
        brightness: Brightness.dark,
        child: const Center(
          child: AppSkinIcon(
            slot: AppSkinIconSlot.home,
            selected: true,
            fallback: Icon(Icons.home, size: 30),
          ),
        ),
      ),
    );

    expect(
      _assetPath(tester.widget<Image>(find.byType(Image))),
      _homeSelectedDark,
    );
  });

  testWidgets('missing icon slot preserves the exact original glyph', (
    tester,
  ) async {
    const fallback = Icon(
      Icons.library_books,
      key: ValueKey('original-library-icon'),
      size: 31,
      color: Colors.teal,
      semanticLabel: 'Library',
    );
    await tester.pumpWidget(
      _host(
        skin: _skin(),
        child: const Center(
          child: AppSkinIcon(slot: AppSkinIconSlot.library, fallback: fallback),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    final rendered = tester.widget<Icon>(
      find.byKey(const ValueKey('original-library-icon')),
    );
    expect(rendered.icon, fallback.icon);
    expect(rendered.size, fallback.size);
    expect(rendered.color, fallback.color);
    expect(rendered.semanticLabel, fallback.semanticLabel);
  });

  testWidgets(
    'broken icon reports failure and restores unwrapped fallback size',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousHandler);

      await tester.pumpWidget(
        _host(
          skin: _skin(
            icons: {
              AppSkinIconSlot.home: AppSkinIconAssets(
                normal: AppSkinImage(asset: _broken),
              ),
            },
          ),
          bundle: _SkinAssetBundle(brokenPaths: const {_broken}),
          child: const Center(
            child: AppSkinIcon(
              slot: AppSkinIconSlot.home,
              fallback: Icon(
                Icons.home,
                key: ValueKey('broken-icon-fallback'),
                size: 37,
                color: Colors.orange,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fallback = tester.widget<Icon>(
        find.byKey(const ValueKey('broken-icon-fallback')),
      );
      expect(fallback.size, 37);
      expect(fallback.color, Colors.orange);
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('broken-icon-fallback')),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(
        errors.any((error) => error.context.toString().contains(_broken)),
        isTrue,
      );
    },
  );

  testWidgets(
    'reordered library navigation keeps semantic skin slot, target and click',
    (tester) async {
      final skin = _skin(
        icons: {
          AppSkinIconSlot.library: AppSkinIconAssets(
            normal: AppSkinImage(asset: _library),
          ),
        },
      );
      for (final horizontal in [false, true]) {
        var taps = 0;
        final items = [
          const HomeNavigationItem(
            destination: HomeNavigationDestination.discover,
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Discover',
            page: SizedBox(),
          ),
          const HomeNavigationItem(
            destination: HomeNavigationDestination.library,
            icon: Icons.library_books_outlined,
            selectedIcon: Icons.library_books,
            label: 'Library',
            page: SizedBox(),
          ),
        ];
        await tester.pumpWidget(
          _host(
            skin: skin,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 64,
                child: Row(
                  children: [
                    for (final item in items)
                      Expanded(
                        child: HomeBounceNavigationItem(
                          item: item,
                          isSelected:
                              item.destination ==
                              HomeNavigationDestination.library,
                          horizontal: horizontal,
                          showLabel: horizontal,
                          onTap: () {
                            if (item.destination ==
                                HomeNavigationDestination.library) {
                              taps += 1;
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final libraryTarget = find.byKey(
          const ValueKey('home-nav-press-Library'),
        );
        expect(tester.getSize(libraryTarget), const Size(110, 64));
        expect(
          find.descendant(
            of: libraryTarget,
            matching: find.byWidgetPredicate(
              (widget) => widget is Image && _assetPath(widget) == _library,
            ),
          ),
          findsWidgets,
        );
        expect(find.bySemanticsLabel('Library'), findsOneWidget);
        await tester.tap(libraryTarget);
        await tester.pump();
        expect(taps, 1, reason: 'horizontal=$horizontal');
      }
    },
  );

  testWidgets('navigation artwork stays beneath glass across policies', (
    tester,
  ) async {
    final skin = _skin(
      artwork: {
        AppSkinArtworkSlot.navigation: AppSkinImage(asset: _navigation),
      },
    );
    final modes = [
      (name: 'frosted', style: AppUiStyle.glass, disabled: false, high: false),
      (
        name: 'material3',
        style: AppUiStyle.material3,
        disabled: false,
        high: false,
      ),
      (name: 'off', style: AppUiStyle.glass, disabled: true, high: false),
      (
        name: 'high-contrast',
        style: AppUiStyle.glass,
        disabled: false,
        high: true,
      ),
    ];

    for (final mode in modes) {
      GlassEffectConfig.setDisableAllGlassEffects(mode.disabled);
      await tester.pumpWidget(
        _host(
          skin: skin,
          uiStyle: mode.style,
          highContrast: mode.high,
          child: const Center(
            child: FloatingPillNavigationSurface(
              width: 240,
              height: 56,
              child: SizedBox.expand(key: ValueKey('nav-hit-content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassSurface), findsOneWidget, reason: mode.name);
      if (mode.high) {
        expect(find.byType(AppSkinArtwork), findsOneWidget);
        expect(find.byType(Image), findsNothing, reason: mode.name);
        expect(find.byType(BackdropFilter), findsNothing, reason: mode.name);
      } else {
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Image && _assetPath(widget) == _navigation,
          ),
          findsOneWidget,
          reason: mode.name,
        );
        final stack = tester.widget<Stack>(
          find
              .descendant(
                of: find.byType(AppSkinArtwork),
                matching: find.byType(Stack),
              )
              .first,
        );
        expect(stack.children.first, isA<Positioned>(), reason: mode.name);
        expect(stack.children.last, isA<GlassSurface>(), reason: mode.name);
      }
      if (mode.name == 'frosted') {
        expect(find.byType(BackdropFilter), findsOneWidget);
      } else {
        expect(find.byType(BackdropFilter), findsNothing, reason: mode.name);
        expect(
          find.byType(LiquidGlassSurface),
          findsNothing,
          reason: mode.name,
        );
      }
    }
  });

  testWidgets(
    'page skin keeps original gradient and high contrast suppresses image',
    (tester) async {
      const fallback = BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo, Colors.cyan]),
      );
      final skin = _skin(
        artwork: {
          AppSkinArtworkSlot.pageBackground: AppSkinImage(asset: _background),
        },
      );
      BoxDecoration? rendered;

      Widget page(bool highContrast) => _host(
        skin: skin,
        highContrast: highContrast,
        child: Builder(
          builder: (context) {
            rendered = PageStyleHelper.backgroundDecoration(
              context,
              fallback: fallback,
            );
            return DecoratedBox(
              decoration: rendered!,
              child: const SizedBox.expand(),
            );
          },
        ),
      );

      await tester.pumpWidget(page(false));
      expect(rendered!.gradient, same(fallback.gradient));
      expect((rendered!.image!.image as AssetImage).assetName, _background);

      await tester.pumpWidget(page(true));
      expect(rendered!.gradient, same(fallback.gradient));
      expect(rendered!.image, isNull);
    },
  );

  testWidgets(
    'broken page image reports error while fallback remains painted',
    (tester) async {
      final errors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previousHandler);
      const fallback = BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple, Colors.amber]),
      );
      BoxDecoration? rendered;

      await tester.pumpWidget(
        _host(
          skin: _skin(
            artwork: {
              AppSkinArtworkSlot.pageBackground: AppSkinImage(asset: _broken),
            },
          ),
          bundle: _SkinAssetBundle(brokenPaths: const {_broken}),
          child: Builder(
            builder: (context) {
              rendered = PageStyleHelper.backgroundDecoration(
                context,
                fallback: fallback,
              );
              return DecoratedBox(
                decoration: rendered!,
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(rendered!.gradient, same(fallback.gradient));
      expect(rendered!.color, fallback.color);
      expect(
        errors.any((error) => error.context.toString().contains(_broken)),
        isTrue,
      );
    },
  );

  test(
    'reader palette preserves skin and glass policy while owning colors',
    () {
      final skinTheme = AppSkinTheme(
        skin: _skin(
          artwork: {
            AppSkinArtworkSlot.pageBackground: AppSkinImage(asset: _background),
          },
        ),
      );
      const appearance = UiStyleThemeExtension(
        style: AppUiStyle.glass,
        glassStyle: GlassStyle.frosted,
        liquidGlassOpacity: 0.72,
      );
      final parent = ThemeData(extensions: [skinTheme, appearance]);

      final reader = ReaderThemes.parchment.toThemeData(parentTheme: parent);

      expect(reader.extension<AppSkinTheme>(), same(skinTheme));
      expect(reader.extension<UiStyleThemeExtension>(), same(appearance));
      expect(reader.scaffoldBackgroundColor, ReaderThemes.parchment.background);
      expect(reader.colorScheme.surface, ReaderThemes.parchment.surface);
      expect(reader.colorScheme.primary, ReaderThemes.parchment.accent);
    },
  );
}
