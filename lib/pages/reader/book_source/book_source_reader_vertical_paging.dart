part of 'book_source_reader_page.dart';

extension _BookSourceReaderVerticalPaging on _BookSourceReaderPageState {
  ReaderViewportChromeMetrics get _verticalChrome =>
      readerViewportChromeForTopBar(
        safeArea: _readerSafeArea,
        topBarStyle: _topBarStyle,
      );

  double _verticalPageExtentFor(Size viewport) =>
      _verticalChrome.contentHeight(viewport.height);

  Widget _buildVerticalReadingWindow(Widget child) =>
      ReaderVerticalReadingWindow(
        windowKey: const ValueKey('book-source-vertical-reading-window'),
        metrics: _verticalChrome,
        child: child,
      );

  GlobalKey _verticalPartKey(int chapterIndex, int partIndex) =>
      _verticalPartKeys.putIfAbsent('$chapterIndex:$partIndex', GlobalKey.new);

  int _verticalOffsetAtViewportCenter(
    int chapterIndex,
    int partIndex,
    BookSourceTextPage page,
  ) {
    return readerSourceOffsetAtViewportCenter(
      paragraph: readerParagraphForKey(
        _verticalPartKey(chapterIndex, partIndex),
      ),
      text: page.text,
      fallbackOffset: page.startOffset,
      sourceOffsetForTextOffset: page.sourceOffsetForTextOffset,
      viewportCenterY: MediaQuery.sizeOf(context).height / 2,
    );
  }

  double? _verticalCaretOffset(
    int chapterIndex,
    int partIndex,
    BookSourceTextPage page,
    int sourceOffset,
  ) {
    return readerCaretDyForSourceOffset(
      paragraph: readerParagraphForKey(
        _verticalPartKey(chapterIndex, partIndex),
      ),
      text: page.text,
      sourceOffset: sourceOffset,
      textOffsetForSourceOffset: page.textOffsetForSourceOffset,
    );
  }

  List<BookSourceTextPage> _continuousTextParts(
    String text, {
    required String chapterTitle,
    required double width,
    required TextDirection direction,
    required Locale? locale,
  }) {
    return paginateBookSourceText(
      text,
      width: width,
      firstPageHeight: 0,
      pageHeight: 0,
      style: _bodyTextStyle,
      textDirection: direction,
      textScaler: readerBodyTextScaler,
      textAlign: _bodyTextAlign,
      locale: locale,
      firstLineIndent: _firstLineIndent,
      paragraphSpacing: _paragraphSpacing,
      includeChapterTitlePage:
          chapterTitle.trim().isNotEmpty && _chapterTitlePageEnabled,
      inlineChapterTitleExtent:
          chapterTitle.trim().isNotEmpty && !_chapterTitlePageEnabled
          ? 0
          : null,
    );
  }

  _BookSourceVerticalLayout _verticalLayoutFor(
    int chapterIndex,
    BookSourceChapterContent content,
    Size viewport,
  ) {
    _checkOnlinePaginationEpoch();
    final chrome = _verticalChrome;
    final width = readerTextContentWidth(viewport.width, _horizontalMargin);
    final height = _verticalPageExtentFor(viewport);
    const textScaler = readerBodyTextScaler;
    final locale = Localizations.maybeLocaleOf(context);
    final direction = Directionality.of(context);
    final fingerprint = ReaderLayoutFingerprint(
      contentKey: _chapters[chapterIndex].id,
      viewport: Size(width, height),
      fontSize: _fontSize,
      fontWeight: _fontWeight,
      lineHeight: _lineHeight,
      letterSpacing: _letterSpacing,
      textAlign: _bodyTextAlign,
      horizontalMargin: _horizontalMargin,
      verticalMargin: _topMargin + _bottomMargin,
      textScaler: textScaler,
      locale: locale,
      pageMode: BookSourcePageMode.verticalScroll,
      firstLineIndent: _firstLineIndent,
      paragraphSpacing: _paragraphSpacing,
      textDirection: direction,
      extra:
          '${chrome.paginationSignature}:${_readerFontProfile.cacheSignature}:'
          '${_replaceRules.rulesSignature}:'
          '$_chapterTitlePageEnabled:${_chapters[chapterIndex].title}',
    ).cacheKey('book-source-vertical-v4');
    final cached = _verticalLayouts[chapterIndex];
    if (cached?.fingerprint == fingerprint) return cached!;
    final text =
        _readableChapterText[chapterIndex] ??
        readableBookSourceChapterText(
          content,
          fallbackTitle: _chapters[chapterIndex].title,
        );
    final pages = _continuousTextParts(
      text,
      chapterTitle: _chapters[chapterIndex].title,
      width: width,
      direction: direction,
      locale: locale,
    );
    final layout = _BookSourceVerticalLayout(
      fingerprint: fingerprint,
      pages: pages,
    );
    _verticalLayouts[chapterIndex] = layout;
    return layout;
  }

  void _requestVerticalPositionRestore() {
    if (!_restorePagedPosition) {
      final offset = _verticalCanonicalOffset;
      _restoreTextOffset = offset == 0 ? null : offset;
      _restorePageProgress = _scrollProgress.value;
      _autoRestoreCentered = offset != null && offset > 0;
    }
    ++_verticalRestoreSerial;
    _autoScrollRestoring = false;
    _restorePagedPosition = true;
  }

  void _prepareVerticalGeometry(Size viewport) {
    final signature = '$viewport:${_verticalChrome.paginationSignature}';
    if (_verticalGeometrySignature != null &&
        _verticalGeometrySignature != signature) {
      _requestVerticalPositionRestore();
    }
    _verticalGeometrySignature = signature;
  }

  void _restoreVerticalPosition(
    _BookSourceVerticalLayout layout, {
    required bool wholeBook,
  }) {
    if (!_restorePagedPosition || !_appLifecycleActive) return;
    final generation = _catalogGeneration;
    final loadSerial = _chapterLoadSerial;
    final restoreSerial = ++_verticalRestoreSerial;
    final shouldApply = _verticalRestoreShouldApply;
    bool ownsRestore() =>
        mounted &&
        _appLifecycleActive &&
        restoreSerial == _verticalRestoreSerial &&
        generation == _catalogGeneration &&
        loadSerial == _chapterLoadSerial;
    bool isCurrent() {
      if (!ownsRestore()) return false;
      if (shouldApply?.call() ?? true) return true;
      _verticalRestoreShouldApply = null;
      _autoScrollRestoring = false;
      _restorePagedPosition = false;
      _restoreTextOffset = null;
      // Cancellation releases the restore gate. Publish the actual painted
      // position after layout rather than persisting an abandoned target.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ownsRestore()) return;
        if (wholeBook) {
          _onVerticalChapterPositionsChanged();
        } else {
          _onVerticalPagePositionsChanged();
        }
      });
      WidgetsBinding.instance.scheduleFrame();
      return false;
    }

    if (!isCurrent()) return;
    _autoScrollRestoring = true;
    final chapterIndex = _chapterIndex;
    final textLength = _readableChapterText[chapterIndex]?.length ?? 0;
    final restoreOffset =
        _restoreTextOffset ?? (_restorePageProgress * textLength).round();
    final restoresChapterStart =
        _restoreTextOffset == null && restoreOffset == 0;
    final restoreCentered =
        !restoresChapterStart && (_autoRestoreCentered || restoreOffset > 0);
    _autoRestoreCentered = false;
    final pageIndex = restoresChapterStart
        ? 0
        : bookSourcePageIndexForOffset(layout.pages, restoreOffset);
    final partKey = _verticalPartKey(chapterIndex, pageIndex);
    _verticalPageCount = layout.pages.length;
    _verticalPageIndex = pageIndex;
    _pageIndex = pageIndex;
    _restorePagedPosition = false;
    _restoreTextOffset = null;
    _verticalCanonicalOffset = restoreOffset;
    final restoredProgress = textLength > 0
        ? (restoreOffset / textLength).clamp(0.0, 1.0)
        : _restorePageProgress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isCurrent()) return;
      _scrollProgress.value = restoredProgress;
      if (!wholeBook && _verticalPageScrollController.isAttached) {
        _verticalPageScrollController.jumpTo(index: pageIndex);
      } else if (_verticalChapterScrollController.isAttached) {
        _verticalChapterScrollController.jumpTo(index: chapterIndex);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isCurrent()) return;
        final targetContext = partKey.currentContext;
        if (targetContext == null) {
          _updateReaderState(() {
            _autoScrollRestoring = false;
            _verticalRestoreShouldApply = null;
          });
          return;
        }
        unawaited(
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0,
            duration: Duration.zero,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isCurrent()) return;
          final caretOffset = _verticalCaretOffset(
            chapterIndex,
            pageIndex,
            layout.pages[pageIndex],
            restoreOffset,
          );
          final currentTarget = partKey.currentContext;
          final scrollable = currentTarget == null
              ? null
              : Scrollable.maybeOf(currentTarget);
          _updateReaderState(() {
            _autoScrollRestoring = false;
            _verticalRestoreShouldApply = null;
          });
          if (!restoresChapterStart &&
              caretOffset != null &&
              scrollable != null) {
            final paragraph = readerParagraphForKey(partKey);
            final adjustment = restoreCentered && paragraph != null
                ? paragraph.localToGlobal(Offset(0, caretOffset)).dy -
                      MediaQuery.sizeOf(context).height / 2
                : caretOffset;
            scrollable.position.jumpTo(
              (scrollable.position.pixels + adjustment).clamp(
                scrollable.position.minScrollExtent,
                scrollable.position.maxScrollExtent,
              ),
            );
          }
        });
      });
    });
  }

  void _onVerticalPagePositionsChanged() {
    if (!mounted ||
        !_appLifecycleActive ||
        _loadingCatalog ||
        _loadingContent ||
        _error != null ||
        _restorePagedPosition ||
        _autoScrollRestoring ||
        _pageMode != BookSourcePageMode.verticalScroll ||
        !_effectiveScrollByChapter) {
      return;
    }
    final layout = _verticalLayouts[_chapterIndex];
    if (layout == null || layout.pages.isEmpty) return;
    final primary = pickPrimaryReaderItem(
      _verticalPagePositionsListener.itemPositions.value.map(
        readerVisibleItemPositionFromItemPosition,
      ),
    );
    if (primary == null) return;
    final nextPage = primary.index.clamp(0, layout.pages.length - 1);
    _verticalPageCount = layout.pages.length;
    _verticalPageIndex = nextPage;
    final textLength = _readableChapterText[_chapterIndex]?.length ?? 0;
    final offset = _verticalOffsetAtViewportCenter(
      _chapterIndex,
      nextPage,
      layout.pages[nextPage],
    );
    _verticalCanonicalOffset = offset;
    _scrollProgress.value = textLength == 0
        ? 0
        : (offset / textLength).clamp(0.0, 1.0);
    if (nextPage != _pageIndex) {
      if (nextPage > _pageIndex) _sessionPagesRead++;
      _updateReaderState(() => _pageIndex = nextPage);
    }
    _scheduleProgressSave();
  }

  void _onVerticalChapterPositionsChanged() {
    if (!mounted ||
        !_appLifecycleActive ||
        _loadingCatalog ||
        _loadingContent ||
        _error != null ||
        _restorePagedPosition ||
        _autoScrollRestoring ||
        _pageMode != BookSourcePageMode.verticalScroll ||
        _effectiveScrollByChapter ||
        _chapters.isEmpty ||
        _verticalViewportSize.isEmpty) {
      return;
    }
    final primary = pickPrimaryReaderItem(
      _verticalChapterPositionsListener.itemPositions.value.map(
        readerVisibleItemPositionFromItemPosition,
      ),
    );
    if (primary == null) return;
    final nextChapter = primary.index.clamp(0, _chapters.length - 1);
    final content = _prefetchedContent[nextChapter];
    if (content == null) {
      unawaited(_loadVisibleVerticalChapter(nextChapter));
      return;
    }
    final layout = _verticalLayoutFor(
      nextChapter,
      content,
      _verticalViewportSize,
    );
    final viewportCenter = MediaQuery.sizeOf(context).height / 2;
    final nextPage = readerPartIndexAtViewportCenter(
      estimatedIndex: readerPageIndexWithinItem(primary, layout.pages.length),
      itemCount: layout.pages.length,
      renderBoxAt: (index) {
        final renderObject = _verticalPartKey(
          nextChapter,
          index,
        ).currentContext?.findRenderObject();
        return renderObject is RenderBox ? renderObject : null;
      },
      viewportCenterY: viewportCenter,
    );
    final movedForward =
        nextChapter > _chapterIndex ||
        (nextChapter == _chapterIndex && nextPage > _verticalPageIndex);
    final chapterChanged = nextChapter != _chapterIndex;
    _verticalPageCount = layout.pages.length;
    _verticalPageIndex = nextPage;
    final textLength = _readableChapterText[nextChapter]?.length ?? 0;
    final offset = _verticalOffsetAtViewportCenter(
      nextChapter,
      nextPage,
      layout.pages[nextPage],
    );
    _verticalCanonicalOffset = offset;
    _scrollProgress.value = textLength == 0
        ? 0
        : (offset / textLength).clamp(0.0, 1.0);
    if (chapterChanged || nextPage != _pageIndex || _content != content) {
      if (movedForward) _sessionPagesRead++;
      _updateReaderState(() {
        _chapterIndex = nextChapter;
        _content = content;
        _pageIndex = nextPage;
      });
    }
    if (chapterChanged) unawaited(_preloadAround(nextChapter));
    _scheduleProgressSave();
  }

  Future<void> _loadVisibleVerticalChapter(int index) async {
    final generation = _catalogGeneration;
    final loadSerial = _chapterLoadSerial;
    try {
      await _continuousContentFor(index);
    } catch (_) {
      if (!mounted ||
          generation != _catalogGeneration ||
          loadSerial != _chapterLoadSerial ||
          _loadingCatalog ||
          _loadingContent ||
          _error != null) {
        return;
      }
      final primary = pickPrimaryReaderItem(
        _verticalChapterPositionsListener.itemPositions.value.map(
          readerVisibleItemPositionFromItemPosition,
        ),
      );
      if (primary?.index != index) return;
      // This chapter is now visible, so failed speculative content becomes
      // a foreground load with the same recovery and error handling as turns.
      await _loadChapter(index);
    }
  }

  Widget _buildAnnotatedTextPage(
    BookSourceTextPage page, {
    required int chapterIndex,
    required int pageIndex,
    required BookSourceChapterContent content,
    bool fillAvailableSpace = true,
  }) => Builder(
    builder: (context) {
      final chapterTitle = _chapters[chapterIndex].title;
      final tapToSeek = context.select<ReaderAloudService?, bool>(
        (service) => service?.tapToSeek ?? false,
      );
      final listening = context
          .select<ReaderAloudSession?, ReaderAloudController?>(
            (session) =>
                session?.sourceId ==
                        'source:${widget.source.id}:${widget.book.id}' &&
                    session!.isActive
                ? session.controller
                : null,
          );
      final sourceText =
          _readableChapterText[chapterIndex] ??
          readableBookSourceChapterText(
            content,
            fallbackTitle: _chapters[chapterIndex].title,
          );
      return ReaderAnnotatedTextPage(
        key: ValueKey(
          'source-annotated-page:${_chapters[chapterIndex].id}:$pageIndex:'
          '${page.startOffset}:${page.endOffset}',
        ),
        page: page,
        sourceText: sourceText,
        chapterId: _chapters[chapterIndex].id,
        chapterTitle: chapterTitle,
        chapterIndex: chapterIndex,
        pageIndex: pageIndex,
        bookId: _shelfBookId,
        format: content.contentType == 'text/html'
            ? BookFormat.html
            : BookFormat.txt,
        renderer: ReaderRendererType.flutterNative,
        palette: _readerTheme,
        bodyStyle: _bodyTextStyle,
        flowStyle: _bodyTextFlowStyle(),
        annotations: _annotations,
        spokenHighlight: _readerAloudHighlight,
        onPlayFromOffset: tapToSeek && listening != null
            ? (offset) {
                final controller = _ensureReaderAloudController();
                if (controller == null) return;
                _stopAutoPageTurn();
                unawaited(
                  controller.playFromOffset(
                    ReaderAloudPosition(
                      chapterIndex: chapterIndex,
                      offset: offset,
                    ),
                  ),
                );
              }
            : null,
        onSaveTextAnnotation: _saveTextAnnotation,
        onAnnotationUnavailable: () => _ensureAnnotationBook(),
        onAskAiSelection: _askAiAboutSelection,
        onSearchSelection: (selection) =>
            _showFullTextSearch(initialQuery: selection.selectedText),
        onPurifySelection: _purifySelection,
        fillAvailableSpace: fillAvailableSpace,
        onInteractionChanged: (active) {
          if (!mounted || _annotationInteractionActive == active) return;
          if (active) _pauseAutoPageTurn();
          _updateReaderState(() => _annotationInteractionActive = active);
        },
      );
    },
  );

  Widget _buildVerticalPageCell(
    BookSourceTextPage page,
    Size viewport, {
    required int chapterIndex,
    required int pageIndex,
    required BookSourceChapterContent content,
  }) {
    if (page.isChapterTitle) {
      return SizedBox(
        key: _verticalPartKey(chapterIndex, pageIndex),
        height: _verticalPageExtentFor(viewport),
        child: _buildAnnotatedTextPage(
          page,
          chapterIndex: chapterIndex,
          pageIndex: pageIndex,
          content: content,
        ),
      );
    }
    return Padding(
      key: _verticalPartKey(chapterIndex, pageIndex),
      padding: EdgeInsets.symmetric(horizontal: _horizontalMargin),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: readerTextContentMaxWidth(_horizontalMargin),
          ),
          child: Column(
            key: ValueKey(
              'book-source-vertical-part:${_chapters[chapterIndex].id}:'
              '${page.startOffset}:$pageIndex',
            ),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAnnotatedTextPage(
                page,
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                content: content,
                fillAvailableSpace: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalChapter(int chapterIndex, Size viewport) {
    final cached = _prefetchedContent[chapterIndex];
    Widget buildContent(BookSourceChapterContent content) {
      final layout = _verticalLayoutFor(chapterIndex, content, viewport);
      return ConstrainedBox(
        // A short final chapter must still be able to align at the top.
        // Otherwise the viewport center remains in the previous chapter and
        // its position callback immediately overwrites a successful retry.
        constraints: BoxConstraints(
          minHeight: chapterIndex == _chapters.length - 1
              ? _verticalPageExtentFor(viewport)
              : 0,
        ),
        child: Column(
          children: [
            for (
              var pageIndex = 0;
              pageIndex < layout.pages.length;
              pageIndex++
            )
              _buildVerticalPageCell(
                layout.pages[pageIndex],
                viewport,
                chapterIndex: chapterIndex,
                pageIndex: pageIndex,
                content: content,
              ),
            if (!_chapterTitlePageEnabled &&
                chapterIndex < _chapters.length - 1)
              SizedBox(
                height: readerContinuousChapterSpacing(
                  fontSize: _fontSize,
                  lineHeight: _lineHeight,
                ),
              ),
          ],
        ),
      );
    }

    if (cached != null && _readableChapterText.containsKey(chapterIndex)) {
      return buildContent(cached);
    }
    return FutureBuilder<BookSourceChapterContent>(
      key: ValueKey(
        'source-chapter-load:$_catalogGeneration:${_chapters[chapterIndex].id}',
      ),
      future: _continuousContentFor(chapterIndex),
      builder: (context, snapshot) {
        final content = snapshot.data;
        if (content != null) return buildContent(content);
        if (snapshot.hasError) {
          return SizedBox(
            height: _verticalPageExtentFor(viewport),
            child: Center(
              child: TextButton.icon(
                onPressed: () => _loadChapter(chapterIndex, saveCurrent: false),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              ),
            ),
          );
        }
        return SizedBox(
          height: _verticalPageExtentFor(viewport),
          child: Center(
            child: CircularProgressIndicator(color: _readerTheme.accent),
          ),
        );
      },
    );
  }

  Widget _buildVerticalPageList(
    _BookSourceVerticalLayout layout,
    Size viewport,
  ) {
    final layoutStateChanged =
        _verticalPageCount != layout.pages.length ||
        _verticalPageIndex >= layout.pages.length;
    _verticalPageCount = layout.pages.length;
    _verticalPageIndex = _verticalPageIndex.clamp(0, layout.pages.length - 1);
    _pageIndex = _verticalPageIndex;
    if (layoutStateChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateReaderState(() {});
      });
    }
    _restoreVerticalPosition(layout, wholeBook: false);
    return ReaderVerticalPagingSurface(
      surfaceKey: const ValueKey('book-source-reader-surface'),
      onHorizontalDragEnd: _handleHorizontalSwipe,
      child: ScrollablePositionedList.builder(
        key: ValueKey(
          'source-vertical-pages:$_catalogGeneration:$_chapterIndex:'
          '${layout.fingerprint}',
        ),
        itemScrollController: _verticalPageScrollController,
        scrollOffsetController: _verticalPageOffsetController,
        itemPositionsListener: _verticalPagePositionsListener,
        initialScrollIndex: _verticalPageIndex.clamp(
          0,
          layout.pages.length - 1,
        ),
        minCacheExtent: _verticalPageExtentFor(viewport),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: layout.pages.length,
        itemBuilder: (context, index) => _buildVerticalPageCell(
          layout.pages[index],
          viewport,
          chapterIndex: _chapterIndex,
          pageIndex: index,
          content: _content!,
        ),
      ),
    );
  }

  Widget _buildVerticalBook(Size viewport) {
    final content = _prefetchedContent[_chapterIndex] ?? _content!;
    final currentLayout = _verticalLayoutFor(_chapterIndex, content, viewport);
    final layoutStateChanged =
        _verticalPageCount != currentLayout.pages.length ||
        _verticalPageIndex >= currentLayout.pages.length;
    _verticalPageCount = currentLayout.pages.length;
    _verticalPageIndex = _verticalPageIndex.clamp(
      0,
      currentLayout.pages.length - 1,
    );
    _pageIndex = _verticalPageIndex;
    if (layoutStateChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateReaderState(() {});
      });
    }
    _restoreVerticalPosition(currentLayout, wholeBook: true);
    return ReaderVerticalPagingSurface(
      surfaceKey: const ValueKey('book-source-reader-surface'),
      child: ScrollablePositionedList.builder(
        key: ValueKey(
          'source-vertical-book:$_catalogGeneration:'
          '${viewport.width.toStringAsFixed(1)}:'
          '${viewport.height.toStringAsFixed(1)}:'
          '${_fontSize.toStringAsFixed(1)}:$_fontWeight:'
          '${_lineHeight.toStringAsFixed(2)}:'
          '${_letterSpacing.toStringAsFixed(1)}:${_textAlignment.name}:'
          '$_firstLineIndent:$_paragraphSpacing:$_chapterTitlePageEnabled:'
          '${_readerFontProfile.cacheSignature}:'
          '${_verticalChrome.paginationSignature}',
        ),
        itemScrollController: _verticalChapterScrollController,
        scrollOffsetController: _verticalChapterOffsetController,
        itemPositionsListener: _verticalChapterPositionsListener,
        initialScrollIndex: _chapterIndex.clamp(0, _chapters.length - 1),
        minCacheExtent: _verticalPageExtentFor(viewport),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _chapters.length,
        itemBuilder: (context, index) => _buildVerticalChapter(index, viewport),
      ),
    );
  }
}
