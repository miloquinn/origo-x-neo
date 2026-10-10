import 'dart:typed_data';

import '../source_browser_session.dart';
import '../source_login_session.dart';

import 'package:xxread/book_sources/source_engine/source_config.dart';

typedef SourceScriptInteractionEvaluator =
    Future<String> Function(
      String script, {
      void Function()? cancellationCheck,
    });

typedef SourceScriptTransaction =
    Future<T> Function<T>(
      Future<T> Function() action, {
      void Function()? cancellationCheck,
    });

class SourceScriptContext {
  const SourceScriptContext({
    required this.source,
    this.result,
    this.defaultRuleContent,
    this.baseUrl,
    this.scriptBaseUrl,
    this.variables = const {},
    this.book = const {},
    this.chapter = const {},
    this.bookWriter,
    this.chapterWriter,
    this.networkHandler,
    this.cookieReader,
    this.cookieWriter,
    this.cookieRemover,
    this.loginInfo = const {},
    this.loginHeaders = const {},
    this.rawLoginHeader,
    this.sourceVariableReader,
    this.sourceVariableWriter,
    this.persistentCacheReader,
    this.persistentCacheWriter,
    this.browserLocalStorage = const {},
    this.localStorageWriter,
    this.loginInfoWriter,
    this.loginHeaderWriter,
    this.messageWriter,
    this.interactionHandler,
    this.transaction,
    this.htmlBridge = false,
    this.cancellationCheck,
  });

  final ReadingSourceConfig source;
  final Object? result;
  final Object? defaultRuleContent;
  final Uri? baseUrl;
  final String? scriptBaseUrl;
  final Map<String, String> variables;
  final Map<String, Object?> book;
  final Map<String, Object?> chapter;
  final void Function(Map<String, Object?> value)? bookWriter;
  final void Function(Map<String, Object?> value)? chapterWriter;
  final Future<SourceScriptNetworkResult> Function(
    SourceScriptNetworkRequest request,
  )?
  networkHandler;
  final String Function(Uri uri)? cookieReader;
  final void Function(Uri uri, String cookie)? cookieWriter;
  final void Function(Uri uri)? cookieRemover;
  final Map<String, String> loginInfo;
  final Map<String, String> loginHeaders;
  final String? rawLoginHeader;
  final String Function()? sourceVariableReader;
  final void Function(String value)? sourceVariableWriter;
  final Map<String, SourceScriptCacheEntry> Function()? persistentCacheReader;
  final void Function(Map<String, SourceScriptCacheEntry> value)?
  persistentCacheWriter;
  final void Function(String message)? messageWriter;
  final Map<String, Map<String, String>> browserLocalStorage;
  final void Function(
    Map<String, Map<String, String>> value,
    Set<String> clearedOrigins,
  )?
  localStorageWriter;
  final void Function(Map<String, String> value)? loginInfoWriter;
  final void Function(Map<String, String> value, {String? rawLoginHeader})?
  loginHeaderWriter;
  final Future<SourceScriptInteractionResult> Function(
    SourceScriptInteractionRequest request,
  )?
  interactionHandler;
  final SourceScriptTransaction? transaction;
  final bool htmlBridge;
  final void Function()? cancellationCheck;

  SourceScriptContext copyWith({
    void Function(String message)? messageWriter,
    Object? result,
    Object? defaultRuleContent,
    Uri? baseUrl,
    String? scriptBaseUrl,
    Map<String, String>? variables,
    Map<String, Object?>? book,
    Map<String, Object?>? chapter,
    bool? htmlBridge,
    void Function()? cancellationCheck,
    void Function(Map<String, Object?> value)? bookWriter,
    void Function(Map<String, Object?> value)? chapterWriter,
  }) => SourceScriptContext(
    source: source,
    messageWriter: messageWriter ?? this.messageWriter,
    result: result ?? this.result,
    defaultRuleContent: defaultRuleContent ?? this.defaultRuleContent,
    baseUrl: baseUrl ?? this.baseUrl,
    scriptBaseUrl: scriptBaseUrl ?? this.scriptBaseUrl,
    variables: variables ?? this.variables,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    bookWriter: bookWriter ?? this.bookWriter,
    chapterWriter: chapterWriter ?? this.chapterWriter,
    networkHandler: networkHandler,
    cookieReader: cookieReader,
    cookieWriter: cookieWriter,
    cookieRemover: cookieRemover,
    loginInfo: loginInfo,
    loginHeaders: loginHeaders,
    rawLoginHeader: rawLoginHeader,
    sourceVariableReader: sourceVariableReader,
    sourceVariableWriter: sourceVariableWriter,
    persistentCacheReader: persistentCacheReader,
    persistentCacheWriter: persistentCacheWriter,
    browserLocalStorage: browserLocalStorage,
    localStorageWriter: localStorageWriter,
    loginInfoWriter: loginInfoWriter,
    loginHeaderWriter: loginHeaderWriter,
    interactionHandler: interactionHandler,
    transaction: transaction,
    htmlBridge: htmlBridge ?? this.htmlBridge,
    cancellationCheck: cancellationCheck ?? this.cancellationCheck,
  );
}

enum SourceScriptInteractionKind { browser, browserAwait, verificationCode }

enum SourceScriptInteractionPresentation { standard, reading }

class SourceScriptInteractionRequest {
  const SourceScriptInteractionRequest({
    required this.signature,
    required this.kind,
    required this.url,
    this.title = '',
    this.html,
    this.preloadJs,
    this.config,
    this.presentation = SourceScriptInteractionPresentation.standard,
    this.refetchAfterSuccess = false,
    this.headers = const {},
    this.imageBytes,
    this.browserSession = const SourceBrowserSession(),
    this.evaluateScript,
  });

  final String signature;
  final SourceScriptInteractionKind kind;
  final String url;
  final String title;
  final String? html;
  final String? preloadJs;
  final String? config;
  final SourceScriptInteractionPresentation presentation;
  final bool refetchAfterSuccess;
  final Map<String, String> headers;
  final Uint8List? imageBytes;
  final SourceBrowserSession browserSession;
  final SourceScriptInteractionEvaluator? evaluateScript;

  SourceScriptInteractionRequest copyWith({
    String? url,
    String? html,
    String? preloadJs,
    String? config,
    SourceScriptInteractionPresentation? presentation,
    Map<String, String>? headers,
    Uint8List? imageBytes,
    SourceBrowserSession? browserSession,
    SourceScriptInteractionEvaluator? evaluateScript,
  }) => SourceScriptInteractionRequest(
    signature: signature,
    kind: kind,
    url: url ?? this.url,
    title: title,
    html: html ?? this.html,
    preloadJs: preloadJs ?? this.preloadJs,
    config: config ?? this.config,
    presentation: presentation ?? this.presentation,
    refetchAfterSuccess: refetchAfterSuccess,
    headers: headers ?? this.headers,
    imageBytes: imageBytes ?? this.imageBytes,
    browserSession: browserSession ?? this.browserSession,
    evaluateScript: evaluateScript ?? this.evaluateScript,
  );
}

class SourceScriptInteractionResult {
  const SourceScriptInteractionResult({
    this.value = '',
    this.body = '',
    this.finalUrl = '',
    this.cookieHeader,
    this.browserSession,
    this.cancelled = false,
    this.error,
  });

  final String value;
  final String body;
  final String finalUrl;
  final String? cookieHeader;
  final SourceBrowserSession? browserSession;
  final bool cancelled;
  final String? error;

  Map<String, Object?> toJson() => {
    'value': value,
    'body': body,
    'finalUrl': finalUrl,
    'cookieHeader': cookieHeader,
    if (browserSession != null)
      'browserLocalStorage': browserSession!.localStorage,
    'cancelled': cancelled,
    'error': error,
  };
}

class SourceScriptNetworkResult {
  const SourceScriptNetworkResult({
    required this.body,
    required this.finalUrl,
    this.statusCode = 200,
    this.headers = const {},
    this.cookies = const {},
    this.failureMessage,
  });

  final String body;
  final String finalUrl;
  final int statusCode;
  final Map<String, String> headers;
  final Map<String, String> cookies;
  final String? failureMessage;

  Map<String, Object?> toJson() => {
    'body': body,
    'finalUrl': finalUrl,
    'statusCode': statusCode,
    'headers': headers,
    'cookies': cookies,
    if (failureMessage != null) 'failureMessage': failureMessage,
  };
}

class SourceScriptNetworkRequest {
  const SourceScriptNetworkRequest({
    required this.signature,
    required this.method,
    required this.url,
    this.body,
    this.headers = const {},
    this.webJs,
  });

  final String signature;
  final String method;
  final String url;
  final String? body;
  final Map<String, String> headers;
  final String? webJs;
}

abstract class SourceScriptEvaluator {
  Object? evaluate(String script, SourceScriptContext context);

  Future<Object?> evaluateAsync(
    String script,
    SourceScriptContext context,
  ) async => evaluate(script, context);

  void dispose();
}
