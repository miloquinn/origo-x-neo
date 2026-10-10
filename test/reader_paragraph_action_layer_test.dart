import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/canonical_locator.dart';
import 'package:xxread/core/reader/native_text_paginator.dart';
import 'package:xxread/core/reader/reader_text_layout.dart';
import 'package:xxread/core/reader/reader_text_pagination.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/reader_paragraph_action_layer.dart';
import 'package:xxread/widgets/reader_tap_observer.dart';
import 'package:xxread/widgets/reader_text_page_content.dart';

void main() {
  testWidgets('merged paragraph actions remain independently reachable', (
    tester,
  ) async {
    const source = '合并后的正文。';
    final clicked = <String>[];
    await _render(
      tester,
      source: source,
      page: const ReaderTextPage(text: source, endOffset: source.length),
      actions: [
        _action('first', source.length, clicked),
        _action('second', source.length, clicked),
      ],
    );
    await tester.tap(
      find.byKey(const ValueKey('reader-paragraph-action:first')),
    );
    await tester.pumpAndSettle();
    expect(clicked, isEmpty);
    expect(
      find.byKey(const ValueKey('reader-paragraph-choice:first')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('reader-paragraph-choice:second')),
    );
    await tester.pumpAndSettle();
    expect(clicked, ['second']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('actions follow real glyphs without becoming selectable text', (
    tester,
  ) async {
    const source = '同一段落。\n同一段落。\n结尾😀。';
    final layout = ReaderTextLayout.build(
      source,
      firstLineIndent: 2,
      paragraphSpacing: 1,
    );
    final page = ReaderTextPage(
      text: layout.text,
      layout: layout,
      endOffset: source.length,
    );
    final clicked = <String>[];
    var pageTaps = 0;
    var spoken = 0;
    await _render(
      tester,
      source: source,
      page: page,
      actions: [
        _action('first', source.indexOf('\n'), clicked),
        _action('last', source.length, clicked),
      ],
      onPageTap: () => pageTaps++,
      onPlay: (_) => spoken++,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(ReaderTextPageContent),
        matching: find.byType(RichText),
      ),
    );
    expect(paragraph.text.toPlainText(), layout.text);
    expect(paragraph.size.width, 320 - ReaderParagraphActionLayer.gutter);
    final bubble = find.byKey(const ValueKey('reader-paragraph-action:last'));
    final offset = page.textOffsetForSourceOffset(source.length - 1);
    final glyph = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + 1),
        )
        .last
        .toRect();
    expect(
      tester.getCenter(bubble).dy,
      closeTo(paragraph.localToGlobal(glyph.center).dy, 0.1),
    );
    expect(
      tester.getRect(bubble).left,
      greaterThanOrEqualTo(
        paragraph.localToGlobal(Offset.zero).dx + paragraph.size.width,
      ),
    );
    await tester.tap(bubble);
    await tester.pump();
    expect(clicked, ['last']);
    expect(pageTaps, 0);
    expect(spoken, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the page containing a paragraph end shows its action', (
    tester,
  ) async {
    const source = '第一段。跨页段落的结尾。';
    const page = ReaderTextPage(text: '的结尾。', startOffset: 8, endOffset: 12);
    final clicked = <String>[];
    await _render(
      tester,
      source: source,
      page: page,
      actions: [
        _action('previous', 4, clicked),
        _action('end', 12, clicked),
        _action('next', 13, clicked),
      ],
    );
    expect(
      find.byKey(const ValueKey('reader-paragraph-action:previous')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reader-paragraph-action:next')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('reader-paragraph-action:end')));
    await tester.pump();
    expect(clicked, ['end']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('continuous content uses its natural height and action gutter', (
    tester,
  ) async {
    const source = '第一段。\n第二段。';
    await _render(
      tester,
      source: source,
      page: const ReaderTextPage(text: source, endOffset: source.length),
      actions: [_action('end', source.length, [])],
      fill: false,
    );
    expect(
      tester.getSize(find.byType(ReaderParagraphActionLayer)).height,
      lessThan(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapters without actions keep the full original text width', (
    tester,
  ) async {
    const source = '没有段评的正文';
    await _render(
      tester,
      source: source,
      page: const ReaderTextPage(text: source),
      actions: [],
      gutter: 0,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(ReaderTextPageContent),
        matching: find.byType(RichText),
      ),
    );
    expect(paragraph.size.width, 320);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
  });
}

ReaderParagraphAction _action(String id, int end, List<String> clicked) =>
    ReaderParagraphAction(
      id: id,
      endOffset: end,
      label: '查看段评',
      onPressed: () => clicked.add(id),
    );

Future<void> _render(
  WidgetTester tester, {
  required String source,
  required ReaderTextPage page,
  required List<ReaderParagraphAction> actions,
  VoidCallback? onPageTap,
  ValueChanged<int>? onPlay,
  bool fill = true,
  double gutter = ReaderParagraphActionLayer.gutter,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            height: 320,
            child: ReaderTapObserver(
              onTap: (_) => onPageTap?.call(),
              child: Align(
                alignment: Alignment.topLeft,
                child: ReaderAnnotatedTextPage(
                  page: page,
                  sourceText: source,
                  chapterId: 'chapter',
                  chapterTitle: '',
                  chapterIndex: 0,
                  pageIndex: 0,
                  bookId: 1,
                  format: BookFormat.txt,
                  renderer: ReaderRendererType.flutterNative,
                  palette: ReaderThemes.day,
                  bodyStyle: const TextStyle(fontSize: 20, height: 1.8),
                  flowStyle: const NativeTextFlowStyle(
                    textDirection: TextDirection.ltr,
                    textScaler: TextScaler.noScaling,
                    locale: null,
                    strutStyle: null,
                    textHeightBehavior: null,
                  ),
                  annotations: [],
                  onSaveTextAnnotation: (_, _) async {},
                  paragraphActions: actions,
                  paragraphActionGutter: gutter,
                  fillAvailableSpace: fill,
                  onPlayFromOffset: onPlay,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
