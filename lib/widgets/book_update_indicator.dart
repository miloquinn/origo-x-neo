import 'package:flutter/material.dart';

import '../book_sources/models/source_book_update_info.dart';
import '../models/book.dart';
import '../utils/localization_extension.dart';

/// A small, consistent update marker in every library cover layout.
class BookUpdateIndicator extends StatelessWidget {
  const BookUpdateIndicator({
    super.key,
    required this.book,
    required this.child,
  });

  final Book book;
  final Widget child;

  static bool hasUpdate(Book book) =>
      SourceBookUpdateInfo.fromBook(book).hasNewChapters;

  @override
  Widget build(BuildContext context) {
    final updates = SourceBookUpdateInfo.fromBook(book);
    if (!updates.hasNewChapters) return child;
    final count = updates.newChapterCount;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBadgeWidth = (constraints.maxWidth - 8).clamp(
          0.0,
          double.infinity,
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: count > 0
                    ? '${context.l10n.bookSourceUpdatesAvailable} · '
                          '${context.l10n.bookSourceChangeChapterCount(count)}'
                    : context.l10n.bookSourceUpdatesAvailable,
                child: Container(
                  key: const ValueKey('book-cover-update-indicator'),
                  constraints: BoxConstraints(
                    minWidth: maxBadgeWidth.clamp(0.0, 18.0),
                    maxWidth: maxBadgeWidth,
                    minHeight: 18,
                  ),
                  padding: count > 0
                      ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.surface, width: 1.5),
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: count > 0
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$count',
                              maxLines: 1,
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontSize: 10,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.update_rounded,
                            size: 11,
                            color: scheme.onPrimary,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
