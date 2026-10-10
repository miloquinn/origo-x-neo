part of 'native_reader_page.dart';

final Expando<Future<int>> _nativeLogicalSourceLengthFutures =
    Expando<Future<int>>('native-logical-source-length');

class _NativeProgressChapter {
  const _NativeProgressChapter({
    required this.storageIndex,
    required this.storageEnd,
    this.navigation,
  });

  final int storageIndex;
  final int storageEnd;
  final ReaderNavigationChapter? navigation;
}

extension _NativeReaderProgress on _NativeReaderPageState {
  Widget? _buildProgressPill({
    required List<_NativeChapter> chapters,
    required List<_ReaderPageData> pages,
    required Size paginationSize,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required bool usesTwoPageLayout,
  }) {
    if (!_progressBarEnabled ||
        chapters.isEmpty ||
        pages.isEmpty ||
        _chapterIndex < 0 ||
        _chapterIndex >= chapters.length ||
        chapters[_chapterIndex].plainText.isEmpty) {
      return null;
    }
    final logicalChapters = _nativeProgressChapters(chapters);
    if (logicalChapters.isEmpty) return null;
    final navigationCatalog = _parsedNavigationChapters.isEmpty
        ? null
        : ReaderNavigationCatalog(
            logicalChapters
                .map((entry) => entry.navigation!)
                .toList(growable: false),
          );

    Widget buildPill(
      double verticalProgress,
      int logicalIndex,
      int? sourceLength,
    ) {
      final chapterProgress = _nativeChapterProgress(
        logicalChapters: logicalChapters,
        logicalIndex: logicalIndex,
        chapters: chapters,
        pages: pages,
        verticalProgress: verticalProgress,
        usesTwoPageLayout: usesTwoPageLayout,
        sourceLength: sourceLength,
      );
      final position = ReaderProgressPosition(
        chapterIndex: logicalIndex,
        chapterCount: logicalChapters.length,
        chapterProgress: chapterProgress,
      );
      final busy = _pendingChapterIndex != null;
      return ReaderProgressPill(
        palette: _readerTheme,
        position: position,
        scope: _progressBarScope,
        onSeekStart: busy ? null : _beginNativeProgressPreview,
        onSeek: busy
            ? null
            : (target) => unawaited(
                _seekNativeProgress(
                  target,
                  logicalChapters: logicalChapters,
                  chapters: chapters,
                  paginationSize: paginationSize,
                  textDirection: textDirection,
                  textScaler: textScaler,
                ),
              ),
        onPreviousChapter: !busy && logicalIndex > 0
            ? () => unawaited(
                _changeNativeProgressChapter(
                  logicalIndex - 1,
                  logicalChapters: logicalChapters,
                  chapters: chapters,
                ),
              )
            : null,
        onNextChapter: !busy && logicalIndex + 1 < logicalChapters.length
            ? () => unawaited(
                _changeNativeProgressChapter(
                  logicalIndex + 1,
                  logicalChapters: logicalChapters,
                  chapters: chapters,
                ),
              )
            : null,
      );
    }

    Widget buildForProgress(double verticalProgress) {
      final logicalIndex = _currentNativeProgressChapter(
        logicalChapters,
        chapters,
        pages: pages,
        usesTwoPageLayout: usesTwoPageLayout,
        navigationCatalog: navigationCatalog,
      );
      if (logicalIndex < 0) return const SizedBox.shrink();
      if (_parsedNavigationChapters.isNotEmpty) {
        return buildPill(verticalProgress, logicalIndex, null);
      }
      return FutureBuilder<int>(
        future: _nativeLogicalSourceLength(
          logicalChapters[logicalIndex],
          chapters,
        ),
        builder: (context, snapshot) => snapshot.hasData
            ? buildPill(verticalProgress, logicalIndex, snapshot.data)
            : const SizedBox.shrink(),
      );
    }

    if (_pageMode != NativePageMode.verticalScroll) return buildForProgress(0);
    return ValueListenableBuilder<double>(
      valueListenable: _verticalScrollProgress,
      builder: (context, progress, _) => buildForProgress(progress),
    );
  }

  List<_NativeProgressChapter> _nativeProgressChapters(
    List<_NativeChapter> chapters,
  ) {
    if (_parsedNavigationChapters.isNotEmpty &&
        _navigationChapters.isNotEmpty) {
      return <_NativeProgressChapter>[
        for (final navigation in _navigationChapters)
          if (navigation.index >= 0 && navigation.index < chapters.length)
            _NativeProgressChapter(
              storageIndex: navigation.index,
              storageEnd: navigation.index + 1,
              navigation: navigation,
            ),
      ];
    }

    final result = <_NativeProgressChapter>[];
    var start = 0;
    while (start < chapters.length) {
      final sourceId = chapters[start].sourceChapterId ?? chapters[start].id;
      var end = start + 1;
      while (end < chapters.length &&
          (chapters[end].sourceChapterId ?? chapters[end].id) == sourceId) {
        end++;
      }
      result.add(_NativeProgressChapter(storageIndex: start, storageEnd: end));
      start = end;
    }
    return result;
  }

  Future<int> _nativeLogicalSourceLength(
    _NativeProgressChapter logical,
    List<_NativeChapter> chapters,
  ) {
    final first = chapters[logical.storageIndex];
    return _nativeLogicalSourceLengthFutures[first] ??= () async {
      final last = chapters[logical.storageEnd - 1];
      final tailLength = await last.rawTextLengthAsync();
      return math.max(
        0,
        last.sourceBodyStart + tailLength - first.sourceBodyStart,
      );
    }();
  }

  int _currentNativeProgressChapter(
    List<_NativeProgressChapter> logicalChapters,
    List<_NativeChapter> chapters, {
    required List<_ReaderPageData> pages,
    required bool usesTwoPageLayout,
    required ReaderNavigationCatalog? navigationCatalog,
  }) {
    if (navigationCatalog != null) {
      return _currentNavigationPosition(
        navigationCatalog,
        chapters,
        offsetOverride: _nativeVisibleOffset(
          pages,
          usesTwoPageLayout: usesTwoPageLayout,
        ),
      ).clamp(0, logicalChapters.length - 1);
    }
    var selected = 0;
    for (var index = 0; index < logicalChapters.length; index++) {
      if (logicalChapters[index].storageIndex > _chapterIndex) break;
      selected = index;
    }
    return selected;
  }

  double _nativeChapterProgress({
    required List<_NativeProgressChapter> logicalChapters,
    required int logicalIndex,
    required List<_NativeChapter> chapters,
    required List<_ReaderPageData> pages,
    required double verticalProgress,
    required bool usesTwoPageLayout,
    required int? sourceLength,
  }) {
    final chapter = chapters[_chapterIndex];
    final bounds = _nativeLogicalBounds(logicalChapters, logicalIndex, chapter);
    double localProgress;
    if (_pageMode == NativePageMode.verticalScroll) {
      final offset = (_verticalCanonicalOffset ?? _anchorOffset ?? 0).clamp(
        bounds.$1,
        bounds.$2,
      );
      final length = bounds.$2 - bounds.$1;
      localProgress = length > 0
          ? (offset - bounds.$1) / length
          : verticalProgress.clamp(0.0, 1.0);
    } else {
      final pageIndexes = _nativeLogicalPageIndexes(
        pages,
        bounds.$1,
        bounds.$2,
      );
      if (pageIndexes.length <= 1) {
        localProgress = 1;
      } else {
        final visiblePage = usesTwoPageLayout
            ? math.min(_spreadStartForPage(_pageIndex) + 1, pages.length - 1)
            : _pageIndex.clamp(0, pages.length - 1);
        var localPage = pageIndexes.lastIndexWhere(
          (index) => index <= visiblePage,
        );
        if (localPage < 0) localPage = 0;
        localProgress = (localPage / (pageIndexes.length - 1)).clamp(0.0, 1.0);
      }
    }
    if (_parsedNavigationChapters.isNotEmpty || sourceLength == null) {
      return localProgress;
    }
    final logical = logicalChapters[logicalIndex];
    if (sourceLength <= 0 || logical.storageEnd <= logical.storageIndex + 1) {
      return localProgress;
    }
    final groupStart = chapters[logical.storageIndex].sourceBodyStart;
    final segmentStart = chapter.sourceBodyStart - groupStart;
    final segmentEnd = _chapterIndex + 1 < logical.storageEnd
        ? chapters[_chapterIndex + 1].sourceBodyStart - groupStart
        : sourceLength;
    return ((segmentStart + (segmentEnd - segmentStart) * localProgress) /
            sourceLength)
        .clamp(0.0, 1.0);
  }

  int _nativeVisibleOffset(
    List<_ReaderPageData> pages, {
    required bool usesTwoPageLayout,
  }) {
    if (_pageMode == NativePageMode.verticalScroll) {
      return _verticalCanonicalOffset ?? _anchorOffset ?? 0;
    }
    final pageIndex = usesTwoPageLayout
        ? _spreadStartForPage(_pageIndex)
        : _pageIndex;
    return pages[pageIndex.clamp(0, pages.length - 1)].startOffset;
  }

  (int, int) _nativeLogicalBounds(
    List<_NativeProgressChapter> logicalChapters,
    int logicalIndex,
    _NativeChapter chapter,
  ) {
    final current = logicalChapters[logicalIndex];
    final start = current.navigation == null
        ? 0
        : chapter.navigationOffsetFor(current.navigation!) ?? 0;
    var end = chapter.plainText.length;
    if (logicalIndex + 1 < logicalChapters.length) {
      final next = logicalChapters[logicalIndex + 1];
      if (next.storageIndex == current.storageIndex &&
          next.navigation != null) {
        end = chapter.navigationOffsetFor(next.navigation!) ?? end;
      }
    }
    return (
      start.clamp(0, chapter.plainText.length),
      end.clamp(start, chapter.plainText.length),
    );
  }

  List<int> _nativeLogicalPageIndexes(
    List<_ReaderPageData> pages,
    int start,
    int end,
  ) {
    final result = <int>[];
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      final overlaps = end > start
          ? page.endOffset > start && page.startOffset < end
          : page.startOffset == start;
      if (overlaps || (page.isChapterTitle && start == 0)) result.add(index);
    }
    return result.isEmpty
        ? <int>[
            readerTextPageIndexForOffset(
              pages,
              start,
            ).clamp(0, pages.length - 1),
          ]
        : result;
  }

  void _beginNativeProgressPreview() {
    _cancelAutoSweepOrPause();
    _controlsTimer?.cancel();
    if (mounted && !_controlsVisible) {
      _setReaderState(() => _controlsVisible = true);
    }
  }

  void _commitNativeProgressNavigation() {
    _beginNativeProgressPreview();
    _markReadingPositionChanged();
    _markReaderAloudForManualPageTurn();
  }

  void _keepNativeProgressControlsVisible() {
    _controlsTimer?.cancel();
    if (mounted && !_controlsVisible) {
      _setReaderState(() => _controlsVisible = true);
    }
    _controlsTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _setReaderState(() => _controlsVisible = false);
    });
  }

  Future<void> _seekNativeProgress(
    ReaderProgressTarget target, {
    required List<_NativeProgressChapter> logicalChapters,
    required List<_NativeChapter> chapters,
    required Size paginationSize,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) async {
    if (!mounted ||
        _pendingChapterIndex != null ||
        logicalChapters.isEmpty ||
        paginationSize.isEmpty) {
      return;
    }
    _commitNativeProgressNavigation();
    final logicalIndex = target.chapterIndex.clamp(
      0,
      logicalChapters.length - 1,
    );
    final storageTarget = await _nativeStorageTarget(
      target.chapterProgress,
      logicalIndex: logicalIndex,
      logicalChapters: logicalChapters,
      chapters: chapters,
    );
    if (!mounted || _pendingChapterIndex != null) return;
    await _setChapter(
      storageTarget.$1,
      chapters.length,
      resolveOffset: (chapter) {
        final bounds = _nativeLogicalBounds(
          logicalChapters,
          logicalIndex,
          chapter,
        );
        final navigation = logicalChapters[logicalIndex].navigation;
        if (storageTarget.$2 == 0 && navigation != null) {
          _lastNavigationJumpPosition = _navigationChapters.indexOf(navigation);
          return chapter.navigationOffsetFor(navigation) ?? bounds.$1;
        }
        if (_pageMode == NativePageMode.verticalScroll) {
          return (bounds.$1 + ((bounds.$2 - bounds.$1) * storageTarget.$2))
              .round()
              .clamp(bounds.$1, bounds.$2);
        }
        final targetPages = _pagesFor(
          chapter,
          storageTarget.$1,
          paginationSize,
          textDirection,
          textScaler,
        );
        final pageIndexes = _nativeLogicalPageIndexes(
          targetPages,
          bounds.$1,
          bounds.$2,
        );
        final last = pageIndexes.length - 1;
        final pagePosition = (storageTarget.$2 * last).round();
        return targetPages[pageIndexes[pagePosition.clamp(0, last)]]
            .startOffset;
      },
      centerInViewport: _pageMode == NativePageMode.verticalScroll,
    );
    if (mounted) _keepNativeProgressControlsVisible();
  }

  Future<void> _changeNativeProgressChapter(
    int logicalIndex, {
    required List<_NativeProgressChapter> logicalChapters,
    required List<_NativeChapter> chapters,
  }) async {
    if (!mounted ||
        _pendingChapterIndex != null ||
        logicalIndex < 0 ||
        logicalIndex >= logicalChapters.length) {
      return;
    }
    _commitNativeProgressNavigation();
    final target = logicalChapters[logicalIndex];
    final navigation = target.navigation;
    if (navigation != null) {
      await _jumpToNavigationChapter(navigation, chapters);
    } else {
      await _setChapter(
        target.storageIndex,
        chapters.length,
        resolveOffset: (_) => 0,
        centerInViewport: false,
      );
    }
    if (mounted) _keepNativeProgressControlsVisible();
  }

  Future<(int, double)> _nativeStorageTarget(
    double progress, {
    required int logicalIndex,
    required List<_NativeProgressChapter> logicalChapters,
    required List<_NativeChapter> chapters,
  }) async {
    final logical = logicalChapters[logicalIndex];
    if (_parsedNavigationChapters.isNotEmpty) {
      return (logical.storageIndex, progress.clamp(0.0, 1.0));
    }
    final sourceLength = await _nativeLogicalSourceLength(logical, chapters);
    final bounded = progress.clamp(0.0, 1.0);
    if (bounded == 1 || sourceLength <= 0) {
      return (logical.storageEnd - 1, bounded);
    }
    final groupStart = chapters[logical.storageIndex].sourceBodyStart;
    final sourceOffset = sourceLength * bounded;
    var storageIndex = logical.storageIndex;
    while (storageIndex + 1 < logical.storageEnd &&
        chapters[storageIndex + 1].sourceBodyStart - groupStart <=
            sourceOffset) {
      storageIndex++;
    }
    final segmentStart = chapters[storageIndex].sourceBodyStart - groupStart;
    final segmentEnd = storageIndex + 1 < logical.storageEnd
        ? chapters[storageIndex + 1].sourceBodyStart - groupStart
        : sourceLength;
    final segmentLength = segmentEnd - segmentStart;
    final localProgress = segmentLength <= 0
        ? 0.0
        : ((sourceOffset - segmentStart) / segmentLength).clamp(0.0, 1.0);
    return (storageIndex, localProgress);
  }
}
