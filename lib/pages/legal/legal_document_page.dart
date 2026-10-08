import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:xxread/models/legal_document.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

import 'legal_copy.dart';

class LegalDocumentSupplement {
  const LegalDocumentSupplement({required this.title, required this.body});

  final String title;
  final String body;
}

/// Displays one immutable legal snapshot.
///
/// A background check may announce a newer revision, but the text is replaced
/// only after the reader explicitly chooses to switch versions.
class LegalDocumentPage extends StatefulWidget {
  const LegalDocumentPage({
    super.key,
    required this.document,
    this.repository,
    this.source,
    this.checkedAt,
    this.checkForUpdates = true,
    this.additionalSections = const [],
  });

  final LegalDocument document;
  final LegalDocumentRepository? repository;
  final LegalContentSource? source;
  final DateTime? checkedAt;
  final bool checkForUpdates;
  final List<LegalDocumentSupplement> additionalSections;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  late LegalDocument _document;
  late List<GlobalKey> _sectionKeys;
  LegalContentSource? _source;
  DateTime? _checkedAt;
  LegalDocument? _availableUpdate;
  LegalContentSource? _availableSource;
  DateTime? _availableCheckedAt;
  bool _checkedForUpdate = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _source = widget.source;
    _checkedAt = widget.checkedAt;
    _resetSectionKeys();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedForUpdate || !widget.checkForUpdates) return;
    _checkedForUpdate = true;
    unawaited(_checkForUpdate());
  }

  void _resetSectionKeys() {
    _sectionKeys = List<GlobalKey>.generate(
      _document.sections.length + widget.additionalSections.length,
      (_) => GlobalKey(),
    );
  }

  Future<void> _checkForUpdate() async {
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final snapshot =
          await (widget.repository ?? LegalDocumentRepository.instance).refresh(
            locale: locale,
          );
      if (!mounted) return;
      final candidate = snapshot.catalog.document(_document.id);
      if (candidate != null && candidate.revision != _document.revision) {
        setState(() {
          _availableUpdate = candidate;
          _availableSource = snapshot.source;
          _availableCheckedAt = snapshot.checkedAt;
        });
      } else if (candidate != null) {
        setState(() {
          _source = snapshot.source;
          _checkedAt = snapshot.checkedAt;
        });
      }
    } catch (_) {
      // The displayed snapshot remains complete and readable offline.
    }
  }

  void _showAvailableUpdate() {
    final update = _availableUpdate;
    if (update == null) return;
    setState(() {
      _document = update;
      _source = _availableSource;
      _checkedAt = _availableCheckedAt;
      _availableUpdate = null;
      _availableSource = null;
      _availableCheckedAt = null;
      _resetSectionKeys();
    });
  }

  Future<void> _scrollToSection(int index) async {
    final sectionContext = _sectionKeys[index].currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _openUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sections = <({String title, Widget body})>[
      for (final section in _document.sections)
        (
          title: section.title,
          body: _CatalogSectionBody(section: section, onOpenUri: _openUri),
        ),
      for (final section in widget.additionalSections)
        (title: section.title, body: Text(section.body)),
    ];

    return FloatingSubpageScaffold(
      title: _document.title,
      actions: [
        FloatingSubpageAction(
          key: const ValueKey('legal-open-canonical'),
          icon: Icons.open_in_browser_rounded,
          tooltip: copy.officialCopy,
          onPressed: () => _openUri(_document.canonicalUrl),
        ),
      ],
      body: SingleChildScrollView(
        key: const ValueKey('legal-document-scroll'),
        padding: floatingSubpagePadding(context, bottom: 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _document.summary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      height: 1.55,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MetadataCard(document: _document),
                  if (_source case final source?) ...[
                    const SizedBox(height: 12),
                    _SourceNotice(source: source, checkedAt: _checkedAt),
                  ],
                  if (_usesFallbackLanguage(
                    Localizations.localeOf(context),
                    _document.locale,
                  )) ...[
                    const SizedBox(height: 12),
                    _StatusNotice(
                      icon: Icons.translate_rounded,
                      text: copy.fallbackLanguage,
                    ),
                  ],
                  if (_availableUpdate != null) ...[
                    const SizedBox(height: 12),
                    _UpdateNotice(onShowUpdate: _showAvailableUpdate),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    copy.contents,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < sections.length; index++)
                        ActionChip(
                          key: ValueKey('legal-section-link-$index'),
                          avatar: Text('${index + 1}'),
                          label: Text(sections[index].title),
                          onPressed: () => _scrollToSection(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  for (var index = 0; index < sections.length; index++) ...[
                    _DocumentSection(
                      key: _sectionKeys[index],
                      index: index,
                      title: sections[index].title,
                      body: sections[index].body,
                    ),
                    if (index != sections.length - 1)
                      Divider(
                        height: 42,
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                  ],
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    key: const ValueKey('legal-official-copy-link'),
                    onPressed: () => _openUri(_document.canonicalUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(copy.officialCopy),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _MetadataItem(label: copy.version, value: document.revision),
                _MetadataItem(
                  label: copy.effectiveDate,
                  value: _formatLegalDate(document.effectiveDate),
                ),
                _MetadataItem(
                  label: copy.updatedDate,
                  value: _formatLegalDate(document.updatedAt),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              copy.changes,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            if (document.changeSummary.isEmpty)
              Text(copy.noChanges)
            else
              for (final change in document.changeSummary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(change)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _SourceNotice extends StatelessWidget {
  const _SourceNotice({required this.source, this.checkedAt});

  final LegalContentSource source;
  final DateTime? checkedAt;

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final text = switch (source) {
      LegalContentSource.bundled => copy.bundledCopy,
      LegalContentSource.cache => copy.cachedCopy,
      LegalContentSource.network => copy.onlineCopy,
    };
    final suffix = checkedAt == null
        ? ''
        : '\n${copy.lastChecked}: ${_formatLegalDate(checkedAt!)}';
    return _StatusNotice(
      icon: Icons.offline_pin_outlined,
      text: '$text$suffix',
    );
  }
}

class _UpdateNotice extends StatelessWidget {
  const _UpdateNotice({required this.onShowUpdate});

  final VoidCallback onShowUpdate;

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    return _StatusNotice(
      icon: Icons.update_rounded,
      text: copy.updateAvailable,
      action: TextButton(onPressed: onShowUpdate, child: Text(copy.showUpdate)),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
            if (action != null) ...[const SizedBox(width: 8), action!],
          ],
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  const _DocumentSection({
    super.key,
    required this.index,
    required this.title,
    required this.body,
  });

  final int index;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${index + 1}. $title',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 12),
      DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.75),
        child: body,
      ),
    ],
  );
}

class _CatalogSectionBody extends StatelessWidget {
  const _CatalogSectionBody({required this.section, required this.onOpenUri});

  final LegalSection section;
  final ValueChanged<Uri> onOpenUri;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final paragraph in section.paragraphs) ...[
        Text(paragraph),
        const SizedBox(height: 13),
      ],
      for (final bullet in section.bullets)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text(bullet)),
            ],
          ),
        ),
      if (section.links.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final link in section.links)
              OutlinedButton.icon(
                onPressed: () => onOpenUri(link.href),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(link.label),
              ),
          ],
        ),
      ],
    ],
  );
}

String _formatLegalDate(Object value) {
  if (value is DateTime) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
  return value.toString().split('T').first;
}

bool _usesFallbackLanguage(Locale requested, String documentLocale) {
  final language = requested.languageCode.toLowerCase();
  if (language == 'zh') return documentLocale != 'zh-CN';
  if (language == 'en') return documentLocale != 'en';
  return true;
}
