import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/canonical_locator.dart';
import 'package:xxread/core/reader/native_text_paginator.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/core/reader/reader_annotation.dart';
import 'package:xxread/core/reader/reader_text_pagination.dart';
import 'package:xxread/core/reader/reader_text_layout.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book_note.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_annotated_text_page.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/reader_chapter_title_page.dart';
import 'package:xxread/widgets/reader_tap_observer.dart';

void main() {
  testWidgets('sentence tap consumes page tap on either half of a glyph', (
    tester,
  ) async {
    final offsets = <int>[];
    var pageTaps = 0;
    await _renderTapPage(
      tester,
      onPlay: offsets.add,
      onPageTap: () => pageTaps++,
    );
    final paragraph = _tapParagraph(tester);
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 1, extentOffset: 2),
        )
        .single
        .toRect();
    for (final fraction in [0.25, 0.75]) {
      await tester.tapAt(
        paragraph.localToGlobal(
          Offset(box.left + box.width * fraction, box.center.dy),
        ),
      );
      await tester.pump();
    }
    expect(offsets, [1, 1]);
    expect(pageTaps, 0);
  });

  testWidgets('blank page space keeps the existing tap action', (tester) async {
    final offsets = <int>[];
    var pageTaps = 0;
    await _renderTapPage(
      tester,
      onPlay: offsets.add,
      onPageTap: () => pageTaps++,
    );
    final paragraph = _tapParagraph(tester);
    await tester.tapAt(paragraph.localToGlobal(const Offset(330, 120)));
    await tester.pump();
    expect(offsets, isEmpty);
    expect(pageTaps, 1);
  });

  testWidgets('disabled sentence navigation leaves ordinary page taps intact', (
    tester,
  ) async {
    var pageTaps = 0;
    await _renderTapPage(tester, onPageTap: () => pageTaps++);
    final paragraph = _tapParagraph(tester);
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 1, extentOffset: 2),
        )
        .single
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await tester.pump();
    expect(pageTaps, 1);
  });

  testWidgets('generated indentation maps glyph taps to canonical text', (
    tester,
  ) async {
    const source = '甲句。\n乙句。';
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
    final offsets = <int>[];
    var pageTaps = 0;
    await _renderTapPage(
      tester,
      source: source,
      page: page,
      onPlay: offsets.add,
      onPageTap: () => pageTaps++,
    );
    final paragraph = _tapParagraph(tester);
    final displayOffset = layout.text.indexOf('乙');
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(
            baseOffset: displayOffset,
            extentOffset: displayOffset + 1,
          ),
        )
        .single
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await tester.pump();
    expect(offsets, [4]);
    expect(pageTaps, 0);
    final indent = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .single
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(indent.center));
    await tester.pump();
    expect(offsets, [4]);
    expect(pageTaps, 1);
  });

  testWidgets('cross-page text taps retain chapter offsets', (tester) async {
    const source = '甲句。乙句继续跨页。';
    const page = ReaderTextPage(text: '继续跨页。', startOffset: 5);
    final offsets = <int>[];
    await _renderTapPage(
      tester,
      source: source,
      page: page,
      onPlay: offsets.add,
      onPageTap: () {},
    );
    final paragraph = _tapParagraph(tester);
    final box = paragraph
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .single
        .toRect();
    await tester.tapAt(paragraph.localToGlobal(box.center));
    await tester.pump();
    expect(offsets, [5]);
  });

  testWidgets(
    'sentence navigation leaves long press selection and drags alone',
    (tester) async {
      final offsets = <int>[];
      var pageTaps = 0;
      await _renderTapPage(
        tester,
        onPlay: offsets.add,
        onPageTap: () => pageTaps++,
      );
      final paragraph = _tapParagraph(tester);
      final box = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 1, extentOffset: 2),
          )
          .single
          .toRect();
      final position = paragraph.localToGlobal(box.center);
      final gesture = await tester.startGesture(position);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('reader-selection-toolbar')),
        findsOneWidget,
      );
      await tester.dragFrom(position, const Offset(80, 0));
      await tester.pump();
      expect(offsets, isEmpty);
      expect(pageTaps, 0);
    },
  );

  testWidgets('moving spoken highlight preserves every character position', (
    tester,
  ) async {
    const source = '翻页后正文保持原来的字重。正在朗读的句子只改变背景色。Next sentence stays in place.';
    const bodyStyle = TextStyle(
      fontSize: 20,
      height: 1.6,
      fontWeight: FontWeight.w400,
    );
    Future<List<Rect>> render(ReaderAloudHighlight? highlight) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 240,
              height: 500,
              child: ReaderAnnotatedTextPage(
                page: const ReaderTextPage(text: source),
                sourceText: source,
                chapterId: 'chapter-1',
                chapterTitle: '第一章',
                chapterIndex: 0,
                pageIndex: 0,
                bookId: 1,
                format: BookFormat.txt,
                renderer: ReaderRendererType.flutterNative,
                palette: ReaderThemes.day,
                bodyStyle: bodyStyle,
                flowStyle: const NativeTextFlowStyle(
                  textDirection: TextDirection.ltr,
                  textScaler: TextScaler.noScaling,
                  locale: Locale('zh'),
                  strutStyle: null,
                  textHeightBehavior: readerTextHeightBehavior,
                ),
                annotations: const [],
                spokenHighlight: highlight,
                onSaveTextAnnotation: (_, _) async {},
              ),
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(ReaderAnnotatedTextPage),
          matching: find.byType(RichText),
        ),
      );
      return [
        for (var i = 0; i < source.length; i++)
          for (final box in paragraph.getBoxesForSelection(
            TextSelection(baseOffset: i, extentOffset: i + 1),
          ))
            box.toRect().shift(paragraph.localToGlobal(Offset.zero)),
      ];
    }

    final original = await render(null);
    expect(original, isNotEmpty);
    for (final range in [(0, 14), (14, 31), (31, source.length)]) {
      expect(
        await render(
          ReaderAloudHighlight(
            chapterIndex: 0,
            chapterId: 'chapter-1',
            startOffset: range.$1,
            endOffset: range.$2,
          ),
        ),
        original,
      );
    }
    expect(await render(null), original);
  });

  testWidgets('inline chapter title is outside selectable body coordinates', (
    tester,
  ) async {
    const bodyStyle = TextStyle(fontSize: 20, height: 1.6);
    const flowStyle = NativeTextFlowStyle(
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      locale: Locale('zh'),
      strutStyle: null,
      textHeightBehavior: readerTextHeightBehavior,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: ReaderAnnotatedTextPage(
              page: const ReaderTextPage(
                text: '正文',
                showsInlineChapterTitle: true,
              ),
              sourceText: '正文',
              chapterId: 'chapter-1',
              chapterTitle: '第一章',
              chapterIndex: 0,
              pageIndex: 0,
              bookId: 1,
              format: BookFormat.txt,
              renderer: ReaderRendererType.flutterNative,
              palette: ReaderThemes.green,
              bodyStyle: bodyStyle,
              flowStyle: flowStyle,
              annotations: const [],
              onSaveTextAnnotation: (_, _) async {},
            ),
          ),
        ),
      ),
    );

    final title = find.byType(ReaderInlineChapterTitle);
    final body = find.descendant(
      of: find.byType(SelectionArea),
      matching: find.byType(RichText),
    );
    expect(title, findsOneWidget);
    expect(
      find.ancestor(of: title, matching: find.byType(SelectionArea)),
      findsNothing,
    );
    expect(
      find.ancestor(of: body, matching: find.byType(SelectionArea)),
      findsOneWidget,
    );
    expect(
      find.ancestor(of: body, matching: find.byType(Expanded)),
      findsOneWidget,
    );
    expect(tester.getTopLeft(title).dy, lessThan(tester.getTopLeft(body).dy));
  });

  testWidgets('inline chapter title uses natural height in scrolling layout', (
    tester,
  ) async {
    const bodyStyle = TextStyle(fontSize: 20, height: 1.6);
    const flowStyle = NativeTextFlowStyle(
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      locale: Locale('zh'),
      strutStyle: null,
      textHeightBehavior: readerTextHeightBehavior,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderAnnotatedTextPage(
            page: const ReaderTextPage(
              text: '正文',
              showsInlineChapterTitle: true,
            ),
            sourceText: '正文',
            chapterId: 'chapter-1',
            chapterTitle: '第一章',
            chapterIndex: 0,
            pageIndex: 0,
            bookId: 1,
            format: BookFormat.txt,
            renderer: ReaderRendererType.flutterNative,
            palette: ReaderThemes.green,
            bodyStyle: bodyStyle,
            flowStyle: flowStyle,
            annotations: const [],
            onSaveTextAnnotation: (_, _) async {},
            fillAvailableSpace: false,
          ),
        ),
      ),
    );

    final body = find.descendant(
      of: find.byType(SelectionArea),
      matching: find.byType(RichText),
    );
    expect(find.byType(ReaderInlineChapterTitle), findsOneWidget);
    expect(
      find.ancestor(of: body, matching: find.byType(Expanded)),
      findsNothing,
    );
  });

  testWidgets(
    'selection toolbar follows the reader palette and saves highlight',
    (tester) async {
      ReaderSelectionSnapshot? savedSelection;
      ReaderAnnotationEditorResult? savedAnnotation;
      var readerTaps = 0;
      const bodyStyle = TextStyle(fontSize: 20, height: 1.6);
      final flowStyle = NativeTextFlowStyle(
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        locale: const Locale('zh'),
        strutStyle: readerStrutStyle(bodyStyle),
        textHeightBehavior: readerTextHeightBehavior,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 260,
                child: ReaderTapObserver(
                  onTap: (_) => readerTaps++,
                  child: ReaderAnnotatedTextPage(
                    page: const ReaderTextPage(text: '选择这段文字进行高亮和批注。'),
                    sourceText: '选择这段文字进行高亮和批注。',
                    chapterId: 'chapter-1',
                    chapterTitle: '第一章',
                    chapterIndex: 0,
                    pageIndex: 0,
                    bookId: 1,
                    format: BookFormat.txt,
                    renderer: ReaderRendererType.flutterNative,
                    palette: ReaderThemes.green,
                    bodyStyle: bodyStyle,
                    flowStyle: flowStyle,
                    annotations: const [],
                    onSaveTextAnnotation: (selection, annotation) async {
                      savedSelection = selection;
                      savedAnnotation = annotation;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = find.descendant(
        of: find.byType(ReaderAnnotatedTextPage),
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(richText);
      final characterBox = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 5, extentOffset: 6),
          )
          .single
          .toRect();
      final gesture = await tester.startGesture(
        paragraph.localToGlobal(characterBox.center),
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      final toolbar = tester.widget<Material>(
        find.byKey(const ValueKey('reader-selection-toolbar')),
      );
      expect(toolbar.color, Colors.transparent);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.byKey(const ValueKey('reader-selection-toolbar')),
            matching: find.byType(GlassSurface),
          ),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(find.text('高亮'), findsOneWidget);
      expect(find.text('批注'), findsNothing);
      expect(find.text('笔记'), findsOneWidget);
      expect(find.text('画笔记'), findsNothing);
      expect(readerTaps, 0);

      await tester.tap(find.text('高亮'));
      await tester.pumpAndSettle();
      expect(find.text('荧光笔颜色'), findsOneWidget);

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(savedSelection?.selectedText, isNotEmpty);
      expect(savedAnnotation?.type, readerAnnotationTypeHighlight);
    },
  );

  for (final action in [
    (name: 'ask AI', label: '问AI'),
    (name: 'purify', label: '净化所选文字'),
    (name: 'search', label: '搜索'),
  ]) {
    testWidgets('${action.name} action hands the selection to the reader', (
      tester,
    ) async {
      ReaderSelectionSnapshot? handedSelection;
      final interactionChanges = <bool>[];
      const bodyStyle = TextStyle(fontSize: 20, height: 1.6);
      final flowStyle = NativeTextFlowStyle(
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        locale: const Locale('zh'),
        strutStyle: readerStrutStyle(bodyStyle),
        textHeightBehavior: readerTextHeightBehavior,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 260,
                child: ReaderAnnotatedTextPage(
                  page: const ReaderTextPage(text: '选择这段文字去问问AI助手。'),
                  sourceText: '选择这段文字去问问AI助手。',
                  chapterId: 'chapter-1',
                  chapterTitle: '第一章',
                  chapterIndex: 0,
                  pageIndex: 0,
                  bookId: 1,
                  format: BookFormat.txt,
                  renderer: ReaderRendererType.flutterNative,
                  palette: ReaderThemes.green,
                  bodyStyle: bodyStyle,
                  flowStyle: flowStyle,
                  annotations: const [],
                  onSaveTextAnnotation: (_, _) async {},
                  onAskAiSelection: action.name == 'ask AI'
                      ? (selection) async {
                          handedSelection = selection;
                        }
                      : null,
                  onPurifySelection: action.name == 'purify'
                      ? (selection) async {
                          handedSelection = selection;
                        }
                      : null,
                  onSearchSelection: action.name == 'search'
                      ? (selection) async {
                          handedSelection = selection;
                        }
                      : null,
                  onInteractionChanged: interactionChanges.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = find.descendant(
        of: find.byType(ReaderAnnotatedTextPage),
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(richText);
      final characterBox = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 5, extentOffset: 6),
          )
          .single
          .toRect();
      final gesture = await tester.startGesture(
        paragraph.localToGlobal(characterBox.center),
      );
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('reader-selection-more')));
      await tester.pumpAndSettle();
      expect(find.text(action.label), findsOneWidget);
      await tester.tap(find.text(action.label));
      await tester.pumpAndSettle();

      expect(handedSelection?.selectedText, isNotEmpty);
      expect(interactionChanges, [true, false]);
    });
  }

  testWidgets(
    'tapping an underlined note opens its details without turning the page',
    (tester) async {
      var readerTaps = 0;
      var sentenceTaps = 0;
      final interactionChanges = <bool>[];
      const sourceText = '点击笔记文字查看内容';
      const bodyStyle = TextStyle(fontSize: 20, height: 1.6);
      final flowStyle = NativeTextFlowStyle(
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        locale: const Locale('zh'),
        strutStyle: readerStrutStyle(bodyStyle),
        textHeightBehavior: readerTextHeightBehavior,
      );
      final note = BookNote(
        bookId: 1,
        content: '点击笔记',
        cfi: 'or-annotation:note:chapter-1:0:4',
        chapter: '第一章',
        type: readerAnnotationTypeNote,
        color: '7DD3FC',
        readerNote: '这是保存的笔记内容。',
        startOffset: 0,
        endOffset: 4,
        createTime: DateTime(2026, 7, 26),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 260,
                child: ReaderTapObserver(
                  onTap: (_) => readerTaps++,
                  child: ReaderAnnotatedTextPage(
                    page: const ReaderTextPage(text: sourceText),
                    sourceText: sourceText,
                    chapterId: 'chapter-1',
                    chapterTitle: '第一章',
                    chapterIndex: 0,
                    pageIndex: 0,
                    bookId: 1,
                    format: BookFormat.txt,
                    renderer: ReaderRendererType.flutterNative,
                    palette: ReaderThemes.night,
                    bodyStyle: bodyStyle,
                    flowStyle: flowStyle,
                    annotations: [note],
                    onPlayFromOffset: (_) => sentenceTaps++,
                    onSaveTextAnnotation: (_, _) async {},
                    onInteractionChanged: interactionChanges.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final richText = find.descendant(
        of: find.byType(ReaderAnnotatedTextPage),
        matching: find.byType(RichText),
      );
      final paragraph = tester.renderObject<RenderParagraph>(richText);
      final noteBox = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 4),
          )
          .first
          .toRect();

      await tester.tapAt(paragraph.localToGlobal(noteBox.center));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('reader-annotation-detail-sheet')),
        findsOneWidget,
      );
      expect(find.text('点击笔记'), findsOneWidget);
      expect(find.text('这是保存的笔记内容。'), findsOneWidget);
      expect(readerTaps, 0);
      expect(sentenceTaps, 0);
      expect(interactionChanges, [true]);

      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(interactionChanges, [true, false]);
    },
  );
}

RenderParagraph _tapParagraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(ReaderAnnotatedTextPage),
        matching: find.byType(RichText),
      ),
    );

Future<void> _renderTapPage(
  WidgetTester tester, {
  String source = '甲句。乙句。',
  ReaderTextPage? page,
  ValueChanged<int>? onPlay,
  required VoidCallback onPageTap,
}) async {
  const style = TextStyle(fontSize: 20, height: 1.6);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 260,
            child: ReaderTapObserver(
              onTap: (_) => onPageTap(),
              child: ReaderAnnotatedTextPage(
                page: page ?? ReaderTextPage(text: source),
                sourceText: source,
                chapterId: 'chapter-1',
                chapterTitle: '第一章',
                chapterIndex: 0,
                pageIndex: 0,
                bookId: 1,
                format: BookFormat.txt,
                renderer: ReaderRendererType.flutterNative,
                palette: ReaderThemes.day,
                bodyStyle: style,
                flowStyle: NativeTextFlowStyle(
                  textDirection: TextDirection.ltr,
                  textScaler: TextScaler.noScaling,
                  locale: const Locale('zh'),
                  strutStyle: readerStrutStyle(style),
                  textHeightBehavior: readerTextHeightBehavior,
                ),
                annotations: const [],
                onSaveTextAnnotation: (_, _) async {},
                onPlayFromOffset: onPlay,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
