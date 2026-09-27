// flutter test --no-pub tool/capture_welcome_preview.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'welcome_preview.dart';

void main() {
  testWidgets('capture the Flutter welcome motion concept', (tester) async {
    // This tool is run by flutter test, despite living outside test/.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final output = Directory('docs/previews/welcome-motion');
    final frames = Directory('/tmp/origo-welcome-motion-frames');
    await tester.runAsync(() async {
      await output.create(recursive: true);
      await frames.create(recursive: true);
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'WelcomePreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final icons = await File(
        '/Users/xiaoyuan/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    await tester.pumpWidget(
      const RepaintBoundary(
        key: Key('capture'),
        child: WelcomePreviewApp(fontFamily: 'WelcomePreview'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/app_icon.png'),
        tester.element(find.byType(WelcomePreviewApp)),
      ),
    );
    await tester.pump();
    final pager = tester.widget<PageView>(
      find.byKey(const Key('welcomePager')),
    );
    final controller = pager.controller!;
    Future<void> capture(String path) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (var page = 0; page < 3; page++) {
      controller.jumpToPage(page);
      await tester.pumpAndSettle();
      await capture('${output.path}/chapter-${page + 1}.png');
    }
    final positions = <double>[];
    void hold(double page, int frames) =>
        positions.addAll(List.filled(frames, page));
    void move(double from, double to) {
      for (var i = 0; i < 24; i++) {
        positions.add(
          from + (to - from) * Curves.easeInOutCubic.transform(i / 23),
        );
      }
    }

    hold(0, 18);
    move(0, 1);
    hold(1, 18);
    move(1, 2);
    hold(2, 18);
    move(2, 3);
    hold(3, 42);
    move(3, 2);
    move(2, 1);
    move(1, 0);
    for (var frame = 0; frame < positions.length; frame++) {
      controller.jumpTo(
        positions[frame] * controller.position.viewportDimension,
      );
      await tester.pump(const Duration(milliseconds: 42));
      await capture('${frames.path}/${frame.toString().padLeft(4, '0')}.png');
    }
    controller.jumpToPage(3);
    await tester.pumpAndSettle();
    await capture('${output.path}/agreements.png');
    for (final (name, key) in const [
      ('terms', 'agreementTermsDisclosure'),
      ('source', 'agreementSourceDisclosure'),
      ('privacy', 'agreementPrivacyDisclosure'),
    ]) {
      final disclosure = find
          .descendant(of: find.byKey(Key(key)), matching: find.byType(ListTile))
          .first;
      await tester.ensureVisible(disclosure);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
      await capture('${output.path}/$name-expanded.png');
      await tester.ensureVisible(disclosure);
      await tester.tap(disclosure);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pumpAndSettle();
    expect(find.text('故事，从这里开始。'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool('userAgreementAccepted'),
      isNull,
      reason: 'The visual preview must not store real consent.',
    );
    expect(tester.takeException(), isNull);
  });
}
