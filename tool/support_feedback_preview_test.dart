// flutter test --no-pub tool/support_feedback_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/support/feedback_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/diagnostics/diagnostics_controller.dart';
import 'package:xxread/utils/app_themes.dart';

const _captureKey = Key('support-feedback-preview');
const _outputDirectory = 'build/support-delivery-20261008/previews';

class _PreviewAccount extends MemberAccountController {
  @override
  bool get isAuthenticated => true;

  @override
  MemberUser get user => MemberUser(
    id: 'preview-account',
    email: 'preview@example.test',
    emailVerified: true,
    username: 'preview',
    effectiveName: '预览用户',
    authMethods: const ['password'],
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

class _PreviewDiagnostics extends DiagnosticsController {
  _PreviewDiagnostics({required super.account});

  @override
  bool get enabled => false;

  @override
  bool get supported => true;

  @override
  Future<void> setEnabled(bool value) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture 320px large-text feedback page in light and dark', (
    tester,
  ) async {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'Origo X',
      packageName: 'com.niki.xxread',
      version: '2.7.0',
      buildNumber: '270001',
      buildSignature: '',
    );
    await _loadPreviewFonts(tester);

    for (final brightness in [Brightness.light, Brightness.dark]) {
      final account = _PreviewAccount();
      final diagnostics = _PreviewDiagnostics(account: account);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 1500);
      final appTheme = AppThemes.fromAccentColor(AppThemes.defaultAccentColor);
      final scheme = brightness == Brightness.light
          ? appTheme.lightColorScheme
          : appTheme.darkColorScheme;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MemberAccountController>.value(
              value: account,
            ),
            ChangeNotifierProvider<DiagnosticsController>.value(
              value: diagnostics,
            ),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              fontFamily: 'SupportFeedbackPreview',
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: RepaintBoundary(key: _captureKey, child: child!),
            ),
            home: FeedbackPage(
              platformName: 'ios',
              submitter: (_) =>
                  throw StateError('Preview must never send feedback.'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('feedback-message')),
        '例如：连续阅读半小时后设备明显发热，希望帮助定位耗电和卡顿原因。',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _capture(tester, 'feedback-320-large-${brightness.name}.png');
      await tester.pumpWidget(const SizedBox.shrink());
      diagnostics.dispose();
      account.dispose();
    }
    tester.view.reset();
  });
}

Future<void> _loadPreviewFonts(
  WidgetTester tester,
) => tester.runAsync(() async {
  final chinese = await File(
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
  ).readAsBytes();
  await (FontLoader(
    'SupportFeedbackPreview',
  )..addFont(Future.value(ByteData.sublistView(chinese)))).load();
  final flutterRoot = Platform.resolvedExecutable.split('/bin/cache').first;
  final icons = await File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(icons)))).load();
});

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = Directory(_outputDirectory);
    await output.create(recursive: true);
    await File(
      '${output.path}/$name',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
