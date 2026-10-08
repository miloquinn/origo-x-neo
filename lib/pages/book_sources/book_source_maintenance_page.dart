import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../../book_sources/models/registered_book_source.dart';
import '../../book_sources/services/book_source_health_configuration.dart';
import '../../book_sources/services/book_source_maintenance_coordinator.dart';
import '../../book_sources/source_engine/source_health_checker.dart';
import '../../utils/localization_extension.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/floating_subpage_scaffold.dart';
import '../../widgets/pill_search_field.dart';
import 'controllers/book_source_management_controller.dart';
import 'widgets/book_source_management_source_card.dart';
import 'widgets/book_source_pill.dart';

part 'book_source_maintenance_page_content.dart';

enum _MaintenanceScope { enabled, all, selected }

/// A durable workspace for checking, filtering, and cleaning installed sources.
class BookSourceMaintenancePage extends StatefulWidget {
  const BookSourceMaintenancePage({
    super.key,
    required this.controller,
    required this.maintenance,
    required this.readReferencedSourceIds,
    required this.onDedupe,
  });

  final BookSourceManagementController controller;
  final BookSourceMaintenanceCoordinator maintenance;
  final Future<Set<String>> Function() readReferencedSourceIds;
  final Future<void> Function(Set<String>) onDedupe;

  @override
  State<BookSourceMaintenancePage> createState() =>
      _BookSourceMaintenancePageState();
}

class _BookSourceMaintenancePageState extends State<BookSourceMaintenancePage> {
  final _search = TextEditingController();
  final _filterScroll = ScrollController();
  bool _checkedOnly = false;
  BookSourceMaintenanceStatus? _lastStatus;
  final _selected = <String>{};
  Set<String> _referenced = const {};
  _MaintenanceScope _scope = _MaintenanceScope.enabled;
  BookSourceMaintenanceClassification? _classification;
  bool _problemsOnly = false;
  bool _busy = false;
  Object? _actionFailure;

  int? _cachedSourcesRevision;
  int? _cachedAssessmentSourcesRevision;
  int? _cachedRunId;
  Object? _cachedResult;
  BookSourceMaintenanceStatus? _cachedStatus;
  List<RegisteredBookSource> _cachedCheckableSources = const [];
  List<BookSourceMaintenanceAssessment> _cachedAssessments = const [];

  @override
  void initState() {
    super.initState();
    if (widget.controller.state.selectedSourceIds.isNotEmpty) {
      _scope = _MaintenanceScope.selected;
    }
    _lastStatus = widget.maintenance.state.status;
    _checkedOnly = _lastStatus == BookSourceMaintenanceStatus.cancelled;
    widget.controller.addListener(_changed);
    widget.maintenance.addListener(_changed);
    _search.addListener(_searchChanged);
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    try {
      final ids = await widget.readReferencedSourceIds();
      if (mounted) setState(() => _referenced = ids);
    } on Object {
      // Reference information is advisory; cleanup remains available.
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.maintenance.removeListener(_changed);
    _search
      ..removeListener(_searchChanged)
      ..dispose();
    _filterScroll.dispose();
    super.dispose();
  }

  bool get _mutationBusy =>
      _busy ||
      widget.controller.state.loading ||
      widget.controller.state.mutation != null;

  void _searchChanged() {
    _selected.clear();
    _changed();
  }

  void _setScope(_MaintenanceScope scope) {
    setState(() => _scope = scope);
  }

  void _toggleVisibleSelection(Set<String> visibleIds, bool allSelected) {
    setState(() {
      allSelected
          ? _selected.removeAll(visibleIds)
          : _selected.addAll(visibleIds);
    });
  }

  void _selectFilter(VoidCallback updateFilter) {
    setState(() {
      _selected.clear();
      updateFilter();
    });
  }

  void _setSourceSelected(String sourceId, bool selected) {
    setState(() {
      selected ? _selected.add(sourceId) : _selected.remove(sourceId);
    });
  }

  void _changed() {
    final status = widget.maintenance.state.status;
    if (status != _lastStatus &&
        status == BookSourceMaintenanceStatus.cancelled) {
      _checkedOnly = true;
      _classification = null;
      _problemsOnly = false;
      _selected.clear();
    }
    _lastStatus = status;
    if (mounted) setState(() {});
  }

  Set<String> get _currentCheckedIds {
    final result = widget.maintenance.state.result;
    if (result == null) return const {};
    final remaining = result.remainingSources
        .map((source) => source.id)
        .toSet();
    final current = {for (final source in _checkableSources) source.id: source};
    return {
      for (final item in result.assessments)
        if (!remaining.contains(item.source.id) &&
            current.containsKey(item.source.id) &&
            sameBookSourceHealthCheckConfiguration(
              current[item.source.id]!,
              item.source,
            ))
          item.source.id,
    };
  }

  List<RegisteredBookSource> get _checkableSources {
    final revision = widget.controller.state.sourcesRevision;
    if (_cachedSourcesRevision == revision) return _cachedCheckableSources;
    _cachedSourcesRevision = revision;
    return _cachedCheckableSources = widget.controller.state.sources
        .where(
          (source) =>
              source.sourceProtocol == BookSourceProtocolKind.readingSource,
        )
        .toList(growable: false);
  }

  Set<String> get _scopeIds {
    final state = widget.controller.state;
    return switch (_scope) {
      _MaintenanceScope.enabled =>
        _checkableSources
            .where((source) => source.enabled)
            .map((source) => source.id)
            .toSet(),
      _MaintenanceScope.all =>
        _checkableSources.map((source) => source.id).toSet(),
      _MaintenanceScope.selected =>
        _checkableSources
            .where((source) => state.selectedSourceIds.contains(source.id))
            .map((source) => source.id)
            .toSet(),
    };
  }

  List<BookSourceMaintenanceAssessment> get _assessments {
    final sourceRevision = widget.controller.state.sourcesRevision;
    final maintenanceState = widget.maintenance.state;
    final checkable = _checkableSources;
    if (_cachedAssessmentSourcesRevision == sourceRevision &&
        _cachedRunId == maintenanceState.runId &&
        identical(_cachedResult, maintenanceState.result) &&
        _cachedStatus == maintenanceState.status) {
      return _cachedAssessments;
    }
    final runAssessments = {
      for (final item
          in maintenanceState.result?.assessments ??
              const <BookSourceMaintenanceAssessment>[])
        item.source.id: item,
    };
    final unpersistedIds =
        !maintenanceState.isRunning && maintenanceState.failure != null
        ? maintenanceState.remainingSources.map((source) => source.id).toSet()
        : const <String>{};
    final merged = <BookSourceMaintenanceAssessment>[];
    for (final source in checkable) {
      final run = runAssessments[source.id];
      final saved = sourceHealthCheckResultOf(source);
      final unsaved = unpersistedIds.contains(source.id);
      if (run != null &&
          !unsaved &&
          (saved == null ||
              run.healthResult == null ||
              !saved.checkedAt.isAfter(run.healthResult!.checkedAt)) &&
          sameBookSourceHealthCheckConfiguration(source, run.source)) {
        merged.add(
          BookSourceMaintenanceAssessment(
            source: source,
            classification: run.classification,
            healthResult: run.healthResult,
            error: run.error,
          ),
        );
      } else {
        merged.add(bookSourceMaintenanceAssessment(source));
      }
    }
    const priority = {
      BookSourceMaintenanceClassification.failed: 0,
      BookSourceMaintenanceClassification.timedOut: 1,
      BookSourceMaintenanceClassification.limited: 2,
      BookSourceMaintenanceClassification.unchecked: 3,
      BookSourceMaintenanceClassification.available: 4,
    };
    merged.sort((a, b) {
      final byClass = priority[a.classification]!.compareTo(
        priority[b.classification]!,
      );
      return byClass != 0 ? byClass : a.source.name.compareTo(b.source.name);
    });
    _cachedAssessmentSourcesRevision = sourceRevision;
    _cachedRunId = maintenanceState.runId;
    _cachedResult = maintenanceState.result;
    _cachedStatus = maintenanceState.status;
    return _cachedAssessments = List.unmodifiable(merged);
  }

  List<BookSourceMaintenanceAssessment> get _visible {
    final query = _search.text.trim().toLowerCase();
    final checkedIds = _checkedOnly ? _currentCheckedIds : const <String>{};
    const problems = {
      BookSourceMaintenanceClassification.limited,
      BookSourceMaintenanceClassification.failed,
      BookSourceMaintenanceClassification.timedOut,
    };
    return _assessments
        .where((item) {
          if (_checkedOnly && !checkedIds.contains(item.source.id)) {
            return false;
          }
          if (_problemsOnly && !problems.contains(item.classification)) {
            return false;
          }
          if (_classification != null &&
              item.classification != _classification) {
            return false;
          }
          if (query.isEmpty) return true;
          final url =
              '${item.source.sourceConfig?['bookSourceUrl'] ?? item.source.apiBaseUrl}';
          return item.source.name.toLowerCase().contains(query) ||
              url.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  String _classificationLabel(BookSourceMaintenanceClassification value) =>
      switch (value) {
        BookSourceMaintenanceClassification.available =>
          context.l10n.bookSourcesMaintenanceAvailable,
        BookSourceMaintenanceClassification.limited =>
          context.l10n.bookSourcesMaintenanceLimited,
        BookSourceMaintenanceClassification.failed =>
          context.l10n.bookSourcesMaintenanceFailed,
        BookSourceMaintenanceClassification.timedOut =>
          context.l10n.bookSourcesMaintenanceTimedOut,
        BookSourceMaintenanceClassification.unchecked =>
          context.l10n.bookSourcesMaintenanceUnchecked,
      };

  String _assessmentDetail(BookSourceMaintenanceAssessment item) =>
      switch (item.classification) {
        BookSourceMaintenanceClassification.timedOut =>
          context.l10n.bookSourcesMaintenanceTimeoutReason,
        BookSourceMaintenanceClassification.unchecked =>
          context.l10n.bookSourcesMaintenanceUncheckedReason,
        BookSourceMaintenanceClassification.available =>
          context.l10n.bookSourcesMaintenanceAvailableReason,
        _ =>
          (item.healthResult?.missingForFullAvailability ?? const {})
              .map(
                (capability) =>
                    sourceHealthCapabilityLabel(context, capability),
              )
              .join(' · '),
      };

  Future<void> _start() async {
    if (_mutationBusy || widget.maintenance.state.isRunning) return;
    setState(() {
      _actionFailure = null;
      _checkedOnly = false;
      _selected.clear();
    });
    final ids = _scopeIds;
    final targets = _checkableSources
        .where((source) => ids.contains(source.id))
        .toList(growable: false);
    if (targets.isEmpty || widget.maintenance.state.isRunning) return;
    try {
      await widget.maintenance.begin(targets);
      if (mounted) await widget.controller.load();
    } on Object catch (error) {
      if (mounted) setState(() => _actionFailure = error);
    }
  }

  Future<void> _resume() async {
    if (_mutationBusy || widget.maintenance.state.isRunning) return;
    setState(() => _actionFailure = null);
    try {
      await widget.maintenance.resume();
      if (mounted) await widget.controller.load();
    } on Object catch (error) {
      if (mounted) setState(() => _actionFailure = error);
    }
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_mutationBusy || widget.maintenance.state.isRunning) return;
    setState(() {
      _busy = true;
      _actionFailure = null;
    });
    try {
      await action();
      if (widget.controller.state.failure case final failure?) {
        if (mounted) setState(() => _actionFailure = failure);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _actionFailure = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disableSelected() => _runBusy(() async {
    final enabledIds = widget.controller.state.sources
        .where((source) => source.enabled && _selected.contains(source.id))
        .map((source) => source.id)
        .toSet();
    if (enabledIds.isEmpty) return;
    await widget.controller.disableSources(enabledIds);
    widget.maintenance.reconcileSources(widget.controller.state.sources);
  });

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty ||
        _mutationBusy ||
        widget.maintenance.state.isRunning) {
      return;
    }
    final ids = Set<String>.of(_selected);
    final referencedCount = ids.intersection(_referenced).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.bookSourcesRemoveTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.bookSourcesDeleteSelectedMessage(ids.length)),
            if (referencedCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.bookSourcesMaintenanceDeleteReferencedWarning(
                  referencedCount,
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.bookSourcesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.bookSourcesConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBusy(() async {
      await widget.controller.removeSources(ids);
      if (widget.controller.state.failure == null) {
        widget.maintenance.reconcileSources(widget.controller.state.sources);
        _selected.removeAll(ids);
      }
    });
  }

  bool _useWideLayout(BuildContext context, double width) =>
      width >= 800 &&
      MediaQuery.sizeOf(context).height >= 560 &&
      MediaQuery.textScalerOf(context).scale(14) <= 18;

  @override
  Widget build(BuildContext context) {
    final busy = _mutationBusy || widget.maintenance.state.isRunning;
    final visible = _visible;
    final visibleIds = visible.map((item) => item.source.id).toSet();
    _selected.retainAll(visibleIds);
    final canDisable = visible.any(
      (item) => item.source.enabled && _selected.contains(item.source.id),
    );
    return FloatingSubpageScaffold(
      title: context.l10n.bookSourcesMaintenanceTitle,
      maxHeaderWidth: 1320,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = _useWideLayout(context, constraints.maxWidth);
          final results = _resultSlivers(visible, busy, wide: wide);
          if (!wide) {
            return CustomScrollView(
              key: const Key('bookSourceMaintenanceScroll'),
              slivers: [
                SliverPadding(
                  padding: floatingSubpagePadding(context, bottom: 20),
                  sliver: SliverToBoxAdapter(child: _checkControls(busy)),
                ),
                SliverToBoxAdapter(child: _resultTools(visibleIds, busy)),
                ...results,
              ],
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: floatingSubpagePadding(
                  context,
                  left: 24,
                  right: 24,
                  bottom: 12,
                ),
                child: Row(
                  key: const Key('maintenanceWideLayout'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth < 1000 ? 240 : 280,
                      child: SingleChildScrollView(
                        key: const Key('maintenanceControlsScroll'),
                        child: _checkControls(busy, wide: true),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Material(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _resultTools(visibleIds, busy, wide: true),
                            Expanded(
                              child: CustomScrollView(
                                key: const Key('bookSourceMaintenanceScroll'),
                                slivers: results,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final wide = _useWideLayout(context, constraints.maxWidth);
          return Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Padding(
                padding: EdgeInsets.only(
                  left: wide ? (constraints.maxWidth < 1000 ? 288 : 328) : 0,
                  right: wide ? 24 : 0,
                ),
                child: _selectionBar(busy, canDisable),
              ),
            ),
          );
        },
      ),
    );
  }
}
