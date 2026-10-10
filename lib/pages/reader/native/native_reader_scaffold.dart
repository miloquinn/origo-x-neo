part of 'native_reader_page.dart';

extension _NativeReaderScaffold on _NativeReaderPageState {
  Widget _buildReaderPage(BuildContext context) {
    final systemUiOverlayStyle = _readerSystemUiOverlayStyle;
    if (!_readerDependenciesInitialized) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        key: const ValueKey('reader-system-ui-region'),
        value: systemUiOverlayStyle,
        child: Theme(
          data: _readerThemeData,
          child: _buildOpeningScaffold(
            key: const ValueKey('native-reader-opening-placeholder'),
            showLoader: false,
          ),
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('reader-system-ui-region'),
      value: systemUiOverlayStyle,
      child: PopScope(
        // A route pop used to dispose the reader before its last horizontal
        // page, which can be held until the PageView settles, was persisted.
        // Keep the route until _exitReader has committed that page.
        canPop: _exitPositionCommitted,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            BookOpenTransition.beginExit();
          } else if (_tapZoneEditorVisible) {
            _setReaderState(() => _tapZoneEditorVisible = false);
          } else {
            unawaited(_exitReader());
          }
        },
        child: Theme(
          data: _readerThemeData,
          child: FutureBuilder<List<_NativeChapter>>(
            future: _chaptersFuture,
            builder: (context, snapshot) {
              if (!_readerSettingsLoaded ||
                  !_readerFontReady ||
                  !_readerSystemUiApplied) {
                return _buildOpeningScaffold(
                  key: const ValueKey('native-reader-opening-placeholder'),
                  showLoader: false,
                );
              }
              if (snapshot.hasError) {
                _scheduleOpeningContentReady();
                return _buildReaderMessageScaffold(
                  key: const ValueKey('native-reader-error'),
                  message: context.l10n.readerOpenFailed(
                    snapshot.error.toString(),
                  ),
                  showAppBar: true,
                );
              }
              final chapters = snapshot.data;
              if (chapters == null) {
                if (!_showOpeningLoader) {
                  return _buildOpeningScaffold(
                    key: const ValueKey('native-reader-loading-placeholder'),
                    showLoader: false,
                  );
                }
                return _buildOpeningScaffold(
                  key: const ValueKey('native-reader-loading'),
                  showLoader: true,
                );
              }
              if (chapters.isEmpty) {
                _scheduleOpeningContentReady();
                return _buildReaderMessageScaffold(
                  key: const ValueKey('native-reader-empty'),
                  message: context.l10n.readerNoContent,
                );
              }
              // 封面还在飞行时不构建正文：首次整章排版（50~100ms）会
              // 冻结飞行帧。等封面到达静止停留画面后再构建，排版落在
              // 无感知窗口里；已有分页缓存（重开同一本书）则立即构建。
              if (!_openingCoverHoldReachedNow && _pageCache.isEmpty) {
                return _buildOpeningScaffold(
                  key: const ValueKey('native-reader-loading-placeholder'),
                  showLoader: false,
                );
              }

              _resolveSavedChapter(chapters);
              _chapterIndex = _chapterIndex.clamp(0, chapters.length - 1);
              final chapter = chapters[_chapterIndex];
              _scheduleOpeningContentReady();
              return Scaffold(
                key: const ValueKey('native-reader-content'),
                backgroundColor: Colors.transparent,
                // The reader page has no text field of its own, but Scaffold
                // shrinks `body` for ANY keyboard inset by default, including
                // one raised by a TextField inside a modal sheet stacked on
                // top (e.g. the TOC search box). That resize changes the
                // LayoutBuilder constraints below every animation frame,
                // forcing a full chapter re-pagination each frame.
                resizeToAvoidBottomInset: false,
                body: ReaderThemeBackground(
                  palette: _readerTheme,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      _readerViewportSize = size;
                      final paginationViewport = _desktopResizeController
                          .resolve(
                            size,
                            enabled:
                                !kIsWeb &&
                                (defaultTargetPlatform ==
                                        TargetPlatform.macOS ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.windows ||
                                    defaultTargetPlatform ==
                                        TargetPlatform.linux),
                            onSettled: () {
                              if (mounted) _setReaderState(() {});
                            },
                          );
                      _chromeViewportHeight = paginationViewport.height;
                      final usesTwoPageLayout = _usesTwoPageLayout(
                        paginationViewport,
                      );
                      final paginationSize = _paginationSize(
                        paginationViewport,
                        usesTwoPageLayout,
                      );
                      final paginationGeometryChanged =
                          !_lastPaginationSize.isEmpty &&
                          (_lastPaginationSize != paginationSize ||
                              _lastUsesTwoPageLayout != usesTwoPageLayout);
                      final verticalGeometrySignature =
                          _pageMode == NativePageMode.verticalScroll
                          ? '$paginationViewport:${_verticalChrome.paginationSignature}'
                          : null;
                      final verticalGeometryChanged =
                          _verticalGeometrySignature != null &&
                          _verticalGeometrySignature !=
                              verticalGeometrySignature;
                      if (paginationGeometryChanged ||
                          verticalGeometryChanged) {
                        if (_pageMode == NativePageMode.verticalScroll &&
                            !_initialPositionRestored) {
                          // Reflow the pending intent without dropping its
                          // cancellation predicate or completing it early.
                          ++_verticalScrollRevision;
                          _initialPositionRestoreScheduled = false;
                          _restoreAnchorAfterLayout = true;
                        } else {
                          final wasAtChapterStart =
                              (_anchorOffset ?? 0) == 0 &&
                              !_restoreContinuousAnchorCentered;
                          _requestPositionRestore();
                          if (wasAtChapterStart) {
                            _restoreContinuousAnchorCentered = false;
                          }
                        }
                        _lastSavedLocation = null;
                      }
                      _verticalGeometrySignature = verticalGeometrySignature;
                      _lastPaginationSize = paginationSize;
                      _lastUsesTwoPageLayout = usesTwoPageLayout;
                      final textDirection = Directionality.of(context);
                      const textScaler = readerBodyTextScaler;
                      final pages = _pagesFor(
                        chapter,
                        _chapterIndex,
                        paginationSize,
                        textDirection,
                        textScaler,
                      );
                      _visiblePages = pages;
                      if (_pageMode == NativePageMode.verticalScroll) {
                        _visibleContinuousParts = _continuousPartsFor(
                          chapter,
                          paginationViewport,
                        );
                        _visiblePages = _visibleContinuousParts
                            .map((part) => part.content)
                            .toList(growable: false);
                      }
                      _visibleChapterCount = chapters.length;
                      _visibleUsesTwoPageLayout = usesTwoPageLayout;
                      final buildsBookPages =
                          _pageMode == NativePageMode.horizontalSlide ||
                          _pageMode == NativePageMode.coverSlide ||
                          _pageMode == NativePageMode.pageCurl ||
                          (_autoPageTurnController.isActive &&
                              _autoPageTurnController.mode ==
                                  ReaderAutoPageTurnMode.sweep);
                      final bookPages = buildsBookPages
                          ? _bookPagesFor(
                              chapters,
                              _horizontalFirstChapter,
                              _horizontalLastChapter,
                              paginationSize,
                              textDirection,
                              textScaler,
                              padOddChapters: usesTwoPageLayout,
                            )
                          : const <_BookPageRef>[];
                      if (buildsBookPages &&
                          (_pageMode == NativePageMode.horizontalSlide ||
                              _pageMode == NativePageMode.coverSlide ||
                              _pageMode == NativePageMode.pageCurl)) {
                        _scheduleBookPaginationWarm(
                          chapters,
                          _horizontalLastChapter + 1,
                          paginationSize,
                          textDirection,
                          textScaler,
                        );
                        _scheduleBookPaginationWarm(
                          chapters,
                          _horizontalFirstChapter - 1,
                          paginationSize,
                          textDirection,
                          textScaler,
                        );
                      }
                      if (_openPreviousChapterAtLastPage) {
                        _pageIndex = usesTwoPageLayout
                            ? _spreadStartForPage(pages.length - 1)
                            : pages.length - 1;
                        _openPreviousChapterAtLastPage = false;
                      }
                      _pageIndex = _pageIndex.clamp(0, pages.length - 1);
                      if (usesTwoPageLayout) {
                        _pageIndex = _spreadStartForPage(_pageIndex);
                      }
                      _cancelInvalidPositionRestore();
                      var needsHorizontalAlignment = false;
                      if (_restoreAnchorAfterLayout &&
                          _anchorOffset != null &&
                          (_pendingRestoreChapterIndex == null ||
                              _pendingRestoreChapterIndex == _chapterIndex)) {
                        needsHorizontalAlignment = true;
                        final anchor = _anchorOffset!.clamp(
                          0,
                          chapter.plainText.length,
                        );
                        _anchorOffset = anchor;
                        if (_pageMode == NativePageMode.verticalScroll) {
                          _verticalCanonicalOffset = anchor;
                        }
                        final restorePages =
                            _pageMode == NativePageMode.verticalScroll
                            ? _visiblePages
                            : pages;
                        final restoredIndex =
                            anchor == 0 &&
                                restorePages.first.isChapterTitle &&
                                (_pageMode != NativePageMode.verticalScroll ||
                                    !_restoreContinuousAnchorCentered)
                            ? 0
                            : readerTextPageIndexForOffset(
                                restorePages,
                                anchor,
                              );
                        if (restoredIndex >= 0) _pageIndex = restoredIndex;
                        if (usesTwoPageLayout) {
                          _pageIndex = _spreadStartForPage(_pageIndex);
                        }
                        _restoreAnchorAfterLayout = false;
                        _pendingRestoreChapterIndex = null;
                        if (_pageMode == NativePageMode.verticalScroll) {
                          _scheduleInitialContinuousScrollRestore(size);
                        } else {
                          _initialPositionRestored = true;
                          _positionRestoreShouldApply = null;
                          _positionRestorePreviousVerticalOffset = null;
                        }
                      }
                      if (_pageMode != NativePageMode.verticalScroll) {
                        final locationKey =
                            '$_chapterIndex:$_pageIndex:'
                            '${pages[_pageIndex].startOffset}';
                        if (_lastSavedLocation != locationKey) {
                          _lastSavedLocation = locationKey;
                          final pageToSave = pages[_pageIndex];
                          final chapterToSave = chapter;
                          final chapterIndexToSave = _chapterIndex;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _saveCanonicalProgress(
                              chapterToSave,
                              pageToSave,
                              chapterIndexToSave,
                            );
                          });
                        }
                      }
                      if (_pageMode == NativePageMode.horizontalSlide) {
                        final targetPage = bookPages.indexWhere(
                          (page) =>
                              page.chapterIndex == _chapterIndex &&
                              page.pageIndex == _pageIndex,
                        );
                        final localTargetControllerPage = usesTwoPageLayout
                            ? targetPage ~/ 2
                            : targetPage;
                        final targetControllerPage =
                            _horizontalPageIndexMap.origin +
                            localTargetControllerPage;
                        _pageController ??= PageController(
                          initialPage: math.max(0, targetControllerPage),
                          keepPage: false,
                        );
                        _schedulePendingHorizontalForwardBoundaryCommit(
                          bookPages,
                          chapters,
                          usesTwoPageLayout: usesTwoPageLayout,
                        );
                        final pageControllerGeneration =
                            _pageControllerGeneration;
                        final pageController = _pageController;
                        final alignmentChapter = _chapterIndex;
                        final alignmentPage = _pageIndex;
                        final blockControllerRealignment =
                            _pendingHorizontalForwardBoundary != null ||
                            _pendingHorizontalPage != null;
                        _initialPositionRestored = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!needsHorizontalAlignment) return;
                          _runWhenHorizontalControllerIsIdle(
                            pageController,
                            pageControllerGeneration,
                            () {
                              if (blockControllerRealignment ||
                                  _pendingHorizontalForwardBoundary != null ||
                                  _pendingHorizontalPage != null ||
                                  _chapterIndex != alignmentChapter ||
                                  _pageIndex != alignmentPage ||
                                  pageController == null ||
                                  !pageController.hasClients) {
                                return;
                              }
                              if (targetPage >= 0 &&
                                  pageController.page?.round() !=
                                      targetControllerPage) {
                                pageController.jumpToPage(targetControllerPage);
                              }
                            },
                          );
                        });
                      }

                      final bookmarkPage = _currentPositionPage(pages);
                      final currentBookmarkAnchorKey = _bookmarkAnchorKey(
                        chapter,
                        bookmarkPage,
                      );
                      final currentPageIsBookmarked = _bookmarks.any(
                        (bookmark) =>
                            isTxtBookmarkLocatorResolved(bookmark.anchorKey) &&
                            bookmark.anchorKey == currentBookmarkAnchorKey,
                      );

                      final reader = ReaderPullBookmark(
                        enabled: _pullBookmarkEnabled,
                        bookmarked: currentPageIsBookmarked,
                        busy: _bookmarkBusy,
                        palette: _readerTheme,
                        addHint: context.l10n.readerPullBookmarkAddHint,
                        removeHint: context.l10n.readerPullBookmarkRemoveHint,
                        releaseHint: context.l10n.readerPullBookmarkReleaseHint,
                        onTriggered: () =>
                            unawaited(_toggleBookmark(chapter, bookmarkPage)),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child:
                                  BookOpenTransition.buildReaderContentReveal(
                                    context,
                                    child: ReaderDesktopInput(
                                      key: const ValueKey(
                                        'native-reader-desktop-input',
                                      ),
                                      enabled: !_annotationInteractionActive,
                                      turnPageOnPointerScroll:
                                          _pageMode !=
                                          NativePageMode.verticalScroll,
                                      onNext: _handleDesktopNextPage,
                                      onPrevious: _handleDesktopPreviousPage,
                                      child: ReaderTapObserver(
                                        key: const ValueKey(
                                          'native-reader-tap-observer',
                                        ),
                                        enabled: !_annotationInteractionActive,
                                        onTap: _handleReaderTap,
                                        child: Listener(
                                          onPointerDown:
                                              _handleAutoPageTurnPointerDown,
                                          onPointerMove:
                                              _handleAutoPageTurnPointerMove,
                                          onPointerSignal:
                                              _handleAutoPageTurnPointerSignal,
                                          child: GestureDetector(
                                            behavior:
                                                HitTestBehavior.translucent,
                                            onHorizontalDragEnd:
                                                _pageMode ==
                                                        NativePageMode
                                                            .horizontalSlide ||
                                                    _pageMode ==
                                                        NativePageMode
                                                            .coverSlide ||
                                                    _pageMode ==
                                                        NativePageMode.pageCurl
                                                ? null
                                                : (details) =>
                                                      _handleHorizontalSwipe(
                                                        details,
                                                        pages,
                                                        chapters.length,
                                                        usesTwoPageLayout,
                                                      ),
                                            child: _buildReaderContent(
                                              chapters,
                                              chapter,
                                              pages,
                                              bookPages,
                                              usesTwoPageLayout,
                                              _paginationFingerprintFor(
                                                _chapterIndex,
                                                paginationSize,
                                                textDirection,
                                                textScaler,
                                              ),
                                              paginationViewport,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                            if (!_initialPositionRestored)
                              Positioned.fill(
                                child: ColoredBox(
                                  key: const ValueKey(
                                    'native-reader-positioning-placeholder',
                                  ),
                                  color: _readerTheme.background,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            if (_pendingChapterIndex != null)
                              Positioned(
                                top: MediaQuery.paddingOf(context).top + 12,
                                right: 16,
                                child: IgnorePointer(
                                  child: SizedBox.square(
                                    key: const ValueKey(
                                      'native-reader-chapter-loading',
                                    ),
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _readerTheme.text,
                                    ),
                                  ),
                                ),
                              ),
                            if (_showLeafFloatingStatus &&
                                _pageMode == NativePageMode.verticalScroll)
                              ReaderFloatingStatusOverlay(
                                palette: _readerTheme,
                                status: _leafStatusController.value,
                                safeArea: _readerSafeArea,
                                horizontalPadding:
                                    _floatingStatusHorizontalPadding,
                              ),
                            ReaderChromeOverlay(
                              progressBar: _buildProgressPill(
                                chapters: chapters,
                                pages: pages,
                                paginationSize: paginationSize,
                                textDirection: textDirection,
                                textScaler: textScaler,
                                usesTwoPageLayout: usesTwoPageLayout,
                              ),
                              autoPageTurnController: _autoPageTurnController,
                              onResumeAutoPageTurn: () =>
                                  unawaited(_resumeAutoPageTurn()),
                              palette: _readerTheme,
                              visible: _controlsVisible,
                              title: chapter.title.isEmpty
                                  ? widget.book.title
                                  : chapter.title,
                              statusBottom: _readerSafeArea.pageNumberBottom,
                              showViewportStatus:
                                  _pageMode == NativePageMode.verticalScroll &&
                                  _topBarStyle != ReaderTopBarStyle.hidden,
                              showViewportTitle:
                                  _pageMode == NativePageMode.verticalScroll &&
                                  _topBarStyle == ReaderTopBarStyle.reader,
                              viewportTitleTop: _readerSafeArea.readerTopBarTop,
                              viewportTitleHeight: _readerSafeArea.headerHeight,
                              viewportStatusHeight:
                                  _readerSafeArea.footerHeight,
                              viewportTitleKey: const ValueKey(
                                'native-reader-viewport-title',
                              ),
                              readerStatus: _leafStatusController.value,
                              viewportStatusHorizontalPadding: math.max(
                                24,
                                _horizontalMargin,
                              ),
                              statusBuilder: (context, style, key) =>
                                  _buildReaderStatusText(
                                    pages: pages,
                                    chapterCount: chapters.length,
                                    style: style,
                                    key: key,
                                  ),
                              onBack: () => unawaited(_exitReader()),
                              onBookmark: () => unawaited(
                                _toggleBookmark(chapter, bookmarkPage),
                              ),
                              onTableOfContents: () => unawaited(
                                _showTableOfContents(
                                  chapters,
                                  currentAnchorKey: currentBookmarkAnchorKey,
                                ),
                              ),
                              onSearch: () => unawaited(_showFullTextSearch()),
                              searchTooltip: '全文搜索',
                              onReadAloud: isReaderAloudPlatformSupported
                                  ? () => unawaited(
                                      _handleReaderAloudButtonPressed(),
                                    )
                                  : null,
                              readAloudTooltip: context.l10n.ttsReading,
                              readAloudActive: context
                                  .select<ReaderAloudSession?, bool>(
                                    (session) =>
                                        session?.sourceId ==
                                            'local:${widget.book.id}' &&
                                        (session?.isActive ?? false),
                                  ),
                              onLocateReadAloud: () =>
                                  unawaited(_locateReaderAloud()),
                              onAskAi: () => unawaited(
                                _showAskAiPanel(chapter, bookmarkPage),
                              ),
                              askAiTooltip: context.l10n.readerAskAi,
                              onBookSettings: () =>
                                  unawaited(_showBookSettings()),
                              onSettings: _showReadingSettings,
                              backTooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                              bookmarkTooltip: currentPageIsBookmarked
                                  ? context.l10n.bookmarkRemoved
                                  : context.l10n.readerAddBookmark,
                              tableOfContentsTooltip:
                                  context.l10n.readerToolbarTOC,
                              settingsTooltip: context.l10n.readingSettings,
                              bookmarked: currentPageIsBookmarked,
                              bookmarkBusy: _bookmarkBusy,
                              topKey: const ValueKey(
                                'native-reader-top-controls',
                              ),
                              bottomKey: const ValueKey(
                                'native-reader-bottom-controls',
                              ),
                              statusKey: const ValueKey('native-reader-status'),
                            ),
                          ],
                        ),
                      );
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          reader,
                          if (_tapZoneEditorVisible)
                            Positioned.fill(
                              child: ReaderTapZoneEditorOverlay(
                                palette: _readerTheme,
                                zones: _tapZones,
                                onZonesChanged: _setTapZones,
                                onClose: () => _setReaderState(
                                  () => _tapZoneEditorVisible = false,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
