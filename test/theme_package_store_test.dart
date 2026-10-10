import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/services/themes/theme_package_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;
  late ThemePackageStore store;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('theme-package-store-');
    store = ThemePackageStore(rootDirectory: sandbox);
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  test('normalizes Windows receipt keys to the ZIP POSIX convention', () {
    expect(
      normalizeThemePackageRelativePath(r'assets\icons\home.png'),
      'assets/icons/home.png',
    );
  });

  test('installs and reloads the canonical server theme template', () async {
    final bytes = await File(
      'test/fixtures/theme-template-v1.zip',
    ).readAsBytes();
    const expectedSha256 =
        '8d47127b561065318f01b5e2f548556dac8c41c6712ccec6f365e1da8a187867';
    expect(sha256.convert(bytes).toString(), expectedSha256);

    final package = await store.install(
      bytes,
      expectedSha256: expectedSha256,
      expectedId: 'coastal-studio-template',
      expectedVersion: 1,
    );

    expect(package.skin.icons.keys.toSet(), AppSkinIconSlot.values.toSet());
    for (final slot in AppSkinIconSlot.values) {
      final icon = package.skin.icons[slot]!;
      expect(icon.selected, isNotNull, reason: '$slot selected icon');
      for (final image in [icon.normal, icon.selected!]) {
        expect(image.darkAsset, isNotNull, reason: '$slot dark icon');
        for (final brightness in Brightness.values) {
          final png = await File(image.stablePathFor(brightness)).readAsBytes();
          expect(png.length, greaterThan(25), reason: '$slot $brightness');
          expect(
            png[25],
            anyOf(4, 6),
            reason: '$slot $brightness must retain a PNG alpha channel',
          );
        }
      }
    }

    for (final slot in AppSkinArtworkSlot.values) {
      final artwork = package.skin.artwork[slot]!;
      expect(
        artwork.stablePathFor(Brightness.light),
        endsWith(path.join('assets', 'background.jpg')),
      );
      expect(
        artwork.stablePathFor(Brightness.dark),
        endsWith(path.join('assets', 'background-dark.jpg')),
      );
    }

    final reloaded = (await store.loadInstalled()).single;
    expect(reloaded.id, 'coastal-studio-template');
    expect(reloaded.version, 1);
    expect(
      reloaded.referencedRelativePaths(),
      package.referencedRelativePaths(),
    );
  });

  test(
    'installs atomically, reloads verified versions and resolves fallback',
    () async {
      final firstBytes = _packageZip(version: 1);
      final first = await store.install(
        firstBytes,
        expectedSha256: sha256.convert(firstBytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      );
      final secondBytes = _packageZip(version: 2);
      final second = await store.install(
        secondBytes,
        expectedSha256: sha256.convert(secondBytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 2,
      );

      expect(
        await File('${first.rootDirectory}/install.json').exists(),
        isTrue,
      );
      expect((await store.loadInstalled()).single.version, 2);
      expect(
        (await store.findInstalled('paper-garden', version: 1))?.version,
        1,
      );
      expect(await store.findInstalled('paper-garden', version: 99), isNull);
      expect(
        (await store.findInstalled(
          'paper-garden',
          version: 99,
          allowVersionFallback: true,
        ))?.version,
        2,
      );

      await store.remove(second);
      expect((await store.loadInstalled()).single.version, 1);
    },
  );

  test(
    'rejects hash and marketplace identity mismatches without residue',
    () async {
      final bytes = _packageZip();
      for (final invocation in <Future<void> Function()>[
        () async {
          await store.install(
            bytes,
            expectedSha256: '0' * 64,
            expectedId: 'paper-garden',
            expectedVersion: 1,
          );
        },
        () async {
          await store.install(
            bytes,
            expectedSha256: sha256.convert(bytes).toString(),
            expectedId: 'another-theme',
            expectedVersion: 1,
          );
        },
        () async {
          await store.install(
            bytes,
            expectedSha256: sha256.convert(bytes).toString(),
            expectedId: 'paper-garden',
            expectedVersion: 2,
          );
        },
      ]) {
        await expectLater(
          invocation(),
          throwsA(isA<ThemePackageStoreException>()),
        );
      }
      expect(await store.loadInstalled(), isEmpty);
    },
  );

  test(
    'rejects traversal, folded duplicates, symlinks and non-static files',
    () async {
      final malicious = <Uint8List>[
        _zip({..._files(), '../escape.png': _png}),
        _zip({..._files(), 'assets/Icon.png': _png}),
        _zip({
          ..._files(),
          'assets/theme.js': Uint8List.fromList([1]),
        }),
        _zip(_files(), symbolicLink: 'assets/link.png'),
      ];

      for (final bytes in malicious) {
        await expectLater(
          store.install(
            bytes,
            expectedSha256: sha256.convert(bytes).toString(),
            expectedId: 'paper-garden',
            expectedVersion: 1,
          ),
          throwsA(isA<ThemePackageStoreException>()),
        );
      }
      expect(await File('${sandbox.path}/escape.png').exists(), isFalse);
      expect(await store.loadInstalled(), isEmpty);
    },
  );

  test(
    'rejects missing references, malformed images and oversized headers',
    () async {
      final missing = _files()..remove('assets/icon.png');
      final malformed = _files()..['assets/icon.png'] = Uint8List(24);
      final oversized = _files()
        ..['assets/unreferenced.png'] = _pngHeader(width: 4096, height: 1);

      for (final files in [missing, malformed, oversized]) {
        final bytes = _zip(files);
        await expectLater(
          store.install(
            bytes,
            expectedSha256: sha256.convert(bytes).toString(),
            expectedId: 'paper-garden',
            expectedVersion: 1,
          ),
          throwsA(isA<ThemePackageStoreException>()),
        );
      }
    },
  );

  test('enforces the 96-entry and 64-KiB manifest boundaries', () async {
    final tooMany = _files();
    for (var index = 0; index < 92; index++) {
      tooMany['assets/extra-$index.png'] = _png;
    }
    final oversizedManifest = _files();
    final manifest = oversizedManifest['manifest.json']!;
    oversizedManifest['manifest.json'] = Uint8List.fromList([
      ...manifest,
      ...List<int>.filled(64 * 1024 + 1 - manifest.length, 0x20),
    ]);

    for (final files in [tooMany, oversizedManifest]) {
      final bytes = _zip(files);
      await expectLater(
        store.install(
          bytes,
          expectedSha256: sha256.convert(bytes).toString(),
          expectedId: 'paper-garden',
          expectedVersion: 1,
        ),
        throwsA(isA<ThemePackageStoreException>()),
      );
    }
  });

  test(
    'failed attempt can retry; immutable versions cannot be replaced',
    () async {
      final broken = _packageZip(extraManifest: {'code': 'forbidden'});
      await expectLater(
        store.install(
          broken,
          expectedSha256: sha256.convert(broken).toString(),
          expectedId: 'paper-garden',
          expectedVersion: 1,
        ),
        throwsA(isA<ThemePackageStoreException>()),
      );

      final valid = _packageZip();
      await store.install(
        valid,
        expectedSha256: sha256.convert(valid).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      );
      final changed = _packageZip(extraManifest: {'description': 'Changed'});
      await expectLater(
        store.install(
          changed,
          expectedSha256: sha256.convert(changed).toString(),
          expectedId: 'paper-garden',
          expectedVersion: 1,
        ),
        throwsA(isA<ThemePackageStoreException>()),
      );
      expect((await store.loadInstalled()).single.version, 1);
    },
  );

  test(
    'corrupted installed files can be replaced by the verified same version',
    () async {
      final bytes = _packageZip();
      final package = await store.install(
        bytes,
        expectedSha256: sha256.convert(bytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      );
      await File(
        path.join(package.rootDirectory, 'assets', 'icon.png'),
      ).writeAsBytes([1, 2, 3], flush: true);

      expect(await store.loadInstalled(), isEmpty);
      expect(
        await store.findInstalled(
          'paper-garden',
          version: 1,
          allowVersionFallback: false,
        ),
        isNull,
      );

      final invalidReplacement = _packageZip(
        extraManifest: {'code': 'forbidden'},
      );
      await expectLater(
        store.install(
          invalidReplacement,
          expectedSha256: sha256.convert(invalidReplacement).toString(),
          expectedId: 'paper-garden',
          expectedVersion: 1,
        ),
        throwsA(isA<ThemePackageStoreException>()),
      );
      expect(
        await File(
          path.join(package.rootDirectory, 'assets', 'icon.png'),
        ).readAsBytes(),
        [1, 2, 3],
      );

      final recovered = await store.install(
        bytes,
        expectedSha256: sha256.convert(bytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      );
      expect(recovered.version, 1);
      expect((await store.loadInstalled()).single.version, 1);
      expect(
        await File(
          path.join(recovered.rootDirectory, 'assets', 'icon.png'),
        ).readAsBytes(),
        _png,
      );
      final staging = Directory(path.join(sandbox.path, '.staging'));
      expect(await staging.list().toList(), isEmpty);
    },
  );

  test('rejects a staging symlink without writing outside the store', () async {
    final outside = await Directory.systemTemp.createTemp(
      'theme-package-outside-',
    );
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    final sentinel = File(path.join(outside.path, 'sentinel.txt'));
    await sentinel.writeAsString('keep');
    await Link(path.join(sandbox.path, '.staging')).create(outside.path);
    final bytes = _packageZip();

    await expectLater(
      store.install(
        bytes,
        expectedSha256: sha256.convert(bytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      ),
      throwsA(isA<ThemePackageStoreException>()),
    );
    expect(await sentinel.readAsString(), 'keep');
    expect(
      await File(path.join(outside.path, 'manifest.json')).exists(),
      isFalse,
    );
  });

  test('rejects a theme store root that is itself a symlink', () async {
    final outside = await Directory.systemTemp.createTemp(
      'theme-package-root-outside-',
    );
    final linkedRoot = Link(path.join(sandbox.path, 'linked-root'));
    await linkedRoot.create(outside.path);
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });

    final linkedStore = ThemePackageStore(
      rootDirectory: Directory(linkedRoot.path),
    );
    await expectLater(
      linkedStore.loadInstalled(),
      throwsA(isA<ThemePackageStoreException>()),
    );
  });

  test('rejects id ancestor symlinks for install, find and remove', () async {
    final bytes = _packageZip();
    final package = await store.install(
      bytes,
      expectedSha256: sha256.convert(bytes).toString(),
      expectedId: 'paper-garden',
      expectedVersion: 1,
    );
    final idDirectory = Directory(path.join(sandbox.path, 'paper-garden'));
    await idDirectory.delete(recursive: true);
    final outside = await Directory.systemTemp.createTemp(
      'theme-package-id-outside-',
    );
    addTearDown(() async {
      if (await outside.exists()) await outside.delete(recursive: true);
    });
    final sentinel = File(path.join(outside.path, 'sentinel.txt'));
    await sentinel.writeAsString('keep');
    await Link(idDirectory.path).create(outside.path);

    expect(
      await store.findInstalled(
        'paper-garden',
        version: 1,
        allowVersionFallback: false,
      ),
      isNull,
    );
    final update = _packageZip(version: 2);
    await expectLater(
      store.install(
        update,
        expectedSha256: sha256.convert(update).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 2,
      ),
      throwsA(isA<ThemePackageStoreException>()),
    );
    await expectLater(
      store.remove(package),
      throwsA(isA<ThemePackageStoreException>()),
    );
    expect(await sentinel.readAsString(), 'keep');
  });
}

Uint8List _packageZip({int version = 1, Map<String, Object?>? extraManifest}) {
  final files = _files(version: version, extraManifest: extraManifest);
  return _zip(files);
}

Map<String, Uint8List> _files({
  int version = 1,
  Map<String, Object?>? extraManifest,
}) {
  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'id': 'paper-garden',
    'version': version,
    'name': 'Paper Garden',
    'description': 'A calm paper garden.',
    'author': 'Theme Maker',
    'license': 'CC BY 4.0',
    'preview': 'assets/preview.png',
    'palette': {
      'primary': '#123456',
      'secondary': '#ABCDEF',
      'tertiary': '#998877',
    },
    'icons': {
      'home': {
        'normal': {'asset': 'assets/icon.png'},
      },
    },
    'artwork': {
      'pageBackground': {'asset': 'assets/background.png'},
    },
    ...?extraManifest,
  };
  return {
    'manifest.json': Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
    'assets/preview.png': _png,
    'assets/icon.png': _png,
    'assets/background.png': _png,
    'README.md': Uint8List.fromList(utf8.encode('Theme readme')),
    'LICENSE.txt': Uint8List.fromList(utf8.encode('CC BY 4.0')),
  };
}

Uint8List _zip(Map<String, Uint8List> files, {String? symbolicLink}) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  if (symbolicLink != null) {
    final link = ArchiveFile(symbolicLink, 0, Uint8List(0))
      ..isSymbolicLink = true
      ..mode = 0xA000;
    archive.addFile(link);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

Uint8List _pngHeader({required int width, required int height}) {
  final bytes = Uint8List(24);
  bytes.setAll(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  final data = ByteData.sublistView(bytes);
  data.setUint32(16, width);
  data.setUint32(20, height);
  return bytes;
}
