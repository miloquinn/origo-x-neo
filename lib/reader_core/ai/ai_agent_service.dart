// 文件说明：阅读 Agent 原生工具调用循环，保留各模型的原始助手消息上下文。
// 技术要点：OpenAI tools、Anthropic tool_use、Gemini functionCall、取消与轮次上限。

part of 'ai_service.dart';

class _ReaderAIAgentTurn {
  _ReaderAIAgentTurn(this._service);

  static const int _maxCallsPerRound = 16;

  final ReaderHttpAIService _service;

  Future<String> run({
    required List<AIChatMessage> history,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
    required Future<Map<String, dynamic>> Function(AIToolCall) onToolCall,
    required CancelToken? cancelToken,
    required int maxToolRounds,
  }) async {
    if (maxToolRounds <= 0) {
      throw const AIServiceException(code: 'tool_round_limit_invalid');
    }
    final normalizedTools = _validateTools(tools);
    final messages = history
        .where(
          (message) =>
              (message.role == 'user' || message.role == 'assistant') &&
              message.content.trim().isNotEmpty,
        )
        .toList(growable: false);
    if (!messages.any((message) => message.role == 'user')) {
      throw const AIServiceException(code: 'enter_question_first');
    }

    _throwIfCancelled(cancelToken);
    final settings = await _service._resolveActiveSettings();
    final validationError = validateAIProviderSettings(settings);
    if (validationError != null) {
      throw AIServiceException(code: validationError);
    }

    final conversation = _AgentConversation.create(
      protocol: settings.effectiveProtocol,
      history: messages,
    );

    for (var round = 0; round <= maxToolRounds; round++) {
      _throwIfCancelled(cancelToken);
      final payload = conversation.buildPayload(
        settings: settings,
        systemPrompt: systemPrompt,
        tools: normalizedTools,
      );
      final responseData = await _service._postDecodedChatPayload(
        settings: settings,
        payload: payload,
        cancelToken: cancelToken,
      );

      final step = conversation.readStep(responseData, round: round);
      if (step.calls.isEmpty) {
        final answer = step.text.trim();
        if (answer.isEmpty) {
          throw const AIServiceException(code: 'empty_response');
        }
        return answer;
      }
      if (round == maxToolRounds) {
        throw const AIServiceException(code: 'tool_round_limit_exceeded');
      }

      final results = <_AgentToolResult>[];
      for (var index = 0; index < step.calls.length; index++) {
        final parsed = step.calls[index];
        if (index >= _maxCallsPerRound) {
          results.add(parsed.safeError('tool_call_limit_exceeded'));
          continue;
        }
        final issue = parsed.validationIssue(normalizedTools);
        if (issue != null) {
          results.add(parsed.safeError(issue));
          continue;
        }
        _throwIfCancelled(cancelToken);
        try {
          final output = await onToolCall(parsed.call!);
          jsonEncode(output);
          results.add(parsed.success(output));
        } on DioException catch (error) {
          if (CancelToken.isCancel(error)) rethrow;
          results.add(parsed.safeError('tool_execution_failed'));
        } catch (_) {
          results.add(parsed.safeError('tool_execution_failed'));
        }
        _throwIfCancelled(cancelToken);
      }
      conversation.appendStep(step, results);
    }

    throw const AIServiceException(code: 'tool_round_limit_exceeded');
  }

  List<AIToolDefinition> _validateTools(List<AIToolDefinition> tools) {
    final names = <String>{};
    for (final tool in tools) {
      final name = tool.name.trim();
      if (name.isEmpty || !RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(name)) {
        throw const AIServiceException(code: 'tool_definition_invalid');
      }
      if (!names.add(name)) {
        throw const AIServiceException(code: 'tool_definition_duplicate');
      }
    }
    return List<AIToolDefinition>.unmodifiable(tools);
  }

  void _throwIfCancelled(CancelToken? cancelToken) {
    final error = cancelToken?.cancelError;
    if (error != null) throw error;
  }
}

sealed class _AgentConversation {
  _AgentConversation();

  factory _AgentConversation.create({
    required AIProtocolType protocol,
    required List<AIChatMessage> history,
  }) {
    return switch (protocol) {
      AIProtocolType.openai => _OpenAIAgentConversation(history),
      AIProtocolType.anthropic => _AnthropicAgentConversation(history),
      AIProtocolType.gemini => _GeminiAgentConversation(history),
    };
  }

  Map<String, dynamic> buildPayload({
    required AIProviderSettings settings,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
  });

  _AgentStep readStep(dynamic responseData, {required int round});

  void appendStep(_AgentStep step, List<_AgentToolResult> results);
}

class _OpenAIAgentConversation extends _AgentConversation {
  _OpenAIAgentConversation(List<AIChatMessage> history)
    : _messages = history.map((message) => message.toJson()).toList();

  final List<Map<String, dynamic>> _messages;

  @override
  Map<String, dynamic> buildPayload({
    required AIProviderSettings settings,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
  }) => <String, dynamic>{
    'model': settings.model,
    'messages': <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      ..._messages,
    ],
    if (tools.isNotEmpty)
      'tools': tools
          .map(
            (tool) => <String, dynamic>{
              'type': 'function',
              'function': {
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.parameters,
              },
            },
          )
          .toList(),
    if (const AIProtocolAdapter().supportsTemperature(settings))
      'temperature': settings.provider == AIProviderType.minimax
          ? settings.temperature.clamp(0.01, 1.0)
          : settings.temperature,
    'stream': false,
  };

  @override
  _AgentStep readStep(dynamic responseData, {required int round}) {
    final root = _stringMap(responseData);
    final choices = root?['choices'];
    final choice = choices is List && choices.isNotEmpty
        ? _stringMap(choices.first)
        : null;
    final message = _stringMap(choice?['message']);
    if (message == null) return const _AgentStep.empty();
    final rawCalls = message['tool_calls'];
    final calls = <_ParsedAgentCall>[];
    if (rawCalls is List) {
      for (var index = 0; index < rawCalls.length; index++) {
        final raw = _stringMap(rawCalls[index]);
        final function = _stringMap(raw?['function']);
        final rawId = raw?['id'];
        final id = rawId is String && rawId.isNotEmpty
            ? rawId
            : 'invalid_call_${round}_$index';
        final name = function?['name'];
        final arguments = function?['arguments'];
        Map<String, dynamic>? decodedArguments;
        var malformed = function == null || name is! String || name.isEmpty;
        if (arguments is String) {
          try {
            decodedArguments = _stringMap(jsonDecode(arguments));
          } catch (_) {
            malformed = true;
          }
        } else {
          decodedArguments = _stringMap(arguments);
        }
        if (decodedArguments == null) malformed = true;
        calls.add(
          _ParsedAgentCall(
            id: id,
            name: name is String ? name : '',
            arguments: decodedArguments ?? const {},
            malformed: malformed,
            includeResultId: true,
          ),
        );
      }
    }
    return _AgentStep(
      rawAssistant: Map<String, dynamic>.from(message),
      text: _openAIText(message['content']),
      calls: calls,
    );
  }

  @override
  void appendStep(_AgentStep step, List<_AgentToolResult> results) {
    _messages.add(step.rawAssistant);
    for (final result in results) {
      _messages.add({
        'role': 'tool',
        'tool_call_id': result.id,
        'content': jsonEncode(result.output),
      });
    }
  }
}

class _AnthropicAgentConversation extends _AgentConversation {
  _AnthropicAgentConversation(List<AIChatMessage> history)
    : _messages = history
          .map(
            (message) => <String, dynamic>{
              'role': message.role,
              'content': [
                {'type': 'text', 'text': message.content},
              ],
            },
          )
          .toList();

  final List<Map<String, dynamic>> _messages;

  @override
  Map<String, dynamic> buildPayload({
    required AIProviderSettings settings,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
  }) => <String, dynamic>{
    'model': settings.model,
    'system': systemPrompt,
    'messages': _messages,
    if (tools.isNotEmpty)
      'tools': tools
          .map(
            (tool) => <String, dynamic>{
              'name': tool.name,
              'description': tool.description,
              'input_schema': tool.parameters,
            },
          )
          .toList(),
    'max_tokens': _anthropicDefaultMaxTokens,
    if (const AIProtocolAdapter().supportsTemperature(settings))
      'temperature': settings.temperature.clamp(0.0, 1.0),
  };

  @override
  _AgentStep readStep(dynamic responseData, {required int round}) {
    final root = _stringMap(responseData);
    final content = root?['content'];
    if (content is! List) return const _AgentStep.empty();
    final blocks = content
        .map(_stringMap)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
    final calls = <_ParsedAgentCall>[];
    final text = StringBuffer();
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      if (block['type'] == 'text' && block['text'] is String) {
        text.write(block['text'] as String);
      }
      if (block['type'] != 'tool_use') continue;
      final rawId = block['id'];
      final id = rawId is String && rawId.isNotEmpty
          ? rawId
          : 'invalid_call_${round}_$index';
      final name = block['name'];
      final arguments = _stringMap(block['input']);
      calls.add(
        _ParsedAgentCall(
          id: id,
          name: name is String ? name : '',
          arguments: arguments ?? const {},
          malformed: name is! String || name.isEmpty || arguments == null,
          includeResultId: true,
        ),
      );
    }
    return _AgentStep(
      rawAssistant: {'role': 'assistant', 'content': blocks},
      text: text.toString(),
      calls: calls,
    );
  }

  @override
  void appendStep(_AgentStep step, List<_AgentToolResult> results) {
    _messages.add(step.rawAssistant);
    _messages.add({
      'role': 'user',
      'content': results
          .map(
            (result) => <String, dynamic>{
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': jsonEncode(result.output),
              if (result.isError) 'is_error': true,
            },
          )
          .toList(),
    });
  }
}

class _GeminiAgentConversation extends _AgentConversation {
  _GeminiAgentConversation(List<AIChatMessage> history)
    : _contents = history
          .map(
            (message) => <String, dynamic>{
              'role': message.role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': message.content},
              ],
            },
          )
          .toList();

  final List<Map<String, dynamic>> _contents;

  @override
  Map<String, dynamic> buildPayload({
    required AIProviderSettings settings,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
  }) => <String, dynamic>{
    if (systemPrompt.isNotEmpty)
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
    'contents': _contents,
    if (tools.isNotEmpty)
      'tools': [
        {
          'functionDeclarations': tools
              .map(
                (tool) => <String, dynamic>{
                  'name': tool.name,
                  'description': tool.description,
                  'parameters': tool.parameters,
                },
              )
              .toList(),
        },
      ],
    if (const AIProtocolAdapter().supportsTemperature(settings))
      'generationConfig': {'temperature': settings.temperature.clamp(0.0, 1.0)},
  };

  @override
  _AgentStep readStep(dynamic responseData, {required int round}) {
    final root = _stringMap(responseData);
    final candidates = root?['candidates'];
    final candidate = candidates is List && candidates.isNotEmpty
        ? _stringMap(candidates.first)
        : null;
    final content = _stringMap(candidate?['content']);
    final rawParts = content?['parts'];
    if (content == null || rawParts is! List) {
      return const _AgentStep.empty();
    }
    final parts = rawParts
        .map(_stringMap)
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList();
    final calls = <_ParsedAgentCall>[];
    final text = StringBuffer();
    for (var index = 0; index < parts.length; index++) {
      final part = parts[index];
      if (part['text'] is String) text.write(part['text'] as String);
      if (!part.containsKey('functionCall')) continue;
      final functionCall = _stringMap(part['functionCall']);
      final rawId = functionCall?['id'];
      final id = rawId is String && rawId.isNotEmpty
          ? rawId
          : 'gemini_call_${round}_$index';
      final name = functionCall?['name'];
      final rawArguments = functionCall?['args'];
      final arguments = rawArguments == null
          ? <String, dynamic>{}
          : _stringMap(rawArguments);
      calls.add(
        _ParsedAgentCall(
          id: id,
          name: name is String ? name : '',
          arguments: arguments ?? const {},
          malformed:
              functionCall == null ||
              name is! String ||
              name.isEmpty ||
              (rawArguments != null && arguments == null),
          includeResultId: rawId is String && rawId.isNotEmpty,
        ),
      );
    }
    final assistant = Map<String, dynamic>.from(content);
    assistant['role'] = content['role'] is String ? content['role'] : 'model';
    assistant['parts'] = parts;
    return _AgentStep(
      rawAssistant: assistant,
      text: text.toString(),
      calls: calls,
    );
  }

  @override
  void appendStep(_AgentStep step, List<_AgentToolResult> results) {
    _contents.add(step.rawAssistant);
    _contents.add({
      'role': 'user',
      'parts': results
          .map(
            (result) => <String, dynamic>{
              'functionResponse': {
                if (result.includeId) 'id': result.id,
                'name': result.name,
                'response': result.output,
              },
            },
          )
          .toList(),
    });
  }
}

class _AgentStep {
  final Map<String, dynamic> rawAssistant;
  final String text;
  final List<_ParsedAgentCall> calls;

  const _AgentStep({
    required this.rawAssistant,
    required this.text,
    required this.calls,
  });

  const _AgentStep.empty()
    : rawAssistant = const {},
      text = '',
      calls = const [];
}

class _ParsedAgentCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;
  final bool malformed;
  final bool includeResultId;

  const _ParsedAgentCall({
    required this.id,
    required this.name,
    required this.arguments,
    required this.malformed,
    required this.includeResultId,
  });

  AIToolCall? get call =>
      malformed ? null : AIToolCall(id: id, name: name, arguments: arguments);

  String? validationIssue(List<AIToolDefinition> tools) {
    if (malformed) return 'invalid_tool_call';
    if (!tools.any((tool) => tool.name == name)) return 'unknown_tool';
    return null;
  }

  _AgentToolResult success(Map<String, dynamic> output) => _AgentToolResult(
    id: id,
    name: name,
    output: output,
    isError: false,
    includeId: includeResultId,
  );

  _AgentToolResult safeError(String code) => _AgentToolResult(
    id: id,
    name: name.isEmpty ? 'invalid_tool' : name,
    output: {'error': code},
    isError: true,
    includeId: includeResultId,
  );
}

class _AgentToolResult {
  final String id;
  final String name;
  final Map<String, dynamic> output;
  final bool isError;
  final bool includeId;

  const _AgentToolResult({
    required this.id,
    required this.name,
    required this.output,
    required this.isError,
    required this.includeId,
  });
}

Map<String, dynamic>? _stringMap(dynamic value) {
  if (value is! Map) return null;
  return value.map((key, dynamic item) => MapEntry(key.toString(), item));
}

String _openAIText(dynamic content) {
  if (content is String) return content;
  if (content is! List) return '';
  final buffer = StringBuffer();
  for (final part in content) {
    if (part is String) {
      buffer.write(part);
      continue;
    }
    final map = _stringMap(part);
    if (map?['text'] is String) buffer.write(map!['text'] as String);
  }
  return buffer.toString();
}
