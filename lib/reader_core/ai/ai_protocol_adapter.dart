// 文件说明：AI 提供商协议适配器，集中处理 Endpoint、Header、Payload 与成功响应正文。
// 技术要点：OpenAI Compatible、Anthropic Messages、Google Gemini GenerateContent、Dio Options。

part of 'ai_service.dart';

const int _anthropicDefaultMaxTokens = 8192;

class AIProtocolAdapter {
  const AIProtocolAdapter();

  String chatEndpoint(AIProviderSettings settings) {
    final base = normalizeAIBaseUrl(
      settings.provider,
      settings.baseUrl,
      protocol: settings.effectiveProtocol,
    );
    switch (settings.effectiveProtocol) {
      case AIProtocolType.openai:
        return '$base/chat/completions';
      case AIProtocolType.anthropic:
        return base.endsWith('/v1') ? '$base/messages' : '$base/v1/messages';
      case AIProtocolType.gemini:
        final modelPath = settings.model.startsWith('models/')
            ? settings.model
            : 'models/${settings.model}';
        return '$base/$modelPath:generateContent';
    }
  }

  String modelListEndpoint(AIProviderSettings settings) {
    final base = normalizeAIBaseUrl(
      settings.provider,
      settings.baseUrl,
      protocol: settings.effectiveProtocol,
    );
    return switch (settings.effectiveProtocol) {
      AIProtocolType.anthropic =>
        base.endsWith('/v1') ? '$base/models' : '$base/v1/models',
      AIProtocolType.openai || AIProtocolType.gemini => '$base/models',
    };
  }

  Options requestOptions(AIProviderSettings settings) {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};

    switch (settings.effectiveProtocol) {
      case AIProtocolType.openai:
        headers['Authorization'] = 'Bearer ${settings.apiKey}';
        break;
      case AIProtocolType.anthropic:
        headers['x-api-key'] = settings.apiKey;
        headers['anthropic-version'] = '2023-06-01';
        break;
      case AIProtocolType.gemini:
        headers['x-goog-api-key'] = settings.apiKey;
        break;
    }

    return Options(
      headers: headers,
      responseType: ResponseType.plain,
      receiveDataWhenStatusError: true,
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
    );
  }

  Map<String, dynamic> buildPayload({
    required AIProviderSettings settings,
    required List<Map<String, dynamic>> messages,
  }) {
    if (settings.provider == AIProviderType.minimax &&
        settings.effectiveProtocol == AIProtocolType.openai) {
      return <String, dynamic>{
        'model': settings.model,
        'messages': messages,
        'temperature': settings.temperature.clamp(0.01, 1.0),
        'stream': false,
      };
    }
    switch (settings.effectiveProtocol) {
      case AIProtocolType.openai:
        return <String, dynamic>{
          'model': settings.model,
          'messages': messages,
          'temperature': settings.temperature,
          'stream': false,
        };
      case AIProtocolType.anthropic:
        final systemPrompt = _systemPrompt(messages);
        final chatMessages = messages
            .where((message) {
              final role = message['role'];
              return role == 'user' || role == 'assistant';
            })
            .map(
              (message) => <String, dynamic>{
                'role': message['role'],
                'content': [
                  {
                    'type': 'text',
                    'text': (message['content'] as String?) ?? '',
                  },
                ],
              },
            )
            .toList();
        return <String, dynamic>{
          'model': settings.model,
          'system': systemPrompt,
          'messages': chatMessages,
          'max_tokens': _anthropicDefaultMaxTokens,
          if (supportsTemperature(settings))
            'temperature': settings.temperature.clamp(0.0, 1.0),
        };
      case AIProtocolType.gemini:
        final systemPrompt = _systemPrompt(messages);
        final contents = messages
            .where((message) {
              final role = message['role'];
              return role == 'user' || role == 'assistant';
            })
            .map(
              (message) => <String, dynamic>{
                'role': message['role'] == 'assistant' ? 'model' : 'user',
                'parts': [
                  {'text': (message['content'] as String?) ?? ''},
                ],
              },
            )
            .toList();
        return <String, dynamic>{
          if (systemPrompt.isNotEmpty)
            'systemInstruction': {
              'parts': [
                {'text': systemPrompt},
              ],
            },
          'contents': contents,
          if (supportsTemperature(settings))
            'generationConfig': {
              'temperature': settings.temperature.clamp(0.0, 1.0),
            },
        };
    }
  }

  bool supportsTemperature(AIProviderSettings settings) {
    final model = settings.model.trim().toLowerCase();
    if (settings.effectiveProtocol == AIProtocolType.gemini) {
      final match = RegExp(r'^gemini-(\d+)').firstMatch(model);
      final major = int.tryParse(match?.group(1) ?? '');
      return major == null || major < 3;
    }
    if (settings.effectiveProtocol == AIProtocolType.anthropic &&
        model.startsWith('claude-')) {
      final match = RegExp(
        r'^claude-(?:[a-z]+-)?(\d+)(?:[-.](\d+))?',
      ).firstMatch(model);
      final major = int.tryParse(match?.group(1) ?? '');
      final minor = int.tryParse(match?.group(2) ?? '') ?? 0;
      if (major != null && (major > 4 || major == 4 && minor >= 7)) {
        return false;
      }
    }
    return true;
  }

  String extractAssistantContent({
    required AIProviderSettings settings,
    required dynamic responseData,
  }) {
    switch (settings.effectiveProtocol) {
      case AIProtocolType.openai:
        return _extractOpenAIContent(responseData);
      case AIProtocolType.anthropic:
        return _extractAnthropicContent(responseData);
      case AIProtocolType.gemini:
        return _extractGeminiContent(responseData);
    }
  }

  String _systemPrompt(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty ||
        messages.first['role'] != 'system' ||
        messages.first['content'] is! String) {
      return '';
    }
    return messages.first['content'] as String;
  }

  String _extractOpenAIContent(dynamic responseData) {
    if (responseData is! Map) return '';
    final choices = responseData['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final first = choices.first;
    if (first is! Map) return '';
    final message = first['message'];
    if (message is! Map) return '';
    final content = message['content'];
    if (content is String) return content;
    if (content is! List) return '';
    final buffer = StringBuffer();
    for (final part in content) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      } else if (part is String) {
        buffer.write(part);
      }
    }
    return buffer.toString();
  }

  String _extractAnthropicContent(dynamic responseData) {
    if (responseData is! Map) return '';
    final content = responseData['content'];
    if (content is! List || content.isEmpty) return '';
    final buffer = StringBuffer();
    for (final part in content) {
      if (part is Map && part['type'] == 'text' && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }

  String _extractGeminiContent(dynamic responseData) {
    if (responseData is! Map) return '';
    final candidates = responseData['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final first = candidates.first;
    if (first is! Map) return '';
    final content = first['content'];
    if (content is! Map) return '';
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return '';
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }
    return buffer.toString();
  }
}
