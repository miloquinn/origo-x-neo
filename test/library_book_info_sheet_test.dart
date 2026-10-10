import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/library_book_info_sheet.dart';

void main() {
  testWidgets('online statistics retain chapter unit conversion', (
    tester,
  ) async {
    final book = Book(
      title: 'Online book',
      author: 'Author',
      filePath: '',
      format: 'txt',
      storageType: 'online',
      currentPage: 3250,
      totalPages: 12000,
    );
    await tester.pumpWidget(
      _infoHost(
        LibraryBookInfoSheet(
          book: book,
          cover: const ColoredBox(color: Colors.indigo),
        ),
      ),
    );
    expect(find.text('12 chapters'), findsOneWidget);
    expect(find.text('3 chapters'), findsOneWidget);
    expect(find.text('27.1%'), findsOneWidget);
    expect(find.text('12000 pages'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid stored metadata remains visible with source actions', (
    tester,
  ) async {
    final service = BookSourceShelfService();
    addTearDown(service.close);
    final source = RegisteredBookSource(
      id: 'source',
      name: 'Source',
      description: '',
      manifestUrl: Uri.parse(
        'https://example.test/.well-known/open-reading-source.json',
      ),
      apiBaseUrl: Uri.parse('https://example.test/api'),
      protocolVersion: '1.4',
      languages: const ['en'],
      capabilities: const {'search', 'book', 'chapters', 'content'},
      enabled: true,
      addedAt: DateTime(2026, 10, 10),
    );
    const sourceBook = BookSourceBook(
      id: 'book',
      title: 'Book',
      author: 'Author',
      description: '',
      categories: [],
    );
    for (final sourceJson in ['{broken', jsonEncode(source.toJson())]) {
      final book = Book(
        title: 'Stored book',
        author: 'Author',
        filePath: '/book.txt',
        format: 'txt',
        sourceId: 'source',
        sourceBookId: 'mismatched-book',
        sourceJson: sourceJson,
        sourceBookJson: jsonEncode(sourceBook.toJson()),
      );
      expect(book.hasSourceBinding, isTrue);
      final sheet = LibraryBookInfoSheet.fromShelf(
        book: book,
        cover: const ColoredBox(color: Colors.indigo),
        shelfService: service,
        sourceStatus: const Text('Preserved source actions'),
      );
      expect(sheet.metadataUnavailable, isTrue);
      expect(sheet.sourceBook, isNull);
      await tester.pumpWidget(_infoHost(sheet));
      expect(
        find.byKey(const Key('library-book-info-metadata-error')),
        findsOneWidget,
      );
      expect(find.text('Stored book'), findsOneWidget);
      expect(find.text('Preserved source actions'), findsOneWidget);
      expect(book.sourceJson, sourceJson);
      expect(book.sourceBookId, 'mismatched-book');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'small large-text sheet keeps metadata scrollable and close reachable',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 568);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        const longTitle =
            'A very long library title that must remain available on a narrow phone';
        const longAuthor =
            'An author with a deliberately long display name for accessibility';
        const sourceStatusKey = ValueKey<String>('preserved-source-status');
        const sourceBook = BookSourceBook(
          id: 'source-book',
          title: 'Remote title',
          author: 'Remote author',
          description:
              '<p>A source description with enough detail to require scrolling.</p>'
              '<p>The close action must stay outside that scrolling region.</p>',
          status: ' 连载中 ',
          categories: ['  奇幻  ', '冒险'],
        );
        final book = Book(
          title: longTitle,
          author: longAuthor,
          filePath: '/books/long.epub',
          format: 'epub',
          currentPage: 48,
          totalPages: 320,
        );

        await tester.pumpWidget(
          _sheetHost(
            book: book,
            sourceBook: sourceBook,
            sourceLabel: 'Personal Source',
            sourceStatus: const SizedBox(
              key: sourceStatusKey,
              height: 120,
              child: Text('Source health and update controls'),
            ),
            media: const MediaQueryData(
              size: Size(320, 568),
              padding: EdgeInsets.only(top: 44, bottom: 28),
              viewPadding: EdgeInsets.only(top: 44, bottom: 28),
              textScaler: TextScaler.linear(1.6),
            ),
            brightness: Brightness.dark,
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GlassSurface), findsOneWidget);
        final panel = tester.getRect(find.byType(GlassSurface));
        expect(panel.height, lessThanOrEqualTo(568 * 0.86));
        expect(panel.top, greaterThanOrEqualTo(44));
        final footer = tester.getRect(
          find.byKey(const Key('library-book-info-footer')),
        );
        expect(footer.bottom, closeTo(panel.bottom, 0.01));
        expect(
          tester
              .getRect(find.byKey(const Key('library-book-info-scroll')))
              .bottom,
          lessThanOrEqualTo(footer.top),
        );

        expect(find.text(longTitle), findsOneWidget);
        expect(find.text(longAuthor), findsOneWidget);
        expect(find.text('Personal Source'), findsOneWidget);
        expect(find.text('连载中'), findsOneWidget);
        expect(find.text('奇幻'), findsOneWidget);
        expect(find.text('冒险'), findsOneWidget);
        expect(find.text('EPUB'), findsOneWidget);
        expect(find.text('320 pages'), findsOneWidget);
        expect(find.text('48 pages'), findsOneWidget);
        expect(find.text('15.0%'), findsOneWidget);
        expect(find.byKey(sourceStatusKey), findsOneWidget);

        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('library-book-info-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.position.maxScrollExtent, greaterThan(0));

        final close = find.widgetWithText(FilledButton, 'Close');
        expect(close, findsOneWidget);
        expect(close.hitTestable(), findsOneWidget);
        expect(find.bySemanticsLabel('Close'), findsOneWidget);
        expect(tester.getBottomRight(close).dy, lessThanOrEqualTo(568 - 28));

        expect(sourceBook.status, ' 连载中 ');
        expect(sourceBook.categories, ['  奇幻  ', '冒险']);

        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.text(longTitle), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );
}

Widget _infoHost(Widget sheet) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: sheet),
);

Widget _sheetHost({
  required Book book,
  required BookSourceBook sourceBook,
  required String sourceLabel,
  required Widget sourceStatus,
  required MediaQueryData media,
  required Brightness brightness,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(brightness: brightness, colorSchemeSeed: Colors.indigo),
    builder: (context, child) => MediaQuery(data: media, child: child!),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showGlassBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.86,
              ),
              builder: (_) => LibraryBookInfoSheet(
                book: book,
                cover: const ColoredBox(
                  key: ValueKey<String>('library-info-cover'),
                  color: Colors.deepPurple,
                ),
                sourceBook: sourceBook,
                sourceLabel: sourceLabel,
                sourceStatus: sourceStatus,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}
