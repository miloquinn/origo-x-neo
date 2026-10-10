part of 'book_source_reader_page.dart';

extension _BookSourceReaderChapterLoading on _BookSourceReaderPageState {
  Future<void> _loadChapter(
    int index, {
    double restoreProgress = 0,
    int? restoreTextOffset,
    bool saveCurrent = true,
    bool Function()? shouldApply,
  }) async {
    if (!(shouldApply?.call() ?? true)) return;
    if (index < 0 || index >= _chapters.length) return;
    if (saveCurrent && index > _chapterIndex) _sessionPagesRead++;
    if (saveCurrent && _content != null) unawaited(_saveProgress());
    if (!mounted) return;
    final requestCancellation = _activeReaderRequestCancellation;
    final loadSerial = ++_chapterLoadSerial;
    var catalogGeneration = _catalogGeneration;
    var targetIndex = index;
    bool isCurrent() =>
        mounted &&
        loadSerial == _chapterLoadSerial &&
        catalogGeneration == _catalogGeneration &&
        _isReaderRequestActive(requestCancellation) &&
        (shouldApply?.call() ?? true);
    _updateReaderState(() {
      _loadingContent = true;
      // This load owns the next restore; old frame callbacks are now stale.
      _autoScrollRestoring = false;
      _verticalRestoreShouldApply = null;
      _restoreTextOffset = restoreTextOffset;
      _restorePageProgress = restoreProgress.clamp(0.0, 1.0);
      _requestedChapterIndex = index;
      _error = null;
    });
    try {
      final loaded = await _chapterContentWithRecovery(
        index,
        cancellation: requestCancellation,
        shouldApply: () =>
            mounted &&
            loadSerial == _chapterLoadSerial &&
            _isReaderRequestActive(requestCancellation) &&
            (shouldApply?.call() ?? true),
        onCatalogChanged: (mappedIndex) {
          targetIndex = mappedIndex;
          catalogGeneration = _catalogGeneration;
        },
      );
      if (loaded == null) return;
      targetIndex = loaded.index;
      final content = loaded.content;
      catalogGeneration = _catalogGeneration;
      if (!isCurrent()) return;
      if (await _deferChapterApplyForOpeningFlight(targetIndex)) {
        if (!isCurrent()) return;
      }
      while (isCurrent() &&
          _pageMode != BookSourcePageMode.verticalScroll &&
          !_pagedViewportSize.isEmpty &&
          _cachedPagedLayoutFor(targetIndex, content, _pagedViewportSize) ==
              null) {
        await _warmPagedLayout(targetIndex);
      }
      if (!isCurrent()) return;
      _applyLoadedChapter(
        targetIndex,
        content,
        restoreProgress: restoreProgress,
        restoreTextOffset: restoreTextOffset,
        shouldApply: shouldApply,
      );
    } on BookDownloadCancelledException {
      return;
    } catch (error) {
      if (!isCurrent()) return;
      _updateReaderState(() {
        _loadingContent = false;
        _requestedChapterIndex = targetIndex;
        _error = error;
        _controlsVisible = true;
      });
    } finally {
      // Only this load may clear its cancelled loading surface; a newer load
      // retains ownership of its own requested chapter and restore anchor.
      if (mounted &&
          loadSerial == _chapterLoadSerial &&
          !(shouldApply?.call() ?? true)) {
        _updateReaderState(() {
          _loadingContent = false;
          _requestedChapterIndex = null;
          _restoreTextOffset = null;
        });
      }
    }
  }

  Future<({int index, BookSourceChapterContent content})?>
  _chapterContentWithRecovery(
    int index, {
    required BookDownloadCancellation cancellation,
    required bool Function() shouldApply,
    void Function(int index)? onCatalogChanged,
  }) async {
    var generation = _catalogGeneration;
    bool isCurrent() =>
        mounted &&
        generation == _catalogGeneration &&
        _isReaderRequestActive(cancellation) &&
        shouldApply();
    if (!isCurrent()) return null;
    BookSourceChapterContent content;
    var targetIndex = index;
    try {
      content = await _continuousContentFor(index, cancellation: cancellation);
    } on BookSourceProtocolException catch (error) {
      if (!isCurrent()) return null;
      if (!error.isMissingChapter) rethrow;
      final mapped = await _refreshCatalogChapter(
        index,
        cancellation: cancellation,
        shouldApply: isCurrent,
      );
      if (mapped == null) {
        if (!isCurrent()) return null;
        rethrow;
      }
      targetIndex = mapped;
      generation = _catalogGeneration;
      onCatalogChanged?.call(targetIndex);
      // Only one recovery attempt; surface a second failure to the caller.
      content = await _continuousContentFor(
        targetIndex,
        cancellation: cancellation,
      );
    }
    if (!isCurrent()) return null;
    return (index: targetIndex, content: content);
  }

  Future<int?> _refreshCatalogChapter(
    int index, {
    required BookDownloadCancellation cancellation,
    required bool Function() shouldApply,
    bool following = false,
  }) async {
    final generation = _catalogGeneration;
    final targetChapter = _chapters[index];
    final targetTitle = _sourceChapterTitle(index);
    bool isCurrent() =>
        mounted &&
        generation == _catalogGeneration &&
        _isReaderRequestActive(cancellation) &&
        shouldApply();
    final rawChapters = [
      ...await _client.getChaptersForDownload(
        widget.source,
        widget.book.id,
        sourceVariables: widget.book.sourceVariables,
        cancellation: cancellation,
      ),
    ]..sort((a, b) => a.order.compareTo(b.order));
    if (!isCurrent()) return null;
    if (rawChapters.isEmpty ||
        rawChapters.map((chapter) => chapter.id).toSet().length !=
            rawChapters.length) {
      return null;
    }
    var mappedIndex = _chapterIndexInCatalog(
      rawChapters,
      id: targetChapter.id,
      title: targetTitle,
    );
    if (mappedIndex == null) return null;
    if (following) mappedIndex++;
    if (mappedIndex >= rawChapters.length) return null;
    final chapters = await _withReplacedChapterTitles(rawChapters);
    if (!isCurrent()) return null;
    // Listening can refresh the catalog without turning the visible page yet.
    // Keep that page readable if the next content request is slow or cancelled.
    final visibleContent = _loadingContent ? null : _content;
    final visibleIndex = visibleContent == null
        ? null
        : _chapterIndexInCatalog(
            rawChapters,
            id: _chapters[_chapterIndex].id,
            title: _sourceChapterTitle(_chapterIndex),
          );
    final visibleText = _readableChapterText[_chapterIndex];
    final visibleActions = _paragraphActions[_chapterIndex];
    final visibleOffset = _currentTextOffset;
    final visibleProgress = _currentReadingProgress;
    _updateReaderState(() {
      _replaceChapterCatalog(chapters, {
        for (final chapter in rawChapters) chapter.id: chapter.title,
      });
      if (visibleContent != null && visibleIndex != null) {
        _chapterIndex = visibleIndex;
        _content = visibleContent;
        _prefetchedContent[visibleIndex] = visibleContent;
        if (visibleText != null) {
          _readableChapterText[visibleIndex] = visibleText;
          if (visibleActions != null) {
            _paragraphActions[visibleIndex] = visibleActions;
          }
        }
        _restoreTextOffset = visibleOffset;
        _restorePageProgress = visibleProgress;
        _restorePagedPosition = true;
      }
      if (_loadingContent) _requestedChapterIndex = mappedIndex;
    });
    return mappedIndex;
  }

  int? _chapterIndexInCatalog(
    List<BookSourceChapter> chapters, {
    required String id,
    required String title,
  }) {
    final byId = chapters.indexWhere((chapter) => chapter.id == id);
    if (byId >= 0) return byId;
    final normalizedTitle = normalizeChapterTitle(title);
    if (normalizedTitle.isEmpty) return null;
    final matches = chapters.indexed.where(
      (entry) => normalizeChapterTitle(entry.$2.title) == normalizedTitle,
    );
    return matches.length == 1 ? matches.single.$1 : null;
  }

  void _applyLoadedChapter(
    int index,
    BookSourceChapterContent content, {
    required double restoreProgress,
    required int? restoreTextOffset,
    bool Function()? shouldApply,
  }) {
    final normalizedProgress = restoreProgress.clamp(0.0, 1.0);
    final preparedLayout = _preparedPagedLayoutForChapter(index, content);
    final preparedPages = preparedLayout?.pages;
    final preparedPageCount = preparedPages?.length ?? 1;
    final preparedTarget = preparedPages == null
        ? 0
        : restoreTextOffset != null
        ? bookSourcePageIndexForOffset(preparedPages, restoreTextOffset)
        : ((preparedPageCount - 1) * normalizedProgress).round();
    final preparedPageIndex = preparedPages == null
        ? 0
        : (_usesTwoPageLayout
                  ? _spreadStartForPage(preparedTarget)
                  : preparedTarget)
              .clamp(0, preparedPageCount - 1);
    final slideLeading = _slideLeadingPageCount(index);
    _pagedLayouts.removeWhere(
      (chapterIndex, _) => chapterIndex < index - 1 || chapterIndex > index + 2,
    );
    _pagedLayoutWarms.removeWhere(
      (chapterIndex, _) => chapterIndex < index - 1 || chapterIndex > index + 2,
    );
    _updateReaderState(() {
      _chapterIndex = index;
      _content = content;
      _prefetchedContent[index] = content;
      _loadingContent = false;
      _requestedChapterIndex = null;
      _pageIndex = preparedPageIndex;
      _pageCount = preparedPageCount;
      _pageViewLeading = slideLeading;
      _paginatedPages = preparedPages ?? const [];
      _paginationKey = preparedLayout?.fingerprint;
      _restorePageProgress = normalizedProgress;
      _restorePagedPosition = preparedLayout == null;
      _verticalRestoreShouldApply =
          _pageMode == BookSourcePageMode.verticalScroll ? shouldApply : null;
      _restoreTextOffset = preparedLayout == null ? restoreTextOffset : null;
      _ignoreSlidePageChanges = true;
      _horizontalPageTurnTracker.clear();
      _pendingSlideChapterIndex = null;
      _pendingSlideBoundaryViewIndex = null;
    });
    _trimChapterMemoryCaches();
    _restartReaderAloudFromCurrentPageAfterManualTurn();
    if (_pageMode == BookSourcePageMode.horizontalSlide) {
      _replaceSlidePageController(
        initialPage: preparedPageIndex + slideLeading,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ignoreSlidePageChanges = false;
      });
    }
    _scrollProgress.value = normalizedProgress;
    unawaited(_preloadAround(index));
  }

  _BookSourcePagedLayout? _preparedPagedLayoutForChapter(
    int index,
    BookSourceChapterContent content,
  ) {
    if (_pageMode == BookSourcePageMode.verticalScroll ||
        _pagedViewportSize.isEmpty) {
      return null;
    }
    return _cachedPagedLayoutFor(index, content, _pagedViewportSize);
  }

  int _slideLeadingPageCount(int chapterIndex) {
    if (chapterIndex <= 0) return 0;
    final previousContent = _prefetchedContent[chapterIndex - 1];
    if (previousContent == null || _pagedViewportSize.isEmpty) return 1;
    final previousLayout = _cachedPagedLayoutFor(
      chapterIndex - 1,
      previousContent,
      _pagedViewportSize,
    );
    return previousLayout?.pages.length ?? 1;
  }

  void _replaceSlidePageController({required int initialPage}) {
    final previous = _pageController;
    _pageController = PageController(initialPage: initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  Future<void> _preloadAround(int index) async {
    final generation = _catalogGeneration;
    // The next chapter is the only cache entry needed for a forward turn.
    // Load and lay it out before competing for a source connection with the
    // backwards preview or the farther look-ahead chapter.
    await _preloadChapter(index + 1);
    if (!mounted || generation != _catalogGeneration) return;
    for (final chapterIndex in <int>[index - 1, index + 2]) {
      unawaited(_preloadChapter(chapterIndex));
    }
  }

  Future<void> _preloadChapter(int index) async {
    if (index < 0 || index >= _chapters.length) return;
    final generation = _catalogGeneration;
    try {
      await _continuousContentFor(index);
      if (!mounted || generation != _catalogGeneration) return;
      _schedulePagedLayoutWarm(index);
    } catch (_) {
      // Adjacent content is opportunistic and can be retried on demand.
    }
  }

  Future<BookSourceChapterContent> _continuousContentFor(
    int index, {
    BookDownloadCancellation? cancellation,
  }) {
    final requestCancellation =
        cancellation ?? _activeReaderRequestCancellation;
    requestCancellation.throwIfCancelled();
    final cached = _prefetchedContent[index];
    if (cached != null && _readableChapterText.containsKey(index)) {
      return Future.value(cached);
    }
    final inFlight = _continuousContentLoads[index];
    if (inFlight != null) return inFlight;
    final generation = _catalogGeneration;
    final chapter = _chapters[index];
    final chapterTitle = _sourceChapterTitle(index);
    bool isCurrent() =>
        mounted &&
        _isReaderRequestActive(requestCancellation) &&
        generation == _catalogGeneration &&
        index < _chapters.length &&
        _chapters[index].id == chapter.id;
    late final Future<BookSourceChapterContent> future;
    final contentFuture = cached != null
        ? Future<BookSourceChapterContent>.value(cached)
        : _client.getChapterContent(
            widget.source,
            bookId: widget.book.id,
            chapterId: chapter.id,
            sourceVariables: {
              ...widget.book.sourceVariables,
              'chapterIndex': '$index',
              'chapterTitle': chapterTitle,
              'bookName': widget.book.title,
              'bookAuthor': widget.book.author,
              'bookType': '${widget.book.type}',
            },
            cancellation: requestCancellation,
          );
    future = contentFuture
        .then((content) async {
          if (!isCurrent()) return content;
          final projection = isImageOnlyBookSourceChapter(content)
              ? const BookSourceChapterProjection(text: '')
              : await readableBookSourceChapterProjectionAsync(
                  content,
                  fallbackTitle: chapterTitle,
                );
          if (!isCurrent()) return content;
          final replacement = await _replaceRules.applyBatchAsync(
            <String>[projection.text],
            bookTitle: widget.book.title,
            sourceName: widget.source.name,
            sourceUrl: _replaceRuleSourceUrl,
            bookId: _replaceRuleBookId,
            eligibleByDefault: _replaceRulesEligibleByDefault,
            ranges: [
              [
                for (final action in projection.actions)
                  ReplaceRuleTextRange(
                    id: action.id,
                    startOffset: action.startOffset,
                    endOffset: action.endOffset,
                  ),
              ],
            ],
          );
          if (!isCurrent()) return content;
          final replacedText = replacement.values.single;
          _effectiveReplaceRuleIdsByChapter[index] = replacement
              .effectiveRuleIds
              .toSet();
          if (index == _chapterIndex) {
            _effectiveReplaceRuleIds = Set<String>.unmodifiable(
              _effectiveReplaceRuleIdsByChapter[index]!,
            );
          }
          _readableChapterText[index] = replacedText;
          final originalActions = {
            for (final action in projection.actions) action.id: action,
          };
          _paragraphActions[index] = List.unmodifiable([
            for (final range in replacement.mappedRanges.single)
              if (originalActions[range.id] case final action?)
                if (range.endOffset > range.startOffset &&
                    replacedText
                        .substring(range.startOffset, range.endOffset)
                        .trim()
                        .isNotEmpty)
                  action.copyWith(
                    startOffset: range.startOffset,
                    endOffset: range.endOffset,
                  ),
          ]);
          while (_readableChapterText.length >
              _bookSourceReadableChapterTextLimit) {
            final evicted = _readableChapterText.keys.first;
            _readableChapterText.remove(evicted);
            _paragraphActions.remove(evicted);
          }
          await _loadOnlinePagination(index);
          if (!isCurrent()) return content;
          _prefetchedContent[index] = content;
          _trimChapterMemoryCaches();
          if (!mounted) {
            return content;
          }
          final pageStep = _usesTwoPageLayout ? 2 : 1;
          final updatesCurrentContent =
              !_loadingContent && _chapterIndex == index && _content != content;
          final revealsPagedBoundary =
              !_loadingContent &&
              _pageMode != BookSourcePageMode.verticalScroll &&
              ((index == _chapterIndex + 1 &&
                      _pageIndex + pageStep >= _pageCount) ||
                  (index == _chapterIndex - 1 && _pageIndex < pageStep));
          if (updatesCurrentContent || revealsPagedBoundary) {
            _updateReaderState(() {
              if (updatesCurrentContent) {
                _content = content;
              }
            });
          }
          _schedulePagedLayoutWarm(index);
          return content;
        })
        .whenComplete(() {
          if (identical(_continuousContentLoads[index], future)) {
            _continuousContentLoads.remove(index);
          }
        });
    _continuousContentLoads[index] = future;
    return future;
  }

  void _trimChapterMemoryCaches({bool aggressive = false}) {
    if (_chapters.isEmpty) return;
    final center = _chapterIndex;
    final requested = _requestedChapterIndex;
    bool retain(int index) {
      if (index == center || index == requested) return true;
      if (aggressive) return false;
      return index >= center - 1 &&
          index <=
              (_autoWholeBook
                  ? math.max(center + 2, _autoRetainThrough)
                  : center + 2);
    }

    _prefetchedContent.removeWhere((index, _) => !retain(index));
    _readableChapterText.removeWhere((index, _) => !retain(index));
    _paragraphActions.removeWhere((index, _) => !retain(index));
    _pagedLayouts.removeWhere((index, _) => !retain(index));
    _verticalLayouts.removeWhere((index, _) => !retain(index));
    _pagedLayoutWarms.removeWhere((index, _) => !retain(index));
    _verticalPartKeys.removeWhere((key, _) {
      final separator = key.indexOf(':');
      final chapter = int.tryParse(
        separator < 0 ? key : key.substring(0, separator),
      );
      return chapter != null && !retain(chapter);
    });
  }

  void _releasePaginationPointer(PointerEvent event) {
    _paginationPointers.remove(event.pointer);
    if (_paginationPointers.isNotEmpty) return;
    _paginationPointerReleased?.complete();
    _paginationPointerReleased = null;
  }

  bool get _pageTurnIsAnimating =>
      (_pageController.hasClients &&
          _pageController.position.isScrollingNotifier.value) ||
      _coverPageTurnController.isAnimating ||
      _pageCurlController.isAnimating ||
      _spreadForwardPageCurlController.isAnimating ||
      _spreadBackwardPageCurlController.isAnimating;

  Future<void> _yieldForPagedLayout() async {
    // Layout may be queued while a finger is held still, when Flutter has no
    // transient animation callbacks. Let the gesture finish before measuring.
    do {
      while (mounted && _paginationPointers.isNotEmpty) {
        _paginationPointerReleased ??= Completer<void>();
        await _paginationPointerReleased!.future;
      }
      if (!mounted) return;
      // One event-loop turn per page keeps input responsive. Waiting on frames
      // instead of queuing idle scheduler tasks avoids polling while an
      // animation owns the scheduler.
      if (_paginationYield == null) {
        final yielded = Completer<void>();
        _paginationYield = yielded;
        _paginationYieldTimer = Timer(Duration.zero, () {
          _paginationYieldTimer = null;
          _paginationYield = null;
          yielded.complete();
        });
      }
      await _paginationYield!.future;
      while (mounted && _pageTurnIsAnimating) {
        await SchedulerBinding.instance.endOfFrame;
      }
    } while (mounted && _paginationPointers.isNotEmpty);
  }

  Future<_BookSourcePagedLayout?> _warmPagedLayout(int index) {
    final content = _prefetchedContent[index];
    if (!mounted ||
        content == null ||
        _pagedViewportSize.isEmpty ||
        _pageMode == BookSourcePageMode.verticalScroll) {
      return Future.value();
    }
    final viewport = _pagedViewportSize;
    final cached = _cachedPagedLayoutFor(index, content, viewport);
    if (cached != null) return Future.value(cached);
    final existing = _pagedLayoutWarms[index];
    if (existing != null) return existing;
    final generation = _catalogGeneration;
    late final Future<_BookSourcePagedLayout?> future;
    future = Future<void>.value()
        .then((_) async {
          if (!mounted) return null;
          final settled = BookOpenTransition.openingFlightSettledListenableOf(
            context,
          );
          if (settled != null && !settled.value) {
            final ready = Completer<void>();
            void onSettled() {
              if (!settled.value) return;
              settled.removeListener(onSettled);
              ready.complete();
            }

            settled.addListener(onSettled);
            await Future.any([ready.future, _paginationDisposed.future]);
            settled.removeListener(onSettled);
          }
          if (!mounted || !identical(_pagedLayoutWarms[index], future)) {
            return null;
          }
          final result = await _preparePagedLayoutFor(
            index,
            content,
            viewport,
            yieldBetweenPages: _yieldForPagedLayout,
            isCurrent: () =>
                generation == _catalogGeneration &&
                identical(_pagedLayoutWarms[index], future) &&
                _pagedViewportSize == viewport &&
                identical(_prefetchedContent[index], content),
          );
          if (result != null && mounted && generation == _catalogGeneration) {
            final leading = _slideLeadingPageCount(_chapterIndex);
            final needsSlideRebase =
                _pageMode == BookSourcePageMode.horizontalSlide &&
                index == _chapterIndex - 1 &&
                leading != _pageViewLeading;
            _updateReaderState(() {
              if (needsSlideRebase) {
                _pageViewLeading = leading;
                _ignoreSlidePageChanges = true;
              }
            });
            if (needsSlideRebase) {
              final controller = _pageController;
              final chapter = _chapterIndex;
              final serial = _chapterLoadSerial;
              final paginationKey = _paginationKey;
              bool isCurrent() =>
                  mounted &&
                  _pageMode == BookSourcePageMode.horizontalSlide &&
                  _chapterIndex == chapter &&
                  _chapterLoadSerial == serial &&
                  _paginationKey == paginationKey &&
                  _pageViewLeading == leading &&
                  identical(_pageController, controller);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!isCurrent()) return;
                if (controller.hasClients) {
                  controller.jumpToPage(_pageIndex + leading);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isCurrent()) _ignoreSlidePageChanges = false;
                });
              });
            }
          }
          return result;
        })
        .whenComplete(() {
          if (identical(_pagedLayoutWarms[index], future)) {
            _pagedLayoutWarms.remove(index);
          }
        });
    _pagedLayoutWarms[index] = future;
    return future;
  }

  void _schedulePagedLayoutWarm(int index) {
    if (!mounted ||
        index < 0 ||
        index >= _chapters.length ||
        (index != _chapterIndex + 1 && index != _chapterIndex - 1)) {
      return;
    }
    unawaited(
      _warmPagedLayout(index).catchError((Object error) {
        debugPrint('prepare adjacent chapter failed: $error');
        return null;
      }),
    );
  }

  Future<void> _jumpToVerticalChapter(
    int index, {
    int? textOffset,
    double progress = 0,
    bool Function()? shouldApply,
  }) async {
    if (!(shouldApply?.call() ?? true)) return;
    if (index < 0 || index >= _chapters.length) return;
    // The loaded chapter keeps its canonical restore pending until the shared
    // vertical layout commits it. Two-list scroll animations can duplicate
    // keyed chapter cells and race a lifecycle or geometry restore.
    await _loadChapter(
      index,
      restoreProgress: progress,
      restoreTextOffset: textOffset,
      shouldApply: shouldApply,
    );
  }
}
