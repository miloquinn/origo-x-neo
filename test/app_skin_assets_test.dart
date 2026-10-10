// 文件说明：验证内置皮肤素材和第三方许可随 Flutter 资源包交付。
// 测试重点：语义槽完整、图片可解码、许可证注册幂等且内容可读。

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/utils/app_skin_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every bundled image skin has complete decodable assets', () async {
    const navigationSlots = {
      AppSkinIconSlot.home,
      AppSkinIconSlot.library,
      AppSkinIconSlot.discover,
      AppSkinIconSlot.ai,
      AppSkinIconSlot.profile,
    };
    final skins = AppSkinCatalog.builtIn.skins
        .where((skin) => skin.id != AppSkin.originalId)
        .toList(growable: false);
    final imagePaths = <String>{};

    expect(skins, hasLength(3));
    for (final skin in skins) {
      expect(skin.icons.keys.toSet(), navigationSlots, reason: skin.id);
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

    for (final path in imagePaths) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(0), reason: path);
      expect(frame.image.height, greaterThan(0), reason: path);
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
              entry.packages.contains('Twemoji graphics') ||
              entry.packages.contains('App skin artwork'),
        )
        .toList();
    expect(entries, hasLength(2));

    final text = entries
        .expand((entry) => entry.paragraphs)
        .map((paragraph) => paragraph.text)
        .join('\n');
    expect(text, contains('Creative Commons Corporation'));
    expect(text, contains('twitter/twemoji/tree/v14.0.2'));
    expect(text, contains('NASA does not endorse Origo X'));
  });
}

void _addImagePaths(Set<String> paths, AppSkinImage image) {
  paths.add(image.asset);
  final darkAsset = image.darkAsset;
  if (darkAsset != null) paths.add(darkAsset);
}
