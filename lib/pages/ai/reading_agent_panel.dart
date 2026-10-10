import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xxread/services/ai/ai_chat_history_store.dart';
import 'package:xxread/services/ai/reading_agent_memory_store.dart';
import 'package:xxread/services/ai/reading_agent_service.dart';

String readingAgentText(BuildContext context, String zh, String en) =>
    Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

class ReadingAgentSettingsSheet extends StatefulWidget {
  const ReadingAgentSettingsSheet({super.key, required this.store});
  final ReadingAgentMemoryStore store;

  @override
  State<ReadingAgentSettingsSheet> createState() =>
      _ReadingAgentSettingsSheetState();
}

class ReadingAgentHistoryPanel extends StatelessWidget {
  const ReadingAgentHistoryPanel({
    super.key,
    required this.recommendations,
    required this.onOpen,
  });
  final List<AiChatBookRecommendation> recommendations;
  final void Function(AiChatBookRecommendation) onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in recommendations)
        _ReadingRecommendationCard(
          title: item.title,
          author: item.author,
          sourceName: item.sourceName,
          reason: item.reason,
          onOpen: () => onOpen(item),
        ),
    ],
  );
}

class _ReadingAgentSettingsSheetState extends State<ReadingAgentSettingsSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = readingAgentText(
            context,
            '保存失败，请重试',
            'Could not save. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editMemory([ReadingAgentMemory? memory]) async {
    final input = TextEditingController(text: memory?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(readingAgentText(context, '阅读偏好', 'Reading preference')),
        content: TextField(
          key: const ValueKey('reading-agent-memory-input'),
          controller: input,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: readingAgentText(
              context,
              '例如：喜欢历史小说，不喜欢剧透',
              'For example: I enjoy historical fiction. Avoid spoilers.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(readingAgentText(context, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, input.text.trim());
              }
            },
            child: Text(readingAgentText(context, '保存', 'Save')),
          ),
        ],
      ),
    );
    // The closing route may still render its TextField for one animation frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => input.dispose());
    if (text != null && mounted) {
      await _save(() => widget.store.saveMemory(text: text, id: memory?.id));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final permissions = store.permissions;
      Widget toggle(
        String key,
        String zh,
        String en,
        bool value,
        void Function(bool) change, {
        String? subtitle,
      }) => SwitchListTile(
        key: ValueKey(key),
        title: Text(readingAgentText(context, zh, en)),
        subtitle: subtitle == null ? null : Text(subtitle),
        value: value,
        onChanged: _saving ? null : change,
      );
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                readingAgentText(
                  context,
                  '阅读 Agent 与记忆',
                  'Reading Agent & memory',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                readingAgentText(
                  context,
                  '按需读取本设备的阅读记录和启用书源。提问时，所需数据会发送给你配置的 AI 服务商。原始记录保留在本地；关闭后停止 Agent 访问。',
                  'Queries reading records on this device and enabled book sources. When you ask, the needed data is sent to your configured AI provider. Original records stay local. Turning this off stops Agent access.',
                ),
              ),
              toggle(
                'reading-agent-enabled',
                '启用阅读 Agent',
                'Enable Reading Agent',
                permissions.enabled,
                (value) => _save(
                  () => store.setPermissions(
                    permissions.copyWith(
                      enabled: value,
                      proactive: value ? permissions.proactive : false,
                    ),
                  ),
                ),
              ),
              toggle(
                'reading-agent-stats',
                '阅读统计与会话',
                'Reading statistics & sessions',
                permissions.readingStats,
                (value) => _save(
                  () => store.setPermissions(
                    permissions.copyWith(readingStats: value),
                  ),
                ),
              ),
              toggle(
                'reading-agent-library',
                '书架与阅读进度',
                'Library & reading progress',
                permissions.library,
                (value) => _save(
                  () => store.setPermissions(
                    permissions.copyWith(library: value),
                  ),
                ),
              ),
              toggle(
                'reading-agent-sources',
                '启用书源与搜索',
                'Enabled book sources & search',
                permissions.bookSources,
                (value) => _save(
                  () => store.setPermissions(
                    permissions.copyWith(
                      bookSources: value,
                      proactive: value ? permissions.proactive : false,
                    ),
                  ),
                ),
              ),
              SwitchListTile(
                key: const ValueKey('reading-agent-proactive'),
                title: Text(
                  readingAgentText(
                    context,
                    '应用内主动推荐',
                    'Proactive recommendations in the app',
                  ),
                ),
                subtitle: Text(
                  readingAgentText(
                    context,
                    '默认关闭。开启后，进入 AI 页时最多每天主动推荐一次，会调用你的模型。',
                    'Off by default. When enabled, visiting the AI page can trigger one recommendation per day using your model.',
                  ),
                ),
                value: permissions.proactive,
                onChanged:
                    !_saving && permissions.enabled && permissions.bookSources
                    ? (value) => _save(
                        () => store.setPermissions(
                          permissions.copyWith(proactive: value),
                        ),
                      )
                    : null,
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  readingAgentText(
                    context,
                    '长期阅读偏好',
                    'Long-term reading preferences',
                  ),
                ),
                subtitle: Text(
                  readingAgentText(
                    context,
                    '你可以随时修改或删除。AI 提出的偏好需要你保存后才会记住。',
                    'Edit or delete at any time. AI suggestions are remembered only after you save them.',
                  ),
                ),
                trailing: IconButton(
                  key: const ValueKey('reading-agent-add-memory'),
                  tooltip: readingAgentText(context, '添加偏好', 'Add preference'),
                  onPressed: _saving ? null : _editMemory,
                  icon: const Icon(Icons.add),
                ),
              ),
              for (final memory in store.memories)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(memory.text),
                  subtitle: Text(
                    '${readingAgentText(context, memory.origin == 'user' ? '用户记录' : '已确认 AI 建议', memory.origin == 'user' ? 'User entry' : 'Confirmed AI suggestion')} · ${memory.updatedAt.toLocal().toIso8601String().split('T').first}',
                  ),
                  onTap: _saving ? null : () => _editMemory(memory),
                  trailing: IconButton(
                    tooltip: readingAgentText(
                      context,
                      '删除偏好',
                      'Delete preference',
                    ),
                    onPressed: _saving
                        ? null
                        : () => _save(() => store.deleteMemory(memory.id)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              if (store.memories.isEmpty)
                Text(
                  readingAgentText(
                    context,
                    '还没有长期偏好。可以添加喜爱的题材、作者或想避开的内容。',
                    'No saved preferences yet. Add genres, authors or content you want to avoid.',
                  ),
                ),
              if (store.feedback.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  readingAgentText(context, '推荐反馈', 'Recommendation feedback'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final entry in store.feedback)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${entry['title']} · ${entry['author']}'),
                    subtitle: Text(
                      readingAgentText(
                        context,
                        entry['value'] == 'interested' ? '感兴趣' : '不感兴趣',
                        entry['value'] == 'interested'
                            ? 'Interested'
                            : 'Not interested',
                      ),
                    ),
                  ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: store.toMarkdown()),
                    ),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(
                      readingAgentText(
                        context,
                        '复制为 Markdown',
                        'Copy as Markdown',
                      ),
                    ),
                  ),
                  if (store.memories.isNotEmpty || store.feedback.isNotEmpty)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    readingAgentText(
                                      context,
                                      '清除偏好与推荐反馈？',
                                      'Clear preferences and feedback?',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text(
                                        readingAgentText(
                                          context,
                                          '取消',
                                          'Cancel',
                                        ),
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text(
                                        readingAgentText(
                                          context,
                                          '清除',
                                          'Clear',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && mounted) {
                                await _save(store.clearMemories);
                              }
                            },
                      child: Text(
                        readingAgentText(context, '清除记忆', 'Clear memory'),
                      ),
                    ),
                ],
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class ReadingAgentResultPanel extends StatelessWidget {
  const ReadingAgentResultPanel({
    super.key,
    required this.result,
    required this.onOpen,
    required this.onFeedback,
    required this.onSaveMemory,
    required this.onSettings,
  });
  final ReadingAgentResult result;
  final void Function(ReadingAgentRecommendation recommendation) onOpen;
  final void Function(
    ReadingAgentRecommendation recommendation,
    bool interested,
  )
  onFeedback;
  final void Function(String text) onSaveMemory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final recommendation in result.recommendations)
        _ReadingRecommendationCard(
          title: recommendation.book.book.title,
          author: recommendation.book.book.author,
          sourceName: recommendation.book.source.name,
          reason: recommendation.reason,
          onOpen: () => onOpen(recommendation),
          actions: [
            IconButton(
              tooltip: readingAgentText(context, '感兴趣', 'Interested'),
              onPressed: () => onFeedback(recommendation, true),
              icon: const Icon(Icons.thumb_up_outlined),
            ),
            IconButton(
              tooltip: readingAgentText(context, '不感兴趣', 'Not interested'),
              onPressed: () => onFeedback(recommendation, false),
              icon: const Icon(Icons.thumb_down_outlined),
            ),
          ],
        ),
      for (final text in result.memorySuggestions)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.psychology_outlined),
          title: Text(text),
          subtitle: Text(
            readingAgentText(
              context,
              '建议记住的偏好',
              'Suggested preference to remember',
            ),
          ),
          trailing: TextButton(
            onPressed: () => onSaveMemory(text),
            child: Text(readingAgentText(context, '保存', 'Save')),
          ),
        ),
      if (result.proactiveSuggested)
        TextButton.icon(
          onPressed: onSettings,
          icon: const Icon(Icons.notifications_none),
          label: Text(
            readingAgentText(
              context,
              '管理主动推荐开关',
              'Manage proactive recommendations',
            ),
          ),
        ),
    ],
  );
}

class _ReadingRecommendationCard extends StatelessWidget {
  const _ReadingRecommendationCard({
    required this.title,
    required this.author,
    required this.sourceName,
    required this.reason,
    required this.onOpen,
    this.actions = const [],
  });

  final String title;
  final String author;
  final String sourceName;
  final String reason;
  final VoidCallback onOpen;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '$author · $sourceName',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(reason),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onOpen,
                child: Text(readingAgentText(context, '查看书籍', 'View book')),
              ),
              ...actions,
            ],
          ),
        ],
      ),
    ),
  );
}
