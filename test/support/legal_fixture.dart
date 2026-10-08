import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

Map<String, dynamic> legalFixtureJson({
  String locale = 'en',
  String revision = '2026-10-08.1',
  String? consentVersion,
}) => {
  'schemaVersion': 1,
  'bundleVersion': revision,
  'locale': locale,
  'documents': [
    for (final id in [
      'terms',
      'privacy',
      'sources',
      'membership',
      'privacyChoices',
      'third-party-services',
    ])
      {
        'id': id,
        'locale': locale,
        'title': id,
        'summary': 'Summary of $id',
        'revision': revision,
        'consentVersion': consentVersion ?? revision,
        'effectiveDate': '2026-10-08',
        'updatedAt': '2026-10-08',
        'changeSummary': ['Published $revision'],
        'canonicalUrl': 'https://open.xxread.top/legal/$id',
        'requiresAcceptance': ['terms', 'privacy', 'sources'].contains(id),
        'sections': [
          {
            'id': 'scope',
            'title': 'Scope of $id',
            'paragraphs': ['Readable legal text for $id.'],
            'bullets': [],
            'links': [],
          },
        ],
      },
  ],
};

LegalCatalog legalFixtureCatalog({
  String locale = 'en',
  String revision = '2026-10-08.1',
  String? consentVersion,
}) => LegalCatalog.fromJson(
  legalFixtureJson(
    locale: locale,
    revision: revision,
    consentVersion: consentVersion,
  ),
);

String legalFixtureBundle() => jsonEncode({
  'schemaVersion': 1,
  'bundles': {
    'en': legalFixtureJson(),
    'zh-CN': legalFixtureJson(locale: 'zh-CN'),
  },
});

class LegalTestAdapter implements HttpClientAdapter {
  LegalTestAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

LegalDocumentRepository legalFixtureRepository() {
  final dio = Dio()
    ..httpClientAdapter = LegalTestAdapter(
      (options) async => ResponseBody.fromString(
        jsonEncode(
          legalFixtureJson(locale: options.queryParameters['locale'] as String),
        ),
        200,
        headers: {
          'etag': ['"fixture"'],
        },
      ),
    );
  return LegalDocumentRepository(
    dio: dio,
    bundledContent: () async => legalFixtureBundle(),
  );
}
