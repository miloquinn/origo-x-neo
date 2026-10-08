import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/widgets/reader_exit_shelf_dialog.dart';

void main() {
  testWidgets('render shelf exit dialog and verify decisions', (tester) async {
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'ExitPreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final scenario in [
      (
        name: 'light',
        width: 390.0,
        height: 844.0,
        scale: 1.0,
        dark: false,
        locale: 'zh',
      ),
      (
        name: 'dark',
        width: 390.0,
        height: 844.0,
        scale: 1.0,
        dark: true,
        locale: 'zh',
      ),
      (
        name: 'narrow-large',
        width: 320.0,
        height: 568.0,
        scale: 1.5,
        dark: false,
        locale: 'zh',
      ),
      (
        name: 'english-large',
        width: 320.0,
        height: 568.0,
        scale: 2.0,
        dark: true,
        locale: 'en',
      ),
      (
        name: 'german',
        width: 390.0,
        height: 844.0,
        scale: 1.0,
        dark: false,
        locale: 'de',
      ),
      (
        name: 'desktop',
        width: 1024.0,
        height: 768.0,
        scale: 1.0,
        dark: false,
        locale: 'zh',
      ),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      final palette = scenario.dark ? ReaderThemes.night : ReaderThemes.day;
      late BuildContext hostContext;
      late NavigatorState hostNavigator;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(scenario.locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: palette.toThemeData().copyWith(
            textTheme: palette.toThemeData().textTheme.apply(
              fontFamily: 'ExitPreview',
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
            child: RepaintBoundary(key: const Key('capture'), child: child!),
          ),
          home: Builder(
            builder: (context) {
              hostContext = context;
              hostNavigator = Navigator.of(context, rootNavigator: true);
              return const Scaffold();
            },
          ),
        ),
      );

      Future<bool?> open() => showDialog<bool>(
        context: hostContext,
        builder: (_) => ReaderExitShelfDialog(
          bookTitle: '长安的荔枝：一场跨越山海的旅程',
          palette: palette,
        ),
      );

      final decision = open();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario.name);
      final dialogRect = tester.getRect(
        find
            .descendant(
              of: find.byType(Dialog),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(dialogRect.width, lessThanOrEqualTo(360));
      expect(dialogRect.left, greaterThanOrEqualTo(24));
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'docs/previews/reader-exit-shelf-20261007/${scenario.name}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(await decision, isTrue);

      final decline = open();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextButton));
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(await decline, isFalse);

      final dismissed = open();
      await tester.pumpAndSettle();
      hostNavigator.pop();
      await tester.pumpAndSettle();
      expect(await dismissed, isNull);
      expect(tester.takeException(), isNull, reason: scenario.name);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
