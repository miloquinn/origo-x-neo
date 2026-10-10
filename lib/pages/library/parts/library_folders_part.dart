part of '../library_page.dart';

extension _LibraryPageFolders on _LibraryPageState {
  GlobalKey _folderArtKey(ShelfFolder folder) =>
      _folderArtKeys.putIfAbsent(folder.id, () => GlobalKey());

  String get _shelfTitle =>
      _shelf.folder(_currentFolderId)?.name ?? context.l10n.library;

  void _syncFolderTitle() {
    widget.controller?.folderName.value = _shelf.folder(_currentFolderId)?.name;
  }

  void _reconcileFolderPath() {
    if (_currentFolderId != null && _shelf.folder(_currentFolderId) == null) {
      _folderMotionOpening = false;
      _currentFolderId = _folderPath.reversed
          .where((id) => _shelf.folder(id) != null)
          .firstOrNull;
    }
    _folderPath.clear();
    String? id = _currentFolderId;
    while (id != null) {
      _folderPath.insert(0, id);
      id = _shelf.folder(id)?.parentId;
    }
  }

  void _enterFolder(String? id, {bool returning = false}) {
    if (_isReordering ||
        _folderMutationInProgress ||
        _folderNavigationPending ||
        (_shelfTransitionKey.currentState?.isAnimating ?? false) ||
        id == _currentFolderId) {
      return;
    }
    if (_shelfScrollController.hasClients) {
      _directoryScrollOffsets[_currentFolderId] = _shelfScrollController.offset;
    }
    _directoryViews[_currentFolderId] = (
      query: _searchQuery,
      searchVisible: _searchBarVisible,
      filter: _selectedFilter,
    );
    _searchDebounce?.cancel();
    _searchFocus.unfocus();
    final view = _directoryViews[id];
    _updateState(() {
      _folderNavigationPending = true;
      _folderMotionOpening = !returning;
      _folderMotionOriginKey =
          _folderArtKeys[returning ? _currentFolderId : id];
      _currentFolderId = id;
      _searchQuery = view?.query ?? '';
      _searchController.text = _searchQuery;
      _searchBarVisible = view?.searchVisible ?? false;
      _selectedFilter = view?.filter ?? _LibraryFilter.all;
      _selection.exit();
      _reconcileFolderPath();
    });
    _syncSelection();
    _syncFilterActive();
    _syncFolderTitle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _folderNavigationPending = false;
      if (!_shelfScrollController.hasClients) return;
      final offset = (_directoryScrollOffsets[id] ?? 0).clamp(
        0.0,
        _shelfScrollController.position.maxScrollExtent,
      );
      _shelfScrollController.jumpTo(offset.toDouble());
    });
  }

  void _goUp() {
    if (_currentFolderId != null) {
      _enterFolder(_shelf.folder(_currentFolderId)?.parentId, returning: true);
    }
  }

  Widget _buildShelfBackScope(Widget child) {
    final destination = HomeTabFocusScope.maybeActiveOf(context);
    final active =
        destination == null || destination == HomeNavigationDestination.library;
    return PopScope(
      canPop:
          !active ||
          (!_isReordering && !_selection.isActive && _currentFolderId == null),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !active) return;
        if (_isReordering) {
          _finishReordering();
        } else if (_selection.isActive) {
          _exitSelectionMode();
        } else {
          _goUp();
        }
      },
      child: child,
    );
  }

  Widget _buildParentButton({required bool useRailNavigation}) {
    final chrome = HomeMobileChromeScope.of(context);
    final bottom = useRailNavigation
        ? MediaQuery.viewPaddingOf(context).bottom +
              (_selection.isActive ? 96 : 24)
        : chrome.pageBottomPadding + 8;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedPositioned(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: LayoutHelper.usesTabletLayout(context)
          ? LayoutHelper.tabletPagePadding
          : 16,
      bottom: bottom,
      child: AnimatedSwitcher(
        key: const ValueKey('library-parent-button-switcher'),
        duration: Duration(milliseconds: reduceMotion ? 80 : 240),
        reverseDuration: Duration(milliseconds: reduceMotion ? 80 : 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [
            for (final child in previous)
              IgnorePointer(child: ExcludeSemantics(child: child)),
            ?current,
          ],
        ),
        transitionBuilder: (child, animation) {
          final fade = FadeTransition(opacity: animation, child: child);
          if (reduceMotion) return fade;
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.2, 0.12),
              end: Offset.zero,
            ).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
              alignment: Alignment.centerLeft,
              child: fade,
            ),
          );
        },
        child: _currentFolderId == null
            ? const SizedBox.shrink(
                key: ValueKey('library-parent-button-hidden'),
              )
            : GlassTextButton(
                key: const ValueKey('library-back-to-parent'),
                onPressed: _isReordering || _folderMutationInProgress
                    ? null
                    : _goUp,
                minimumHeight: 48,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(context.l10n.libraryBackToParent),
                  ],
                ),
              ),
      ),
    );
  }

  List<ShelfFolder> get _visibleFolders {
    final children = _shelf.childrenOf(_currentFolderId);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty && _selectedFilter == _LibraryFilter.all) return children;
    final matched = _shelf.foldersMatching(
      (book) =>
          _matchesSelectedFilter(book) &&
          (query.isEmpty ||
              book.title.toLowerCase().contains(query) ||
              book.author.toLowerCase().contains(query)),
    );
    return children
        .where(
          (folder) =>
              matched.contains(folder.id) ||
              (_selectedFilter == _LibraryFilter.all &&
                  folder.name.toLowerCase().contains(query)),
        )
        .toList();
  }

  Future<void> _showAddMenu() async {
    final action = await showGlassBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(context.l10n.libraryNewFolder),
              onTap: () => Navigator.of(sheetContext).pop('folder'),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: Text(context.l10n.importBooks),
              onTap: () => Navigator.of(sheetContext).pop('import'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'folder') {
      await _createFolder();
    } else if (action == 'import') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ImportBookPage()));
      if (mounted) await _loadBooks();
    }
  }

  Future<void> _createFolderFromSelected() async {
    if (_selection.selectedIds.isEmpty) return;
    await _createFolder(bookIds: _selection.selectedIds);
  }

  Future<void> _createFolder({Set<int> bookIds = const {}}) async {
    if (_folderMutationInProgress) return;
    final parentId = _currentFolderId;
    final selected = Set<int>.of(bookIds);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LibraryFolderNameDialog(
        movingBooks: selected.isNotEmpty,
        onSave: (name) => _commitFolderChange(() async {
          await _folderDao.create(name, parentId: parentId, bookIds: selected);
        }),
      ),
    );
    if (saved == true && mounted) _exitSelectionMode();
  }

  Future<void> _commitFolderChange(Future<void> Function() operation) async {
    if (_folderMutationInProgress) {
      throw StateError('Shelf operation is in progress');
    }
    _updateState(() => _folderMutationInProgress = true);
    try {
      await operation();
      // DAO change notifications use an asynchronous broadcast stream. Let the
      // completed mutation's event install its debounce before replacing it
      // with the immediate reload below.
      await Future<void>.delayed(Duration.zero);
      _libraryRefreshDebounce?.cancel();
      _libraryRefreshDebounce = null;
      if (mounted) await _loadBooks();
    } finally {
      if (mounted) _updateState(() => _folderMutationInProgress = false);
    }
  }

  Future<void> _moveSelectedBooks() =>
      _moveBooksToFolder(_selection.selectedIds);

  Future<void> _moveBooksToFolder(Set<int> bookIds) async {
    if (bookIds.isEmpty || _folderMutationInProgress) return;
    final selected = Set<int>.of(bookIds);
    final destination = await _pickFolderDestination();
    if (destination == null || !mounted) return;
    try {
      await _commitFolderChange(
        () => _folderDao.moveBooks(selected, destination.id),
      );
      if (mounted) _exitSelectionMode();
    } catch (error, stack) {
      _reportFolderError(error, stack);
    }
  }

  Future<({String? id})?> _pickFolderDestination({ShelfFolder? movingFolder}) {
    String? location = movingFolder?.parentId ?? _currentFolderId;
    return showGlassBottomSheet<({String? id})>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) {
          final children = _shelf
              .childrenOf(location)
              .where(
                (folder) =>
                    movingFolder == null ||
                    !_shelf.isWithin(folder.id, movingFolder.id),
              )
              .toList();
          final samePlace = movingFolder != null
              ? location == movingFolder.parentId
              : location == _currentFolderId;
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 20, 12),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: context.l10n.libraryBackToParent,
                          onPressed: location == null
                              ? null
                              : () => updateSheet(() {
                                  location = _shelf.folder(location)?.parentId;
                                }),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        Expanded(
                          child: Text(
                            _shelf.folder(location)?.name ??
                                context.l10n.libraryRootShelf,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (location != null)
                          IconButton(
                            tooltip: context.l10n.libraryRootShelf,
                            onPressed: () => updateSheet(() => location = null),
                            icon: const Icon(Icons.home_outlined),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: children.length,
                      itemBuilder: (_, index) {
                        final folder = children[index];
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(folder.name),
                          subtitle: Text(
                            context.l10n.libraryFolderBooks(
                              _shelf.bookCount(folder.id),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => updateSheet(() => location = folder.id),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('library-folder-move-here'),
                        onPressed: samePlace
                            ? null
                            : () => Navigator.of(
                                sheetContext,
                              ).pop((id: location)),
                        child: Text(context.l10n.libraryMoveHere),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFolderOptions(ShelfFolder folder) async {
    if (_selection.isActive || _folderMutationInProgress) return;
    final action = await showGlassBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                folder.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.libraryRenameFolder),
              onTap: () => Navigator.of(sheetContext).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outlined),
              title: Text(context.l10n.libraryMoveToFolder),
              onTap: () => Navigator.of(sheetContext).pop('move'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(context.l10n.libraryDissolveFolder),
              onTap: () => Navigator.of(sheetContext).pop('dissolve'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'rename') {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => LibraryFolderNameDialog(
          initialName: folder.name,
          onSave: (name) =>
              _commitFolderChange(() => _folderDao.rename(folder.id, name)),
        ),
      );
      return;
    }
    try {
      if (action == 'move') {
        final destination = await _pickFolderDestination(movingFolder: folder);
        if (destination == null || !mounted) return;
        await _commitFolderChange(
          () => _folderDao.moveFolder(folder.id, destination.id),
        );
      } else if (action == 'dissolve') {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.libraryDissolveFolder),
            content: Text(context.l10n.libraryDissolveFolderMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.libraryDissolveFolder),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        await _commitFolderChange(() => _folderDao.dissolve(folder.id));
      }
    } catch (error, stack) {
      _reportFolderError(error, stack);
    }
  }

  void _reportFolderError(Object error, StackTrace stack) {
    debugPrint('Shelf folder operation failed: $error\n$stack');
    if (mounted) {
      showSideToast(
        context,
        context.l10n.libraryFolderOperationFailed,
        kind: SideToastKind.error,
      );
    }
  }

  Widget _buildFolderArt(ShelfFolder folder) {
    final scheme = Theme.of(context).colorScheme;
    final preview = _shelf.previewOf(folder.id);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: preview.isEmpty
            ? Icon(Icons.folder_outlined, color: scheme.primary, size: 36)
            : Column(
                children: List.generate(
                  3,
                  (row) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: row == 2 ? 0 : 4),
                      child: Row(
                        children: List.generate(3, (column) {
                          final index = row * 3 + column;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: column == 2 ? 0 : 4,
                              ),
                              child: index >= preview.length
                                  ? const SizedBox.expand()
                                  : ClipRRect(
                                      key: ValueKey(
                                        'folder-preview-${folder.id}-$index',
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                      child: ExcludeSemantics(
                                        child: _buildListCoverArt(
                                          context,
                                          preview[index],
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFolderTile(ShelfFolder folder, {bool list = false}) {
    final count = context.l10n.libraryFolderBooks(_shelf.bookCount(folder.id));
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${folder.name}，$count',
      child: Padding(
        padding: EdgeInsets.only(bottom: list ? 10 : 0),
        child: Material(
          color: list
              ? _isMaterial3Style
                    ? scheme.surfaceContainerLow
                    : scheme.surface.withValues(alpha: 0.86)
              : Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: list && _isMaterial3Style ? 1 : 0,
          shadowColor: scheme.shadow.withValues(alpha: 0.07),
          shape: list
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: scheme.outline.withValues(
                      alpha: _isMaterial3Style ? 0.2 : 0.12,
                    ),
                    width: 0.8,
                  ),
                )
              : null,
          child: InkWell(
            key: ValueKey('library-folder-${folder.id}'),
            borderRadius: BorderRadius.circular(list ? 18 : 16),
            onTap: _selection.isActive ? null : () => _enterFolder(folder.id),
            onLongPress: _selection.isActive
                ? null
                : () => _showFolderOptions(folder),
            child: list
                ? KeyedSubtree(
                    key: _folderArtKey(folder),
                    child: _buildFolderCard(folder, count),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox.expand(
                          child: KeyedSubtree(
                            key: _folderArtKey(folder),
                            child: _buildFolderArt(folder),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                        child: Text(
                          folder.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          count,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard(ShelfFolder folder, String count) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: ValueKey('library-folder-card-${folder.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.folder_outlined,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFolderCoverStrip(folder),
        ],
      ),
    );
  }

  Widget _buildFolderCoverStrip(ShelfFolder folder) {
    final preview = _shelf.previewOf(folder.id);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (preview.isEmpty) {
      return Container(
        key: ValueKey('folder-preview-empty-${folder.id}'),
        constraints: const BoxConstraints(minHeight: 80),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_stories_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.libraryFolderEmptyPreview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (preview.length == 1) {
      final book = preview.single;
      return Row(
        children: [
          SizedBox(
            width: 72,
            height: 108,
            child: ClipRRect(
              key: ValueKey('folder-preview-${folder.id}-0'),
              borderRadius: BorderRadius.circular(10),
              child: ExcludeSemantics(child: _buildListCoverArt(context, book)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (book.author.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }
    final remaining = _shelf.bookCount(folder.id) - preview.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final coverWidth = ((constraints.maxWidth - 30) / 4).clamp(64.0, 88.0);
        final coverHeight = coverWidth * 1.5;
        final captionHeight = MediaQuery.textScalerOf(context).scale(12) * 1.35;
        return SizedBox(
          height: coverHeight + captionHeight + 10,
          child: ListView.separated(
            key: PageStorageKey('folder-preview-strip-${folder.id}'),
            primary: false,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 1, bottom: 3),
            itemCount: preview.length + (remaining > 0 ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == preview.length) {
                return SizedBox(
                  key: ValueKey('folder-preview-more-${folder.id}'),
                  width: coverWidth,
                  child: Column(
                    children: [
                      Container(
                        height: coverHeight,
                        width: coverWidth,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '+$remaining',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final book = preview[index];
              return SizedBox(
                width: coverWidth,
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      SizedBox(
                        height: coverHeight,
                        width: coverWidth,
                        child: ClipRRect(
                          key: ValueKey('folder-preview-${folder.id}-$index'),
                          borderRadius: BorderRadius.circular(10),
                          child: _buildListCoverArt(context, book),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: captionHeight,
                        width: coverWidth,
                        child: Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.35,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
