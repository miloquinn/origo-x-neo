import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/image/image_reader_chrome.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/elastic_press.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/widgets/glass_control_surface.dart';

void main() {
  testWidgets('image reader actions retain expanded spring glass roles', (
    tester,
  ) async {
    const directionKey = ValueKey('image-direction');
    const settingsKey = ValueKey('image-settings');
    var tableOfContentsTaps = 0;
    var directionTaps = 0;
    var settingsTaps = 0;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 620));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Stack(
              children: [
                ImageReaderChrome(
                  palette: ReaderThemes.green,
                  visible: true,
                  title: '很长的漫画章节标题',
                  pageIndex: 2,
                  pageCount: 12,
                  directionIcon: Icons.swap_horiz_rounded,
                  directionLabel: '从左向右阅读',
                  onBack: () {},
                  onPageSelected: (_) {},
                  onDirection: () => directionTaps += 1,
                  onSettings: () => settingsTaps += 1,
                  onTableOfContents: () => tableOfContentsTaps += 1,
                  directionKey: directionKey,
                  settingsKey: settingsKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final directionButton = find.descendant(
      of: find.byKey(directionKey),
      matching: find.byType(GlassTextButton),
    );
    expect(directionButton, findsOneWidget);
    final size = tester.getSize(directionButton);
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThan(44));
    final settingsButton = find.descendant(
      of: find.byKey(settingsKey),
      matching: find.byType(GlassTextButton),
    );
    expect(tester.getSize(settingsButton).width, size.width);
    expect(
      find.descendant(of: directionButton, matching: find.byType(ElasticPress)),
      findsOneWidget,
    );
    final surface = tester.widget<GlassControlSurface>(
      find.descendant(
        of: directionButton,
        matching: find.byType(GlassControlSurface),
      ),
    );
    expect(surface.blurBackground, isFalse);
    expect(surface.brightness, ReaderThemes.green.brightness);
    expect(surface.border?.color, ReaderThemes.green.border);

    await tester.tap(directionButton);
    await tester.pump();
    expect(directionTaps, 1);
    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await tester.tap(settingsButton);
    await tester.pump();
    expect(tableOfContentsTaps, 1);
    expect(settingsTaps, 1);
  });
}
