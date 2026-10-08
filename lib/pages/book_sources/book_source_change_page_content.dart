part of 'book_source_change_page.dart';

extension _BookSourceChangePageContent on _BookSourceChangePageState {
  Widget _buildResults(BuildContext context) => CustomScrollView(
    key: const Key('bookSourceChangeResultsScroll'),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        sliver: SliverToBoxAdapter(child: _buildMigrationHeader(context)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        sliver: SliverToBoxAdapter(child: _buildSearchControls(context)),
      ),
      if (_candidates.isEmpty)
        SliverToBoxAdapter(child: _buildEmptyState(context))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          sliver: SliverList.builder(
            itemCount: _candidates.length * 2 - 1,
            itemBuilder: (context, index) => index.isOdd
                ? const SizedBox(height: 10)
                : _buildCandidate(context, _candidates[index ~/ 2]),
          ),
        ),
    ],
  );

  Widget _buildMigrationHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedName = _selected?.source.name;
    return Container(
      key: const Key('bookSourceChangeHeader'),
      padding: const EdgeInsets.all(16),
      decoration: bookSourcePanelDecoration(
        context,
        radius: 20,
        stronger: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.currentBook.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SourceRailStop(
                  label: context.l10n.bookSourceChangeCurrentSource,
                  value:
                      widget.currentSource?.name ??
                      context.l10n.bookSourceNotBound,
                  active: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, color: scheme.primary),
              ),
              Expanded(
                child: _SourceRailStop(
                  label: context.l10n.bookSourceChangeTargetSource,
                  value:
                      selectedName ?? context.l10n.bookSourceChangeNotSelected,
                  active: selectedName != null,
                ),
              ),
            ],
          ),
          if (_position != null && _position!.chapterCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.bookSourceChangeCurrentChapter(
                _position!.chapterIndex + 1,
              ),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchControls(BuildContext context) {
    final progress = _searching || _completed > 0
        ? context.l10n.bookSourceChangeQuickProgress(
            _completed,
            _searchBatchTotal,
            _total,
          )
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PillSearchField(
          textFieldKey: const Key('bookSourceChangeQuery'),
          controller: _queryController,
          hintText: context.l10n.bookSourceChangeSearchLabel,
          leadingIcon: Icons.manage_search_rounded,
          onSubmitted: (_) => _startSearch(),
          showClearButton: false,
          trailing: IconButton(
            tooltip: context.l10n.bookSourceChangeSearchAgain,
            onPressed: _preparing ? null : _startSearch,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final authorFilter = FilterChip(
              key: const Key('bookSourceChangeAuthorFilter'),
              selected: _checkAuthor,
              avatar: const Icon(Icons.person_search_outlined, size: 18),
              label: Text(context.l10n.bookSourceChangeCheckAuthor),
              onSelected: _setCheckAuthor,
            );
            if (progress == null || constraints.maxWidth < 500) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  authorFilter,
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      progress,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              );
            }
            return Row(
              children: [
                authorFilter,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    progress,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            );
          },
        ),
        if (_failed > 0) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.bookSourceChangeFailedSources(_failed),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_searching || _hasMoreSources) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: Key(
              _searching
                  ? 'bookSourceChangeStopSearch'
                  : 'bookSourceChangeSearchRemaining',
            ),
            onPressed: _searching
                ? _stopSearch
                : () => _startSearch(continueSearch: true),
            icon: Icon(
              _searching
                  ? Icons.stop_circle_outlined
                  : Icons.travel_explore_rounded,
              size: 18,
            ),
            label: Text(
              _searching
                  ? context.l10n.bookSourceChangeStopSearch
                  : context.l10n.bookSourceChangeSearchRemaining,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (_preparing) {
      return _EmptyChangeState(
        icon: Icons.radar_rounded,
        title: context.l10n.bookSourceChangeSearching,
        message: context.l10n.bookSourceChangeSearchingHint,
        loading: true,
      );
    }
    if (_sourceLoadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EmptyChangeState(
              icon: Icons.cloud_off_outlined,
              title: context.l10n.bookSourceChangeLoadFailed,
              message: context.l10n.bookSourceChangeLoadFailedHint,
            ),
            TextButton(
              onPressed: () => _loadSourcesAndSearch(retry: true),
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }
    if (_total == 0) {
      return _EmptyChangeState(
        icon: Icons.travel_explore_outlined,
        title: context.l10n.bookSourceChangeNoOtherSources,
        message: context.l10n.bookSourceChangeNoOtherSourcesHint,
      );
    }
    if (_searching) {
      return _EmptyChangeState(
        icon: Icons.radar_rounded,
        title: context.l10n.bookSourceChangeSearching,
        message: context.l10n.bookSourceChangeSearchingHint,
        loading: true,
      );
    }
    return _EmptyChangeState(
      icon: Icons.search_off_rounded,
      title: context.l10n.bookSourceChangeNoMatches,
      message: _failed > 0
          ? context.l10n.bookSourceChangeFailedSources(_failed)
          : context.l10n.bookSourceChangeNoMatchesHint,
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final candidate = _selected;
    if (candidate == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            key: const Key('bookSourceChangeConfirmation'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _buildMigrationHeader(context),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: bookSourcePanelDecoration(context, radius: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      candidate.source.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (candidate.book.author.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        candidate.book.author,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                    if (!candidate.authorMatches) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.bookSourceChangeAuthorDifferent,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildCheckPanel(context),
              if (_validated != null) ...[
                const SizedBox(height: 12),
                _buildMappingPanel(context, _validated!),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: bookSourcePanelDecoration(context, radius: 18),
                  child: Text(
                    widget.shelfBook?.isOnline == false
                        ? context.l10n.bookSourceChangeLocalImpact
                        : context.l10n.bookSourceChangeOnlineImpact,
                  ),
                ),
              ],
              if (_commitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _commitError is BookSourceChangeConflict
                      ? context.l10n.bookSourceChangeAlreadyOnShelf
                      : context.l10n.bookSourceChangeCommitFailed,
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ],
          ),
        ),
        _buildBottomAction(context),
      ],
    );
  }

  Widget _buildCheckPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final validated = _validated;
    final error = _validationError;
    return Container(
      key: const Key('bookSourceChangeCheckPanel'),
      padding: const EdgeInsets.all(16),
      decoration: bookSourcePanelDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.bookSourceChangeChecking,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (_validating) ...[
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_validationStageLabel(context))),
              ],
            ),
            if (_slowCheck) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.bookSourceChangeSlow,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('bookSourceChangeCancelCheck'),
              onPressed: _backToResults,
              child: Text(context.l10n.cancel),
            ),
          ] else if (error != null) ...[
            Text(
              error is BookSourceChangeConflict
                  ? context.l10n.bookSourceChangeAlreadyOnShelf
                  : error is TimeoutException ||
                        error is BookSourceChangeTimeoutException
                  ? context.l10n.bookSourceChangeCheckTimedOut
                  : context.l10n.bookSourceChangeCheckFailed,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const Key('bookSourceChangeRetryCheck'),
                    onPressed: () => _selectCandidate(_selected!),
                    child: Text(context.l10n.retry),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _backToResults,
                    child: Text(context.l10n.back),
                  ),
                ),
              ],
            ),
          ] else if (validated != null) ...[
            Text(
              context.l10n.bookSourceChangeReadable,
              style: TextStyle(color: scheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              '${context.l10n.bookSourceChangeChapterCount(validated.chapters.length)}'
              ' · ${context.l10n.bookSourceChangeResponseTime(validated.responseTime.inMilliseconds)}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  String _validationStageLabel(BuildContext context) {
    switch (_validationStage) {
      case BookSourceChangeValidationStage.detail:
        return context.l10n.bookSourceChangeCheckingDetail;
      case BookSourceChangeValidationStage.catalog:
        return context.l10n.bookSourceChangeCheckingCatalog;
      case BookSourceChangeValidationStage.content:
        return context.l10n.bookSourceChangeCheckingContent;
      case null:
        return context.l10n.bookSourceChangeCheckingPosition;
    }
  }

  Widget _buildMappingPanel(
    BuildContext context,
    ValidatedBookSourceChange validated,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final position = _position;
    final confidence = validated.mappingConfidence;
    final needsSelection =
        (confidence == BookSourceChapterMappingConfidence.proportional ||
            _positionLoadFailed) &&
        confidence != BookSourceChapterMappingConfidence.manual;
    final mappingLabel = switch (confidence) {
      BookSourceChapterMappingConfidence.exactTitle =>
        context.l10n.bookSourceChangeMappingTitle,
      BookSourceChapterMappingConfidence.chapterNumber =>
        context.l10n.bookSourceChangeMappingNumber,
      BookSourceChapterMappingConfidence.manual =>
        context.l10n.bookSourceChangeMappingManual,
      _ => context.l10n.bookSourceChangeMappingEstimate,
    };
    return Container(
      key: const Key('bookSourceChangeMappingPanel'),
      padding: const EdgeInsets.all(16),
      decoration: bookSourcePanelDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.bookSourceChangeReadingPosition,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.bookSourceChangeOriginalChapter(
              position?.chapterIndex == null ? 1 : position!.chapterIndex + 1,
              position?.chapterTitle ?? '',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.bookSourceChangeNewChapter(
              validated.chapterIndex + 1,
              validated.chapter.title,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mappingLabel,
            style: TextStyle(
              color: needsSelection ? scheme.error : scheme.primary,
            ),
          ),
          if (needsSelection) ...[
            const SizedBox(height: 8),
            Text(
              _positionLoadFailed
                  ? context.l10n.bookSourceChangePositionUnavailable
                  : context.l10n.bookSourceChangeMappingNeedsChoice,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('bookSourceChangeChooseChapter'),
              onPressed: () => _chooseChapter(validated),
              icon: const Icon(Icons.list_rounded),
              label: Text(context.l10n.bookSourceChangeChooseChapter),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseChapter(ValidatedBookSourceChange validated) async {
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ChapterSelectionSheet(
        chapters: validated.chapters,
        initialIndex: validated.chapterIndex,
      ),
    );
    if (index == null || !mounted || _selected == null) return;
    await _selectCandidate(_selected!, selectedChapterIndex: index);
  }

  int _searchTargetCount(Iterable<RegisteredBookSource> sources) => sources
      .where(
        (source) =>
            source.enabled &&
            source.id != widget.currentSource?.id &&
            source.capabilities.contains('search'),
      )
      .length;

  Widget _buildCandidate(
    BuildContext context,
    BookSourceChangeCandidate candidate,
  ) {
    final selected = identical(_selected, candidate);
    final validated = selected ? _validated : null;
    final scheme = Theme.of(context).colorScheme;
    final subtitleParts = <String>[
      if (candidate.book.author.isNotEmpty) candidate.book.author,
      if (candidate.book.latestChapter?.isNotEmpty ?? false)
        candidate.book.latestChapter!,
    ];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('bookSourceChangeCandidate-${candidate.source.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectCandidate(candidate),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: bookSourcePanelDecoration(context, radius: 18).copyWith(
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outline.withValues(alpha: 0.16),
              width: selected ? 1.6 : 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  validated != null
                      ? Icons.verified_rounded
                      : Icons.public_rounded,
                  color: validated != null
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.source.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!candidate.authorMatches)
                          _StatusPill(
                            label: context.l10n.bookSourceChangeAuthorDifferent,
                            color: scheme.tertiary,
                          ),
                      ],
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (selected) ...[
                      const SizedBox(height: 9),
                      _buildCandidateStatus(context, validated),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateStatus(
    BuildContext context,
    ValidatedBookSourceChange? validated,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (_validating) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(context.l10n.bookSourceChangeValidating)),
        ],
      );
    }
    if (_validationError != null) {
      return Text(
        _validationError is BookSourceChangeConflict
            ? context.l10n.bookSourceChangeAlreadyOnShelf
            : context.l10n.bookSourceChangeCheckFailed,
        style: TextStyle(color: scheme.error, fontSize: 12),
      );
    }
    if (validated != null) {
      return Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _StatusPill(
            label: context.l10n.bookSourceChangeReadable,
            color: scheme.primary,
          ),
          _StatusPill(
            label: context.l10n.bookSourceChangeChapterCount(
              validated.chapters.length,
            ),
            color: scheme.secondary,
          ),
          _StatusPill(
            label: context.l10n.bookSourceChangeResponseTime(
              validated.responseTime.inMilliseconds,
            ),
            color: scheme.tertiary,
          ),
        ],
      );
    }
    return Text(context.l10n.bookSourceChangeTapToValidate);
  }

  Widget _buildBottomAction(BuildContext context) {
    final validated = _validated;
    final needsManualMapping =
        validated != null &&
        (validated.mappingConfidence ==
                BookSourceChapterMappingConfidence.proportional ||
            _positionLoadFailed) &&
        validated.mappingConfidence !=
            BookSourceChapterMappingConfidence.manual;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          key: const Key('bookSourceChangeCommit'),
          onPressed: validated == null || needsManualMapping || _committing
              ? null
              : _commit,
          icon: _committing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swap_horiz_rounded),
          label: Text(
            _committing
                ? context.l10n.bookSourceChangeSwitching
                : context.l10n.bookSourceChangeConfirmAction(
                    _selected?.source.name ?? '',
                  ),
          ),
        ),
      ),
    );
  }
}
