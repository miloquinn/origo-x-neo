// 文件说明：阅读内核 AI 配置与请求模型，统一描述模型、提供商和请求参数。
// 技术要点：ReaderCore、Dio、SharedPreferences、Secure Storage、JSON。

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ai_settings_store.dart';
part 'ai_protocol_adapter.dart';
part 'ai_http_error_translator.dart';
part 'ai_model_presets.dart';
part 'ai_configuration.dart';
part 'ai_agent_protocol.dart';
part 'ai_agent_service.dart';

class AIRequestMeta {
  final String bookId;
  final String chapterId;
  final int? pageIndex;

  const AIRequestMeta({
    required this.bookId,
    required this.chapterId,
    this.pageIndex,
  });
}

class AIChatMessage {
  final String role;
  final String content;

  const AIChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

abstract class AIService {
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  });

  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  });

  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  });
}

abstract class ConfigurableAIService implements AIService {
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]);
  Future<void> saveSettings(AIProviderSettings settings);
}

class AIServiceException implements Exception {
  final String code;
  final String? status;
  final String? text;
  final String? endpoint;
  final String? error;
  final String? provider;
  final String? snippet;

  const AIServiceException({
    required this.code,
    this.status,
    this.text,
    this.endpoint,
    this.error,
    this.provider,
    this.snippet,
  });

  @override
  String toString() => code;
}

class ReaderHttpAIService implements ConfigurableAIService, AgentAIService {
  ReaderHttpAIService({
    Dio? dio,
    AISettingsStore? settingsStore,
    AIProtocolAdapter? protocolAdapter,
    AIErrorTranslator? errorTranslator,
  }) : _dio = dio ?? Dio(),
       _settingsStore = settingsStore ?? SharedPreferencesAISettingsStore(),
       _protocolAdapter = protocolAdapter ?? const AIProtocolAdapter(),
       _errorTranslator = errorTranslator ?? const AIErrorTranslator();

  final Dio _dio;
  final AISettingsStore _settingsStore;
  final AIProtocolAdapter _protocolAdapter;
  final AIErrorTranslator _errorTranslator;

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) =>
      _settingsStore.load(provider);

  @override
  Future<void> saveSettings(AIProviderSettings settings) =>
      _settingsStore.save(settings);

  @override
  Future<String> chatWithTools({
    required List<AIChatMessage> history,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
    required Future<Map<String, dynamic>> Function(AIToolCall) onToolCall,
    CancelToken? cancelToken,
    int maxToolRounds = 6,
  }) => _ReaderAIAgentTurn(this).run(
    history: history,
    systemPrompt: systemPrompt,
    tools: tools,
    onToolCall: onToolCall,
    cancelToken: cancelToken,
    maxToolRounds: maxToolRounds,
  );

  Future<List<String>> fetchAvailableModels(AIProviderSettings settings) async {
    final normalized = settings.normalized();
    if (normalized.apiKey.isEmpty) {
      throw const AIServiceException(code: 'api_key_required');
    }

    final endpoint = _protocolAdapter.modelListEndpoint(normalized);
    final options = _protocolAdapter
        .requestOptions(normalized)
        .copyWith(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 30),
        );

    try {
      final models = <String>{};
      Map<String, dynamic>? query;
      for (var page = 0; page < 20; page += 1) {
        final response = await _dio.get<dynamic>(
          endpoint,
          queryParameters: query,
          options: options,
        );
        final body = _decodeModelListBody(response.data);
        _throwModelListBusinessError(body, endpoint: endpoint);
        final rawModels = body['data'] ?? body['models'];
        if (rawModels is! List) {
          throw const AIServiceException(code: 'no_models_returned');
        }
        models.addAll(
          _extractModelIds(rawModels, protocol: normalized.effectiveProtocol),
        );
        query = _nextModelPageQuery(
          normalized.effectiveProtocol,
          body,
          rawModels,
        );
        if (query == null) break;
      }

      final sortedModels = models.toList()..sort();

      if (sortedModels.isEmpty) {
        throw const AIServiceException(code: 'no_models_available');
      }
      return sortedModels;
    } on DioException catch (error) {
      if (_modelListIsExplicitlyUnsupported(error)) {
        throw AIServiceException(
          code: 'model_list_unsupported_manual_entry',
          status: error.response?.statusCode?.toString(),
          endpoint: endpoint,
        );
      }
      throw _errorTranslator.translate(error);
    } on AIServiceException {
      rethrow;
    } catch (error) {
      throw AIServiceException(
        code: 'fetch_models_failed',
        error: error.toString(),
      );
    }
  }

  Map<dynamic, dynamic> _decodeModelListBody(dynamic data) {
    dynamic body = data;
    if (body is String) body = jsonDecode(body);
    if (body is! Map) {
      throw const AIServiceException(code: 'model_list_format_unrecognized');
    }
    return body;
  }

  void _throwModelListBusinessError(
    Map<dynamic, dynamic> body, {
    required String endpoint,
  }) {
    final error = body['error'];
    final errorMap = error is Map ? error : null;
    final rawCode =
        body['code'] ??
        errorMap?['code'] ??
        errorMap?['status'] ??
        body['status'];
    final code = rawCode?.toString().trim().toLowerCase();
    final hasSuccessCode =
        code == null || code.isEmpty || code == '0' || code == '200';
    final hasErrorObject = error != null;
    if (hasSuccessCode && !hasErrorObject) return;

    final message =
        [
              body['message'],
              body['msg'],
              errorMap?['message'],
              error is String ? error : null,
            ]
            .whereType<Object>()
            .map((value) => value.toString().toLowerCase())
            .join(' ');
    final isAuthenticationError =
        code == '401' ||
        code == '403' ||
        message.contains('invalid api key') ||
        message.contains('invalid_api_key') ||
        message.contains('unauthorized') ||
        message.contains('authentication');
    throw AIServiceException(
      code: isAuthenticationError
          ? 'request_failed_provider_mismatch_hint'
          : 'request_failed_generic',
      status: rawCode?.toString(),
      endpoint: endpoint,
    );
  }

  Iterable<String> _extractModelIds(
    List<dynamic> rawModels, {
    required AIProtocolType protocol,
  }) sync* {
    for (final item in rawModels) {
      if (protocol == AIProtocolType.gemini && item is Map) {
        final methods = item['supportedGenerationMethods'];
        if (methods is List &&
            !methods.any((method) => method.toString() == 'generateContent')) {
          continue;
        }
      }
      final value = item is String
          ? item
          : item is Map
          ? item['id'] ?? item['name'] ?? item['model']
          : null;
      final model = value
          ?.toString()
          .replaceFirst(RegExp(r'^models/'), '')
          .trim();
      if (model != null && model.isNotEmpty) yield model;
    }
  }

  Map<String, dynamic>? _nextModelPageQuery(
    AIProtocolType protocol,
    Map<dynamic, dynamic> body,
    List<dynamic> rawModels,
  ) {
    if (protocol == AIProtocolType.gemini) {
      final token = body['nextPageToken']?.toString().trim();
      return token == null || token.isEmpty ? null : {'pageToken': token};
    }
    if (body['has_more'] != true || rawModels.isEmpty) return null;
    final last = rawModels.last;
    final lastId = last is Map ? last['id']?.toString().trim() : null;
    if (lastId == null || lastId.isEmpty) return null;
    return {
      protocol == AIProtocolType.anthropic ? 'after_id' : 'after': lastId,
    };
  }

  bool _modelListIsExplicitlyUnsupported(DioException error) =>
      const {404, 405, 501}.contains(error.response?.statusCode);

  @override
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  }) {
    final prompt = StringBuffer()
      ..writeln('请解释下面这段选中文本，并给出 3 条要点。')
      ..writeln()
      ..writeln('【选中文本】')
      ..writeln(selectedText.trim())
      ..writeln()
      ..writeln('【上文】')
      ..writeln(contextBefore.trim().isEmpty ? '(无)' : contextBefore.trim())
      ..writeln()
      ..writeln('【下文】')
      ..writeln(contextAfter.trim().isEmpty ? '(无)' : contextAfter.trim());

    return chat(
      history: [AIChatMessage(role: 'user', content: prompt.toString())],
      pageText: '$contextBefore\n$selectedText\n$contextAfter',
      meta: meta,
    );
  }

  @override
  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  }) {
    return chat(
      history: const [
        AIChatMessage(role: 'user', content: '请总结当前页的核心观点，并给出 3 条可执行的阅读建议。'),
      ],
      pageText: pageText,
      meta: meta,
    );
  }

  @override
  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    final settings = await _resolveActiveSettings();
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    final validationError = validateAIProviderSettings(settings);
    if (validationError != null) {
      throw AIServiceException(code: validationError);
    }

    final context = _compactPageContext(pageText);
    final singleSystemPrompt = _buildSingleSystemPrompt(
      context: context,
      meta: meta,
    );
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': singleSystemPrompt},
      ...history
          .where(
            (m) =>
                (m.role == 'user' ||
                    m.role == 'assistant' ||
                    m.role == 'system') &&
                m.content.trim().isNotEmpty,
          )
          .map((m) => m.toJson()),
    ];

    if (!messages.any((m) => m['role'] == 'user')) {
      throw const AIServiceException(code: 'enter_question_first');
    }

    final payload = _protocolAdapter.buildPayload(
      settings: settings,
      messages: messages,
    );
    final responseData = await _postDecodedChatPayload(
      settings: settings,
      payload: payload,
      cancelToken: cancelToken,
    );

    try {
      final answer = _protocolAdapter.extractAssistantContent(
        settings: settings,
        responseData: responseData,
      );
      if (answer.trim().isEmpty) {
        throw const AIServiceException(code: 'empty_response');
      }
      return answer.trim();
    } on AIServiceException {
      rethrow;
    } catch (e) {
      throw AIServiceException(code: 'request_failed', error: e.toString());
    }
  }

  Future<dynamic> _postDecodedChatPayload({
    required AIProviderSettings settings,
    required Map<String, dynamic> payload,
    CancelToken? cancelToken,
  }) async {
    final endpoint = _protocolAdapter.chatEndpoint(settings);
    try {
      final response = await _dio.post<String>(
        endpoint,
        data: payload,
        options: _protocolAdapter.requestOptions(settings),
        cancelToken: cancelToken,
      );
      return _decodeResponseBody(
        rawBody: response.data,
        endpoint: endpoint,
        settings: settings,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      throw _errorTranslator.translate(error);
    } on AIServiceException {
      rethrow;
    } catch (error) {
      throw AIServiceException(code: 'request_failed', error: error.toString());
    }
  }

  /// 每次请求都重新读取当前激活配置：服务在各页面被独立实例化，
  /// 实例级缓存会让设置页切换的模型无法作用到已打开的对话界面。
  Future<AIProviderSettings> _resolveActiveSettings() => loadSettings();

  String _compactPageContext(String pageText) {
    final text = pageText
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.length <= 2800) {
      return text;
    }
    return '${text.substring(0, 2800)}...';
  }

  String _buildSingleSystemPrompt({
    required String context,
    required AIRequestMeta meta,
  }) {
    final buffer = StringBuffer()
      ..writeln('你是一个中文阅读助手。')
      ..writeln('回答要求：简洁、准确、结构清晰，优先结合用户当前阅读页内容。')
      ..writeln(
        '元信息：bookId=${meta.bookId}, chapterId=${meta.chapterId}, pageIndex=${meta.pageIndex ?? -1}',
      );
    if (context.isNotEmpty) {
      buffer
        ..writeln('当前阅读页正文（仅供参考）：')
        ..writeln(context);
    }
    return buffer.toString().trim();
  }

  dynamic _decodeResponseBody({
    required String? rawBody,
    required String endpoint,
    required AIProviderSettings settings,
  }) {
    final body = rawBody?.trim() ?? '';
    if (body.isEmpty) {
      throw AIServiceException(
        code: 'empty_response_error',
        endpoint: endpoint,
      );
    }

    try {
      return jsonDecode(body);
    } on FormatException {
      throw AIServiceException(
        code: 'invalid_json_error',
        provider: settings.provider.displayName,
        endpoint: endpoint,
        snippet: _errorTranslator.truncateForError(body),
      );
    }
  }
}

class MockAIService implements ConfigurableAIService {
  AIProviderSettings _settings = AIProviderSettings.defaults(
    AIProviderType.minimax,
  );

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async {
    if (provider == null || provider == _settings.provider) {
      return _settings;
    }
    return AIProviderSettings.defaults(provider);
  }

  @override
  Future<void> saveSettings(AIProviderSettings settings) async {
    _settings = settings.normalized();
  }

  @override
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _mockToken('mock_selection_response', {
      'selectedText': selectedText,
      'before': _trim(contextBefore),
      'after': _trim(contextAfter),
    });
  }

  @override
  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _mockToken('mock_page_analysis', {'chars': pageText.length});
  }

  @override
  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (cancelToken?.isCancelled ?? false) throw cancelToken!.cancelError!;
    final last = history.isNotEmpty ? history.last.content : '';
    if (last.trim().isEmpty) {
      return _mockToken('mock_greeting', {});
    }
    return _mockToken('mock_chat_response', {
      'question': _trim(last),
      'chars': pageText.length,
    });
  }

  String _trim(String text) {
    if (text.length <= 80) return text;
    return '${text.substring(0, 80)}...';
  }

  /// Encode a mock response as a token that the UI layer translates
  /// via [translateMockAiResponse].
  static String _mockToken(String code, Map<String, dynamic> params) {
    return '[[mock:$code|${jsonEncode(params)}]]';
  }
}
