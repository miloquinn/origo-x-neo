// 文件说明：安全安装、完整性复核与移除本地主题包。
// 安全边界：先读 ZIP 中央目录再解压；严格白名单、体积、图片尺寸与哈希约束。

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../models/app_skin.dart';
import '../../models/theme_package.dart';
import 'theme_package_store_exception.dart';

class ThemePackageStore {
  ThemePackageStore({Directory? rootDirectory})
    : _providedRootDirectory = rootDirectory;

  static const int maxCompressedBytes = 10 * 1024 * 1024;
  static const int maxUncompressedBytes = 20 * 1024 * 1024;
  static const int maxEntries = 96;
  static const int maxImageDimension = 2048;
  static const int maxPreviewDimension = 1600;
  static const int maxIconDimension = 512;
  static const int maxTotalImagePixels = 24 * 1000 * 1000;
  static const int _maxManifestBytes = 64 * 1024;
  static const String _manifestName = 'manifest.json';
  static const String _receiptName = 'install.json';

  static final Set<String> _reservedIds = AppSkinCatalog.builtIn.skins
      .map((skin) => skin.id)
      .toSet();

  final Directory? _providedRootDirectory;

  bool get isSupported => true;

  Future<Directory> _root() async {
    final base =
        _providedRootDirectory ??
        Directory(
          path.join(
            (await getApplicationSupportDirectory()).path,
            'themes',
            'v1',
          ),
        );
    final canonical = Directory(path.normalize(path.absolute(base.path)));
    final type = await FileSystemEntity.type(
      canonical.path,
      followLinks: false,
    );
    if (type == FileSystemEntityType.link) {
      throw const ThemePackageStoreException(
        'Theme store root cannot be a symbolic link.',
      );
    }
    if (type == FileSystemEntityType.notFound) {
      await canonical.create(recursive: true);
    } else if (type != FileSystemEntityType.directory) {
      throw const ThemePackageStoreException(
        'Theme store root must be a directory.',
      );
    }
    return Directory(path.normalize(await canonical.resolveSymbolicLinks()));
  }

  Future<List<ThemePackage>> loadInstalled() async {
    final root = await _root();
    if (!await root.exists()) return const [];
    final latest = <String, ThemePackage>{};
    await for (final idEntity in root.list(followLinks: false)) {
      if (idEntity is! Directory ||
          path.basename(idEntity.path) == '.staging') {
        continue;
      }
      await for (final versionEntity in idEntity.list(followLinks: false)) {
        if (versionEntity is! Directory) continue;
        final package = await _loadVersion(root, versionEntity);
        if (package == null) continue;
        final current = latest[package.id];
        if (current == null || package.version > current.version) {
          latest[package.id] = package;
        }
      }
    }
    final result = latest.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return List.unmodifiable(result);
  }

  Future<ThemePackage?> findInstalled(
    String id, {
    int? version,
    bool allowVersionFallback = false,
  }) async {
    if (!RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(id) ||
        _reservedIds.contains(id) ||
        (version != null && version <= 0)) {
      return null;
    }
    final root = await _root();
    if (version != null) {
      final exact = await _loadVersion(
        root,
        Directory(path.join(root.path, id, '$version')),
      );
      if (exact != null) return exact;
      if (!allowVersionFallback) return null;
    }
    return (await loadInstalled()).where((item) => item.id == id).firstOrNull;
  }

  Future<ThemePackage> install(
    Uint8List bytes, {
    required String expectedSha256,
    required String expectedId,
    required int expectedVersion,
  }) async {
    if (bytes.length > maxCompressedBytes) {
      throw const ThemePackageStoreException('Theme ZIP exceeds 10 MiB.');
    }
    final normalizedHash = expectedSha256.toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedHash) ||
        sha256.convert(bytes).toString() != normalizedHash) {
      throw const ThemePackageStoreException('Theme ZIP SHA-256 mismatch.');
    }
    if (expectedVersion <= 0) {
      throw const ThemePackageStoreException(
        'Expected version must be positive.',
      );
    }

    final headers = _preflight(bytes);
    final archive = _decode(bytes);
    final files = <String, Uint8List>{};
    var actualBytes = 0;
    for (final item in archive.files) {
      if (!item.isFile) continue;
      if (item.isSymbolicLink) {
        throw const ThemePackageStoreException('Symbolic links are forbidden.');
      }
      final content = Uint8List.fromList(item.content as List<int>);
      actualBytes += content.length;
      if (actualBytes > maxUncompressedBytes) {
        throw const ThemePackageStoreException('Theme expands beyond 20 MiB.');
      }
      final declared = headers[item.name.toLowerCase()];
      if (declared == null || declared != content.length) {
        throw ThemePackageStoreException('ZIP size mismatch for ${item.name}.');
      }
      files[item.name] = content;
    }
    final manifestBytes = files[_manifestName];
    if (manifestBytes == null || manifestBytes.length > _maxManifestBytes) {
      throw const ThemePackageStoreException(
        'manifest.json is missing or too large.',
      );
    }

    final root = await _root();
    final staging = Directory(
      path.join(root.path, '.staging', _randomIdentifier()),
    );
    ThemePackage? parsed;
    Directory? publishedTarget;
    var stagingCreated = false;
    try {
      parsed = _parseManifest(manifestBytes, staging.path);
      if (parsed.id != expectedId || parsed.version != expectedVersion) {
        throw const ThemePackageStoreException(
          'Marketplace identity does not match the package manifest.',
        );
      }
      _validateReferences(parsed, files.keys.toSet());
      await _validateImages(parsed, files);

      final target = Directory(
        path.join(root.path, parsed.id, '${parsed.version}'),
      );
      if (await target.exists()) {
        throw const ThemePackageStoreException(
          'This immutable theme version is already installed.',
        );
      }
      final stagingParent = await _ensureChildDirectory(root, '.staging');
      final idParent = await _ensureChildDirectory(root, parsed.id);
      await _assertSafeDirectory(root, stagingParent);
      await _assertSafeDirectory(root, idParent);
      await staging.create(recursive: false);
      stagingCreated = true;
      final hashes = <String, String>{};
      for (final entry in files.entries) {
        final output = File(path.join(staging.path, entry.key));
        await output.parent.create(recursive: true);
        await output.writeAsBytes(entry.value, flush: true);
        hashes[entry.key] = sha256.convert(entry.value).toString();
      }
      final receipt = <String, Object?>{
        'schemaVersion': 1,
        'packageSha256': normalizedHash,
        'id': parsed.id,
        'version': parsed.version,
        'files': hashes,
      };
      await File(
        path.join(staging.path, _receiptName),
      ).writeAsString(jsonEncode(receipt), flush: true);
      await _assertSafeDirectory(root, staging.parent);
      await _assertSafeDirectory(root, target.parent);
      if (await FileSystemEntity.type(target.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        throw const ThemePackageStoreException(
          'This immutable theme version is already installed.',
        );
      }
      try {
        await staging.rename(target.path);
        publishedTarget = target;
      } on FileSystemException catch (error) {
        throw ThemePackageStoreException(
          'Could not publish immutable theme version: ${error.message}',
        );
      }
      final installed = await _loadVersion(root, target);
      if (installed == null) {
        await target.delete(recursive: true);
        publishedTarget = null;
        throw const ThemePackageStoreException(
          'Installed theme failed its integrity check.',
        );
      }
      return installed;
    } catch (_) {
      final target = publishedTarget;
      if (target != null &&
          await _isSafeDirectory(root, target.parent) &&
          await FileSystemEntity.type(target.path, followLinks: false) ==
              FileSystemEntityType.directory) {
        await target.delete(recursive: true);
      }
      rethrow;
    } finally {
      if (stagingCreated &&
          await _isSafeDirectory(root, staging.parent) &&
          await FileSystemEntity.type(staging.path, followLinks: false) ==
              FileSystemEntityType.directory) {
        await staging.delete(recursive: true);
      }
    }
  }

  Future<void> remove(ThemePackage package) async {
    final root = await _root();
    final expected = path.join(root.path, package.id, '${package.version}');
    if (package.rootDirectory != expected ||
        _reservedIds.contains(package.id) ||
        !RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$').hasMatch(package.id) ||
        package.version <= 0) {
      throw const ThemePackageStoreException(
        'Refusing to remove a theme outside the managed store.',
      );
    }
    final directory = Directory(expected);
    final idDirectory = directory.parent;
    await _assertSafeDirectory(root, idDirectory);
    final entityType = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (entityType == FileSystemEntityType.link) {
      throw const ThemePackageStoreException(
        'Refusing to remove a linked theme directory.',
      );
    }
    if (entityType == FileSystemEntityType.directory) {
      await directory.delete(recursive: true);
    }
    final parent = directory.parent;
    if (await parent.exists() && await parent.list().isEmpty) {
      await parent.delete();
    }
  }

  Map<String, int> _preflight(Uint8List bytes) {
    try {
      final directory = ZipDirectory.read(InputStream(bytes));
      if (directory.fileHeaders.isEmpty ||
          directory.fileHeaders.length > maxEntries) {
        throw const ThemePackageStoreException(
          'Theme ZIP must contain between 1 and 96 entries.',
        );
      }
      final folded = <String>{};
      final sizes = <String, int>{};
      var total = 0;
      for (final header in directory.fileHeaders) {
        final name = header.filename;
        final directoryEntry = name.endsWith('/');
        _validateZipPath(name, directoryEntry: directoryEntry);
        final foldedName = name.toLowerCase().replaceFirst(RegExp(r'/$'), '');
        if (!folded.add(foldedName)) {
          throw ThemePackageStoreException(
            'ZIP contains duplicate folded path: $name.',
          );
        }
        if ((header.generalPurposeBitFlag & 0x1) != 0) {
          throw const ThemePackageStoreException(
            'Encrypted ZIP entries are forbidden.',
          );
        }
        final mode = (header.externalFileAttributes ?? 0) >> 16;
        if ((mode & 0xF000) == 0xA000) {
          throw const ThemePackageStoreException(
            'Symbolic links are forbidden.',
          );
        }
        final method = header.compressionMethod;
        if (method != ZipFile.zipCompressionStore &&
            method != ZipFile.zipCompressionDeflate) {
          throw ThemePackageStoreException(
            'Unsupported ZIP compression method for $name.',
          );
        }
        final size = header.uncompressedSize;
        final compressed = header.compressedSize;
        if (size == null || compressed == null || size < 0 || compressed < 0) {
          throw ThemePackageStoreException('Invalid ZIP sizes for $name.');
        }
        total += size;
        if (total > maxUncompressedBytes) {
          throw const ThemePackageStoreException(
            'Theme expands beyond 20 MiB.',
          );
        }
        if (!directoryEntry) sizes[name.toLowerCase()] = size;
      }
      return sizes;
    } on ThemePackageStoreException {
      rethrow;
    } catch (error) {
      throw ThemePackageStoreException('Invalid ZIP directory: $error');
    }
  }

  Archive _decode(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes, verify: true);
    } catch (error) {
      throw ThemePackageStoreException('Could not decode theme ZIP: $error');
    }
  }

  void _validateZipPath(String value, {required bool directoryEntry}) {
    if (value.isEmpty ||
        value.startsWith('/') ||
        value.contains('\\') ||
        value.contains('?') ||
        value.contains('#') ||
        Uri.parse(value).hasScheme ||
        value.split('/').contains('..') ||
        value.split('/').contains('.') ||
        value.contains('//') ||
        path.posix.normalize(value) != value.replaceFirst(RegExp(r'/$'), '')) {
      throw ThemePackageStoreException('Unsafe ZIP path: $value.');
    }
    final clean = value.replaceFirst(RegExp(r'/$'), '');
    if (directoryEntry) {
      if (clean != 'assets' && !clean.startsWith('assets/')) {
        throw ThemePackageStoreException('Unsupported ZIP directory: $value.');
      }
      return;
    }
    final lower = clean.toLowerCase();
    final isStaticRoot =
        clean == _manifestName ||
        clean == 'LICENSE.txt' ||
        clean == 'README.md';
    final isImage =
        clean.startsWith('assets/') &&
        const ['.png', '.jpg', '.jpeg', '.webp'].any(lower.endsWith);
    if (!isStaticRoot && !isImage) {
      throw ThemePackageStoreException('Unsupported ZIP entry: $value.');
    }
  }

  ThemePackage _parseManifest(Uint8List bytes, String rootDirectory) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (decoded is! Map) {
        throw const ThemePackageFormatException('manifest must be an object');
      }
      return ThemePackage.parse(
        decoded.cast<String, Object?>(),
        rootDirectory: path.normalize(path.absolute(rootDirectory)),
        reservedIds: _reservedIds,
      );
    } on ThemePackageFormatException catch (error) {
      throw ThemePackageStoreException(error.message);
    } catch (error) {
      throw ThemePackageStoreException('Invalid manifest.json: $error');
    }
  }

  void _validateReferences(ThemePackage package, Set<String> available) {
    for (final reference in package.referencedRelativePaths()) {
      if (!available.contains(reference)) {
        throw ThemePackageStoreException(
          'Manifest references missing asset: $reference.',
        );
      }
    }
  }

  Future<void> _validateImages(
    ThemePackage package,
    Map<String, Uint8List> files,
  ) async {
    final iconPaths = <String>{};
    for (final assets in package.skin.icons.values) {
      for (final image in [assets.normal, assets.selected]) {
        if (image == null) continue;
        iconPaths.addAll(_relativeVariants(package, image));
      }
    }
    final previewPath = package.referencedRelativePaths().firstWhere(
      (value) =>
          path.join(package.rootDirectory, value) == package.preview.asset,
    );
    var totalPixels = 0;
    for (final entry in files.entries) {
      if (!entry.key.startsWith('assets/')) continue;
      final dimensions = _imageDimensions(entry.value, entry.key);
      totalPixels += dimensions.width * dimensions.height;
      if (totalPixels > maxTotalImagePixels) {
        throw const ThemePackageStoreException(
          'Theme images exceed 24 million decoded pixels.',
        );
      }
      final limit = entry.key == previewPath
          ? maxPreviewDimension
          : iconPaths.contains(entry.key)
          ? maxIconDimension
          : maxImageDimension;
      if (dimensions.width > limit || dimensions.height > limit) {
        throw ThemePackageStoreException(
          '${entry.key} exceeds its ${limit}px dimension limit.',
        );
      }
      if (iconPaths.contains(entry.key) &&
          dimensions.width != dimensions.height) {
        throw ThemePackageStoreException('${entry.key} must be square.');
      }
      ui.Codec? codec;
      ui.Image? decoded;
      try {
        codec = await ui.instantiateImageCodec(entry.value);
        final frame = await codec.getNextFrame();
        decoded = frame.image;
        if (decoded.width != dimensions.width ||
            decoded.height != dimensions.height) {
          throw ThemePackageStoreException(
            '${entry.key} decoded dimensions do not match its header.',
          );
        }
      } on ThemePackageStoreException {
        rethrow;
      } catch (_) {
        throw ThemePackageStoreException(
          '${entry.key} is not a decodable image.',
        );
      } finally {
        decoded?.dispose();
        codec?.dispose();
      }
    }
  }

  Set<String> _relativeVariants(ThemePackage package, AppSkinImage image) {
    final result = <String>{
      path
          .relative(image.asset, from: package.rootDirectory)
          .replaceAll('\\', '/'),
    };
    if (image.darkAsset case final dark?) {
      result.add(
        path.relative(dark, from: package.rootDirectory).replaceAll('\\', '/'),
      );
    }
    return result;
  }

  Future<ThemePackage?> _loadVersion(
    Directory root,
    Directory directory,
  ) async {
    try {
      if (!await _isSafeDirectory(root, directory.parent)) return null;
      if (!await directory.exists() ||
          await FileSystemEntity.type(directory.path, followLinks: false) !=
              FileSystemEntityType.directory) {
        return null;
      }
      final receiptFile = File(path.join(directory.path, _receiptName));
      if (!await receiptFile.exists()) return null;
      final receiptValue = jsonDecode(await receiptFile.readAsString());
      if (receiptValue is! Map) return null;
      final receipt = receiptValue.cast<String, Object?>();
      if (receipt.keys.toSet().difference(const {
            'schemaVersion',
            'packageSha256',
            'id',
            'version',
            'files',
          }).isNotEmpty ||
          receipt['schemaVersion'] != 1 ||
          receipt['packageSha256'] is! String ||
          !RegExp(
            r'^[0-9a-f]{64}$',
          ).hasMatch(receipt['packageSha256']! as String) ||
          receipt['id'] != path.basename(directory.parent.path) ||
          '${receipt['version']}' != path.basename(directory.path) ||
          receipt['files'] is! Map) {
        return null;
      }
      final hashes = (receipt['files'] as Map).cast<String, Object?>();
      final seen = <String>{};
      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        final type = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );
        if (type == FileSystemEntityType.link) return null;
        if (type != FileSystemEntityType.file) continue;
        final relative = normalizeThemePackageRelativePath(
          path.relative(entity.path, from: directory.path),
        );
        if (relative == _receiptName) continue;
        seen.add(relative);
      }
      if (seen.length != hashes.length || !seen.containsAll(hashes.keys)) {
        return null;
      }
      for (final entry in hashes.entries) {
        if (entry.value is! String ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.value! as String)) {
          return null;
        }
        final file = File(path.join(directory.path, entry.key));
        if (await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file) {
          return null;
        }
        final digest = await sha256.bind(file.openRead()).first;
        if (digest.toString() != entry.value) return null;
      }
      final manifestFile = File(path.join(directory.path, _manifestName));
      final package = _parseManifest(
        await manifestFile.readAsBytes(),
        directory.path,
      );
      if (package.id != receipt['id'] ||
          package.version != receipt['version']) {
        return null;
      }
      _validateReferences(package, seen);
      return package;
    } catch (_) {
      return null;
    }
  }

  String _randomIdentifier() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<Directory> _ensureChildDirectory(Directory root, String name) async {
    await _assertSafeDirectory(root, root);
    final child = Directory(path.join(root.path, name));
    final type = await FileSystemEntity.type(child.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await child.create(recursive: false);
    } else if (type != FileSystemEntityType.directory) {
      throw ThemePackageStoreException(
        'Managed theme path is not a directory: $name.',
      );
    }
    await _assertSafeDirectory(root, child);
    return child;
  }

  Future<void> _assertSafeDirectory(Directory root, Directory directory) async {
    if (!await _isSafeDirectory(root, directory)) {
      throw const ThemePackageStoreException(
        'Managed theme directory escaped the store root.',
      );
    }
  }

  Future<bool> _isSafeDirectory(Directory root, Directory directory) async {
    if (await FileSystemEntity.type(directory.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      return false;
    }
    final resolvedRoot = path.normalize(await root.resolveSymbolicLinks());
    final resolvedDirectory = path.normalize(
      await directory.resolveSymbolicLinks(),
    );
    return resolvedDirectory == resolvedRoot ||
        path.isWithin(resolvedRoot, resolvedDirectory);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

({int width, int height}) _imageDimensions(Uint8List bytes, String name) {
  try {
    if (bytes.length >= 24 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return (width: _uint32Big(bytes, 16), height: _uint32Big(bytes, 20));
    }
    if (bytes.length >= 12 && bytes[0] == 0xff && bytes[1] == 0xd8) {
      var offset = 2;
      while (offset + 9 < bytes.length) {
        if (bytes[offset] != 0xff) {
          offset++;
          continue;
        }
        final marker = bytes[offset + 1];
        offset += 2;
        if (marker == 0xd8 || marker == 0xd9) continue;
        if (offset + 2 > bytes.length) break;
        final length = (bytes[offset] << 8) | bytes[offset + 1];
        if (length < 2 || offset + length > bytes.length) break;
        if ({
          0xc0,
          0xc1,
          0xc2,
          0xc3,
          0xc5,
          0xc6,
          0xc7,
          0xc9,
          0xca,
          0xcb,
          0xcd,
          0xce,
          0xcf,
        }.contains(marker)) {
          return (
            width: (bytes[offset + 5] << 8) | bytes[offset + 6],
            height: (bytes[offset + 3] << 8) | bytes[offset + 4],
          );
        }
        offset += length;
      }
    }
    if (bytes.length >= 30 &&
        ascii.decode(bytes.sublist(0, 4)) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12)) == 'WEBP') {
      final kind = ascii.decode(bytes.sublist(12, 16));
      if (kind == 'VP8X') {
        return (
          width: 1 + _uint24Little(bytes, 24),
          height: 1 + _uint24Little(bytes, 27),
        );
      }
      if (kind == 'VP8L' && bytes[20] == 0x2f) {
        return (
          width: 1 + bytes[21] + ((bytes[22] & 0x3f) << 8),
          height:
              1 +
              ((bytes[22] & 0xc0) >> 6) +
              (bytes[23] << 2) +
              ((bytes[24] & 0x0f) << 10),
        );
      }
      if (kind == 'VP8 ' &&
          bytes[23] == 0x9d &&
          bytes[24] == 0x01 &&
          bytes[25] == 0x2a) {
        return (
          width: (bytes[26] | (bytes[27] << 8)) & 0x3fff,
          height: (bytes[28] | (bytes[29] << 8)) & 0x3fff,
        );
      }
    }
  } catch (_) {
    // Converted to a stable validation error below.
  }
  throw ThemePackageStoreException('Invalid or unsupported image: $name.');
}

int _uint32Big(Uint8List bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

int _uint24Little(Uint8List bytes, int offset) =>
    bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);

/// ZIP manifests and receipts always use POSIX separators on every platform.
String normalizeThemePackageRelativePath(String value) =>
    value.replaceAll('\\', '/');
