import 'package:flutter/material.dart';
import 'package:xxread/widgets/app_skin_icon.dart';

import '../../utils/localization_extension.dart';

/// The same book actions are used by mobile, tablet and desktop shelves.
class LibrarySelectionActions extends StatelessWidget {
  const LibrarySelectionActions({
    super.key,
    required this.selectedCount,
    required this.onCreateFolder,
    required this.onMove,
    required this.onDelete,
  });

  final int selectedCount;
  final VoidCallback onCreateFolder;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final enabled = selectedCount > 0;
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const ValueKey('library-create-folder-selected'),
            onPressed: enabled ? onCreateFolder : null,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: AppSkinIcon.adapt(
              const Icon(Icons.create_new_folder_outlined),
            ),
            label: Text(l10n.libraryNewFolder, maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('library-move-selected'),
          onPressed: enabled ? onMove : null,
          tooltip: l10n.libraryMoveToFolder,
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: AppSkinIcon.adapt(const Icon(Icons.drive_file_move_outlined)),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('library-delete-selected'),
          onPressed: enabled ? onDelete : null,
          tooltip: l10n.libraryDeleteSelected(selectedCount),
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: AppSkinIcon.adapt(const Icon(Icons.delete_outline_rounded)),
        ),
      ],
    );
  }
}
