import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/legal/agreement_summary.dart';

void main() {
  Widget buildSubject({double textScale = 1}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AgreementSummary(),
          ),
        ),
      ),
    );
  }

  testWidgets('disclosures start collapsed and reveal complete terms', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agreementTermsDisclosure')), findsOneWidget);
    expect(find.byKey(const Key('agreementSourceDisclosure')), findsOneWidget);
    expect(find.byKey(const Key('agreementPrivacyDisclosure')), findsOneWidget);
    expect(find.text('Scope and acceptance'), findsNothing);
    expect(find.text('Third-party source boundary'), findsNothing);
    expect(find.text('Local by default'), findsNothing);

    await tester.tap(find.text('Terms'));
    await tester.pumpAndSettle();
    expect(find.text('Scope and acceptance'), findsOneWidget);
    expect(find.text('Open-source license'), findsOneWidget);
    expect(find.text('Changes, termination, and law'), findsOneWidget);
    expect(
      find.textContaining('does not preinstall, bundle, or recommend'),
      findsOneWidget,
    );

    await tester.tap(find.text('Terms'));
    await tester.pumpAndSettle();
    expect(find.text('Scope and acceptance'), findsNothing);

    await tester.ensureVisible(find.text('Book sources'));
    await tester.tap(find.text('Book sources'));
    await tester.pumpAndSettle();
    expect(find.text('Third-party source boundary'), findsOneWidget);
    expect(find.text('Book sources and third parties'), findsOneWidget);
    // This fact appears in the always-visible summary and in the full text.
    expect(
      find.textContaining('provides no source addresses'),
      findsNWidgets(2),
    );

    await tester.ensureVisible(find.text('Privacy'));
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Local by default'), findsOneWidget);
    expect(find.text('Network use is explicit'), findsOneWidget);
    expect(find.text('Limited download records'), findsOneWidget);
    expect(find.text('Data and privacy'), findsOneWidget);
    expect(
      find.textContaining('kept for no more than 180 days'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a narrow screen with large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject(textScale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Privacy'));
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Data and privacy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
