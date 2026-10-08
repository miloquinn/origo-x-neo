import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_custom_theme.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_theme_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory support;
  var directoryReads = 0;

  setUp(() async {
    support = await Directory.systemTemp.createTemp(
      'reader-background-widget-',
    );
    directoryReads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getApplicationSupportDirectory');
          directoryReads++;
          return support.path;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await support.delete(recursive: true);
  });

  testWidgets('saved legacy background decodes after container relocation', (
    tester,
  ) async {
    final file = File(
      path.join(support.path, 'reader_theme_backgrounds/paper.png'),
    );
    await tester.runAsync(() async {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
        ),
      );
    });
    const oldPath =
        '/var/mobile/Containers/Data/Application/OLD/Library/Application Support/reader_theme_backgrounds/paper.png';
    SharedPreferences.setMockInitialValues({
      ReaderCustomThemeStore.storageKey: jsonEncode([
        {
          ...ReaderCustomTheme.defaults.toMap(),
          'id': 'custom:paper',
          'backgroundImagePath': oldPath,
        },
      ]),
    });
    final themes = await const ReaderCustomThemeStore().loadAll();
    var palette = ReaderThemes.fromCustomTheme(themes.single);
    Widget preview() => MaterialApp(
      home: SizedBox(
        width: 100,
        height: 100,
        child: ReaderThemeBackground(
          palette: palette,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpWidget(preview());
    await tester.runAsync(() async {
      // Wait for actual file resolution and image codec, not only Image creation.
      for (var attempt = 0; attempt < 100; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
        final images = tester.widgetList<RawImage>(find.byType(RawImage));
        if (images.any((image) => image.image != null)) break;
      }
    });
    final rawImage = tester.widget<RawImage>(find.byType(RawImage));
    expect(rawImage.image, isNotNull);
    expect(rawImage.image!.width, 1);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      file.path,
    );
    expect(tester.takeException(), isNull);
    expect(directoryReads, 1);
    await tester.pumpWidget(preview());
    await tester.pump();
    expect(
      directoryReads,
      1,
      reason: 'ordinary reader rebuilds reuse path resolution',
    );
    final secondFile = File(path.join(file.parent.path, 'second.png'));
    await tester.runAsync(() => file.copy(secondFile.path));
    palette = ReaderThemes.fromCustomTheme(
      themes.single.copyWith(
        backgroundImagePath: 'reader_theme_backgrounds/second.png',
      ),
    );
    await tester.pumpWidget(preview());
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 100; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
        final images = tester.widgetList<Image>(find.byType(Image));
        if (images.any(
              (image) =>
                  (image.image as FileImage).file.path == secondFile.path,
            ) &&
            tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((image) => image.image != null)) {
          break;
        }
      }
    });
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      secondFile.path,
    );
    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    expect(directoryReads, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    imageCache.clear();
    imageCache.clearLiveImages();
  });
}
