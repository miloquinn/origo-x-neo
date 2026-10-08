import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/activities/activity_center_page.dart';
import 'package:xxread/services/account/account.dart';

import '../test/activity_center_test.dart' show ActivityTestAccount;

// Actual production widgets, explicitly using sample campaign presentation.
void main() {
  testWidgets('capture activity center themes, width and text scale', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final chinese = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'ActivityPreview',
      )..addFont(Future.value(ByteData.sublistView(chinese)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    for (final scenario in [
      (
        name: 'phone-light',
        size: const Size(390, 844),
        dark: false,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'phone-dark',
        size: const Size(390, 844),
        dark: true,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'wide-light',
        size: const Size(1024, 768),
        dark: false,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'narrow-large',
        size: const Size(320, 568),
        dark: false,
        scale: 2.0,
        locale: 'zh',
      ),
      (
        name: 'english-large',
        size: const Size(390, 844),
        dark: true,
        scale: 2.0,
        locale: 'en',
      ),
    ]) {
      final account = ActivityTestAccount();
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: MaterialApp(
            locale: Locale(scenario.locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'ActivityPreview',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1768B4),
                brightness: scenario.dark ? Brightness.dark : Brightness.light,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scenario.scale)),
              child: RepaintBoundary(key: boundaryKey, child: child!),
            ),
            home: const ActivityCenterPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final directory = Directory('docs/previews/activity-center-20261008');
        await directory.create(recursive: true);
        await File(
          '${directory.path}/${scenario.name}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      account.dispose();
    }
  });
}
