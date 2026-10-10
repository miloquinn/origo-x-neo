import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';
import 'package:xxread/pages/book_sources/sourced_book_details_page.dart';
import 'package:xxread/pages/book_sources/widgets/sourced_book_cards.dart';
import 'package:xxread/services/library/download_task_controller.dart';
import 'package:xxread/widgets/glass_surface.dart';

void main() {
  testWidgets(
    'summary and reading remain available while details load and fail',
    (tester) async {
      final gateway = _Gateway(pending: Completer<BookSourceBook>());
      await tester.pumpWidget(_harness(gateway: gateway));
      expect(find.text('山海之间'), findsWidgets);
      expect(find.byKey(const Key('bookSourceDetailsLoading')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('bookSourceReadButton')))
            .onPressed,
        isNotNull,
      );
      gateway.pending!.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bookSourceDetailsLoading')), findsNothing);
      expect(
        find.byKey(const Key('bookSourceDetailsRetryButton')),
        findsOneWidget,
      );
      expect(find.text(_book.description), findsOneWidget);
      gateway.pending = null;
      await tester.tap(find.byKey(const Key('bookSourceDetailsRetryButton')));
      await tester.pumpAndSettle();
      expect(gateway.calls, 2);
      expect(
        find.byKey(const Key('bookSourceDetailsRetryButton')),
        findsNothing,
      );
    },
  );

  testWidgets('reader returns to details and can be opened again', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      _harness(
        onRead: (context, book) async {
          reads++;
          expect(book.id, _book.id);
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Reader')),
                body: const Text('Chapter content'),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('bookSourceReadButton')));
      await tester.pumpAndSettle();
      expect(find.text('Chapter content'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bookSourceDetailsPage')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('bookSourceReadButton')))
            .onPressed,
        isNotNull,
      );
    }
    expect(reads, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('more menu opens shared book settings with source login', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('bookSourceDetailsMoreButton')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('bookSourceDetailsMoreButton')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('bookSourceDetailsSettingsMenuItem')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('bookSourceDetailsSettingsMenuItem')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book-settings-page')), findsOneWidget);
    expect(find.byKey(const Key('book-settings-login-action')), findsOneWidget);
    expect(find.byKey(const Key('book-settings-edit-action')), findsNothing);
    expect(find.byKey(const Key('book-settings-reading-action')), findsNothing);
    expect(
      find.byKey(const Key('book-settings-replace-rules-action')),
      findsNothing,
    );
    expect(find.text(_book.title), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book-settings-page')), findsNothing);
    expect(find.byKey(const Key('bookSourceDetailsPage')), findsOneWidget);
    expect(
      find.byKey(const Key('bookSourceReadButton')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('bookSourceAddToShelfButton')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending shelf add cannot be submitted twice and stays on page', (
    tester,
  ) async {
    final shelf = _Shelf(pending: Completer<Book>());
    await tester.pumpWidget(_harness(shelf: shelf));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bookSourceAddToShelfButton')));
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('bookSourceAddToShelfButton')),
          )
          .onPressed,
      isNull,
    );
    expect(shelf.adds, 1);
    shelf.pending!.complete(_shelfBook);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bookSourceOnShelf')), findsOneWidget);
    expect(find.byKey(const Key('bookSourceDetailsPage')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating actions keep add failure and retry visible after scrolling',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 700);
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      final shelf = _Shelf(failNextAdd: true);
      await tester.pumpWidget(
        _harness(
          shelf: shelf,
          book: BookSourceBook(
            id: 'retry-visible',
            categories: const [],
            title: '山海之间',
            author: '林间客',
            description: List.generate(
              20,
              (index) => '第 $index 段长简介。',
            ).join('\n\n'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(
            find.ancestor(
              of: find.byKey(const Key('bookSourceDetailsContent')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('bookSourceAddToShelfButton')));
      await tester.pumpAndSettle();
      final retry = find.byKey(const Key('bookSourceAddRetryButton'));
      expect(retry.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('bookSourceDetailsScroll'))).bottom,
        700,
      );
      expect(
        tester.getRect(find.byKey(const Key('bookSourceReadButton'))).bottom,
        lessThanOrEqualTo(700 - 34),
      );
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(shelf.adds, 2);
      expect(find.byKey(const Key('bookSourceOnShelf')), findsOneWidget);
      expect(retry, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelled download can be dismissed without leaving details', (
    tester,
  ) async {
    final shelf = _Shelf();
    await tester.pumpWidget(_harness(shelf: shelf));
    await tester.pumpAndSettle();
    final option = find.byKey(const Key('bookSourceDownloadLocalOption'));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceReadButton')))
          .onPressed,
      isNull,
    );
    final cancel = find.descendant(
      of: find.byKey(const Key('bookSourceDownloadInline')),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pump();
    shelf.download.complete(_shelfBook);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bookSourceDownloadInline')), findsOneWidget);
    final back = find.descendant(
      of: find.byKey(const Key('bookSourceDownloadInline')),
      matching: find.byType(TextButton),
    );
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bookSourceDownloadInline')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('bookSourceReadButton')))
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(const Key('bookSourceDetailsPage')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard Android-width phones keep book identity horizontal', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final cover = tester.getRect(find.byType(SourcedBookCoverThumb));
    final title = tester.getRect(find.text(_book.title));
    expect(title.left, greaterThanOrEqualTo(cover.right + 20));
    expect(title.top, lessThanOrEqualTo(cover.top + 4));
  });

  testWidgets('long genres use the full width beneath book identity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 844);
    addTearDown(tester.view.reset);
    const genre = '历史人物与时代洪流中的选择以及非常长的分类名称';
    await tester.pumpWidget(
      _harness(
        book: const BookSourceBook(
          id: 'long-genre',
          title: '山海之间',
          author: '林间客',
          description: '',
          categories: [genre],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cover = tester.getRect(find.byType(SourcedBookCoverThumb));
    final tag = tester.getRect(find.text(genre));
    expect(tag.left, lessThanOrEqualTo(cover.left + 16));
    expect(tag.top, greaterThanOrEqualTo(cover.bottom + 12));
    expect(tester.widget<Text>(find.text(genre)).maxLines, 1);
    expect(tag.right, lessThanOrEqualTo(340));
    expect(tester.takeException(), isNull);
  });

  testWidgets('many genres expand without obscuring detail actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final genres = List.generate(24, (index) => '分类标签 $index');
    await tester.pumpWidget(
      _harness(
        book: BookSourceBook(
          id: 'many-genres',
          title: '山海之间',
          author: '林间客',
          description: '',
          categories: genres,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(genres.last), findsNothing);
    final toggle = find.byKey(const ValueKey('book-details-tags-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(genres.last), findsOneWidget);
    expect(
      find.byKey(const Key('bookSourceReadButton')).hitTestable(),
      findsOneWidget,
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(genres.last), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('display labels trim and deduplicate source metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        book: const BookSourceBook(
          id: 'duplicate-genres',
          title: '山海之间',
          author: '林间客',
          description: '',
          status: ' 完结 ',
          categories: [' 文学 ', '文学', '完结', ' ', '文学'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(' 文学 '), findsNothing);
    expect(find.text(' 完结 '), findsNothing);
    expect(find.text('文学'), findsOneWidget);
    expect(find.text('完结'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final variant in [
    (name: 'mobile', size: const Size(390, 844), scale: 1.0, dark: false),
    (name: 'narrow', size: const Size(320, 640), scale: 1.0, dark: false),
    (name: 'dark-large', size: const Size(390, 844), scale: 1.6, dark: true),
    (name: 'tablet', size: const Size(1100, 850), scale: 1.0, dark: false),
  ]) {
    testWidgets('details stay usable at ${variant.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = variant.size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.reset);
      final previewDir = Platform.environment['DETAILS_PREVIEW_DIR'];
      if (previewDir != null) {
        await tester.runAsync(() async {
          final font = await File(
            '/System/Library/Fonts/Hiragino Sans GB.ttc',
          ).readAsBytes();
          await (FontLoader(
            'DetailsPreview',
          )..addFont(Future.value(ByteData.sublistView(font)))).load();
          await (FontLoader(
            'Ahem',
          )..addFont(Future.value(ByteData.sublistView(font)))).load();
          final root = Platform.resolvedExecutable.split('/bin/cache').first;
          final icons = await File(
            '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes();
          await (FontLoader(
            'MaterialIcons',
          )..addFont(Future.value(ByteData.sublistView(icons)))).load();
        });
      }
      await tester.pumpWidget(
        _harness(scale: variant.scale, dark: variant.dark),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final viewport = find.byKey(const Key('bookSourceDetailsScroll'));
      expect(tester.getRect(viewport).bottom, variant.size.height);
      expect(
        find.ancestor(
          of: find.byKey(const Key('bookSourceReadButton')),
          matching: find.byType(GlassSurface),
        ),
        findsNothing,
        reason: 'detail actions float individually over the scrolling content',
      );
      final scrollable = find.ancestor(
        of: find.byKey(const Key('bookSourceDetailsContent')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.byKey(const Key('bookSourceDownloadLocalOption')))
            .bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const Key('bookSourceReadButton'))).top -
              12,
        ),
        reason:
            'the last detail action can scroll completely above the buttons',
      );
      final readRect = tester.getRect(
        find.byKey(const Key('bookSourceReadButton')),
      );
      expect(readRect.bottom, lessThanOrEqualTo(variant.size.height - 20));
      expect(readRect.height, greaterThanOrEqualTo(48));
      if (previewDir != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('detailsPreview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(previewDir).create(recursive: true);
          await File(
            '$previewDir/${variant.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(
        find.byKey(const Key('bookSourceDownloadLocalOption')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('bookSourceDownloadLocalOption')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _harness({
  _Gateway? gateway,
  _Shelf? shelf,
  BookSourceBook book = _book,
  double scale = 1,
  bool dark = false,
  Future<void> Function(BuildContext, BookSourceBook)? onRead,
}) => ChangeNotifierProvider(
  create: (_) => DownloadTaskController(),
  child: MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'DetailsPreview',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF526B62),
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: RepaintBoundary(key: const Key('detailsPreview'), child: child!),
    ),
    home: SourcedBookDetailsPage(
      result: SourcedBook(source: _source, book: book),
      gateway: gateway ?? _Gateway(book: book),
      shelfService: shelf ?? _Shelf(),
      onRead: onRead ?? (_, _) async {},
      onDownloadContinuesInBackground: () {},
    ),
  ),
);

final _source = RegisteredBookSource(
  id: 'source',
  name: '山海书屋',
  description: '',
  manifestUrl: Uri.parse('https://example.org/source.json'),
  apiBaseUrl: Uri.parse('https://example.org/api/'),
  protocolVersion: '1.1',
  languages: const ['zh'],
  capabilities: const {'search'},
  enabled: true,
  addedAt: DateTime.utc(2026),
);
const _book = BookSourceBook(
  id: 'book',
  title: '山海之间',
  author: '林间客',
  description:
      '一封来自故乡的信，让远行多年的游子重新踏上归途。\n\n沿着旧时的山路，他走过晨雾中的村落、海边的灯塔，也慢慢找回那些被岁月遗忘的名字。这是关于相遇、告别与重新出发的故事。',
  categories: ['文学', '旅行'],
  status: '连载中',
  latestChapter: '第二十四章 · 风从海上来',
);
final _shelfBook = Book(
  id: 1,
  title: _book.title,
  author: _book.author,
  filePath: '',
  format: 'source',
  storageType: 'online',
  sourceId: 'source',
  sourceBookId: 'book',
);

class _Gateway extends BookSourceClient {
  _Gateway({this.pending, this.book = _book});
  Completer<BookSourceBook>? pending;
  final BookSourceBook book;
  int calls = 0;
  @override
  Future<BookSourceBook> getBook(
    RegisteredBookSource source,
    String bookId, {
    Map<String, String> sourceVariables = const {},
  }) async {
    calls++;
    return pending?.future ?? book;
  }
}

class _Shelf extends BookSourceShelfService {
  _Shelf({this.pending, this.failNextAdd = false});
  final Completer<Book>? pending;
  bool failNextAdd;
  bool added = false;
  int adds = 0;
  final download = Completer<Book>();

  @override
  Future<Book> downloadToLocal({
    required RegisteredBookSource source,
    required BookSourceBook book,
    String? bookUid,
    void Function(int completed, int total)? onProgress,
    BookDownloadCancellation? cancellation,
  }) {
    onProgress?.call(1, 3);
    return download.future;
  }

  @override
  Future<Book?> findShelfBook({
    required String sourceId,
    required String sourceBookId,
  }) async => added ? _shelfBook : null;
  @override
  Future<Book> addOnline({
    required RegisteredBookSource source,
    required BookSourceBook book,
  }) async {
    adds++;
    if (failNextAdd) {
      failNextAdd = false;
      throw StateError('offline');
    }
    final result = await (pending?.future ?? Future.value(_shelfBook));
    added = true;
    return result;
  }
}
