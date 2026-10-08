@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';

const _parent = 'card-parent';
const _child = 'card-child';
const _empty = 'card-empty';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('shelf-card-test-');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => directory.path,
    );
  });
  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'library_layout_mode_v1': 'card'});
  });

  testWidgets(
    'horizontal previews scroll without navigating and stay bounded',
    (tester) async {
      final fixture = await _mount(tester);
      final strip = find.byKey(
        const PageStorageKey('folder-preview-strip-$_parent'),
      );
      final list = tester.widget<ListView>(strip);
      expect(list.scrollDirection, Axis.horizontal);
      expect(
        (list.childrenDelegate as SliverChildBuilderDelegate).childCount,
        19, // Ten items and their nine separators.
      );
      await tester.drag(strip, const Offset(-900, 0));
      await tester.pumpAndSettle();
      expect(fixture.controller.folderName.value, isNull);
      expect(
        find.byKey(const ValueKey('folder-preview-$_parent-8')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('folder-preview-$_parent-9')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('folder-preview-more-$_parent')),
        findsOneWidget,
      );
      expect(find.text('+5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'card expands from its full surface and returns to the same card',
    (tester) async {
      final fixture = await _mount(tester);
      final card = find.byKey(const ValueKey('library-folder-card-$_parent'));
      final original = tester.getRect(card);
      expect(original.width, greaterThan(300));
      expect(original.height, greaterThan(150));
      final strip = find.byKey(
        const PageStorageKey('folder-preview-strip-$_parent'),
      );
      final previewScroll = find.descendant(
        of: strip,
        matching: find.byType(Scrollable),
      );
      await tester.drag(strip, const Offset(-300, 0));
      await tester.pumpAndSettle();
      final previewOffset = tester
          .state<ScrollableState>(previewScroll)
          .position
          .pixels;
      expect(previewOffset, greaterThan(0));
      await tester.tap(find.text('Literature and life'));
      await tester.pump();
      final snapshot = tester.widget<Positioned>(
        find.byKey(const ValueKey('library-shelf-snapshot')),
      );
      expect(snapshot.width, closeTo(original.width, 1));
      expect(snapshot.height, closeTo(original.height, 1));
      await tester.pumpAndSettle();
      expect(fixture.controller.folderName.value, 'Literature and life');
      expect(
        find.byKey(const ValueKey('library-folder-card-$_child')),
        findsOneWidget,
      );
      fixture.controller.goUp();
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(fixture.controller.folderName.value, isNull);
      expect(tester.getSize(card).width, closeTo(original.width, 1));
      expect(
        tester.state<ScrollableState>(previewScroll).position.pixels,
        closeTo(previewOffset, 1),
      );
      expect(
        find.byKey(const ValueKey('library-shelf-snapshot')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty and single-book cards remain usable with large text', (
    tester,
  ) async {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final fixture = await _mount(
        tester,
        size: const Size(320, 900),
        scale: 2,
        brightness: brightness,
        single: true,
      );
      expect(find.text('Single book with a long title'), findsWidgets);
      expect(find.text('An actual author'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final empty = find.byKey(const ValueKey('library-folder-card-$_empty'));
      await tester.ensureVisible(empty);
      await tester.pumpAndSettle();
      expect(find.text('No books yet'), findsOneWidget);
      await tester.tap(find.text('For later'));
      await tester.pumpAndSettle();
      expect(fixture.controller.folderName.value, 'For later');
      expect(
        find.byKey(const ValueKey('library-create-empty-folder')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      fixture.dispose();
    }
  });

  testWidgets('folder card keeps long-press actions and selection guard', (
    tester,
  ) async {
    final fixture = await _mount(tester);
    await tester.longPress(find.text('Literature and life'));
    await tester.pumpAndSettle();
    expect(find.text('Rename group'), findsOneWidget);
    expect(find.text('Move to group'), findsOneWidget);
    Navigator.of(tester.element(find.text('Rename group'))).pop();
    await tester.pumpAndSettle();
    fixture.controller.selectAllVisible();
    await tester.pump();
    expect(fixture.controller.selection.value.isActive, isTrue);
    await tester.tap(find.text('Literature and life'));
    await tester.pumpAndSettle();
    expect(fixture.controller.folderName.value, isNull);
    expect(fixture.controller.selection.value.selectedCount, 2);
    expect(tester.takeException(), isNull);
  });
}

class _CardFixture {
  _CardFixture(this.settings, this.controller);
  final AppSettingsNotifier settings;
  final LibraryPageController controller;
  bool _disposed = false;
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    controller.dispose();
    settings.dispose();
  }
}

Future<_CardFixture> _mount(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  bool single = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final settings = (await tester.runAsync(() async {
    final settings = AppSettingsNotifier();
    if (!settings.isInitialized) {
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
    }
    return settings;
  }))!;
  final controller = LibraryPageController();
  final fixture = _CardFixture(settings, controller);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.dispose();
  });
  final folders = [
    ShelfFolder(
      id: _parent,
      name: 'Literature and life',
      parentId: null,
      createdAt: DateTime(2026),
    ),
    ShelfFolder(
      id: _child,
      name: 'Modern classics',
      parentId: _parent,
      createdAt: DateTime(2026),
    ),
    ShelfFolder(
      id: _empty,
      name: 'For later',
      parentId: null,
      createdAt: DateTime(2025),
    ),
  ];
  final books = [
    for (var i = 0; i < (single ? 1 : 14); i++)
      Book(
        id: i + 1,
        title: single ? 'Single book with a long title' : 'Book $i',
        author: single ? 'An actual author' : 'Author $i',
        filePath: '/card-fixture-$i.txt',
        format: 'TXT',
        shelfFolderId: !single && i >= 10 ? _child : _parent,
      ),
    for (var i = 0; i < 2; i++)
      Book(
        id: i + 100,
        title: 'Root book $i',
        filePath: '/root-$i.txt',
        format: 'TXT',
      ),
  ];
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: LibraryPage(
          controller: controller,
          booksLoader: () async => books,
          foldersLoader: () async => folders,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixture;
}
