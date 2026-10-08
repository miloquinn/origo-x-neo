part of 'book_source_maintenance_page.dart';

extension _BookSourceMaintenancePageContent on _BookSourceMaintenancePageState {
  Widget _checkControls(bool busy, {bool wide = false}) {
    final state = widget.maintenance.state;
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final targets = _scopeIds;
    final statusLabel = switch (state.status) {
      BookSourceMaintenanceStatus.running =>
        l10n.bookSourcesMaintenanceHealthRunning,
      BookSourceMaintenanceStatus.cancelling =>
        l10n.bookSourcesMaintenancePausing,
      BookSourceMaintenanceStatus.cancelled =>
        l10n.bookSourcesMaintenancePaused,
      BookSourceMaintenanceStatus.failed =>
        l10n.bookSourcesMaintenanceFailedTitle,
      BookSourceMaintenanceStatus.completed =>
        l10n.bookSourcesMaintenanceCompleted,
      _ => l10n.bookSourcesMaintenanceHealthTitle,
    };
    final progress = state.progress;
    return Container(
      key: const Key('maintenanceCheckPanel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                state.isRunning
                    ? Icons.radar_rounded
                    : Icons.fact_check_outlined,
                color: scheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!wide) _scopeMenu(busy),
            ],
          ),
          const SizedBox(height: 10),
          if (wide)
            Align(alignment: Alignment.centerLeft, child: _scopeMenu(busy)),
          if (progress != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.bookSourcesMaintenanceProgress(
                      progress.completed,
                      progress.total,
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.canResume)
                  Text(
                    l10n.bookSourcesMaintenanceRemaining(
                      state.remainingSources.length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress.fraction ?? 0,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 10),
          ] else
            Text(
              l10n.bookSourcesMaintenanceCount(targets.length),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          if (state.status == BookSourceMaintenanceStatus.cancelled)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.bookSourcesMaintenancePausedHint,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (state.isRunning)
                FilledButton.icon(
                  key: const Key('maintenanceStop'),
                  onPressed: state.isCancelling
                      ? null
                      : widget.maintenance.cancel,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  label: Text(
                    state.isCancelling
                        ? l10n.bookSourcesMaintenancePausing
                        : l10n.bookSourcesMaintenancePause,
                  ),
                )
              else if (state.canResume)
                FilledButton.icon(
                  key: const Key('maintenanceResume'),
                  onPressed: busy ? null : _resume,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.bookSourcesMaintenanceResume),
                )
              else
                FilledButton.icon(
                  key: const Key('maintenanceStart'),
                  onPressed: busy || targets.isEmpty ? null : _start,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(l10n.bookSourcesMaintenanceStart),
                ),
              if (state.canResume && !state.isRunning)
                TextButton(
                  key: const Key('maintenanceStart'),
                  onPressed: busy || targets.isEmpty ? null : _start,
                  child: Text(l10n.bookSourcesMaintenanceRestart),
                )
              else
                TextButton.icon(
                  key: const Key('maintenanceDedupe'),
                  onPressed: busy || targets.isEmpty
                      ? null
                      : () => _runBusy(() => widget.onDedupe(targets)),
                  icon: const Icon(Icons.content_copy_outlined, size: 16),
                  label: Text(l10n.bookSourcesMaintenanceDedupeTitle),
                ),
            ],
          ),
          if (wide || state.isRunning) ...[
            const SizedBox(height: 12),
            Text(
              state.isRunning
                  ? l10n.bookSourcesMaintenanceBackgroundHint
                  : l10n.bookSourcesMaintenanceHealthSubtitle,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.45,
                fontSize: 12,
              ),
            ),
          ],
          if (_actionFailure != null || state.failure != null) ...[
            const SizedBox(height: 12),
            Text(
              _actionFailure != null
                  ? l10n.bookSourcesMaintenanceApplyFailed
                  : l10n.bookSourcesMaintenanceFailedTitle,
              key: const Key('maintenanceActionFailure'),
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scopeMenu(bool busy) {
    final l10n = context.l10n;
    String label(_MaintenanceScope scope) => switch (scope) {
      _MaintenanceScope.enabled => l10n.bookSourcesMaintenanceScopeEnabled,
      _MaintenanceScope.all => l10n.bookSourcesMaintenanceScopeAll,
      _MaintenanceScope.selected => l10n.bookSourcesMaintenanceScopeSelected,
    };
    return AppPopupMenuButton<_MaintenanceScope>(
      key: const Key('maintenanceScope'),
      enabled: !busy,
      tooltip: l10n.bookSourcesMaintenanceScope,
      initialValue: _scope,
      onSelected: _setScope,
      itemBuilder: (_) => [
        for (final scope in _MaintenanceScope.values)
          if (scope != _MaintenanceScope.selected ||
              widget.controller.state.selectedSourceIds.isNotEmpty)
            PopupMenuItem(
              value: scope,
              key: Key('maintenanceScope-${scope.name}'),
              child: Text(label(scope)),
            ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label(_scope),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _resultTools(Set<String> visibleIds, bool busy, {bool wide = false}) {
    final l10n = context.l10n;
    final allSelected =
        visibleIds.isNotEmpty && _selected.containsAll(visibleIds);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, wide ? 18 : 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.bookSourcesMaintenanceResultTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('maintenanceSelectVisible'),
                onPressed: visibleIds.isEmpty || busy
                    ? null
                    : () => _toggleVisibleSelection(visibleIds, allSelected),
                icon: Icon(
                  allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded,
                  size: 16,
                ),
                label: Text(
                  allSelected
                      ? l10n.bookSourcesClearSelection
                      : l10n.bookSourcesSelectAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          PillSearchField(
            textFieldKey: const Key('maintenanceResultSearch'),
            controller: _search,
            hintText: l10n.bookSourcesMaintenanceReviewSearch,
            onClear: _search.clear,
            clearTooltip: l10n.bookSourcesClearSelection,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          _filterBar(wide: wide),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _filterBar({bool wide = false}) {
    final l10n = context.l10n;
    final counts = <BookSourceMaintenanceClassification, int>{};
    for (final item in _assessments) {
      counts.update(
        item.classification,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final checkedIds = _currentCheckedIds;
    Widget filter(
      String key,
      String label,
      bool selected,
      VoidCallback onTap,
    ) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: BookSourcePill(
        key: Key(key),
        label: label,
        selected: selected,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        selectedForegroundColor: Theme.of(
          context,
        ).colorScheme.onPrimaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: () => _selectFilter(onTap),
      ),
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: Scrollbar(
        controller: _filterScroll,
        thumbVisibility: wide,
        child: SingleChildScrollView(
          key: const Key('maintenanceFiltersScroll'),
          controller: _filterScroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(bottom: wide ? 8 : 0),
          child: Row(
            children: [
              if (widget.maintenance.state.result != null)
                filter(
                  'maintenanceFilterChecked',
                  '${l10n.bookSourcesMaintenanceCheckedThisRun} ${checkedIds.length}',
                  _checkedOnly,
                  () {
                    _checkedOnly = true;
                    _problemsOnly = false;
                    _classification = null;
                  },
                ),
              filter(
                'maintenanceFilterAll',
                '${l10n.bookSourcesMaintenanceReviewAll} ${_assessments.length}',
                !_checkedOnly && !_problemsOnly && _classification == null,
                () {
                  _checkedOnly = false;
                  _problemsOnly = false;
                  _classification = null;
                },
              ),
              filter(
                'maintenanceFilterProblems',
                '${l10n.bookSourcesMaintenanceProblemsFilter} ${(counts[BookSourceMaintenanceClassification.failed] ?? 0) + (counts[BookSourceMaintenanceClassification.timedOut] ?? 0) + (counts[BookSourceMaintenanceClassification.limited] ?? 0)}',
                _problemsOnly,
                () {
                  _checkedOnly = false;
                  _problemsOnly = true;
                  _classification = null;
                },
              ),
              for (final category in BookSourceMaintenanceClassification.values)
                if ((counts[category] ?? 0) > 0)
                  filter(
                    'maintenanceResultFilter-${category.name}',
                    '${_classificationLabel(category)} ${counts[category]}',
                    _classification == category,
                    () {
                      _checkedOnly = false;
                      _problemsOnly = false;
                      _classification = category;
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resultSlivers(
    List<BookSourceMaintenanceAssessment> visible,
    bool busy, {
    required bool wide,
  }) => [
    if (visible.isEmpty)
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.l10n.bookSourcesMaintenanceReviewEmpty),
          ),
        ),
      )
    else
      SliverList.builder(
        itemCount: visible.length,
        itemBuilder: (context, index) =>
            _sourceRow(visible[index], busy, wide: wide),
      ),
    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
  ];

  Widget _sourceRow(
    BookSourceMaintenanceAssessment item,
    bool busy, {
    required bool wide,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final source = item.source;
    final result = item.healthResult;
    final date = result == null
        ? null
        : MaterialLocalizations.of(
            context,
          ).formatShortDate(result.checkedAt.toLocal());
    final classification = item.classification;
    final color = switch (classification) {
      BookSourceMaintenanceClassification.failed => scheme.error,
      BookSourceMaintenanceClassification.available => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };
    final detail = _assessmentDetail(item);
    final small = TextStyle(
      fontSize: 12,
      color: scheme.onSurfaceVariant,
      height: 1.4,
    );
    return Column(
      children: [
        CheckboxListTile(
          key: Key('maintenanceSource-${source.id}'),
          value: _selected.contains(source.id),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          onChanged: busy
              ? null
              : (value) => _setSourceSelected(source.id, value == true),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  source.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _classificationLabel(classification),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${source.sourceConfig?['bookSourceUrl'] ?? source.apiBaseUrl}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
                if (detail.isNotEmpty) Text(detail, style: small),
                if (_referenced.contains(source.id) || !source.enabled)
                  Text(
                    [
                      if (_referenced.contains(source.id))
                        context.l10n.bookSourcesMaintenanceShelfUsed,
                      if (!source.enabled) context.l10n.bookSourcesDisabled,
                    ].join(' · '),
                    style: small,
                  ),
                if (date != null)
                  Text(
                    '$date${result?.respondTimeMs == null ? '' : ' · ${result!.respondTimeMs} ms'}',
                    style: small.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          indent: 60,
          endIndent: 16,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }

  Widget _selectionBar(bool busy, bool canDisable) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 640 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final count = Text(
              l10n.bookSourcesMaintenanceSelectedCount(_selected.length),
              style: Theme.of(context).textTheme.labelMedium,
            );
            final actions = [
              OutlinedButton(
                key: const Key('maintenanceDisableSelected'),
                onPressed: !canDisable || busy ? null : _disableSelected,
                child: Text(l10n.bookSourcesDisableSelected),
              ),
              FilledButton(
                key: const Key('maintenanceDeleteSelected'),
                onPressed: _selected.isEmpty || busy ? null : _deleteSelected,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text(l10n.bookSourcesDeleteSelected),
              ),
            ];
            if (compact) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  count,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: actions[0]),
                      const SizedBox(width: 10),
                      Expanded(child: actions[1]),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: count),
                actions[0],
                const SizedBox(width: 10),
                actions[1],
              ],
            );
          },
        ),
      ),
    );
  }
}
