import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/legal/user_agreement_page.dart';
import 'support/legal_fixture.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'updated terms require the current version and source acknowledgment',
    () async {
      final catalog = legalFixtureCatalog();

      SharedPreferences.setMockInitialValues({
        'userAgreementAccepted': true,
        'agreementAcceptedVersion': '2026-07-13.1',
        'thirdPartySourceBoundaryAccepted': true,
      });

      expect(
        await UserAgreementService.hasUserAcceptedAgreement(
          catalog: legalFixtureCatalog(),
        ),
        isFalse,
      );

      await UserAgreementService.acceptAgreement(
        locale: 'en',
        catalog: catalog,
      );

      expect(
        await UserAgreementService.hasUserAcceptedAgreement(
          catalog: legalFixtureCatalog(),
        ),
        isTrue,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('agreementAcceptedVersion'),
        catalog.bundleVersion,
      );
      expect(prefs.getString('agreementAcceptedLocale'), 'en');
      expect(prefs.getBool('thirdPartySourceBoundaryAccepted'), isTrue);
    },
  );

  testWidgets('one explicit acceptance completes the welcome and legal flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 844);
    addTearDown(tester.view.reset);
    var agreedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UserAgreementPage(
          repository: legalFixtureRepository(),
          onAgreed: () => agreedCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcomePager')), findsOneWidget);
    expect(find.byKey(const Key('agreementTermsDisclosure')), findsNothing);

    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
    expect(find.byKey(const Key('agreementTermsDisclosure')), findsOneWidget);
    expect(find.byKey(const Key('agreementSourceDisclosure')), findsOneWidget);
    expect(find.byKey(const Key('agreementPrivacyDisclosure')), findsOneWidget);
    expect(find.text('Agree and continue'), findsOneWidget);
    expect(
      await UserAgreementService.hasUserAcceptedAgreement(
        catalog: legalFixtureCatalog(),
      ),
      isFalse,
    );

    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(agreedCount, 1);
    expect(
      await UserAgreementService.hasUserAcceptedAgreement(
        catalog: legalFixtureCatalog(),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a pending material update cannot accept an older snapshot', (
    tester,
  ) async {
    final repository = _PendingLegalRepository();
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UserAgreementPage(
          repository: repository,
          onAgreed: () => completions++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pump();
    expect(completions, 0);
    expect(
      (await SharedPreferences.getInstance()).getString(
        UserAgreementService.receiptKey,
      ),
      isNull,
    );
    repository.pending.complete(
      LegalCatalogSnapshot(
        catalog: legalFixtureCatalog(revision: '2026-10-08.2'),
        source: LegalContentSource.network,
      ),
    );
    await tester.pumpAndSettle();
    expect(completions, 0);
    expect(
      (await SharedPreferences.getInstance()).getString(
        UserAgreementService.receiptKey,
      ),
      isNull,
    );
    await tester.tap(find.byKey(const Key('welcomeNext')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(completions, 1);
    expect(
      await UserAgreementService.hasUserAcceptedAgreement(
        catalog: legalFixtureCatalog(revision: '2026-10-08.2'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('declining requires confirmation before invoking onDisagreed', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 844);
    addTearDown(tester.view.reset);
    var disagreed = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: UserAgreementPage(
          repository: legalFixtureRepository(),
          onAgreed: () {},
          onDisagreed: () => disagreed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('welcomeSkip')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('welcomeDecline')));
    await tester.pumpAndSettle();
    expect(find.text('Decline the terms?'), findsOneWidget);
    expect(disagreed, isFalse);

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(disagreed, isFalse);

    await tester.tap(find.byKey(const Key('welcomeDecline')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();

    expect(disagreed, isTrue);
    expect(
      await UserAgreementService.hasUserAcceptedAgreement(
        catalog: legalFixtureCatalog(),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('welcome agreement flow fits a narrow screen in $locale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 720);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: UserAgreementPage(
            repository: legalFixtureRepository(),
            onAgreed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'welcome in $locale');

      await tester.tap(find.byKey(const Key('welcomeSkip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('agreementTermsDisclosure')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'agreement in $locale');
    });
  }
}

class _PendingLegalRepository extends LegalDocumentRepository {
  final pending = Completer<LegalCatalogSnapshot>();
  @override
  Future<LegalCatalogSnapshot> load({required String locale}) async =>
      LegalCatalogSnapshot(
        catalog: legalFixtureCatalog(),
        source: LegalContentSource.bundled,
      );
  @override
  Future<LegalCatalogSnapshot> refresh({
    required String locale,
    bool force = false,
  }) => pending.future;
}
