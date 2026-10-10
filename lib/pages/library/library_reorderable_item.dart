import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../utils/localization_extension.dart';
import 'library_organization.dart';

/// Keeps the existing card as the sole owner of its cover GlobalKey. The drag
/// overlay is a separate, small label so it never mounts a cover twice.
class LibraryReorderableItem extends StatelessWidget {
  const LibraryReorderableItem({
    super.key,
    required this.entry,
    required this.enabled,
    required this.child,
    this.targeted = false,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.onMoveEarlier,
    this.onMoveLater,
  });

  final LibraryShelfEntry entry;
  final bool enabled;
  final Widget child;
  final bool targeted;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback? onMoveEarlier;
  final VoidCallback? onMoveLater;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: entry.label,
      customSemanticsActions: {
        CustomSemanticsAction(label: context.l10n.libraryMoveEarlier):
            ?onMoveEarlier,
        CustomSemanticsAction(label: context.l10n.libraryMoveLater):
            ?onMoveLater,
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 2,
            color: targeted ? scheme.primary : Colors.transparent,
          ),
        ),
        child: LongPressDraggable<LibraryShelfEntry>(
          key: ValueKey('library-drag-${entry.key}'),
          data: entry,
          hitTestBehavior: HitTestBehavior.opaque,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          maxSimultaneousDrags: 1,
          onDragUpdate: (details) => onDragUpdate(details.globalPosition),
          onDragEnd: (_) => onDragEnd(),
          onDragCompleted: onDragEnd,
          onDraggableCanceled: (_, _) => onDragEnd(),
          feedback: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(18),
            color: scheme.primaryContainer,
            child: SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      entry.folder != null
                          ? Icons.folder_outlined
                          : Icons.menu_book_outlined,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
          child: Stack(
            children: [
              IgnorePointer(child: child),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
