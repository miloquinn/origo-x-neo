@Tags(['isolated-process'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('settings offers 2 through 5 columns and wraps at large text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _app(
        settings: settings,
        textScale: 2,
        home: const LibraryLayoutSettingsPage(),
      ),
    );
    await tester.pump();

    final selector = find.byKey(
      const ValueKey('settings-library-grid-columns'),
    );
    expect(selector, findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.byType(ChoiceChip)),
      findsNWidgets(4),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('settings-library-grid-columns-5')),
          )
          .dy,
      greaterThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('settings-library-grid-columns-2')),
            )
            .dy,
      ),
    );
    expect(tester.takeException(), isNull);

    final fiveColumns = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('settings-library-grid-columns-5')),
    );
    fiveColumns.onSelected!(true);
    await tester.pump();
    expect(settings.libraryGridColumns, 5);
    expect(tester.takeException(), isNull);
  });
}
