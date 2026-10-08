import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/source_book_update_info.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/widgets/book_update_indicator.dart';

void main() {
  for (final status in [
    SourceBookCheckStatus.available,
    SourceBookCheckStatus.failed,
  ]) {
    for (final size in [const Size(64, 96), const Size(120, 180)]) {
      testWidgets(
        'new chapters retain one small top-right cover marker at $size ($status)',
        (tester) async {
          final book = Book(
            title: 'Book',
            filePath: '',
            format: 'source',
            sourceBookJson: '{}',
          );
          final updated = book.copyWith(
            sourceBookJson: SourceBookUpdateInfo(
              status: status,
              newChapterCount: 2,
            ).encodeInto(book),
          );
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: BookUpdateIndicator(
                      book: updated,
                      child: const ColoredBox(color: Colors.blue),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = find.byKey(
            const ValueKey('book-cover-update-indicator'),
          );
          expect(badge, findsOneWidget);
          expect(tester.getSize(badge), const Size(18, 18));
          expect(
            find.descendant(of: badge, matching: find.text('2')),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.update_rounded), findsNothing);
          final cover = tester.getRect(find.byType(BookUpdateIndicator));
          final marker = tester.getRect(badge);
          expect(marker.top - cover.top, 4);
          expect(cover.right - marker.right, 4);
          expect(find.text('书籍更新'), findsNothing);
          expect(find.text('有新章节'), findsNothing);
          expect(find.byTooltip('有新章节 · 2 章'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            MaterialApp(
              home: BookUpdateIndicator(
                book: book,
                child: const SizedBox(width: 64, height: 96),
              ),
            ),
          );
          expect(
            find.byKey(const ValueKey('book-cover-update-indicator')),
            findsNothing,
          );
        },
      );
    }
  }

  for (final count in [0, -1, null]) {
    testWidgets('unknown update count $count keeps the update icon', (
      tester,
    ) async {
      final book = Book(
        title: 'Online book',
        filePath: '',
        format: 'source',
        storageType: 'online',
        sourceBookJson:
            '{"_openReadingUpdates":{"status":"available"'
            '${count == null ? '' : ',"newChapterCount":$count'}}}',
      );
      await _pumpCover(tester, book);
      expect(find.byIcon(Icons.update_rounded), findsOneWidget);
      expect(find.byTooltip('有新章节'), findsOneWidget);
      final badge = find.byKey(const ValueKey('book-cover-update-indicator'));
      expect(tester.getSize(badge), const Size(18, 18));
      expect(
        find.descendant(of: badge, matching: find.byType(Text)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final count in [1, 12, 128, 1234]) {
    for (final brightness in Brightness.values) {
      testWidgets('shows the full count $count in $brightness', (tester) async {
        final book = Book(
          title: 'Online book',
          filePath: '',
          format: 'source',
          storageType: 'online',
          sourceBookJson: '{}',
        );
        await _pumpCover(
          tester,
          book.copyWith(
            sourceBookJson: SourceBookUpdateInfo(
              status: SourceBookCheckStatus.available,
              newChapterCount: count,
            ).encodeInto(book),
          ),
          brightness: brightness,
          textScale: 2,
        );
        final badge = find.byKey(const ValueKey('book-cover-update-indicator'));
        final label = find.descendant(of: badge, matching: find.text('$count'));
        expect(label, findsOneWidget);
        expect(find.byIcon(Icons.update_rounded), findsNothing);
        final cover = tester.getRect(find.byType(BookUpdateIndicator));
        final marker = tester.getRect(badge);
        expect(cover.contains(marker.topLeft), isTrue);
        expect(cover.contains(marker.bottomRight), isTrue);
        expect(marker.contains(tester.getRect(label).topLeft), isTrue);
        expect(marker.contains(tester.getRect(label).bottomRight), isTrue);
        expect(marker.top - cover.top, 4);
        expect(cover.right - marker.right, 4);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('failed check keeps an unknown update icon', (tester) async {
    final book = Book(
      title: 'Online book',
      filePath: '',
      format: 'source',
      storageType: 'online',
      sourceBookJson: '{}',
    );
    await _pumpCover(
      tester,
      book.copyWith(
        sourceBookJson: const SourceBookUpdateInfo(
          status: SourceBookCheckStatus.failed,
          hasUnacknowledgedUpdate: true,
        ).encodeInto(book),
      ),
    );
    expect(find.byIcon(Icons.update_rounded), findsOneWidget);
    expect(find.byTooltip('有新章节'), findsOneWidget);
  });

  testWidgets('large count fits a small list cover with enlarged type', (
    tester,
  ) async {
    final book = Book(
      title: 'Online book',
      filePath: '',
      format: 'source',
      storageType: 'online',
      sourceBookJson: '{}',
    );
    await _pumpCover(
      tester,
      book.copyWith(
        sourceBookJson: const SourceBookUpdateInfo(
          status: SourceBookCheckStatus.available,
          newChapterCount: 123456,
        ).encodeInto(book),
      ),
      size: const Size(64, 96),
      textScale: 2,
    );
    final badge = tester.getRect(
      find.byKey(const ValueKey('book-cover-update-indicator')),
    );
    final text = tester.getRect(find.text('123456'));
    final cover = tester.getRect(find.byType(BookUpdateIndicator));
    expect(cover.contains(badge.topLeft), isTrue);
    expect(cover.contains(badge.bottomRight), isTrue);
    expect(text.width, greaterThan(0));
    expect(badge.contains(text.topLeft), isTrue);
    expect(badge.contains(text.bottomRight), isTrue);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('123456'), matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    final glyphs = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 6),
    );
    expect(glyphs, isNotEmpty);
    for (final box in glyphs) {
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + 0.5));
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCover(
  WidgetTester tester,
  Book book, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
  Size size = const Size(120, 180),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: BookUpdateIndicator(
                book: book,
                child: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
