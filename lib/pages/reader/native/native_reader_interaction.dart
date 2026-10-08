part of 'native_reader_page.dart';

extension _NativeReaderInteraction on _NativeReaderPageState {
  void _handleDesktopNextPage() {
    _cancelAutoSweepOrPause();
    if (_annotationInteractionActive || _visiblePages.isEmpty) return;
    if (_pageMode == NativePageMode.verticalScroll) {
      unawaited(_scrollVerticalByViewport(forward: true));
      return;
    }
    _nextPage(
      _visiblePages,
      _visibleChapterCount,
      usesTwoPageLayout: _visibleUsesTwoPageLayout,
      animate: _tapPageAnimationEnabled,
    );
  }

  void _handleDesktopPreviousPage() {
    _cancelAutoSweepOrPause();
    if (_annotationInteractionActive || _visiblePages.isEmpty) return;
    if (_pageMode == NativePageMode.verticalScroll) {
      unawaited(_scrollVerticalByViewport(forward: false));
      return;
    }
    _previousPage(
      _visiblePages,
      _visibleChapterCount,
      usesTwoPageLayout: _visibleUsesTwoPageLayout,
      animate: _tapPageAnimationEnabled,
    );
  }

  Future<void> _scrollVerticalByViewport({required bool forward}) async {
    final itemController = _scrollByChapter
        ? _verticalPageScrollController
        : _verticalChapterScrollController;
    if (!itemController.isAttached || _verticalViewportSize.isEmpty) return;
    _markReadingPositionChanged();
    _hideControlsForPageTurn();
    final offsetController = _scrollByChapter
        ? _verticalPageOffsetController
        : _verticalChapterOffsetController;
    final distance = math
        .max(120, _verticalViewportSize.height * 0.86)
        .toDouble();
    await offsetController.animateScroll(
      offset: forward ? distance : -distance,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _setChapter(
    int index,
    int chapterCount, {
    bool recenterContinuousScroll = false,
    bool Function()? shouldApply,
    int Function(_NativeChapter chapter)? resolveOffset,
    bool? centerInViewport,
  }) async {
    if (!mounted || chapterCount <= 0 || !(shouldApply?.call() ?? true)) return;
    final next = index.clamp(0, chapterCount - 1);
    final loadSerial = ++_chapterLoadSerial;
    bool requestIsCurrent() =>
        mounted &&
        loadSerial == _chapterLoadSerial &&
        (shouldApply?.call() ?? true);
    _cancelInvalidPositionRestore();
    if (next == _chapterIndex &&
        resolveOffset == null &&
        !recenterContinuousScroll) {
      _setReaderState(() => _pendingChapterIndex = null);
      return;
    }
    _setReaderState(() => _pendingChapterIndex = next);
    try {
      final chapters = _loadedChapters.isNotEmpty
          ? _loadedChapters
          : await _chaptersFuture;
      if (!requestIsCurrent() || next >= chapters.length) return;
      final targetOnly = _pageMode == NativePageMode.horizontalSlide;
      if (targetOnly) {
        await _loadIndexedChapter(chapters, next);
      } else {
        await _loadIndexedChapterWindow(chapters, next);
      }
      if (!requestIsCurrent()) return;
      if (targetOnly && _pageMode != NativePageMode.horizontalSlide) {
        await _loadIndexedChapterWindow(chapters, next);
        if (!requestIsCurrent()) return;
      }

      // Resolve EPUB fragments only after the target is prepared. Installing
      // the anchor earlier lets unrelated rebuilds apply it to the old chapter.
      final offset = resolveOffset?.call(chapters[next]) ?? 0;
      _anchorOffset = offset;
      if (resolveOffset != null ||
          recenterContinuousScroll ||
          _pageMode == NativePageMode.verticalScroll) {
        _pendingRestoreChapterIndex = next;
        _requestPositionRestore(shouldApply: requestIsCurrent);
        _restoreContinuousAnchorCentered = centerInViewport ?? offset > 0;
      } else {
        _restoreAnchorAfterLayout = false;
        _pendingRestoreChapterIndex = null;
      }
      final chapterRestore = _continuousRestoreCompletion?.future;
      final previousPageController = _pageMode == NativePageMode.horizontalSlide
          ? _pageController
          : null;
      if (previousPageController != null) {
        _pageController = null;
        _pageControllerGeneration++;
      }
      _setReaderState(() {
        _chapterIndex = next;
        _pageIndex = 0;
        _pendingChapterIndex = null;
        _resetHorizontalPagingWindow(
          next,
          chapterCount: chapters.length,
          targetOnly: _pageMode == NativePageMode.horizontalSlide,
        );
      });
      _retainIndexedChapterContent(chapters);
      _restartReaderAloudFromCurrentPageAfterManualTurn();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousPageController?.dispose();
        if (!requestIsCurrent() || _lastPaginationSize.isEmpty) return;
        _commitHorizontalBackwardExpansion(
          chapters,
          _lastPaginationSize,
          Directionality.of(context),
          readerBodyTextScaler,
          usesTwoPageLayout: _lastUsesTwoPageLayout ?? false,
        );
      });
      _verticalScrollProgress.value = 0;
      final bookId = widget.book.id;
      if (bookId != null) await _queueBookProgress(bookId, next);
      if (requestIsCurrent() && chapterRestore != null) await chapterRestore;
    } finally {
      if (mounted && loadSerial == _chapterLoadSerial) {
        if (_pendingChapterIndex != null) {
          _setReaderState(() => _pendingChapterIndex = null);
        }
        _cancelInvalidPositionRestore();
      }
      _retainIndexedChapterContent(_loadedChapters);
    }
  }

  Future<void> _nextPage(
    List<_ReaderPageData> pages,
    int chapterCount, {
    required bool usesTwoPageLayout,
    bool animate = true,
  }) async {
    _markReadingPositionChanged();
    _hideControlsForPageTurn();
    if (_pageMode == NativePageMode.pageCurl && animate) {
      _markReaderAloudForManualPageTurn();
      final controller = usesTwoPageLayout
          ? _spreadForwardPageCurlController
          : _pageCurlController;
      await controller.turnForward();
      return;
    }
    if (_pageMode == NativePageMode.coverSlide && animate) {
      _markReaderAloudForManualPageTurn();
      await _coverPageTurnController.turnForward();
      return;
    }
    final pageController = _pageController;
    if (_pageMode == NativePageMode.horizontalSlide &&
        pageController != null &&
        pageController.hasClients) {
      if (animate) {
        _markReaderAloudForManualPageTurn();
        await pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _markReaderAloudForManualPageTurn();
        pageController.jumpToPage((pageController.page?.round() ?? 0) + 1);
      }
      return;
    }
    final pageStep = usesTwoPageLayout ? 2 : 1;
    if (_pageIndex + pageStep < pages.length) {
      _sessionPagesRead++;
      _markReaderAloudForManualPageTurn();
      _setReaderState(() => _pageIndex += pageStep);
      _restartReaderAloudFromCurrentPageAfterManualTurn();
    } else if (_chapterIndex < chapterCount - 1) {
      _sessionPagesRead++;
      _markReaderAloudForManualPageTurn();
      await _setChapter(_chapterIndex + 1, chapterCount);
    }
  }

  void _previousPage(
    List<_ReaderPageData> pages,
    int chapterCount, {
    required bool usesTwoPageLayout,
    bool animate = true,
  }) {
    _markReadingPositionChanged();
    _hideControlsForPageTurn();
    if (_pageMode == NativePageMode.pageCurl && animate) {
      _markReaderAloudForManualPageTurn();
      final controller = usesTwoPageLayout
          ? _spreadBackwardPageCurlController
          : _pageCurlController;
      unawaited(controller.turnBackward());
      return;
    }
    if (_pageMode == NativePageMode.coverSlide && animate) {
      _markReaderAloudForManualPageTurn();
      unawaited(_coverPageTurnController.turnBackward());
      return;
    }
    final pageController = _pageController;
    if (_pageMode == NativePageMode.horizontalSlide &&
        pageController != null &&
        pageController.hasClients) {
      if (pageController.page!.round() <= _horizontalPageIndexMap.origin) {
        _commitHorizontalBackwardExpansion(
          _loadedChapters,
          _lastPaginationSize,
          Directionality.of(context),
          readerBodyTextScaler,
          usesTwoPageLayout: usesTwoPageLayout,
        );
        return;
      }
      if (animate) {
        _markReaderAloudForManualPageTurn();
        pageController.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _markReaderAloudForManualPageTurn();
        pageController.jumpToPage(
          math.max(0, (pageController.page?.round() ?? 0) - 1),
        );
      }
      return;
    }
    final pageStep = usesTwoPageLayout ? 2 : 1;
    if (_pageIndex >= pageStep) {
      _markReaderAloudForManualPageTurn();
      _setReaderState(() => _pageIndex -= pageStep);
      _restartReaderAloudFromCurrentPageAfterManualTurn();
    } else if (_chapterIndex > 0) {
      _openPreviousChapterAtLastPage = true;
      _markReaderAloudForManualPageTurn();
      _setChapter(_chapterIndex - 1, chapterCount);
    }
  }

  void _handleHorizontalSwipe(
    DragEndDetails details,
    List<_ReaderPageData> pages,
    int chapterCount,
    bool usesTwoPageLayout,
  ) {
    if (_annotationInteractionActive) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_pageMode == NativePageMode.horizontalSlide ||
        _pageMode == NativePageMode.coverSlide ||
        _pageMode == NativePageMode.pageCurl) {
      return;
    }
    if (_pageMode == NativePageMode.instantPage) {
      if (velocity < -350) {
        _nextPage(pages, chapterCount, usesTwoPageLayout: usesTwoPageLayout);
      } else if (velocity > 350) {
        _previousPage(
          pages,
          chapterCount,
          usesTwoPageLayout: usesTwoPageLayout,
        );
      }
      return;
    }
    if (!_scrollByChapter) return;
    if (velocity < -350) {
      _setChapter(_chapterIndex + 1, chapterCount);
    } else if (velocity > 350) {
      _setChapter(_chapterIndex - 1, chapterCount);
    }
  }

  void _handleTap(
    Offset localPosition,
    Size viewportSize,
    List<_ReaderPageData> pages,
    int chapterCount,
    bool usesTwoPageLayout,
  ) {
    if (_annotationInteractionActive) return;
    switch (_tapZones.actionAt(localPosition, viewportSize)) {
      case ReaderTapZoneAction.menu:
        _toggleControls();
      case ReaderTapZoneAction.none:
        break;
      case ReaderTapZoneAction.previousPage:
        // 上下翻页由滚动手势负责，点击翻页保持关闭。
        if (_pageMode == NativePageMode.verticalScroll) return;
        _previousPage(
          pages,
          chapterCount,
          usesTwoPageLayout: usesTwoPageLayout,
          animate: _tapPageAnimationEnabled,
        );
      case ReaderTapZoneAction.nextPage:
        if (_pageMode == NativePageMode.verticalScroll) return;
        _nextPage(
          pages,
          chapterCount,
          usesTwoPageLayout: usesTwoPageLayout,
          animate: _tapPageAnimationEnabled,
        );
      case ReaderTapZoneAction.previousChapter:
        if (_chapterIndex > 0) {
          unawaited(
            _setChapter(
              _chapterIndex - 1,
              chapterCount,
              recenterContinuousScroll: true,
            ),
          );
        }
      case ReaderTapZoneAction.nextChapter:
        if (_chapterIndex < chapterCount - 1) {
          unawaited(
            _setChapter(
              _chapterIndex + 1,
              chapterCount,
              recenterContinuousScroll: true,
            ),
          );
        }
    }
  }

  void _handleReaderTap(Offset localPosition) {
    if (_consumeAutoPageTurnContentTap()) return;
    _handleTap(
      localPosition,
      _readerViewportSize,
      _visiblePages,
      _visibleChapterCount,
      _visibleUsesTwoPageLayout,
    );
  }

  void _setTapZones(ReaderTapZones zones) {
    if (zones == _tapZones) return;
    _setReaderState(() => _tapZones = zones);
    unawaited(_readerSettingsStore.saveTapZones(zones));
  }

  Future<void> _showTapZoneSettings() async {
    Navigator.of(context).pop();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    _setReaderState(() {
      _controlsVisible = false;
      _tapZoneEditorVisible = true;
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControlsForPageTurn();
      return;
    }
    _pauseAutoPageTurn();
    _controlsTimer?.cancel();
    _setReaderState(() => _controlsVisible = true);
    _controlsTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _setReaderState(() => _controlsVisible = false);
    });
  }

  void _hideControlsForPageTurn() {
    _controlsTimer?.cancel();
    if (mounted && _controlsVisible) {
      _setReaderState(() => _controlsVisible = false);
    }
  }
}
