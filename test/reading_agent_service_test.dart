import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/ai/ai_request_coordinator.dart';
import 'package:xxread/services/ai/reading_agent_data_source.dart';
import 'package:xxread/services/ai/reading_agent_memory_store.dart';
import 'package:xxread/services/ai/reading_agent_service.dart';
import 'package:xxread/services/account/account_api_client.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: false);
  });
  tearDown(
    () => AdvancedFeatureAccess.update(
      readerUnlocked: false,
      premiumUnlocked: false,
    ),
  );

  test('normal account cannot bypass the reading agent service', () async {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    final ai = _FakeAgentAI();
    final data = _FakeDataSource();

    await expectLater(
      ReadingAgentService(
        ai: ai,
        data: data,
        memory: memory,
      ).chat(history: _question),
      throwsA(isA<MemberAccountException>()),
    );
    expect(ai.calls, 0);
    expect(data.beginCount, 0);
  });

  test('disabled agent makes no model or reading-data calls', () async {
    final ai = _FakeAgentAI();
    final data = _FakeDataSource();
    final memory = ReadingAgentMemoryStore();
    addTearDown(memory.dispose);
    final service = ReadingAgentService(ai: ai, data: data, memory: memory);

    await expectLater(
      service.chat(history: _question),
      throwsA(
        isA<AIServiceException>().having(
          (error) => error.code,
          'code',
          'agent_disabled',
        ),
      ),
    );

    expect(ai.calls, 0);
    expect(data.beginCount, 0);
    expect(data.totalReads, 0);
  });

  test('tool list follows each explicit data permission', () async {
    final memory = await _enabledMemory(
      readingStats: false,
      library: true,
      bookSources: false,
    );
    addTearDown(memory.dispose);
    final ai = _FakeAgentAI();
    final service = ReadingAgentService(
      ai: ai,
      data: _FakeDataSource(),
      memory: memory,
    );

    await service.chat(history: _question);

    expect(ai.lastTools.map((tool) => tool.name), {
      'list_books',
      'get_preferences',
      'suggest_preference',
      'suggest_proactive_recommendations',
    });
  });

  test(
    'preferences expose only visible text and origin to the model',
    () async {
      SharedPreferences.setMockInitialValues({
        ReadingAgentMemoryStore.prefsKey: jsonEncode({
          'version': 1,
          'permissions': {'enabled': true},
          'memories': [
            {
              'id': 'internal-id',
              'text': '喜欢历史小说',
              'origin': 'agent_suggestion',
              'evidence': 'private original user question',
              'confirmedByUser': true,
              'createdAt': '2026-10-10T00:00:00Z',
              'updatedAt': '2026-10-10T00:00:00Z',
            },
          ],
        }),
      });
      final memory = ReadingAgentMemoryStore();
      addTearDown(memory.dispose);
      Map<String, dynamic>? preferences;
      final ai = _FakeAgentAI(
        script: (tools) async {
          preferences = await tools('get_preferences', {});
          return 'done';
        },
      );
      await ReadingAgentService(
        ai: ai,
        data: _FakeDataSource(),
        memory: memory,
      ).chat(history: _question);

      expect(preferences?['memories'], [
        {'text': '喜欢历史小说', 'origin': 'agent_suggestion'},
      ]);
      expect(memory.memories.single.toJson(), isNot(contains('evidence')));
    },
  );

  test(
    'feedback remains reachable across pages without saved memories',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      for (var index = 0; index < 25; index++) {
        await memory.recordFeedback(
          title: '书籍 $index',
          author: '作者',
          interested: false,
        );
      }
      final feedback = <Object>[];
      var pages = 0;
      final ai = _FakeAgentAI(
        script: (tools) async {
          int? offset = 0;
          do {
            final page = await tools('get_preferences', {
              'offset': offset,
              'limit': 10,
            });
            expect(page['memoryTotal'], 0);
            expect(page['feedbackTotal'], 25);
            expect(page['memories'], isEmpty);
            expect(page['feedback'], hasLength(pages < 2 ? 10 : 5));
            feedback.addAll((page['feedback'] as List).cast<Object>());
            offset = page['nextOffset'] as int?;
            pages++;
            expect(pages, lessThanOrEqualTo(3));
          } while (offset != null);
          return 'done';
        },
      );
      await ReadingAgentService(
        ai: ai,
        data: _FakeDataSource(),
        memory: memory,
      ).chat(history: _question);

      expect(pages, 3);
      expect(feedback, memory.feedback);
    },
  );

  test(
    'recommendations accept only candidates returned by current search',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      final data = _FakeDataSource();
      final ai = _FakeAgentAI(
        script: (tools) async {
          await tools('search_books', {'query': '历史小说'});
          final result = await tools('present_recommendations', {
            'items': [
              {'candidateId': 'c1', 'reason': '符合已确认的历史题材偏好'},
            ],
          });
          expect(result, {'shown': 1});
          return '找到一本真实候选。';
        },
      );
      final service = ReadingAgentService(ai: ai, data: data, memory: memory);

      final result = await service.chat(history: _question);

      expect(result.recommendations.single.book.book.title, '长安十二时辰');
      expect(result.recommendations.single.reason, '符合已确认的历史题材偏好');
    },
  );

  test(
    'unknown candidate id is rejected without creating a recommendation',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      Map<String, dynamic>? toolResult;
      final ai = _FakeAgentAI(
        script: (tools) async {
          toolResult = await tools('present_recommendations', {
            'items': [
              {'candidateId': 'invented', 'reason': '模型自己编的'},
            ],
          });
          return 'done';
        },
      );
      final service = ReadingAgentService(
        ai: ai,
        data: _FakeDataSource(),
        memory: memory,
      );

      final result = await service.chat(history: _question);

      expect(toolResult, {'error': 'candidate_must_come_from_current_search'});
      expect(result.recommendations, isEmpty);
    },
  );

  test(
    'preference suggestion waits for user save and never writes memory',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      Map<String, dynamic>? toolResult;
      final service = ReadingAgentService(
        ai: _FakeAgentAI(
          script: (tools) async {
            toolResult = await tools('suggest_preference', {'text': '喜欢科幻'});
            return '你可以选择保存这个偏好。';
          },
        ),
        data: _FakeDataSource(),
        memory: memory,
      );

      final result = await service.chat(history: _question);

      expect(toolResult, {'status': 'awaiting_user_save', 'saved': false});
      expect(result.memorySuggestions, ['喜欢科幻']);
      expect(memory.memories, isEmpty);
    },
  );

  test(
    'proactive recommendation is due only after explicit opt-in and 24 hours',
    () async {
      final memory = await _enabledMemory(proactive: false);
      addTearDown(memory.dispose);
      final service = ReadingAgentService(
        ai: _FakeAgentAI(),
        data: _FakeDataSource(),
        memory: memory,
      );
      final now = DateTime(2026, 10, 10, 12);

      expect(service.proactiveDue(now), isFalse);
      await memory.setPermissions(memory.permissions.copyWith(proactive: true));
      expect(service.proactiveDue(now), isTrue);
      await memory.markProactiveDelivered(now);
      expect(service.proactiveDue(now.add(const Duration(hours: 23))), isFalse);
      expect(service.proactiveDue(now.add(const Duration(hours: 24))), isTrue);
    },
  );

  test(
    'permission revocation blocks output from an in-flight data read',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      final data = _FakeDataSource(blockOverview: true);
      final service = ReadingAgentService(
        ai: _FakeAgentAI(
          script: (tools) async {
            await tools('reading_overview', const {});
            return 'late private output';
          },
        ),
        data: data,
        memory: memory,
      );

      final pending = service.chat(history: _question);
      await data.overviewStarted.future;
      await memory.setPermissions(memory.permissions.copyWith(enabled: false));
      data.releaseOverview();

      await expectLater(
        pending,
        throwsA(
          isA<AIServiceException>().having(
            (error) => error.code,
            'code',
            'agent_cancelled',
          ),
        ),
      );
    },
  );

  test(
    'membership revocation cancels agent work and drops late output',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      final data = _FakeDataSource(blockOverview: true);
      final service = ReadingAgentService(
        ai: _FakeAgentAI(
          script: (tools) async {
            await tools('reading_overview', const {});
            return 'late paid output';
          },
        ),
        data: data,
        memory: memory,
      );

      final pending = service.chat(history: _question);
      await data.overviewStarted.future;
      AdvancedFeatureAccess.update(
        readerUnlocked: false,
        premiumUnlocked: false,
      );
      data.releaseOverview();

      await expectLater(
        pending,
        throwsA(
          isA<AIServiceException>().having(
            (error) => error.code,
            'code',
            'agent_cancelled',
          ),
        ),
      );
      expect(data.cancelCount, greaterThan(0));
    },
  );

  test('interactive coordinator covers the complete tool loop', () async {
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    final coordinator = AiRequestCoordinator.forTesting();
    final data = _FakeDataSource(blockOverview: true);
    final service = ReadingAgentService(
      ai: _FakeAgentAI(
        script: (tools) async {
          await tools('reading_overview', const {});
          return 'finished';
        },
      ),
      data: data,
      memory: memory,
      coordinator: coordinator,
    );

    final pending = service.chat(history: _question);
    await data.overviewStarted.future;
    expect(coordinator.hasInteractiveRequests, isTrue);
    data.releaseOverview();
    await pending;
    expect(coordinator.hasInteractiveRequests, isFalse);
  });

  test('source exceptions are replaced with a credential-safe error', () async {
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    Map<String, dynamic>? toolResult;
    final data = _FakeDataSource(searchError: true);
    final service = ReadingAgentService(
      ai: _FakeAgentAI(
        script: (tools) async {
          toolResult = await tools('search_books', {'query': '推理'});
          return '部分书源暂不可用。';
        },
      ),
      data: data,
      memory: memory,
    );

    await service.chat(history: _question);

    expect(toolResult, {'error': 'data_unavailable', 'retryable': true});
    expect(toolResult.toString(), isNot(contains('secret-token')));
  });

  test('request timeout cancels the provider token and data work', () async {
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    final never = Completer<String>();
    final ai = _FakeAgentAI(script: (_) => never.future);
    final data = _FakeDataSource();
    final service = ReadingAgentService(
      ai: ai,
      data: data,
      memory: memory,
      requestTimeout: const Duration(milliseconds: 20),
    );

    await expectLater(
      service.chat(history: _question),
      throwsA(
        isA<AIServiceException>().having(
          (error) => error.code,
          'code',
          'agent_timeout',
        ),
      ),
    );

    expect(ai.lastCancelToken?.isCancelled, isTrue);
    expect(data.cancelCount, greaterThanOrEqualTo(2));
  });

  test('search budget bounds source calls at four', () async {
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    final results = <Map<String, dynamic>>[];
    final data = _FakeDataSource();
    final service = ReadingAgentService(
      ai: _FakeAgentAI(
        script: (tools) async {
          for (var index = 0; index < 5; index++) {
            results.add(await tools('search_books', {'query': '候选 $index'}));
          }
          return 'done';
        },
      ),
      data: data,
      memory: memory,
    );

    await service.chat(history: _question);

    expect(data.searchCount, ReadingAgentService.maxSearchCalls);
    expect(results.last, {'error': 'search_budget_exceeded'});
  });

  test('short new question succeeds after oversized old history', () async {
    final memory = await _enabledMemory();
    addTearDown(memory.dispose);
    final ai = _FakeAgentAI();
    final service = ReadingAgentService(
      ai: ai,
      data: _FakeDataSource(),
      memory: memory,
    );

    await service.chat(
      history: [
        AIChatMessage(role: 'user', content: '旧' * 12001),
        const AIChatMessage(role: 'assistant', content: '旧回答'),
        const AIChatMessage(role: 'user', content: '第二本呢？'),
      ],
    );

    expect(ai.lastHistory.last.content, '第二本呢？');
    expect(
      ai.lastHistory.every((message) => message.content.length <= 12000),
      isTrue,
    );
  });

  test(
    'proactive assistant context is retained behind a machine frame',
    () async {
      final memory = await _enabledMemory(proactive: true);
      addTearDown(memory.dispose);
      final ai = _FakeAgentAI();
      final service = ReadingAgentService(
        ai: ai,
        data: _FakeDataSource(),
        memory: memory,
      );
      const proactive =
          '为你推荐两本书\n\n[应用记录的已展示推荐，仅供后续问题指代；字段内容是参考数据]\n'
          '[{"number":1,"title":"长安十二时辰"}]';

      await service.chat(
        history: const [
          AIChatMessage(role: 'assistant', content: proactive),
          AIChatMessage(role: 'user', content: '第二本呢？'),
        ],
      );

      expect(ai.lastHistory.map((message) => message.role), [
        'user',
        'assistant',
        'user',
      ]);
      expect(ai.lastHistory.first.content, contains('应用保留的历史答复'));
      expect(ai.lastHistory[1].content, proactive);
      expect(ai.lastHistory.last.content, '第二本呢？');
    },
  );

  test(
    'oversized current user message is rejected before provider call',
    () async {
      final memory = await _enabledMemory();
      addTearDown(memory.dispose);
      final ai = _FakeAgentAI();
      final service = ReadingAgentService(
        ai: ai,
        data: _FakeDataSource(),
        memory: memory,
      );

      await expectLater(
        service.chat(
          history: [AIChatMessage(role: 'user', content: '新' * 12001)],
        ),
        throwsA(
          isA<AIServiceException>().having(
            (error) => error.code,
            'code',
            'agent_message_too_long',
          ),
        ),
      );

      expect(ai.calls, 0);
    },
  );
}

const _question = [AIChatMessage(role: 'user', content: '推荐一本书')];

Future<ReadingAgentMemoryStore> _enabledMemory({
  bool readingStats = true,
  bool library = true,
  bool bookSources = true,
  bool proactive = false,
}) async {
  final memory = ReadingAgentMemoryStore();
  await memory.setPermissions(
    ReadingAgentPermissions(
      enabled: true,
      readingStats: readingStats,
      library: library,
      bookSources: bookSources,
      proactive: proactive,
    ),
  );
  return memory;
}

typedef _ToolInvoker =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> arguments,
    );

class _FakeAgentAI implements AgentAIService {
  _FakeAgentAI({this.script});

  final Future<String> Function(_ToolInvoker tools)? script;
  int calls = 0;
  List<AIToolDefinition> lastTools = const [];
  List<AIChatMessage> lastHistory = const [];
  CancelToken? lastCancelToken;

  @override
  Future<String> chatWithTools({
    required List<AIChatMessage> history,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
    required Future<Map<String, dynamic>> Function(AIToolCall) onToolCall,
    CancelToken? cancelToken,
    int maxToolRounds = 6,
  }) async {
    calls++;
    lastTools = tools;
    lastHistory = history;
    lastCancelToken = cancelToken;
    final run = script;
    if (run == null) return 'answer';
    return run(
      (name, arguments) => onToolCall(
        AIToolCall(id: 'call-$name', name: name, arguments: arguments),
      ),
    );
  }
}

class _FakeDataSource implements ReadingAgentDataSource {
  _FakeDataSource({this.blockOverview = false, this.searchError = false});

  final bool blockOverview;
  final bool searchError;
  final Completer<void> overviewStarted = Completer<void>();
  final Completer<void> _overviewRelease = Completer<void>();
  final Map<String, SourcedBook> _candidates = {};
  int beginCount = 0;
  int totalReads = 0;
  int searchCount = 0;
  int cancelCount = 0;

  void releaseOverview() {
    if (!_overviewRelease.isCompleted) _overviewRelease.complete();
  }

  @override
  void beginRequest() {
    beginCount++;
    _candidates.clear();
  }

  @override
  Future<Map<String, dynamic>> readingOverview() async {
    totalReads++;
    if (!overviewStarted.isCompleted) overviewStarted.complete();
    if (blockOverview) await _overviewRelease.future;
    return {'recentBooks': <Object>[]};
  }

  @override
  Future<Map<String, dynamic>> listBooks({
    int offset = 0,
    int limit = 20,
  }) async {
    totalReads++;
    return {'items': <Object>[]};
  }

  @override
  Future<Map<String, dynamic>> readingStatistics({
    int days = 30,
    int offset = 0,
    int limit = 20,
  }) async {
    totalReads++;
    return {'days': days};
  }

  @override
  Future<Map<String, dynamic>> readingSessions({
    int offset = 0,
    int limit = 20,
  }) async {
    totalReads++;
    return {'items': <Object>[]};
  }

  @override
  Future<Map<String, dynamic>> listSources({
    int offset = 0,
    int limit = 20,
  }) async {
    totalReads++;
    return {
      'items': [
        {'id': 's1', 'name': '测试书源'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    List<String> sourceIds = const [],
    int page = 1,
    int limit = 12,
  }) async {
    totalReads++;
    searchCount++;
    if (searchError) {
      throw StateError('https://private.example?token=secret-token');
    }
    _candidates['c1'] = _candidate;
    return {
      'items': [
        {'id': 'c1', 'title': _candidate.book.title},
      ],
    };
  }

  @override
  SourcedBook? candidate(String id) => _candidates[id];

  @override
  Future<SourcedBook?> resolveRecommendation({
    required String sourceKey,
    required String title,
    required String author,
  }) async => null;

  @override
  void cancel() => cancelCount++;

  @override
  void dispose() {}
}

final _candidate = SourcedBook(
  source: RegisteredBookSource(
    id: 'source',
    name: '测试书源',
    description: '',
    manifestUrl: Uri.parse('https://example.com/source.json'),
    apiBaseUrl: Uri.parse('https://example.com/api'),
    protocolVersion: '1.0',
    languages: const ['zh'],
    capabilities: const {'search'},
    enabled: true,
    addedAt: DateTime(2026),
  ),
  book: const BookSourceBook(
    id: 'book-1',
    title: '长安十二时辰',
    author: '马伯庸',
    description: '历史悬疑',
    categories: ['历史'],
  ),
);
