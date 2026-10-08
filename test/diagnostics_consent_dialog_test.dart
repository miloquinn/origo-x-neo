@Tags(['isolated-process'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/support/diagnostics_consent_dialog.dart';

void main() {
  testWidgets('discloses fields and records explicit enable', (tester) async {
    bool? answer;
    var privacyOpens = 0;
    await _pumpDialog(
      tester,
      onAnswer: (value) async => answer = value,
      onOpenPrivacy: () async => privacyOpens++,
    );

    expect(find.textContaining('CPU 时间与内存占用'), findsOneWidget);
    expect(find.textContaining('整机掉电估算'), findsOneWidget);
    expect(find.textContaining('最长保留 30 天'), findsOneWidget);
    expect(find.textContaining('上传到我们的服务'), findsOneWidget);
    expect(find.textContaining('不代表 APP 独占耗电'), findsOneWidget);
    expect(find.textContaining('不收集书名'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('diagnostics-consent-privacy')));
    await tester.pump();
    expect(privacyOpens, 1);

    await tester.tap(find.byKey(const ValueKey('diagnostics-consent-accept')));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
    expect(
      find.byKey(const ValueKey('diagnostics-consent-dialog')),
      findsNothing,
    );
  });

  testWidgets('save failure stays visible and does not claim success', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpDialog(
      tester,
      onAnswer: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('storage unavailable');
      },
      onOpenPrivacy: () async {},
    );

    await tester.tap(find.byKey(const ValueKey('diagnostics-consent-accept')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('diagnostics-consent-dialog')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('diagnostics-consent-error')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('diagnostics-consent-decline')));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(
      find.byKey(const ValueKey('diagnostics-consent-dialog')),
      findsNothing,
    );
  });

  testWidgets('narrow large-text layout remains scrollable', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpDialog(
      tester,
      onAnswer: (_) async {},
      onOpenPrivacy: () async {},
      dark: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const ValueKey('diagnostics-consent-accept')),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  required Future<void> Function(bool) onAnswer,
  required Future<void> Function() onOpenPrivacy,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.indigo,
      ),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => unawaited(
                showDiagnosticsConsentDialog(
                  context,
                  onAnswer: onAnswer,
                  onOpenPrivacy: onOpenPrivacy,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
