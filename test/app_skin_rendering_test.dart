import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/pages/home/widgets/home_navigation_item.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/app_skin_image_provider.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/app_skin_artwork.dart';
import 'package:xxread/widgets/app_menu.dart';
import 'package:xxread/widgets/app_skin_icon.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

const _home = 'assets/test-skins/home.png';
const _homeSelected = 'assets/test-skins/home-selected.png';
const _homeSelectedDark = 'assets/test-skins/home-selected-dark.png';
const _library = 'assets/test-skins/library.png';
const _navigation = 'assets/test-skins/navigation.png';
const _background = 'assets/test-skins/background.png';
const _broken = 'assets/test-skins/broken.png';
const _fullCanvas = 'assets/test-skins/full-canvas.png';
final _fullCanvasPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgaGj4DwADhAIAV8n6LgAAAABJRU5ErkJggg==',
);

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
    _fullCanvas,
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
        : key == _fullCanvas
        ? _fullCanvasPng
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
  double textScale = 1,
  TargetPlatform? platform,
}) {
  return DefaultAssetBundle(
    bundle: bundle ?? _SkinAssetBundle(),
    child: MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        platform: platform,
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
          textScaler: TextScaler.linear(textScale),
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

  testWidgets('larger action stickers stay inside their glass hit targets', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        skin: _skin(
          icons: {
            AppSkinIconSlot.back: AppSkinIconAssets(
              normal: AppSkinImage(asset: _home),
            ),
            AppSkinIconSlot.search: AppSkinIconAssets(
              normal: AppSkinImage(asset: _library),
            ),
          },
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconButton(
                key: const ValueKey('sticker-back'),
                icon: const Icon(Icons.arrow_back),
                dimension: 48,
                iconSize: 30,
                tooltip: 'Back',
                onPressed: () => taps++,
              ),
              GlassToolbarButton(
                key: const ValueKey('sticker-search'),
                icon: Icons.search,
                tooltip: 'Search',
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final control in const [
      (key: 'sticker-back', targetSize: 48.0, glyphSize: 30.0),
      (key: 'sticker-search', targetSize: 44.0, glyphSize: 20.0),
    ]) {
      final target = find.byKey(ValueKey(control.key));
      final hitRect = tester.getRect(target);
      final image = find.descendant(
        of: target,
        matching: find.byType(RawImage),
      );
      final paintRect = tester.getRect(image);
      expect(tester.getSize(target), Size.square(control.targetSize));
      expect(paintRect.width, greaterThan(control.glyphSize * 1.4));
      expect(paintRect.center, hitRect.center);
      expect(hitRect.contains(paintRect.topLeft), isTrue);
      expect(hitRect.contains(paintRect.bottomRight), isTrue);
      await tester.tapAt(hitRect.topLeft + const Offset(2, 2));
    }
    expect(taps, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('larger navigation stickers leave labels and targets clear', (
    tester,
  ) async {
    for (final horizontal in [false, true]) {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          skin: _skin(
            icons: {
              AppSkinIconSlot.library: AppSkinIconAssets(
                normal: AppSkinImage(asset: _library),
                selected: AppSkinImage(asset: _homeSelected),
              ),
            },
          ),
          child: Center(
            child: SizedBox(
              width: 140,
              height: 64,
              child: HomeBounceNavigationItem(
                item: const HomeNavigationItem(
                  destination: HomeNavigationDestination.library,
                  icon: Icons.library_books_outlined,
                  selectedIcon: Icons.library_books,
                  label: 'Library',
                  page: SizedBox(),
                ),
                isSelected: true,
                horizontal: horizontal,
                showLabel: true,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hitRect = tester.getRect(
        find.byKey(const ValueKey('home-nav-press-Library')),
      );
      final image = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is AppSkinIcon && widget.selected,
        ),
        matching: find.byType(RawImage),
      );
      final paintRect = tester.getRect(image);
      final labelRect = tester.getRect(find.text('Library'));
      expect(hitRect.size, const Size(140, 64));
      expect(paintRect.width, greaterThan(horizontal ? 32 : 37));
      expect(hitRect.contains(paintRect.topLeft), isTrue);
      expect(hitRect.contains(paintRect.bottomRight), isTrue);
      expect(paintRect.overlaps(labelRect), isFalse);
      expect(find.bySemanticsLabel('Library'), findsOneWidget);
      await tester.tapAt(hitRect.bottomRight - const Offset(2, 2));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('hiding navigation labels gives artwork and glyphs more room', (
    tester,
  ) async {
    for (final artwork in [false, true]) {
      for (final horizontal in [false, true]) {
        final skin = artwork
            ? _skin(
                icons: {
                  AppSkinIconSlot.library: AppSkinIconAssets(
                    normal: AppSkinImage(asset: _fullCanvas),
                  ),
                },
              )
            : AppSkin.original;
        Rect? labeledIcon;
        var taps = 0;
        for (final showLabel in [true, false]) {
          await tester.pumpWidget(
            _host(
              skin: skin,
              child: Center(
                child: SizedBox(
                  width: horizontal ? 140 : 70,
                  height: 60,
                  child: HomeBounceNavigationItem(
                    item: const HomeNavigationItem(
                      destination: HomeNavigationDestination.library,
                      icon: Icons.library_books_outlined,
                      selectedIcon: Icons.library_books,
                      label: '书库',
                      page: SizedBox(),
                    ),
                    isSelected: true,
                    showLabel: showLabel,
                    horizontal: horizontal,
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final target = tester.getRect(
            find.byKey(const ValueKey('home-nav-press-书库')),
          );
          final icon = tester.getRect(
            find.descendant(
              of: find.byWidgetPredicate(
                (widget) => widget is AppSkinIcon && widget.selected,
              ),
              matching: artwork ? find.byType(RawImage) : find.byType(Icon),
            ),
          );
          expect(target.contains(icon.topLeft), isTrue);
          expect(target.contains(icon.bottomRight), isTrue);
          expect(find.bySemanticsLabel('书库'), findsOneWidget);
          if (showLabel) {
            labeledIcon = icon;
            expect(icon.overlaps(tester.getRect(find.text('书库'))), isFalse);
          } else {
            expect(find.text('书库'), findsNothing);
            expect(icon.width, greaterThan(labeledIcon!.width * 1.2));
            expect((icon.center - target.center).distance, lessThan(1.5));
          }
          await tester.tapAt(target.bottomRight - const Offset(2, 2));
          expect(tester.takeException(), isNull);
        }
        expect(taps, 2);
      }
    }
  });

  testWidgets('full-canvas artwork fits compact and large-text UI', (
    tester,
  ) async {
    // Check installed-file resolution separately from platform image I/O.
    expect(
      appSkinImageProvider(
        AppSkinImage.installed(path: '/tmp/skin-full-canvas.png'),
        Brightness.light,
      ),
      isA<FileImage>(),
    );
    final asset = AppSkinIconAssets(normal: AppSkinImage(asset: _fullCanvas));
    final skin = _skin(
      icons: {AppSkinIconSlot.back: asset, AppSkinIconSlot.library: asset},
    );
    await tester.pumpWidget(
      _host(
        skin: skin,
        child: Center(
          child: GlassIconButton(
            key: const ValueKey('compact-sticker'),
            dimension: 32,
            iconSize: 22,
            icon: const Icon(Icons.arrow_back),
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Codec completion can arrive after the test binding has no scheduled frame.
    for (
      var attempt = 0;
      attempt < 20 &&
          tester.widget<RawImage>(find.byType(RawImage)).image == null;
      attempt++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    final compactRect = tester.getRect(
      find.byKey(const ValueKey('compact-sticker')),
    );
    final compactPaint = tester.getRect(find.byType(RawImage));
    expect(compactRect.contains(compactPaint.topLeft), isTrue);
    expect(
      compactRect.bottomRight.dx,
      greaterThanOrEqualTo(compactPaint.right),
    );
    expect(
      compactRect.bottomRight.dy,
      greaterThanOrEqualTo(compactPaint.bottom),
    );

    for (final horizontal in [false, true]) {
      await tester.pumpWidget(
        _host(
          skin: skin,
          textScale: 2,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 64,
              child: HomeBounceNavigationItem(
                item: const HomeNavigationItem(
                  destination: HomeNavigationDestination.library,
                  icon: Icons.library_books,
                  selectedIcon: Icons.library_books,
                  label: 'Library',
                  page: SizedBox(),
                ),
                isSelected: true,
                horizontal: horizontal,
                showLabel: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final image = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is AppSkinIcon && widget.selected,
        ),
        matching: find.byType(RawImage),
      );
      expect(
        tester.getRect(image).overlaps(tester.getRect(find.text('Library'))),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'menu stickers retain the original trigger size and interaction',
    (tester) async {
      final skin = _skin(
        icons: {
          AppSkinIconSlot.more: AppSkinIconAssets(
            normal: AppSkinImage(asset: _fullCanvas),
          ),
        },
      );
      for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
        Widget menu() => AppPopupMenuButton<String>(
          key: const ValueKey('skin-menu-trigger'),
          tooltip: 'More',
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'choice', child: Text('Choice')),
          ],
        );
        await tester.pumpWidget(
          _host(
            skin: _skin(),
            platform: platform,
            child: Center(child: menu()),
          ),
        );
        await tester.pumpAndSettle();
        final originalRect = tester.getRect(
          find.byKey(const ValueKey('skin-menu-trigger')),
        );
        await tester.pumpWidget(
          _host(
            skin: skin,
            platform: platform,
            child: Center(child: menu()),
          ),
        );
        await tester.pumpAndSettle();
        final target = find.byKey(const ValueKey('skin-menu-trigger'));
        final rect = tester.getRect(target);
        final paintRect = tester.getRect(find.byType(RawImage));
        expect(rect, originalRect);
        expect(rect.contains(paintRect.topLeft), isTrue);
        expect(rect.contains(paintRect.bottomRight), isTrue);
        expect(find.byTooltip('More'), findsOneWidget);
        await tester.tapAt(rect.topLeft + const Offset(2, 2));
        await tester.pumpAndSettle();
        expect(find.text('Choice'), findsOneWidget);
        await tester.tap(find.text('Choice'));
        await tester.pumpAndSettle();
        expect(find.text('Choice'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
      expect(
        tester.getSize(find.byKey(const ValueKey('broken-icon-fallback'))),
        const Size.square(37),
      );
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('broken-icon-fallback')),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
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

      Widget page(
        bool highContrast, {
        Brightness brightness = Brightness.light,
      }) => _host(
        skin: skin,
        brightness: brightness,
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
      expect(rendered!.image!.opacity, 0.35);

      await tester.pumpWidget(page(false, brightness: Brightness.dark));
      await tester.pumpAndSettle();
      expect(rendered!.gradient, same(fallback.gradient));
      expect(rendered!.image!.opacity, 0.24);

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
