import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/widgets/home_bounce_navigation_item.dart';
import 'package:xxread/pages/home/widgets/home_navigation_item.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/elastic_pill_navigation_bar.dart';
import 'package:xxread/widgets/floating_pill_navigation_surface.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_surface.dart';

// Developer fixture only: reuse existing bundled artwork; no shipped skin choice.
void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _skin = AppSkin(
    id: 'preview-artwork',
    icons: {
      AppSkinIconSlot.library: AppSkinIconAssets(
        normal: AppSkinImage(asset: 'assets/images/app_icon_android.png'),
        selected: AppSkinImage(asset: 'assets/images/app_icon.png'),
      ),
    },
    artwork: {
      AppSkinArtworkSlot.pageBackground: AppSkinImage(
        asset: 'assets/purchase/wave.jpg',
        darkAsset: 'assets/purchase/irises.jpg',
      ),
      AppSkinArtworkSlot.navigation: AppSkinImage(
        asset: 'assets/purchase/irises.jpg',
      ),
    },
  );
  static const _cases = [
    'original',
    'artwork-frosted',
    'artwork-liquid',
    'artwork-dark',
    'artwork-solid',
    'artwork-contrast',
  ];
  var _caseIndex = 0;
  var _selected = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  Widget build(BuildContext context) {
    final name = _cases[_caseIndex];
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: name == 'artwork-dark' ? Brightness.dark : Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        extensions: [
          AppSkinTheme(skin: name == 'original' ? AppSkin.original : _skin),
          UiStyleThemeExtension(
            style: name == 'artwork-solid'
                ? AppUiStyle.material3
                : AppUiStyle.glass,
            glassStyle: name == 'artwork-liquid' || name == 'artwork-dark'
                ? GlassStyle.liquid
                : GlassStyle.frosted,
          ),
        ],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(highContrast: name == 'artwork-contrast'),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: scheme.surface,
          body: Center(
            child: RepaintBoundary(
              key: _boundary,
              child: SizedBox(
                width: 390,
                height: 650,
                child: DecoratedBox(
                  decoration: PageStyleHelper.backgroundDecoration(context),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Library',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const Spacer(),
                            GlassToolbarButton(
                              icon: Icons.search_rounded,
                              onPressed: () {},
                            ),
                            GlassToolbarButton(
                              icon: Icons.more_vert_rounded,
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        GlassSurface(
                          role: GlassSurfaceRole.panel,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Continue reading',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Artwork changes. The shared glass material and navigation remain in control.',
                                  style: TextStyle(fontSize: 17, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 18),
                        FloatingPillNavigationSurface(
                          width: 346,
                          height: 72,
                          child: ElasticPillNavigationBar(
                            selectedIndex: _selected,
                            onSelected: (index) =>
                                setState(() => _selected = index),
                            children: List.generate(
                              4,
                              (index) => HomeBounceNavigationItem(
                                item: HomeNavigationItem(
                                  destination:
                                      HomeNavigationDestination.values[index],
                                  icon: [
                                    Icons.home_outlined,
                                    Icons.library_books_outlined,
                                    Icons.explore_outlined,
                                    Icons.auto_awesome_outlined,
                                  ][index],
                                  selectedIcon: [
                                    Icons.home,
                                    Icons.library_books,
                                    Icons.explore_rounded,
                                    Icons.auto_awesome,
                                  ][index],
                                  label: [
                                    'Home',
                                    'Books',
                                    'Discover',
                                    'AI',
                                  ][index],
                                  page: const SizedBox.shrink(),
                                ),
                                isSelected: _selected == index,
                                showLabel: true,
                                showSelectionIndicator: false,
                                onTap: () => setState(() => _selected = index),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _capture() async {
    final output = Directory('${Directory.systemTemp.path}/app-skin-preview');
    await output.create(recursive: true);
    for (var index = 0; index < _cases.length; index++) {
      setState(() => _caseIndex = index);
      await Future<void>.delayed(const Duration(seconds: 2));
      await WidgetsBinding.instance.endOfFrame;
      final image =
          await (_boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${output.path}/${_cases[index]}.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }
    debugPrint('Skin preview captures: ${output.path}');
  }
}
