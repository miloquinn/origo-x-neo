import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/reader_ai_panel.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/release_notes_markdown.dart';

class _FakeAiService implements ConfigurableAIService {
  _FakeAiService({required this.configured, this.answer = 'AI 的回答'});

  final bool configured;
  final String answer;
  List<AIChatMessage>? lastHistory;
  String? lastPageText;
  AIRequestMeta? lastMeta;

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async =>
      AIProviderSettings.defaults(
        AIProviderType.openai,
      ).copyWith(apiKey: configured ? 'test-key' : '');

  @override
  Future<void> saveSettings(AIProviderSettings settings) async {}

  @override
  Future<String> chat({
    required List<AIChatMessage> history,
    required String pageText,
    required AIRequestMeta meta,
    CancelToken? cancelToken,
  }) async {
    lastHistory = history;
    lastPageText = pageText;
    lastMeta = meta;
    return answer;
  }

  @override
  Future<String> askSelection({
    required String selectedText,
    required String contextBefore,
    required String contextAfter,
    required AIRequestMeta meta,
  }) async => answer;

  @override
  Future<String> analyzePage({
    required String pageText,
    required AIRequestMeta meta,
  }) async => answer;
}

Widget _wrapPanel(ReaderAiPanel panel) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: panel),
);

void main() {
  setUp(() {
    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: false);
  });
  tearDown(() {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
  });
  const meta = AIRequestMeta(bookId: '1', chapterId: 'chapter-1', pageIndex: 2);

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('multiline dark-reader input grows and sends in each material', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() {
      GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
      GlassEffectConfig.setDisableAllGlassEffects(false);
    });
    for (final mode in ['frosted', 'liquid', 'off']) {
      GlassEffectConfig.setGlassStyle(
        mode == 'liquid' ? GlassStyle.liquid : GlassStyle.frosted,
      );
      GlassEffectConfig.setDisableAllGlassEffects(mode == 'off');
      final service = _FakeAiService(
        configured: true,
        answer: List.filled(16, '这一段表达了人物面对抉择时的犹豫。').join('\n\n'),
      );
      final store = AiChatHistoryStore();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ReaderAiPanel(
              palette: ReaderThemes.night,
              meta: meta,
              pageText: '当前页正文',
              aiService: service,
              historyStore: store,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('reader-ai-input'));
      await tester.enterText(input, 'Hi');
      await tester.pumpAndSettle();
      final height = tester.getSize(input).height;
      const question = '请解释这一段。\n再说明作者的表达。';
      await tester.enterText(input, question);
      await tester.pumpAndSettle();
      expect(tester.getSize(input).height, greaterThan(height));
      expect(
        tester.widget<TextField>(input).style?.color,
        ReaderThemes.night.text,
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(service.lastHistory?.last.content, question);
      expect(tester.widget<TextField>(input).controller?.text, isEmpty);
      await tester.enterText(input, question);
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(ReleaseNotesMarkdown)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(PillInputSurface)).top),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      store.dispose();
    }
  });

  testWidgets('sends a typed question and renders the answer', (tester) async {
    final service = _FakeAiService(configured: true, answer: '这是模型的解释。');
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.pumpWidget(
      _wrapPanel(
        ReaderAiPanel(
          palette: ReaderThemes.green,
          meta: meta,
          pageText: '当前页正文',
          aiService: service,
          historyStore: historyStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reader-ai-input')),
      '这一段讲了什么？',
    );
    await tester.tap(find.byKey(const ValueKey('reader-ai-send')));
    await tester.pumpAndSettle();

    expect(find.text('这一段讲了什么？'), findsOneWidget);
    expect(find.text('这是模型的解释。'), findsOneWidget);
    expect(service.lastHistory, hasLength(1));
    expect(service.lastHistory!.single.role, 'user');
    expect(service.lastHistory!.single.content, '这一段讲了什么？');
    expect(service.lastPageText, '当前页正文');
    expect(service.lastMeta?.chapterId, 'chapter-1');
    expect(historyStore.sessions, hasLength(1));
    expect(historyStore.sessions.single.messages, hasLength(2));
    expect(historyStore.sessions.single.firstQuestion, '这一段讲了什么？');
    expect(historyStore.sessions.single.messages.first.content, '这一段讲了什么？');
  });

  testWidgets('shows the setup hint and disables sending when unconfigured', (
    tester,
  ) async {
    final service = _FakeAiService(configured: false);
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.pumpWidget(
      _wrapPanel(
        ReaderAiPanel(
          palette: ReaderThemes.green,
          meta: meta,
          pageText: '当前页正文',
          aiService: service,
          historyStore: historyStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('尚未配置 AI 模型'), findsOneWidget);
    final sendButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('reader-ai-send')),
    );
    expect(sendButton.onPressed, isNull);
    expect(service.lastHistory, isNull);
  });

  testWidgets('renders assistant answers as markdown', (tester) async {
    final service = _FakeAiService(
      configured: true,
      answer: '## 摘要\n\n- **要点**一\n- 要点二',
    );
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.pumpWidget(
      _wrapPanel(
        ReaderAiPanel(
          palette: ReaderThemes.green,
          meta: meta,
          pageText: '当前页正文',
          aiService: service,
          historyStore: historyStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('reader-ai-input')),
      '总结一下',
    );
    await tester.tap(find.byKey(const ValueKey('reader-ai-send')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('release-notes-markdown')),
      findsOneWidget,
    );
    expect(find.text('摘要'), findsOneWidget);
    expect(find.text('要点二'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('##'), findsNothing);
  });

  testWidgets('auto-asks about the seeded selection', (tester) async {
    final service = _FakeAiService(configured: true, answer: '选中内容的解释。');
    final historyStore = AiChatHistoryStore();
    addTearDown(historyStore.dispose);
    await tester.pumpWidget(
      _wrapPanel(
        ReaderAiPanel(
          palette: ReaderThemes.night,
          meta: meta,
          pageText: '上文 选中文字 下文',
          aiService: service,
          historyStore: historyStore,
          selection: const ReaderAiSelectionContext(
            selectedText: '选中文字',
            contextBefore: '上文',
            contextAfter: '下文',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('解释这段选中内容'), findsOneWidget);
    expect(find.text('选中内容的解释。'), findsOneWidget);
    expect(service.lastHistory, hasLength(1));
    expect(service.lastHistory!.single.content, contains('选中文字'));
    expect(service.lastHistory!.single.content, contains('上文'));
    expect(service.lastHistory!.single.content, contains('下文'));
    expect(historyStore.sessions, hasLength(1));
    final session = historyStore.sessions.single;
    expect(session.bookId, meta.bookId);
    expect(session.messages, hasLength(2));
    final savedQuestion = session.messages.first;
    expect(savedQuestion.text, contains('解释这段选中内容'));
    expect(savedQuestion.text, contains('选中文字'));
    expect(savedQuestion.content, contains('选中文字'));
    expect(savedQuestion.content, contains('上文'));
    expect(savedQuestion.content, contains('下文'));
  });
}
