import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_js/flutter_js.dart';

import 'package:xxread/book_sources/protocol/book_source_protocol.dart';

import 'source_script_bootstrap.dart';
import 'source_script_contract.dart';
import 'source_script_host_api.dart';
import 'source_script_state.dart';
import 'source_javascriptcore_runtime.dart';

export 'source_script_contract.dart';

class QuickJsSourceScriptEvaluator implements SourceScriptEvaluator {
  QuickJsSourceScriptEvaluator({JavascriptRuntime? runtime})
    : _runtime =
          runtime ??
          (Platform.isIOS || Platform.isMacOS
              ? SourceJavaScriptCoreRuntime()
              : getJavascriptRuntime(xhr: false)),
      _host = SourceScriptHostApi() {
    _runtime.onMessage(sourceScriptHostChannel, _host.handle);
  }

  JavascriptRuntime _runtime;
  static const _promiseTimeout = Duration(seconds: 30);
  final SourceScriptHostApi _host;
  Future<void> _evaluationTail = Future<void>.value();
  bool _disposed = false;
  bool get isDisposed => _disposed;
  var _promiseSequence = 0;
  var _invocationSequence = 0;

  @override
  Object? evaluate(String script, SourceScriptContext context) {
    return _evaluateAttempt(script, context, const {});
  }

  @override
  Future<Object?> evaluateAsync(String script, SourceScriptContext context) {
    // A network/interaction handler can evaluate a header or response script
    // before its parent can resume. Queueing that child behind its parent
    // deadlocks both. Attempts themselves are synchronous, so children in the
    // active operation can safely run while the parent awaits its handler.
    final scope = Zone.current[this];
    if (scope is _SourceEvaluationScope && scope.active) {
      return _evaluateAsyncLocked(script, context);
    }
    final previous = _evaluationTail;
    final operation = () async {
      try {
        await previous;
      } on Object {
        // A failed script must not poison the queue for later sources.
      }
      final scope = _SourceEvaluationScope();
      try {
        return await runZoned(
          () => _evaluateAsyncLocked(script, context),
          zoneValues: {this: scope},
        );
      } finally {
        scope.active = false;
      }
    }();
    _evaluationTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<Object?> _evaluateAsyncLocked(
    String script,
    SourceScriptContext context,
  ) async {
    final networkResponses = <String, SourceScriptNetworkResult>{};
    final interactionResponses = <String, SourceScriptInteractionResult>{};
    final replayValues = <String, Object?>{};
    var networkCount = 0;
    var interactionCount = 0;
    for (var replayCount = 0; replayCount < 24; replayCount++) {
      try {
        return context.htmlBridge
            ? await _evaluateAttemptAsync(
                script,
                context,
                networkResponses,
                interactionResponses,
                replayValues,
              )
            : _evaluateAttempt(
                script,
                context,
                networkResponses,
                interactionResponses,
                replayValues,
              );
      } on _SourceNetworkNeeded catch (pending) {
        if (++networkCount > 12) {
          throw const BookSourceProtocolException(
            'Source script exceeded the network request limit.',
          );
        }
        final handler = context.networkHandler;
        if (handler == null) {
          throw const BookSourceProtocolException(
            'This source script requested network access outside a source operation.',
          );
        }
        try {
          networkResponses[pending.request.signature] = await handler(
            pending.request,
          );
        } on BookSourceProtocolException catch (error) {
          // Replay failures at the original JS call site so the source's own
          // try/catch can handle optional endpoints. Cancellation is not caught.
          networkResponses[pending.request.signature] =
              SourceScriptNetworkResult(
                body: '',
                finalUrl: pending.request.url,
                failureMessage: error.message,
              );
        }
      } on _SourceInteractionNeeded catch (pending) {
        if (++interactionCount > 4) {
          throw const BookSourceProtocolException(
            'Source script exceeded the user interaction limit.',
          );
        }
        final handler = context.interactionHandler;
        if (handler == null) {
          throw const BookSourceProtocolException(
            'This source requires an interactive verification screen.',
          );
        }
        final result = await handler(pending.request);
        if (result.cancelled) {
          throw const BookSourceProtocolException(
            'Reading source verification was cancelled.',
          );
        }
        if (result.error?.isNotEmpty == true) {
          throw BookSourceProtocolException(result.error!);
        }
        interactionResponses[pending.request.signature] = result;
      }
    }
    throw const BookSourceProtocolException(
      'Source script exceeded the replay limit.',
    );
  }

  Object? _evaluateAttempt(
    String script,
    SourceScriptContext context,
    Map<String, SourceScriptNetworkResult> networkResponses, [
    Map<String, SourceScriptInteractionResult> interactionResponses = const {},
    Map<String, Object?>? replayValues,
  ]) {
    if (_disposed) throw StateError('The source script evaluator is disposed.');
    final invocationId = 'source_invocation_${_invocationSequence++}';
    final state = _host.beginInvocation(
      context,
      networkResponses,
      interactionResponses,
      replayValues ?? <String, Object?>{},
      invocationId,
    );
    try {
      final payload = SourceScriptBootstrap.payload(script, context, state)
        ..['invocationId'] = invocationId;
      final evaluated = _runtime.evaluate(SourceScriptBootstrap.build(payload));
      if (evaluated.isError) {
        final pending = sourceScriptNetworkRequestFromError(
          evaluated.stringResult,
        );
        if (pending != null) throw _SourceNetworkNeeded(pending);
        final interaction = sourceScriptInteractionRequestFromError(
          evaluated.stringResult,
        );
        if (interaction != null) throw _SourceInteractionNeeded(interaction);
        throw BookSourceProtocolException(
          'Reading source JavaScript failed: ${evaluated.stringResult}',
        );
      }
      return _decodeEnvelope(evaluated.stringResult, context, state);
    } finally {
      _host.endInvocation();
    }
  }

  Future<Object?> _evaluateAttemptAsync(
    String script,
    SourceScriptContext context,
    Map<String, SourceScriptNetworkResult> networkResponses,
    Map<String, SourceScriptInteractionResult> interactionResponses,
    Map<String, Object?> replayValues,
  ) async {
    if (_disposed) throw StateError('The source script evaluator is disposed.');
    final invocationId = 'source_invocation_${_invocationSequence++}';
    final state = _host.beginInvocation(
      context,
      networkResponses,
      interactionResponses,
      replayValues,
      invocationId,
    );
    try {
      final payload = SourceScriptBootstrap.payload(script, context, state)
        ..['invocationId'] = invocationId;
      final result = await _settlePromise(
        SourceScriptBootstrap.build(payload, awaitResult: true),
        cancellationCheck: context.cancellationCheck,
      );
      return _decodeEnvelope(result, context, state);
    } finally {
      _host.endInvocation();
    }
  }

  Never _throwAsyncMarkerOrProtocolError(String message) {
    final pending = sourceScriptNetworkRequestFromError(message);
    if (pending != null) throw _SourceNetworkNeeded(pending);
    final interaction = sourceScriptInteractionRequestFromError(message);
    if (interaction != null) throw _SourceInteractionNeeded(interaction);
    throw BookSourceProtocolException(
      'Reading source JavaScript failed: $message',
    );
  }

  Future<String> _settlePromise(
    String expression, {
    void Function()? cancellationCheck,
  }) async {
    final key = '__origo_source_promise_${_promiseSequence++}';
    final encodedKey = jsonEncode(key);
    final started = _runtime.evaluate('''
(() => {
  const key = $encodedKey;
  globalThis[key] = { state: 'pending', value: '' };
  Promise.resolve($expression).then(
    value => { globalThis[key] = { state: 'fulfilled', value: String(value) }; },
    error => { globalThis[key] = {
      state: 'rejected',
      value: String(error) + (error && error.stack ? '\\n' + String(error.stack) : '')
    }; }
  );
  return key;
})()
''');
    if (started.isError) {
      _throwAsyncMarkerOrProtocolError(started.stringResult);
    }
    final deadline = Stopwatch()..start();
    try {
      while (deadline.elapsed < _promiseTimeout) {
        try {
          cancellationCheck?.call();
        } catch (_) {
          _replaceRuntime();
          rethrow;
        }
        _runtime.executePendingJob();
        final checked = _runtime.evaluate(
          'JSON.stringify(globalThis[$encodedKey])',
        );
        if (checked.isError) {
          _throwAsyncMarkerOrProtocolError(checked.stringResult);
        }
        final decoded = jsonDecode(checked.stringResult);
        if (decoded is Map && decoded['state'] == 'fulfilled') {
          return '${decoded['value'] ?? ''}';
        }
        if (decoded is Map && decoded['state'] == 'rejected') {
          _throwAsyncMarkerOrProtocolError('${decoded['value'] ?? ''}');
        }
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      // A timed-out promise can still own timers and queued microtasks. The
      // only safe boundary is to invalidate this evaluator and its JS runtime;
      // otherwise a stale continuation could mutate a later source invocation.
      _replaceRuntime();
      throw const BookSourceProtocolException(
        'Reading source JavaScript promise did not settle.',
      );
    } finally {
      if (!_disposed) {
        _runtime.evaluate('delete globalThis[$encodedKey]');
      }
    }
  }

  void _replaceRuntime() {
    _runtime.dispose();
    _runtime = Platform.isIOS || Platform.isMacOS
        ? SourceJavaScriptCoreRuntime()
        : getJavascriptRuntime(xhr: false);
    _runtime.onMessage(sourceScriptHostChannel, _host.handle);
  }

  Object? _decodeEnvelope(
    String result,
    SourceScriptContext context,
    SourceScriptState state,
  ) {
    try {
      final envelope = jsonDecode(result);
      if (envelope is! Map) {
        throw const FormatException('Script result envelope is not an object.');
      }
      state.variable = '${envelope['sourceVariable'] ?? ''}';
      if (envelope['messages'] case final List messages) {
        for (final message in messages.whereType<String>()) {
          context.messageWriter?.call(message);
        }
      }
      if (envelope['sourceValues'] case final Map sourceValues) {
        state.values = sourceValues.map(
          (key, value) => MapEntry('$key', '${value ?? ''}'),
        );
      }
      if (envelope['loginInfo'] case final Map loginInfo) {
        final normalized = loginInfo.map(
          (key, value) => MapEntry('$key', '${value ?? ''}'),
        );
        if (context.loginInfoWriter != null) {
          context.loginInfoWriter!(normalized);
        } else {
          state.loginInfo = normalized;
        }
      }
      if (envelope['loginHeaders'] case final Map loginHeaders) {
        final normalized = loginHeaders.map(
          (key, value) => MapEntry('$key', '${value ?? ''}'),
        );
        final raw = envelope['rawLoginHeader'] as String? ?? '';
        if (context.loginHeaderWriter != null) {
          context.loginHeaderWriter!(normalized, rawLoginHeader: raw);
        } else {
          state.loginHeaders = normalized;
          state.rawLoginHeader = raw;
        }
      }
      if (envelope['browserLocalStorage'] case final Map origins) {
        final storage = <String, Map<String, String>>{};
        for (final origin in origins.entries) {
          final uri = Uri.tryParse('${origin.key}');
          if (uri == null ||
              !const {'https', 'http'}.contains(uri.scheme) ||
              uri.host.isEmpty ||
              origin.value is! Map) {
            continue;
          }
          storage[uri.origin] = {
            for (final entry in (origin.value as Map).entries)
              '${entry.key}': '${entry.value}',
          };
        }
        final cleared = <String>{
          if (envelope['clearedStorageOrigins'] case final List origins)
            for (final origin in origins) '$origin',
        };
        if (cleared.isNotEmpty ||
            jsonEncode(storage) != jsonEncode(context.browserLocalStorage)) {
          context.localStorageWriter?.call(storage, cleared);
        }
      }
      if (envelope['state'] case final Map javaState) {
        state.javaState = javaState.map(
          (key, value) => MapEntry('$key', value),
        );
      }
      if (envelope['book'] case final Map book) {
        context.bookWriter?.call(
          book.map((key, value) => MapEntry('$key', value)),
        );
      }
      if (envelope['chapter'] case final Map chapter) {
        context.chapterWriter?.call(
          chapter.map((key, value) => MapEntry('$key', value)),
        );
      }
      return envelope['value'];
    } on FormatException catch (error) {
      throw BookSourceProtocolException(
        'Reading source JavaScript returned invalid data: ${error.message}',
      );
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _runtime.dispose();
  }
}

class _SourceEvaluationScope {
  bool active = true;
}

class _SourceNetworkNeeded implements Exception {
  const _SourceNetworkNeeded(this.request);

  final SourceScriptNetworkRequest request;
}

class _SourceInteractionNeeded implements Exception {
  const _SourceInteractionNeeded(this.request);

  final SourceScriptInteractionRequest request;
}
