// Opt-in live diagnostic. It is intentionally outside the hermetic test suite.
//
// SOURCE_REGISTRY_PATH='/absolute/book_sources/registry-v1.json' flutter test \
//   tool/reader_vertical_live_fetch_test.dart --concurrency=1 --reporter expanded
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/services/book_source_client_resources.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';

const _bookQueries = ['三国演义', '封神演义', '隋唐演义'];
const _sensitiveVariablePattern =
    r'(authorization|cookie|credential|header|pass(word)?|secret|session|token)';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'fetches sanitized live books for vertical reader lifecycle auditing',
    () async {
      final registryPath = Platform.environment['SOURCE_REGISTRY_PATH'];
      if (registryPath == null || registryPath.trim().isEmpty) {
        throw ArgumentError(
          'SOURCE_REGISTRY_PATH must point to registry-v1.json.',
        );
      }
      final outputPath =
          Platform.environment['SOURCE_LIVE_OUTPUT'] ??
          'build/reader-vertical-audit-20261010/live-books.json';
      final sourceName =
          Platform.environment['SOURCE_LIVE_SOURCE_NAME'] ?? '七猫';
      final sourceHost =
          Platform.environment['SOURCE_LIVE_SOURCE_HOST'] ?? 'api-bc.wtzw.com';

      // This opt-in test must not read or mutate the installed app's account
      // preferences while exercising the production client facade.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues(const {
        additionalSourceProtocolsPreferenceKey: true,
      });
      AdvancedFeatureAccess.premiumUnlocked = true;
      addTearDown(() => AdvancedFeatureAccess.premiumUnlocked = false);

      final stored = jsonDecode(File(registryPath).readAsStringSync());
      if (stored is! List) {
        throw const FormatException(
          'Book source registry must be a JSON list.',
        );
      }
      final sources = stored
          .whereType<Map>()
          .map(
            (item) =>
                RegisteredBookSource.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false);
      final source = sources.firstWhere(
        (item) =>
            item.enabled &&
            item.name == sourceName &&
            item.apiBaseUrl.host == sourceHost,
        orElse: () => throw StateError(
          'No enabled source named $sourceName at host $sourceHost.',
        ),
      );

      final runtime = SourceRuntime(
        loginSessionStore: _MemorySourceLoginSessionStore(),
      );
      // Keep the production BookSourceClient facade and its default network
      // transport while making credential isolation an explicit contract.
      // ignore: invalid_use_of_visible_for_testing_member
      final client = BookSourceClient.withResources(
        // ignore: invalid_use_of_visible_for_testing_member
        BookSourceClientResources.create(runtime: runtime),
      );
      addTearDown(() {
        client.close();
        runtime.close();
      });
      final samples = <Map<String, Object?>>[];
      for (final query in _bookQueries) {
        final search = await client
            .search(source, query)
            .timeout(const Duration(seconds: 15));
        final candidate = search.items.firstWhere(
          (item) => item.title == query,
          orElse: () => throw StateError(
            '$sourceName returned no exact title for $query.',
          ),
        );
        final book = await client
            .getBook(
              source,
              candidate.id,
              sourceVariables: candidate.sourceVariables,
            )
            .timeout(const Duration(seconds: 15));
        final catalog = await client
            .getChapters(source, book.id, sourceVariables: book.sourceVariables)
            .timeout(const Duration(seconds: 30));
        if (catalog.length < 4) {
          throw StateError('${book.title} returned fewer than four chapters.');
        }
        final chapters = catalog.take(4).toList(growable: false);
        final contents = <BookSourceChapterContent>[];
        for (final chapter in chapters) {
          final content = await client
              .getChapterContent(
                source,
                bookId: book.id,
                chapterId: chapter.id,
                sourceVariables: book.sourceVariables,
              )
              .timeout(const Duration(seconds: 15));
          if (content.content.trim().isEmpty && content.images.isEmpty) {
            throw StateError(
              '${book.title}/${chapter.title} returned no content.',
            );
          }
          contents.add(content);
        }
        samples.add({
          'source': _sanitizedSource(source),
          'book': _sanitizedBook(book),
          'chapters': chapters.map(_chapterJson).toList(growable: false),
          'contents': contents.map(_contentJson).toList(growable: false),
        });
        stdout.writeln(
          'LIVE BOOK ${book.title} chapters=${catalog.length} '
          'sampleChars=${contents.fold<int>(0, (sum, item) => sum + item.content.length)}',
        );
      }

      final output = File(outputPath);
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'generatedAt': DateTime.now().toUtc().toIso8601String(),
          'samples': samples,
        }),
        flush: true,
      );
      stdout.writeln(
        'LIVE DATASET ${output.absolute.path} samples=${samples.length}',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Map<String, Object?> _sanitizedSource(RegisteredBookSource source) => {
  'id': source.id,
  'name': source.name,
  'description': source.description,
  'manifestUrl': source.manifestUrl.toString(),
  'apiBaseUrl': source.apiBaseUrl.toString(),
  'protocolVersion': source.protocolVersion,
  'languages': source.languages,
  'capabilities': source.capabilities.toList()..sort(),
  'sourceProtocol': source.sourceProtocol.name,
};

Map<String, Object?> _sanitizedBook(BookSourceBook book) => {
  'id': book.id,
  'title': book.title,
  'author': book.author,
  'description': book.description,
  'categories': book.categories,
  'sourceVariables': _sanitizedVariables(book.sourceVariables),
};

Map<String, String> _sanitizedVariables(Map<String, String> variables) {
  final sensitive = RegExp(_sensitiveVariablePattern, caseSensitive: false);
  return {
    for (final entry in variables.entries)
      if (!sensitive.hasMatch(entry.key)) entry.key: entry.value,
  };
}

Map<String, Object?> _chapterJson(BookSourceChapter chapter) => {
  'id': chapter.id,
  'title': chapter.title,
  'order': chapter.order,
};

Map<String, Object?> _contentJson(BookSourceChapterContent content) => {
  'bookId': content.bookId,
  'chapterId': content.chapterId,
  'title': content.title,
  'content': content.content,
  'contentType': content.contentType,
  'images': [
    for (final image in content.images) {'url': image.url.toString()},
  ],
};

class _MemorySourceLoginSessionStore implements SourceLoginSessionStore {
  final _sessions = <String, SourceLoginSession>{};

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      _sessions[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    _sessions[sourceId] = session;
  }

  @override
  Future<void> clear(String sourceId) async {
    _sessions.remove(sourceId);
  }
}
