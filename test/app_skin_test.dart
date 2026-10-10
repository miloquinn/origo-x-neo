import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_theme.dart';

void main() {
  group('AppSkinImage', () {
    test(
      'selects a dark variant and otherwise falls back to the base asset',
      () {
        final withDark = AppSkinImage(
          asset: 'assets/skins/ocean/home.png',
          darkAsset: 'assets/skins/ocean/home-dark.webp',
        );
        final withoutDark = AppSkinImage(
          asset: 'assets/skins/ocean/library.jpg',
        );

        expect(withDark.pathFor(Brightness.light), withDark.asset);
        expect(
          withDark.pathFor(Brightness.dark),
          'assets/skins/ocean/home-dark.webp',
        );
        expect(withoutDark.pathFor(Brightness.dark), withoutDark.asset);
      },
    );

    test('accepts only supported bundled relative raster paths', () {
      for (final asset in [
        '/assets/skin.png',
        'https://example.com/skin.png',
        'assets/../private/skin.png',
        'assets/skins/./skin.png',
        r'assets\skins\skin.png',
        'images/skin.png',
        'assets/skins/skin.svg',
      ]) {
        expect(
          () => AppSkinImage(asset: asset),
          throwsArgumentError,
          reason: asset,
        );
      }
    });
  });

  test('icon assets select the selected variant when one exists', () {
    final normal = AppSkinImage(asset: 'assets/skins/ocean/home.png');
    final selected = AppSkinImage(
      asset: 'assets/skins/ocean/home-selected.png',
    );

    expect(
      AppSkinIconAssets(normal: normal, selected: selected).resolve(true),
      same(selected),
    );
    expect(AppSkinIconAssets(normal: normal).resolve(true), same(normal));
  });

  test('skin collections are immutable snapshots', () {
    final sourceIcons = <AppSkinIconSlot, AppSkinIconAssets>{
      AppSkinIconSlot.home: AppSkinIconAssets(
        normal: AppSkinImage(asset: 'assets/skins/ocean/home.png'),
      ),
    };
    final skin = AppSkin(id: 'ocean', icons: sourceIcons);
    sourceIcons.clear();

    expect(skin.icons, contains(AppSkinIconSlot.home));
    expect(
      () => skin.icons[AppSkinIconSlot.library] = AppSkinIconAssets(
        normal: AppSkinImage(asset: 'assets/skins/ocean/library.png'),
      ),
      throwsUnsupportedError,
    );
  });

  test('skin ids use a stable simple format', () {
    expect(() => AppSkin(id: 'Ocean Friends'), throwsArgumentError);
    expect(() => AppSkin(id: 'ocean/friends'), throwsArgumentError);
    expect(AppSkin(id: 'ocean-friends').id, 'ocean-friends');
  });

  test(
    'catalog owns original fallback and rejects reserved or duplicate ids',
    () {
      final ocean = AppSkin(id: 'ocean');
      final catalog = AppSkinCatalog([ocean]);

      expect(catalog.skins, [AppSkin.original, ocean]);
      expect(catalog.find('ocean'), same(ocean));
      expect(catalog.find('missing'), isNull);
      expect(catalog.resolve(null), same(AppSkin.original));
      expect(catalog.resolve('removed'), same(AppSkin.original));
      expect(
        () => catalog.skins.add(AppSkin(id: 'forest')),
        throwsUnsupportedError,
      );
      expect(
        () => AppSkinCatalog([AppSkin(id: 'ocean'), AppSkin(id: 'ocean')]),
        throwsArgumentError,
      );
      expect(
        () => AppSkinCatalog([AppSkin(id: AppSkin.originalId)]),
        throwsArgumentError,
      );
    },
  );

  testWidgets('theme extension falls back and switches discretely', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(AppSkinTheme.of(context).skin, same(AppSkin.original));

    final ocean = AppSkin(id: 'ocean');
    final originalTheme = AppSkinTheme(skin: AppSkin.original);
    final oceanTheme = AppSkinTheme(skin: ocean);
    expect(originalTheme.lerp(oceanTheme, 0.49).skin, same(AppSkin.original));
    expect(originalTheme.lerp(oceanTheme, 0.5).skin, same(ocean));
    expect(originalTheme.copyWith(skin: ocean).skin, same(ocean));
  });
}
