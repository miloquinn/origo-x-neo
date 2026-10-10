// 文件说明：阅读 Agent 的稳定工具调用接口，与具体模型提供商协议解耦。
// 技术要点：JSON Schema、结构化工具调用、Dio 请求取消。

part of 'ai_service.dart';

class AIToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const AIToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

class AIToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> arguments;

  const AIToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

abstract interface class AgentAIService {
  Future<String> chatWithTools({
    required List<AIChatMessage> history,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
    required Future<Map<String, dynamic>> Function(AIToolCall) onToolCall,
    CancelToken? cancelToken,
    int maxToolRounds = 6,
  });
}
