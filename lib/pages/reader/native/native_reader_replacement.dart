part of 'native_reader_page.dart';

extension _NativeReaderReplacement on _NativeReaderPageState {
  String get _replaceRuleBookId => widget.book.id == null
      ? 'local:${sha1.convert(utf8.encode(widget.book.filePath))}'
      : 'book:${widget.book.id}';

  bool get _replaceRulesEligibleByDefault {
    final format = widget.book.format.toLowerCase();
    return format != 'epub' &&
        !const <String>{
          'cbz',
          'cbr',
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
        }.contains(format);
  }

  Map<String, dynamic> get _replaceRuleSourceConfig {
    final raw = _activeBook.sourceJson;
    if (raw == null || raw.isEmpty) return const <String, dynamic>{};
    try {
      final source = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final config = source['sourceConfig'];
      return <String, dynamic>{
        ...source,
        if (config is Map) ...Map<String, dynamic>.from(config),
      };
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  String? get _replaceRuleSourceName {
    final config = _replaceRuleSourceConfig;
    final value = '${config['bookSourceName'] ?? config['name'] ?? ''}'.trim();
    return value.isEmpty ? null : value;
  }

  String? get _replaceRuleSourceUrl {
    final config = _replaceRuleSourceConfig;
    final value = '${config['bookSourceUrl'] ?? config['manifestUrl'] ?? ''}'
        .trim();
    return value.isEmpty ? null : value;
  }

  void _onReplaceRulesChanged() {
    final revision = _replaceRules.revision;
    if (revision == _observedReplaceRuleRevision) return;
    _observedReplaceRuleRevision = revision;
    if (_loadedChapters.isEmpty) return;
    unawaited(_refreshNativeReplacements(revision));
  }

  Future<void> _refreshNativeReplacements(int revision) async {
    final serial = ++_replaceRuleRefreshSerial;
    final loadSerial = ++_chapterLoadSerial;
    bool isCurrent() =>
        mounted &&
        serial == _replaceRuleRefreshSerial &&
        loadSerial == _chapterLoadSerial;
    final chapters = _loadedChapters;
    final chapterIndex = _chapterIndex.clamp(0, chapters.length - 1);
    final previousText = chapters[chapterIndex].plainText;
    final anchor = _visiblePages.isEmpty
        ? (_verticalCanonicalOffset ?? _anchorOffset ?? 0)
        : _currentPositionPage(_visiblePages).startOffset;
    final position =
        _replacementPosition?.chapterId == chapters[chapterIndex].id
        ? _replacementPosition!
        : (
            chapterId: chapters[chapterIndex].id,
            anchor: captureReaderReplacementAnchor(previousText, anchor),
            textLength: previousText.length,
            progress: previousText.isEmpty ? 0.0 : anchor / previousText.length,
          );
    _replacementPosition = position;
    for (final chapter in chapters) {
      chapter.configureReplacement(
        bookTitle: widget.book.title,
        bookId: _replaceRuleBookId,
        sourceName: _replaceRuleSourceName,
        sourceUrl: _replaceRuleSourceUrl,
        eligibleByDefault: _replaceRulesEligibleByDefault,
      );
      chapter.prepareReplacementRevision(revision);
    }
    final titleResult = await _replaceRules.applyBatchAsync(
      chapters.map((chapter) => chapter.originalTitle).toList(growable: false),
      bookTitle: widget.book.title,
      bookId: _replaceRuleBookId,
      sourceName: _replaceRuleSourceName,
      sourceUrl: _replaceRuleSourceUrl,
      eligibleByDefault: _replaceRulesEligibleByDefault,
      title: true,
    );
    if (!isCurrent()) return;
    for (var index = 0; index < chapters.length; index++) {
      chapters[index].applyPreparedTitle(titleResult.values[index]);
    }
    await Future.wait<void>([
      for (final chapter in chapters.where((chapter) => chapter.hasLoadedText))
        chapter.prepareReplacementAsync(_replaceRules),
    ]);
    if (!isCurrent()) return;
    final navigation = await _prepareNavigationTitles(
      _parsedNavigationChapters,
    );
    if (!isCurrent()) return;
    final effective = <String>{...chapters[chapterIndex].effectiveRuleIds};
    final currentTitleResult = await _replaceRules.applyBatchAsync(
      <String>[chapters[chapterIndex].originalTitle],
      bookTitle: widget.book.title,
      bookId: _replaceRuleBookId,
      sourceName: _replaceRuleSourceName,
      sourceUrl: _replaceRuleSourceUrl,
      eligibleByDefault: _replaceRulesEligibleByDefault,
      title: true,
    );
    if (!isCurrent()) return;
    effective.addAll(currentTitleResult.effectiveRuleIds);
    _pageCache.clear();
    _persistedPaginationPayloads.clear();
    _continuousPartCache.clear();
    _navigationMemoryCache.removeWhere(
      (key, _) => key == _bookCacheKey || key.startsWith('$_bookCacheKey:'),
    );
    _resetHorizontalPagingWindow(chapterIndex, chapterCount: chapters.length);
    _setReaderState(() {
      _navigationChapters = navigation.isNotEmpty
          ? navigation
          : List<ReaderNavigationChapter>.generate(
              chapters.length,
              (index) => ReaderNavigationChapter(
                title: chapters[index].title,
                index: index,
                id: chapters[index].id,
                depth: chapters[index].depth,
              ),
              growable: false,
            );
      _navigationCatalog = ReaderNavigationCatalog(_navigationChapters);
      _effectiveReplaceRuleIds = Set<String>.unmodifiable(effective);
      _chapterIndex = chapterIndex;
      _pageIndex = 0;
      _anchorOffset = resolveReaderReplacementAnchor(
        position.anchor,
        chapters[chapterIndex].plainText,
        previousTextLength: position.textLength,
      );
      _verticalCanonicalOffset = _anchorOffset;
      _restoreAnchorAfterLayout = true;
      _initialPositionRestored = false;
      _initialPositionRestoreScheduled = false;
      _restoreContinuousAnchorCentered = true;
      _visiblePages = const [];
      _visibleContinuousParts = const [];
    });
    _replacementPosition = null;
  }

  Future<void> _showReplaceRules() async {
    if (_loadedChapters.isNotEmpty) {
      final chapter =
          _loadedChapters[_chapterIndex.clamp(0, _loadedChapters.length - 1)];
      final titleResult = await _replaceRules.applyBatchAsync(
        <String>[chapter.originalTitle],
        bookTitle: widget.book.title,
        bookId: _replaceRuleBookId,
        sourceName: _replaceRuleSourceName,
        sourceUrl: _replaceRuleSourceUrl,
        eligibleByDefault: _replaceRulesEligibleByDefault,
        title: true,
      );
      _effectiveReplaceRuleIds = Set<String>.unmodifiable({
        ...chapter.effectiveRuleIds,
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
          sourceName: _replaceRuleSourceName,
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
