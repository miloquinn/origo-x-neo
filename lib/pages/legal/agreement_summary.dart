import 'dart:async';

import 'package:flutter/material.dart';

import 'package:xxread/models/legal_document.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';

import 'legal_copy.dart';
import 'legal_document_page.dart';

/// Compact legal summaries used by the final welcome step.
///
/// When a catalog is supplied it is treated as the parent's fixed acceptance
/// snapshot. Replay surfaces may omit it; in that case this widget loads the
/// offline copy first and checks for a fresher catalog in the background.
class AgreementSummary extends StatefulWidget {
  const AgreementSummary({
    super.key,
    this.catalog,
    this.repository,
    this.source,
    this.checkedAt,
  });

  final LegalCatalog? catalog;
  final LegalDocumentRepository? repository;
  final LegalContentSource? source;
  final DateTime? checkedAt;

  @override
  State<AgreementSummary> createState() => _AgreementSummaryState();
}

class _AgreementSummaryState extends State<AgreementSummary> {
  LegalCatalogSnapshot? _snapshot;
  Object? _error;
  String? _locale;

  LegalDocumentRepository get _repository =>
      widget.repository ?? LegalDocumentRepository.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.catalog != null) return;
    final locale = Localizations.localeOf(context).toLanguageTag();
    if (_locale == locale) return;
    _locale = locale;
    unawaited(_load(locale));
  }

  @override
  void didUpdateWidget(covariant AgreementSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.catalog != oldWidget.catalog && widget.catalog != null) {
      _snapshot = null;
      _error = null;
    }
  }

  Future<void> _load(String locale) async {
    setState(() {
      _error = null;
      _snapshot = null;
    });
    try {
      final snapshot = await _repository.load(locale: locale);
      if (!mounted || _locale != locale || widget.catalog != null) return;
      setState(() => _snapshot = snapshot);
      unawaited(_refresh(locale));
    } catch (error) {
      if (!mounted || _locale != locale || widget.catalog != null) return;
      setState(() => _error = error);
    }
  }

  Future<void> _refresh(String locale) async {
    try {
      final snapshot = await _repository.refresh(locale: locale);
      if (!mounted || _locale != locale || widget.catalog != null) return;
      setState(() => _snapshot = snapshot);
    } catch (_) {
      // The bundled or cached snapshot stays visible.
    }
  }

  void _open(LegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LegalDocumentPage(
          document: document,
          repository: _repository,
          source: widget.catalog == null ? _snapshot?.source : widget.source,
          checkedAt: widget.catalog == null
              ? _snapshot?.checkedAt
              : widget.checkedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = LegalCopy.of(context);
    final catalog = widget.catalog ?? _snapshot?.catalog;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          copy.agreementTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          copy.agreementSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        if (catalog == null && _error == null)
          for (var index = 0; index < 3; index++) ...[
            _LoadingCard(label: copy.loading),
            if (index != 2) const SizedBox(height: 8),
          ]
        else if (catalog == null)
          _ErrorCard(
            message: copy.loadFailed,
            retryLabel: copy.retry,
            onRetry: () => _load(_locale!),
          )
        else
          for (final entry in const [
            ('terms', 'agreementTermsDisclosure', Icons.article_outlined),
            ('sources', 'agreementSourceDisclosure', Icons.hub_outlined),
            ('privacy', 'agreementPrivacyDisclosure', Icons.shield_outlined),
          ].indexed) ...[
            if (catalog.document(entry.$2.$1) case final document?)
              _SummaryCard(
                cardKey: Key(entry.$2.$2),
                icon: entry.$2.$3,
                document: document,
                actionLabel: copy.openDetails,
                onTap: () => _open(document),
              ),
            if (entry.$1 != 2) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cardKey,
    required this.icon,
    required this.document,
    required this.actionLabel,
    required this.onTap,
  });

  final Key cardKey;
  final IconData icon;
  final LegalDocument document;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      key: cardKey,
      color: scheme.surface.withValues(alpha: 0.52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      actionLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 82),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(message),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
    ],
  );
}
