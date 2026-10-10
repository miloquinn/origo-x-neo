import 'package:flutter/material.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_shelf_service.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/pages/book_sources/widgets/book_source_text_normalizer.dart';
import 'package:xxread/utils/localization_extension.dart';

import 'book_details_header.dart';

class LibraryBookInfoSheet extends StatelessWidget {
  const LibraryBookInfoSheet({
    super.key,
    required this.book,
    required this.cover,
    this.sourceBook,
    this.sourceLabel,
    this.sourceStatus,
    this.metadataUnavailable = false,
  });

  factory LibraryBookInfoSheet.fromShelf({
    required Book book,
    required Widget cover,
    required BookSourceShelfService shelfService,
    Widget? sourceStatus,
  }) {
    BookSourceBook? sourceBook;
    String? sourceLabel;
    var metadataUnavailable = false;
    if (book.hasSourceBinding) {
      try {
        final binding = shelfService.bindingFrom(book);
        sourceBook = binding.book;
        sourceLabel = binding.source.name;
      } on OnlineShelfBookBindingException catch (error) {
        metadataUnavailable = true;
        debugPrint('Book details metadata unavailable (${error.runtimeType}).');
      }
    }
    return LibraryBookInfoSheet(
      book: book,
      cover: cover,
      sourceBook: sourceBook,
      sourceLabel: sourceLabel,
      sourceStatus: sourceStatus,
      metadataUnavailable: metadataUnavailable,
    );
  }

  final Book book;
  final Widget cover;
  final BookSourceBook? sourceBook;
  final String? sourceLabel;
  final Widget? sourceStatus;
  final bool metadataUnavailable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final description = normalizeBookSourceDescription(
      sourceBook?.description ?? '',
    );
    final isOnline = book.isOnline;
    final totalLabel = isOnline ? l10n.totalChapters : l10n.totalPages;
    final currentLabel = isOnline ? l10n.currentChapter : l10n.currentPage;
    final totalValue = isOnline
        ? l10n.libraryChaptersCount(
            (book.totalPages / BookSourceShelfService.unitsPerChapter).round(),
          )
        : l10n.libraryPagesCount(book.totalPages);
    final currentValue = isOnline
        ? l10n.libraryChaptersCount(
            (book.currentPage / BookSourceShelfService.unitsPerChapter).round(),
          )
        : l10n.libraryPagesCount(book.currentPage);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              key: const Key('library-book-info-scroll'),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookDetailsHeader(
                    title: book.title,
                    author: book.author,
                    cover: cover,
                    sourceLabel: sourceLabel,
                    status: sourceBook?.status,
                    categories: sourceBook?.categories ?? const [],
                    framed: false,
                  ),
                  if (metadataUnavailable) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.bookSourceDetailsLoadFailed,
                        key: const Key('library-book-info-metadata-error'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      l10n.bookSourceDetailsDescription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.libraryBookInfo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BookStatistics(
                    items: [
                      (
                        label: l10n.libraryFormat,
                        value: book.format.toUpperCase(),
                      ),
                      (label: totalLabel, value: totalValue),
                      (label: currentLabel, value: currentValue),
                      (
                        label: l10n.readingProgress,
                        value: '${(book.progress * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                  if (sourceStatus != null) ...[
                    const SizedBox(height: 20),
                    sourceStatus!,
                  ],
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          SafeArea(
            key: const Key('library-book-info-footer'),
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.libraryClose),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookStatistics extends StatelessWidget {
  const _BookStatistics({required this.items});

  final List<({String label, String value})> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _BookStatistic(label: item.label, value: item.value),
              ),
          ],
        );
      },
    );
  }
}

class _BookStatistic extends StatelessWidget {
  const _BookStatistic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
