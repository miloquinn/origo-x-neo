import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-width book metadata, independent of the cover's text column.
class BookDetailsTags extends StatefulWidget {
  const BookDetailsTags({super.key, this.status, this.categories = const []});

  final String? status;
  final List<String> categories;

  @override
  State<BookDetailsTags> createState() => _BookDetailsTagsState();
}

class _BookDetailsTagsState extends State<BookDetailsTags> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.status?.trim() ?? '';
    final labels = <String>{
      if (status.isNotEmpty) status,
      for (final category in widget.categories)
        if (category.trim().isNotEmpty) category.trim(),
    }.toList();
    if (labels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium!;
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final localizations = MaterialLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        var row = 1;
        var usedWidth = 0.0;
        var visibleCount = 0;
        for (final label in labels) {
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: direction,
            textScaler: textScaler,
            locale: Localizations.maybeLocaleOf(context),
            maxLines: 1,
          )..layout();
          final chipWidth = math.min(width, painter.width + 24);
          painter.dispose();
          final spacing = usedWidth == 0 ? 0 : 8;
          if (usedWidth + spacing + chipWidth > width + 0.01) {
            if (row == 2) break;
            row++;
            usedWidth = chipWidth;
          } else {
            usedWidth += spacing + chipWidth;
          }
          visibleCount++;
        }

        final canExpand = visibleCount < labels.length;
        final visible = _expanded ? labels : labels.take(visibleCount);
        final tags = Wrap(
          key: const ValueKey('book-details-tags'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in visible)
              Tooltip(
                message: label,
                excludeFromSemantics: true,
                child: Container(
                  constraints: BoxConstraints(maxWidth: width),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: label == status
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style.copyWith(
                      color: label == status
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.disableAnimationsOf(context))
              tags
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: AlignmentDirectional.topStart,
                child: tags,
              ),
            if (canExpand) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                key: const ValueKey('book-details-tags-toggle'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  _expanded
                      ? localizations.expandedIconTapHint
                      : '${localizations.collapsedIconTapHint} (${labels.length})',
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
