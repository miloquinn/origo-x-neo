// 文件说明：验证内置皮肤素材和第三方许可随 Flutter 资源包交付。
// 测试重点：语义槽完整、图片可解码、许可证注册幂等且内容可读。

import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled image skin has complete decodable assets', () async {
    final skins = AppSkinCatalog.builtIn.skins
        .where((skin) => skin.id != AppSkin.originalId)
        .toList(growable: false);
    final imagePaths = <String>{};

    expect(skins, hasLength(3));
    expect(AppSkinIconSlot.values, hasLength(62));
    for (final skin in skins) {
      expect(
        skin.icons.keys.toSet(),
        AppSkinIconSlot.values.toSet(),
        reason: skin.id,
      );
      expect(
        skin.artwork.keys.toSet(),
        AppSkinArtworkSlot.values.toSet(),
        reason: skin.id,
      );

      for (final icon in skin.icons.values) {
        _addImagePaths(imagePaths, icon.normal);
        final selected = icon.selected;
        if (selected != null) _addImagePaths(imagePaths, selected);
      }
      for (final artwork in skin.artwork.values) {
        _addImagePaths(imagePaths, artwork);
      }
    }
    expect(imagePaths, hasLength(750));

    final manifestEntries =
        (await rootBundle.loadString('assets/skins/MANIFEST.sha256'))
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => line.split('  '))
            .toList(growable: false);
    final manifestDigests = {
      for (final entry in manifestEntries) entry.last: entry.first,
    };
    final manifestPaths = manifestDigests.keys.toSet();
    final expectedManifestPaths = <String>{
      for (final path in imagePaths) path.replaceFirst('assets/skins/', ''),
      for (final theme in ['tidal', 'botanical', 'celestial']) ...[
        'backgrounds/$theme.jpg',
        'backgrounds/$theme-dark.jpg',
      ],
      'source/generate_builtin_skins.py',
      'LICENSE-ICONPARK-APACHE-2.0.txt',
    };
    expect(manifestPaths, expectedManifestPaths);
    expect(manifestPaths, hasLength(752));

    for (final path in imagePaths) {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final relativePath = path.replaceFirst('assets/skins/', '');
      expect(
        sha256.convert(bytes).toString(),
        manifestDigests[relativePath],
        reason: '$path must match MANIFEST.sha256',
      );
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (relativePath.startsWith('collections/')) {
        expect(frame.image.width, 128, reason: path);
        expect(frame.image.height, 128, reason: path);
        final pixels = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        expect(pixels, isNotNull, reason: path);
        expect(pixels!.getUint8(3), 0, reason: '$path must keep transparency');
      } else {
        expect(frame.image.width, 1200, reason: path);
        expect(frame.image.height, 1800, reason: path);
      }
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('skin credits and full graphics license register once', () async {
    registerAppSkinLicenses();
    registerAppSkinLicenses();

    final entries = await LicenseRegistry.licenses
        .where(
          (entry) =>
              entry.packages.contains('IconPark graphics') ||
              entry.packages.contains('App skin artwork'),
        )
        .toList();
    expect(entries, hasLength(2));

    final text = entries
        .expand((entry) => entry.paragraphs)
        .map((paragraph) => paragraph.text)
        .join('\n');
    expect(text, contains('Apache License'));
    expect(text, contains('bytedance/IconPark/tree/v1.4.2'));
  });
}

void _addImagePaths(Set<String> paths, AppSkinImage image) {
  paths.add(image.asset);
  final darkAsset = image.darkAsset;
  if (darkAsset != null) paths.add(darkAsset);
}
