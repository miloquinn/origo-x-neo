import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/book_details_header.dart';
import 'package:xxread/widgets/glass_surface.dart';

void main() {
  testWidgets('phone header keeps identity beside cover and tags below it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        const BookDetailsHeader(
          title: 'The Long Journey',
          author: 'A Patient Author',
          sourceLabel: 'Personal Source',
          status: 'Ongoing',
          categories: ['Fantasy', 'Adventure'],
          cover: ColoredBox(color: Colors.deepPurple),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(GlassSurface), findsOneWidget);
    final cover = tester.getRect(
      find.byKey(const ValueKey('book-details-cover')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('book-details-title')),
    );
    final tags = tester.getRect(
      find.byKey(const ValueKey('book-details-tags')),
    );

    expect(cover.right, lessThan(title.left));
    expect(tags.top, greaterThanOrEqualTo(cover.bottom));
    expect(find.text('The Long Journey'), findsOneWidget);
    expect(find.text('A Patient Author'), findsOneWidget);
    expect(find.text('Personal Source'), findsOneWidget);
  });

  testWidgets('narrow large text stacks without losing identity', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _host(
          const BookDetailsHeader(
            title: 'A title that remains readable at a large text setting',
            author: 'A long author name that is still retained',
            sourceLabel: 'Accessible source',
            cover: ColoredBox(color: Colors.teal),
            framed: false,
          ),
          textScaler: const TextScaler.linear(1.6),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(GlassSurface), findsNothing);
      final cover = tester.getRect(
        find.byKey(const ValueKey('book-details-cover')),
      );
      final title = tester.getRect(
        find.byKey(const ValueKey('book-details-title')),
      );
      expect(cover.bottom, lessThan(title.top));
      expect(
        find.text('A title that remains readable at a large text setting'),
        findsOneWidget,
      );
      expect(
        find.text('A long author name that is still retained'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'A title that remains readable at a large text setting',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tags trim and deduplicate for display without mutating input', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const rawStatus = '  Ongoing  ';
    final rawCategories = <String>[
      ' Fantasy ',
      'Fantasy',
      '  ',
      'Adventure',
      'Ongoing',
    ];

    await tester.pumpWidget(
      _host(
        BookDetailsHeader(
          title: 'Ordered tags',
          author: 'Author',
          status: rawStatus,
          categories: rawCategories,
          cover: const ColoredBox(color: Colors.orange),
          framed: false,
        ),
      ),
    );

    final tags = find.byKey(const ValueKey('book-details-tags'));
    final messages = tester
        .widgetList<Tooltip>(
          find.descendant(of: tags, matching: find.byType(Tooltip)),
        )
        .map((tooltip) => tooltip.message)
        .toList();
    expect(messages, ['Ongoing', 'Fantasy', 'Adventure']);
    expect(find.text('Ongoing'), findsOneWidget);
    expect(find.text('Fantasy'), findsOneWidget);
    expect(find.text('Adventure'), findsOneWidget);
    expect(find.text(rawStatus), findsNothing);
    expect(rawStatus, '  Ongoing  ');
    expect(rawCategories, [
      ' Fantasy ',
      'Fantasy',
      '  ',
      'Adventure',
      'Ongoing',
    ]);
  });

  testWidgets('overflowing tags expand and collapse from two measured rows', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const labels = [
      'Status in progress',
      'Epic fantasy',
      'Long adventure',
      'Found family',
      'Political intrigue',
      'Slow burn mystery',
      'Ancient mythology retold across an exceptionally long category label',
    ];

    await tester.pumpWidget(
      _host(
        const BookDetailsHeader(
          title: 'Many categories',
          author: 'Author',
          status: 'Status in progress',
          categories: labels,
          cover: ColoredBox(color: Colors.blueGrey),
          framed: false,
        ),
        disableAnimations: true,
      ),
    );

    final tags = find.byKey(const ValueKey('book-details-tags'));
    final toggle = find.byKey(const ValueKey('book-details-tags-toggle'));
    expect(toggle, findsOneWidget);
    final collapsedTooltips = find.descendant(
      of: tags,
      matching: find.byType(Tooltip),
    );
    expect(collapsedTooltips.evaluate().length, lessThan(labels.length));
    expect(_rowTops(tester, collapsedTooltips), hasLength(2));
    for (final tooltip in tester.widgetList<Tooltip>(collapsedTooltips)) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(tooltip),
          matching: find.byType(Text),
        ),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final expandedTooltips = find.descendant(
      of: tags,
      matching: find.byType(Tooltip),
    );
    expect(expandedTooltips, findsNWidgets(labels.length));
    expect(_rowTops(tester, expandedTooltips).length, greaterThan(2));
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    for (final tooltip in tester.widgetList<Tooltip>(expandedTooltips)) {
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byWidget(tooltip),
          matching: find.byType(Text),
        ),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }
    expect(
      tester.getSize(find.text(labels.last)).width,
      lessThanOrEqualTo(tester.getSize(tags).width),
    );

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find
          .descendant(of: tags, matching: find.byType(Tooltip))
          .evaluate()
          .length,
      lessThan(labels.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet RTL keeps the logical cover and identity order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _host(
        const BookDetailsHeader(
          title: 'عنوان الكتاب',
          author: 'اسم المؤلف',
          status: 'مستمر',
          categories: ['خيال', 'مغامرة'],
          cover: ColoredBox(color: Colors.brown),
          framed: false,
        ),
        textDirection: TextDirection.rtl,
      ),
    );

    expect(tester.takeException(), isNull);
    final cover = tester.getRect(
      find.byKey(const ValueKey('book-details-cover')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('book-details-title')),
    );
    expect(cover.left, greaterThan(title.right));
    expect(find.text('مستمر'), findsOneWidget);
    expect(find.text('خيال'), findsOneWidget);
    expect(find.text('مغامرة'), findsOneWidget);
  });
}

Set<int> _rowTops(WidgetTester tester, Finder tooltips) => {
  for (var index = 0; index < tooltips.evaluate().length; index++)
    tester.getTopLeft(tooltips.at(index)).dy.round(),
};

Widget _host(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) {
  return MaterialApp(
    builder: (context, materialChild) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: textScaler, disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: textDirection,
        child: materialChild!,
      ),
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}
