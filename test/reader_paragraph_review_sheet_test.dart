import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/scripting/source_script_contract.dart';
import 'package:xxread/book_sources/source_engine/source_browser_session.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/reader_paragraph_review_sheet.dart';

void main() {
  test('source presentation reads Legado fractions and bounds app geometry', () {
    final value = ReaderParagraphReviewPresentation.fromConfig(
      '{"heightPercentage":0.5,"dismissOnTouchOutside":false,"isDraggable":false}',
    );
    expect(value.heightFraction, 0.5);
    expect(value.dismissOnTouchOutside, isFalse);
    expect(value.isDraggable, isFalse);
    expect(
      ReaderParagraphReviewPresentation.fromConfig(
        '{"heightPercentage":1}',
      ).heightFraction,
      0.95,
    );
    expect(
      ReaderParagraphReviewPresentation.fromConfig(
        '{"heightPercentage":55}',
      ).heightFraction,
      0.78,
    );
    expect(
      ReaderParagraphReviewPresentation.fromConfig('broken').heightFraction,
      0.78,
    );
  });

  setUp(() => GlassEffectConfig.setDisableAllGlassEffects(false));
  tearDown(() => GlassEffectConfig.setDisableAllGlassEffects(false));

  for (final mode in ['solid', 'frosted', 'liquid']) {
    for (final dark in [false, true]) {
      testWidgets('comment sheet owns shared appearance $mode dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (Platform.environment['ORIGO_PARAGRAPH_PREVIEWS'] == '1') {
          await tester.runAsync(_loadPreviewFonts);
        }
        final cancellation = BookDownloadCancellation();
        final callbackCancellation = BookDownloadCancellation();
        var closingCount = 0;
        final boundary = GlobalKey();
        SourceBrowserResult? result;
        await tester.pumpWidget(
          _host(
            mode: mode,
            dark: dark,
            cancellation: cancellation,
            boundary: boundary,
            onResult: (value) => result = value,
            onClosing: () {
              closingCount++;
              callbackCancellation.cancel();
            },
          ),
        );
        await tester.tap(find.text('打开段评'));
        await tester.pumpAndSettle();
        expect(find.text('段评'), findsOneWidget);
        expect(find.text('示例书源'), findsOneWidget);
        expect(find.byType(GlassBottomSheetSurface), findsOneWidget);
        final panel = tester.widget<GlassSurface>(
          find
              .descendant(
                of: find.byType(GlassBottomSheetSurface),
                matching: find.byType(GlassSurface),
              )
              .first,
        );
        expect(panel.shape, isA<RoundedSuperellipseBorder>());
        expect(
          find.byType(LiquidGlassSurface),
          mode == 'liquid' ? findsWidgets : findsNothing,
        );
        expect(find.byType(GlassIconButton), findsNWidgets(2));
        expect(
          Theme.of(tester.element(find.text('段评'))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        if (Platform.environment['ORIGO_PARAGRAPH_PREVIEWS'] == '1') {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'build/paragraph-comments/previews/'
              'sheet-$mode-${dark ? 'dark' : 'light'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byKey(const ValueKey('paragraph-reviews-close')));
        await tester.pumpAndSettle();
        expect(find.byType(ReaderParagraphReviewSheet), findsNothing);
        expect(closingCount, 1);
        expect(callbackCancellation.isCancelled, isTrue);
        expect(cancellation.isCancelled, isFalse);
        expect(result?.finalUri.toString(), 'https://comments.test/chapter');
        expect(
          result?.session.localStorage['https://comments.test']?['theme'],
          'saved',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('back, barrier and request cancellation close the sheet', (
    tester,
  ) async {
    for (final dismissal in ['back', 'barrier', 'cancel']) {
      final cancellation = BookDownloadCancellation();
      var closingCount = 0;
      SourceBrowserResult? result;
      await tester.pumpWidget(
        _host(
          mode: 'solid',
          dark: false,
          cancellation: cancellation,
          boundary: GlobalKey(),
          onResult: (value) => result = value,
          onClosing: () => closingCount++,
        ),
      );
      await tester.tap(find.text('打开段评'));
      await tester.pumpAndSettle();
      switch (dismissal) {
        case 'back':
          await tester.binding.handlePopRoute();
        case 'barrier':
          await tester.tapAt(const Offset(3, 3));
        case 'cancel':
          cancellation.cancel();
      }
      await tester.pumpAndSettle();
      expect(
        find.byType(ReaderParagraphReviewSheet),
        findsNothing,
        reason: dismissal,
      );
      expect(result?.body, contains('Comments'), reason: dismissal);
      expect(closingCount, 1, reason: dismissal);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _host({
  required String mode,
  required bool dark,
  required BookDownloadCancellation cancellation,
  required GlobalKey boundary,
  required ValueChanged<SourceBrowserResult> onResult,
  VoidCallback? onClosing,
}) {
  final palette = dark ? ReaderThemes.night : ReaderThemes.day;
  return MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      fontFamily: Platform.environment['ORIGO_PARAGRAPH_PREVIEWS'] == '1'
          ? 'ParagraphPreview'
          : null,
      brightness: palette.brightness,
      extensions: [
        UiStyleThemeExtension(
          style: mode == 'solid' ? AppUiStyle.material3 : AppUiStyle.glass,
          glassStyle: mode == 'liquid' ? GlassStyle.liquid : GlassStyle.frosted,
        ),
      ],
    ),
    builder: (_, child) => RepaintBoundary(key: boundary, child: child!),
    home: Builder(
      builder: (context) => Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: FilledButton(
            onPressed: () async {
              onResult(
                await showReaderParagraphReviewSheet(
                  context,
                  palette: palette,
                  sourceId: 'fixture',
                  sourceName: '示例书源',
                  cancellation: cancellation,
                  request: const SourceScriptInteractionRequest(
                    signature: 'fixture',
                    kind: SourceScriptInteractionKind.browser,
                    presentation: SourceScriptInteractionPresentation.reading,
                    url: 'https://comments.test/chapter',
                    html: '<p>Comments</p>',
                    browserSession: SourceBrowserSession(
                      localStorage: {
                        'https://comments.test': {'theme': 'saved'},
                      },
                    ),
                  ),
                  onScriptRequest: (_, _) async => null,
                  onClosing: onClosing,
                  contentBuilder: (_) => ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: const [
                      Text(
                        '“风吹过山间，新的故事才刚刚开始。”',
                        style: TextStyle(fontSize: 15, height: 1.6),
                      ),
                      Divider(height: 28),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('读')),
                        title: Text('读者 A'),
                        subtitle: Text('这段描写很有画面感。'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('书')),
                        title: Text('读者 B'),
                        subtitle: Text('期待后面的故事。'),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: const Text('打开段评'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _loadPreviewFonts() async {
  final font = await File(
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ).readAsBytes();
  await (FontLoader(
    'ParagraphPreview',
  )..addFont(Future.value(ByteData.sublistView(font)))).load();
  final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
  final icons = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/'
    'MaterialIcons-Regular.otf',
  ).readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(icons)))).load();
}
