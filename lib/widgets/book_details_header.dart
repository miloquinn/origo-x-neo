import 'package:flutter/material.dart';

import 'book_details_tags.dart';
import 'glass_surface.dart';

/// Shared book identity for an online page or an already-painted info sheet.
class BookDetailsHeader extends StatelessWidget {
  const BookDetailsHeader({
    super.key,
    required this.title,
    required this.author,
    required this.cover,
    this.sourceLabel,
    this.status,
    this.categories = const [],
    this.framed = true,
  });

  final String title;
  final String author;
  final Widget cover;
  final String? sourceLabel;
  final String? status;
  final List<String> categories;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTags =
        (status?.trim().isNotEmpty ?? false) ||
        categories.any((value) => value.trim().isNotEmpty);
    final artwork = SizedBox(
      key: const ValueKey('book-details-cover'),
      width: 112,
      height: 160,
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: cover),
    );
    final metadata = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          key: const ValueKey('book-details-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        if (author.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            author,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
        if (sourceLabel?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 10),
          Text(
            sourceLabel!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: artwork),
                  const SizedBox(height: 20),
                  metadata,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artwork,
                const SizedBox(width: 24),
                Expanded(child: metadata),
              ],
            );
          },
        ),
        if (hasTags) ...[
          const SizedBox(height: 20),
          BookDetailsTags(status: status, categories: categories),
        ],
      ],
    );
    if (!framed) return content;

    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );
    return GlassSurface(
      role: GlassSurfaceRole.panel,
      shape: shape,
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(20), child: content),
      ),
    );
  }
}
