import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_request.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_runtime_state.dart';

const _bookId = 'https://catalog.test/book/1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'large catalog yields so event-loop cancellation stops final state',
    () async {
      final state = _TrackingRuntimeState();
      final runtime = SourceRuntime(
        transport: _CatalogTransport(_catalogHtml(512)),
        state: state,
      );
      addTearDown(runtime.close);
      final cancellation = BookDownloadCancellation();
      var cancellationEventRan = false;
      Timer.run(() {
        cancellationEventRan = true;
        cancellation.cancel();
      });

      await expectLater(
        runtime.getChapters(_source, _bookId, cancellation: cancellation),
        throwsA(isA<BookDownloadCancelledException>()),
      );

      expect(cancellationEventRan, isTrue);
      expect(state.catalogParsed, isFalse);
      expect(state.chapterContext(_config, _bookId, _chapterUrl(1)), isEmpty);
      expect(state.chapterContext(_config, _bookId, _chapterUrl(512)), isEmpty);
    },
  );

  test(
    'cooperative catalog processing preserves order and boundaries',
    () async {
      final state = _TrackingRuntimeState();
      final runtime = SourceRuntime(
        transport: _CatalogTransport(_catalogHtml(130)),
        state: state,
      );
      addTearDown(runtime.close);

      final chapters = await runtime.getChapters(_source, _bookId);

      expect(chapters, hasLength(130));
      expect(chapters.first.id, _chapterUrl(1));
      expect(chapters.first.title, 'Chapter 1');
      expect(chapters.last.id, _chapterUrl(130));
      expect(chapters.last.order, 129);
      expect(
        state.chapterContext(
          _config,
          _bookId,
          _chapterUrl(1),
        )['nextChapterUrl'],
        _chapterUrl(2),
      );
      expect(
        state.chapterContext(
          _config,
          _bookId,
          _chapterUrl(130),
        )['nextChapterUrl'],
        '',
      );
      expect(state.catalogParsed, isTrue);
    },
  );

  test(
    'final context publication yields and leaves catalog incomplete',
    () async {
      final cancellation = BookDownloadCancellation();
      late final _TrackingRuntimeState state;
      state = _TrackingRuntimeState(
        onFirstChapterRemembered: () {
          Timer.run(cancellation.cancel);
        },
      );
      final runtime = SourceRuntime(
        transport: _CatalogTransport(_catalogHtml(130)),
        state: state,
      );
      addTearDown(runtime.close);

      await expectLater(
        runtime.getChapters(_source, _bookId, cancellation: cancellation),
        throwsA(isA<BookDownloadCancelledException>()),
      );

      expect(
        state.chapterContext(_config, _bookId, _chapterUrl(1)),
        isNotEmpty,
      );
      expect(state.chapterContext(_config, _bookId, _chapterUrl(130)), isEmpty);
      expect(state.catalogParsed, isFalse);
    },
  );
}

final _config = ReadingSourceConfig.fromJson({
  'bookSourceName': 'Catalog cancellation test',
  'bookSourceUrl': 'https://catalog.test',
  'ruleToc': {
    'chapterList': '#chapters@li',
    'chapterName': 'a@text',
    'chapterUrl': 'a@href',
  },
});

final _source = _config.toRegisteredSource(enabled: true);

String _catalogHtml(int count) =>
    '''
<ul id="chapters">
${List.generate(count, (index) {
      final chapter = index + 1;
      return '<li><a href="/chapter/$chapter">Chapter $chapter</a></li>';
    }).join()}
</ul>
''';

String _chapterUrl(int chapter) => 'https://catalog.test/chapter/$chapter';

class _CatalogTransport implements SourceTransport {
  const _CatalogTransport(this.body);

  final String body;

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    return SourceResponse(body: body, finalUri: request.url);
  }
}

class _TrackingRuntimeState extends SourceRuntimeState {
  _TrackingRuntimeState({this.onFirstChapterRemembered});

  final void Function()? onFirstChapterRemembered;
  bool catalogParsed = false;
  bool _rememberedChapter = false;

  @override
  void rememberChapterContext(
    ReadingSourceConfig source,
    String bookId,
    String chapterId,
    Map<String, Object?> context,
  ) {
    super.rememberChapterContext(source, bookId, chapterId, context);
    if (!_rememberedChapter) {
      _rememberedChapter = true;
      onFirstChapterRemembered?.call();
    }
  }

  @override
  void rememberCatalogParsed(ReadingSourceConfig source, String bookId) {
    catalogParsed = true;
    super.rememberCatalogParsed(source, bookId);
  }
}
