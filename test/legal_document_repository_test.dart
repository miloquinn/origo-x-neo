import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

import 'support/legal_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LegalDocumentRepository repository(
    LegalTestAdapter adapter, {
    DateTime Function()? now,
    Uri? endpoint,
  }) => LegalDocumentRepository(
    dio: Dio()..httpClientAdapter = adapter,
    bundledContent: () async => legalFixtureBundle(),
    now: now,
    endpoint: endpoint,
  );
  ResponseBody body(
    Map<String, dynamic> catalog, {
    String etag = '"published"',
  }) => ResponseBody.fromString(
    jsonEncode(catalog),
    200,
    headers: {
      'etag': [etag],
    },
  );

  test(
    'bundled documents are readable without any network or account',
    () async {
      final adapter = LegalTestAdapter(
        (_) async => throw StateError('offline'),
      );
      final repo = repository(adapter);
      expect((await repo.load(locale: 'zh-Hant')).catalog.locale, 'zh-CN');
      expect((await repo.load(locale: 'ja')).catalog.locale, 'en');
      expect(adapter.requests, isEmpty);
      final failed = await repo.refresh(locale: 'ja');
      expect(failed.refreshError, isTrue);
      expect(failed.source, LegalContentSource.bundled);
      expect(
        failed.catalog.document('privacy')!.sections.first.paragraphs,
        isNotEmpty,
      );
      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    },
  );

  test(
    'whole catalog persists across repository restart and an offline refresh',
    () async {
      final online = LegalTestAdapter(
        (_) async => body(legalFixtureJson(revision: '2026-10-08.2')),
      );
      final repo = repository(online);
      final fetched = await repo.refresh(locale: 'en');
      expect(fetched.catalog.bundleVersion, '2026-10-08.2');
      final offline = repository(
        LegalTestAdapter((_) async => throw StateError('offline')),
      );
      final cached = await offline.load(locale: 'en');
      expect(cached.source, LegalContentSource.cache);
      expect(cached.catalog.contentHash, fetched.catalog.contentHash);
      final failed = await offline.refresh(locale: 'en', force: true);
      expect(failed.refreshError, isTrue);
      expect(failed.catalog.contentHash, fetched.catalog.contentHash);
    },
  );

  test('fresh cache avoids requests; stale cache uses ETag and 304', () async {
    var now = DateTime.utc(2026, 10, 8);
    final adapter = LegalTestAdapter(
      (_) async => ResponseBody.fromString('', 304),
    );
    final repo = repository(adapter, now: () => now);
    final seed = repository(
      LegalTestAdapter((_) async => body(legalFixtureJson())),
      now: () => now,
    );
    await seed.refresh(locale: 'en');
    expect((await repo.refresh(locale: 'en')).source, LegalContentSource.cache);
    expect(adapter.requests, isEmpty);
    now = now.add(const Duration(hours: 7));
    final checked = await repo.refresh(locale: 'en');
    expect(checked.refreshError, isFalse);
    expect(checked.checkedAt, now);
    expect(adapter.requests.single.headers['If-None-Match'], '"published"');
    expect(checked.catalog.contentHash, legalFixtureCatalog().contentHash);
  });

  test(
    'concurrent refreshes share one request and languages remain isolated',
    () async {
      final gate = Completer<ResponseBody>();
      final started = Completer<void>();
      final adapter = LegalTestAdapter((_) {
        started.complete();
        return gate.future;
      });
      final repo = repository(adapter);
      final first = repo.refresh(locale: 'zh-TW');
      final second = repo.refresh(locale: 'zh-CN', force: true);
      await started.future;
      expect(adapter.requests.length, 1);
      gate.complete(
        body(legalFixtureJson(locale: 'zh-CN', revision: '2026-10-08.2')),
      );
      expect(
        (await first).catalog.contentHash,
        (await second).catalog.contentHash,
      );
      expect(
        (await repo.load(locale: 'en')).source,
        LegalContentSource.bundled,
      );
      expect(
        (await repo.load(locale: 'zh-CN')).catalog.bundleVersion,
        '2026-10-08.2',
      );
    },
  );

  test(
    'corrupt cache and another service cannot replace bundled text',
    () async {
      final adapter = LegalTestAdapter(
        (_) async => throw StateError('offline'),
      );
      final repo = repository(adapter);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(repo.cacheKey('en'), '{bad json');
      expect(
        (await repo.load(locale: 'en')).source,
        LegalContentSource.bundled,
      );
      final other = repository(
        adapter,
        endpoint: Uri.parse('https://example.com/legal'),
      );
      expect(other.cacheKey('en'), isNot(repo.cacheKey('en')));
    },
  );

  for (final scenario in [
    'unsupported',
    'wrong-locale',
    'missing-document',
    'unchanged-revision',
    'downgrade',
    'unsafe-link',
    'consent-rollback',
    'future-consent',
    'document-newer-than-bundle',
    'wrong-update-date',
  ]) {
    test(
      'invalid publication $scenario never overwrites a readable snapshot',
      () async {
        final json = legalFixtureJson(revision: '2026-10-08.2');
        switch (scenario) {
          case 'unsupported':
            json['schemaVersion'] = 2;
          case 'wrong-locale':
            json['locale'] = 'zh-CN';
          case 'missing-document':
            (json['documents'] as List).removeAt(0);
          case 'unchanged-revision':
            json['bundleVersion'] = '2026-10-08.1';
            for (final doc in json['documents'] as List) {
              doc['revision'] = '2026-10-08.1';
            }
          case 'downgrade':
            json['bundleVersion'] = '2026-10-07.1';
          case 'unsafe-link':
            (json['documents'] as List).first['canonicalUrl'] =
                'javascript:alert(1)';
          case 'consent-rollback':
            (json['documents'] as List).first['consentVersion'] =
                '2026-10-07.1';
          case 'future-consent':
            (json['documents'] as List).first['consentVersion'] =
                '2026-10-08.3';
          case 'document-newer-than-bundle':
            (json['documents'] as List).first['revision'] = '2026-10-08.3';
          case 'wrong-update-date':
            (json['documents'] as List).first['updatedAt'] = '2026-10-07';
        }
        final repo = repository(LegalTestAdapter((_) async => body(json)));
        final result = await repo.refresh(locale: 'en');
        expect(result.refreshError, isTrue);
        expect(result.catalog.contentHash, legalFixtureCatalog().contentHash);
        expect(
          (await SharedPreferences.getInstance()).getString(
            repo.cacheKey('en'),
          ),
          isNull,
        );
      },
    );
  }

  test(
    'a published bundle cannot change even when a document advances',
    () async {
      final original = legalFixtureJson()..['bundleVersion'] = '2026-10-08.2';
      var response = original;
      final repo = repository(LegalTestAdapter((_) async => body(response)));
      final published = await repo.refresh(locale: 'en');
      expect(published.refreshError, isFalse);
      response = legalFixtureJson(revision: '2026-10-08.2');
      final rejected = await repo.refresh(locale: 'en', force: true);
      expect(rejected.refreshError, isTrue);
      expect(rejected.catalog.contentHash, published.catalog.contentHash);
    },
  );

  test(
    'unexpected 304 without a cached publication remains offline-readable',
    () async {
      final result = await repository(
        LegalTestAdapter((_) async => ResponseBody.fromString('', 304)),
      ).refresh(locale: 'en');
      expect(result.refreshError, isTrue);
      expect(result.source, LegalContentSource.bundled);
    },
  );

  test(
    'packaged release has six bilingual validated documents and dated metadata',
    () {
      final bundle =
          jsonDecode(File('assets/legal/documents.json').readAsStringSync())
              as Map;
      for (final locale in ['zh-CN', 'en']) {
        final catalog = LegalCatalog.fromJson(
          bundle['bundles'][locale] as Map<String, dynamic>,
        );
        expect(catalog.documents.map((doc) => doc.id).toSet(), {
          'terms',
          'privacy',
          'sources',
          'membership',
          'privacyChoices',
          'third-party-services',
        });
        for (final doc in catalog.documents) {
          expect(doc.updatedAt, isNotEmpty);
          expect(doc.effectiveDate, isNotEmpty);
          expect(doc.changeSummary, isNotEmpty);
          expect(doc.sections, isNotEmpty);
        }
      }
    },
  );
}
