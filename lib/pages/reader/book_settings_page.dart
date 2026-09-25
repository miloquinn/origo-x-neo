import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../library/source_book_status_card.dart';

import '../../book_sources/models/registered_book_source.dart';
import '../../book_sources/services/book_source_client.dart';
import '../../book_sources/source_engine/source_config.dart';
import '../../book_sources/source_engine/source_login_session.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../book_sources/source_login_page.dart';
import '../book_sources/widgets/book_source_text_normalizer.dart';

enum BookSettingsAction { editText, changeSource, readingSettings }

/// Reader-specific book management, separate from the discovery details page.
class BookSettingsPage extends StatefulWidget {
  const BookSettingsPage({
    super.key,
    required this.title,
    required this.author,
    required this.cover,
    required this.format,
    this.shelfBook,
    this.onBookChanged,
    this.description = '',
    this.canEditText = false,
    this.canChangeSource = false,
    this.source,
    this.client,
    this.loginSessionStore,
  });

  final ValueChanged<Book>? onBookChanged;
  final Book? shelfBook;
  final String title;
  final String author;
  final Widget cover;
  final String format;
  final String description;
  final bool canEditText;
  final bool canChangeSource;
  final RegisteredBookSource? source;
  final BookSourceClient? client;
  final SourceLoginSessionStore? loginSessionStore;

  @override
  State<BookSettingsPage> createState() => _BookSettingsPageState();
}

class _BookSettingsPageState extends State<BookSettingsPage> {
  late Book? _book = widget.shelfBook;
  RegisteredBookSource? get _source {
    try {
      return _book?.hasSourceBinding == true
          ? RegisteredBookSource.fromJson(
              jsonDecode(_book!.sourceJson!) as Map<String, dynamic>,
            )
          : widget.source;
    } catch (_) {
      return widget.source;
    }
  }

  bool _loggedIn = false;
  bool _loadingLogin = true;
  bool _descriptionExpanded = false;

  String _copy(String zh, String en, String ja) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'ja' => ja,
        _ => zh,
      };

  @override
  void initState() {
    super.initState();
    _refreshLogin();
  }

  Future<void> _refreshLogin() async {
    final config = _source?.sourceConfig;
    var loggedIn = false;
    try {
      if (config != null) {
        final session =
            await (widget.loginSessionStore ?? SecureSourceLoginSessionStore())
                .read(ReadingSourceConfig.fromJson(config).stableId);
        loggedIn =
            session.browserSession.active ||
            session.loginInfo.isNotEmpty ||
            session.loginHeaders.isNotEmpty;
      }
    } catch (_) {
      // Secure storage can be unavailable; keep the login entry usable.
    }
    if (mounted) {
      setState(() {
        _loggedIn = loggedIn;
        _loadingLogin = false;
      });
    }
  }

  Future<void> _login() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            SourceLoginPage(source: _source!, client: widget.client),
      ),
    );
    if (mounted) await _refreshLogin();
  }

  Widget _action(
    IconData icon,
    String title,
    BookSettingsAction action, {
    bool enabled = true,
    String? subtitle,
    Key? key,
  }) => _BookSettingsActionCard(
    key: key,
    icon: icon,
    title: title,
    subtitle: subtitle,
    enabled: enabled,
    onTap: enabled ? () => Navigator.of(context).pop(action) : null,
  );

  List<Widget> _actions() => [
    _action(
      Icons.edit_note_rounded,
      _copy('编辑正文', 'Edit text', '本文を編集'),
      BookSettingsAction.editText,
      key: const Key('book-settings-edit-action'),
      enabled: widget.canEditText,
      subtitle: widget.canEditText
          ? null
          : _copy(
              '仅本地 TXT 书籍可用',
              'Available for local TXT books only',
              'ローカル TXT 書籍のみ対応',
            ),
    ),
    if (widget.canChangeSource)
      _action(
        Icons.swap_horiz_rounded,
        context.l10n.bookSourceChangeSourceTitle,
        BookSettingsAction.changeSource,
        key: const Key('book-settings-change-source-action'),
      ),
    if (_source != null)
      _BookSettingsActionCard(
        key: const Key('book-settings-login-action'),
        icon: Icons.account_circle_outlined,
        title: _loggedIn
            ? _copy('已登录', 'Logged in', 'ログイン済み')
            : context.l10n.sourceLoginTitle,
        subtitle: _loggedIn ? context.l10n.sourceLoginTitle : null,
        loading: _loadingLogin,
        onTap: _login,
      ),
    _action(
      Icons.tune_rounded,
      context.l10n.readingSettings,
      BookSettingsAction.readingSettings,
      key: const Key('book-settings-reading-action'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final normalizedDescription = normalizeBookSourceDescription(
      widget.description,
    );
    return FloatingSubpageScaffold(
      key: const Key('book-settings-page'),
      title: _copy('书籍设置', 'Book settings', '書籍設定'),
      maxHeaderWidth: 920,
      body: SingleChildScrollView(
        key: const Key('book-settings-scroll'),
        padding: floatingSubpagePadding(context, left: 20, right: 20, top: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 872),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BookIdentity(
                  title: widget.title,
                  author: widget.author,
                  sourceLabel: _source?.name ?? widget.format.toUpperCase(),
                  cover: _book?.coverImagePath != null && !kIsWeb
                      ? Image.file(
                          File(_book!.coverImagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => widget.cover,
                        )
                      : widget.cover,
                ),
                if (normalizedDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _CollapsibleBookDescription(
                    description: normalizedDescription,
                    expanded: _descriptionExpanded,
                    onToggle: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                    showMoreLabel: _copy('展开', 'Show more', 'もっと見る'),
                    showLessLabel: _copy('收起', 'Show less', '閉じる'),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  _copy('书籍功能', 'Book actions', '書籍の操作'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _BookSettingsActionGrid(actions: _actions()),
                if (_book != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SourceBookStatusCard(
                      book: _book!,
                      allowSourceBinding: !widget.canChangeSource,
                      onBookChanged: (book) {
                        setState(() => _book = book);
                        widget.onBookChanged?.call(book);
                        _refreshLogin();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookIdentity extends StatelessWidget {
  const _BookIdentity({
    required this.title,
    required this.author,
    required this.sourceLabel,
    required this.cover,
  });

  final String title;
  final String author;
  final String sourceLabel;
  final Widget cover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480 || textScale > 1.35;
        final coverWidth = compact ? 84.0 : 104.0;
        final coverHeight = compact ? 118.0 : 146.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    key: const Key('book-settings-cover'),
                    width: coverWidth,
                    height: coverHeight,
                    child: cover,
                  ),
                ),
                SizedBox(width: compact ? 16 : 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        key: const Key('book-settings-title'),
                        maxLines: compact ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        author,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          child: Text(
                            sourceLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollapsibleBookDescription extends StatelessWidget {
  const _CollapsibleBookDescription({
    required this.description,
    required this.expanded,
    required this.onToggle,
    required this.showMoreLabel,
    required this.showLessLabel,
  });

  final String description;
  final bool expanded;
  final VoidCallback onToggle;
  final String showMoreLabel;
  final String showLessLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.65);
    return DecoratedBox(
      key: const Key('book-settings-description-card'),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bookSourceDetailsDescription,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final painter = TextPainter(
                  text: TextSpan(text: description, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  maxLines: 4,
                )..layout(maxWidth: constraints.maxWidth);
                final canExpand = painter.didExceedMaxLines;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      description,
                      key: const Key('book-settings-description'),
                      maxLines: expanded ? null : 4,
                      overflow: expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: style,
                    ),
                    if (canExpand || expanded)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          key: const Key('book-settings-description-toggle'),
                          onPressed: onToggle,
                          iconAlignment: IconAlignment.end,
                          icon: Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                          ),
                          label: Text(expanded ? showLessLabel : showMoreLabel),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookSettingsActionGrid extends StatelessWidget {
  const _BookSettingsActionGrid({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const Key('book-settings-action-grid'),
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final twoColumns = constraints.maxWidth >= 340 && textScale <= 1.25;
      if (!twoColumns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              actions[index],
              if (index != actions.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index += 2) ...[
            if (index + 1 < actions.length)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: actions[index]),
                    const SizedBox(width: 12),
                    Expanded(child: actions[index + 1]),
                  ],
                ),
              )
            else
              actions[index],
            if (index + 2 < actions.length) const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}

class _BookSettingsActionCard extends StatelessWidget {
  const _BookSettingsActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = enabled && onTap != null;
    return Opacity(
      opacity: active ? 1 : 0.56,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: active && !loading ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 124),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          color: active
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (loading)
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
