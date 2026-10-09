import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_aloud_transcript.dart';

void main() {
  const readerStyle = TextStyle(
    inherit: false,
    fontFamily: 'Book Serif',
    fontFamilyFallback: ['Book CJK'],
    fontSize: 21,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 510)],
    letterSpacing: 1.2,
    height: 1.9,
  );

  Future<ReaderAloudController> open(
    WidgetTester tester, {
    TextStyle? style = readerStyle,
    ReaderAloudTextSpanBuilder? builder,
    bool preserveDocumentFont = false,
  }) async {
    final engine = _HeldEngine();
    final chapter = ReaderAloudChapter(
      index: 0,
      id: 'one',
      title: 'Chapter',
      text: 'Dělám písně a zpívám je! Další věta!',
      buildTextSpan: builder,
    );
    final controller = ReaderAloudController(
      engine: engine,
      source: CallbackReaderAloudSource(
        bookTitle: 'Test book',
        chapterCount: () => 1,
        currentPosition: () async =>
            const ReaderAloudPosition(chapterIndex: 0, offset: 0),
        loadChapter: (_) async => chapter,
        revealPosition: (_) async {},
        persistPosition: (_) async {},
        textStyle: style,
        preserveDocumentFont: preserveDocumentFont,
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await controller.stop();
      controller.dispose();
      engine.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Decorative App Font'),
        home: Scaffold(
          body: ReaderAloudTranscript(
            controller: controller,
            palette: ReaderThemes.day,
          ),
        ),
      ),
    );
    unawaited(controller.start());
    await tester.pumpAndSettle();
    return controller;
  }

  List<Text> sentences(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => text.textSpan != null)
      .toList();

  testWidgets(
    'transcript uses reading typography for active and inactive sentences',
    (tester) async {
      final controller = await open(tester);
      final text = sentences(tester);
      expect(text, hasLength(2));
      for (final sentence in text) {
        final style = sentence.textSpan!.style!;
        expect(style.inherit, isFalse);
        expect(style.fontFamily, readerStyle.fontFamily);
        expect(style.fontFamilyFallback, readerStyle.fontFamilyFallback);
        expect(style.fontSize, 21);
        expect(style.fontWeight, readerStyle.fontWeight);
        expect(style.fontVariations, readerStyle.fontVariations);
        expect(style.height, readerStyle.height);
        expect(style.letterSpacing, readerStyle.letterSpacing);
      }
      expect(text.first.textSpan!.style!.color, ReaderThemes.day.accent);
      expect(text.last.textSpan!.style!.color, ReaderThemes.day.text);
      await tester.tap(
        find.byKey(
          ValueKey(
            'reader-aloud-transcript-segment-0-${controller.chapterSegments.last.startOffset}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentSegment, controller.chapterSegments.last);
      expect(sentences(tester).last.textSpan!.style!.fontFamily, 'Book Serif');
    },
  );

  testWidgets('unspecified reading font cannot inherit the application font', (
    tester,
  ) async {
    await open(tester, style: const TextStyle(inherit: false, fontSize: 19));
    for (final sentence in sentences(tester)) {
      expect(sentence.style!.inherit, isFalse);
      expect(sentence.textSpan!.style!.inherit, isFalse);
      expect(sentence.textSpan!.style!.fontFamily, isNull);
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byWidget(sentence),
          matching: find.byType(RichText),
        ),
      );
      expect(richText.text.style!.fontFamily, isNull);
    }
  });

  testWidgets('mixed book font runs retain typography and highlight color', (
    tester,
  ) async {
    await open(
      tester,
      preserveDocumentFont: true,
      builder: (start, end, base, preserve) {
        expect(preserve, isTrue);
        const text = 'Dělám písně a zpívám je! Další věta!';
        final middle = (start + 5).clamp(start, end);
        return TextSpan(
          style: base,
          children: [
            TextSpan(
              text: text.substring(start, middle),
              style: base.copyWith(fontFamily: 'Embedded Serif'),
            ),
            TextSpan(
              text: text.substring(middle, end),
              style: base.copyWith(
                fontFamily: 'Embedded Alternate',
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      },
    );
    final sentence = sentences(tester).first;
    final span = sentence.textSpan! as TextSpan;
    expect(span.toPlainText(), 'Dělám písně a zpívám je!');
    expect(span.children!.first.style!.fontFamily, 'Embedded Serif');
    expect(span.children!.last.style!.fontFamily, 'Embedded Alternate');
    expect(span.children!.last.style!.fontStyle, FontStyle.italic);
    expect(span.children!.first.style!.color, ReaderThemes.day.accent);
    expect(span.children!.last.style!.color, ReaderThemes.day.accent);
  });
}

class _HeldEngine extends ChangeNotifier implements ReaderAloudEngine {
  Completer<void>? _speech;
  @override
  bool isPlaying = false;
  @override
  bool get isPaused => false;
  @override
  int get currentPosition => 0;
  @override
  Future<void> speak(String text) {
    isPlaying = true;
    _speech = Completer<void>();
    return _speech!.future;
  }

  @override
  Future<void> pause() => stop();
  @override
  Future<void> stop() async {
    isPlaying = false;
    final speech = _speech;
    _speech = null;
    if (speech != null && !speech.isCompleted) speech.complete();
  }
}
