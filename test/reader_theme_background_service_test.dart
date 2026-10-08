import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:xxread/core/reader/reader_background_image_reference.dart';
import 'package:xxread/core/reader/reader_custom_theme.dart';
import 'package:xxread/services/core/reader_theme_background_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const filePickerChannel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
  );
  late Directory sandbox;
  late Directory currentSupport;
  late Directory currentBackgrounds;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('reader-theme-background-');
    currentSupport = Directory(
      path.join(sandbox.path, 'current-container', 'Application Support'),
    );
    currentBackgrounds = Directory(
      path.join(
        currentSupport.path,
        ReaderBackgroundImageReference.directoryName,
      ),
    );
    await currentBackgrounds.create(recursive: true);
  });

  tearDown(() async {
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  ReaderThemeBackgroundService service() => ReaderThemeBackgroundService(
    supportDirectoryProvider: () async => currentSupport,
  );

  test(
    'picked image is copied into support storage with a stable reference',
    () async {
      final source = File(path.join(sandbox.path, 'picker-cache.webp'));
      final expectedBytes = Uint8List.fromList([82, 73, 70, 70, 1, 2, 3]);
      await source.writeAsBytes(expectedBytes);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(filePickerChannel, (call) async {
            expect(call.method, 'custom');
            return [
              {
                'name': 'paper.webp',
                'path': source.path,
                'bytes': expectedBytes,
                'size': expectedBytes.length,
              },
            ];
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(filePickerChannel, null),
      );

      final reference = await service().pickAndStore();

      expect(reference, isNotNull);
      expect(
        ReaderBackgroundImageReference.managedReference(reference!),
        reference,
      );
      expect(path.isAbsolute(reference), isFalse);
      final resolved = await service().resolvePath(reference);
      expect(await File(resolved).readAsBytes(), expectedBytes);

      await source.delete();

      expect(await source.exists(), isFalse);
      expect(await File(resolved).readAsBytes(), expectedBytes);
    },
  );

  test(
    'legacy iOS container path resolves inside the current container',
    () async {
      final currentFile = File(
        path.join(currentBackgrounds.path, 'paper.webp'),
      );
      final expectedBytes = Uint8List.fromList([1, 3, 3, 7]);
      await currentFile.writeAsBytes(expectedBytes);
      final oldContainerPath = path.join(
        sandbox.path,
        'old-container',
        'Application Support',
        ReaderBackgroundImageReference.directoryName,
        'paper.webp',
      );

      final resolved = await service().resolvePath(oldContainerPath);

      expect(resolved, currentFile.path);
      expect(await File(resolved).readAsBytes(), expectedBytes);
    },
  );

  test('managed relative reference survives a new service instance', () async {
    final currentFile = File(path.join(currentBackgrounds.path, 'rain.jpg'));
    await currentFile.writeAsBytes([9, 8, 7]);
    const reference = 'reader_theme_backgrounds/rain.jpg';

    final firstResolved = await service().resolvePath(reference);
    final secondResolved = await service().resolvePath(reference);

    expect(firstResolved, currentFile.path);
    expect(secondResolved, currentFile.path);
    expect(await File(secondResolved).readAsBytes(), [9, 8, 7]);
  });

  test(
    'deleting a legacy reference removes only the current managed file',
    () async {
      final currentFile = File(path.join(currentBackgrounds.path, 'linen.png'));
      await currentFile.writeAsBytes([1]);
      final oldFile = File(
        path.join(
          sandbox.path,
          'old-container',
          'Application Support',
          ReaderBackgroundImageReference.directoryName,
          'linen.png',
        ),
      );
      await oldFile.parent.create(recursive: true);
      await oldFile.writeAsBytes([2]);

      await service().delete(oldFile.path);

      expect(await currentFile.exists(), isFalse);
      expect(await oldFile.exists(), isTrue);
    },
  );

  test('external and traversing references are never deleted', () async {
    final external = File(path.join(sandbox.path, 'external.webp'));
    final escaped = File(path.join(currentSupport.path, 'escaped.webp'));
    await external.writeAsBytes([4]);
    await escaped.writeAsBytes([5]);

    await service().delete(external.path);
    await service().delete('reader_theme_backgrounds/../escaped.webp');

    expect(await external.exists(), isTrue);
    expect(await escaped.exists(), isTrue);
    expect(
      ReaderBackgroundImageReference.managedReference(
        'reader_theme_backgrounds/../escaped.webp',
      ),
      isNull,
    );
    expect(
      ReaderBackgroundImageReference.managedReference(
        'reader_theme_backgrounds/./escaped.webp',
      ),
      isNull,
    );
    expect(
      ReaderBackgroundImageReference.normalize(r'C:\themes\rain.webp'),
      r'C:\themes\rain.webp',
    );
  });

  test('legacy and stable references identify the same managed image', () {
    final legacyPath = path.join(
      sandbox.path,
      'old-container',
      'Application Support',
      ReaderBackgroundImageReference.directoryName,
      'paper.jpeg',
    );

    expect(
      ReaderBackgroundImageReference.sameImage(
        legacyPath,
        'reader_theme_backgrounds/paper.jpeg',
      ),
      isTrue,
    );
    expect(
      ReaderBackgroundImageReference.sameImage(
        legacyPath,
        'reader_theme_backgrounds/linen.jpeg',
      ),
      isFalse,
    );
  });

  test('legacy Windows managed path normalizes to a stable reference', () {
    expect(
      ReaderBackgroundImageReference.normalize(
        r'C:\Users\reader\AppData\Support\reader_theme_backgrounds\paper.webp',
      ),
      'reader_theme_backgrounds/paper.webp',
    );
  });

  test(
    'theme decoding migrates a legacy managed path without losing metadata',
    () {
      final legacyPath = path.join(
        sandbox.path,
        'old-container',
        'Application Support',
        ReaderBackgroundImageReference.directoryName,
        'paper.jpeg',
      );

      final theme = ReaderCustomTheme.fromMap({
        'id': 'custom:paper',
        'name': 'Paper',
        'background': const Color(0xFFF4EBD8).toARGB32(),
        'text': const Color(0xFF30271F).toARGB32(),
        'controlBar': const Color(0xFFE1D0B4).toARGB32(),
        'backgroundImagePath': legacyPath,
        'backgroundImageOpacity': 0.42,
      });

      expect(theme.id, 'custom:paper');
      expect(theme.name, 'Paper');
      expect(theme.background, const Color(0xFFF4EBD8));
      expect(theme.text, const Color(0xFF30271F));
      expect(theme.controlBar, const Color(0xFFE1D0B4));
      expect(theme.backgroundImagePath, 'reader_theme_backgrounds/paper.jpeg');
      expect(theme.backgroundImageOpacity, 0.42);
    },
  );

  test('resolving a missing image leaves theme metadata intact', () async {
    const theme = ReaderCustomTheme(
      id: 'custom:missing',
      name: 'Missing paper',
      background: Color(0xFFF4EBD8),
      text: Color(0xFF30271F),
      controlBar: Color(0xFFE1D0B4),
      backgroundImagePath: 'reader_theme_backgrounds/missing.webp',
      backgroundImageOpacity: 0.37,
    );
    final before = theme.toMap();

    final resolved = await service().resolvePath(theme.backgroundImagePath!);

    expect(await File(resolved).exists(), isFalse);
    expect(theme.toMap(), before);
    expect(theme.backgroundImagePath, 'reader_theme_backgrounds/missing.webp');
    expect(theme.backgroundImageOpacity, 0.37);
  });
}
