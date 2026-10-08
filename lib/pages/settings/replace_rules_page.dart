import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/services/reader/replace_rule_execution.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';
import 'package:xxread/widgets/pill_search_field.dart';
import 'package:xxread/widgets/side_toast.dart';

Future<ReplaceRule?> showReplaceRuleEditor(
  BuildContext context, {
  required ReplaceRuleService service,
  ReplaceRule? rule,
}) => showModalBottomSheet<ReplaceRule>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _ReplaceRuleEditor(service: service, rule: rule),
);

class ReplaceRulesPage extends StatefulWidget {
  const ReplaceRulesPage({
    super.key,
    required this.service,
    this.bookId,
    this.bookTitle,
    this.sourceName,
    this.sourceUrl,
    this.eligibleByDefault = true,
    this.effectiveRuleIds = const [],
  });

  final ReplaceRuleService service;
  final String? bookId;
  final String? bookTitle;
  final String? sourceName;
  final String? sourceUrl;
  final bool eligibleByDefault;
  final List<String> effectiveRuleIds;

  @override
  State<ReplaceRulesPage> createState() => _ReplaceRulesPageState();
}

class _ReplaceRulesPageState extends State<ReplaceRulesPage> {
  late final ReplaceRuleService _service = widget.service;
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedGroup;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  final Map<String, String> _effectiveRuleFingerprints = <String, String>{};

  @override
  void initState() {
    super.initState();
    for (final rule in _service.rules) {
      if (widget.effectiveRuleIds.contains(rule.id)) {
        _effectiveRuleFingerprints[rule.id] = _service.fingerprintForRule(rule);
      }
    }
    unawaited(_service.load());
    _service.addListener(_onRulesChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onRulesChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRulesChanged() {
    if (mounted) setState(() {});
  }

  List<ReplaceRule> get _visibleRules {
    final query = _query.trim().toLowerCase();
    return _service.rules
        .where(
          (rule) =>
              (_selectedGroup == null ||
                  _groupTokens(rule.group).contains(_selectedGroup)) &&
              (query.isEmpty ||
                  '${rule.name} ${rule.pattern} ${rule.group}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList(growable: false);
  }

  List<String> get _groups =>
      (_service.rules
              .expand((rule) => _groupTokens(rule.group))
              .toSet()
              .toList()
            ..sort())
          .toList(growable: false);

  Iterable<String> _groupTokens(String group) => group
      .split(RegExp(r'[,;，；\n\r]+'))
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);

  Future<void> _edit([ReplaceRule? rule]) async {
    final result = await showReplaceRuleEditor(
      context,
      service: _service,
      rule: rule,
    );
    if (result == null) return;
    try {
      await _service.upsert(result);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (!mounted) return;
    final file = result?.files.single;
    if (file == null) return;
    if (file.size > ReplaceRuleService.maxImportBytes) {
      _showMessage(
        context.l10n.replaceRulesImportTooLarge('8 MiB'),
        SideToastKind.warning,
      );
      return;
    }
    final bytes = file.bytes;
    if (bytes == null) return;
    try {
      final imported = ReplaceRuleService.decodeImport(utf8.decode(bytes));
      final merged = _service.mergeImported(imported);
      await _service.saveAll(merged);
      if (mounted) {
        _showMessage(
          context.l10n.replaceRulesImported(imported.length),
          SideToastKind.success,
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          context.l10n.replaceRulesImportFailed(_localizedError(error)),
          SideToastKind.error,
        );
      }
    }
  }

  Future<void> _export([Iterable<ReplaceRule>? selected]) async {
    final rules = selected?.toList(growable: false) ?? _service.rules;
    final bytes = utf8.encode(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(rules.map((rule) => rule.toJson()).toList()),
    );
    final path = await FilePicker.saveFile(
      dialogTitle: context.l10n.replaceRulesExport,
      fileName: 'origo-x-replace-rules.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(bytes),
    );
    if (!kIsWeb && (path == null || path.isEmpty)) return;
    if (mounted) {
      _showMessage(context.l10n.replaceRulesExported, SideToastKind.success);
    }
  }

  Future<void> _toggle(ReplaceRule rule, bool enabled) async {
    try {
      await _service.toggle(rule.id, enabled);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final next = [..._service.rules];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    try {
      await _service.saveAll(next);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  Future<void> _setRulesEnabled(bool enabled) async {
    try {
      final selected = Set<String>.of(_selectedIds);
      await _service.saveAll([
        for (final rule in _service.rules)
          selected.contains(rule.id) ? rule.copyWith(enabled: enabled) : rule,
      ]);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  Future<void> _deleteSelected() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replaceRulesDeleteSelectedConfirmTitle),
        content: Text(
          l10n.replaceRulesDeleteSelectedConfirmBody(_selectedIds.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replaceRulesDeleteSelected),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final selected = Set<String>.of(_selectedIds);
      await _service.saveAll(
        _service.rules.where((rule) => !selected.contains(rule.id)).toList(),
      );
      if (mounted) setState(_exitSelectionMode);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  void _exitSelectionMode() {
    _selectionMode = false;
    _selectedIds.clear();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.add(id)) _selectedIds.remove(id);
    });
  }

  Future<void> _copyRule(ReplaceRule rule) async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert(rule.toJson()),
      ),
    );
    if (mounted) {
      _showMessage(context.l10n.replaceRulesCopied, SideToastKind.success);
    }
  }

  Future<void> _pasteRule() async {
    try {
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      if (text == null || text.trim().isEmpty) return;
      final imported = ReplaceRuleService.decodeImport(text);
      if (imported.isEmpty) return;
      final pasted = imported.first.copyWith(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        order: _service.rules.length,
      );
      await _service.upsert(pasted);
      if (mounted) {
        _showMessage(context.l10n.replaceRulesPasted, SideToastKind.success);
      }
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  Future<void> _moveRule(ReplaceRule rule, {required bool toTop}) async {
    try {
      final next = [..._service.rules]
        ..removeWhere((item) => item.id == rule.id);
      if (toTop) {
        next.insert(0, rule);
      } else {
        next.add(rule);
      }
      await _service.saveAll(next);
    } catch (error) {
      if (mounted) _showMessage(_localizedError(error), SideToastKind.error);
    }
  }

  String _localizedError(Object error) {
    final l10n = context.l10n;
    if (error is ReplaceRuleValidationException) {
      return switch (error.kind) {
        ReplaceRuleValidationKind.emptyPattern =>
          l10n.replaceRulesPatternRequired,
        ReplaceRuleValidationKind.patternTooLong =>
          l10n.replaceRulesPatternTooLong(ReplaceRuleService.maxPatternLength),
        ReplaceRuleValidationKind.invalidRegex => l10n.replaceRulesInvalidRegex(
          error.message,
        ),
        ReplaceRuleValidationKind.tooManyRules => l10n.replaceRulesTooMany(
          ReplaceRuleService.maxRules,
        ),
        ReplaceRuleValidationKind.missingTarget =>
          l10n.replaceRulesMissingTarget,
        ReplaceRuleValidationKind.unsupportedReplacement =>
          l10n.replaceRulesUnsupportedReplacement,
      };
    }
    return error.toString().replaceFirst('FormatException: ', '');
  }

  void _showMessage(String message, SideToastKind kind) {
    showSideToast(context, message, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final rules = _visibleRules;
    final l10n = context.l10n;
    return FloatingSubpageScaffold(
      title: l10n.replaceRulesTitle,
      actions: [
        if (_selectionMode)
          FloatingSubpageAction(
            key: const ValueKey('replaceRulesCloseSelection'),
            icon: Icons.close_rounded,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => setState(_exitSelectionMode),
          )
        else
          FloatingSubpageMenuButton<_ReplaceRulesMenuAction>(
            key: const ValueKey('replaceRulesToolButton'),
            tooltip: l10n.replaceRulesTitle,
            icon: Icons.tune_rounded,
            items: [
              FloatingSubpageMenuItem(
                value: _ReplaceRulesMenuAction.import,
                child: ListTile(
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(l10n.replaceRulesImport),
                ),
              ),
              FloatingSubpageMenuItem(
                value: _ReplaceRulesMenuAction.export,
                enabled: _service.rules.isNotEmpty,
                child: ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: Text(l10n.replaceRulesExport),
                ),
              ),
              FloatingSubpageMenuItem(
                value: _ReplaceRulesMenuAction.paste,
                child: ListTile(
                  leading: const Icon(Icons.content_paste_rounded),
                  title: Text(l10n.replaceRulesPasteJson),
                ),
              ),
              FloatingSubpageMenuItem(
                value: _ReplaceRulesMenuAction.select,
                itemKey: const ValueKey('replaceRulesSelectionMode'),
                enabled: _service.rules.isNotEmpty,
                child: ListTile(
                  leading: const Icon(Icons.checklist_rounded),
                  title: Text(l10n.replaceRulesSelectionMode),
                ),
              ),
            ],
            onSelected: (action) => switch (action) {
              _ReplaceRulesMenuAction.import => _import(),
              _ReplaceRulesMenuAction.export => _export(),
              _ReplaceRulesMenuAction.paste => _pasteRule(),
              _ReplaceRulesMenuAction.select => setState(() {
                _selectionMode = true;
                _selectedIds.clear();
              }),
            },
          ),
      ],
      tools: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillSearchField(
            textFieldKey: const ValueKey('replaceRulesSearchField'),
            controller: _searchController,
            hintText: l10n.replaceRulesSearchHint,
            clearTooltip: MaterialLocalizations.of(context).clearButtonTooltip,
            onChanged: (value) => setState(() => _query = value),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          if (_groups.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: Text(l10n.replaceRulesGroupAll),
                    selected: _selectedGroup == null,
                    onSelected: (_) => setState(() => _selectedGroup = null),
                  ),
                  for (final group in _groups) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(group),
                      selected: _selectedGroup == group,
                      onSelected: (_) => setState(() => _selectedGroup = group),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_service.isLoaded) _buildEnablementTile(),
          if (_selectionMode) _buildSelectionBar(rules),
          Expanded(
            child: !_service.isLoaded
                ? const Center(child: CircularProgressIndicator())
                : rules.isEmpty
                ? _EmptyRules(
                    title: _query.trim().isEmpty
                        ? l10n.replaceRulesEmptyTitle
                        : l10n.replaceRulesNoSearchResults,
                    body: _query.trim().isEmpty
                        ? l10n.replaceRulesEmptyBody
                        : null,
                    onCreate: _query.trim().isEmpty ? () => _edit() : null,
                  )
                : _buildRuleList(rules),
          ),
        ],
      ),
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: Text(l10n.replaceRulesCreate),
            ),
    );
  }

  Widget _buildEnablementTile() {
    final bookId = widget.bookId;
    final contextual = bookId != null && bookId.isNotEmpty;
    final value = contextual
        ? _service.isEnabledForBook(
            bookId,
            eligibleByDefault: widget.eligibleByDefault,
          )
        : _service.defaultEnabled;
    final title = contextual
        ? context.l10n.replaceRulesBookEnabledLabel(
            widget.bookTitle?.trim().isNotEmpty == true
                ? widget.bookTitle!.trim()
                : bookId,
          )
        : context.l10n.replaceRulesDefaultEnabledLabel;
    final subtitleParts = <String>[
      if (widget.sourceName?.trim().isNotEmpty == true)
        widget.sourceName!.trim(),
      if (widget.sourceUrl?.trim().isNotEmpty == true) widget.sourceUrl!.trim(),
    ];
    return SwitchListTile.adaptive(
      key: ValueKey(
        contextual ? 'replaceRulesBookEnabled' : 'replaceRulesDefaultEnabled',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(title),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      value: value,
      onChanged: (enabled) async {
        try {
          if (contextual) {
            await _service.setBookEnabled(bookId, enabled);
          } else {
            await _service.setDefaultEnabled(enabled);
          }
        } catch (error) {
          if (mounted) {
            _showMessage(_localizedError(error), SideToastKind.error);
          }
        }
      },
    );
  }

  Widget _buildSelectionBar(List<ReplaceRule> visibleRules) {
    final l10n = context.l10n;
    final selectedRules = _service.rules
        .where((rule) => _selectedIds.contains(rule.id))
        .toList(growable: false);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.replaceRulesSelectedCount(_selectedIds.length)),
            TextButton(
              onPressed: () => setState(() {
                final visibleIds = visibleRules.map((rule) => rule.id).toSet();
                if (_selectedIds.containsAll(visibleIds)) {
                  _selectedIds.removeAll(visibleIds);
                } else {
                  _selectedIds.addAll(visibleIds);
                }
              }),
              child: Text(l10n.replaceRulesSelectAll),
            ),
            IconButton(
              key: const ValueKey('replaceRulesEnableSelected'),
              tooltip: l10n.replaceRulesEnableSelected,
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _setRulesEnabled(true),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
            IconButton(
              key: const ValueKey('replaceRulesDisableSelected'),
              tooltip: l10n.replaceRulesDisableSelected,
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _setRulesEnabled(false),
              icon: const Icon(Icons.pause_rounded),
            ),
            IconButton(
              key: const ValueKey('replaceRulesExportSelected'),
              tooltip: l10n.replaceRulesExportSelected,
              onPressed: selectedRules.isEmpty
                  ? null
                  : () => _export(selectedRules),
              icon: const Icon(Icons.file_download_outlined),
            ),
            IconButton(
              key: const ValueKey('replaceRulesDeleteSelected'),
              tooltip: l10n.replaceRulesDeleteSelected,
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleList(List<ReplaceRule> rules) {
    final reorderable =
        !_selectionMode && _query.trim().isEmpty && _selectedGroup == null;
    final list = ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: rules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rule = rules[index];
        return KeyedSubtree(
          key: ValueKey(rule.id),
          child: _buildRuleCard(rule, index, reorderable),
        );
      },
    );
    if (!reorderable) return list;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: rules.length,
      onReorderItem: _reorder,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return KeyedSubtree(
          key: ValueKey(rule.id),
          child: Padding(
            padding: EdgeInsets.only(bottom: index == rules.length - 1 ? 0 : 8),
            child: _buildRuleCard(rule, index, true),
          ),
        );
      },
    );
  }

  Widget _buildRuleCard(ReplaceRule rule, int index, bool reorderable) {
    final l10n = context.l10n;
    final fingerprint = _service.fingerprintForRule(rule);
    final effective =
        rule.enabled &&
        _service.isEnabledForBook(
          widget.bookId ?? '',
          eligibleByDefault: widget.eligibleByDefault,
        ) &&
        _effectiveRuleFingerprints[rule.id] == fingerprint;
    final timedOut = _service.recentDiagnostics.any(
      (diagnostic) =>
          diagnostic.ruleFingerprint == fingerprint &&
          diagnostic.kind == ReplaceRuleDiagnosticKind.timeout,
    );
    final unsupported =
        (rule.isRegex && rule.replacement.trimLeft().startsWith('@js:')) ||
        _service.recentDiagnostics.any(
          (diagnostic) =>
              diagnostic.ruleFingerprint == fingerprint &&
              diagnostic.kind ==
                  ReplaceRuleDiagnosticKind.unsupportedReplacement,
        );
    final subtitle = StringBuffer(
      '${rule.pattern} → ${rule.replacement.isEmpty ? l10n.replaceRulesDeleteValue : rule.replacement}',
    );
    if (rule.group.isNotEmpty) subtitle.write(' · ${rule.group}');
    if (timedOut) subtitle.write('\n${l10n.replaceRulesTimeoutNotice}');
    if (unsupported) {
      subtitle.write('\n${l10n.replaceRulesUnsupportedReplacement}');
    }
    return Card(
      child: ListTile(
        onTap: _selectionMode
            ? () => _toggleSelection(rule.id)
            : () => _edit(rule),
        onLongPress: _selectionMode
            ? null
            : () => setState(() {
                _selectionMode = true;
                _selectedIds.add(rule.id);
              }),
        leading: _selectionMode
            ? Checkbox(
                value: _selectedIds.contains(rule.id),
                onChanged: (_) => _toggleSelection(rule.id),
              )
            : Icon(
                rule.enabled
                    ? Icons.find_replace_rounded
                    : Icons.pause_circle_outline,
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rule.name.trim().isEmpty ? l10n.replaceRulesUnnamed : rule.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (effective) ...[
              const SizedBox(height: 4),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  l10n.replaceRulesEffectiveLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle.toString(),
          maxLines: timedOut || unsupported ? 4 : 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _selectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: rule.enabled,
                    onChanged: (value) => _toggle(rule, value),
                  ),
                  if (reorderable)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsetsDirectional.only(start: 4),
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  PopupMenuButton<_ReplaceRuleAction>(
                    onSelected: (action) => switch (action) {
                      _ReplaceRuleAction.copy => _copyRule(rule),
                      _ReplaceRuleAction.top => _moveRule(rule, toTop: true),
                      _ReplaceRuleAction.bottom => _moveRule(
                        rule,
                        toTop: false,
                      ),
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ReplaceRuleAction.copy,
                        child: Text(l10n.replaceRulesCopyJson),
                      ),
                      PopupMenuItem(
                        value: _ReplaceRuleAction.top,
                        enabled: rule.id != _service.rules.firstOrNull?.id,
                        child: Text(l10n.replaceRulesMoveTop),
                      ),
                      PopupMenuItem(
                        value: _ReplaceRuleAction.bottom,
                        enabled: rule.id != _service.rules.lastOrNull?.id,
                        child: Text(l10n.replaceRulesMoveBottom),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

enum _ReplaceRulesMenuAction { import, export, paste, select }

enum _ReplaceRuleAction { copy, top, bottom }

class _EmptyRules extends StatelessWidget {
  const _EmptyRules({required this.title, this.body, this.onCreate});
  final String title;
  final String? body;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18)),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(body!, textAlign: TextAlign.center),
          ],
          if (onCreate != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.replaceRulesCreate),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ReplaceRuleEditor extends StatefulWidget {
  const _ReplaceRuleEditor({required this.service, this.rule});

  final ReplaceRuleService service;
  final ReplaceRule? rule;

  @override
  State<_ReplaceRuleEditor> createState() => _ReplaceRuleEditorState();
}

class _ReplaceRuleEditorState extends State<_ReplaceRuleEditor> {
  late final TextEditingController _name;
  late final TextEditingController _pattern;
  late final TextEditingController _replacement;
  late final TextEditingController _group;
  late final TextEditingController _scope;
  late final TextEditingController _excludeScope;
  late final TextEditingController _timeout;
  late bool _isRegex;
  late bool _scopeTitle;
  late bool _scopeContent;

  bool get _isPersisted =>
      widget.rule != null &&
      widget.service.rules.any((rule) => rule.id == widget.rule!.id);

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _name = TextEditingController(text: rule?.name ?? '');
    _pattern = TextEditingController(text: rule?.pattern ?? '');
    _replacement = TextEditingController(text: rule?.replacement ?? '');
    _group = TextEditingController(text: rule?.group ?? '');
    _scope = TextEditingController(text: rule?.scope ?? '');
    _excludeScope = TextEditingController(text: rule?.excludeScope ?? '');
    _timeout = TextEditingController(
      text: '${rule?.timeoutMillisecond ?? 3000}',
    );
    _isRegex = rule?.isRegex ?? false;
    _scopeTitle = rule?.scopeTitle ?? false;
    _scopeContent = rule?.scopeContent ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _pattern,
      _replacement,
      _group,
      _scope,
      _excludeScope,
      _timeout,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final timeout = int.tryParse(_timeout.text.trim());
    if (timeout == null || timeout <= 0) {
      showSideToast(
        context,
        context.l10n.replaceRulesTimeoutInvalid,
        kind: SideToastKind.error,
      );
      return;
    }
    final rule = ReplaceRule(
      id: widget.rule?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      pattern: _pattern.text,
      replacement: _replacement.text,
      group: _group.text.trim(),
      scope: _scope.text.trim(),
      excludeScope: _excludeScope.text.trim(),
      enabled: widget.rule?.enabled ?? true,
      isRegex: _isRegex,
      scopeTitle: _scopeTitle,
      scopeContent: _scopeContent,
      order: widget.rule?.order ?? 0,
      timeoutMillisecond: timeout,
    );
    try {
      ReplaceRuleService.validate(rule);
      Navigator.of(context).pop(rule);
    } catch (error) {
      showSideToast(context, _localizedError(error), kind: SideToastKind.error);
    }
  }

  String _localizedError(Object error) {
    final l10n = context.l10n;
    if (error is ReplaceRuleValidationException) {
      return switch (error.kind) {
        ReplaceRuleValidationKind.emptyPattern =>
          l10n.replaceRulesPatternRequired,
        ReplaceRuleValidationKind.patternTooLong =>
          l10n.replaceRulesPatternTooLong(ReplaceRuleService.maxPatternLength),
        ReplaceRuleValidationKind.invalidRegex => l10n.replaceRulesInvalidRegex(
          error.message,
        ),
        ReplaceRuleValidationKind.tooManyRules => l10n.replaceRulesTooMany(
          ReplaceRuleService.maxRules,
        ),
        ReplaceRuleValidationKind.missingTarget =>
          l10n.replaceRulesMissingTarget,
        ReplaceRuleValidationKind.unsupportedReplacement =>
          l10n.replaceRulesUnsupportedReplacement,
      };
    }
    return error.toString().replaceFirst('FormatException: ', '');
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replaceRulesDeleteConfirmTitle),
        content: Text(l10n.replaceRulesDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replaceRulesDeleteValue),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await widget.service.remove(widget.rule!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        showSideToast(
          context,
          _localizedError(error),
          kind: SideToastKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        alignment: Alignment.bottomCenter,
        child: Material(
          key: const ValueKey('replace-rule-editor-sheet'),
          color: scheme.surface,
          surfaceTintColor: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                key: const ValueKey('replace-rule-editor-drag-handle'),
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.rule == null || !_isPersisted
                            ? l10n.replaceRulesCreateTitle
                            : l10n.replaceRulesEditTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  key: const ValueKey('replace-rule-editor-fields'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('replace-rule-pattern'),
                      controller: _pattern,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesPatternLabel,
                        helperText: l10n.replaceRulesPatternHelper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _replacement,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesReplacementLabel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.replaceRulesRegexLabel),
                      value: _isRegex,
                      onChanged: (value) => setState(() => _isRegex = value),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('replace-rule-scope-title'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.replaceRulesScopeTitleLabel),
                      value: _scopeTitle,
                      onChanged: (value) =>
                          setState(() => _scopeTitle = value ?? false),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('replace-rule-scope-content'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.replaceRulesScopeContentLabel),
                      value: _scopeContent,
                      onChanged: (value) =>
                          setState(() => _scopeContent = value ?? true),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _group,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesGroupLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _scope,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesScopeLabel,
                        helperText: l10n.replaceRulesScopeHelper,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _excludeScope,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesExcludeScopeLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('replace-rule-timeout'),
                      controller: _timeout,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.replaceRulesTimeoutLabel,
                        helperText: l10n.replaceRulesTimeoutHelper,
                        suffixText: 'ms',
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    if (_isPersisted) ...[
                      OutlinedButton.icon(
                        key: const ValueKey('replace-rule-editor-delete'),
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.replaceRulesDeleteValue),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('replace-rule-editor-save'),
                        onPressed: _submit,
                        icon: const Icon(Icons.check),
                        label: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
