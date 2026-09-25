import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/services/book_source_change_service.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/book_source_registry.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/utils/localization_extension.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

import 'widgets/sourced_book_cards.dart';

enum _ChangeView { results, confirmation }

class BookSourceChangePage extends StatefulWidget {
  const BookSourceChangePage({
    super.key,
    this.currentSource,
    required this.currentBook,
    this.sources,
    this.sourcesFuture,
    this.shelfBook,
    this.service,
    this.serviceFactory,
  }) : assert(service == null || serviceFactory == null),
       assert(sources != null || sourcesFuture != null);

  final List<RegisteredBookSource>? sources;
  final Future<List<RegisteredBookSource>>? sourcesFuture;
  final RegisteredBookSource? currentSource;
  final BookSourceBook currentBook;
  final Book? shelfBook;
  final BookSourceChangeService? service;
  final BookSourceChangeService Function()? serviceFactory;

  @override
  State<BookSourceChangePage> createState() => _BookSourceChangePageState();
}

class _BookSourceChangePageState extends State<BookSourceChangePage> {
  static const int _quickSourceLimit = 60;
  static const int _quickCandidateLimit = 8;

  late final bool _ownsService = widget.service == null;
  late final BookSourceChangeService _service =
      widget.service ??
      (widget.serviceFactory ?? BookSourceChangeService.new)();
  late final TextEditingController _queryController = TextEditingController(
    text: widget.currentBook.title,
  );
  late final Future<BookSourceChangePosition> _positionFuture;
  StreamSubscription<BookSourceChangeSearchEvent>? _searchSubscription;
  Timer? _resultFlushTimer;
  Timer? _slowCheckTimer;
  BookDownloadCancellation? _positionCancellation;
  BookDownloadCancellation? _validationCancellation;

  BookSourceChangePosition? _position;
  List<RegisteredBookSource> _sources = const [];
  List<BookSourceChangeCandidate> _candidates = <BookSourceChangeCandidate>[];
  final List<BookSourceChangeCandidate> _pendingCandidates = [];
  final Set<String> _candidateKeys = {};
  final Map<String, int> _candidateArrivalOrder = {};
  int _nextCandidateArrivalOrder = 0;
  final Set<String> _searchedSourceIds = {};
  BookSourceChangeCandidate? _selected;
  ValidatedBookSourceChange? _validated;
  Object? _validationError;
  Object? _commitError;
  Object? _sourceLoadError;
  BookSourceChangeValidationStage? _validationStage;
  _ChangeView _view = _ChangeView.results;
  int _generation = 0;
  int _validationGeneration = 0;
  int _completed = 0;
  int _failed = 0;
  int _total = 0;
  int _pendingCompleted = 0;
  int _pendingFailed = 0;
  bool _checkAuthor = true;
  bool _preparing = true;
  bool _searching = false;
  bool _hasMoreSources = false;
  bool _validating = false;
  bool _committing = false;
  bool _slowCheck = false;
  bool _positionLoadFailed = false;
  int _searchBatchTotal = 0;

  @override
  void initState() {
    super.initState();
    _positionFuture = _loadPosition();
    unawaited(_positionFuture.then<void>((_) {}, onError: (_, _) {}));
    unawaited(_loadSourcesAndSearch());
  }

  @override
  void dispose() {
    final searchSubscription = _searchSubscription;
    _searchSubscription = null;
    _generation++;
    _resultFlushTimer?.cancel();
    _slowCheckTimer?.cancel();
    _positionCancellation?.cancel();
    _validationCancellation?.cancel();
    _queryController.dispose();
    unawaited(_closeOwnedService(searchSubscription));
    super.dispose();
  }

  Future<void> _closeOwnedService(
    StreamSubscription<BookSourceChangeSearchEvent>? searchSubscription,
  ) async {
    await searchSubscription?.cancel();
    if (_ownsService) _service.close();
  }

  Future<BookSourceChangePosition> _loadPosition() async {
    final source = widget.currentSource;
    final cancellation = _positionCancellation = BookDownloadCancellation();
    BookSourceChangePosition position;
    try {
      position = source == null
          ? const BookSourceChangePosition(
              chapterIndex: 0,
              chapterProgress: 0,
              chapterTitle: '',
              chapterCount: 0,
            )
          : await _service.loadPosition(
              source: source,
              book: widget.currentBook,
              shelfBook: widget.shelfBook,
              cancellation: cancellation,
            );
    } catch (_) {
      // The old source can be broken or its progress store unavailable. Let
      // the user pick a chapter manually instead of trapping this flow.
      position = const BookSourceChangePosition(
        chapterIndex: 0,
        chapterProgress: 0,
        chapterTitle: '',
        chapterCount: 0,
      );
      _positionLoadFailed = true;
    }
    if (mounted) setState(() => _position = position);
    return position;
  }

  Future<void> _loadSourcesAndSearch({bool retry = false}) async {
    if (retry) setState(() => _preparing = true);
    List<RegisteredBookSource> sources;
    try {
      sources = await (retry
          ? BookSourceRegistry().loadRunnableInBackground()
          : widget.sourcesFuture ??
                Future<List<RegisteredBookSource>>.value(widget.sources!));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceLoadError = error;
        _preparing = false;
        _searching = false;
      });
      return;
    }
    if (!mounted) return;
    final total = _searchTargetCount(sources);
    setState(() {
      _sources = sources;
      _sourceLoadError = null;
      _preparing = false;
      _total = total;
      _searchBatchTotal = total < _quickSourceLimit ? total : _quickSourceLimit;
      _searching = total > 0;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _startSearch();
  }

  Future<void> _startSearch({bool continueSearch = false}) async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _preparing) return;
    final generation = ++_generation;
    final previousSearch = _searchSubscription;
    _searchSubscription = null;
    if (previousSearch != null) unawaited(previousSearch.cancel());
    _resultFlushTimer?.cancel();
    _resultFlushTimer = null;
    _pendingCandidates.clear();
    if (!continueSearch) {
      _candidateKeys.clear();
      _candidateArrivalOrder.clear();
      _nextCandidateArrivalOrder = 0;
      _searchedSourceIds.clear();
    }
    _pendingCompleted = _searchedSourceIds.length;
    _pendingFailed = 0;
    final targetCount = _searchTargetCount(_sources);
    setState(() {
      _sourceLoadError = null;
      if (!continueSearch) {
        _candidates = <BookSourceChangeCandidate>[];
        _selected = null;
        _validated = null;
        _validationError = null;
        _commitError = null;
        _validating = false;
        _completed = 0;
        _failed = 0;
      }
      _total = targetCount;
      _searchBatchTotal = continueSearch
          ? targetCount
          : (targetCount < _quickSourceLimit ? targetCount : _quickSourceLimit);
      _searching = targetCount > _searchedSourceIds.length;
      _hasMoreSources = false;
    });
    final completedOffset = _searchedSourceIds.length;
    _searchSubscription = _service
        .search(
          sources: _sources,
          title: query,
          author: widget.currentBook.author,
          checkAuthor: _checkAuthor,
          currentSourceId: widget.currentSource?.id,
          excludedSourceIds: _searchedSourceIds,
          sourceLimit: continueSearch ? null : _quickSourceLimit,
          candidateLimit: continueSearch ? null : _quickCandidateLimit,
        )
        .listen(
          (event) {
            if (!mounted || generation != _generation) return;
            _searchedSourceIds.add(event.source.id);
            for (final item in event.candidates) {
              final key = '${item.source.id}\u0000${item.book.id}';
              if (!_candidateKeys.add(key)) continue;
              _candidateArrivalOrder[key] = _nextCandidateArrivalOrder++;
              _pendingCandidates.add(item);
            }
            _pendingCompleted = completedOffset + event.completed;
            if (event.error != null) _pendingFailed++;
            _scheduleResultFlush(generation);
          },
          onError: (Object error) {
            if (!mounted || generation != _generation) return;
            setState(() => _sourceLoadError = error);
            _flushSearchResults(generation, done: true);
          },
          onDone: () => _flushSearchResults(generation, done: true),
        );
  }

  void _scheduleResultFlush(int generation) {
    if (_resultFlushTimer?.isActive ?? false) return;
    _resultFlushTimer = Timer(
      const Duration(milliseconds: 120),
      () => _flushSearchResults(generation),
    );
  }

  void _flushSearchResults(int generation, {bool done = false}) {
    _resultFlushTimer?.cancel();
    _resultFlushTimer = null;
    if (!mounted || generation != _generation) return;
    final added = List<BookSourceChangeCandidate>.of(_pendingCandidates);
    final completed = _pendingCompleted;
    final failed = _pendingFailed;
    _pendingCandidates.clear();
    _pendingFailed = 0;
    setState(() {
      _candidates.addAll(added);
      // Keep visible rows in place while results stream in. Reorder once the
      // batch ends, when the user is no longer reaching for a moving row.
      if (done && _view == _ChangeView.results) {
        _candidates.sort(_compareCandidateRelevance);
      }
      _completed = completed;
      _failed += failed;
      if (done) {
        _searching = false;
        _hasMoreSources = _searchedSourceIds.length < _total;
      }
    });
  }

  void _stopSearch() {
    if (!_searching) return;
    final pending = List<BookSourceChangeCandidate>.of(_pendingCandidates);
    _pendingCandidates.clear();
    _resultFlushTimer?.cancel();
    _resultFlushTimer = null;
    _generation++;
    final subscription = _searchSubscription;
    _searchSubscription = null;
    unawaited(subscription?.cancel());
    setState(() {
      _candidates.addAll(pending);
      _completed = _pendingCompleted;
      _failed += _pendingFailed;
      _pendingFailed = 0;
      _searching = false;
      _hasMoreSources = _searchedSourceIds.length < _total;
    });
  }

  int _compareCandidateRelevance(
    BookSourceChangeCandidate a,
    BookSourceChangeCandidate b,
  ) {
    final authorRank = (b.authorMatches ? 1 : 0).compareTo(
      a.authorMatches ? 1 : 0,
    );
    if (authorRank != 0) return authorRank;
    final orderA =
        _candidateArrivalOrder['${a.source.id}\u0000${a.book.id}'] ?? 0;
    final orderB =
        _candidateArrivalOrder['${b.source.id}\u0000${b.book.id}'] ?? 0;
    return orderA.compareTo(orderB);
  }

  Future<void> _selectCandidate(
    BookSourceChangeCandidate candidate, {
    int? selectedChapterIndex,
  }) async {
    if (_committing) return;
    _stopSearch();
    _validationCancellation?.cancel();
    _slowCheckTimer?.cancel();
    final validationGeneration = ++_validationGeneration;
    final cancellation = _validationCancellation = BookDownloadCancellation();
    setState(() {
      _view = _ChangeView.confirmation;
      _selected = candidate;
      _validated = null;
      _validationError = null;
      _commitError = null;
      _validationStage = null;
      _validating = true;
      _slowCheck = false;
    });
    _slowCheckTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || validationGeneration != _validationGeneration) return;
      setState(() => _slowCheck = true);
    });
    try {
      final position = _position ?? await _positionFuture;
      if (!mounted || validationGeneration != _validationGeneration) return;
      final validated = await _service.validate(
        candidate: candidate,
        position: position,
        cancellation: cancellation,
        selectedChapterIndex: selectedChapterIndex,
        onStage: (stage) {
          if (!mounted || validationGeneration != _validationGeneration) return;
          setState(() => _validationStage = stage);
        },
      );
      if (!mounted || validationGeneration != _validationGeneration) return;
      setState(() => _validated = validated);
    } catch (error) {
      if (!mounted || validationGeneration != _validationGeneration) return;
      setState(() => _validationError = error);
    } finally {
      _slowCheckTimer?.cancel();
      if (mounted && validationGeneration == _validationGeneration) {
        setState(() => _validating = false);
      }
    }
  }

  void _backToResults() {
    if (_committing) return;
    _validationGeneration++;
    _validationCancellation?.cancel();
    _slowCheckTimer?.cancel();
    setState(() {
      _view = _ChangeView.results;
      _validating = false;
      _slowCheck = false;
    });
  }

  void _handleBack() {
    if (_committing) return;
    if (_view == _ChangeView.confirmation) {
      _backToResults();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _commit() async {
    final validated = _validated;
    if (validated == null || _committing) return;
    setState(() {
      _committing = true;
      _commitError = null;
    });
    try {
      final result = await _service.commit(
        validated: validated,
        shelfBook: widget.shelfBook,
        mappingConfirmed: true,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _committing = false;
        _commitError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _view == _ChangeView.results && !_committing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _view == _ChangeView.confirmation) _backToResults();
      },
      child: FloatingSubpageScaffold(
        title: _view == _ChangeView.confirmation
            ? context.l10n.bookSourceChangeConfirmTitle
            : widget.currentSource == null
            ? context.l10n.bookSourceBindSource
            : context.l10n.bookSourceChangeSourceTitle,
        onBack: _handleBack,
        body: Padding(
          padding: EdgeInsets.only(
            top: FloatingSubpageScaffold.headerExtentOf(context),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _view == _ChangeView.confirmation
                  ? _buildConfirmation(context)
                  : _buildResults(context),
            ),
          ),
        ),
      ),
    );
  }

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
        TextField(
          key: const Key('bookSourceChangeQuery'),
          controller: _queryController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _startSearch(),
          decoration: InputDecoration(
            labelText: context.l10n.bookSourceChangeSearchLabel,
            prefixIcon: const Icon(Icons.manage_search_rounded),
            suffixIcon: IconButton(
              tooltip: context.l10n.bookSourceChangeSearchAgain,
              onPressed: _preparing ? null : _startSearch,
              icon: const Icon(Icons.refresh_rounded),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
              onSelected: (selected) {
                setState(() => _checkAuthor = selected);
                unawaited(_startSearch());
              },
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

class _SourceRailStop extends StatelessWidget {
  const _SourceRailStop({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyChangeState extends StatelessWidget {
  const _EmptyChangeState({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            else
              Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterSelectionSheet extends StatefulWidget {
  const _ChapterSelectionSheet({
    required this.chapters,
    required this.initialIndex,
  });

  final List<BookSourceChapter> chapters;
  final int initialIndex;

  @override
  State<_ChapterSelectionSheet> createState() => _ChapterSelectionSheetState();
}

class _ChapterSelectionSheetState extends State<_ChapterSelectionSheet> {
  final TextEditingController _queryController = TextEditingController();
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: widget.initialIndex * 56.0,
  );
  late List<int> _visibleIndices = List<int>.generate(
    widget.chapters.length,
    (index) => index,
  );

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _visibleIndices = [
        for (var index = 0; index < widget.chapters.length; index++)
          if (normalized.isEmpty ||
              widget.chapters[index].title.toLowerCase().contains(normalized) ||
              '${index + 1}' == normalized)
            index,
      ];
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _queryController,
                      onChanged: _filter,
                      decoration: InputDecoration(
                        labelText: context.l10n.bookSourceChangeChooseChapter,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemExtent: 56,
                      itemCount: _visibleIndices.length,
                      itemBuilder: (context, index) {
                        final chapterIndex = _visibleIndices[index];
                        return ListTile(
                          title: Text(
                            '${chapterIndex + 1}. ${widget.chapters[chapterIndex].title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(chapterIndex),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
