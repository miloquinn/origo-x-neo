import 'package:flutter/material.dart';
import '../../../utils/page_style_helper.dart';
import '../../../services/backup/backup_selection.dart';
import '../../../services/backup/webdav_backup_controller.dart';
import 'backup_copy.dart';

class BackupSelectionPanel extends StatelessWidget {
  const BackupSelectionPanel({super.key, required this.controller});
  final WebDavBackupController controller;

  @override
  Widget build(BuildContext context) {
    final zh = BackupCopy.of(context).zh;
    final selection = controller.selection;
    void update({
      bool? reading,
      bool? statistics,
      bool? sources,
      bool? settings,
      Set<int>? ids,
    }) {
      controller.setSelection(
        BackupSelection(
          reading: reading ?? selection.reading,
          statistics: statistics ?? selection.statistics,
          sources: sources ?? selection.sources,
          settings: settings ?? selection.settings,
          bookIds: ids ?? selection.bookIds,
        ),
      );
    }

    final bytes = controller.books
        .where((b) => selection.bookIds.contains(b.id))
        .fold<int>(0, (sum, b) => sum + b.bytes);
    return ExpansionTile(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      title: Text(zh ? '备份内容' : 'Backup content'),
      subtitle: Text(
        zh
            ? '正文已选 ${selection.bookIds.length} 本 · ${backupBytes(bytes)}'
            : '${selection.bookIds.length} book files · ${backupBytes(bytes)}',
      ),
      children: [
        SwitchListTile.adaptive(
          title: Text(
            zh ? '书架、阅读进度、书签和笔记' : 'Library, progress, bookmarks and notes',
          ),
          subtitle: Text(
            zh
                ? '下方可查看已选正文；未备份的本地书籍仍需重新导入。'
                : 'Review selected book files below. Omitted local books must be reimported.',
          ),
          value: selection.reading || selection.bookIds.isNotEmpty,
          onChanged: controller.busy || selection.bookIds.isNotEmpty
              ? null
              : (v) => update(reading: v),
        ),
        SwitchListTile.adaptive(
          title: Text(zh ? '阅读统计' : 'Reading statistics'),
          value: selection.statistics,
          onChanged: controller.busy ? null : (v) => update(statistics: v),
        ),
        SwitchListTile.adaptive(
          title: Text(zh ? '书源' : 'Book sources'),
          value: selection.sources,
          onChanged: controller.busy ? null : (v) => update(sources: v),
        ),
        SwitchListTile.adaptive(
          title: Text(zh ? '阅读设置' : 'Reading settings'),
          value: selection.settings,
          onChanged: controller.busy ? null : (v) => update(settings: v),
        ),
        ListTile(
          title: Text(zh ? '选择书籍正文' : 'Choose book files'),
          subtitle: Text(
            zh
                ? '默认包含可用的本地正文；可按需调整。大小为压缩前估算。'
                : 'Available local book files are included by default. Sizes are estimates before compression.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: controller.busy
              ? null
              : () async {
                  final result = await showModalBottomSheet<Set<int>>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    constraints: const BoxConstraints(maxWidth: 680),
                    builder: (_) => _BookPicker(controller: controller, zh: zh),
                  );
                  if (result != null) update(ids: result);
                },
        ),
      ],
    );
  }
}

class _BookPicker extends StatefulWidget {
  const _BookPicker({required this.controller, required this.zh});
  final WebDavBackupController controller;
  final bool zh;
  @override
  State<_BookPicker> createState() => _BookPickerState();
}

class _BookPickerState extends State<_BookPicker> {
  late final Set<int> selected = {...widget.controller.selection.bookIds};
  late Future<void> loading = widget.controller.loadBooks();
  final search = TextEditingController();
  String query = '';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => loading = widget.controller.loadBooks());

  void _toggle(BackupBook book) {
    if (!book.available) return;
    setState(() {
      if (!selected.add(book.id)) selected.remove(book.id);
    });
  }

  Widget _bookRow(BuildContext context, BackupBook book) {
    final palette = PageStyleHelper.palette(context);
    final scheme = Theme.of(context).colorScheme;
    final active = selected.contains(book.id);
    final rowColor = active
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.1),
            scheme.surface,
          )
        : Color.alphaBlend(palette.cardStrong, scheme.surface);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: book.available ? () => _toggle(book) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 22,
                  color: book.available ? scheme.primary : palette.iconMuted,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        book.available
                            ? backupBytes(book.bytes)
                            : (widget.zh ? '文件缺失' : 'File missing'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Checkbox.adaptive(
                  value: active,
                  onChanged: book.available ? (_) => _toggle(book) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zh = widget.zh;
    final palette = PageStyleHelper.palette(context);
    final scheme = Theme.of(context).colorScheme;
    final accentSurface = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.1),
      scheme.surface,
    );
    final fieldSurface = Color.alphaBlend(palette.cardStrong, scheme.surface);
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    final compact = availableHeight < 560;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: (availableHeight * (compact ? 0.96 : 0.88)).clamp(0.0, 760.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: EdgeInsets.only(top: 10, bottom: compact ? 8 : 22),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  if (!compact) ...[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentSurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.auto_stories_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 13),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          compact
                              ? (zh
                                    ? '选择书籍正文 · ${selected.length}'
                                    : 'Book files · ${selected.length}')
                              : (zh ? '选择书籍正文' : 'Choose book files'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (!compact)
                          Text(
                            zh
                                ? '随备份保存，恢复时找回正文'
                                : 'Save files for a complete restore',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.textMuted),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: zh ? '关闭' : 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 8 : 18),
            Expanded(
              child: FutureBuilder<void>(
                future: loading,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            color: palette.iconMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(zh ? '书籍列表暂时无法读取' : 'Could not load books'),
                          TextButton(
                            onPressed: _reload,
                            child: Text(zh ? '重试' : 'Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final books = widget.controller.books;
                  final available = books
                      .where((book) => book.available)
                      .toList();
                  final visible = books
                      .where(
                        (book) => book.title.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .toList();
                  final bytes = books
                      .where((book) => selected.contains(book.id))
                      .fold<int>(0, (sum, book) => sum + book.bytes);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: accentSurface,
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    zh
                                        ? '已选 ${selected.length} 本 · ${backupBytes(bytes)}'
                                        : '${selected.length} selected · ${backupBytes(bytes)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: compact ? 0 : 14),
                        TextField(
                          controller: search,
                          decoration: InputDecoration(
                            hintText: zh ? '搜索书名' : 'Search books',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: zh ? '清除搜索' : 'Clear search',
                                    onPressed: () {
                                      search.clear();
                                      setState(() => query = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: fieldSurface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) => setState(() => query = value),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                zh
                                    ? '共 ${available.length} 本可备份'
                                    : '${available.length} available books',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: palette.textMuted),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  available.isEmpty ||
                                      available.every(
                                        (book) => selected.contains(book.id),
                                      )
                                  ? null
                                  : () => setState(
                                      () => selected.addAll(
                                        available.map((book) => book.id),
                                      ),
                                    ),
                              child: Text(zh ? '全选' : 'Select all'),
                            ),
                            TextButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () => setState(selected.clear),
                              child: Text(zh ? '取消全选' : 'Deselect all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: visible.isEmpty
                              ? Center(
                                  child: Text(
                                    query.isEmpty
                                        ? (zh ? '没有本地书籍' : 'No local books')
                                        : (zh
                                              ? '没有匹配的书籍'
                                              : 'No matching books'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: palette.textMuted),
                                  ),
                                )
                              : ListView.builder(
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) =>
                                      _bookRow(context, visible[index]),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                compact ? 6 : 12,
                20,
                compact ? 8 : 20,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(zh ? '取消' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, selected),
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(compact ? 40 : 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(zh ? '确定' : 'Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
