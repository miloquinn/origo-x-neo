import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/pages/legal/agreement_summary.dart';
import 'package:xxread/pages/legal/legal_document_page.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

void main() {
  late LegalCatalog catalog;
  late LegalDocumentRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    catalog = _catalog();
    final dio = Dio()..httpClientAdapter = _CatalogAdapter(catalog);
    repository = LegalDocumentRepository(
      dio: dio,
      bundledContent: () async => jsonEncode({
        'schemaVersion': 1,
        'bundles': {'en': catalog.toJson(), 'zh-CN': catalog.toJson()},
      }),
    );
  });

  Widget buildSubject({double textScale = 1}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AgreementSummary(catalog: catalog, repository: repository),
          ),
        ),
      ),
    );
  }

  testWidgets('shows three summaries and opens a fixed document snapshot', (
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
    expect(find.text('Terms full paragraph'), findsNothing);

    await tester.tap(find.byKey(const Key('agreementTermsDisclosure')));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentPage), findsOneWidget);
    expect(find.text('Terms full paragraph'), findsOneWidget);
    expect(find.text('2026-10-08.1'), findsWidgets);
    expect(find.text('Scope and acceptance'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits summary and detail on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildSubject(textScale: 1.6));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('agreementPrivacyDisclosure')),
    );
    await tester.tap(find.byKey(const Key('agreementPrivacyDisclosure')));
    await tester.pumpAndSettle();
    expect(find.text('Privacy full paragraph'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

LegalCatalog _catalog() {
  LegalDocument document(String id, String title, String summary, String body) {
    return LegalDocument(
      id: id,
      locale: 'en',
      title: title,
      summary: summary,
      revision: '2026-10-08.1',
      consentVersion: '2026-10-08.1',
      effectiveDate: '2026-10-08',
      updatedAt: '2026-10-08',
      changeSummary: const ['Initial unified publication.'],
      canonicalUrl: Uri.parse('https://open.xxread.top/legal/$id'),
      requiresAcceptance: true,
      sections: [
        LegalSection(
          id: 'scope',
          title: 'Scope and acceptance',
          paragraphs: [body],
        ),
      ],
    );
  }

  return LegalCatalog(
    schemaVersion: 1,
    bundleVersion: '2026-10-08.1',
    locale: 'en',
    documents: [
      document(
        'terms',
        'Terms of use',
        'Rules for using Origo X.',
        'Terms full paragraph',
      ),
      document(
        'sources',
        'Book source notice',
        'Third-party source boundaries.',
        'Source full paragraph',
      ),
      document(
        'privacy',
        'Privacy policy',
        'How data is handled.',
        'Privacy full paragraph',
      ),
    ],
  );
}

class _CatalogAdapter implements HttpClientAdapter {
  _CatalogAdapter(this.catalog);

  final LegalCatalog catalog;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(jsonEncode(catalog.toJson()), 200);

  @override
  void close({bool force = false}) {}
}
