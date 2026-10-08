// Run explicitly, outside the hermetic unit suite:
// SOURCE_SAMPLE_PATHS='["/absolute/source.json"]' flutter test \
//   tool/source_sample_smoke_test.dart --concurrency=1 --reporter expanded
// Optional: SOURCE_SAMPLE_QUERY, SOURCE_SAMPLE_LIMIT (default 8).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_debug.dart';
import 'package:xxread/book_sources/source_engine/source_http_transport.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // These are opt-in network diagnostics, never part of the offline test suite.
  HttpOverrides.global = null;
  final paths = jsonDecode(Platform.environment['SOURCE_SAMPLE_PATHS'] ?? '[]');
  if (paths is! List || paths.isEmpty || paths.any((path) => path is! String)) {
    throw ArgumentError(
      'SOURCE_SAMPLE_PATHS must be a nonempty JSON path list.',
    );
  }
  final limit =
      int.tryParse(Platform.environment['SOURCE_SAMPLE_LIMIT'] ?? '') ?? 8;
  final chapterIndex =
      int.tryParse(Platform.environment['SOURCE_SAMPLE_CHAPTER_INDEX'] ?? '') ??
      0;
  if (chapterIndex < 0) {
    throw ArgumentError('Chapter index must be nonnegative.');
  }
  final seen = <String>{};
  final configs = <ReadingSourceConfig>[];
  for (final path in paths.cast<String>()) {
    final imported = parseReadingSources(File(path).readAsStringSync());
    if (imported.errors.isNotEmpty) {
      throw FormatException('Import failed for $path: ${imported.errors}');
    }
    for (final source in imported.sources) {
      if (seen.add(source.url) && configs.length < limit) configs.add(source);
    }
  }
  if (configs.isEmpty) throw StateError('No source definitions found.');
  for (final config in configs) {
    test(
      'live reading chain: ${config.name}',
      () async {
        // This explicit Flutter test lives under tool/ to stay outside CI.
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        final runtime = SourceRuntime(
          transport: SourceHttpTransport(
            requestTimeout: const Duration(seconds: 12),
          ),
          loginSessionStore: _MemorySessionStore(),
          debugRecorder: Platform.environment['SOURCE_SAMPLE_TRACE'] == 'true'
              ? _SafeNetworkTrace()
              : null,
        );
        final cancellation = BookDownloadCancellation();
        final timer = Timer(const Duration(seconds: 90), cancellation.cancel);
        addTearDown(() {
          timer.cancel();
          cancellation.cancel();
          runtime.close();
        });
        final source = config.toRegisteredSource(enabled: true);
        var stage = 'import';
        final watch = Stopwatch()..start();
        try {
          expect(
            source.capabilities,
            containsAll(['search', 'detail', 'catalog', 'content']),
          );
          stage = 'search';
          final query =
              Platform.environment['SOURCE_SAMPLE_QUERY'] ??
              config.rule('ruleSearch')['checkKeyWord']?.toString() ??
              '三国';
          final search = await runtime.search(
            source,
            query,
            cancellation: cancellation,
          );
          expect(search.items, isNotEmpty, reason: 'Search returned no books.');
          stdout.writeln('SMOKE ${config.name} search=${search.items.length}');
          final match = search.items.first;
          stage = 'detail';
          final book = await runtime.getBook(
            source,
            match.id,
            sourceVariables: match.sourceVariables,
            cancellation: cancellation,
          );
          expect(book.title, isNotEmpty);
          stage = 'catalog';
          final chapters = await runtime.getChapters(
            source,
            book.id,
            sourceVariables: book.sourceVariables,
            maxChapters: chapterIndex < 10 ? 10 : chapterIndex + 1,
            cancellation: cancellation,
          );
          expect(chapters, isNotEmpty, reason: 'Catalog returned no chapters.');
          stdout.writeln('SMOKE ${config.name} catalog=${chapters.length}');
          stage = 'content';
          expect(chapters.length, greaterThan(chapterIndex));
          final chapter = chapters[chapterIndex];
          final content = await runtime.getChapterContent(
            source,
            bookId: book.id,
            chapterId: chapter.id,
            sourceVariables: book.sourceVariables,
            cancellation: cancellation,
          );
          expect(
            content.content.trim().isNotEmpty || content.images.isNotEmpty,
            isTrue,
            reason: 'Chapter returned neither text nor images.',
          );
          if (Platform.environment['SOURCE_SAMPLE_PREVIEW'] == 'true') {
            stdout.writeln(
              'SMOKE PREVIEW ${jsonEncode({'book': book.title, 'chapter': chapter.title, 'contentType': content.contentType, 'prefix': content.content.substring(0, content.content.length < 300 ? content.content.length : 300)})}',
            );
          }
          stdout.writeln(
            'SMOKE PASS ${config.name} text=${content.content.length} '
            'images=${content.images.length} elapsedMs=${watch.elapsedMilliseconds}',
          );
        } catch (_) {
          stdout.writeln(
            'SMOKE FAIL ${config.name} stage=$stage elapsedMs=${watch.elapsedMilliseconds}',
          );
          rethrow;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}

// Request values, cookies, headers and response text stay out of trace output.
class _SafeNetworkTrace implements SourceDebugRecorder {
  @override
  void stageStarted(String stage) {}
  @override
  void stageSucceeded(String stage, String summary) {}
  @override
  void stageFailed(String stage, Object error) {}
  @override
  void recordNetwork({
    required String stage,
    required String method,
    required Uri url,
    int? statusCode,
    String? bodyPreview,
    Object? error,
    Duration? elapsed,
  }) {
    stdout.writeln(
      'SMOKE NETWORK $stage $method ${url.scheme}://${url.host}'
      '${url.scheme == 'data' ? '' : url.path} status=$statusCode '
      'elapsedMs=${elapsed?.inMilliseconds} errorType=${error?.runtimeType} '
      'queryKeys=${url.queryParameters.keys.join(",")}',
    );
  }
}

// Diagnostics intentionally start without user credentials and never persist
// live cookies/tokens or change the application's login sessions.
class _MemorySessionStore implements SourceLoginSessionStore {
  final _sessions = <String, SourceLoginSession>{};

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      _sessions[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    _sessions[sourceId] = session;
  }

  @override
  Future<void> clear(String sourceId) async => _sessions.remove(sourceId);
}
