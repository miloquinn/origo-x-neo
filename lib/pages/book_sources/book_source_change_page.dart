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
import 'package:xxread/widgets/pill_search_field.dart';

import 'widgets/sourced_book_cards.dart';

part 'book_source_change_page_content.dart';

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

  void _setCheckAuthor(bool selected) {
    setState(() => _checkAuthor = selected);
    unawaited(_startSearch());
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
                    child: PillSearchField(
                      controller: _queryController,
                      hintText: context.l10n.bookSourceChangeChooseChapter,
                      onChanged: _filter,
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
