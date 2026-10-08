import 'dart:convert';

import 'package:crypto/crypto.dart';

String normalizeLegalLocale(String locale) =>
    locale.toLowerCase().startsWith('zh') ? 'zh-CN' : 'en';

int compareLegalRevisions(String a, String b) {
  final left = a.split(RegExp(r'[.-]')).map(int.parse).toList();
  final right = b.split(RegExp(r'[.-]')).map(int.parse).toList();
  for (var i = 0; i < left.length; i++) {
    final comparison = left[i].compareTo(right[i]);
    if (comparison != 0) return comparison;
  }
  return 0;
}

String _text(Map<String, dynamic> json, String key, {int limit = 200000}) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty || value.length > limit) {
    throw FormatException('Invalid legal field: $key');
  }
  return value;
}

List<String> _strings(dynamic value, {bool optional = false}) {
  if (value == null && optional) return const [];
  if (value is! List || value.length > 256) {
    throw const FormatException('Invalid legal text list');
  }
  return List.unmodifiable(
    value.map((item) {
      if (item is! String || item.trim().isEmpty || item.length > 200000) {
        throw const FormatException('Invalid legal text');
      }
      return item;
    }),
  );
}

Map<String, dynamic> _object(dynamic value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid legal object');
  }
  return value;
}

String _date(Map<String, dynamic> json, String key) {
  final value = _text(json, key, limit: 10);
  final parsed = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      parsed == null ||
      parsed.toIso8601String().substring(0, 10) != value) {
    throw FormatException('Invalid legal date: $key');
  }
  return value;
}

String _revision(Map<String, dynamic> json, String key) {
  final value = _text(json, key, limit: 100);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}\.\d+$').hasMatch(value)) {
    throw FormatException('Invalid legal revision: $key');
  }
  _date({'date': value.substring(0, 10)}, 'date');
  return value;
}

Uri _uri(String value, {bool canonical = false}) {
  var uri = Uri.parse(value);
  if (!canonical &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      (value.startsWith('/') || value.startsWith('#'))) {
    uri = Uri.parse('https://open.xxread.top').resolveUri(uri);
  }
  if (canonical
      ? uri.scheme != 'https' || uri.host != 'open.xxread.top'
      : !((uri.scheme == 'https' && uri.host.isNotEmpty) ||
            (uri.scheme == 'mailto' && uri.path.isNotEmpty))) {
    throw const FormatException('Invalid legal link');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const FormatException('Invalid legal link');
  }
  return uri;
}

class LegalLink {
  const LegalLink({required this.label, required this.href});
  final String label;
  final Uri href;

  factory LegalLink.fromJson(Map<String, dynamic> json) => LegalLink(
    label: _text(json, 'label', limit: 1000),
    href: _uri(_text(json, 'href', limit: 4000)),
  );
  Map<String, dynamic> toJson() => {'label': label, 'href': href.toString()};
}

class LegalSection {
  const LegalSection({
    required this.id,
    required this.title,
    required this.paragraphs,
    this.bullets = const [],
    this.links = const [],
  });
  final String id;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<LegalLink> links;

  factory LegalSection.fromJson(Map<String, dynamic> json) => LegalSection(
    id: _text(json, 'id', limit: 100),
    title: _text(json, 'title', limit: 1000),
    paragraphs: _strings(json['paragraphs']),
    bullets: _strings(json['bullets'], optional: true),
    links: List.unmodifiable(
      ((json['links'] ?? []) as List).map(
        (item) => LegalLink.fromJson(_object(item)),
      ),
    ),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'paragraphs': paragraphs,
    'bullets': bullets,
    'links': links.map((link) => link.toJson()).toList(),
  };
}

class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.locale,
    required this.title,
    required this.summary,
    required this.revision,
    required this.consentVersion,
    required this.effectiveDate,
    required this.updatedAt,
    required this.changeSummary,
    required this.canonicalUrl,
    required this.requiresAcceptance,
    required this.sections,
  });
  final String id;
  final String locale;
  final String title;
  final String summary;
  final String revision;
  final String consentVersion;
  final String effectiveDate;
  final String updatedAt;
  final List<String> changeSummary;
  final Uri canonicalUrl;
  final bool requiresAcceptance;
  final List<LegalSection> sections;

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    if (rawSections is! List ||
        rawSections.isEmpty ||
        rawSections.length > 256 ||
        json['requiresAcceptance'] is! bool) {
      throw const FormatException('Invalid legal document');
    }
    final sections = rawSections
        .map((item) => LegalSection.fromJson(_object(item)))
        .toList();
    if (sections.map((section) => section.id).toSet().length !=
        sections.length) {
      throw const FormatException('Duplicate legal section');
    }
    final revision = _revision(json, 'revision');
    final consentVersion = _revision(json, 'consentVersion');
    final updatedAt = _date(json, 'updatedAt');
    if (compareLegalRevisions(consentVersion, revision) > 0 ||
        updatedAt != revision.substring(0, 10)) {
      throw const FormatException('Inconsistent legal publication metadata');
    }
    return LegalDocument(
      id: _text(json, 'id', limit: 100),
      locale: _text(json, 'locale', limit: 20),
      title: _text(json, 'title', limit: 1000),
      summary: _text(json, 'summary', limit: 4000),
      revision: revision,
      consentVersion: consentVersion,
      effectiveDate: _date(json, 'effectiveDate'),
      updatedAt: updatedAt,
      changeSummary: _strings(json['changeSummary']),
      canonicalUrl: _uri(
        _text(json, 'canonicalUrl', limit: 4000),
        canonical: true,
      ),
      requiresAcceptance: json['requiresAcceptance'] as bool,
      sections: List.unmodifiable(sections),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'locale': locale,
    'title': title,
    'summary': summary,
    'revision': revision,
    'consentVersion': consentVersion,
    'effectiveDate': effectiveDate,
    'updatedAt': updatedAt,
    'changeSummary': changeSummary,
    'canonicalUrl': canonicalUrl.toString(),
    'requiresAcceptance': requiresAcceptance,
    'sections': sections.map((section) => section.toJson()).toList(),
  };
  String get contentHash =>
      sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();
}

class LegalCatalog {
  const LegalCatalog({
    required this.schemaVersion,
    required this.bundleVersion,
    required this.locale,
    required this.documents,
  });
  final int schemaVersion;
  final String bundleVersion;
  final String locale;
  final List<LegalDocument> documents;
  static const requiredDocumentIds = {'terms', 'privacy', 'sources'};

  factory LegalCatalog.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['documents'] is! List ||
        (json['documents'] as List).length > 32) {
      throw const FormatException('Unsupported legal catalog');
    }
    final locale = _text(json, 'locale', limit: 20);
    if (!{'zh-CN', 'en'}.contains(locale)) {
      throw const FormatException('Unsupported legal locale');
    }
    final documents = (json['documents'] as List)
        .map((item) => LegalDocument.fromJson(_object(item)))
        .toList();
    final ids = documents.map((document) => document.id).toSet();
    final bundleVersion = _revision(json, 'bundleVersion');
    if (ids.length != documents.length ||
        !ids.containsAll(requiredDocumentIds) ||
        documents.any((document) => document.locale != locale) ||
        documents.any(
          (document) =>
              compareLegalRevisions(document.revision, bundleVersion) > 0,
        ) ||
        documents
            .where((document) => requiredDocumentIds.contains(document.id))
            .any((document) => !document.requiresAcceptance)) {
      throw const FormatException('Incomplete legal catalog');
    }
    return LegalCatalog(
      schemaVersion: 1,
      bundleVersion: bundleVersion,
      locale: locale,
      documents: List.unmodifiable(documents),
    );
  }

  LegalDocument? document(String id) {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  Iterable<LegalDocument> get acceptanceDocuments =>
      documents.where((document) => document.requiresAcceptance);
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'bundleVersion': bundleVersion,
    'locale': locale,
    'documents': documents.map((document) => document.toJson()).toList(),
  };
  String get contentHash =>
      sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();
}
