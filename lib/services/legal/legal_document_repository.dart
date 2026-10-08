import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/legal_document.dart';

enum LegalContentSource { bundled, cache, network }

class LegalCatalogSnapshot {
  const LegalCatalogSnapshot({
    required this.catalog,
    required this.source,
    this.checkedAt,
    this.refreshError = false,
  });
  final LegalCatalog catalog;
  final LegalContentSource source;
  final DateTime? checkedAt;
  final bool refreshError;
}

class _CachedCatalog {
  const _CachedCatalog(this.catalog, this.checkedAt, this.etag);
  final LegalCatalog catalog;
  final DateTime checkedAt;
  final String? etag;
}

/// Anonymous, versioned legal text. No account credentials or analytics.
/// The whole validated catalog is persisted as one value so summaries and
/// documents cannot be mixed across a partial update.
class LegalDocumentRepository {
  LegalDocumentRepository({
    Dio? dio,
    Uri? endpoint,
    Future<SharedPreferences> Function()? preferences,
    Future<String> Function()? bundledContent,
    DateTime Function()? now,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 5),
               receiveTimeout: const Duration(seconds: 8),
               responseType: ResponseType.plain,
             ),
           ),
       endpoint =
           endpoint ??
           Uri.parse('https://open.xxread.top/api/v1/legal/documents'),
       _preferences = preferences ?? SharedPreferences.getInstance,
       _bundledContent =
           bundledContent ??
           (() => rootBundle.loadString('assets/legal/documents.json')),
       _now = now ?? DateTime.now;

  static final instance = LegalDocumentRepository();
  static const freshness = Duration(hours: 6);
  final Uri endpoint;
  final Dio _dio;
  final Future<SharedPreferences> Function() _preferences;
  final Future<String> Function() _bundledContent;
  final DateTime Function() _now;
  final Map<String, _CachedCatalog> _memory = {};
  final Map<String, Future<LegalCatalogSnapshot>> _refreshes = {};
  Future<Map<String, dynamic>>? _bundle;

  String cacheKey(String locale) =>
      'legal.catalog.v1.'
      '${sha256.convert(utf8.encode(endpoint.toString())).toString().substring(0, 16)}.'
      '${normalizeLegalLocale(locale)}';

  Future<LegalCatalog> bundledCatalog(String locale) async {
    _bundle ??= _bundledContent().then((raw) {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['schemaVersion'] != 1 || value['bundles'] is! Map) {
        throw const FormatException('Invalid bundled legal content');
      }
      return value;
    });
    final bundle = await _bundle!;
    return LegalCatalog.fromJson(
      Map<String, dynamic>.from(
        (bundle['bundles'] as Map)[normalizeLegalLocale(locale)] as Map,
      ),
    );
  }

  Future<_CachedCatalog?> _readCache(String locale) async {
    if (_memory.containsKey(locale)) return _memory[locale];
    try {
      final raw = (await _preferences()).getString(cacheKey(locale));
      if (raw == null || raw.length > 2000000) return null;
      final value = jsonDecode(raw) as Map<String, dynamic>;
      final catalog = LegalCatalog.fromJson(
        value['catalog'] as Map<String, dynamic>,
      );
      final checkedAt = DateTime.parse(value['checkedAt'] as String).toUtc();
      if (catalog.locale != locale ||
          catalog.contentHash != value['contentHash']) {
        return null;
      }
      final cache = _CachedCatalog(
        catalog,
        checkedAt,
        value['etag'] as String?,
      );
      _memory[locale] = cache;
      return cache;
    } catch (_) {
      return null; // Keep the packaged document readable after corruption.
    }
  }

  Future<LegalCatalogSnapshot> load({required String locale}) async {
    locale = normalizeLegalLocale(locale);
    final bundled = await bundledCatalog(locale);
    final cached = await _readCache(locale);
    if (cached == null ||
        compareLegalRevisions(
              cached.catalog.bundleVersion,
              bundled.bundleVersion,
            ) <
            0) {
      return LegalCatalogSnapshot(
        catalog: bundled,
        source: LegalContentSource.bundled,
      );
    }
    return LegalCatalogSnapshot(
      catalog: cached.catalog,
      source: LegalContentSource.cache,
      checkedAt: cached.checkedAt,
    );
  }

  Future<LegalCatalogSnapshot> refresh({
    required String locale,
    bool force = false,
  }) {
    locale = normalizeLegalLocale(locale);
    final pending = _refreshes[locale];
    if (pending != null) return pending;
    final future = _refresh(locale, force).whenComplete(() {
      _refreshes.remove(locale);
    });
    _refreshes[locale] = future;
    return future;
  }

  Future<LegalCatalogSnapshot> _refresh(String locale, bool force) async {
    final previous = await load(locale: locale);
    final cache = await _readCache(locale);
    final now = _now().toUtc();
    final age = cache == null ? null : now.difference(cache.checkedAt);
    if (!force &&
        previous.source != LegalContentSource.bundled &&
        age != null &&
        !age.isNegative &&
        age < freshness) {
      return previous;
    }
    try {
      final response = await _dio.getUri<dynamic>(
        endpoint.replace(
          queryParameters: {...endpoint.queryParameters, 'locale': locale},
        ),
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            if (cache?.etag != null &&
                previous.source != LegalContentSource.bundled)
              'If-None-Match': cache!.etag,
          },
          validateStatus: (status) => status == 200 || status == 304,
        ),
      );
      late final LegalCatalog catalog;
      if (response.statusCode == 304) {
        if (cache == null || previous.source == LegalContentSource.bundled) {
          throw const FormatException('Unmatched legal cache validator');
        }
        catalog = cache.catalog;
      } else {
        final raw = response.data;
        if (raw is! String || raw.length > 2000000) {
          throw const FormatException('Invalid legal response');
        }
        catalog = LegalCatalog.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        if (catalog.locale != locale ||
            compareLegalRevisions(
                  catalog.bundleVersion,
                  previous.catalog.bundleVersion,
                ) <
                0 ||
            (catalog.bundleVersion == previous.catalog.bundleVersion &&
                catalog.contentHash != previous.catalog.contentHash)) {
          throw const FormatException('Outdated legal response');
        }
        for (final old in previous.catalog.documents) {
          final next = catalog.document(old.id);
          if (next == null ||
              compareLegalRevisions(next.revision, old.revision) < 0 ||
              compareLegalRevisions(next.consentVersion, old.consentVersion) <
                  0 ||
              (next.revision == old.revision &&
                  next.contentHash != old.contentHash)) {
            throw const FormatException(
              'Legal revision changed without publication',
            );
          }
        }
      }
      final updated = _CachedCatalog(
        catalog,
        now,
        response.headers.value('etag') ??
            (response.statusCode == 304 ? cache?.etag : null),
      );
      final envelope = jsonEncode({
        'catalog': catalog.toJson(),
        'checkedAt': now.toIso8601String(),
        'etag': updated.etag,
        'contentHash': catalog.contentHash,
      });
      // A cache failure does not hide a successfully fetched document.
      try {
        await (await _preferences()).setString(cacheKey(locale), envelope);
      } catch (_) {}
      _memory[locale] = updated;
      return LegalCatalogSnapshot(
        catalog: catalog,
        source: LegalContentSource.network,
        checkedAt: now,
      );
    } catch (_) {
      return LegalCatalogSnapshot(
        catalog: previous.catalog,
        source: previous.source,
        checkedAt: previous.checkedAt,
        refreshError: true,
      );
    }
  }
}
