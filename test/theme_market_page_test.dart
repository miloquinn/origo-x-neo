import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/theme_package.dart';
import 'package:xxread/pages/settings/theme_market_page.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/services/themes/theme_market_item.dart';
import 'package:xxread/services/themes/theme_package_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;
  late ThemePackageStore store;
  late ThemeNotifier notifier;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sandbox = await Directory.systemTemp.createTemp('theme-market-page-');
    store = ThemePackageStore(rootDirectory: sandbox);
    notifier = ThemeNotifier(packageStore: store);
    await _waitUntil(() => notifier.isInitialized);
  });

  tearDown(() async {
    notifier.dispose();
    if (await sandbox.exists()) await sandbox.delete(recursive: true);
  });

  testWidgets('loads approved themes and installs a verified package once', (
    tester,
  ) async {
    final bytes = _packageZip();
    final item = _item(bytes);
    final download = Completer<Uint8List>();
    var downloads = 0;
    var installs = 0;

    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async => [item],
      downloader: (_) {
        downloads++;
        return download.future;
      },
      installAction: (installedItem, installedBytes) async {
        expect(installedItem.id, item.id);
        expect(installedBytes, bytes);
        installs++;
      },
    );

    expect(find.text('Paper Garden'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('download-paper-garden-1')),
    );
    await tester.tap(find.byKey(const ValueKey('download-paper-garden-1')));
    await tester.tap(find.byKey(const ValueKey('download-paper-garden-1')));
    expect(downloads, 1);

    download.complete(bytes);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('theme-market-action-error')),
      findsNothing,
    );
    expect(installs, 1);
    expect(find.textContaining('已安装'), findsOneWidget);
  });

  testWidgets('shows remote failure, retries, and never invents catalog data', (
    tester,
  ) async {
    var calls = 0;
    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async {
        calls++;
        if (calls == 1) throw StateError('offline');
        return const [];
      },
      downloader: (_) => throw UnimplementedError(),
    );

    expect(find.byKey(const ValueKey('theme-market-error')), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('theme-market-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('market-paper-garden-1')), findsNothing);
  });

  testWidgets(
    'keeps installed themes usable offline and removes after consent',
    (tester) async {
      final bytes = _packageZip();
      late final ThemePackage package;
      await tester.runAsync(() async {
        package = await store.install(
          bytes,
          expectedSha256: sha256.convert(bytes).toString(),
          expectedId: 'paper-garden',
          expectedVersion: 1,
        );
        await notifier.reloadInstalledThemes();
      });
      var applied = 0;
      var removed = 0;

      await _pumpPage(
        tester,
        notifier: notifier,
        loader: () async => throw StateError('offline'),
        downloader: (_) => throw UnimplementedError(),
        applyAction: (_) async {
          applied++;
        },
        removeAction: (_) async {
          removed++;
        },
      );
      expect(
        find.byKey(const ValueKey('installed-paper-garden-1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('apply-paper-garden-1')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(applied, 1);

      await tester.tap(find.byKey(const ValueKey('remove-paper-garden-1')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('移除主题？'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(removed, 1);
      expect(package.id, 'paper-garden');
    },
  );

  testWidgets('opens the creator URL supplied by the public account API', (
    tester,
  ) async {
    Uri? opened;
    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async => const [],
      downloader: (_) => throw UnimplementedError(),
      creatorUri: Uri.parse('https://example.test/themes/create'),
      launcher: (uri) async {
        opened = uri;
        return true;
      },
    );

    await tester.tap(find.byKey(const ValueKey('theme-market-create')));
    await tester.pump();
    expect(opened, Uri.parse('https://example.test/themes/create'));
  });

  testWidgets('keeps the selected older version visible beside an update', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final firstBytes = _packageZip(version: 1);
      final first = await store.install(
        firstBytes,
        expectedSha256: sha256.convert(firstBytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 1,
      );
      await notifier.reloadInstalledThemes();
      await notifier.applyInstalledTheme(first);
      final secondBytes = _packageZip(version: 2);
      await store.install(
        secondBytes,
        expectedSha256: sha256.convert(secondBytes).toString(),
        expectedId: 'paper-garden',
        expectedVersion: 2,
      );
      await notifier.reloadInstalledThemes();
    });

    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async => const [],
      downloader: (_) => throw UnimplementedError(),
    );
    expect(
      find.byKey(const ValueKey('installed-paper-garden-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('installed-paper-garden-2')),
      findsOneWidget,
    );
  });

  testWidgets('shows independent skin and palette packages as active', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final skinBytes = _packageZip(id: 'skin-layer');
      final skin = await store.install(
        skinBytes,
        expectedSha256: sha256.convert(skinBytes).toString(),
        expectedId: 'skin-layer',
        expectedVersion: 1,
      );
      final paletteBytes = _packageZip(
        id: 'palette-layer',
        includePalette: true,
        includeSkin: false,
      );
      final palette = await store.install(
        paletteBytes,
        expectedSha256: sha256.convert(paletteBytes).toString(),
        expectedId: 'palette-layer',
        expectedVersion: 1,
      );
      await notifier.reloadInstalledThemes();
      await notifier.applyInstalledTheme(skin);
      await notifier.applyInstalledTheme(palette);
    });

    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async => const [],
      downloader: (_) => throw UnimplementedError(),
    );
    for (final id in ['skin-layer', 'palette-layer']) {
      final card = find.byKey(ValueKey('installed-$id-1'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('apply-$id-1')), findsNothing);
    }
  });

  testWidgets(
    'reapplies a full package after a palette-only package overrides its color',
    (tester) async {
      await _expectPartialFullPackageCanBeReapplied(
        tester,
        notifier: notifier,
        store: store,
        overridePalette: true,
      );
    },
  );

  testWidgets(
    'reapplies a full package after a skin-only package overrides its artwork',
    (tester) async {
      await _expectPartialFullPackageCanBeReapplied(
        tester,
        notifier: notifier,
        store: store,
        overridePalette: false,
      );
    },
  );

  test('update guard includes an active older palette package', () async {
    final firstBytes = _packageZip(
      version: 1,
      includePalette: true,
      includeSkin: false,
    );
    final first = await store.install(
      firstBytes,
      expectedSha256: sha256.convert(firstBytes).toString(),
      expectedId: 'paper-garden',
      expectedVersion: 1,
    );
    await notifier.reloadInstalledThemes();
    await notifier.applyInstalledTheme(first);

    expect(notifier.currentSkinPackage, isNull);
    expect(notifier.currentColorPackage?.version, 1);
    expect(
      ThemeMarketPage.shouldPreserveActiveVersion(
        activePackages: [
          notifier.currentSkinPackage,
          notifier.currentColorPackage,
        ],
        incomingId: 'paper-garden',
        incomingVersion: 2,
      ),
      isTrue,
    );
  });

  testWidgets(
    'keeps the public market offline when network consent is absent',
    (tester) async {
      var loads = 0;
      tester.view.physicalSize = const Size(780, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: notifier,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ThemeMarketPage(
              canFetch: false,
              loader: () async {
                loads++;
                return [_item(_packageZip())];
              },
              downloader: (_) => throw UnimplementedError(),
              previewUriBuilder: (_) =>
                  Uri.parse('https://example.test/preview.png'),
              creatorUri: Uri.parse('https://example.test/create'),
              installedLoader: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(loads, 0);
      expect(
        find.byKey(const ValueKey('theme-market-network-disabled')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '制作并投稿主题'))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('reports an installed theme reload failure without hanging', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      notifier: notifier,
      loader: () async => const [],
      downloader: (_) => throw UnimplementedError(),
      installedLoader: () async => throw StateError('receipt unreadable'),
    );

    expect(
      find.byKey(const ValueKey('theme-market-installed-loading')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('theme-market-action-error')),
      findsOneWidget,
    );
    expect(find.textContaining('receipt unreadable'), findsOneWidget);
  });

  testWidgets('renders English long labels at large text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: ThemeMarketPage(
            canFetch: true,
            loader: () async => [_item(_packageZip())],
            downloader: (_) => throw UnimplementedError(),
            previewUriBuilder: (_) =>
                Uri.parse('https://example.test/preview.png'),
            creatorUri: Uri.parse('https://example.test/create'),
            uriLauncher: (_) async => true,
            installedLoader: () async {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Theme Market'), findsOneWidget);
    expect(find.text('Themes made by everyone'), findsOneWidget);
    expect(find.text('Create and submit a theme'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('download-paper-garden-1')),
    );
    await tester.pump();
    expect(find.text('Download and apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required ThemeNotifier notifier,
  required ThemeMarketLoader loader,
  required ThemeMarketDownloader downloader,
  Uri? creatorUri,
  ThemeMarketUriLauncher? launcher,
  ThemeMarketInstallAction? installAction,
  InstalledThemeAction? applyAction,
  InstalledThemeAction? removeAction,
  InstalledThemeLoader? installedLoader,
  Locale locale = const Locale('zh'),
}) async {
  tester.view.physicalSize = const Size(780, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: notifier,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThemeMarketPage(
          loader: loader,
          downloader: downloader,
          previewUriBuilder: (_) =>
              Uri.parse('https://example.test/preview.png'),
          creatorUri: creatorUri ?? Uri.parse('https://example.test/create'),
          uriLauncher: launcher ?? (_) async => true,
          canFetch: true,
          installAction: installAction,
          applyAction: applyAction,
          removeAction: removeAction,
          installedLoader: installedLoader ?? () async {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('Timed out waiting for notifier initialization.');
}

ThemeMarketItem _item(
  Uint8List bytes, {
  String id = 'paper-garden',
  int version = 1,
}) => ThemeMarketItem.fromJson({
  'schemaVersion': 1,
  'id': id,
  'version': version,
  'name': 'Paper Garden',
  'description': 'A calm paper garden.',
  'author': 'Theme Maker',
  'license': 'CC BY 4.0',
  'sha256': sha256.convert(bytes).toString(),
  'size': bytes.length,
});

Future<void> _expectPartialFullPackageCanBeReapplied(
  WidgetTester tester, {
  required ThemeNotifier notifier,
  required ThemePackageStore store,
  required bool overridePalette,
}) async {
  const fullId = 'full-layer';
  late ThemePackage fullPackage;
  await tester.runAsync(() async {
    final fullBytes = _packageZip(id: fullId, includePalette: true);
    fullPackage = await store.install(
      fullBytes,
      expectedSha256: sha256.convert(fullBytes).toString(),
      expectedId: fullId,
      expectedVersion: 1,
    );
    await notifier.reloadInstalledThemes();
    await notifier.applyInstalledTheme(fullPackage);

    final overrideId = overridePalette ? 'palette-layer' : 'skin-layer';
    final overrideBytes = _packageZip(
      id: overrideId,
      includePalette: overridePalette,
      includeSkin: !overridePalette,
    );
    final overridePackage = await store.install(
      overrideBytes,
      expectedSha256: sha256.convert(overrideBytes).toString(),
      expectedId: overrideId,
      expectedVersion: 1,
    );
    await notifier.reloadInstalledThemes();
    await notifier.applyInstalledTheme(overridePackage);

    final updateBytes = _packageZip(
      id: fullId,
      version: 2,
      includePalette: true,
    );
    await store.install(
      updateBytes,
      expectedSha256: sha256.convert(updateBytes).toString(),
      expectedId: fullId,
      expectedVersion: 2,
    );
    await notifier.reloadInstalledThemes();
  });

  expect(
    ThemeMarketPage.usesAnyLayer(
      package: fullPackage,
      currentSkinPackage: notifier.currentSkinPackage,
      currentColorPackage: notifier.currentColorPackage,
    ),
    isTrue,
  );
  expect(
    ThemeMarketPage.isFullyApplied(
      package: fullPackage,
      currentSkinPackage: notifier.currentSkinPackage,
      currentColorPackage: notifier.currentColorPackage,
    ),
    isFalse,
  );

  final applied = <ThemePackage>[];
  final fullBytes = _packageZip(id: fullId, includePalette: true);
  await _pumpPage(
    tester,
    notifier: notifier,
    loader: () async => [_item(fullBytes, id: fullId)],
    downloader: (_) => throw UnimplementedError(),
    applyAction: (package) async => applied.add(package),
  );

  final localApply = find.byKey(const ValueKey('apply-full-layer-1'));
  expect(localApply, findsOneWidget);
  await tester.ensureVisible(localApply);
  await tester.tap(localApply);
  await tester.pump(const Duration(milliseconds: 200));
  expect(applied.map((package) => (package.id, package.version)), [
    (fullId, 1),
  ]);

  final remoteApply = find.byKey(const ValueKey('download-full-layer-1'));
  await tester.ensureVisible(remoteApply);
  await tester.pump();
  expect(tester.widget<FilledButton>(remoteApply).onPressed, isNotNull);
  await tester.tap(remoteApply);
  await tester.pump(const Duration(milliseconds: 200));
  expect(applied.map((package) => (package.id, package.version)), [
    (fullId, 1),
    (fullId, 1),
  ]);

  await tester.runAsync(() => notifier.applyInstalledTheme(fullPackage));
  expect(
    (notifier.currentSkinPackage?.id, notifier.currentSkinPackage?.version),
    (fullId, 1),
  );
  expect(
    (notifier.currentColorPackage?.id, notifier.currentColorPackage?.version),
    (fullId, 1),
  );
  expect(
    ThemeMarketPage.isFullyApplied(
      package: fullPackage,
      currentSkinPackage: notifier.currentSkinPackage,
      currentColorPackage: notifier.currentColorPackage,
    ),
    isTrue,
  );
}

Uint8List _packageZip({
  String id = 'paper-garden',
  int version = 1,
  bool includePalette = false,
  bool includeSkin = true,
}) {
  final manifest = <String, Object?>{
    'schemaVersion': 1,
    'id': id,
    'version': version,
    'name': 'Paper Garden',
    'description': 'A calm paper garden.',
    'author': 'Theme Maker',
    'license': 'CC BY 4.0',
    'preview': 'assets/preview.png',
    if (includePalette)
      'palette': {
        'primary': '#123456',
        'secondary': '#BC9070',
        'tertiary': '#9070BC',
      },
    if (includeSkin)
      'icons': {
        'home': {
          'normal': {'asset': 'assets/icon.png'},
        },
      },
  };
  final files = <String, Uint8List>{
    'manifest.json': Uint8List.fromList(utf8.encode(jsonEncode(manifest))),
    'assets/preview.png': _png,
    if (includeSkin) 'assets/icon.png': _png,
  };
  final archive = Archive();
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
