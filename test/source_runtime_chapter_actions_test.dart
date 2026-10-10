import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/source_engine/source_browser_session.dart';
import 'package:xxread/book_sources/source_engine/source_browser_script_request.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_request_template.dart';
import 'package:xxread/book_sources/source_engine/source_response.dart';
import 'package:xxread/book_sources/source_engine/source_runtime.dart';
import 'package:xxread/book_sources/source_engine/source_runtime_login.dart';
import 'package:xxread/book_sources/source_engine/source_script_contract.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'chapter action runs in the source context and preserves reading browser parameters',
    () async {
      final transport = _ActionTransport();
      final sessions = _MemoryLoginSessionStore();
      final runtime = SourceRuntime(
        transport: transport,
        loginSessionStore: sessions,
      );
      addTearDown(runtime.close);
      final source = _source(
        'https://actions.test',
        jsLib: "function decorate(value) { return '[' + value + ']'; }",
      );
      final interactions = <SourceScriptInteractionRequest>[];
      String? nestedCallbackValue;

      await runtime.executeChapterAction(
        source,
        bookId: 'https://actions.test/book/1',
        chapterId: 'https://actions.test/chapter/3',
        script:
            "book.putVariable('remove', 'old'); chapter.putVariable('remove', 'old');",
        result: '',
        sourceVariables: const {'chapterIndex': '3', 'chapterTitle': '第三章'},
      );

      final value = await runtime.executeChapterAction(
        source,
        bookId: 'https://actions.test/book/1',
        chapterId: 'https://actions.test/chapter/3',
        script: '''
          source.setVariable('saved-' + result);
          cache.put('action', 'cached');
          var network = java.ajax('/touch');
          java.showBrowser(
            '/comments',
            '<p>seed</p>',
            'window.seed=1',
            '{"height":0.7}'
          );
          decorate([
            result,
            book.bookUrl,
            book.durChapterIndex,
            book.durChapterTitle,
            chapter.chapterUrl,
            chapter.index,
            chapter.title
          ].join('|')) + '|' + network + '|' + cache.get('action');
        ''',
        result: 'paragraph-7',
        sourceVariables: const {
          'bookName': '测试书',
          'bookAuthor': '作者',
          'chapterIndex': '3',
          'chapterTitle': '第三章',
        },
        interactionHandler: (request) async {
          interactions.add(request);
          nestedCallbackValue = await request.evaluateScript!(
            "book.putVariable('kept', 'book-nested');"
            "chapter.putVariable('kept', 'chapter-nested');"
            "book.putVariable('remove', '');"
            "chapter.putVariable('remove', '');"
            "book.bookUrl + '|' + chapter.title + '|' + result + '|' + source.getVariable()",
          );
          return const SourceScriptInteractionResult(
            finalUrl: 'https://actions.test/comments',
          );
        },
      );

      expect(
        value,
        '[paragraph-7|https://actions.test/book/1|3|第三章|'
        'https://actions.test/chapter/3|3|第三章]|network-ok|cached',
      );
      expect(transport.requests, hasLength(1));
      expect(
        transport.requests.single.url.toString(),
        'https://actions.test/touch',
      );
      expect(interactions, hasLength(1));
      expect(
        nestedCallbackValue,
        'https://actions.test/book/1|第三章|paragraph-7|',
      );
      expect(interactions.single.url, 'https://actions.test/comments');
      expect(interactions.single.html, '<p>seed</p>');
      expect(interactions.single.preloadJs, 'window.seed=1');
      expect(interactions.single.config, '{"height":0.7}');
      expect(
        interactions.single.presentation,
        SourceScriptInteractionPresentation.reading,
      );
      final saved = await sessions.read(source.id);
      expect(saved.sourceVariable, 'saved-paragraph-7');
      expect(saved.scriptCache['action']?.value, 'cached');

      final sameSource = await runtime.executeChapterAction(
        source,
        bookId: '/book/1',
        chapterId: '/chapter/3',
        script:
            "source.getVariable() + ':' + String(cache.get('action')) + ':' + result",
        result: 'again',
      );
      final isolated = await runtime.executeChapterAction(
        _source('https://isolated.test'),
        bookId: '/book/2',
        chapterId: '/chapter/1',
        script:
            "source.getVariable() + ':' + String(cache.get('action')) + ':' + result",
        result: 'other',
      );

      expect(sameSource, 'saved-paragraph-7:cached:again');
      expect(isolated, ':null:other');

      final liveVariables = await runtime.executeChapterAction(
        source,
        bookId: 'https://actions.test/book/1',
        chapterId: 'https://actions.test/chapter/3',
        script:
            "[book.getVariable('kept'), book.getVariable('remove'), chapter.getVariable('kept'), chapter.getVariable('remove')].join('|')",
        result: '',
      );
      expect(liveVariables, 'book-nested||chapter-nested|');
    },
  );

  test(
    'browser callback preserves Legado string and Await semantics',
    () async {
      final transport = _ActionTransport();
      final runtime = SourceRuntime(transport: transport);
      addTearDown(runtime.close);
      final source = _source('https://callbacks.test');

      Future<String> evaluate(String method, List<Object?> arguments) async {
        final value = await runtime.executeChapterAction(
          source,
          bookId: '/book/1',
          chapterId: '/chapter/1',
          script: SourceBrowserScriptRequestEvaluator.scriptFor(
            method,
            arguments,
          ),
          result: 'paragraph',
        );
        return SourceBrowserScriptRequestEvaluator.resultFrom(value);
      }

      expect(await evaluate('eval', const ['1 + 1']), '2');
      expect(await evaluate('run', const ['true']), 'true');
      expect(await evaluate('eval', const ['({value: 7})']), '[object Object]');
      expect(await evaluate('eval', const ["'text'"]), 'text');
      expect(await evaluate('eval', const ["''"]), isEmpty);
      expect(await evaluate('source.getVariable', const []), isEmpty);
      expect(await evaluate('java.get', const ['/get']), 'network-ok');
      expect(
        await evaluate('java.post', const ['/post', 'id=1']),
        'network-ok',
      );
      expect(await evaluate('java.head', const ['/head']), '{}');
      expect(
        jsonDecode(await evaluate('java.connect', const ['/connect'])),
        containsPair('body', 'network-ok'),
      );
      const cryptoArguments = [
        'AES/CBC/PKCS5Padding',
        '1234567890123456',
        '1234567890123456',
        'hello',
      ];
      expect(
        await evaluate('encryptBase64', cryptoArguments),
        'ObBxtb9plyPvM6ZEdBv6MQ==',
      );
      expect(
        await evaluate('encryptHex', cryptoArguments),
        '39b071b5bf699723ef33a644741bfa31',
      );
      expect(
        await evaluate('decryptStr', const [
          'AES/CBC/PKCS5Padding',
          '1234567890123456',
          '1234567890123456',
          'ObBxtb9plyPvM6ZEdBv6MQ==',
        ]),
        'hello',
      );
      expect(
        transport.requests.map((request) => request.method.name.toUpperCase()),
        ['GET', 'POST', 'HEAD', 'GET'],
      );
    },
  );

  test('chapter action cancellation blocks late session writes', () async {
    final sessions = _MemoryLoginSessionStore();
    final runtime = SourceRuntime(
      transport: _ActionTransport(),
      loginSessionStore: sessions,
    );
    addTearDown(runtime.close);
    final source = _source('https://cancel-action.test');
    final cancellation = BookDownloadCancellation();

    await expectLater(
      runtime.executeChapterAction(
        source,
        bookId: '/book/1',
        chapterId: '/chapter/1',
        script:
            "java.showBrowser('/comments'); source.setVariable('late'); 'done';",
        result: 'paragraph',
        cancellation: cancellation,
        interactionHandler: (_) async {
          cancellation.cancel();
          return const SourceScriptInteractionResult(
            finalUrl: 'https://cancel-action.test/comments',
            browserSession: SourceBrowserSession(
              localStorage: {
                'https://cancel-action.test': {'token': 'late'},
              },
            ),
          );
        },
      ),
      throwsA(isA<BookDownloadCancelledException>()),
    );
    expect((await sessions.read(source.id)).sourceVariable, isEmpty);
    expect((await sessions.read(source.id)).browserSession.active, isFalse);
  });

  test(
    'cancellation after a browser session write starts restores the prior account',
    () async {
      const prior = SourceLoginSession(
        loginInfo: {'account': 'prior'},
        sourceVariable: 'prior-variable',
        browserSession: SourceBrowserSession(
          active: true,
          localStorage: {
            'https://write-race.test': {'token': 'prior'},
          },
        ),
      );
      final source = _source('https://write-race.test');
      final sessions = _BlockingLoginSessionStore(source.id, prior);
      final runtime = SourceRuntime(
        transport: _ActionTransport(),
        loginSessionStore: sessions,
      );
      addTearDown(runtime.close);
      final cancellation = BookDownloadCancellation();

      final action = runtime.executeChapterAction(
        source,
        bookId: '/book/1',
        chapterId: '/chapter/1',
        script:
            "source.setVariable('late'); java.showBrowser('/comments'); 'done';",
        result: 'paragraph',
        cancellation: cancellation,
        interactionHandler: (_) async => const SourceScriptInteractionResult(
          finalUrl: 'https://write-race.test/comments',
          browserSession: SourceBrowserSession(
            active: true,
            localStorage: {
              'https://write-race.test': {'token': 'late'},
            },
          ),
        ),
      );
      await sessions.writeStarted.future;
      final concurrentSave = runtime.saveLoginSession(
        source,
        loginInfo: const {'account': 'concurrent'},
      );
      cancellation.cancel();
      sessions.releaseWrite.complete();

      await expectLater(action, throwsA(isA<BookDownloadCancelledException>()));
      await concurrentSave;
      final saved = await sessions.read(source.id);
      expect(saved.loginInfo, const {'account': 'concurrent'});
      expect(saved.sourceVariable, prior.sourceVariable);
      expect(saved.browserSession.toJson(), prior.browserSession.toJson());
      expect(sessions.writeCount, greaterThanOrEqualTo(3));
    },
  );

  test(
    'cancelled action rollback preserves a concurrent same-source login update',
    () async {
      final source = _source('https://concurrent-session.test');
      final sessions = _MemoryLoginSessionStore()
        ..values[source.id] = const SourceLoginSession(
          loginInfo: {'account': 'prior'},
          sourceVariable: 'prior-variable',
          scriptCache: {'prior': SourceScriptCacheEntry(value: 'cached')},
        );
      final runtime = SourceRuntime(
        transport: _ActionTransport(),
        loginSessionStore: sessions,
      );
      addTearDown(runtime.close);
      final callbackReady = Completer<void>();
      final releaseCallback = Completer<void>();
      final cancellation = BookDownloadCancellation();

      final action = runtime.executeChapterAction(
        source,
        bookId: '/book/1',
        chapterId: '/chapter/1',
        script: "java.showBrowser('/comments'); 'done';",
        result: 'paragraph',
        cancellation: cancellation,
        interactionHandler: (request) async {
          await Zone.root.run(
            () => request.evaluateScript!(
              "source.setVariable('action-owned'); cache.put('action', 'late');",
            ),
          );
          callbackReady.complete();
          await releaseCallback.future;
          return const SourceScriptInteractionResult(
            finalUrl: 'https://concurrent-session.test/comments',
          );
        },
      );
      await callbackReady.future;
      await runtime.saveLoginSession(
        source,
        loginInfo: const {'account': 'concurrent'},
      );
      cancellation.cancel();
      releaseCallback.complete();

      await expectLater(action, throwsA(isA<BookDownloadCancelledException>()));
      final saved = await sessions.read(source.id);
      expect(saved.loginInfo, const {'account': 'concurrent'});
      expect(saved.sourceVariable, 'prior-variable');
      expect(saved.scriptCache['prior']?.value, 'cached');
      expect(saved.scriptCache, isNot(contains('action')));
    },
  );

  test(
    'session rollback preserves source and cache updates made during its write',
    () async {
      final source = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Concurrent fields',
        'bookSourceUrl': 'https://concurrent-fields.test',
      });
      const prior = SourceLoginSession(
        sourceVariable: 'prior-variable',
        scriptCache: {'prior': SourceScriptCacheEntry(value: 'cached')},
      );
      final store = _BlockingLoginSessionStore(source.stableId, prior);
      final manager = SourceRuntimeSessionManager(store, null);
      await manager.ensure(source);
      final cancellation = BookDownloadCancellation();

      final transaction = manager.transaction<void>(
        source,
        cancellationCheck: cancellation.throwIfCancelled,
        action: () async {
          manager.updateVariable(source, 'action-owned');
          manager.updateScriptCache(source, const {
            'action': SourceScriptCacheEntry(value: 'late'),
          });
          await manager.saveBrowserSession(
            source,
            const SourceBrowserSession(active: true),
          );
        },
      );
      await store.writeStarted.future;
      manager.updateVariable(source, 'concurrent-variable');
      manager.updateScriptCache(source, const {
        'prior': SourceScriptCacheEntry(value: 'cached'),
        'concurrent': SourceScriptCacheEntry(value: 'kept'),
      });
      final concurrentFlush = manager.flush(source);
      cancellation.cancel();
      store.releaseWrite.complete();

      await expectLater(
        transaction,
        throwsA(isA<BookDownloadCancelledException>()),
      );
      await concurrentFlush;
      await manager.flush(source);
      final saved = await store.read(source.stableId);
      expect(saved.sourceVariable, 'concurrent-variable');
      expect(saved.scriptCache['prior']?.value, 'cached');
      expect(saved.scriptCache['concurrent']?.value, 'kept');
      expect(saved.scriptCache, isNot(contains('action')));
      expect(saved.browserSession.active, isFalse);
    },
  );

  test(
    'cancelled browser transaction cannot overwrite a later successful save',
    () async {
      final source = ReadingSourceConfig.fromJson({
        'bookSourceName': 'Browser race',
        'bookSourceUrl': 'https://browser-race.test',
      });
      const prior = SourceLoginSession(
        browserSession: SourceBrowserSession(
          active: true,
          localStorage: {
            'https://browser-race.test': {'token': 'prior'},
          },
        ),
      );
      final store = _BlockingLoginSessionStore(source.stableId, prior);
      final manager = SourceRuntimeSessionManager(store, null);
      await manager.ensure(source);
      final cancellation = BookDownloadCancellation();

      final first = manager.transaction<void>(
        source,
        cancellationCheck: cancellation.throwIfCancelled,
        action: () => manager.saveBrowserSession(
          source,
          const SourceBrowserSession(
            active: true,
            localStorage: {
              'https://browser-race.test': {'token': 'cancelled'},
            },
          ),
        ),
      );
      await store.writeStarted.future;
      final second = manager.transaction<void>(
        source,
        action: () => manager.saveBrowserSession(
          source,
          const SourceBrowserSession(
            active: true,
            localStorage: {
              'https://browser-race.test': {'token': 'successful'},
            },
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      cancellation.cancel();
      store.releaseWrite.complete();

      await expectLater(first, throwsA(isA<BookDownloadCancelledException>()));
      await second;
      final saved = await store.read(source.stableId);
      expect(
        saved
            .browserSession
            .localStorage['https://browser-race.test']?['token'],
        'successful',
      );
    },
  );

  test(
    'clearing a source while its chapter action is open rejects stale results',
    () async {
      final sessions = _MemoryLoginSessionStore();
      final runtime = SourceRuntime(
        transport: _ActionTransport(),
        loginSessionStore: sessions,
      );
      addTearDown(runtime.close);
      final source = _source('https://stale-action.test');
      final interactionStarted = Completer<void>();
      final releaseInteraction = Completer<void>();

      final action = runtime.executeChapterAction(
        source,
        bookId: '/book/1',
        chapterId: '/chapter/1',
        script:
            "java.showBrowser('/comments'); source.setVariable('late'); 'done';",
        result: 'paragraph',
        interactionHandler: (_) async {
          interactionStarted.complete();
          await releaseInteraction.future;
          return const SourceScriptInteractionResult(
            finalUrl: 'https://stale-action.test/comments',
            browserSession: SourceBrowserSession(
              localStorage: {
                'https://stale-action.test': {'token': 'late'},
              },
            ),
          );
        },
      );
      await interactionStarted.future;
      await runtime.clearLoginSession(source);
      releaseInteraction.complete();

      await expectLater(action, throwsA(isA<SourceBrowserCancelled>()));
      final saved = await sessions.read(source.id);
      expect(saved.sourceVariable, isEmpty);
      expect(saved.browserSession.active, isFalse);
    },
  );
}

RegisteredBookSource _source(String url, {String jsLib = ''}) =>
    ReadingSourceConfig.fromJson({
      'bookSourceName': url,
      'bookSourceUrl': url,
      'jsLib': jsLib,
      'ruleContent': {'content': 'body'},
    }).toRegisteredSource(enabled: true);

class _ActionTransport implements SourceTransport {
  final List<SourceRequestTemplate> requests = [];

  @override
  Future<SourceResponse> send(
    SourceRequestTemplate request, {
    BookDownloadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    requests.add(request);
    return SourceResponse(body: 'network-ok', finalUri: request.url);
  }
}

class _MemoryLoginSessionStore implements SourceLoginSessionStore {
  final Map<String, SourceLoginSession> values = {};

  @override
  Future<void> clear(String sourceId) async => values.remove(sourceId);

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      values[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    values[sourceId] = session;
  }
}

class _BlockingLoginSessionStore implements SourceLoginSessionStore {
  _BlockingLoginSessionStore(String sourceId, SourceLoginSession initial)
    : values = {sourceId: initial};

  final Map<String, SourceLoginSession> values;
  final Completer<void> writeStarted = Completer<void>();
  final Completer<void> releaseWrite = Completer<void>();
  int writeCount = 0;

  @override
  Future<void> clear(String sourceId) async => values.remove(sourceId);

  @override
  Future<SourceLoginSession> read(String sourceId) async =>
      values[sourceId] ?? const SourceLoginSession();

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {
    writeCount++;
    if (writeCount == 1) {
      writeStarted.complete();
      await releaseWrite.future;
    }
    values[sourceId] = session;
  }
}
