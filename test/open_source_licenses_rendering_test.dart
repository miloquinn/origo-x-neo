import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/about/open_source_licenses_page.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/app_skin_licenses.dart';
import 'package:xxread/utils/ui_style.dart';
import 'support/license_registry_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerLicenseFixture();
  final render = Platform.environment['CREDITS_PREVIEW'] == '1';
  setUpAll(() async {
    if (!render) return;
    final font = FontLoader('CreditsPreview');
    font.addFont(
      File(
        Platform.environment['CREDITS_PREVIEW_FONT']!,
      ).readAsBytes().then(ByteData.sublistView),
    );
    await font.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() async {
    // Prime asset-backed collectors in a real I/O zone, before any fake-async
    // widget frame can create a pending cached bundle future.
    rootBundle.clear();
    registerAppSkinLicenses();
    await LicenseRegistry.licenses.toList();
  });
  for (final style in AppUiStyle.values) {
    for (final brightness in Brightness.values) {
      testWidgets('credits, MIT and registry adapt to $style $brightness', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(402, 874);
        addTearDown(tester.view.reset);
        final scheme = brightness == Brightness.dark
            ? AppThemes.colorPresets.first.theme.darkColorScheme
            : AppThemes.colorPresets.first.theme.lightColorScheme;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              brightness: brightness,
              colorScheme: scheme,
              fontFamily: render ? 'CreditsPreview' : null,
              extensions: [
                UiStyleThemeExtension(
                  style: style,
                  glassStyle: GlassStyle.frosted,
                ),
              ],
            ),
            builder: (context, child) => RepaintBoundary(
              key: const ValueKey('credits-preview'),
              child: child!,
            ),
            home: const OpenSourceLicensesPage(
              title: '素材与开源致谢',
              prioritizeAssets: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name =
            '${style == AppUiStyle.glass ? 'glass' : 'solid'}-${brightness.name}';
        if (render) await _capture(tester, 'directory-$name');
        await _open(tester, 'bundled-code-license-Lobe Icons');
        if (render) await _capture(tester, 'mit-$name');
        await _back(tester);
        await tester.pumpAndSettle();
        await _open(tester, 'flutter-package-licenses');
        await tester.enterText(
          find.byKey(const ValueKey('license-search-field')),
          'zz_fixture_a',
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        if (render) await _capture(tester, 'packages-$name');
        await _open(tester, 'license-registry-entry-zz_fixture_a');
        if (render) await _capture(tester, 'detail-$name');
        expect(tester.takeException(), isNull);
        expect(find.byType(LicensePage), findsNothing);
      });
    }
  }
  for (final locale in [const Locale('zh'), const Locale('de')]) {
    testWidgets(
      'credits fit 320px at 200% and package search with keyboard $locale',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 700);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const OpenSourceLicensesPage(prioritizeAssets: true),
          ),
        );
        await tester.pumpAndSettle();
        await _open(tester, 'flutter-package-licenses');
        await tester.enterText(
          find.byKey(const ValueKey('license-search-field')),
          'zz_fixture_b',
        );
        await tester.pumpAndSettle();
        await _open(tester, 'license-registry-entry-zz_fixture_b');
        expect(tester.takeException(), isNull);
        expect(find.text('Final shared warranty clause'), findsOneWidget);
      },
    );
  }
}

Future<void> _back(WidgetTester tester) =>
    tester.tap(find.byKey(const ValueKey('floating-subpage-back')));

Future<void> _open(WidgetTester tester, String key) async {
  final row = find.byKey(ValueKey(key));
  await tester.ensureVisible(row);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(row);
    await tester.pump();
    // Allow asset channels and asynchronous stream collectors to finish in a
    // real event loop before waiting on UI animations in fake time.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('credits-preview')),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'build/provider-credits-20261010/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
