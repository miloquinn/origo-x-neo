import 'dart:convert';

import '../models/registered_book_source.dart';
import '../services/book_download_cancellation.dart';
import 'source_browser_session.dart';
import 'source_config.dart';
import 'source_runtime_catalog.dart';
import 'source_runtime_login.dart';
import 'source_runtime_requests.dart';
import 'source_runtime_rules.dart';
import 'source_runtime_state.dart';
import 'scripting/source_script_contract.dart';

class SourceRuntimeChapterActions {
  SourceRuntimeChapterActions(
    this._contexts,
    this._rules,
    this._state,
    this._sessions,
    this._scripts,
  );

  final SourceRuntimeScriptContextPort _contexts;
  final SourceRuntimeRulePort _rules;
  final SourceRuntimeState _state;
  final SourceRuntimeSessionPort _sessions;
  final SourceScriptEvaluator Function() _scripts;

  Future<String> execute(
    RegisteredBookSource registered, {
    required String bookId,
    required String chapterId,
    required String script,
    required String result,
    Map<String, String> sourceVariables = const {},
    BookDownloadCancellation? cancellation,
    Future<SourceScriptInteractionResult> Function(
      SourceScriptInteractionRequest request,
    )?
    interactionHandler,
  }) async {
    cancellation?.throwIfCancelled();
    final source = sourceFromRegistered(registered);
    await _sessions.ensure(source);
    cancellation?.throwIfCancelled();
    final generation = _sessions.generation(source);

    void checkCurrent() {
      cancellation?.throwIfCancelled();
      if (_sessions.generation(source) != generation) {
        throw const SourceBrowserCancelled();
      }
    }

    final ruleState = runtimeRuleStateFor(
      _state,
      _rules,
      source,
      bookId,
      sourceVariables,
    );
    final book = _state.bookContext(
      source,
      bookId,
      ruleState,
      bookType: bookType(source),
    );
    final chapter = _state.chapterContext(source, bookId, chapterId);
    final chapterIndex =
        int.tryParse(sourceVariables['chapterIndex'] ?? '') ??
        _intValue(chapter['index']);
    final chapterTitle =
        sourceVariables['chapterTitle'] ?? '${chapter['title'] ?? ''}';
    book
      ..['bookUrl'] = bookId
      ..['durChapterIndex'] = chapterIndex
      ..['durChapterTitle'] = chapterTitle;
    chapter
      ..['url'] = chapterId
      ..['chapterUrl'] = chapterId
      ..['index'] = chapterIndex
      ..['title'] = chapterTitle;

    final context = _contexts.scriptContext(
      source,
      result: result,
      baseUrl: _chapterBaseUri(source, chapterId),
      variables: requestVariables(ruleState, {
        'bookUrl': bookId,
        'chapterUrl': chapterId,
        'chapterIndex': '$chapterIndex',
        'chapterTitle': chapterTitle,
      }),
      book: book,
      chapter: chapter,
      cancellation: cancellation,
      interactionHandler: interactionHandler,
      interactionPresentation: SourceScriptInteractionPresentation.reading,
    );
    Future<Object?> runAction() async {
      final action = sourceScriptBody(script) ?? script;
      final value = await _scripts().evaluateAsync(action, context);
      checkCurrent();
      final sessions = _sessions;
      if (sessions is SourceRuntimeGuardedSessionPort) {
        await (sessions as SourceRuntimeGuardedSessionPort).flushIfCurrent(
          source,
          expectedGeneration: generation,
        );
      } else {
        await sessions.flush(source);
      }
      checkCurrent();
      return value;
    }

    final sessions = _sessions;
    final value = sessions is SourceRuntimeTransactionalSessionPort
        ? await (sessions as SourceRuntimeTransactionalSessionPort)
              .transaction<Object?>(
                source,
                action: runAction,
                cancellationCheck: checkCurrent,
              )
        : await runAction();
    _state.rememberBookContext(source, bookId, book);
    _state.rememberChapterContext(source, bookId, chapterId, chapter);
    return _stringValue(value);
  }
}

Uri _chapterBaseUri(ReadingSourceConfig source, String chapterId) {
  final parsed = Uri.tryParse(chapterId.trim());
  if (parsed != null && parsed.hasScheme) return parsed;
  return source.baseUri.resolve(chapterId);
}

int _intValue(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  _ => int.tryParse('${value ?? ''}') ?? 0,
};

String _stringValue(Object? value) => switch (value) {
  null => '',
  String text => text,
  Map _ || List _ => jsonEncode(value),
  _ => '$value',
};
