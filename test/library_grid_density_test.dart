@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/pages/settings/library_layout_settings_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/layout_helper.dart';

Future<AppSettingsNotifier> _loadSettings() async {
  final settings = AppSettingsNotifier();
  if (settings.isInitialized) return settings;
  final initialized = Completer<void>();
  void listener() {
    if (settings.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  settings.addListener(listener);
  listener();
  await initialized.future;
  settings.removeListener(listener);
  return settings;
}

Widget _app({
  required AppSettingsNotifier settings,
  required Widget home,
  double textScale = 1,
  bool previewFont = false,
}) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: previewFont ? ThemeData(fontFamily: 'GridColumnPreview') : null,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

List<Book> _books() => List.generate(
  12,
  (index) => Book(
    id: index + 1,
    importDate: DateTime.utc(2026, 10, 10).subtract(Duration(days: index)),
    title: 'Density Book $index',
    filePath: '/tmp/density-$index.txt',
    format: 'TXT',
  ),
);

Future<int> _pumpLibrary(
  WidgetTester tester, {
  required AppSettingsNotifier settings,
  required Size size,
  double textScale = 1,
  List<ShelfFolder> folders = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  await tester.pumpWidget(
    _app(
      settings: settings,
      textScale: textScale,
      home: LibraryPage(
        foldersLoader: () async => folders,
        booksLoader: () async => _books(),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  final grid = tester.widget<GridView>(
    find.byKey(const ValueKey('library-cover-grid')),
  );
  return (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
      .crossAxisCount;
}

Future<void> _pumpLayoutSettings(
  WidgetTester tester, {
  required AppSettingsNotifier settings,
  required Size size,
  double textScale = 1,
  bool hasFolders = false,
  String? captureName,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final previewFont = await _loadPreviewFontsIfRequested(tester);
  final captureKey = GlobalKey(debugLabel: captureName);
  await tester.pumpWidget(
    _app(
      settings: settings,
      textScale: textScale,
      previewFont: previewFont,
      home: RepaintBoundary(
        key: captureKey,
        child: LibraryLayoutSettingsPage(hasFolders: hasFolders),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
  await _captureSettingsIfRequested(tester, captureKey, captureName);
}

bool _previewFontsLoaded = false;

Future<bool> _loadPreviewFontsIfRequested(WidgetTester tester) async {
  final captureDirectory = Platform.environment['GRID_COLUMN_CAPTURE_DIR'];
  if (captureDirectory == null || captureDirectory.isEmpty) return false;
  if (_previewFontsLoaded) return true;
  await tester.runAsync(() async {
    final font = FontLoader('GridColumnPreview');
    font.addFont(
      File(
        '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  _previewFontsLoaded = true;
  return true;
}

Future<void> _captureSettingsIfRequested(
  WidgetTester tester,
  GlobalKey captureKey,
  String? captureName,
) async {
  final captureDirectory = Platform.environment['GRID_COLUMN_CAPTURE_DIR'];
  if (captureDirectory == null ||
      captureDirectory.isEmpty ||
      captureName == null) {
    return;
  }
  if (!path.isAbsolute(captureDirectory)) {
    throw ArgumentError.value(
      captureDirectory,
      'GRID_COLUMN_CAPTURE_DIR',
      'must be an absolute path',
    );
  }
  if (captureName.contains('large-text-folder')) {
    final selector = find.byKey(
      const ValueKey('settings-library-grid-columns'),
    );
    await Scrollable.ensureVisible(tester.element(selector), alignment: 0.18);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getRect(selector).top, greaterThanOrEqualTo(110));
  }
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory(captureDirectory);
    await directory.create(recursive: true);
    final bytes = data!.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(
      path.join(captureDirectory, '$captureName.png'),
    ).writeAsBytes(bytes);
    image.dispose();
  });
}

List<int> _visibleColumnChoices(WidgetTester tester) => [
  for (final columns in const [2, 3, 4, 5])
    if (find
        .byKey(ValueKey('settings-library-grid-columns-$columns'))
        .evaluate()
        .isNotEmpty)
      columns,
];

bool _columnChoiceIsSelected(WidgetTester tester, int columns) => tester
    .widget<ChoiceChip>(
      find.byKey(ValueKey('settings-library-grid-columns-$columns')),
    )
    .selected;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('density policy keeps covers readable without losing preference', () {
    expect(LayoutHelper.coverOnlyGridColumnsForWidth(390, mobileColumns: 5), 5);
    expect(LayoutHelper.coverOnlyGridColumnsForWidth(320, mobileColumns: 5), 4);
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(
        390,
        mobileColumns: 5,
        showDetails: true,
        textScaleFactor: 1.5,
      ),
      4,
    );
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(
        390,
        mobileColumns: 5,
        showDetails: true,
        textScaleFactor: 2,
      ),
      3,
    );
    expect(LayoutHelper.coverOnlyGridColumnsForWidth(820, mobileColumns: 2), 4);
    expect(LayoutHelper.coverOnlyGridColumnsForWidth(820, mobileColumns: 3), 5);
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(1600, mobileColumns: 5),
      8,
    );
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(
        350,
        mobileColumns: 5,
        usesWideLayout: true,
        horizontalPadding: 32,
        spacing: 14,
        showDetails: true,
        textScaleFactor: 2,
      ),
      2,
    );
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(
        80,
        mobileColumns: 5,
        horizontalPadding: 12,
        spacing: 10,
      ),
      1,
    );
    expect(
      LayoutHelper.coverOnlyGridColumnsForWidth(
        390,
        mobileColumns: 5,
        showDetails: false,
        hasFolders: true,
        textScaleFactor: 3,
      ),
      2,
    );
  });

  test('capacity reports one column when only one cover fits', () {
    expect(
      LayoutHelper.coverOnlyGridCapacityForWidth(
        80,
        usesWideLayout: false,
        horizontalPadding: 12,
        spacing: 10,
      ),
      1,
    );
  });

  testWidgets('LibraryPage applies adaptive 5-column density', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() => settings.setLibraryGridColumns(5));

    expect(
      await _pumpLibrary(
        tester,
        settings: settings,
        size: const Size(390, 844),
      ),
      5,
    );
    expect(settings.libraryGridColumns, 5);

    expect(
      await _pumpLibrary(
        tester,
        settings: settings,
        size: const Size(320, 700),
      ),
      4,
    );
    expect(settings.libraryGridColumns, 5);

    expect(
      await _pumpLibrary(
        tester,
        settings: settings,
        size: const Size(390, 844),
        textScale: 2,
      ),
      3,
    );
    expect(settings.libraryGridColumns, 5);
  });

  testWidgets('LibraryPage caps a wide shelf at eight columns', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() => settings.setLibraryGridColumns(5));

    expect(
      await _pumpLibrary(
        tester,
        settings: settings,
        size: const Size(1200, 900),
      ),
      8,
    );
    expect(settings.libraryGridColumns, 5);
  });

  testWidgets('folder grid reserves readable labels when details are hidden', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(false);
    });
    final folder = ShelfFolder(
      id: 'large-text-folder',
      name: 'Large Text Shelf',
      parentId: null,
      createdAt: DateTime.utc(2026, 10, 8),
    );

    for (final size in const [Size(390, 844), Size(320, 700)]) {
      final columns = await _pumpLibrary(
        tester,
        settings: settings,
        size: size,
        textScale: 3,
        folders: [folder],
      );
      expect(columns, 2);
      expect(
        tester.getSize(find.byIcon(Icons.folder_outlined).first).height,
        greaterThanOrEqualTo(32),
      );
      final firstBook = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Density Book 0',
      );
      final cover = find
          .descendant(of: firstBook, matching: find.byType(ClipRRect))
          .first;
      final coverSize = tester.getSize(cover);
      expect(coverSize.height / coverSize.width, closeTo(1.5, 0.01));
      expect(tester.takeException(), isNull);
    }
    expect(settings.libraryGridColumns, 5);
    expect(settings.libraryGridShowDetails, isFalse);
  });

  testWidgets('settings hides 5 columns when the current shelf fits only 4', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(360, 780),
      captureName: 'settings-360-details-columns-2-3-4',
    );

    expect(_visibleColumnChoices(tester), [2, 3, 4]);
  });

  testWidgets('settings offers 5 columns when the shelf can render 5', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
      captureName: 'settings-390-details-columns-2-3-4-5',
    );

    expect(_visibleColumnChoices(tester), [2, 3, 4, 5]);
  });

  testWidgets('narrow shelf preserves a saved 5-column preference', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(360, 780),
    );

    expect(_columnChoiceIsSelected(tester, 4), isTrue);
    expect(settings.libraryGridColumns, 5);

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
    );

    expect(_columnChoiceIsSelected(tester, 5), isTrue);
    expect(settings.libraryGridColumns, 5);
  });

  testWidgets('selecting an achievable column count updates the preference', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });
    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(360, 780),
    );

    await tester.tap(
      find.byKey(const ValueKey('settings-library-grid-columns-4')),
    );
    await tester.pump();

    expect(settings.libraryGridColumns, 4);
    expect(_columnChoiceIsSelected(tester, 4), isTrue);
  });

  testWidgets('large text reduces column choices when details are visible', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
      textScale: 2,
    );

    expect(_visibleColumnChoices(tester), [2, 3]);
  });

  testWidgets('hidden details keep 5 columns available without folders', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(false);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
      textScale: 3,
    );

    expect(_visibleColumnChoices(tester), [2, 3, 4, 5]);
  });

  testWidgets('visible folders reduce choices at large text', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(false);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
      textScale: 3,
      hasFolders: true,
      captureName: 'settings-390-large-text-folder-columns-2',
    );

    expect(_visibleColumnChoices(tester), [2]);
  });

  testWidgets('settings route reads visible folders from the live shelf', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(false);
    });
    final controller = LibraryPageController();
    addTearDown(controller.dispose);
    final folder = ShelfFolder(
      id: 'root-folder',
      name: 'Root Shelf',
      parentId: null,
      createdAt: DateTime.utc(2026, 10, 8),
    );

    await tester.pumpWidget(
      _app(
        settings: settings,
        textScale: 3,
        home: LibraryPage(
          controller: controller,
          foldersLoader: () async => [folder],
          booksLoader: () async => _books(),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.hasVisibleFolders, isTrue);

    unawaited(
      Navigator.of(tester.element(find.byType(LibraryPage))).push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              LibraryLayoutSettingsPage(libraryController: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_visibleColumnChoices(tester), [2]);
    expect(controller.hasVisibleFolders, isTrue);
    expect(settings.libraryGridColumns, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings uses shelf viewport width outside its inner padding', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);
    await tester.runAsync(() async {
      await settings.setLibraryGridColumns(5);
      await settings.setLibraryGridShowDetails(true);
    });

    await _pumpLayoutSettings(
      tester,
      settings: settings,
      size: const Size(390, 844),
    );

    final selector = find.byKey(
      const ValueKey('settings-library-grid-columns'),
    );
    expect(tester.getSize(selector).width, lessThan(390));
    expect(_visibleColumnChoices(tester), [2, 3, 4, 5]);
  });

  testWidgets(
    'phone landscape settings match the rendered grid capacity',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final settings = (await tester.runAsync(_loadSettings))!;
      addTearDown(settings.dispose);
      await tester.runAsync(() async {
        await settings.setLibraryGridColumns(5);
        await settings.setLibraryGridShowDetails(true);
      });

      await _pumpLayoutSettings(
        tester,
        settings: settings,
        size: const Size(800, 390),
      );
      expect(_visibleColumnChoices(tester), [2, 3, 4, 5]);

      expect(
        await _pumpLibrary(
          tester,
          settings: settings,
          size: const Size(800, 390),
        ),
        5,
      );
    },
    variant: TargetPlatformVariant(<TargetPlatform>{TargetPlatform.android}),
  );
}
