import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/core/reader/reader_progress_position.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/widgets/reader_progress_pill.dart';

const _sliderKey = ValueKey('reader-progress-slider');
const _previousKey = ValueKey('reader-progress-previous');
const _nextKey = ValueKey('reader-progress-next');

void main() {
  setUp(() {
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    GlassEffectConfig.setDisableAllGlassEffects(false);
  });
  tearDown(() {
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
    GlassEffectConfig.setDisableAllGlassEffects(false);
  });

  testWidgets('thick tank previews a drag and seeks only on release', (
    tester,
  ) async {
    final seeks = <ReaderProgressTarget>[];
    var starts = 0;
    await tester.pumpWidget(
      _app(_pill(onSeek: seeks.add, onSeekStart: () => starts++)),
    );
    final slider = find.byKey(_sliderKey);
    expect(tester.getSize(slider).height, 44);
    final bounds = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(bounds.left + bounds.width * .45, bounds.center.dy),
    );
    await gesture.moveTo(
      Offset(bounds.left + bounds.width * .8, bounds.center.dy),
    );
    await tester.pump();
    expect(starts, 1);
    expect(seeks, isEmpty);
    final preview = tester.widget<Slider>(slider).value;
    expect(preview, greaterThan(.7));
    await gesture.up();
    await tester.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single.chapterIndex, greaterThanOrEqualTo(7));
  });

  testWidgets('native keyboard and semantics keep seeking accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final seeks = <ReaderProgressTarget>[];
    await tester.pumpWidget(_app(_pill(onSeek: seeks.add)));
    final slider = tester.widget<Slider>(find.byKey(_sliderKey));
    expect(slider.semanticFormatterCallback!(.75), '全书 · 75%');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    // The previous-chapter action precedes the native slider.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(seeks, hasLength(1));
    semantics.dispose();
  });

  testWidgets('chapter boundaries and loading disable the correct actions', (
    tester,
  ) async {
    var previous = 0;
    var next = 0;
    await tester.pumpWidget(
      _app(
        _pill(
          index: 0,
          onPrevious: () => previous++,
          onNext: () => next++,
          onSeek: null,
        ),
      ),
    );
    expect(
      tester.widget<IconButton>(find.byKey(_previousKey)).onPressed,
      isNull,
    );
    expect(tester.widget<Slider>(find.byKey(_sliderKey)).onChanged, isNull);
    await tester.tap(find.byKey(_nextKey));
    expect(next, 1);
    expect(previous, 0);
    await tester.pumpWidget(_app(_pill(index: 9)));
    expect(tester.widget<IconButton>(find.byKey(_nextKey)).onPressed, isNull);
  });

  testWidgets('scope labels and large text fit a narrow reader', (
    tester,
  ) async {
    for (final scope in ReaderProgressScope.values) {
      await tester.pumpWidget(
        _app(_pill(scope: scope), width: 276, textScale: 3.2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(_previousKey)), const Size(44, 44));
      expect(
        find.text(scope == ReaderProgressScope.book ? '全书 · 35%' : '本章 · 50%'),
        findsOneWidget,
      );
    }
  });

  testWidgets('glass and solid share geometry without double sampling', (
    tester,
  ) async {
    for (final off in [false, true]) {
      GlassEffectConfig.setDisableAllGlassEffects(off);
      await tester.pumpWidget(_app(_pill()));
      expect(
        tester.getSize(find.byType(ReaderProgressPill)),
        const Size(330, 60),
      );
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(find.byType(BackdropFilter), off ? findsNothing : findsOneWidget);
    }
  });

  testWidgets('pill sits above controls and hides with the reader chrome', (
    tester,
  ) async {
    Widget chrome(bool visible) => _app(
      ReaderChromeOverlay(
        palette: ReaderThemes.day,
        visible: visible,
        title: '章节',
        statusBottom: 0,
        statusBuilder: (_, _, _) => const SizedBox.shrink(),
        onBack: () {},
        onBookmark: null,
        onTableOfContents: () {},
        onSettings: () {},
        backTooltip: '返回',
        bookmarkTooltip: '书签',
        tableOfContentsTooltip: '目录',
        settingsTooltip: '设置',
        bookmarked: false,
        progressBar: _pill(),
      ),
      height: 650,
    );
    await tester.pumpWidget(chrome(true));
    await tester.pumpAndSettle();
    final pill = tester.getRect(find.byType(ReaderProgressPill));
    final bar = tester.getRect(find.byType(ReaderControlBar).last);
    expect(bar.top - pill.bottom, 12);
    await tester.pumpWidget(chrome(false));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(ReaderProgressPill)).top,
      greaterThan(650),
    );
  });
}

Widget _pill({
  ReaderProgressScope scope = ReaderProgressScope.book,
  int index = 3,
  ValueChanged<ReaderProgressTarget>? onSeek = _noop,
  VoidCallback? onSeekStart,
  VoidCallback? onPrevious,
  VoidCallback? onNext,
}) => ReaderProgressPill(
  palette: ReaderThemes.day,
  position: ReaderProgressPosition(
    chapterIndex: index,
    chapterCount: 10,
    chapterProgress: .5,
  ),
  scope: scope,
  onSeek: onSeek,
  onSeekStart: onSeekStart,
  onPreviousChapter: onPrevious ?? () {},
  onNextChapter: onNext ?? () {},
);

void _noop(ReaderProgressTarget _) {}

Widget _app(
  Widget child, {
  double width = 330,
  double height = 200,
  double textScale = 1,
}) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: ReaderThemes.day.toThemeData().copyWith(
    extensions: const [
      UiStyleThemeExtension(
        style: AppUiStyle.glass,
        glassStyle: GlassStyle.frosted,
      ),
    ],
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.zero,
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  ),
);
