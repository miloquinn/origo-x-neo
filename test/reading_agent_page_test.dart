import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/ai/ai_page.dart';
import 'package:xxread/pages/ai/reading_agent_panel.dart';
import 'package:xxread/pages/book_sources/models/sourced_book.dart';
import 'package:xxread/pages/home/home_shell_page.dart';
import 'package:xxread/pages/home/widgets/home_page_wrappers.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/services/ai/reading_agent_data_source.dart';
import 'package:xxread/services/ai/reading_agent_memory_store.dart';
import 'package:xxread/widgets/glass_surface.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets(
    'disabled agent keeps old chat path and never starts automatically',
    (tester) async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(_app(fixture.page()));
      await tester.pumpAndSettle();

      expect(fixture.ai.chatCalls, 0);
      expect(fixture.ai.agentCalls, 0);
      await tester.enterText(
        find.byKey(const ValueKey('ai-page-input')),
        '普通聊天',
      );
      await tester.tap(find.byKey(const ValueKey('ai-page-send')));
      await tester.pumpAndSettle();

      expect(fixture.ai.chatCalls, 1);
      expect(fixture.ai.agentCalls, 0);
      expect(find.text('旧聊天回答'), findsOneWidget);
    },
  );

  testWidgets(
    'explicit enablement shows genuine recommendation and saves consented memory',
    (tester) async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      fixture.ai.agentScript = (tools) async {
        await tools('search_books', {'query': '历史悬疑'});
        await tools('present_recommendations', {
          'items': [
            {'candidateId': 'c1', 'reason': '来自启用书源的真实候选'},
          ],
        });
        await tools('suggest_preference', {'text': '喜欢历史悬疑'});
        return '我找到了一本书。';
      };
      await tester.pumpWidget(_app(fixture.page()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ai-page-agent-setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reading-agent-enabled')));
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byType(ReadingAgentSettingsSheet)),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ai-page-agent-recommend')));
      await tester.pumpAndSettle();

      expect(fixture.ai.agentCalls, 1);
      expect(find.text('长安十二时辰'), findsOneWidget);
      expect(find.text('来自启用书源的真实候选'), findsOneWidget);
      expect(find.text('喜欢历史悬疑'), findsOneWidget);
      expect(fixture.memory.memories, isEmpty);

      await tester.tap(find.widgetWithText(TextButton, '保存'));
      await tester.pumpAndSettle();
      expect(fixture.memory.memories.single.text, '喜欢历史悬疑');

      await tester.tap(find.byTooltip('不感兴趣'));
      await tester.pumpAndSettle();
      expect(fixture.memory.feedback.single, {
        'title': '长安十二时辰',
        'author': '马伯庸',
        'value': 'not_interested',
      });
      final feedback = find.text('已记录推荐反馈');
      expect(feedback, findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      final toast = find.ancestor(
        of: feedback,
        matching: find.byType(GlassSurface),
      );
      expect(toast, findsOneWidget);
      expect(
        tester.getRect(toast).bottom,
        lessThan(
          tester.getRect(find.byKey(const ValueKey('ai-page-input'))).top,
        ),
      );
    },
  );

  testWidgets('manual follow-up receives safe ordered recommendation context', (
    tester,
  ) async {
    final fixture = await _Fixture.create(
      permissions: const ReadingAgentPermissions(enabled: true),
    );
    addTearDown(fixture.dispose);
    fixture.ai.agentScript = (tools) async {
      if (fixture.ai.agentCalls == 1) {
        await tools('search_books', {'query': '历史悬疑'});
        await tools('present_recommendations', {
          'items': [
            {'candidateId': 'c1', 'reason': '第一本原因'},
            {'candidateId': 'c2', 'reason': '第二本原因'},
          ],
        });
        return '先推荐这两本。';
      }
      return '第二本更偏推理。';
    };
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-page-agent-recommend')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ai-page-input')),
      '第二本呢？',
    );
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pumpAndSettle();

    final context = fixture.ai.agentHistories[1]
        .map((message) => message.content)
        .join('\n');
    expect(context, contains('长安十二时辰'));
    expect(context, contains('显微镜下的大明'));
    expect(context.indexOf('长安十二时辰'), lessThan(context.indexOf('显微镜下的大明')));
    expect(context, contains('第二本呢？'));
    expect(context, isNot(contains('private.example')));
    expect(context, isNot(contains('secret-token')));
    expect(find.text('先推荐这两本。'), findsOneWidget);
    expect(find.text('第二本更偏推理。'), findsOneWidget);
    expect(find.textContaining('[{"number"'), findsNothing);
  });

  testWidgets(
    'restored session follow-up retains safe recommendation context',
    (tester) async {
      final fixture = await _Fixture.create(
        permissions: const ReadingAgentPermissions(enabled: true),
      );
      addTearDown(fixture.dispose);
      fixture.ai.agentScript = (tools) async {
        if (fixture.ai.agentCalls == 1) {
          await tools('search_books', {'query': '历史悬疑'});
          await tools('present_recommendations', {
            'items': [
              {'candidateId': 'c1', 'reason': '第一本原因'},
              {'candidateId': 'c2', 'reason': '第二本原因'},
            ],
          });
          return '先推荐这两本。';
        }
        return '恢复后仍知道第二本。';
      };
      final firstController = AiPageController();
      await tester.pumpWidget(_app(fixture.page(controller: firstController)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ai-page-agent-recommend')));
      await tester.pumpAndSettle();
      expect(fixture.history.sessions, hasLength(1));

      final restoredController = AiPageController();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(fixture.page(controller: restoredController)),
      );
      await tester.pumpAndSettle();
      restoredController.openHistory();
      await tester.pumpAndSettle();
      await tester.tap(find.text('根据我的阅读偏好，在启用书源中为我推荐下一本书。'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ai-page-input')),
        '第二本呢？',
      );
      await tester.tap(find.byKey(const ValueKey('ai-page-send')));
      await tester.pumpAndSettle();

      final context = fixture.ai.agentHistories.last
          .map((message) => message.content)
          .join('\n');
      expect(context, contains('长安十二时辰'));
      expect(context, contains('显微镜下的大明'));
      expect(context.indexOf('长安十二时辰'), lessThan(context.indexOf('显微镜下的大明')));
      expect(context, isNot(contains('private.example')));
      expect(context, isNot(contains('secret-token')));
    },
  );

  testWidgets('agent continues across home tab switch and persists result', (
    tester,
  ) async {
    final fixture = await _Fixture.create(
      permissions: const ReadingAgentPermissions(enabled: true),
    );
    addTearDown(fixture.dispose);
    final destination = ValueNotifier(HomeNavigationDestination.ai);
    addTearDown(destination.dispose);
    final pending = Completer<String>();
    fixture.ai.agentScript = (_) => pending.future;

    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<HomeNavigationDestination>(
          valueListenable: destination,
          builder: (_, active, child) =>
              HomeTabFocusScope(activeDestination: active, child: child!),
          child: fixture.page(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '继续完成');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();

    destination.value = HomeNavigationDestination.library;
    await tester.pump();
    pending.complete('切换页面后完成');
    await tester.pumpAndSettle();

    expect(find.text('切换页面后完成'), findsOneWidget);
    expect(fixture.history.sessions.single.messages.last.text, '切换页面后完成');
    expect(fixture.ai.lastAgentToken?.isCancelled, isFalse);
  });

  testWidgets('chat stop cancels token and stale completion cannot end retry', (
    tester,
  ) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final first = Completer<String>();
    final second = Completer<String>();
    fixture.ai.chatScript = (_, _, call) =>
        call == 1 ? first.future : second.future;
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '第一问');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();
    var send = tester.widget<IconButton>(
      find.byKey(const ValueKey('ai-page-send')),
    );
    expect(send.onPressed, isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ai-page-send')),
        matching: find.byIcon(Icons.stop_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();
    expect(fixture.ai.chatTokens.single.isCancelled, isTrue);

    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '第二问');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();
    first.complete('迟到的第一问结果');
    await tester.pump();

    expect(find.text('迟到的第一问结果'), findsNothing);
    send = tester.widget<IconButton>(
      find.byKey(const ValueKey('ai-page-send')),
    );
    expect(send.onPressed, isNotNull);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    second.complete('第二问完成');
    await tester.pumpAndSettle();
    expect(find.text('第二问完成'), findsOneWidget);
    expect(find.text('迟到的第一问结果'), findsNothing);
  });

  testWidgets('agent stop cancels tool data and allows next request', (
    tester,
  ) async {
    final fixture = await _Fixture.create(
      permissions: const ReadingAgentPermissions(enabled: true),
    );
    addTearDown(fixture.dispose);
    fixture.data.blockOverview();
    fixture.ai.agentScript = (tools) async {
      if (fixture.ai.agentCalls == 1) {
        await tools('reading_overview', const {});
        return '迟到 Agent';
      }
      return '下一轮 Agent 完成';
    };
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '查统计');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await fixture.data.overviewStarted;
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();

    expect(fixture.ai.lastAgentToken?.isCancelled, isTrue);
    expect(fixture.data.cancelCount, greaterThan(0));
    fixture.data.releaseOverview();
    await tester.pump();
    expect(find.text('迟到 Agent'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '重新查询');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pumpAndSettle();
    expect(find.text('下一轮 Agent 完成'), findsOneWidget);
  });

  testWidgets('immediate stop before memory load prevents agent startup', (
    tester,
  ) async {
    final history = AiChatHistoryStore();
    final memory = _DelayedMemoryStore();
    final ai = _FakeAI();
    final data = _PageDataSource();
    addTearDown(() {
      history.dispose();
      memory.dispose();
      data.dispose();
    });
    await tester.pumpWidget(
      _app(
        AiPage(
          historyStore: history,
          aiService: ai,
          agentMemoryStore: memory,
          agentDataSource: data,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '立刻停止');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    memory.release();
    await tester.pumpAndSettle();

    expect(ai.agentCalls, 0);
    expect(data.beginCount, 0);
    expect(find.text('Agent 回答'), findsNothing);
  });

  testWidgets('chat continues while another route is pushed and popped', (
    tester,
  ) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final pending = Completer<String>();
    fixture.ai.chatScript = (_, _, call) => pending.future;
    await tester.pumpWidget(_app(fixture.page()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ai-page-input')), '后台继续');
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();

    final pageContext = tester.element(find.byType(AiPage));
    unawaited(
      Navigator.of(pageContext).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('其它页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('其它页面'), findsOneWidget);
    pending.complete('路由覆盖期间完成');
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('其它页面'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('路由覆盖期间完成'), findsOneWidget);
    expect(fixture.history.sessions.single.messages.last.text, '路由覆盖期间完成');
    expect(fixture.ai.chatTokens.single.isCancelled, isFalse);
  });

  testWidgets('new chat cancels old request and rejects its late result', (
    tester,
  ) async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final controller = AiPageController();
    final first = Completer<String>();
    final second = Completer<String>();
    fixture.ai.chatScript = (_, _, call) =>
        call == 1 ? first.future : second.future;
    await tester.pumpWidget(_app(fixture.page(controller: controller)));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ai-page-input')),
      '旧会话问题',
    );
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();

    controller.startNewChat();
    await tester.pump();
    expect(fixture.ai.chatTokens.single.isCancelled, isTrue);
    first.complete('旧会话迟到结果');
    await tester.pump();
    expect(find.text('旧会话问题'), findsNothing);
    expect(find.text('旧会话迟到结果'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('ai-page-input')),
      '新会话问题',
    );
    await tester.tap(find.byKey(const ValueKey('ai-page-send')));
    await tester.pump();
    second.complete('新会话回答');
    await tester.pumpAndSettle();
    expect(find.text('新会话回答'), findsOneWidget);
    expect(find.text('旧会话迟到结果'), findsNothing);
  });

  testWidgets('hidden AI tab does not trigger opted-in proactive request', (
    tester,
  ) async {
    final fixture = await _Fixture.create(
      permissions: const ReadingAgentPermissions(
        enabled: true,
        proactive: true,
      ),
    );
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      _app(
        HomeTabFocusScope(
          activeDestination: HomeNavigationDestination.library,
          child: fixture.page(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fixture.ai.agentCalls, 0);
    expect(fixture.data.beginCount, 0);
  });

  testWidgets('narrow large-text welcome and settings have no overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);

    await tester.pumpWidget(
      _app(
        fixture.page(),
        mediaQuery: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(1.8),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-page-agent-setup')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('ai-page-agent-setup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-agent-enabled')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home, {MediaQueryData? mediaQuery}) {
  final app = MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: NavigationContext(useRailNavigation: true, child: home),
    ),
  );
  return mediaQuery == null ? app : MediaQuery(data: mediaQuery, child: app);
}

typedef _ToolInvoker =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> arguments,
    );

typedef _ChatScript =
    Future<String> Function(
      List<AIChatMessage> history,
      CancelToken token,
      int call,
    );

class _FakeAI implements ConfigurableAIService, AgentAIService {
  Future<String> Function(_ToolInvoker tools)? agentScript;
  _ChatScript? chatScript;
  int chatCalls = 0;
  int agentCalls = 0;
  final List<List<AIChatMessage>> agentHistories = [];
  final List<CancelToken> chatTokens = [];
  CancelToken? lastAgentToken;

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async =>
      AIProviderSettings.defaults(
        AIProviderType.openai,
      ).copyWith(apiKey: 'test-key');

  @override
  Future<void> saveSettings(AIProviderSettings settings) async {}

  @override
  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  }) async {
    chatCalls++;
    final token = cancelToken ?? CancelToken();
    chatTokens.add(token);
    final script = chatScript;
    if (script != null) return script(history, token, chatCalls);
    return '旧聊天回答';
  }

  @override
  Future<String> chatWithTools({
    required List<AIChatMessage> history,
    required String systemPrompt,
    required List<AIToolDefinition> tools,
    required Future<Map<String, dynamic>> Function(AIToolCall) onToolCall,
    CancelToken? cancelToken,
    int maxToolRounds = 6,
  }) async {
    agentCalls++;
    lastAgentToken = cancelToken;
    agentHistories.add(List<AIChatMessage>.of(history));
    final script = agentScript;
    if (script == null) return 'Agent 回答';
    return script(
      (name, arguments) => onToolCall(
        AIToolCall(id: 'call-$name', name: name, arguments: arguments),
      ),
    );
  }

  @override
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  }) async => 'unused';

  @override
  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  }) async => 'unused';
}

class _Fixture {
  _Fixture(this.history, this.memory, this.ai, this.data);

  final AiChatHistoryStore history;
  final ReadingAgentMemoryStore memory;
  final _FakeAI ai;
  final _PageDataSource data;

  static Future<_Fixture> create({ReadingAgentPermissions? permissions}) async {
    final memory = ReadingAgentMemoryStore();
    if (permissions != null) await memory.setPermissions(permissions);
    return _Fixture(AiChatHistoryStore(), memory, _FakeAI(), _PageDataSource());
  }

  AiPage page({AiPageController? controller}) => AiPage(
    historyStore: history,
    controller: controller,
    aiService: ai,
    agentMemoryStore: memory,
    agentDataSource: data,
  );

  void dispose() {
    history.dispose();
    memory.dispose();
    data.dispose();
  }
}

class _PageDataSource implements ReadingAgentDataSource {
  final Map<String, SourcedBook> _candidates = {};
  int beginCount = 0;
  int cancelCount = 0;
  Completer<Map<String, dynamic>>? _overview;
  Completer<void>? _overviewStarted;

  Future<void> get overviewStarted =>
      _overviewStarted?.future ?? Future.value();

  void blockOverview() {
    _overview = Completer<Map<String, dynamic>>();
    _overviewStarted = Completer<void>();
  }

  void releaseOverview() {
    final overview = _overview;
    if (overview != null && !overview.isCompleted) {
      overview.complete(const {});
    }
  }

  @override
  void beginRequest() {
    beginCount++;
    _candidates.clear();
  }

  @override
  Future<Map<String, dynamic>> searchBooks({
    required String query,
    List<String> sourceIds = const [],
    int page = 1,
    int limit = 12,
  }) async {
    _candidates['c1'] = _candidate;
    _candidates['c2'] = _secondCandidate;
    return {
      'items': [
        {'candidateId': 'c1', 'title': _candidate.book.title},
        {'candidateId': 'c2', 'title': _secondCandidate.book.title},
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
  }) async => _candidate;

  @override
  Future<Map<String, dynamic>> listBooks({
    int offset = 0,
    int limit = 20,
  }) async => {'items': <Object>[]};

  @override
  Future<Map<String, dynamic>> listSources({
    int offset = 0,
    int limit = 20,
  }) async => {'items': <Object>[]};

  @override
  Future<Map<String, dynamic>> readingOverview() async {
    final started = _overviewStarted;
    if (started != null && !started.isCompleted) started.complete();
    return _overview?.future ?? const {};
  }

  @override
  Future<Map<String, dynamic>> readingSessions({
    int offset = 0,
    int limit = 20,
  }) async => {'items': <Object>[]};

  @override
  Future<Map<String, dynamic>> readingStatistics({
    int days = 30,
    int offset = 0,
    int limit = 20,
  }) async => {'items': <Object>[]};

  @override
  void cancel() => cancelCount++;

  @override
  void dispose() {}
}

class _DelayedMemoryStore extends ReadingAgentMemoryStore {
  final Completer<void> _loaded = Completer<void>();

  @override
  ReadingAgentPermissions get permissions =>
      const ReadingAgentPermissions(enabled: true);

  @override
  Future<void> ensureLoaded() => _loaded.future;

  void release() {
    if (!_loaded.isCompleted) _loaded.complete();
  }
}

final _candidate = SourcedBook(
  source: RegisteredBookSource(
    id: 'https://private.example/source?id=secret-token',
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

final _secondCandidate = _candidate.copyWith(
  book: const BookSourceBook(
    id: 'book-2',
    title: '显微镜下的大明',
    author: '马伯庸',
    description: '历史纪实',
    categories: ['历史'],
  ),
);
