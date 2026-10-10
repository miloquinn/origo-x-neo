import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/theme_package.dart';
import 'package:xxread/utils/app_skin_image_provider.dart';

void main() {
  const root = '/tmp/origo-theme-model';

  test('v1 manifest maps every public semantic slot to installed files', () {
    final manifest = _manifest();
    manifest['icons'] = {
      for (final slot in AppSkinIconSlot.values)
        slot.name: {
          'normal': {'asset': 'assets/icon.png'},
          'selected': {
            'asset': 'assets/icon-selected.png',
            'darkAsset': 'assets/icon-selected-dark.png',
          },
        },
    };

    final package = ThemePackage.parse(
      manifest,
      rootDirectory: root,
      reservedIds: const {'original', 'tidal'},
    );

    expect(package.runtimeSkinId, 'community_paper-garden');
    expect(package.skin.id, package.runtimeSkinId);
    expect(package.skin.icons.keys, AppSkinIconSlot.values);
    expect(package.palette?.primary, '#123456');
    expect(package.preview.source, AppSkinImageSource.installedFile);
    expect(
      package.preview.pathFor(Brightness.light),
      '$root/assets/preview.png',
    );
    expect(
      package.referencedRelativePaths(),
      containsAll({
        'assets/preview.png',
        'assets/icon.png',
        'assets/icon-selected.png',
        'assets/icon-selected-dark.png',
        'assets/background.jpg',
      }),
    );
  });

  test(
    'strict parser rejects reserved ids, URLs, code fields and unknown slots',
    () {
      expect(
        () => ThemePackage.parse(
          _manifest(id: 'tidal'),
          rootDirectory: root,
          reservedIds: const {'tidal'},
        ),
        throwsA(isA<ThemePackageFormatException>()),
      );

      final url = _manifest()..['preview'] = 'https://example.com/preview.png';
      expect(
        () => ThemePackage.parse(url, rootDirectory: root),
        throwsA(isA<ThemePackageFormatException>()),
      );

      final executable = _manifest()..['code'] = 'alert(1)';
      expect(
        () => ThemePackage.parse(executable, rootDirectory: root),
        throwsA(isA<ThemePackageFormatException>()),
      );

      final unknownSlot = _manifest()
        ..['icons'] = {
          'launchNuclearMissile': {
            'normal': {'asset': 'assets/icon.png'},
          },
        };
      expect(
        () => ThemePackage.parse(unknownSlot, rootDirectory: root),
        throwsA(isA<ThemePackageFormatException>()),
      );
    },
  );

  test('image sources preserve bundled compatibility and choose providers', () {
    final bundled = AppSkinImage(asset: 'assets/skins/icon.png');
    final installed = AppSkinImage.installed(
      path: '/tmp/origo-theme/icon.png',
      darkPath: '/tmp/origo-theme/icon-dark.png',
    );

    expect(bundled.source, AppSkinImageSource.bundledAsset);
    expect(appSkinImageProvider(bundled, Brightness.light), isA<AssetImage>());
    expect(installed.source, AppSkinImageSource.installedFile);
    expect(appSkinImageProvider(installed, Brightness.dark), isA<FileImage>());
    expect(
      () => AppSkinImage.installed(path: '../outside.png'),
      throwsArgumentError,
    );
  });
}

Map<String, Object?> _manifest({String id = 'paper-garden', int version = 1}) =>
    <String, Object?>{
      'schemaVersion': 1,
      'id': id,
      'version': version,
      'name': 'Paper Garden',
      'description': 'A calm paper garden.',
      'author': 'Theme Maker',
      'license': 'CC BY 4.0',
      'preview': 'assets/preview.png',
      'palette': {
        'primary': '#123456',
        'secondary': '#abcdef',
        'tertiary': '#998877',
      },
      'icons': {
        'home': {
          'normal': {'asset': 'assets/icon.png'},
        },
      },
      'artwork': {
        'pageBackground': {'asset': 'assets/background.jpg'},
      },
    };
