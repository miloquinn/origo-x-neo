import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_source_text_paginator.dart';
import 'package:xxread/core/reader/native_text_paginator.dart';
import 'package:xxread/core/reader/reader_desktop_resize_controller.dart';
import 'package:xxread/core/reader/reader_leaf_status.dart';
import 'package:xxread/core/reader/reader_safe_area.dart';
import 'package:xxread/core/reader/reader_text_pagination.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_paper_page_leaf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reader chrome position geometry', () {
    test('zero offsets preserve the production default content bounds', () {
      const implicit = ReaderSafeAreaMetrics(
        viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        topMargin: 4,
        bottomMargin: 0,
        topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
        hasReaderHeader: true,
        viewportHeight: 844,
      );
      const explicit = ReaderSafeAreaMetrics(
        viewPadding: EdgeInsets.only(top: 59, bottom: 34),
        topMargin: 4,
        bottomMargin: 0,
        topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
        headerOffset: 0,
        footerOffset: 0,
        hasReaderHeader: true,
        viewportHeight: 844,
      );

      expect(explicit.contentTop, implicit.contentTop);
      expect(explicit.contentBottom, implicit.contentBottom);
      expect(explicit.readerTopBarTop, implicit.readerTopBarTop);
      expect(explicit.pageNumberBottom, implicit.pageNumberBottom);
      expect(explicit.paginationSignature, implicit.paginationSignature);
      expect(explicit.contentTop, 87);
      expect(explicit.contentBottom, 34);
      expect(explicit.readerTopBarTop, 63);
      expect(explicit.pageNumberBottom, 14);
    });

    test('keeps the body outside independently moved header and footer', () {
      const devices = <(String, Size, EdgeInsets)>[
        (
          'iPhone portrait',
          Size(320, 568),
          EdgeInsets.only(top: 59, bottom: 34),
        ),
        (
          'Android portrait',
          Size(320, 568),
          EdgeInsets.only(top: 24, bottom: 24),
        ),
        ('no-inset landscape', Size(844, 390), EdgeInsets.zero),
        ('short viewport', Size(320, 300), EdgeInsets.zero),
      ];

      for (final device in devices) {
        for (final margins in <(double, double)>[
          (0, 0),
          (120, 0),
          (0, 120),
          (120, 120),
        ]) {
          for (final offsets in <(double, double)>[
            (0, 0),
            (80, 0),
            (0, 80),
            (80, 80),
          ]) {
            for (final chromeHeight in <double>[16, 42]) {
              final metrics = ReaderSafeAreaMetrics(
                viewPadding: device.$3,
                topMargin: margins.$1,
                bottomMargin: margins.$2,
                topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
                headerOffset: offsets.$1,
                footerOffset: offsets.$2,
                hasReaderHeader: true,
                headerHeight: chromeHeight,
                footerHeight: chromeHeight,
                headerContentGap: 4,
                footerContentGap: 4,
                viewportHeight: device.$2.height,
                minimumContentHeight: 120,
              );
              final bodyBottom = device.$2.height - metrics.contentBottom;
              final headerBottom =
                  metrics.readerTopBarTop + metrics.headerHeight;
              final footerTop =
                  device.$2.height -
                  metrics.pageNumberBottom -
                  metrics.footerHeight;
              final reason =
                  '${device.$1}, margins=$margins, offsets=$offsets, '
                  'chrome=$chromeHeight';

              expect(
                metrics.contentTop,
                greaterThanOrEqualTo(
                  headerBottom + metrics.headerContentGap - 0.000001,
                ),
                reason: reason,
              );
              expect(
                bodyBottom,
                lessThanOrEqualTo(
                  footerTop - metrics.footerContentGap + 0.000001,
                ),
                reason: reason,
              );
              expect(
                bodyBottom - metrics.contentTop,
                greaterThanOrEqualTo(120 - 0.000001),
                reason: reason,
              );
            }
          }
        }
      }
    });

    test(
      'compresses effective whitespace without changing raw preferences',
      () {
        ReaderSafeAreaMetrics metrics(double height) => ReaderSafeAreaMetrics(
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          topMargin: 120,
          bottomMargin: 120,
          topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
          headerOffset: 80,
          footerOffset: 80,
          hasReaderHeader: true,
          headerHeight: 42,
          footerHeight: 42,
          headerContentGap: 4,
          footerContentGap: 4,
          viewportHeight: height,
          minimumContentHeight: 120,
        );

        final tall = metrics(844);
        final short = metrics(390);

        expect(short.topMargin, tall.topMargin);
        expect(short.bottomMargin, tall.bottomMargin);
        expect(short.headerOffset, tall.headerOffset);
        expect(short.footerOffset, tall.footerOffset);
        expect(short.contentTop, lessThan(tall.contentTop));
        expect(short.contentBottom, lessThan(tall.contentBottom));
        expect(
          390 - short.contentTop - short.contentBottom,
          closeTo(120, 0.001),
        );
      },
    );

    test('offset-only chrome movement changes the pagination signature', () {
      ReaderSafeAreaMetrics metrics(double header, double footer) =>
          ReaderSafeAreaMetrics(
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
            topMargin: 120,
            bottomMargin: 120,
            topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
            headerOffset: header,
            footerOffset: footer,
            hasReaderHeader: true,
            viewportHeight: 844,
            minimumContentHeight: 120,
          );

      final baseline = metrics(0, 0);
      final moved = metrics(48, 48);

      expect(moved.contentTop, baseline.contentTop);
      expect(moved.contentBottom, baseline.contentBottom);
      expect(moved.readerTopBarTop, greaterThan(baseline.readerTopBarTop));
      expect(moved.pageNumberBottom, greaterThan(baseline.pageNumberBottom));
      expect(moved.paginationSignature, isNot(baseline.paginationSignature));
    });
  });

  testWidgets('information height measures the effective label font metrics', (
    tester,
  ) async {
    const scaler = TextScaler.linear(3.2);
    const locale = Locale('zh', 'CN');
    const inheritedLabelStyle = TextStyle(
      fontFamily: 'Ahem',
      fontFamilyFallback: <String>['serif'],
      fontStyle: FontStyle.italic,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final effectiveStyle = inheritedLabelStyle.copyWith(
      fontSize: 10,
      height: 1,
      fontWeight: FontWeight.w600,
    );
    final painter = TextPainter(
      text: TextSpan(text: '章Ag09:05', style: effectiveStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      locale: locale,
    )..layout();
    final expected = painter.height.ceilToDouble() + 2;
    painter.dispose();

    expect(
      readerInformationTextHeight(scaler, locale, style: inheritedLabelStyle),
      expected,
    );
  });

  testWidgets(
    'shared pagination preserves every source unit and every visible page fits',
    (tester) async {
      const sourceOffset = 37;
      final source = List.generate(
        9,
        (index) =>
            '第$index段中文与 Latin text 📖 keep UTF-16 offsets intact.\n'
            '　　段落缩进和间距也必须经过同一套分页。',
      ).join('\n\n');
      const width = 260.0;
      const height = 220.0;
      const style = TextStyle(fontSize: 20, height: 1.8);
      final flow = NativeTextFlowStyle(
        textDirection: TextDirection.ltr,
        textScaler: readerBodyTextScaler,
        locale: const Locale('zh', 'CN'),
        strutStyle: readerStrutStyle(style),
        textHeightBehavior: readerTextHeightBehavior,
      );

      final nativeRanges =
          NativeTextPaginator(
            maxWidth: width,
            maxHeight: height,
            flowStyle: flow,
          ).paginate(
            text: source,
            sourceOffset: sourceOffset,
            spanBuilder: (start, end) => TextSpan(
              text: source.substring(start - sourceOffset, end - sourceOffset),
              style: style,
            ),
          );
      expect(
        nativeRanges
            .map((range) => source.substring(range.start, range.end))
            .join(),
        source,
      );
      for (final range in nativeRanges) {
        final painter = flow.createPainter(
          TextSpan(
            text: source.substring(range.visibleStart, range.visibleEnd),
            style: style,
          ),
        )..layout(maxWidth: width);
        expect(painter.height, lessThanOrEqualTo(height + 0.01));
        painter.dispose();
      }

      final sharedPages = paginateReaderText(
        text: source,
        maxWidth: width,
        maxHeight: height,
        flowStyle: flow,
        style: style,
        sourceOffset: sourceOffset,
        firstLineIndent: 2,
        paragraphSpacing: 1,
      );
      final sourcePages = paginateBookSourceText(
        source,
        width: width,
        firstPageHeight: height,
        pageHeight: height,
        style: style,
        textDirection: TextDirection.ltr,
        locale: const Locale('zh', 'CN'),
        firstLineIndent: 2,
        paragraphSpacing: 1,
        includeChapterTitlePage: false,
      );

      _expectCanonicalChapter(sharedPages, source, sourceOffset);
      _expectCanonicalChapter(sourcePages, source, 0);
      _expectEveryPageFits(sharedPages, flow, style, width, height);
      _expectEveryPageFits(sourcePages, flow, style, width, height);
    },
  );

  testWidgets('large typography uses guarded production viewport height', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 72, height: 4);
    final flow = NativeTextFlowStyle(
      textDirection: TextDirection.ltr,
      textScaler: readerBodyTextScaler,
      locale: const Locale('zh', 'CN'),
      strutStyle: readerStrutStyle(style),
      textHeightBehavior: readerTextHeightBehavior,
    );
    final source = List.filled(10, '大字 A📖 中文与 Latin').join('\n\n');
    const minimumContentHeight = 72.0 * 4;
    const viewports = <(String, Size, EdgeInsets)>[
      ('iPhone portrait', Size(320, 568), EdgeInsets.only(top: 59, bottom: 34)),
      ('landscape', Size(844, 390), EdgeInsets.zero),
      ('physically constrained', Size(320, 240), EdgeInsets.zero),
    ];

    for (final viewport in viewports) {
      final metrics = ReaderSafeAreaMetrics(
        viewPadding: viewport.$3,
        topMargin: 120,
        bottomMargin: 120,
        topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
        headerOffset: 80,
        footerOffset: 80,
        hasReaderHeader: true,
        viewportHeight: viewport.$2.height,
        minimumContentHeight: minimumContentHeight,
      );
      final maxHeight = readerTextContentHeight(
        viewport.$2.height,
        metrics.contentTop,
        metrics.contentBottom,
      );
      final maxWidth = readerTextContentWidth(viewport.$2.width, 16);
      final reason = '${viewport.$1}: ${viewport.$2}';

      if (viewport.$2.height >= 336) {
        expect(
          maxHeight,
          greaterThanOrEqualTo(minimumContentHeight - 0.000001),
          reason: reason,
        );
      } else {
        // 240 px cannot contain the irreducible 24 + 24 px chrome reserves
        // plus the requested 288 px minimum body. The geometry still gives
        // all physically available space to text without overlapping chrome.
        expect(maxHeight, closeTo(192, 0.001), reason: reason);
        expect(maxHeight, lessThan(minimumContentHeight), reason: reason);
      }

      final localPages = paginateReaderText(
        text: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        flowStyle: flow,
        style: style,
        sourceOffset: 23,
        firstLineIndent: 2,
        paragraphSpacing: 1,
      );
      final onlinePages = paginateBookSourceText(
        source,
        width: maxWidth,
        firstPageHeight: maxHeight,
        pageHeight: maxHeight,
        style: style,
        textDirection: TextDirection.ltr,
        locale: const Locale('zh', 'CN'),
        firstLineIndent: 2,
        paragraphSpacing: 1,
        includeChapterTitlePage: false,
      );

      _expectCanonicalChapter(localPages, source, 23);
      _expectCanonicalChapter(onlinePages, source, 0);
      _expectEveryPageFits(localPages, flow, style, maxWidth, maxHeight);
      _expectEveryPageFits(onlinePages, flow, style, maxWidth, maxHeight);
    }
  });

  testWidgets('styled EPUB heading spans fit the narrow shared paginator', (
    tester,
  ) async {
    const bodyStyle = TextStyle(fontSize: 20, height: 1.8);
    const headingStyle = TextStyle(
      fontSize: 28,
      height: 1.8,
      fontWeight: FontWeight.w600,
    );
    const source =
        '第三章 Chapter Three\n'
        '这是一段中英文混排的 EPUB 正文📖，标题是正文字号的 1.4 倍。\n'
        '第二段继续验证窄屏时的分页高度。';
    final headingEnd = source.indexOf('\n') + 1;
    final flow = NativeTextFlowStyle(
      textDirection: TextDirection.ltr,
      textScaler: readerBodyTextScaler,
      locale: const Locale('zh', 'CN'),
      strutStyle: readerStrutStyle(bodyStyle),
      textHeightBehavior: readerTextHeightBehavior,
    );
    TextSpan spanBuilder(int start, int end) {
      final children = <InlineSpan>[];
      if (start < headingEnd) {
        final split = end < headingEnd ? end : headingEnd;
        children.add(
          TextSpan(text: source.substring(start, split), style: headingStyle),
        );
      }
      if (end > headingEnd) {
        final split = start > headingEnd ? start : headingEnd;
        children.add(
          TextSpan(text: source.substring(split, end), style: bodyStyle),
        );
      }
      return TextSpan(children: children);
    }

    const width = 180.0;
    const height = 150.0;
    final ranges = NativeTextPaginator(
      maxWidth: width,
      maxHeight: height,
      flowStyle: flow,
    ).paginate(text: source, spanBuilder: spanBuilder);

    expect(
      ranges.map((range) => source.substring(range.start, range.end)).join(),
      source,
    );
    for (final range in ranges) {
      final painter = flow.createPainter(
        spanBuilder(range.visibleStart, range.visibleEnd),
      )..layout(maxWidth: width);
      expect(
        painter.height,
        lessThanOrEqualTo(height + 0.01),
        reason: 'styled range ${range.start}-${range.end} must fit',
      );
      painter.dispose();
    }
  });

  testWidgets(
    'production leaf keeps paginated glyph boxes between scaled chrome slots',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const scaler = TextScaler.linear(3.2);
      final informationHeight = readerInformationTextHeight(
        scaler,
        const Locale('zh', 'CN'),
      );
      final metrics = ReaderSafeAreaMetrics(
        viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        topMargin: 0,
        bottomMargin: 0,
        topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
        headerOffset: 80,
        footerOffset: 80,
        hasReaderHeader: true,
        headerHeight: informationHeight,
        footerHeight: informationHeight,
        headerContentGap: 4,
        footerContentGap: 4,
        viewportHeight: 568,
        minimumContentHeight: 120,
      );
      const style = TextStyle(fontSize: 20, height: 1.8);
      final flow = NativeTextFlowStyle(
        textDirection: TextDirection.ltr,
        textScaler: readerBodyTextScaler,
        locale: const Locale('zh', 'CN'),
        strutStyle: readerStrutStyle(style),
        textHeightBehavior: readerTextHeightBehavior,
      );
      final page = paginateReaderText(
        text: List.filled(12, '正文 Latin 📖 不得被页眉页脚遮挡。').join('\n'),
        maxWidth: 288,
        maxHeight: readerTextContentHeight(
          568,
          metrics.contentTop,
          metrics.contentBottom,
        ),
        flowStyle: flow,
        style: style,
      ).first;
      final bodyKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              viewPadding: EdgeInsets.only(top: 24, bottom: 24),
              textScaler: scaler,
              alwaysUse24HourFormat: true,
            ),
            child: ReaderPaperPageLeaf(
              palette: ReaderThemes.day,
              safeArea: metrics,
              metadata: const ReaderPaperPageMetadata(
                pageIdentity: 'geometry:0',
                layoutFingerprint: 'geometry',
                themeId: 'day',
                chapterTitle: '章节',
                pageNumber: 1,
                pageCount: 2,
              ),
              showTopInformation: true,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  metrics.contentTop,
                  16,
                  metrics.contentBottom,
                ),
                child: RichText(
                  key: bodyKey,
                  text: page.buildSpan(style: style),
                  textDirection: TextDirection.ltr,
                  textScaler: readerBodyTextScaler,
                  strutStyle: readerStrutStyle(style),
                  textHeightBehavior: readerTextHeightBehavior,
                ),
              ),
            ),
          ),
        ),
      );

      final headerRect = tester.getRect(
        find.byKey(const ValueKey('reader-leaf-top-information:geometry:0')),
      );
      final footerRect = tester.getRect(
        find.byKey(const ValueKey('reader-leaf-footer:geometry:0')),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(bodyKey),
      );
      final plainText = page.buildSpan(style: style).toPlainText();
      final firstIndex = plainText.indexOf(RegExp(r'\S'));
      final lastIndex = plainText.lastIndexOf(RegExp(r'\S'));
      final firstBox = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: firstIndex, extentOffset: firstIndex + 1),
          )
          .first;
      final lastBox = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: lastIndex, extentOffset: lastIndex + 1),
          )
          .last;
      final firstRect =
          paragraph.localToGlobal(firstBox.toRect().topLeft) &
          firstBox.toRect().size;
      final lastRect =
          paragraph.localToGlobal(lastBox.toRect().topLeft) &
          lastBox.toRect().size;

      expect(firstRect.top, greaterThanOrEqualTo(headerRect.bottom + 4));
      expect(lastRect.bottom, lessThanOrEqualTo(footerRect.top - 4));
    },
  );

  testWidgets('paper chrome clips wrapped information before the body', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(180, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const scaler = TextScaler.linear(3.2);
    const labelStyle = TextStyle(
      fontFamily: 'Ahem',
      leadingDistribution: TextLeadingDistribution.even,
    );
    final informationHeight = readerInformationTextHeight(
      scaler,
      const Locale('zh', 'CN'),
      style: labelStyle,
    );
    final metrics = ReaderSafeAreaMetrics(
      viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
      topMargin: 0,
      bottomMargin: 0,
      topChromeReserve: ReaderSafeAreaMetrics.readerTopBarReserve,
      hasReaderHeader: true,
      headerHeight: informationHeight,
      footerHeight: informationHeight,
      viewportHeight: 568,
    );
    const pageIdentity = 'clip:0';
    final status = ReaderLeafStatusData(
      time: DateTime(2026, 10, 10, 9, 5),
      revision: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(textTheme: const TextTheme(labelSmall: labelStyle)),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: scaler,
            alwaysUse24HourFormat: true,
          ),
          child: ReaderPaperPageLeaf(
            palette: ReaderThemes.day,
            safeArea: metrics,
            metadata: const ReaderPaperPageMetadata(
              pageIdentity: pageIdentity,
              layoutFingerprint: 'clip',
              themeId: 'day',
              chapterTitle: '章节',
              pageNumber: 1,
              pageCount: 2,
            ),
            horizontalPadding: 62,
            pageNumberHorizontalPadding: 0,
            showTopInformation: true,
            status: status,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    final leafRect = tester.getRect(find.byType(ReaderPaperPageLeaf));
    final header = find.byKey(
      const ValueKey('reader-leaf-top-information:$pageIdentity'),
    );
    final footer = find.byKey(
      const ValueKey('reader-leaf-footer:$pageIdentity'),
    );
    final headerClip = find.ancestor(
      of: header,
      matching: find.byType(ClipRect),
    );
    final footerClip = find.ancestor(
      of: footer,
      matching: find.byType(ClipRect),
    );

    expect(headerClip, findsOneWidget);
    expect(footerClip, findsOneWidget);
    expect(tester.getRect(headerClip), tester.getRect(header));
    expect(tester.getRect(footerClip), tester.getRect(footer));
    expect(tester.widget<ClipRect>(headerClip).clipBehavior, isNot(Clip.none));
    expect(tester.widget<ClipRect>(footerClip).clipBehavior, isNot(Clip.none));

    final bodyTop = leafRect.top + metrics.contentTop;
    final bodyBottom = leafRect.bottom - metrics.contentBottom;
    expect(
      tester.getRect(headerClip).bottom,
      lessThanOrEqualTo(bodyTop - metrics.headerContentGap),
    );
    expect(
      tester.getRect(footerClip).top,
      greaterThanOrEqualTo(bodyBottom + metrics.footerContentGap),
    );

    // The deliberately narrow header makes the unbounded time paragraph wrap
    // below its slot. Its glyph geometry reaches the body, so this assertion
    // proves the production ClipRect is what prevents those glyphs painting
    // over the first body line.
    final timeParagraph = tester.renderObject<RenderParagraph>(
      find.text('09:05'),
    );
    final timeBoxes = timeParagraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
    );
    final unpaintedInkBottom = timeBoxes
        .map((box) => timeParagraph.localToGlobal(Offset(0, box.bottom)).dy)
        .reduce((a, b) => a > b ? a : b);
    expect(unpaintedInkBottom, greaterThan(tester.getRect(headerClip).bottom));
    expect(unpaintedInkBottom, greaterThan(bodyTop));
  });

  testWidgets('viewport chrome clips title and status to their fixed slots', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(180, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const titleKey = ValueKey('viewport-title');
    const statusKey = ValueKey('viewport-status');
    const titleTop = 28.0;
    const titleHeight = 34.0;
    const statusBottom = 24.0;
    const statusHeight = 34.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            labelSmall: TextStyle(
              fontFamily: 'Ahem',
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(3.2),
            alwaysUse24HourFormat: true,
          ),
          child: ReaderChromeOverlay(
            palette: ReaderThemes.day,
            visible: false,
            title: '章节',
            statusBottom: statusBottom,
            statusBuilder: (_, style, key) =>
                Text('123456789 / 123456789', key: key, style: style),
            onBack: () {},
            onBookmark: null,
            onTableOfContents: () {},
            onSettings: () {},
            backTooltip: '返回',
            bookmarkTooltip: '书签',
            tableOfContentsTooltip: '目录',
            settingsTooltip: '设置',
            bookmarked: false,
            showViewportTitle: true,
            viewportTitleTop: titleTop,
            viewportTitleHeight: titleHeight,
            viewportStatusHeight: statusHeight,
            viewportTitleKey: titleKey,
            statusKey: statusKey,
            readerStatus: ReaderLeafStatusData(
              time: DateTime(2026, 10, 10, 9, 5),
              revision: 1,
            ),
          ),
        ),
      ),
    );

    final titleClip = find.ancestor(
      of: find.byKey(titleKey),
      matching: find.byType(ClipRect),
    );
    final statusClip = find.ancestor(
      of: find.byKey(statusKey),
      matching: find.byType(ClipRect),
    );
    expect(titleClip, findsOneWidget);
    expect(statusClip, findsOneWidget);
    expect(
      tester.getRect(titleClip),
      const Rect.fromLTWH(30, titleTop, 120, titleHeight),
    );
    expect(
      tester.getRect(statusClip),
      const Rect.fromLTWH(
        0,
        568 - statusBottom - statusHeight,
        180,
        statusHeight,
      ),
    );
    expect(tester.widget<ClipRect>(titleClip).clipBehavior, isNot(Clip.none));
    expect(tester.widget<ClipRect>(statusClip).clipBehavior, isNot(Clip.none));
  });

  testWidgets('desktop drag keeps chrome signature stable until settle', (
    tester,
  ) async {
    final controller = ReaderDesktopResizeController(
      settleDelay: const Duration(milliseconds: 40),
    );
    addTearDown(controller.dispose);
    var settled = 0;
    String signature(Size viewport) {
      final stable = controller.resolve(
        viewport,
        enabled: true,
        onSettled: () => settled += 1,
      );
      return ReaderSafeAreaMetrics(
        viewPadding: EdgeInsets.zero,
        topMargin: 120,
        bottomMargin: 120,
        headerOffset: 80,
        footerOffset: 80,
        hasReaderHeader: true,
        viewportHeight: stable.height,
        minimumContentHeight: 120,
      ).paginationSignature;
    }

    final initial = signature(const Size(1200, 800));
    expect(signature(const Size(1040, 620)), initial);
    expect(signature(const Size(900, 300)), initial);
    await tester.pump(const Duration(milliseconds: 40));
    expect(settled, 1);
    expect(signature(const Size(900, 300)), isNot(initial));
  });
}

void _expectCanonicalChapter(
  List<ReaderTextPage> pages,
  String source,
  int sourceOffset,
) {
  final body = pages.where((page) => !page.isChapterTitle).toList();
  expect(body.first.startOffset, sourceOffset);
  expect(body.last.endOffset, sourceOffset + source.length);
  for (var index = 1; index < body.length; index++) {
    expect(body[index - 1].endOffset, body[index].startOffset);
  }
  expect(
    body
        .map(
          (page) => source.substring(
            page.startOffset - sourceOffset,
            page.endOffset - sourceOffset,
          ),
        )
        .join(),
    source,
  );
}

void _expectEveryPageFits(
  List<ReaderTextPage> pages,
  NativeTextFlowStyle flow,
  TextStyle style,
  double width,
  double height,
) {
  for (final page in pages.where((page) => !page.isChapterTitle)) {
    final painter = flow.createPainter(page.buildSpan(style: style))
      ..layout(maxWidth: width);
    expect(
      painter.height,
      lessThanOrEqualTo(height + 0.01),
      reason: 'page ${page.startOffset}-${page.endOffset} must fit',
    );
    painter.dispose();
  }
}
