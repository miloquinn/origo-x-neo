import 'dart:async';

import 'package:flutter/material.dart';

import 'package:xxread/models/legal_document.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

import 'legal_copy.dart';
import 'legal_document_page.dart';

class LegalDocumentsPage extends StatefulWidget {
  const LegalDocumentsPage({super.key, this.repository});

  final LegalDocumentRepository? repository;

  @override
  State<LegalDocumentsPage> createState() => _LegalDocumentsPageState();
}

class _LegalDocumentsPageState extends State<LegalDocumentsPage> {
  LegalCatalogSnapshot? _snapshot;
  Object? _loadError;
  String? _locale;
  Object? _refreshToken;
  int _generation = 0;

  bool get _refreshing => _refreshToken != null;

  LegalDocumentRepository get _repository =>
      widget.repository ?? LegalDocumentRepository.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale == locale) return;
    _locale = locale;
    unawaited(_load(locale));
  }

  Future<void> _load(String locale) async {
    final generation = ++_generation;
    setState(() {
      _loadError = null;
      _snapshot = null;
      _refreshToken = null;
    });
    try {
      final snapshot = await _repository.load(locale: locale);
      if (!mounted || _locale != locale || _generation != generation) return;
      setState(() => _snapshot = snapshot);
      unawaited(_refresh(locale: locale, generation: generation));
    } catch (error) {
      if (!mounted || _locale != locale || _generation != generation) return;
      setState(() => _loadError = error);
    }
  }

  Future<void> _refresh({String? locale, int? generation}) async {
    locale ??= _locale;
    generation ??= _generation;
    if (locale == null || _refreshing) return;
    final token = Object();
    setState(() => _refreshToken = token);
    try {
      final snapshot = await _repository.refresh(locale: locale, force: true);
      if (!mounted ||
          _locale != locale ||
          _generation != generation ||
          !identical(_refreshToken, token)) {
        return;
      }
      setState(() => _snapshot = snapshot);
    } catch (_) {
      // The repository's load result remains usable offline.
    } finally {
      if (mounted && identical(_refreshToken, token)) {
        setState(() => _refreshToken = null);
      }
    }
  }

  void _openDocument(LegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(
          document: document,
          repository: _repository,
          source: _snapshot?.source,
          checkedAt: _snapshot?.checkedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    return FloatingSubpageScaffold(
      title: copy.hubTitle,
      actions: [
        FloatingSubpageAction(
          key: const ValueKey('legal-documents-refresh'),
          icon: _refreshing
              ? Icons.hourglass_top_rounded
              : Icons.refresh_rounded,
          tooltip: _refreshing ? copy.refreshing : copy.refresh,
          onPressed: _refreshing ? null : _refresh,
        ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final copy = LegalCopy.of(context);
    if (_snapshot == null && _loadError == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_snapshot == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 42),
              const SizedBox(height: 12),
              Text(copy.loadFailed, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _load(_locale!),
                child: Text(copy.retry),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _snapshot!;
    final documents = _orderedDocuments(snapshot.catalog.documents);
    final fallback = !_catalogMatchesLocale(snapshot.catalog.locale, _locale!);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const ValueKey('legal-documents-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: floatingSubpagePadding(context, bottom: 48),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy.hubSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CatalogStatus(snapshot: snapshot, fallback: fallback),
                  const SizedBox(height: 18),
                  for (final document in documents) ...[
                    _LegalDocumentCard(
                      document: document,
                      onTap: () => _openDocument(document),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogStatus extends StatelessWidget {
  const _CatalogStatus({required this.snapshot, required this.fallback});

  final LegalCatalogSnapshot snapshot;
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sourceText = switch (snapshot.source) {
      LegalContentSource.bundled => copy.bundledCopy,
      LegalContentSource.cache => copy.cachedCopy,
      LegalContentSource.network => copy.onlineCopy,
    };
    final notices = <String>[
      sourceText,
      if (snapshot.refreshError) copy.refreshFailed,
      if (fallback) copy.fallbackLanguage,
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notices.join('\n'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({required this.document, required this.onTap});

  final LegalDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('legal-document-${document.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _iconForDocument(document.id),
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      document.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '${copy.version} ${document.revision}  ·  '
                      '${copy.updatedDate} ${_formatDate(document.updatedAt)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<LegalDocument> _orderedDocuments(List<LegalDocument> documents) {
  const order = <String>[
    'terms',
    'privacy',
    'sources',
    'membership',
    'privacyChoices',
    'third-party-services',
  ];
  final rank = <String, int>{
    for (var i = 0; i < order.length; i++) order[i]: i,
  };
  final result = List<LegalDocument>.of(documents);
  result.sort((a, b) {
    final byRank = (rank[a.id] ?? order.length).compareTo(
      rank[b.id] ?? order.length,
    );
    return byRank != 0 ? byRank : a.title.compareTo(b.title);
  });
  return result;
}

IconData _iconForDocument(String id) => switch (id) {
  'terms' => Icons.article_outlined,
  'privacy' => Icons.shield_outlined,
  'sources' => Icons.hub_outlined,
  'membership' => Icons.workspace_premium_outlined,
  'privacyChoices' => Icons.tune_rounded,
  'third-party-services' => Icons.extension_outlined,
  _ => Icons.description_outlined,
};

bool _catalogMatchesLocale(String catalogLocale, String requestedLocale) =>
    catalogLocale.toLowerCase() == requestedLocale.toLowerCase() ||
    catalogLocale.split('-').first.toLowerCase() ==
        requestedLocale.split('-').first.toLowerCase();

String _formatDate(Object value) {
  if (value is DateTime) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
  return value.toString().split('T').first;
}
