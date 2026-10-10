// 文件说明：AI 导航页，进入即为对话界面；左上角入口打开历史记录。
// 技术要点：壳层内嵌聊天、选书注入知识库与笔记上下文、AiChatHistoryStore 落盘。

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/book_note.dart';
import 'package:xxread/pages/ai/ai_history_page.dart';
import 'package:xxread/pages/ai/reading_agent_panel.dart';
import 'package:xxread/pages/book_sources/widgets/sourced_book_actions.dart';
import 'package:xxread/pages/home/home_mobile_chrome.dart';
import 'package:xxread/pages/home/home_shell_page.dart';
import 'package:xxread/pages/home/widgets/home_page_wrappers.dart';
import 'package:xxread/reader_core/ai/ai_error_translator.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/services/ai/ai_request_coordinator.dart';
import 'package:xxread/services/ai/global_ai_reading_service.dart';
import 'package:xxread/services/ai/reading_agent_data_source.dart';
import 'package:xxread/services/ai/reading_agent_memory_store.dart';
import 'package:xxread/services/ai/reading_agent_service.dart';
import 'package:xxread/services/books/book_dao.dart';
import 'package:xxread/services/books/book_note_dao.dart';
import 'package:xxread/utils/layout_helper.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/utils/page_style_helper.dart';
import 'package:xxread/widgets/release_notes_markdown.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/measured_size.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';
import 'package:xxread/widgets/side_toast.dart';

class _AiChatEntry {
  _AiChatEntry({
    required this.role,
    required this.text,
    String? content,
    this.agentResult,
  }) : content = content ?? text,
       historyRecommendations = const [],
       at = DateTime.now();

  _AiChatEntry.restored({
    required this.role,
    required this.text,
    required this.content,
    required this.at,
    this.historyRecommendations = const [],
  }) : agentResult = null;

  final String role;
  final String text;
  final String content;
  final DateTime at;
  final ReadingAgentResult? agentResult;
  final List<AiChatBookRecommendation> historyRecommendations;
}

/// 壳层顶栏与 AI 页之间的轻量桥：顶栏右侧工具按钮驱动页面行为。
class AiPageController {
  _AiPageState? _state;

  void openHistory() {
    final state = _state;
    if (state != null) unawaited(state._openHistory());
  }

  void startNewChat() => _state?._startNewChat();
}

/// AI 页：悬浮导航直达的对话界面。
class AiPage extends StatefulWidget {
  const AiPage({
    super.key,
    required this.historyStore,
    this.controller,
    this.aiService,
    this.agentMemoryStore,
    this.agentDataSource,
  });

  final AiChatHistoryStore historyStore;
  final AiPageController? controller;
  final ConfigurableAIService? aiService;
  final ReadingAgentMemoryStore? agentMemoryStore;
  final ReadingAgentDataSource? agentDataSource;

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with WidgetsBindingObserver {
  late final ConfigurableAIService _ai =
      widget.aiService ?? ReaderHttpAIService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiChatHistoryStore _historyStore = widget.historyStore;
  final List<_AiChatEntry> _entries = [];
  late final ReadingAgentMemoryStore _agentMemory =
      widget.agentMemoryStore ?? ReadingAgentMemoryStore();
  ReadingAgentDataSource? _agentData;
  ReadingAgentService? _agent;
  BookSourceShelfService? _agentShelf;
  ReadingAgentPermissions _lastPermissions = const ReadingAgentPermissions();
  bool _agentLoaded = false;
  bool _agentTabActive = false;
  bool _checkingConfiguration = false;
  DateTime? _proactiveAttemptedAt;
  String? _activeTool;
  int _sendGeneration = 0;
  CancelToken? _sendCancelToken;

  bool _configured = false;
  bool _configChecked = false;
  bool _sending = false;
  String? _error;
  String? _sessionId;
  DateTime? _sessionCreatedAt;

  Book? _selectedBook;
  String _bookContext = '';
  bool _bookContextLoading = false;
  bool _lastKeyboardVisible = false;
  double _overlayHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    WidgetsBinding.instance.addObserver(this);
    _agentMemory.addListener(_agentChanged);
    unawaited(_loadAgentMemory());
    unawaited(_checkConfigured());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = HomeTabFocusScope.maybeActiveOf(context);
    final wasActive = _agentTabActive;
    _agentTabActive = active == null || active == HomeNavigationDestination.ai;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_agentTabActive && !wasActive) {
        unawaited(_checkConfigured());
      } else {
        _maybeProactive();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkConfigured());
    }
  }

  Future<void> _loadAgentMemory() async {
    try {
      await _agentMemory.ensureLoaded();
      if (!mounted) return;
      setState(() => _agentLoaded = true);
      _maybeProactive();
    } catch (_) {}
  }

  void _agentChanged() {
    final permissions = _agentMemory.permissions;
    if (!mapEquals(_lastPermissions.toJson(), permissions.toJson())) {
      _agent?.cancel();
      _lastPermissions = permissions;
    }
    if (mounted) setState(() {});
  }

  ReadingAgentService? _ensureAgent() {
    final ai = _ai;
    if (ai is! AgentAIService) return null;
    if (_agent != null) return _agent;
    final data = _agentData ??=
        widget.agentDataSource ?? LocalReadingAgentDataSource();
    return _agent = ReadingAgentService(
      ai: ai as AgentAIService,
      data: data,
      memory: _agentMemory,
    );
  }

  Future<void> _openAgentSettings() async {
    await _agentMemory.ensureLoaded();
    if (!mounted) return;
    await showGlassBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ReadingAgentSettingsSheet(store: _agentMemory),
    );
    if (mounted) _maybeProactive();
  }

  void _maybeProactive() {
    if (!mounted ||
        !_agentLoaded ||
        !_configured ||
        !_agentTabActive ||
        _sending ||
        _entries.isNotEmpty ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed) ||
        (_proactiveAttemptedAt != null &&
            DateTime.now().difference(_proactiveAttemptedAt!) <
                const Duration(minutes: 30))) {
      return;
    }
    if (!_agentMemory.permissions.proactive ||
        !_agentMemory.permissions.enabled) {
      return;
    }
    final agent = _ensureAgent();
    if (agent == null || !agent.proactiveDue(DateTime.now())) return;
    _proactiveAttemptedAt = DateTime.now();
    unawaited(_handleSend(proactive: true));
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) {
      widget.controller?._state = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _cancelSendRequest();
    _agentShelf?.close();
    if (widget.agentDataSource == null) _agentData?.dispose();
    _agentMemory.removeListener(_agentChanged);
    if (widget.agentMemoryStore == null) _agentMemory.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkConfigured() async {
    if (_checkingConfiguration || !mounted) return;
    _checkingConfiguration = true;
    var configured = false;
    try {
      configured = (await _ai.loadSettings()).isConfigured;
    } catch (_) {}
    _checkingConfiguration = false;
    if (!mounted) return;
    setState(() {
      _configured = configured;
      _configChecked = true;
    });
    _maybeProactive();
  }

  Future<void> _openHistory() async {
    final session = LayoutHelper.usesTabletLayout(context)
        ? await showDialog<AiChatHistorySession>(
            context: context,
            builder: (dialogContext) {
              final size = MediaQuery.sizeOf(dialogContext);
              return Dialog(
                clipBehavior: Clip.antiAlias,
                insetPadding: const EdgeInsets.all(32),
                child: SizedBox(
                  key: const ValueKey('ai-history-tablet-dialog'),
                  width: 720,
                  height: (size.height - 96).clamp(520.0, 820.0),
                  child: AiHistoryPage(store: _historyStore),
                ),
              );
            },
          )
        : await Navigator.of(context).push<AiChatHistorySession>(
            MaterialPageRoute<AiChatHistorySession>(
              builder: (_) => AiHistoryPage(store: _historyStore),
            ),
          );
    if (session == null || !mounted || _sending) return;
    await _restoreSession(session);
  }

  /// 载入历史会话继续对话：沿用原会话 ID，后续问答仍更新同一条记录。
  Future<void> _restoreSession(AiChatHistorySession session) async {
    setState(() {
      _entries
        ..clear()
        ..addAll(
          session.messages.map(
            (message) => _AiChatEntry.restored(
              role: message.role,
              text: message.text,
              content: message.content,
              at: message.at,
              historyRecommendations: message.recommendations,
            ),
          ),
        );
      _error = null;
      _sessionId = session.id;
      _sessionCreatedAt = session.createdAt;
      _selectedBook = null;
      _bookContext = '';
    });
    _scrollToBottomSoon();

    // 恢复关联书籍：优先按存储的书籍 ID，老记录退回书名匹配。
    Book? book;
    try {
      final numericId = int.tryParse(session.bookId ?? '');
      if (numericId != null) {
        book = await BookDao().getBookById(numericId);
      }
      if (book == null && session.bookTitle.trim().isNotEmpty) {
        final books = await BookDao().getAllBooks();
        book = books
            .where((candidate) => candidate.title == session.bookTitle.trim())
            .firstOrNull;
      }
    } catch (_) {}
    if (!mounted || book == null) return;
    final restoredBook = book;
    setState(() {
      _selectedBook = restoredBook;
      _bookContextLoading = true;
    });
    final loaded = await _buildBookContext(restoredBook);
    if (!mounted) return;
    setState(() {
      _bookContext = loaded;
      _bookContextLoading = false;
    });
  }

  void _cancelSendRequest() {
    _sendGeneration++;
    _sendCancelToken?.cancel('AI conversation stopped');
    _sendCancelToken = null;
    _agent?.cancel();
  }

  void _stopSending() {
    if (!_sending) return;
    _cancelSendRequest();
    setState(() {
      _sending = false;
      _activeTool = null;
      _error = null;
    });
    unawaited(_persistHistory());
  }

  /// 开启新对话：保留已发送内容，并结束上一轮请求。
  void _startNewChat() {
    if (_entries.isEmpty && _error == null && !_sending) return;
    if (_sending) unawaited(_persistHistory());
    _cancelSendRequest();
    setState(() {
      _entries.clear();
      _error = null;
      _sessionId = null;
      _sessionCreatedAt = null;
      _sending = false;
      _activeTool = null;
    });
  }

  /// 输入框左侧加号菜单：书籍关联入口。
  Future<void> _showPlusMenu() async {
    final selectedTitle = _selectedBook?.title;
    final action = await showGlassBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('ai-page-agent-settings'),
              leading: const Icon(Icons.psychology_outlined),
              title: Text(
                readingAgentText(
                  sheetContext,
                  '阅读 Agent 与记忆',
                  'Reading Agent & memory',
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('agent'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(sheetContext.l10n.aiChatSelectBook),
              subtitle: selectedTitle == null
                  ? null
                  : Text(
                      selectedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => Navigator.of(sheetContext).pop('pick'),
            ),
            if (selectedTitle != null)
              ListTile(
                leading: const Icon(Icons.link_off_rounded),
                title: Text(sheetContext.l10n.aiChatNoBook),
                onTap: () => Navigator.of(sheetContext).pop('clear'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'agent':
        await _openAgentSettings();
      case 'pick':
        await _pickBook();
      case 'clear':
        setState(() {
          _selectedBook = null;
          _bookContext = '';
        });
    }
  }

  Future<void> _pickBook() async {
    List<Book> books = const [];
    try {
      books = await BookDao().getAllBooks();
    } catch (_) {}
    if (!mounted) return;
    final selection = await showGlassBottomSheet<Object>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(sheetContext).bottom,
          ),
          children: [
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: Text(l10n.aiChatNoBook),
              onTap: () => Navigator.of(sheetContext).pop('none'),
            ),
            for (final book in books)
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: book.author.trim().isEmpty
                    ? null
                    : Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => Navigator.of(sheetContext).pop(book),
              ),
          ],
        );
      },
    );
    if (!mounted || selection == null) return;
    if (selection == 'none') {
      setState(() {
        _selectedBook = null;
        _bookContext = '';
      });
      return;
    }
    final book = selection as Book;
    setState(() {
      _selectedBook = book;
      _bookContext = '';
      _bookContextLoading = true;
    });
    final loaded = await _buildBookContext(book);
    if (!mounted) return;
    setState(() {
      _bookContext = loaded;
      _bookContextLoading = false;
    });
  }

  /// 注入内容 = 预处理摘要（若有）+ 用户笔记/高亮；总长受服务端 2800 字符
  /// 压缩约束，这里主动裁剪并保证两部分都有配额。
  Future<String> _buildBookContext(Book book) async {
    final buffer = StringBuffer();
    final bookId = book.id?.toString() ?? '';
    try {
      final summary = bookId.isEmpty
          ? null
          : await GlobalAIReadingService().loadBookSummary(bookId);
      if (summary != null) {
        final trimmed = summary.length > 1800
            ? '${summary.substring(0, 1800)}…'
            : summary;
        buffer
          ..writeln('【《${book.title}》本地知识库摘要】')
          ..writeln(trimmed)
          ..writeln();
      }
    } catch (_) {}
    try {
      final notes = book.id == null
          ? const <BookNote>[]
          : await BookNoteDao().selectBookNotesByBookId(book.id!);
      if (notes.isNotEmpty) {
        buffer.writeln('【用户在《${book.title}》中的笔记与高亮】');
        var used = 0;
        for (final note in notes) {
          final label = switch (note.type) {
            'note' => '笔记',
            'underline' => '下划线',
            _ => '高亮',
          };
          final quote = note.content.replaceAll(RegExp(r'\s+'), ' ').trim();
          final own = note.readerNote?.trim() ?? '';
          final line = '- [$label] $quote${own.isEmpty ? '' : '（批注：$own）'}';
          if (used + line.length > 900) break;
          used += line.length;
          buffer.writeln(line);
        }
      }
    } catch (_) {}
    return buffer.toString().trim();
  }

  Future<void> _handleSend({bool proactive = false}) async {
    final text = proactive
        ? readingAgentText(
            context,
            '根据我的阅读偏好，在启用书源中为我推荐下一本书。',
            'Recommend my next book from enabled sources based on my reading preferences.',
          )
        : _inputController.text.trim();
    if (text.isEmpty || _sending || !_configured) return;
    if (!proactive) _inputController.clear();
    final generation = ++_sendGeneration;
    final cancelToken = _sendCancelToken = CancelToken();
    bool isCurrent() =>
        mounted && generation == _sendGeneration && !cancelToken.isCancelled;
    setState(() {
      if (!proactive) _entries.add(_AiChatEntry(role: 'user', text: text));
      _sending = true;
      _error = null;
    });
    _scrollToBottomSoon();
    try {
      final history = proactive
          ? [AIChatMessage(role: 'user', content: text)]
          : _entries
                .map(
                  (entry) =>
                      AIChatMessage(role: entry.role, content: entry.content),
                )
                .toList(growable: false);
      ReadingAgentResult? agentResult;
      final String answer;
      await _agentMemory.ensureLoaded();
      if (!isCurrent()) return;
      if (_agentMemory.permissions.enabled) {
        final agent = _ensureAgent();
        if (agent == null) {
          throw const AIServiceException(code: 'agent_not_supported');
        }
        agentResult = await agent.chat(
          history: history,
          bookContext: _bookContext,
          onTool: (name) {
            if (isCurrent()) {
              setState(() => _activeTool = name);
            }
          },
        );
        answer = agentResult.answer;
      } else {
        // 交互式请求登记到协调器：后台预处理会让行，对话不排队。
        answer = await AiRequestCoordinator().runInteractive(
          () => _ai.chat(
            history: history,
            pageText: _bookContext,
            meta: AIRequestMeta(
              bookId: _selectedBook?.id?.toString() ?? '',
              chapterId: 'ai-page-chat',
            ),
            cancelToken: cancelToken,
          ),
        );
      }
      if (!isCurrent()) return;
      setState(() {
        _entries.add(
          _AiChatEntry(
            role: 'assistant',
            text:
                '${proactive ? '${readingAgentText(context, '为你推荐', 'For you')}\n\n' : ''}${translateMockAiResponse(context, answer)}',
            content: agentResult?.conversationContent ?? answer,
            agentResult: agentResult,
          ),
        );
        _sending = false;
        _activeTool = null;
      });
      unawaited(_persistHistory());
      if (proactive) await _agentMemory.markProactiveDelivered(DateTime.now());
    } on AIServiceException catch (exception) {
      if (!isCurrent()) return;
      setState(() {
        _sending = false;
        _activeTool = null;
        _error = exception.code == 'agent_cancelled'
            ? null
            : switch (exception.code) {
                'agent_message_too_long' => readingAgentText(
                  context,
                  '问题过长，请缩短至 12000 字符以内',
                  'Please shorten your question to 12,000 characters.',
                ),
                'agent_timeout' => readingAgentText(
                  context,
                  '本次查询已超时，请缩小推荐范围后重试',
                  'This request timed out. Narrow your request and try again.',
                ),
                'tool_round_limit_exceeded' => readingAgentText(
                  context,
                  '已达到本次查询上限，请缩小范围后重试',
                  'The query limit was reached. Narrow your request and retry.',
                ),
                'agent_not_supported' => readingAgentText(
                  context,
                  '当前 AI 服务不支持阅读 Agent，请检查模型配置',
                  'This AI service does not support the reading Agent. Check your model settings.',
                ),
                _ => translateAIServiceException(context, exception),
              };
      });
    } on DioException catch (exception) {
      if (!isCurrent()) return;
      setState(() {
        _sending = false;
        _activeTool = null;
        _error = CancelToken.isCancel(exception)
            ? null
            : context.l10n.readerAiUnknownError;
      });
    } catch (_) {
      if (!isCurrent()) return;
      setState(() {
        _sending = false;
        _activeTool = null;
        _error = context.l10n.readerAiUnknownError;
      });
    } finally {
      if (identical(_sendCancelToken, cancelToken)) _sendCancelToken = null;
    }
    _scrollToBottomSoon();
  }

  Future<void> _persistHistory() async {
    if (_entries.isEmpty) return;
    final now = DateTime.now();
    _sessionId ??= now.microsecondsSinceEpoch.toString();
    _sessionCreatedAt ??= _entries.first.at;
    await _historyStore.upsertSession(
      AiChatHistorySession(
        id: _sessionId!,
        bookTitle: _selectedBook?.title ?? '',
        bookId: _selectedBook?.id?.toString(),
        createdAt: _sessionCreatedAt!,
        updatedAt: now,
        messages: [
          for (final entry in _entries)
            AiChatHistoryMessage(
              role: entry.role,
              text: entry.text,
              content: entry.content,
              at: entry.at,
              recommendations:
                  entry.agentResult?.recommendations
                      .map(
                        (item) => AiChatBookRecommendation(
                          sourceKey: sha256
                              .convert(utf8.encode(item.book.source.id))
                              .toString(),
                          sourceName: item.book.source.name,
                          title: item.book.book.title,
                          author: item.book.book.author,
                          reason: item.reason,
                        ),
                      )
                      .where(
                        (item) =>
                            AiChatBookRecommendation.fromJson(item.toJson()) !=
                            null,
                      )
                      .toList() ??
                  entry.historyRecommendations,
            ),
        ],
      ),
    );
  }

  void _openAgentBook(ReadingAgentRecommendation recommendation) {
    final data = _agentData;
    if (data is! LocalReadingAgentDataSource) return;
    final shelf = _agentShelf ??= BookSourceShelfService(client: data.client);
    SourcedBookActions(
      context: context,
      client: data.client,
      shelfService: shelf,
    ).showBookDetails(recommendation.book);
  }

  Future<void> _openHistoricalAgentBook(
    AiChatBookRecommendation recommendation,
  ) async {
    final data = _agentData ??=
        widget.agentDataSource ?? LocalReadingAgentDataSource();
    if (data is! LocalReadingAgentDataSource) return;
    try {
      final book = await data.resolveRecommendation(
        sourceKey: recommendation.sourceKey,
        title: recommendation.title,
        author: recommendation.author,
      );
      if (!mounted) return;
      if (book == null) {
        showSideToast(
          context,
          readingAgentText(
            context,
            '该书暂不可用，请检查书源或让 AI 重新搜索',
            'This book is unavailable. Check the source or ask the Agent to search again.',
          ),
          kind: SideToastKind.warning,
        );
        return;
      }
      _openAgentBook(
        ReadingAgentRecommendation(book: book, reason: recommendation.reason),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = readingAgentText(
            context,
            '书源查询失败，请稍后重试',
            'The book source could not be reached. Please retry.',
          ),
        );
      }
    }
  }

  Future<void> _saveAgentPreference(String text) async {
    try {
      await _agentMemory.saveMemory(text: text, origin: 'agent_suggestion');
      if (!mounted) return;
      showSideToast(
        context,
        readingAgentText(context, '已保存阅读偏好', 'Reading preference saved'),
        kind: SideToastKind.success,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = readingAgentText(
            context,
            '偏好保存失败，请重试',
            'Could not save the preference.',
          ),
        );
      }
    }
  }

  Future<void> _recordAgentFeedback(
    ReadingAgentRecommendation recommendation,
    bool interested,
  ) async {
    try {
      await _agentMemory.recordFeedback(
        title: recommendation.book.book.title,
        author: recommendation.book.book.author,
        interested: interested,
      );
      if (!mounted) return;
      showSideToast(
        context,
        readingAgentText(context, '已记录推荐反馈', 'Recommendation feedback saved'),
        kind: SideToastKind.success,
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = readingAgentText(
            context,
            '反馈保存失败，请重试',
            'Could not save the feedback.',
          ),
        );
      }
    }
  }

  Widget _buildEntry(_AiChatEntry entry) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _AiChatBubble(entry: entry),
      if (entry.agentResult case final result?)
        ReadingAgentResultPanel(
          result: result,
          onOpen: _openAgentBook,
          onFeedback: (book, interested) =>
              unawaited(_recordAgentFeedback(book, interested)),
          onSaveMemory: (text) => unawaited(_saveAgentPreference(text)),
          onSettings: () => unawaited(_openAgentSettings()),
        ),
      if (entry.historyRecommendations.isNotEmpty)
        ReadingAgentHistoryPanel(
          recommendations: entry.historyRecommendations,
          onOpen: (item) => unawaited(_openHistoricalAgentBook(item)),
        ),
    ],
  );

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _updateOverlayHeight(Size size) {
    if ((size.height - _overlayHeight).abs() < 0.5) return;
    final keepPinnedToBottom =
        !_scrollController.hasClients ||
        _scrollController.position.extentAfter < 24;
    setState(() => _overlayHeight = size.height);
    if (keepPinnedToBottom) _scrollToBottomSoon();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final useRailNavigation =
        NavigationContext.of(context)?.useRailNavigation ?? false;
    final usesTabletLayout = LayoutHelper.usesTabletLayout(context);
    final mobileChrome = HomeMobileChromeScope.of(context);
    final topPadding = useRailNavigation ? 16.0 : mobileChrome.pageTopPadding;
    // 键盘弹出时悬浮导航栏滑出隐藏，输入条收起为导航栏预留的底部留白，
    // 直接贴近键盘。键盘可见性来自壳层 Scaffold 外侧的原始 viewInsets。
    final bottomPadding = useRailNavigation
        ? 20.0
        : mobileChrome.keyboardVisible
        ? 10.0
        : mobileChrome.pageBottomPadding;
    // 键盘弹出的瞬间把对话滚到底，避免最后几条消息被压缩后的视口截断。
    if (mobileChrome.keyboardVisible != _lastKeyboardVisible) {
      _lastKeyboardVisible = mobileChrome.keyboardVisible;
      if (mobileChrome.keyboardVisible) _scrollToBottomSoon();
    }
    // 列表顶部留白：手机端内容需越过顶栏（顶栏高度并入滚动区内边距）。
    final bannerVisible = _configChecked && !_configured;
    final listTopPadding = useRailNavigation || bannerVisible
        ? 10.0
        : topPadding + 10.0;
    final emptyState = mobileChrome.keyboardVisible
        ? const SizedBox.shrink()
        : Padding(
            key: const ValueKey('ai-page-empty-state'),
            padding: EdgeInsets.fromLTRB(
              32,
              listTopPadding,
              32,
              _overlayHeight + 8,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 44,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.readerAiEmptyHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    key: const ValueKey('ai-page-agent-setup'),
                    onPressed: () => unawaited(_openAgentSettings()),
                    icon: const Icon(Icons.psychology_outlined),
                    label: Text(
                      readingAgentText(
                        context,
                        '阅读 Agent 与记忆',
                        'Reading Agent & memory',
                      ),
                    ),
                  ),
                  if (_configured &&
                      _agentLoaded &&
                      _agentMemory.permissions.enabled)
                    FilledButton.tonal(
                      key: const ValueKey('ai-page-agent-recommend'),
                      onPressed: () {
                        _inputController.text = readingAgentText(
                          context,
                          '根据我的阅读偏好，在启用书源中为我推荐下一本书。',
                          'Recommend my next book from enabled sources based on my reading preferences.',
                        );
                        unawaited(_handleSend());
                      },
                      child: Text(
                        readingAgentText(
                          context,
                          '推荐下一本',
                          'Recommend my next book',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );

    return Container(
      decoration: PageStyleHelper.backgroundDecoration(context),
      child: SafeArea(
        top: useRailNavigation,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            key: const ValueKey('ai-page-content'),
            constraints: BoxConstraints(maxWidth: usesTabletLayout ? 760 : 860),
            child: Column(
              children: [
                // 手机端标题与工具在壳层顶栏（工具在右）；宽屏保留页内大标题行。
                if (useRailNavigation)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, topPadding, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.navAi,
                            style: const TextStyle(
                              fontSize: 36,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('ai-page-history'),
                          tooltip: l10n.aiHistoryTitle,
                          onPressed: _sending
                              ? null
                              : () => unawaited(_openHistory()),
                          icon: const Icon(Icons.history_rounded),
                        ),
                        IconButton(
                          key: const ValueKey('ai-page-new-chat'),
                          tooltip: l10n.aiChatNewChat,
                          onPressed: _sending ? null : _startNewChat,
                          icon: const Icon(Icons.add_comment_outlined),
                        ),
                      ],
                    ),
                  ),
                // 手机端不加实体占位：内容从半透明顶栏下方穿过（与其他页一致），
                // 顶部留白放进滚动区内部，避免顶栏区域出现双色图层。
                if (_configChecked && !_configured)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      useRailNavigation ? 8 : topPadding + 8,
                      16,
                      0,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.readerAiNotConfiguredHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                // 输入条真悬浮：只有胶囊本体有背景，四周完全透出消息；
                // 列表底部预留胶囊高度，滚到底时最后一条消息停在胶囊上方。
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _entries.isEmpty && !_sending
                            ? emptyState
                            : ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  listTopPadding,
                                  16,
                                  _overlayHeight + 8,
                                ),
                                children: [
                                  for (final entry in _entries)
                                    _buildEntry(entry),
                                  if (_sending)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _activeTool == null
                                                ? l10n.readerAiThinking
                                                : readingAgentText(
                                                    context,
                                                    '正在查询阅读数据与书源…',
                                                    'Checking reading data and book sources…',
                                                  ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      scheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      // 悬浮层：错误条/书籍胶囊/输入条，周边区域不拦截点击。
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: MeasuredSize(
                          onChanged: _updateOverlayHeight,
                          child: Column(
                            key: const ValueKey('ai-page-overlay'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer.withValues(
                                        alpha: 0.92,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _error!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onErrorContainer,
                                          ),
                                    ),
                                  ),
                                ),
                              // 已关联书籍时在输入条上方展示可移除的胶囊。
                              if (_selectedBook != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    6,
                                  ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: InputChip(
                                          key: const ValueKey(
                                            'ai-page-linked-book',
                                          ),
                                          avatar: Icon(
                                            Icons.menu_book,
                                            size: 16,
                                            color: scheme.primary,
                                          ),
                                          label: Text(
                                            _selectedBook!.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onDeleted: _sending
                                              ? null
                                              : () => setState(() {
                                                  _selectedBook = null;
                                                  _bookContext = '';
                                                }),
                                        ),
                                      ),
                                      if (_bookContextLoading)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              // 悬浮输入条：与悬浮导航栏同风格的玻璃胶囊。
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  bottomPadding,
                                ),
                                child: _buildFloatingInputBar(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 悬浮输入条：玻璃胶囊（与悬浮导航栏同参数），加号、输入框与
  /// 发送键垂直居中在同一水平线上。
  Widget _buildFloatingInputBar(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return PillInputSurface(
      fillColor: scheme.surfaceContainerHigh,
      elevated: true,
      shadowColor: scheme.shadow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        // 全部元素垂直居中：加号、输入文字与发送键保持同一水平线；
        // 多行输入时整条同步增高，仍居中。
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('ai-page-plus'),
              tooltip: l10n.aiChatSelectBook,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: _sending ? null : () => unawaited(_showPlusMenu()),
              icon: const Icon(Icons.add_circle_outline, size: 22),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                key: const ValueKey('ai-page-input'),
                controller: _inputController,
                enabled: _configured,
                minLines: 1,
                maxLines: 4,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => unawaited(_handleSend()),
                style: const TextStyle(fontSize: 15, height: 1.4),
                decoration: InputDecoration(
                  hintText: l10n.readerAiInputHint,
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              key: const ValueKey('ai-page-send'),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: _sending
                  ? _stopSending
                  : _configured
                  ? () => unawaited(_handleSend())
                  : null,
              tooltip: _sending
                  ? readingAgentText(context, '停止生成', 'Stop generation')
                  : l10n.readerAiSendButton,
              icon: Icon(
                _sending ? Icons.stop_rounded : Icons.arrow_upward_rounded,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiChatBubble extends StatelessWidget {
  const _AiChatBubble({required this.entry});

  final _AiChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = entry.role == 'user';
    final maxWidth = LayoutHelper.usesTabletLayout(context) ? 600.0 : 560.0;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.fromLTRB(13, 10, 13, isUser ? 10 : 0),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: isUser
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? scheme.primary.withValues(alpha: 0.32)
                : scheme.outlineVariant,
          ),
        ),
        child: isUser
            ? SelectableText(
                entry.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              )
            : ReleaseNotesMarkdown(data: entry.text),
      ),
    );
  }
}
