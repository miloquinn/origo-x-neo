import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_annotation.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book_note.dart';
import 'package:xxread/models/bookmark.dart';
import 'package:xxread/pages/settings/app_text_size_sheet.dart';
import 'package:xxread/pages/settings/font_selection_sheet.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/utils/font_catalog_helper.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/reader_navigation_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GlassEffectConfig.setDisableAllGlassEffects(true);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  testWidgets('font list reaches the panel edge and exposes its last option', (
    tester,
  ) async {
    const media = MediaQueryData(
      size: Size(390, 900),
      padding: EdgeInsets.only(bottom: 34),
      viewPadding: EdgeInsets.only(bottom: 34),
    );
    _configureView(tester, media.size);
    final settings = (await tester.runAsync(_loadSettings))!;
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      _sheetHost(
        media: media,
        builder: (_) => FontSelectionSheet(
          settings: settings,
          domain: FontDomain.app,
          title: 'App font',
          description: 'Choose the interface font.',
        ),
      ),
    );
    await _open(tester);

    final viewport = find.byType(ListView);
    _expectViewportAtPanelBottom(tester, viewport);
    final lastOption = find.byKey(const ValueKey('font-option-jetbrains_mono'));
    await _jumpToEnd(tester, viewport);

    expect(lastOption, findsOneWidget);
    expect(lastOption.hitTestable(), findsOneWidget);
    expect(tester.getRect(lastOption).bottom, lessThanOrEqualTo(900 - 34));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text size list reaches the panel edge and applies its last choice',
    (tester) async {
      const media = MediaQueryData(
        size: Size(320, 568),
        padding: EdgeInsets.only(bottom: 34),
        viewPadding: EdgeInsets.only(bottom: 34),
        textScaler: TextScaler.linear(1.5),
      );
      _configureView(tester, media.size);
      final settings = (await tester.runAsync(_loadSettings))!;
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: _sheetHost(
            media: media,
            builder: (_) => const AppTextSizeSheet(),
          ),
        ),
      );
      await _open(tester);

      final viewport = find.byType(SingleChildScrollView);
      _expectViewportAtPanelBottom(tester, viewport);
      final lastChoice = find.byKey(const ValueKey('app-text-size-4'));
      await _jumpToEnd(tester, viewport);

      expect(lastChoice.hitTestable(), findsOneWidget);
      expect(tester.getRect(lastChoice).bottom, lessThanOrEqualTo(568 - 34));
      await tester.tap(lastChoice);
      await tester.pumpAndSettle();
      expect(settings.appTextScaleLevel, 4);
      expect(tester.takeException(), isNull);
    },
  );

  for (final tab in _NavigationTabCase.values) {
    testWidgets(
      'reader ${tab.name} list reaches the panel edge and its last item',
      (tester) async {
        const media = MediaQueryData(
          size: Size(390, 700),
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
          textScaler: TextScaler.linear(1.15),
        );
        _configureView(tester, media.size);
        int? selectedChapter;
        Bookmark? selectedBookmark;
        BookNote? selectedAnnotation;

        await tester.pumpWidget(
          _sheetHost(
            media: media,
            builder: (context) => SizedBox(
              height:
                  MediaQuery.sizeOf(context).height * 0.86 -
                  GlassBottomSheetSurface.dragHandleExtent,
              child: ReaderNavigationSheet(
                palette: ReaderThemes.day,
                chapters: _chapters,
                currentChapterIndex: 0,
                bookmarks: _bookmarks,
                annotations: _annotations,
                onChapterSelected: (value) => selectedChapter = value,
                onBookmarkSelected: (value) => selectedBookmark = value,
                onBookmarkDeleted: (_) {},
                onAnnotationSelected: (value) => selectedAnnotation = value,
                onAnnotationDeleted: (_) {},
              ),
            ),
          ),
        );
        await _open(tester);
        if (tab.index > 0) {
          await tester.tap(find.byType(Tab).at(tab.index));
          await tester.pumpAndSettle();
        }

        final viewport = find.byType(ListView).hitTestable();
        _expectViewportAtPanelBottom(tester, viewport);
        await _jumpToEnd(tester, viewport);
        final lastItem = switch (tab) {
          _NavigationTabCase.catalog => find.text('Chapter 15'),
          _NavigationTabCase.bookmarks => find.text('Bookmark excerpt 8'),
          _NavigationTabCase.annotations => find.text('Annotation excerpt 7'),
        };

        expect(lastItem, findsOneWidget);
        expect(lastItem.hitTestable(), findsOneWidget);
        final lastAction = find.ancestor(
          of: lastItem,
          matching: find.byType(InkWell),
        );
        expect(lastAction, findsOneWidget);
        expect(tester.getRect(lastAction).bottom, lessThanOrEqualTo(700 - 34));
        await tester.tap(lastItem);
        await tester.pump();
        switch (tab) {
          case _NavigationTabCase.catalog:
            expect(selectedChapter, 15);
          case _NavigationTabCase.bookmarks:
            expect(selectedBookmark?.id, 8);
          case _NavigationTabCase.annotations:
            expect(selectedAnnotation?.id, 7);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

enum _NavigationTabCase { catalog, bookmarks, annotations }

final _chapters = List.generate(
  16,
  (index) => ReaderNavigationChapter(title: 'Chapter $index', index: index),
  growable: false,
);

final _bookmarks = [
  for (var index = 0; index < 9; index++)
    Bookmark(
      id: index,
      bookId: 1,
      pageNumber: index,
      chapterIndex: index,
      chapterTitle: 'Chapter $index',
      excerpt: 'Bookmark excerpt $index',
      createDate: DateTime.utc(2026, 1, index + 1),
    ),
];

final _annotations = [
  for (var index = 0; index < 8; index++)
    BookNote(
      annotationId: 'annotation-$index',
      id: index,
      bookId: 1,
      content: 'Annotation excerpt $index',
      cfi: '/6/${index + 2}',
      chapter: 'Chapter $index',
      type: readerAnnotationTypeHighlight,
      color: 'FFD54F',
      pageNumber: index,
      startOffset: index,
      createTime: DateTime.utc(2026, 2, index + 1),
      updateTime: DateTime.utc(2026, 2, index + 1),
    ),
];

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

void _configureView(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

Widget _sheetHost({
  required MediaQueryData media,
  required WidgetBuilder builder,
}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(data: media, child: child!),
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showGlassBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: builder,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _expectViewportAtPanelBottom(WidgetTester tester, Finder viewport) {
  final panel = find.byWidgetPredicate(
    (widget) => widget is GlassSurface && widget.role == GlassSurfaceRole.panel,
    description: 'shared bottom-sheet panel surface',
  );
  expect(viewport, findsOneWidget);
  expect(panel, findsOneWidget);
  expect(find.byKey(GlassBottomSheetSurface.dragHandleKey), findsOneWidget);
  expect(tester.getRect(viewport).bottom, tester.getRect(panel).bottom);
}

Future<void> _jumpToEnd(WidgetTester tester, Finder viewport) async {
  final scrollable = find.descendant(
    of: viewport,
    matching: find.byType(Scrollable),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pump();
}
