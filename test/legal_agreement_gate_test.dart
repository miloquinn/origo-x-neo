import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/legal/legal_agreement_gate.dart';

import 'support/legal_fixture.dart';

void main() {
  testWidgets(
    'updated agreement covers existing routes and preserves them after acceptance',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 844);
      addTearDown(tester.view.reset);
      final required = ValueNotifier(false);
      addTearDown(required.dispose);
      final navigator = GlobalKey<NavigatorState>();
      final observer = LegalAgreementNavigationObserver();
      var opens = 0;
      var completions = 0;
      final repo = legalFixtureRepository();
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: required,
          builder: (context, needsConsent, _) => MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [observer],
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => LegalAgreementGate(
              required: needsConsent,
              navigationObserver: observer,
              repository: repo,
              child: child!,
              onAgreed: () {
                completions++;
                required.value = false;
              },
            ),
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: TextButton(
              onPressed: () => opens++,
              child: const Text('Existing reader'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Existing reader'));
      expect(opens, 1);
      required.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Existing reader'), findsNothing);
      expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('agreementPrivacyDisclosure')),
      );
      await tester.tap(find.byKey(const Key('agreementPrivacyDisclosure')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('legal-document-scroll')),
        findsOneWidget,
      );
      expect(find.text('Existing reader'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('welcomeNext')));
      await tester.pumpAndSettle();
      expect(completions, 1);
      expect(find.text('Existing reader'), findsOneWidget);
      expect(navigator.currentState!.canPop(), isTrue);
      await tester.tap(find.text('Existing reader'));
      expect(opens, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
