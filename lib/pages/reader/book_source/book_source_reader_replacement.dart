part of 'book_source_reader_page.dart';

extension _BookSourceReaderReplacement on _BookSourceReaderPageState {
  String get _replaceRuleBookId => _shelfBookId == null
      ? 'source:${widget.source.id}:${widget.book.id}'
      : 'book:$_shelfBookId';

  bool get _replaceRulesEligibleByDefault {
    if (widget.book.type == 64) return false;
    final config = widget.source.sourceConfig;
    if (config == null) return true;
    try {
      return !ReadingSourceConfig.fromJson(config).isImageSource;
    } on FormatException {
      return config['bookSourceType'] != 2;
    }
  }

  String? get _replaceRuleSourceUrl {
    final raw = '${widget.source.sourceConfig?['bookSourceUrl'] ?? ''}'.trim();
    if (raw.isNotEmpty) return raw;
    final manifest = widget.source.manifestUrl.toString().trim();
    return manifest.isEmpty ? null : manifest;
  }

  void _onReplaceRulesChanged() {
    final revision = _replaceRules.revision;
    if (revision == _observedReplaceRuleRevision) return;
    _observedReplaceRuleRevision = revision;
    if (_chapters.isEmpty) return;
    unawaited(_refreshBookSourceReplacements());
  }

  Future<void> _refreshBookSourceReplacements() async {
    final serial = ++_replaceRuleRefreshSerial;
    final generation = ++_catalogGeneration;
    final loadSerial = ++_chapterLoadSerial;
    bool isCurrent() =>
        mounted &&
        serial == _replaceRuleRefreshSerial &&
        generation == _catalogGeneration &&
        loadSerial == _chapterLoadSerial;
    final chapterIndex = (_requestedChapterIndex ?? _chapterIndex).clamp(
      0,
      _chapters.length - 1,
    );
    final chapterId = _chapters[chapterIndex].id;
    final previousText = _readableChapterText[chapterIndex] ?? '';
    final replacesPendingChapter = chapterIndex != _chapterIndex;
    final visibleOffset = replacesPendingChapter ? null : _currentTextOffset;
    final visibleProgress = replacesPendingChapter
        ? 0.0
        : _currentReadingProgress;
    final position = _replacementPosition?.chapterId == chapterId
        ? _replacementPosition!
        : (
            chapterId: chapterId,
            anchor: captureReaderReplacementAnchor(
              previousText,
              visibleOffset ?? (visibleProgress * previousText.length).round(),
            ),
            textLength: previousText.length,
            progress: visibleProgress,
          );
    _replacementPosition = position;
    final rawChapters = <BookSourceChapter>[
      for (final chapter in _chapters)
        BookSourceChapter(
          id: chapter.id,
          title: _rawChapterTitlesById[chapter.id] ?? chapter.title,
          order: chapter.order,
          updatedAt: chapter.updatedAt,
        ),
    ];
    _effectiveReplaceRuleIds = const <String>{};
    final chapters = await _withReplacedChapterTitles(rawChapters);
    if (!isCurrent()) return;
    final nextIndex = chapters.indexWhere((chapter) => chapter.id == chapterId);
    final retainedContent = Map<int, BookSourceChapterContent>.from(
      _prefetchedContent,
    );
    if (_content != null) retainedContent[_chapterIndex] = _content!;
    _continuousContentLoads.clear();
    _paragraphActionCancellation?.cancel();
    _readableChapterText.clear();
    _paragraphActions.clear();
    _effectiveReplaceRuleIdsByChapter.clear();
    _persistedOnlinePagination.clear();
    _pagedLayouts.clear();
    _pagedLayoutWarms.clear();
    _verticalLayouts.clear();
    _verticalPartKeys.clear();
    _paginationKey = null;
    _paginatedPages = const [];
    _chapters = chapters;
    _navigationChapters = _navigationFor(chapters);
    _navigationCatalog = ReaderNavigationCatalog(_navigationChapters);
    _chapterIndex = nextIndex < 0 ? chapterIndex : nextIndex;
    _prefetchedContent
      ..clear()
      ..addAll(retainedContent);
    _restoreTextOffset = position.anchor.startOffsetUtf16;
    _restorePageProgress = position.progress;
    _restorePagedPosition = true;
    _verticalCanonicalOffset = position.anchor.startOffsetUtf16;
    final retainedIndexes = retainedContent.keys.toList()..sort();
    if (retainedIndexes.remove(_chapterIndex)) {
      retainedIndexes.insert(0, _chapterIndex);
    }
    final currentContent = await _continuousContentFor(_chapterIndex);
    if (!isCurrent()) return;
    final nextText = _readableChapterText[_chapterIndex] ?? '';
    final restoredOffset = resolveReaderReplacementAnchor(
      position.anchor,
      nextText,
      previousTextLength: position.textLength,
    );
    _updateReaderState(() {
      _content = currentContent;
      _loadingContent = false;
      _requestedChapterIndex = null;
      _pageIndex = 0;
      _verticalPageIndex = 0;
      _pageCount = 1;
      _verticalPageCount = 1;
      _restoreTextOffset = restoredOffset;
      _verticalCanonicalOffset = restoredOffset;
    });
    _restoreScrollProgress(
      nextText.isEmpty ? position.progress : restoredOffset / nextText.length,
    );
    _replacementPosition = null;
    for (final index in retainedIndexes.where(
      (index) => index != _chapterIndex,
    )) {
      if (!isCurrent()) return;
      await _continuousContentFor(index);
    }
  }

  Future<void> _showReplaceRules() async {
    if (_chapters.isNotEmpty) {
      final index = _chapterIndex.clamp(0, _chapters.length - 1);
      final titleResult = await _replaceRules.applyBatchAsync(
        <String>[
          _rawChapterTitlesById[_chapters[index].id] ?? _chapters[index].title,
        ],
        bookTitle: widget.book.title,
        sourceName: widget.source.name,
        sourceUrl: _replaceRuleSourceUrl,
        bookId: _replaceRuleBookId,
        eligibleByDefault: _replaceRulesEligibleByDefault,
        title: true,
      );
      _effectiveReplaceRuleIds = Set<String>.unmodifiable({
        ...?_effectiveReplaceRuleIdsByChapter[index],
        ...titleResult.effectiveRuleIds,
      });
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReplaceRulesPage(
          service: _replaceRules,
          bookId: _replaceRuleBookId,
          bookTitle: widget.book.title,
          sourceName: widget.source.name,
          sourceUrl: _replaceRuleSourceUrl,
          eligibleByDefault: _replaceRulesEligibleByDefault,
          effectiveRuleIds: _effectiveReplaceRuleIds.toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _purifySelection(ReaderSelectionSnapshot selection) async {
    final selected = selection.selectedText
        .split('\n')
        .map((line) => line.trim())
        .join('\n')
        .trim();
    if (selected.isEmpty) return;
    final rule = await showReplaceRuleEditor(
      context,
      service: _replaceRules,
      rule: ReplaceRule(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: selected.length <= 24
            ? selected
            : '${selected.substring(0, 24)}…',
        pattern: selected,
        replacement: '',
        scope: widget.book.title,
        isRegex: false,
        scopeContent: true,
      ),
    );
    if (rule != null) await _replaceRules.upsert(rule);
  }
}
