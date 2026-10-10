part of 'book_source_reader_page.dart';

extension _BookSourceReaderCatalogLoading on _BookSourceReaderPageState {
  Future<void> _initialize() async {
    final catalogLoadSerial = ++_catalogLoadSerial;
    final requestCancellation = _activeReaderRequestCancellation;
    ++_chapterLoadSerial;
    _updateReaderState(() {
      _loadingCatalog = true;
      _loadingContent = false;
      _requestedChapterIndex = null;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        _resolveShelfBookForInitialization(),
        _replaceRules.load(),
        _client.getChapters(
          widget.source,
          widget.book.id,
          sourceVariables: widget.book.sourceVariables,
          cancellation: requestCancellation,
        ),
        widget.progressStore.load(
          sourceId: widget.source.id,
          bookId: widget.book.id,
        ),
        _readerSettingsStore.load(),
        _readerSettingsStore.loadScrollByChapter(),
        _customThemeStore.loadAll(),
        _themeOrderStore.load(),
        _readerSettingsStore.loadTapZones(),
      ]);
      if (!_isReaderRequestActive(requestCancellation) ||
          catalogLoadSerial != _catalogLoadSerial) {
        return;
      }
      final resolvedShelfBook = results[0] as Book?;
      final shelfBook = _shelfBook?.id == null ? resolvedShelfBook : _shelfBook;
      _updateReaderState(() {
        _shelfBook = shelfBook;
        _shelfBookId = shelfBook?.id;
      });
      final rawChapters = [...results[2]! as List<BookSourceChapter>]
        ..sort((a, b) => a.order.compareTo(b.order));
      final rawChapterTitlesById = <String, String>{
        for (final chapter in rawChapters) chapter.id: chapter.title,
      };
      final chapters = await _withReplacedChapterTitles(rawChapters);
      final saved = results[3] as BookSourceReadingProgress?;
      final settings = results[4]! as ReaderSettings;
      final scrollByChapter = results[5]! as bool;
      final customThemes = results[6] as List<ReaderCustomTheme>;
      final themeOrder = results[7] as List<String>;
      final tapZones = results[8] as ReaderTapZones;
      var initialIndex = saved?.chapterIndex ?? 0;
      if (saved != null && saved.chapterId.isNotEmpty) {
        final byId = chapters.indexWhere(
          (chapter) => chapter.id == saved.chapterId,
        );
        if (byId >= 0) initialIndex = byId;
      }
      if (chapters.isNotEmpty) {
        initialIndex = initialIndex.clamp(0, chapters.length - 1);
      }
      if (!_isReaderRequestActive(requestCancellation) ||
          catalogLoadSerial != _catalogLoadSerial) {
        return;
      }
      ReaderThemes.setCustomThemes(customThemes);
      ReaderThemes.setThemeOrder(themeOrder);
      _updateReaderState(() {
        _replaceChapterCatalog(chapters, rawChapterTitlesById);
        _chapterIndex = initialIndex;
        _fontSize = settings.fontSize;
        _textBrightness = settings.textBrightness;
        _dimTextInDarkMode = settings.dimTextInDarkMode;
        _fontWeight = settings.fontWeight;
        _horizontalMargin = settings.horizontalMargin;
        _topMargin = settings.topMargin;
        _bottomMargin = settings.bottomMargin;
        _lineHeight = settings.lineHeight;
        _letterSpacing = settings.letterSpacing;
        _textAlignment = settings.textAlignment;
        _firstLineIndent = settings.firstLineIndent;
        _paragraphSpacing = settings.paragraphSpacing;
        _readerThemeId = ReaderThemes.byId(settings.themeId).id;
        _pageMode = settings.pageMode;
        _pullBookmarkEnabled = settings.pullBookmarkEnabled;
        _tapPageAnimationEnabled = settings.tapPageAnimationEnabled;
        _tapZones = tapZones;
        _tabletTwoPageEnabled = settings.tabletTwoPageEnabled;
        _scrollByChapter = scrollByChapter;
        _chapterTitlePageEnabled = settings.chapterTitlePageEnabled;
        _chapterProgressStyle = settings.chapterProgressStyle;
        _loadingCatalog = false;
      });
      unawaited(_syncVolumeKeyPaging());
      if (shelfBook != null) {
        unawaited(
          _loadShelfReadingData(
            shelfBook,
            catalogLoadSerial: catalogLoadSerial,
          ),
        );
      }
      if (chapters.isNotEmpty) {
        await _loadChapter(
          initialIndex,
          restoreProgress: saved?.chapterProgress ?? 0,
          saveCurrent: false,
        );
      }
    } on BookDownloadCancelledException {
      return;
    } catch (error) {
      if (!_isReaderRequestActive(requestCancellation) ||
          catalogLoadSerial != _catalogLoadSerial) {
        return;
      }
      _updateReaderState(() {
        _loadingCatalog = false;
        _error = error;
        _controlsVisible = true;
      });
    }
  }

  void _replaceChapterCatalog(
    List<BookSourceChapter> chapters,
    Map<String, String> rawTitlesById,
  ) {
    ++_catalogGeneration;
    _paragraphActionCancellation?.cancel();
    _chapters = chapters;
    _rawChapterTitlesById = Map<String, String>.unmodifiable(rawTitlesById);
    _navigationChapters = _navigationFor(chapters);
    _navigationCatalog = ReaderNavigationCatalog(_navigationChapters);
    _content = null;
    _prefetchedContent.clear();
    _readableChapterText.clear();
    _paragraphActions.clear();
    _continuousContentLoads.clear();
    _persistedOnlinePagination.clear();
    _pagedLayouts.clear();
    _pagedLayoutWarms.clear();
    _verticalLayouts.clear();
    _verticalPartKeys.clear();
    _autoPreparingChapters.clear();
    _autoScrollRestoring = false;
    _paginationKey = null;
    _paginatedPages = const [];
    _pageIndex = 0;
    _pageCount = 1;
    _pendingSlideChapterIndex = null;
    _pendingSlideBoundaryViewIndex = null;
    _horizontalPageTurnTracker.clear();
    _verticalCanonicalOffset = null;
  }

  Future<List<BookSourceChapter>> _withReplacedChapterTitles(
    List<BookSourceChapter> chapters,
  ) async {
    if (chapters.isEmpty) return const <BookSourceChapter>[];
    final replacementRevision = _replaceRules.revision;
    final cleaned = await _replaceRules.applyBatchAsync(
      chapters.map((chapter) => chapter.title).toList(growable: false),
      bookTitle: widget.book.title,
      sourceName: widget.source.name,
      sourceUrl: _replaceRuleSourceUrl,
      bookId: _replaceRuleBookId,
      eligibleByDefault: _replaceRulesEligibleByDefault,
      title: true,
    );
    if (replacementRevision != _replaceRules.revision) {
      return _withReplacedChapterTitles(chapters);
    }
    return List<BookSourceChapter>.generate(
      chapters.length,
      (index) => BookSourceChapter(
        id: chapters[index].id,
        title: cleaned.values[index],
        order: chapters[index].order,
        updatedAt: chapters[index].updatedAt,
      ),
      growable: false,
    );
  }

  String _sourceChapterTitle(int index) {
    final chapter = _chapters[index];
    return _rawChapterTitlesById[chapter.id] ?? chapter.title;
  }

  List<ReaderNavigationChapter> _navigationFor(
    List<BookSourceChapter> chapters,
  ) => List<ReaderNavigationChapter>.generate(
    chapters.length,
    (index) => ReaderNavigationChapter(
      title: chapters[index].title,
      index: index,
      id: chapters[index].id,
    ),
    growable: false,
  );

  Future<void> _syncVolumeKeyPaging() => ReaderVolumeKeyController.activate(
    owner: this,
    pageTurningAvailable: _pageMode != BookSourcePageMode.verticalScroll,
    onNextPage: () => unawaited(_handleVolumePageTurn(forward: true)),
    onPreviousPage: () => unawaited(_handleVolumePageTurn(forward: false)),
  );

  Future<void> _handleVolumePageTurn({required bool forward}) async {
    _pauseAutoPageTurn();
    if (!mounted ||
        _loadingCatalog ||
        _loadingContent ||
        _pageMode == BookSourcePageMode.verticalScroll) {
      return;
    }
    final imageContent = _content;
    if (imageContent != null && isImageOnlyBookSourceChapter(imageContent)) {
      return;
    }
    if (_pageMode == BookSourcePageMode.pageCurl) {
      final controller = _usesTwoPageLayout
          ? (forward
                ? _spreadForwardPageCurlController
                : _spreadBackwardPageCurlController)
          : _pageCurlController;
      if (forward) {
        await controller.turnForward();
      } else {
        await controller.turnBackward();
      }
      return;
    }
    if (_pageMode == BookSourcePageMode.coverSlide) {
      if (forward) {
        await _coverPageTurnController.turnForward();
      } else {
        await _coverPageTurnController.turnBackward();
      }
      return;
    }
    if (_pageMode == BookSourcePageMode.horizontalSlide &&
        _pageController.hasClients) {
      if (forward) {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        await _pageController.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    if (forward) {
      await _turnForward();
    } else {
      await _turnBackward();
    }
  }

  Future<void> _saveProgress() {
    if (_loadingCatalog ||
        _loadingContent ||
        _error != null ||
        _content == null ||
        _chapters.isEmpty ||
        _chapterIndex >= _chapters.length) {
      return _progressSaveQueue;
    }
    final chapterIndex = _chapterIndex;
    final chapterId = _chapters[chapterIndex].id;
    final chapterCount = _chapters.length;
    final shelfBookId = _shelfBookId;
    // A continuous text block can span an entire chapter. Its list index is
    // a layout detail, so persist the canonical text fraction instead.
    if (_pageMode == BookSourcePageMode.verticalScroll &&
        (_restorePagedPosition || _autoScrollRestoring)) {
      return _progressSaveQueue;
    }
    final progress = _currentReadingProgress;
    final progressSnapshot = BookSourceReadingProgress(
      chapterId: chapterId,
      chapterIndex: chapterIndex,
      chapterProgress: progress,
      updatedAt: DateTime.now().toUtc(),
    );
    _progressSaveQueue = _progressSaveQueue.then((_) async {
      try {
        await widget.progressStore.save(
          sourceId: widget.source.id,
          bookId: widget.book.id,
          progress: progressSnapshot,
        );
        if (shelfBookId != null) {
          await _shelfService.updateShelfProgress(
            shelfBookId: shelfBookId,
            chapterIndex: chapterIndex,
            chapterCount: chapterCount,
            chapterProgress: progress,
          );
        }
      } catch (error) {
        debugPrint('save source reading progress failed: $error');
      }
    });
    return _progressSaveQueue;
  }

  Future<Book?> _resolveShelfBookForInitialization() {
    final shelfBook = _shelfBook;
    if (shelfBook?.id != null) return Future<Book?>.value(shelfBook);
    final pending = _shelfBookLookup;
    if (pending != null) return pending;

    late final Future<Book?> lookup;
    lookup = _findShelfBook().whenComplete(() {
      if (identical(_shelfBookLookup, lookup)) _shelfBookLookup = null;
    });
    _shelfBookLookup = lookup;
    return lookup;
  }

  Future<Book?> _findShelfBook() async {
    try {
      return await _shelfService.findShelfBook(
        sourceId: widget.source.id,
        sourceBookId: widget.book.id,
      );
    } catch (error) {
      debugPrint('resolve source shelf book failed: $error');
      return null;
    }
  }

  Future<void> _loadShelfReadingData(
    Book shelfBook, {
    required int catalogLoadSerial,
  }) async {
    final shelfBookId = shelfBook.id;
    if (shelfBookId == null) return;
    if (_chapters.isNotEmpty) {
      unawaited(
        SourceBookUpdateService()
            .markOnlineOpened(shelfBook, latestChapterId: _chapters.last.id)
            .catchError((Object _) {}),
      );
    }
    unawaited(ReadingResumeService.markReading(shelfBookId));
    try {
      final results = await Future.wait<Object>([
        _bookmarkDao.getBookmarksForBook(shelfBookId),
        _bookNoteDao.selectBookNotesByBookId(shelfBookId),
      ]);
      if (!mounted || catalogLoadSerial != _catalogLoadSerial) return;
      _updateReaderState(() {
        _bookmarks = results[0] as List<Bookmark>;
        _annotations = results[1] as List<BookNote>;
        _annotationRevision++;
      });
    } catch (error) {
      debugPrint('load source bookmarks and annotations failed: $error');
    }
  }

  Future<void> _reloadAnnotations() async {
    final bookId = _shelfBookId;
    if (bookId == null) return;
    final annotations = await _bookNoteDao.selectBookNotesByBookId(bookId);
    if (!mounted) return;
    _updateReaderState(() {
      _annotations = annotations;
      _annotationRevision++;
    });
  }

  bool _ensureAnnotationBook() {
    if (_shelfBookId != null) return true;
    showSideToast(
      context,
      context.l10n.readerAnnotationShelfRequired,
      duration: const Duration(milliseconds: 2200),
      icon: Icons.add_to_photos_outlined,
      kind: SideToastKind.info,
    );
    return false;
  }

  Future<void> _saveTextAnnotation(
    ReaderSelectionSnapshot selection,
    ReaderAnnotationEditorResult annotation,
  ) async {
    if (!_ensureAnnotationBook() || _annotationBusy) return;
    final bookId = _shelfBookId!;
    _updateReaderState(() => _annotationBusy = true);
    try {
      final now = DateTime.now();
      await _bookNoteDao.insertBookNote(
        BookNote(
          bookId: bookId,
          content: selection.selectedText,
          cfi: selection.cfiFor(annotation.type),
          canonicalLocator: selection.canonicalLocatorJson,
          chapter: selection.chapterTitle,
          type: annotation.type,
          color: annotation.colorHex,
          readerNote: annotation.note,
          pageNumber: selection.pageIndex,
          startOffset: selection.startOffset,
          endOffset: selection.endOffset,
          createTime: now,
          updateTime: now,
        ),
      );
      await _reloadAnnotations();
      if (!mounted) return;
      showSideToast(
        context,
        context.l10n.readerAnnotationSaved,
        duration: const Duration(milliseconds: 1600),
        icon: annotation.type == readerAnnotationTypeNote
            ? Icons.mode_comment_rounded
            : Icons.auto_awesome_rounded,
        kind: SideToastKind.success,
      );
    } catch (error) {
      debugPrint('save source annotation failed: $error');
    } finally {
      if (mounted) _updateReaderState(() => _annotationBusy = false);
    }
  }

  Future<void> _deleteAnnotation(BookNote annotation) async {
    final id = annotation.id;
    if (id == null) return;
    await _bookNoteDao.deleteBookNoteById(id);
    if (!mounted) return;
    _updateReaderState(() {
      _annotations = _annotations
          .where((candidate) => candidate.id != id)
          .toList(growable: false);
      _annotationRevision++;
    });
    showSideToast(
      context,
      context.l10n.readerAnnotationDeleted,
      duration: const Duration(milliseconds: 1600),
      icon: Icons.delete_outline_rounded,
      kind: SideToastKind.success,
    );
  }
}
