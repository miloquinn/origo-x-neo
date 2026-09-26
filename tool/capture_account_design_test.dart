import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'account_design_preview.dart';

void main() {
  testWidgets('render account design states with real Flutter layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'AccountPreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    for (final page in [
      'login',
      'password',
      'register',
      'register-code',
      'register-finish',
      'account',
      'premium-account',
      'security',
      'profile',
      'membership',
      'reset',
      'reset-finish',
      'authorization',
    ]) {
      for (final dark in [
        false,
        if (page == 'login' || page == 'premium-account') true,
      ]) {
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: AccountDesignApp(
              key: ValueKey('$page-$dark'),
              initialPage: page,
              dark: dark,
            ),
          ),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/app_icon.png'),
            tester.element(find.byType(AccountDesignPage)),
          );
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$page-$dark');
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        expect(
          scrollable.position.maxScrollExtent,
          0,
          reason: 'Normal phone must fit one screen: $page',
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/previews/account-redesign/$page${dark ? '-dark' : ''}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    // Small screen / keyboard / enlarged text must remain navigable, not clipped.
    tester.view.physicalSize = const Size(320, 568);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.3),
            viewInsets: EdgeInsets.only(bottom: 260),
          ),
          child: const AccountDesignPage(page: 'register-finish'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('创建账户'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
