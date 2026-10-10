// 文件说明：定义应用皮肤的语义素材与只读目录。
// 技术要点：不可变模型、稳定 ID 校验、内置资源路径约束。

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppSkinIconSlot {
  home,
  library,
  discover,
  ai,
  profile,
  back,
  search,
  more,
}

enum AppSkinArtworkSlot { pageBackground, navigation }

@immutable
class AppSkinImage {
  AppSkinImage({required String asset, String? darkAsset})
    : asset = _validateAsset(asset, field: 'asset'),
      darkAsset = darkAsset == null
          ? null
          : _validateAsset(darkAsset, field: 'darkAsset');

  final String asset;
  final String? darkAsset;

  String pathFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkAsset ?? asset : asset;

  static String _validateAsset(String value, {required String field}) {
    final lower = value.toLowerCase();
    final segments = value.split('/');
    final isBundledAsset =
        value.startsWith('assets/') &&
        value.length > 'assets/'.length &&
        !value.startsWith('/') &&
        !value.contains('\\') &&
        !value.contains('?') &&
        !value.contains('#') &&
        !segments.contains('..') &&
        !segments.contains('.') &&
        !segments.contains('') &&
        !Uri.parse(value).hasScheme;
    final hasSupportedSuffix = const [
      '.png',
      '.webp',
      '.jpg',
      '.jpeg',
    ].any(lower.endsWith);
    if (!isBundledAsset || !hasSupportedSuffix) {
      throw ArgumentError.value(
        value,
        field,
        'must be a bundled relative assets/ PNG, WebP, JPG, or JPEG path',
      );
    }
    return value;
  }
}

@immutable
class AppSkinIconAssets {
  const AppSkinIconAssets({required this.normal, this.selected});

  final AppSkinImage normal;
  final AppSkinImage? selected;

  AppSkinImage resolve(bool isSelected) =>
      isSelected ? selected ?? normal : normal;
}

@immutable
class AppSkin {
  AppSkin({
    required String id,
    Map<AppSkinIconSlot, AppSkinIconAssets> icons = const {},
    Map<AppSkinArtworkSlot, AppSkinImage> artwork = const {},
  }) : id = _validateId(id),
       icons = Map.unmodifiable(icons),
       artwork = Map.unmodifiable(artwork);

  static const String originalId = 'original';
  static final AppSkin original = AppSkin(id: originalId);

  final String id;
  final Map<AppSkinIconSlot, AppSkinIconAssets> icons;
  final Map<AppSkinArtworkSlot, AppSkinImage> artwork;

  static String _validateId(String value) {
    final isValid = RegExp(
      r'^[a-z][a-z0-9]*(?:[-_][a-z0-9]+)*$',
    ).hasMatch(value);
    if (!isValid) {
      throw ArgumentError.value(
        value,
        'id',
        'must be a stable lowercase identifier',
      );
    }
    return value;
  }
}

@immutable
class AppSkinCatalog {
  AppSkinCatalog(Iterable<AppSkin> additionalSkins) {
    final skins = <AppSkin>[AppSkin.original];
    final ids = <String>{AppSkin.originalId};
    for (final skin in additionalSkins) {
      if (!ids.add(skin.id)) {
        throw ArgumentError.value(
          skin.id,
          'additionalSkins',
          skin.id == AppSkin.originalId
              ? 'cannot replace the reserved original skin'
              : 'contains a duplicate skin id',
        );
      }
      skins.add(skin);
    }
    _skins = List.unmodifiable(skins);
    _skinsById = Map.unmodifiable({for (final skin in skins) skin.id: skin});
  }

  static final AppSkinCatalog builtIn = AppSkinCatalog([
    AppSkin(
      id: 'tidal',
      icons: {
        AppSkinIconSlot.home: _twemojiIcon('1f3e0'),
        AppSkinIconSlot.library: _twemojiIcon('1f4da'),
        AppSkinIconSlot.discover: _twemojiIcon('1f9ed'),
        AppSkinIconSlot.ai: _twemojiIcon('1f52e'),
        AppSkinIconSlot.profile: _twemojiIcon('1f3c4'),
      },
      artwork: {
        AppSkinArtworkSlot.pageBackground: AppSkinImage(
          asset: 'assets/purchase/wave.jpg',
        ),
        AppSkinArtworkSlot.navigation: AppSkinImage(
          asset: 'assets/purchase/wave.jpg',
        ),
      },
    ),
    AppSkin(
      id: 'botanical',
      icons: {
        AppSkinIconSlot.home: _twemojiIcon('1f3e1'),
        AppSkinIconSlot.library: _twemojiIcon('1f4d6'),
        AppSkinIconSlot.discover: _twemojiIcon('1f331'),
        AppSkinIconSlot.ai: _twemojiIcon('1fa84'),
        AppSkinIconSlot.profile: _twemojiIcon('1f9d1'),
      },
      artwork: {
        AppSkinArtworkSlot.pageBackground: AppSkinImage(
          asset: 'assets/purchase/irises.jpg',
        ),
        AppSkinArtworkSlot.navigation: AppSkinImage(
          asset: 'assets/purchase/irises.jpg',
        ),
      },
    ),
    AppSkin(
      id: 'celestial',
      icons: {
        AppSkinIconSlot.home: _twemojiIcon('1f3e0'),
        AppSkinIconSlot.library: _twemojiIcon('1f4da'),
        AppSkinIconSlot.discover: _twemojiIcon('1f52d'),
        AppSkinIconSlot.ai: _twemojiIcon('1f916'),
        AppSkinIconSlot.profile: _twemojiIcon('1f9d1-200d-1f680'),
      },
      artwork: {
        AppSkinArtworkSlot.pageBackground: AppSkinImage(
          asset: 'assets/skins/backgrounds/nasa-blue-marble.jpg',
        ),
        AppSkinArtworkSlot.navigation: AppSkinImage(
          asset: 'assets/skins/backgrounds/nasa-blue-marble.jpg',
        ),
      },
    ),
  ]);

  late final List<AppSkin> _skins;
  late final Map<String, AppSkin> _skinsById;

  List<AppSkin> get skins => _skins;

  AppSkin? find(String id) => _skinsById[id];

  AppSkin resolve(String? savedId) =>
      savedId == null ? AppSkin.original : find(savedId) ?? AppSkin.original;
}

AppSkinIconAssets _twemojiIcon(String codepoint) => AppSkinIconAssets(
  normal: AppSkinImage(asset: 'assets/skins/icons/twemoji/$codepoint.png'),
);
