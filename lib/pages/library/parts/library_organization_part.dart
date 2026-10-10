part of '../library_page.dart';

extension _LibraryPageOrganization on _LibraryPageState {
  List<LibraryShelfEntry> get _displayEntries {
    final settings = context.read<AppSettingsNotifier>();
    final identity = (
      revision: _booksRevision,
      folder: _currentFolderId,
      query: _searchQuery.trim().toLowerCase(),
      filter: _selectedFilter,
      sort: settings.librarySortMode,
      descending: settings.librarySortDescending,
    );
    if (_orderedEntriesIdentity == identity) return _orderedEntriesCache;
    _orderedEntriesIdentity = identity;
    return _orderedEntriesCache = orderedLibraryEntries(
      books: _visibleBooks,
      folders: _visibleFolders,
      sort: settings.librarySortMode,
      descending: settings.librarySortDescending,
    );
  }

  Future<void> _showOrganizationMenu() async {
    if (_reorderSaving || _isInitialLoading || _loadError != null) return;
    if (_isReordering) {
      _finishReordering();
      return;
    }
    final settings = context.read<AppSettingsNotifier>();
    final scopedBooks = _currentFolderId == null
        ? _books
        : _books
              .where(
                (book) =>
                    _shelf.isWithin(book.shelfFolderId, _currentFolderId!),
              )
              .toList();
    final choice = await showGlassBottomSheet<LibraryOrganizationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LibraryOrganizationSheet(
        sort: settings.librarySortMode,
        descending: settings.librarySortDescending,
        filterIndex: _selectedFilter.index,
        filterLabels: [
          context.l10n.libraryFilterAll(scopedBooks.length),
          context.l10n.libraryFilterReading(
            scopedBooks.where(_isReadingBook).length,
          ),
          context.l10n.libraryFilterFinished(
            scopedBooks.where(_isFinishedBook).length,
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    try {
      if (choice.sort != null) {
        await settings.setLibrarySort(
          choice.sort!,
          descending: choice.descending,
        );
      }
      if (!mounted) return;
      _searchDebounce?.cancel();
      _updateState(() {
        _selection.exit();
        if (choice.filterIndex != null) {
          _selectedFilter = _LibraryFilter.values[choice.filterIndex!];
        }
        if (choice.reordering) {
          // Reorder the entire directory so hidden search/filter results are
          // never silently given new positions.
          _searchQuery = '';
          _searchController.clear();
          _searchBarVisible = false;
          _searchFocus.unfocus();
          _selectedFilter = _LibraryFilter.all;
          _isReordering = true;
        }
      });
      widget.controller?.reordering.value = _isReordering;
      _syncSelection();
      _syncFilterActive();
    } catch (_) {
      if (mounted) {
        showSideToast(
          context,
          context.l10n.libraryReorderSaveFailed,
          kind: SideToastKind.error,
        );
      }
    }
  }

  void _finishReordering() {
    if (!_isReordering || _reorderSaving) return;
    _endReorderDrag();
    _updateState(() => _isReordering = false);
    widget.controller?.reordering.value = false;
  }

  Future<void> _reorderShelf(String source, String target) async {
    if (!_isReordering || _reorderSaving || source == target) return;
    final entries = List<LibraryShelfEntry>.of(_displayEntries);
    final from = entries.indexWhere((entry) => entry.key == source);
    final to = entries.indexWhere((entry) => entry.key == target);
    if (from < 0 || to < 0) return;
    entries.insert(to, entries.removeAt(from));
    final parent = _currentFolderId;
    _endReorderDrag();
    _updateState(() => _reorderSaving = true);
    try {
      await (widget.reorderSaver?.call(
            parent,
            entries.map((entry) => entry.identity).toList(),
          ) ??
          _folderDao.reorder(
            parent,
            entries.map((entry) => entry.identity).toList(),
          ));
      if (!mounted) return;
      final ranks = {
        for (var index = 0; index < entries.length; index++)
          entries[index].key: index,
      };
      _updateState(() {
        // Patch only positions in the current snapshot. A source check or
        // reading update arriving during the write retains all of its fields.
        _books = _books
            .map(
              (book) =>
                  book.shelfFolderId == parent &&
                      ranks.containsKey('book:${book.id}')
                  ? book.copyWith(shelfSortIndex: ranks['book:${book.id}'])
                  : book,
            )
            .toList();
        _folders = _folders
            .map(
              (folder) =>
                  folder.parentId == parent &&
                      ranks.containsKey('folder:${folder.id}')
                  ? ShelfFolder(
                      id: folder.id,
                      name: folder.name,
                      parentId: folder.parentId,
                      createdAt: folder.createdAt,
                      sortIndex: ranks['folder:${folder.id}'],
                    )
                  : folder,
            )
            .toList();
        _shelf = LibraryShelfProjection(_folders, _books);
        _booksRevision++;
      });
      LibraryEventBus().notifyLibraryChanged();
    } catch (_) {
      if (!mounted) return;
      showSideToast(
        context,
        context.l10n.libraryReorderSaveFailed,
        kind: SideToastKind.error,
      );
      await _loadBooks();
    } finally {
      if (mounted) _updateState(() => _reorderSaving = false);
    }
  }

  Widget _reorderItem(LibraryShelfEntry entry, Widget child) {
    if (!_isReordering) {
      return KeyedSubtree(
        key: ValueKey('library-entry-${entry.key}'),
        child: child,
      );
    }
    final entries = _displayEntries;
    final index = entries.indexWhere((item) => item.key == entry.key);
    return LibraryReorderableItem(
      key: ValueKey('library-entry-${entry.key}'),
      entry: entry,
      enabled: _isReordering && !_reorderSaving,
      targeted: _reorderDropKey == entry.key,
      onDragUpdate: _updateReorderDrag,
      onDragEnd: _endReorderDrag,
      onMoveEarlier: index > 0
          ? () => unawaited(_reorderShelf(entry.key, entries[index - 1].key))
          : null,
      onMoveLater: index < entries.length - 1
          ? () => unawaited(_reorderShelf(entry.key, entries[index + 1].key))
          : null,
      child: SizedBox(
        key: _reorderItemKeys.putIfAbsent(entry.key, GlobalKey.new),
        child: child,
      ),
    );
  }

  Widget _reorderViewport(Widget child) => DragTarget<LibraryShelfEntry>(
    onWillAcceptWithDetails: (_) => _isReordering && !_reorderSaving,
    onMove: (details) => _updateReorderDrag(details.offset),
    onLeave: (_) => _endReorderDrag(),
    onAcceptWithDetails: (details) {
      // Scrolling can recycle both the source and previous target. Resolve the
      // current geometry at release through this permanently mounted target.
      final target = _reorderTargetAt(details.offset);
      _endReorderDrag();
      if (target != null) {
        unawaited(_reorderShelf(details.data.key, target));
      }
    },
    builder: (_, candidates, rejected) =>
        SizedBox(key: _shelfViewportKey, child: child),
  );

  String? _reorderTargetAt(Offset position) {
    for (final entry in _reorderItemKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final bounds = box.localToGlobal(Offset.zero) & box.size;
        if (bounds.contains(position)) return entry.key;
      }
    }
    return null;
  }

  void _refreshReorderTarget() {
    if (!mounted || !_isReordering || _reorderDragPosition == null) return;
    final target = _reorderTargetAt(_reorderDragPosition!);
    if (target != _reorderDropKey) {
      _updateState(() => _reorderDropKey = target);
    }
  }

  void _updateReorderDrag(Offset position) {
    _reorderDragPosition = position;
    _refreshReorderTarget();
    _reorderScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (
      _,
    ) {
      if (!mounted || !_isReordering || !_shelfScrollController.hasClients) {
        return;
      }
      final box = _shelfViewportKey.currentContext?.findRenderObject();
      final pointer = _reorderDragPosition;
      if (box is! RenderBox || !box.hasSize || pointer == null) return;
      final local = box.globalToLocal(pointer);
      if (!(Offset.zero & box.size).contains(local)) return;
      final y = local.dy;
      final bottomInset = HomeMobileChromeScope.of(context).pageBottomPadding;
      final bottom = math.max(80.0, box.size.height - bottomInset);
      final delta = y < 72
          ? -((72 - y) / 6).clamp(0.0, 16.0)
          : y > bottom - 72
          ? ((y - bottom + 72) / 6).clamp(0.0, 16.0)
          : 0.0;
      if (delta == 0) return;
      final scroll = _shelfScrollController.position;
      _shelfScrollController.jumpTo(
        (scroll.pixels + delta).clamp(
          scroll.minScrollExtent,
          scroll.maxScrollExtent,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshReorderTarget();
      });
    });
  }

  void _endReorderDrag() {
    _reorderScrollTimer?.cancel();
    _reorderScrollTimer = null;
    _reorderDragPosition = null;
    if (mounted && _reorderDropKey != null) {
      _updateState(() => _reorderDropKey = null);
    }
  }

  Widget _buildReorderNotice() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(
      children: [
        const Icon(Icons.drag_indicator_rounded, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.libraryDragHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 8),
        if (_reorderSaving)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          GlassTextButton(
            key: const ValueKey('library-reorder-done'),
            onPressed: _finishReordering,
            child: Text(context.l10n.settingsDone),
          ),
      ],
    ),
  );
}
