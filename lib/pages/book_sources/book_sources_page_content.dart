part of 'book_sources_page.dart';

extension _BookSourcesPageContent on _BookSourcesPageState {
  void _restorePendingScroll() {
    final target = _pendingScrollOffset;
    if (target == null) return;
    _pendingScrollOffset = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      _scrollController.jumpTo(
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  RegisteredBookSource? get _selectedLoginSource {
    final id = _state.selectedSourceId;
    if (id == null) return null;
    final source = _state.discoverySources
        .where((candidate) => candidate.id == id)
        .firstOrNull;
    if (source?.sourceProtocol != BookSourceProtocolKind.readingSource ||
        !sourceDeclaresLogin(source?.sourceConfig)) {
      return null;
    }
    return source;
  }

  void _maybePromptForLogin(Object error) {
    final source = _selectedLoginSource;
    if (source == null || !mounted) return;
    final key = '${source.id}:${error.toString()}';
    if (_loginPromptKey == key) return;
    _loginPromptKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.sourceLoginTitle),
          content: Text(context.l10n.sourceLoginDiscoveryNotice(source.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.login_rounded),
              label: Text(context.l10n.sourceLoginTitle),
            ),
          ],
        ),
      );
      if (shouldLogin == true && mounted) await _openSourceLogin(source);
    });
  }

  List<Widget> _buildSectionSlivers(double bottomPadding) {
    if (_state.loadingSources) {
      return [
        _paddedSectionSliver(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('bookSourceDiscoverSectionLoadingIndicator'),
              ),
            ),
          ),
          bottomPadding: bottomPadding,
        ),
      ];
    }
    if (_state.hasOrganizationFilter &&
        _state.organizedDiscoverySources.isEmpty) {
      final copy = BookSourceOrganizationCopy.of(context);
      return [
        _paddedSectionSliver(
          BookSourceMessageCard(
            icon: _state.favoritesOnly
                ? Icons.star_outline_rounded
                : Icons.folder_outlined,
            title: _state.favoritesOnly
                ? copy.favorites
                : _state.selectedGroup!,
            message: _state.favoritesOnly
                ? copy.noFavorites
                : copy.noGroupSources,
            actionLabel: copy.all,
            onAction: () => _controller.changeOrganizationScope(),
          ),
          bottomPadding: bottomPadding,
        ),
      ];
    }
    final cache = _state.caches[_state.section];
    if (cache == null || cache.loading) {
      return [
        _paddedSectionSliver(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 44),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('bookSourceDiscoverSectionLoadingIndicator'),
              ),
            ),
          ),
          bottomPadding: bottomPadding,
        ),
      ];
    }
    if (cache.error != null) {
      _maybePromptForLogin(cache.error!);
      return [
        _paddedSectionSliver(
          BookSourceMessageCard(
            icon: Icons.cloud_off_outlined,
            title: context.l10n.discoverLoadFailed,
            message: cache.error.toString(),
            actionLabel: context.l10n.discoverRetry,
            onAction: () =>
                _controller.loadSection(_state.section, force: true),
          ),
          bottomPadding: bottomPadding,
        ),
      ];
    }
    if (_layoutController.layout.value == BookSourceDiscoverLayout.list) {
      return _buildListLayoutSlivers(cache, bottomPadding);
    }
    return switch (_state.section) {
      BookSourcesSection.recommended => _buildShelvesSlivers(
        cache,
        bottomPadding,
      ),
      BookSourcesSection.categories => _buildCategoriesSlivers(
        cache,
        bottomPadding,
      ),
      BookSourcesSection.latest => _buildLatestSlivers(cache, bottomPadding),
    };
  }

  List<Widget> _buildShelvesSlivers(
    BookSourcesSectionCache cache,
    double bottomPadding,
  ) {
    final horizontalPadding = _sectionHorizontalPadding;
    final shelves = (cache.shelves ?? const <BookSourceDiscoveryShelf>[])
        .where((shelf) => _state.matchesSelectedSource(shelf.source))
        .toList(growable: false);
    if (shelves.isEmpty) {
      return [
        _paddedSectionSliver(
          _state.sourcesFor(BookSourcesSection.recommended).isEmpty
              ? _buildUnsupportedMessage('discover')
              : _buildEmptyMessage(),
          bottomPadding: bottomPadding,
        ),
      ];
    }
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          8,
          horizontalPadding,
          bottomPadding,
        ),
        sliver: SliverList.builder(
          itemCount: shelves.length,
          itemBuilder: (context, index) =>
              _centerSectionChild(_buildShelf(shelves[index])),
        ),
      ),
    ];
  }

  Widget _buildShelf(BookSourceDiscoveryShelf shelf) {
    return BookSourceDiscoveryShelfSection(
      shelf: shelf,
      sourceActions: _state.selectedSourceId == null
          ? _sourceActions(shelf.source)
          : null,
      onBookTap: _actions.showBookDetails,
    );
  }
}
