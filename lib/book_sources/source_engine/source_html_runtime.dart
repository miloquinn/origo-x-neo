import 'dart:convert';

import '../models/registered_book_source.dart';
import '../protocol/book_source_protocol.dart';
import '../services/book_download_cancellation.dart';
import 'source_config.dart';
import 'source_html_contract.dart';
import 'source_runtime_login.dart';
import 'scripting/source_script_contract.dart';

/// Executes the conventional functions exported by an HTML-backed source.
///
/// Network, cookies, storage, and browser interactions remain owned by the
/// shared source script context, so HTML and declarative sources have the same
/// limits, cancellation, session persistence, and transport policy.
class SourceHtmlRuntime {
  SourceHtmlRuntime({
    required this._scripts,
    required this._contexts,
    required this._sessions,
  });

  static const _maxRememberedBooks = 1024;

  final SourceScriptEvaluator Function() _scripts;
  final SourceRuntimeScriptContextPort _contexts;
  final SourceRuntimeSessionPort _sessions;
  final Map<String, Map<String, Object?>> _bookPayloads = {};

  bool handles(RegisteredBookSource registered) {
    final config = registered.sourceConfig;
    return registered.sourceProtocol == BookSourceProtocolKind.readingSource &&
        config != null &&
        SourceHtmlContract.parse(config['html']).isSource;
  }

  Future<BookSourceSearchPage> search(
    RegisteredBookSource registered,
    String query, {
    int page = 1,
    int pageSize = 20,
    BookDownloadCancellation? cancellation,
  }) async {
    final source = sourceFromRegistered(registered);
    final value = await _invoke(
      source,
      'search',
      [query.trim(), page, ''],
      variables: {'key': query.trim(), 'page': '$page'},
      cancellation: cancellation,
    );
    final items = _jsonList(value)
        .map((item) => _book(source, item))
        .whereType<BookSourceBook>()
        .take(100)
        .toList(growable: false);
    return BookSourceSearchPage(
      items: items,
      page: page,
      pageSize: pageSize,
      // HTML contracts receive a page number but no requested page size.
      // Their fixed remote page size is unknowable, so only an empty page is
      // a reliable end-of-pagination signal.
      hasMore: items.isNotEmpty,
    );
  }

  Future<BookSourceBook> getBook(
    RegisteredBookSource registered,
    String bookId, {
    BookDownloadCancellation? cancellation,
  }) async {
    final source = sourceFromRegistered(registered);
    final payload = await _loadInfo(source, bookId, cancellation: cancellation);
    final book = _book(source, payload, fallbackId: bookId);
    if (book == null) {
      throw const BookSourceProtocolException(
        'HTML source info returned a book without a name or URL.',
      );
    }
    return book;
  }

  Future<List<BookSourceChapter>> getChapters(
    RegisteredBookSource registered,
    String bookId, {
    int? maxChapters,
    BookDownloadCancellation? cancellation,
  }) async {
    final source = sourceFromRegistered(registered);
    final info =
        _bookPayloads[_bookKey(source, bookId)] ??
        await _loadInfo(source, bookId, cancellation: cancellation);
    final tocUrl = '${info['tocUrl'] ?? ''}';
    if (tocUrl.trim().isEmpty) {
      throw const BookSourceProtocolException(
        'HTML source info did not return tocUrl.',
      );
    }
    final value = await _invoke(source, 'chapter', [
      tocUrl,
      bookId,
    ], cancellation: cancellation);
    final chapters = <BookSourceChapter>[];
    for (final entry in _jsonList(value).indexed) {
      final item = entry.$2;
      final id = '${item['chapterId'] ?? item['url'] ?? ''}'.trim();
      final title = '${item['name'] ?? item['title'] ?? ''}'.trim();
      if (id.isEmpty || title.isEmpty) continue;
      chapters.add(
        BookSourceChapter(
          id: id,
          title: title,
          order: _int(item['index']) ?? entry.$1,
          updatedAt: _date(item['tag']),
        ),
      );
      if (maxChapters != null && chapters.length >= maxChapters) break;
    }
    return chapters;
  }

  Future<BookSourceChapterContent> getChapterContent(
    RegisteredBookSource registered, {
    required String bookId,
    required String chapterId,
    BookDownloadCancellation? cancellation,
  }) async {
    final source = sourceFromRegistered(registered);
    final value = await _invoke(source, 'content', [
      chapterId,
      bookId,
    ], cancellation: cancellation);
    var content = value is String ? value : jsonEncode(value);
    if (content.startsWith('@html:')) content = content.substring(6);
    if (content.trim().isEmpty) {
      throw const BookSourceProtocolException(
        'HTML source content returned an empty chapter.',
      );
    }
    final isHtml = RegExp(
      r'<(?:p|div|br|img|section|article)\b',
      caseSensitive: false,
    ).hasMatch(content);
    return BookSourceChapterContent(
      bookId: bookId,
      chapterId: chapterId,
      title: '',
      content: content,
      contentType: isHtml ? 'text/html' : 'text/plain',
    );
  }

  Future<Map<String, Object?>> _loadInfo(
    ReadingSourceConfig source,
    String bookId, {
    BookDownloadCancellation? cancellation,
  }) async {
    final value = await _invoke(source, 'info', [
      bookId,
    ], cancellation: cancellation);
    final payload = _jsonMap(value);
    _remember(_bookKey(source, bookId), payload);
    return payload;
  }

  Future<Object?> _invoke(
    ReadingSourceConfig source,
    String function,
    List<Object?> arguments, {
    Map<String, String> variables = const {},
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    await _sessions.ensure(source);
    try {
      return await _scripts().evaluateAsync(
        source.htmlContract.invoke(function, arguments),
        _contexts
            .scriptContext(
              source,
              baseUrl: source.baseUri,
              variables: variables,
              cancellation: cancellation,
            )
            .copyWith(htmlBridge: true),
      );
    } finally {
      await _sessions.flush(source);
    }
  }

  void clearSource(ReadingSourceConfig source) {
    final prefix = '${source.stableId}\u0000';
    _bookPayloads.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() => _bookPayloads.clear();

  BookSourceBook? _book(
    ReadingSourceConfig source,
    Map<String, Object?> item, {
    String? fallbackId,
  }) {
    final id = '${item['bookUrl'] ?? item['url'] ?? fallbackId ?? ''}'.trim();
    final title = '${item['name'] ?? item['title'] ?? ''}'.trim();
    if (id.isEmpty || title.isEmpty) return null;
    final coverText = '${item['coverUrl'] ?? ''}'.trim();
    final cover = coverText.isEmpty ? null : source.baseUri.resolve(coverText);
    final kind = '${item['kind'] ?? ''}'.trim();
    return BookSourceBook(
      id: id,
      title: title,
      author: '${item['author'] ?? ''}'.trim(),
      description: '${item['intro'] ?? item['description'] ?? ''}'.replaceFirst(
        RegExp(r'^@html:', caseSensitive: false),
        '',
      ),
      type: _htmlBookType(_int(item['type']) ?? source.type),
      coverUrl: cover,
      categories: kind
          .split(RegExp(r'[,，]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      latestChapter: _nullable(item['latestChapterTitle']),
      sourceVariables: {
        if ('${item['tocUrl'] ?? ''}'.isNotEmpty)
          'htmlTocUrl': '${item['tocUrl']}',
      },
    );
  }

  void _remember(String key, Map<String, Object?> value) {
    _bookPayloads.remove(key);
    _bookPayloads[key] = value;
    while (_bookPayloads.length > _maxRememberedBooks) {
      _bookPayloads.remove(_bookPayloads.keys.first);
    }
  }

  String _bookKey(ReadingSourceConfig source, String bookId) =>
      '${source.stableId}\u0000$bookId';
}

Object? _decoded(Object? value) {
  if (value is! String) return value;
  final text = value.trim();
  if (text.isEmpty) return text;
  try {
    return jsonDecode(text);
  } on FormatException {
    return value;
  }
}

Map<String, Object?> _jsonMap(Object? value) {
  final decoded = _decoded(value);
  if (decoded is! Map) {
    throw const BookSourceProtocolException(
      'HTML source function must return a JSON object.',
    );
  }
  return decoded.map((key, value) => MapEntry('$key', value));
}

List<Map<String, Object?>> _jsonList(Object? value) {
  final decoded = _decoded(value);
  if (decoded is! List) {
    throw const BookSourceProtocolException(
      'HTML source function must return a JSON array.',
    );
  }
  return decoded
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry('$key', value)))
      .toList(growable: false);
}

int? _int(Object? value) => switch (value) {
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

int _htmlBookType(int value) => switch (value) {
  1 => 32,
  2 => 64,
  3 => 136,
  4 => 4,
  _ => 8,
};

String? _nullable(Object? value) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty ? null : text;
}

DateTime? _date(Object? value) {
  if (value is num && value > 0) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt() < 100000000000 ? value.toInt() * 1000 : value.toInt(),
    );
  }
  return DateTime.tryParse('${value ?? ''}');
}
