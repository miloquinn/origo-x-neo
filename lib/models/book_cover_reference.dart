import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'book.dart';

/// Immutable runtime locations for a book's local and source-provided covers.
@immutable
class BookCoverReference {
  BookCoverReference({
    String? localPath,
    Uri? remoteUrl,
    Map<String, String> remoteHeaders = const {},
  }) : localPath = _nonEmpty(localPath),
       remoteUrl = remoteUrl != null && _isHttpCoverUri(remoteUrl)
           ? remoteUrl
           : null,
       remoteHeaders = Map<String, String>.unmodifiable(remoteHeaders);

  factory BookCoverReference.fromBook(Book book) {
    final sourceBook = _jsonObject(book.sourceBookJson);
    final source = _jsonObject(book.sourceJson);
    return BookCoverReference(
      localPath: book.coverImagePath,
      remoteUrl: _coverUri(sourceBook, source),
      remoteHeaders: _coverHeaders(sourceBook),
    );
  }

  final String? localPath;
  final Uri? remoteUrl;
  final Map<String, String> remoteHeaders;

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<Object?, Object?>? _jsonObject(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Uri? _coverUri(
    Map<Object?, Object?>? sourceBook,
    Map<Object?, Object?>? source,
  ) {
    final value = sourceBook?['coverUrl'];
    if (value is! String || value.trim().isEmpty) return null;
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) return null;
    if (parsed.hasScheme) return _isHttpCoverUri(parsed) ? parsed : null;
    final baseValue = source?['apiBaseUrl'];
    if (baseValue is! String || baseValue.trim().isEmpty) return null;
    final base = Uri.tryParse(baseValue.trim());
    if (base == null || !_isHttpCoverUri(base)) return null;
    try {
      final resolved = base.resolveUri(parsed);
      return _isHttpCoverUri(resolved) ? resolved : null;
    } catch (_) {
      return null;
    }
  }

  static bool _isHttpCoverUri(Uri uri) =>
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.hasAuthority &&
      uri.host.trim().isNotEmpty;

  static Map<String, String> _coverHeaders(Map<Object?, Object?>? sourceBook) {
    final headers = sourceBook?['coverHeaders'];
    if (headers is! Map) return const {};
    return {
      for (final entry in headers.entries)
        '${entry.key}': '${entry.value ?? ''}',
    };
  }
}
