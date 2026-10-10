import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/theme_package.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/services/themes/theme_package_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ThemePackageStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('theme-selection-');
    store = ThemePackageStore(rootDirectory: root);
  });
  tearDown(() async => root.delete(recursive: true));

  test(
    'restores the selected exact version even when a newer one is installed',
    () async {
      final first = await _install(store, 1);
      final notifier = await _notifier(store);
      await notifier.applyInstalledTheme(first);
      await _install(store, 2);
      notifier.dispose();
      final restored = await _notifier(store);
      addTearDown(restored.dispose);
      await restored.reloadInstalledThemes();
      expect(restored.currentSkinPackage?.version, 1);
      expect(restored.currentColorPackage?.version, 1);
      expect(restored.installedThemes.single.version, 2);
      expect(
        restored.currentAppTheme.lightColorScheme.secondary,
        isNot(restored.currentAppTheme.lightColorScheme.primary),
      );
    },
  );

  test('removing a newer version preserves the active older version', () async {
    final first = await _install(store, 1);
    final notifier = await _notifier(store);
    addTearDown(notifier.dispose);
    await notifier.applyInstalledTheme(first);
    final second = await _install(store, 2);
    await notifier.reloadInstalledThemes();
    await notifier.removeInstalledTheme(second);
    expect(notifier.currentSkinPackage?.version, 1);
    expect(notifier.currentColorPackage?.version, 1);
    expect(notifier.installedThemes.single.version, 1);
  });

  test(
    'changing a preset keeps package artwork; equal legacy seed exits its palette',
    () async {
      final package = await _install(store, 1);
      final notifier = await _notifier(store);
      addTearDown(notifier.dispose);
      await notifier.applyInstalledTheme(package);
      var notifications = 0;
      notifier.addListener(() => notifications++);
      final palette = notifier.currentAppTheme;
      await notifier.setAccentColor(notifier.accentColor);
      expect(notifier.currentColorPackage, isNull);
      expect(notifier.currentAppTheme, isNot(same(palette)));
      expect(notifications, 1);
      expect(notifier.currentSkinPackage?.id, package.id);
      await notifier.setColorPreset('forest');
      expect(notifier.currentColorPreset?.id, 'forest');
      expect(notifier.currentSkinPackage?.id, package.id);
    },
  );

  test(
    'corrupt exact selected version falls back without silently applying newer artwork',
    () async {
      final first = await _install(store, 1);
      final notifier = await _notifier(store);
      await notifier.applyInstalledTheme(first);
      notifier.dispose();
      await _install(store, 2);
      await File('${first.rootDirectory}/assets/preview.png').writeAsBytes([1]);
      final restored = await _notifier(store);
      addTearDown(restored.dispose);
      await restored.reloadInstalledThemes();
      expect(restored.currentSkin, same(AppSkin.original));
      expect(restored.currentSkinPackage, isNull);
      expect(restored.currentColorPackage, isNull);
      expect(restored.installedThemes.single.version, 2);
    },
  );

  test(
    'removing an active package preserves independent glass and reader preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'glass_style_mode': 'frosted',
        'reader-font-size': 22.0,
        'reader-background': '/preserved/book.jpg',
      });
      final package = await _install(store, 1);
      final notifier = await _notifier(store);
      addTearDown(notifier.dispose);
      final glass = notifier.glassStyle;
      await notifier.applyInstalledTheme(package);
      await notifier.removeInstalledTheme(package);
      expect(notifier.currentSkin, same(AppSkin.original));
      expect(notifier.currentColorPreset?.id, 'blue');
      expect(notifier.glassStyle, glass);
      expect(notifier.installedThemes, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('reader-font-size'), 22.0);
      expect(prefs.getString('reader-background'), '/preserved/book.jpg');
      expect(prefs.getString('appThemePackageSelectionV1'), isNull);
    },
  );
}

Future<ThemeNotifier> _notifier(ThemePackageStore store) async {
  final notifier = ThemeNotifier(packageStore: store);
  final ready = Completer<void>();
  void listener() {
    if (notifier.isInitialized && !ready.isCompleted) ready.complete();
  }

  notifier.addListener(listener);
  listener();
  await ready.future;
  notifier.removeListener(listener);
  return notifier;
}

Future<ThemePackage> _install(ThemePackageStore store, int version) async {
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  );
  final manifest = utf8.encode(
    jsonEncode({
      'schemaVersion': 1,
      'id': 'test-garden',
      'version': version,
      'name': 'Test Garden',
      'description': '',
      'author': 'Maker',
      'license': 'CC0',
      'preview': 'assets/preview.png',
      'palette': {
        'primary': '#123456',
        'secondary': '#BC9070',
        'tertiary': '#9070BC',
      },
      'icons': {
        'back': {
          'normal': {'asset': 'assets/icon.png'},
        },
      },
    }),
  );
  final archive = Archive()
    ..addFile(ArchiveFile('manifest.json', manifest.length, manifest))
    ..addFile(ArchiveFile('assets/preview.png', png.length, png))
    ..addFile(ArchiveFile('assets/icon.png', png.length, png));
  final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
  return store.install(
    bytes,
    expectedSha256: sha256.convert(bytes).toString(),
    expectedId: 'test-garden',
    expectedVersion: version,
  );
}
