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
  close,
  forward,
  settings,
  refresh,
  add,
  share,
  delete,
  check,
  bookmark,
  catalog,
  readAloud,
  locate,
  play,
  pause,
  stop,
  previous,
  next,
  rewind,
  fastForward,
  speed,
  timer,
  volume,
  volumeOff,
  expand,
  collapse,
  remove,
  filter,
  sort,
  layoutGrid,
  layoutList,
  download,
  upload,
  folder,
  createFolder,
  moveFolder,
  edit,
  copy,
  note,
  highlight,
  history,
  help,
  info,
  cloud,
  sync,
  save,
  restore,
  link,
  palette,
  font,
  image,
  device,
  key,
  extension,
  network,
}

enum AppSkinArtworkSlot { pageBackground, navigation }

enum AppSkinImageSource { bundledAsset, installedFile }

@immutable
class AppSkinImage {
  AppSkinImage({required String asset, String? darkAsset})
    : source = AppSkinImageSource.bundledAsset,
      asset = _validateAsset(asset, field: 'asset'),
      darkAsset = darkAsset == null
          ? null
          : _validateAsset(darkAsset, field: 'darkAsset');

  AppSkinImage.file({required String path, String? darkPath})
    : source = AppSkinImageSource.installedFile,
      asset = _validateFile(path, field: 'path'),
      darkAsset = darkPath == null
          ? null
          : _validateFile(darkPath, field: 'darkPath');

  factory AppSkinImage.installed({required String path, String? darkPath}) =>
      AppSkinImage.file(path: path, darkPath: darkPath);

  final AppSkinImageSource source;
  final String asset;
  final String? darkAsset;

  String pathFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkAsset ?? asset : asset;

  String stablePathFor(Brightness brightness) => pathFor(brightness);

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

  static String _validateFile(String value, {required String field}) {
    final lower = value.toLowerCase();
    final unixSegments = value.split('/');
    final windowsSegments = value.split('\\');
    final isCanonicalUnix =
        value.startsWith('/') &&
        !value.contains('\\') &&
        !value.contains('//') &&
        !unixSegments.contains('..') &&
        !unixSegments.contains('.') &&
        !unixSegments.skip(1).contains('');
    final isCanonicalWindows =
        RegExp(r'^[A-Za-z]:\\[^\\]').hasMatch(value) &&
        !value.contains('/') &&
        !value.contains('\\\\') &&
        !windowsSegments.contains('..') &&
        !windowsSegments.contains('.') &&
        !windowsSegments.skip(1).contains('');
    final isCanonical =
        (isCanonicalUnix || isCanonicalWindows) &&
        !value.contains('?') &&
        !value.contains('#');
    final hasSupportedSuffix = const [
      '.png',
      '.webp',
      '.jpg',
      '.jpeg',
    ].any(lower.endsWith);
    if (!isCanonical || !hasSupportedSuffix) {
      throw ArgumentError.value(
        value,
        field,
        'must be a canonical absolute PNG, WebP, JPG, or JPEG file path',
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
    _collectionSkin('tidal'),
    _collectionSkin('botanical'),
    _collectionSkin('celestial'),
  ]);

  late final List<AppSkin> _skins;
  late final Map<String, AppSkin> _skinsById;

  List<AppSkin> get skins => _skins;

  AppSkin? find(String id) => _skinsById[id];

  AppSkin resolve(String? savedId) =>
      savedId == null ? AppSkin.original : find(savedId) ?? AppSkin.original;
}

AppSkin _collectionSkin(String id) {
  final iconRoot = 'assets/skins/collections/$id/icons';
  final backgroundRoot = 'assets/skins/backgrounds/$id';
  return AppSkin(
    id: id,
    icons: {
      for (final slot in AppSkinIconSlot.values)
        slot: AppSkinIconAssets(
          normal: AppSkinImage(
            asset: '$iconRoot/${slot.name}.png',
            darkAsset: '$iconRoot/${slot.name}-dark.png',
          ),
          selected: AppSkinImage(
            asset: '$iconRoot/${slot.name}-selected.png',
            darkAsset: '$iconRoot/${slot.name}-selected-dark.png',
          ),
        ),
    },
    artwork: {
      for (final slot in AppSkinArtworkSlot.values)
        slot: AppSkinImage(
          asset: '$backgroundRoot.jpg',
          darkAsset: '$backgroundRoot-dark.jpg',
        ),
    },
  );
}
