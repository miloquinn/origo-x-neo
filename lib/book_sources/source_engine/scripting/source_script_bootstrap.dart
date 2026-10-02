import 'dart:convert';

import 'source_script_contract.dart';
import 'source_script_java_compatibility.dart';
import 'source_script_network_guard.dart';
import 'source_script_state.dart';

part 'source_script_bootstrap_program.dart';

const sourceScriptHostChannel = 'OrigoReaderSourceHost';

class SourceScriptBootstrap {
  const SourceScriptBootstrap._();

  static Map<String, Object?> payload(
    String script,
    SourceScriptContext context,
    SourceScriptState state,
  ) {
    final loginInfo = context.loginInfo.isEmpty
        ? state.loginInfo
        : context.loginInfo;
    final ownsSession = context.loginHeaderWriter != null;
    final loginHeaders = ownsSession || context.loginHeaders.isNotEmpty
        ? context.loginHeaders
        : state.loginHeaders;
    final rawLoginHeader =
        context.rawLoginHeader ??
        (!ownsSession && context.loginHeaders.isEmpty
            ? state.rawLoginHeader
            : null) ??
        (loginHeaders.isEmpty ? '' : jsonEncode(loginHeaders));
    return <String, Object?>{
      'script': script,
      'sourceId': context.source.stableId,
      'sourceKey': context.source.url,
      'sourceUrl': context.source.url,
      'sourceComment': context.source.comment,
      'sourceName': context.source.name,
      'sourceType': context.source.type,
      'sourceHeader': _sourceHeader(context.source.raw['header']),
      'sourceGroup': context.source.group,
      'sourceExploreUrl': context.source.exploreUrl,
      'sourceLoginUrl': '${context.source.raw['loginUrl'] ?? ''}',
      'sourceRules': {
        'ruleSearch': context.source.rule('ruleSearch'),
        'ruleExplore': context.source.rule('ruleExplore'),
        'ruleBookInfo': context.source.rule('ruleBookInfo'),
        'ruleToc': context.source.rule('ruleToc'),
        'ruleContent': context.source.rule('ruleContent'),
      },
      'sourceLastUpdateTime': context.source.lastUpdateTime,
      'sourceVariable': state.variable,
      'sourceValues': state.values,
      'loginInfo': loginInfo,
      'loginHeaders': loginHeaders,
      'rawLoginHeader': rawLoginHeader,
      'browserLocalStorage': context.browserLocalStorage,
      'storageOrigin': _storageOrigin(context),
      'sharedScript': context.source.jsLib,
      'state': state.javaState,
      'result': context.result is SourceScriptNetworkResult
          ? {
              '__networkResponse': true,
              ...(context.result as SourceScriptNetworkResult).toJson(),
            }
          : sourceScriptJsonSafe(context.result),
      'defaultRuleContent': sourceScriptJsonSafe(context.defaultRuleContent),
      'baseUrl':
          context.scriptBaseUrl ??
          context.baseUrl?.toString() ??
          context.source.baseUri.toString(),
      'variables': context.variables,
      'hasBook': context.book.isNotEmpty,
      'hasChapter': context.chapter.isNotEmpty,
      'book': context.book,
      'chapter': context.chapter,
      'htmlBridge': context.htmlBridge,
    };
  }

  static String _storageOrigin(SourceScriptContext context) {
    final base = context.baseUrl;
    // Inline data: book/chapter payloads inherit the source's storage scope.
    // They have no HTTP origin of their own.
    if (base != null &&
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty) {
      return base.origin;
    }
    return context.source.baseUri.origin;
  }

  static String build(
    Map<String, Object?> payload, {
    bool awaitResult = false,
  }) {
    // A source's own defensive `try { java.ajax(...) } catch (e) {...}`
    // would otherwise silently swallow the internal marker error this
    // engine throws to request a real (async) network/interaction round
    // trip — see source_script_network_guard.dart.
    final guardedPayload = Map<String, Object?>.from(payload)
      ..['script'] = guardNetworkCatchBlocks('${payload['script'] ?? ''}')
      ..['sharedScript'] = guardNetworkCatchBlocks(
        '${payload['sharedScript'] ?? ''}',
      );
    final encoded = jsonEncode(guardedPayload);
    final sharedFunctionExports = _sharedFunctionExports(
      guardedPayload['sharedScript'],
    );
    return _buildSourceScriptProgram(
      encoded,
      sharedFunctionExports,
      awaitResult,
    );
  }

  // Compatible source scripts expose shared jsLib functions on the script
  // context object. Keep the library lexically scoped to avoid `let`/`const`
  // collisions between
  // invocations, then export its top-level functions so source code using
  // `this.getToken()` or `this.getVariable()` keeps working.
  static String _sharedFunctionExports(Object? sharedScript) {
    final script = sharedScript is String ? sharedScript : '';
    final names = RegExp(
      r'\bfunction\s+([A-Za-z_$][\w$]*)',
    ).allMatches(script).map((match) => match.group(1)!).toSet();
    return names
        .map(
          (name) =>
              '''
if (typeof $name === "function") {
  var __openReadingOriginal_$name = $name;
  $name = function() {
    return __openReadingOriginal_$name.apply(globalThis, arguments);
  };
  __exportShared(${jsonEncode(name)}, $name);
}''',
        )
        .join('\n');
  }
}

Object _sourceHeader(Object? raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry('$key', '$value'));
  }
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', '$value'));
      }
    } on FormatException {
      return const <String, String>{};
    }
  }
  return const <String, String>{};
}
