// 文件说明：定义可审核、可安装的第三方主题包 v1 纯数据契约。
// 安全边界：严格字段白名单；不允许网络地址、脚本、字体、动画或阅读器配置。

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'app_skin.dart';

class ThemePackageFormatException implements Exception {
  const ThemePackageFormatException(this.message);

  final String message;

  @override
  String toString() => 'ThemePackageFormatException: $message';
}

@immutable
class ThemePackagePalette {
  ThemePackagePalette({
    required String primary,
    required String secondary,
    required String tertiary,
  }) : primary = _hex(primary, 'palette.primary'),
       secondary = _hex(secondary, 'palette.secondary'),
       tertiary = _hex(tertiary, 'palette.tertiary');

  final String primary;
  final String secondary;
  final String tertiary;

  static String _hex(String value, String field) {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      throw ThemePackageFormatException('$field must use #RRGGBB');
    }
    return value.toUpperCase();
  }
}

@immutable
class ThemePackage {
  const ThemePackage({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.author,
    required this.license,
    required this.rootDirectory,
    required this.preview,
    required this.skin,
    this.palette,
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final int version;
  final String name;
  final String description;
  final String author;
  final String license;
  final String rootDirectory;
  final AppSkinImage preview;
  final ThemePackagePalette? palette;
  final AppSkin skin;

  String get runtimeSkinId => 'community_$id';

  static ThemePackage parse(
    Map<String, Object?> manifest, {
    required String rootDirectory,
    Set<String> reservedIds = const <String>{},
  }) {
    _expectKeys(manifest, const {
      'schemaVersion',
      'id',
      'version',
      'name',
      'description',
      'author',
      'license',
      'preview',
      'palette',
      'icons',
      'artwork',
    }, 'manifest');

    final schemaVersion = _integer(manifest, 'schemaVersion');
    if (schemaVersion != currentSchemaVersion) {
      throw ThemePackageFormatException(
        'schemaVersion must be $currentSchemaVersion',
      );
    }
    final id = _text(manifest, 'id', max: 48);
    if (!RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id)) {
      throw const ThemePackageFormatException(
        'id must be a lowercase hyphenated slug',
      );
    }
    if (reservedIds.contains(id) || id == AppSkin.originalId) {
      throw ThemePackageFormatException('id "$id" is reserved');
    }
    final version = _integer(manifest, 'version');
    if (version <= 0) {
      throw const ThemePackageFormatException('version must be positive');
    }
    final name = _text(manifest, 'name', max: 60);
    final description = _text(
      manifest,
      'description',
      max: 300,
      allowEmpty: true,
    );
    final author = _text(manifest, 'author', max: 60);
    final license = _text(manifest, 'license', max: 120);
    final canonicalRoot = path.normalize(path.absolute(rootDirectory));
    if (!path.isAbsolute(rootDirectory) || canonicalRoot != rootDirectory) {
      throw const ThemePackageFormatException(
        'rootDirectory must be a canonical absolute path',
      );
    }

    final previewPath = _assetPath(manifest['preview'], 'preview');
    final paletteValue = manifest['palette'];
    final palette = paletteValue == null
        ? null
        : _parsePalette(_map(paletteValue, 'palette'));
    final icons = _parseIcons(manifest['icons'], rootDirectory: canonicalRoot);
    final artwork = _parseArtwork(
      manifest['artwork'],
      rootDirectory: canonicalRoot,
    );
    final skin = AppSkin(id: 'community_$id', icons: icons, artwork: artwork);

    return ThemePackage(
      id: id,
      version: version,
      name: name,
      description: description,
      author: author,
      license: license,
      rootDirectory: canonicalRoot,
      preview: _installedImage(previewPath, canonicalRoot),
      palette: palette,
      skin: skin,
    );
  }

  static ThemePackagePalette _parsePalette(Map<String, Object?> value) {
    _expectKeys(value, const {'primary', 'secondary', 'tertiary'}, 'palette');
    return ThemePackagePalette(
      primary: _text(value, 'primary', max: 7),
      secondary: _text(value, 'secondary', max: 7),
      tertiary: _text(value, 'tertiary', max: 7),
    );
  }

  static Map<AppSkinIconSlot, AppSkinIconAssets> _parseIcons(
    Object? value, {
    required String rootDirectory,
  }) {
    if (value == null) return const {};
    final map = _map(value, 'icons');
    final allowed = AppSkinIconSlot.values.map((slot) => slot.name).toSet();
    _expectKeys(map, allowed, 'icons');
    return {
      for (final entry in map.entries)
        _iconSlot(entry.key): _parseIconAssets(
          _map(entry.value, 'icons.${entry.key}'),
          'icons.${entry.key}',
          rootDirectory,
        ),
    };
  }

  static AppSkinIconAssets _parseIconAssets(
    Map<String, Object?> value,
    String field,
    String rootDirectory,
  ) {
    _expectKeys(value, const {'normal', 'selected'}, field);
    final normal = value['normal'];
    if (normal == null) {
      throw ThemePackageFormatException('$field.normal is required');
    }
    return AppSkinIconAssets(
      normal: _parseImage(
        _map(normal, '$field.normal'),
        '$field.normal',
        rootDirectory,
      ),
      selected: value['selected'] == null
          ? null
          : _parseImage(
              _map(value['selected'], '$field.selected'),
              '$field.selected',
              rootDirectory,
            ),
    );
  }

  static Map<AppSkinArtworkSlot, AppSkinImage> _parseArtwork(
    Object? value, {
    required String rootDirectory,
  }) {
    if (value == null) return const {};
    final map = _map(value, 'artwork');
    final allowed = AppSkinArtworkSlot.values.map((slot) => slot.name).toSet();
    _expectKeys(map, allowed, 'artwork');
    return {
      for (final entry in map.entries)
        _artworkSlot(entry.key): _parseImage(
          _map(entry.value, 'artwork.${entry.key}'),
          'artwork.${entry.key}',
          rootDirectory,
        ),
    };
  }

  static AppSkinImage _parseImage(
    Map<String, Object?> value,
    String field,
    String rootDirectory,
  ) {
    _expectKeys(value, const {'asset', 'darkAsset'}, field);
    final asset = _assetPath(value['asset'], '$field.asset');
    final darkValue = value['darkAsset'];
    final darkAsset = darkValue == null
        ? null
        : _assetPath(darkValue, '$field.darkAsset');
    return AppSkinImage.installed(
      path: path.join(rootDirectory, asset),
      darkPath: darkAsset == null ? null : path.join(rootDirectory, darkAsset),
    );
  }

  static AppSkinImage _installedImage(String asset, String rootDirectory) =>
      AppSkinImage.installed(path: path.join(rootDirectory, asset));

  Set<String> referencedRelativePaths() {
    String relative(AppSkinImage image, Brightness brightness) => path
        .relative(image.pathFor(brightness), from: rootDirectory)
        .replaceAll('\\', '/');
    final result = <String>{relative(preview, Brightness.light)};
    for (final assets in skin.icons.values) {
      for (final image in [assets.normal, assets.selected]) {
        if (image == null) continue;
        result.add(relative(image, Brightness.light));
        if (image.darkAsset != null) {
          result.add(relative(image, Brightness.dark));
        }
      }
    }
    for (final image in skin.artwork.values) {
      result.add(relative(image, Brightness.light));
      if (image.darkAsset != null) {
        result.add(relative(image, Brightness.dark));
      }
    }
    return Set.unmodifiable(result);
  }

  static String _assetPath(Object? value, String field) {
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw ThemePackageFormatException('$field must be a non-empty string');
    }
    final normalized = path.posix.normalize(value);
    final segments = value.split('/');
    final suffix = value.toLowerCase();
    final valid =
        value.startsWith('assets/') &&
        normalized == value &&
        !value.contains('\\') &&
        !value.contains('?') &&
        !value.contains('#') &&
        !segments.contains('..') &&
        !segments.contains('.') &&
        !segments.contains('') &&
        !Uri.parse(value).hasScheme &&
        const ['.png', '.jpg', '.jpeg', '.webp'].any(suffix.endsWith);
    if (!valid) {
      throw ThemePackageFormatException(
        '$field must be a canonical assets/ PNG, JPG, JPEG, or WebP path',
      );
    }
    return value;
  }

  static String _text(
    Map<String, Object?> map,
    String key, {
    required int max,
    bool allowEmpty = false,
  }) {
    final value = map[key];
    if (value is! String ||
        value != value.trim() ||
        (!allowEmpty && value.isEmpty) ||
        value.length > max ||
        value.contains(RegExp(r'[\u0000-\u001F\u007F]'))) {
      throw ThemePackageFormatException(
        '$key must be a trimmed string of at most $max characters',
      );
    }
    return value;
  }

  static int _integer(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw ThemePackageFormatException('$key must be an integer');
    }
    return value;
  }

  static Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map) {
      throw ThemePackageFormatException('$field must be an object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ThemePackageFormatException('$field keys must be strings');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static void _expectKeys(
    Map<String, Object?> map,
    Set<String> allowed,
    String field,
  ) {
    final unknown = map.keys.where((key) => !allowed.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw ThemePackageFormatException(
        '$field contains unsupported fields: ${unknown.join(', ')}',
      );
    }
  }

  static AppSkinIconSlot _iconSlot(String name) =>
      AppSkinIconSlot.values.firstWhere((slot) => slot.name == name);

  static AppSkinArtworkSlot _artworkSlot(String name) =>
      AppSkinArtworkSlot.values.firstWhere((slot) => slot.name == name);
}
