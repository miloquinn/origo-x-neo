import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_control_surface.dart';
import 'package:xxread/widgets/reader_aloud_transcript.dart';

class _HeldEngine extends ChangeNotifier implements ReaderAloudEngine {
  Completer<void>? _speech;

  @override
  int get currentPosition => 0;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => _speech != null;

  @override
  Future<void> pause() async {}

  @override
  Future<void> speak(String text) {
    _speech?.complete();
    _speech = Completer<void>();
    notifyListeners();
    return _speech!.future;
  }

  @override
  Future<void> stop() async {
    _speech?.complete();
    _speech = null;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'return control floats at the trailing edge without covering the last sentence',
    (tester) async {
      final engine = _HeldEngine();
      final chapterText = List.generate(
        80,
        (index) => '这是第${index + 1}句，用来验证悬浮按钮不会遮住正文。',
      ).join();
      final chapter = ReaderAloudChapter(
        index: 0,
        id: 'chapter',
        title: '章节',
        text: chapterText,
      );
      final controller = ReaderAloudController(
        engine: engine,
        source: CallbackReaderAloudSource(
          bookTitle: '测试书籍',
          chapterCount: () => 1,
          currentPosition: () async =>
              const ReaderAloudPosition(chapterIndex: 0, offset: 0),
          loadChapter: (_) async => chapter,
          revealPosition: (_) async {},
          persistPosition: (_) async {},
        ),
      );
      var browseCount = 0;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await controller.stop();
        controller.dispose();
        engine.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 360),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: SizedBox(
                  width: 320,
                  height: 360,
                  child: ReaderAloudTranscript(
                    controller: controller,
                    palette: ReaderThemes.day,
                    onBrowse: () => browseCount++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      unawaited(controller.start());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final transcript = find.byKey(const ValueKey('reader-aloud-transcript'));
      final list = find.byType(ScrollablePositionedList);
      await tester.drag(list, const Offset(0, -240));
      await tester.pump();

      final button = find.byKey(
        const ValueKey('reader-aloud-return-to-reading'),
      );
      expect(button, findsOneWidget);
      expect(button.hitTestable(), findsOneWidget);
      expect(find.text('回到正在朗读'), findsOneWidget);
      expect(tester.widget<GlassTextButton>(button), isA<GlassTextButton>());
      expect(
        find.descendant(of: button, matching: find.byType(GlassControlSurface)),
        findsOneWidget,
      );
      expect(browseCount, greaterThan(0));

      final transcriptRect = tester.getRect(transcript);
      final buttonRect = tester.getRect(button);
      final listRect = tester.getRect(list);
      expect(transcriptRect.right - buttonRect.right, closeTo(12, 1));
      expect(transcriptRect.bottom - buttonRect.bottom, closeTo(12, 1));
      expect(buttonRect.height, greaterThanOrEqualTo(44));
      expect(listRect.bottom, lessThanOrEqualTo(buttonRect.top - 7));

      final lastSegment = controller.chapterSegments.last;
      final last = find.byKey(
        ValueKey(
          'reader-aloud-transcript-segment-${lastSegment.chapterIndex}-${lastSegment.startOffset}',
        ),
      );
      tester
          .widget<ScrollablePositionedList>(list)
          .itemScrollController!
          .jumpTo(index: controller.chapterSegments.length - 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(last, findsOneWidget);
      expect(last.hitTestable(), findsOneWidget);
      expect(
        tester.getRect(last).bottom,
        lessThanOrEqualTo(buttonRect.top - 7),
      );

      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(button, findsNothing);
      expect(controller.currentSegment, controller.chapterSegments.first);
      expect(tester.takeException(), isNull);
      await controller.stop();
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
