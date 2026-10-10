import 'package:flutter/material.dart';

import '../../utils/localization_extension.dart';
import '../../widgets/app_skin_icon.dart';
import 'library_organization.dart';

class LibraryOrganizationChoice {
  const LibraryOrganizationChoice.sort(this.sort, this.descending)
    : filterIndex = null,
      reordering = false;
  const LibraryOrganizationChoice.filter(this.filterIndex)
    : sort = null,
      descending = true,
      reordering = false;
  const LibraryOrganizationChoice.reorder()
    : sort = LibrarySortMode.manual,
      descending = true,
      filterIndex = null,
      reordering = true;

  final LibrarySortMode? sort;
  final bool descending;
  final int? filterIndex;
  final bool reordering;
}

class LibraryOrganizationSheet extends StatelessWidget {
  const LibraryOrganizationSheet({
    super.key,
    required this.sort,
    required this.descending,
    required this.filterIndex,
    required this.filterLabels,
  });

  final LibrarySortMode sort;
  final bool descending;
  final int filterIndex;
  final List<String> filterLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    void choose(LibraryOrganizationChoice choice) =>
        Navigator.of(context).pop(choice);
    Widget heading(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return SingleChildScrollView(
      key: const ValueKey('library-organization-sheet'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.libraryOrganize,
              style: theme.textTheme.titleLarge,
            ),
          ),
          ListTile(
            key: const ValueKey('library-start-reordering'),
            leading: AppSkinIcon.adapt(
              const Icon(Icons.drag_indicator_rounded),
            ),
            title: Text(l10n.libraryDragOrganize),
            subtitle: Text(l10n.libraryDragHint),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => choose(const LibraryOrganizationChoice.reorder()),
          ),
          heading(l10n.librarySortHeading),
          for (final mode in LibrarySortMode.values)
            ListTile(
              key: ValueKey('library-sort-${mode.name}'),
              leading: AppSkinIcon.adapt(
                Icon(
                  sort == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: sort == mode ? theme.colorScheme.primary : null,
                ),
              ),
              title: Text(switch (mode) {
                LibrarySortMode.recentAdded => l10n.librarySortRecentAdded,
                LibrarySortMode.recentRead => l10n.librarySortRecentRead,
                LibrarySortMode.progress => l10n.librarySortProgress,
                LibrarySortMode.manual => l10n.librarySortManual,
              }),
              onTap: () =>
                  choose(LibraryOrganizationChoice.sort(mode, descending)),
            ),
          if (sort != LibrarySortMode.manual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final direction in [true, false])
                    ChoiceChip(
                      key: ValueKey('library-sort-descending-$direction'),
                      selected: descending == direction,
                      label: Text(
                        sort == LibrarySortMode.progress
                            ? (direction
                                  ? l10n.librarySortProgressDescending
                                  : l10n.librarySortProgressAscending)
                            : (direction
                                  ? l10n.librarySortNewestFirst
                                  : l10n.librarySortOldestFirst),
                      ),
                      onSelected: (_) => choose(
                        LibraryOrganizationChoice.sort(sort, direction),
                      ),
                    ),
                ],
              ),
            ),
          heading(l10n.libraryReadingStateHeading),
          for (var index = 0; index < filterLabels.length; index++)
            ListTile(
              key: ValueKey('library-reading-filter-$index'),
              leading: AppSkinIcon.adapt(
                Icon(
                  filterIndex == index
                      ? Icons.check_circle_outline_rounded
                      : Icons.circle_outlined,
                  color: filterIndex == index
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
              title: Text(filterLabels[index]),
              onTap: () => choose(LibraryOrganizationChoice.filter(index)),
            ),
        ],
      ),
    );
  }
}
