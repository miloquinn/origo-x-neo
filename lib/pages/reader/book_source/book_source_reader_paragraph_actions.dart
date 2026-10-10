part of 'book_source_reader_page.dart';

extension _BookSourceReaderParagraphActions on _BookSourceReaderPageState {
  double _paragraphActionGutterFor(int chapterIndex) =>
      (_paragraphActions[chapterIndex]?.isNotEmpty ?? false)
      ? ReaderParagraphActionLayer.gutter
      : 0;

  Future<void> _openParagraphAction(
    int chapterIndex,
    BookSourceParagraphAction action,
  ) async {
    if (_paragraphActionCancellation != null || !mounted) return;
    final actions = _paragraphActions[chapterIndex];
    if (actions == null || !actions.contains(action)) return;
    final generation = _catalogGeneration;
    final chapter = _chapters[chapterIndex];
    final cancellation = BookDownloadCancellation();
    _paragraphActionCancellation = cancellation;
    var refreshContent = false;
    _pauseAutoPageTurn();
    final sourceVariables = <String, String>{
      ...widget.book.sourceVariables,
      'chapterIndex': '$chapterIndex',
      'chapterTitle': _sourceChapterTitle(chapterIndex),
      'bookName': widget.book.title,
      'bookAuthor': widget.book.author,
      'bookType': '${widget.book.type}',
    };
    bool isCurrent() =>
        mounted &&
        !cancellation.isCancelled &&
        generation == _catalogGeneration &&
        chapterIndex < _chapters.length &&
        _chapters[chapterIndex].id == chapter.id;

    Future<SourceScriptInteractionResult> interaction(
      SourceScriptInteractionRequest request,
    ) async {
      if (!isCurrent()) {
        return const SourceScriptInteractionResult(cancelled: true);
      }
      if (request.kind == SourceScriptInteractionKind.verificationCode) {
        return SourceInteractionCoordinator.instance.request(
          sourceId: widget.source.id,
          sourceName: widget.source.name,
          interaction: request,
          cancellation: cancellation,
        );
      }
      final callbackCancellation = BookDownloadCancellation();
      void cancelCallbacks() => callbackCancellation.cancel();
      cancellation.addListener(cancelCallbacks);
      try {
        final result = await showReaderParagraphReviewSheet(
          context,
          palette: _readerTheme,
          sourceId: widget.source.id,
          sourceName: widget.source.name,
          request: request,
          sourceUrl: sourceFromRegistered(widget.source).baseUri.toString(),
          cancellation: cancellation,
          onRefreshContent: (_) => refreshContent = true,
          onClosing: cancelCallbacks,
          onScriptRequest: (method, arguments) async {
            callbackCancellation.throwIfCancelled();
            if (!isCurrent()) throw const BookDownloadCancelledException();
            final script = SourceBrowserScriptRequestEvaluator.scriptFor(
              method,
              arguments,
            );
            final evaluate = request.evaluateScript;
            if (evaluate == null) {
              throw UnsupportedError(
                'The source browser has no chapter action context.',
              );
            }
            final value = await evaluate(
              script,
              cancellationCheck: callbackCancellation.throwIfCancelled,
            );
            if (!isCurrent()) throw const BookDownloadCancelledException();
            callbackCancellation.throwIfCancelled();
            return SourceBrowserScriptRequestEvaluator.resultFrom(value);
          },
        );
        if (!isCurrent()) {
          return const SourceScriptInteractionResult(cancelled: true);
        }
        return SourceScriptInteractionResult(
          body: result.body,
          finalUrl: result.finalUri.toString(),
          browserSession: result.session,
        );
      } finally {
        cancellation.removeListener(cancelCallbacks);
        cancelCallbacks();
      }
    }

    try {
      await _client.executeChapterAction(
        widget.source,
        bookId: widget.book.id,
        chapterId: chapter.id,
        script: action.script,
        result: action.imageSource,
        sourceVariables: sourceVariables,
        cancellation: cancellation,
        interactionHandler: interaction,
      );
      if (refreshContent && isCurrent() && _chapterIndex == chapterIndex) {
        await _refreshParagraphChapter(chapterIndex, cancellation);
      }
    } on BookDownloadCancelledException {
      // Reader exit and catalog changes own cancellation of their comments.
    } on SourceBrowserCancelled {
      // A replaced source session invalidates its active comments.
    } catch (error, stack) {
      debugPrint('Paragraph comments failed: ${error.runtimeType}\n$stack');
      if (mounted && isCurrent()) {
        showSideToast(
          context,
          context.l10n.readerParagraphReviewFailed,
          kind: SideToastKind.error,
        );
      }
    } finally {
      if (identical(_paragraphActionCancellation, cancellation)) {
        _paragraphActionCancellation = null;
      }
      cancellation.cancel();
    }
  }

  Future<void> _refreshParagraphChapter(
    int index,
    BookDownloadCancellation cancellation,
  ) async {
    final chapter = _chapters[index];
    final generation = _catalogGeneration;
    final offset = _currentTextOffset;
    final progress = _currentReadingProgress;
    final content = await _client.refreshChapterContent(
      widget.source,
      bookId: widget.book.id,
      chapterId: chapter.id,
      sourceVariables: {
        ...widget.book.sourceVariables,
        'chapterIndex': '$index',
        'chapterTitle': _sourceChapterTitle(index),
        'bookName': widget.book.title,
        'bookAuthor': widget.book.author,
        'bookType': '${widget.book.type}',
      },
      cancellation: cancellation,
    );
    if (!mounted ||
        cancellation.isCancelled ||
        generation != _catalogGeneration ||
        _chapterIndex != index) {
      return;
    }
    _prefetchedContent[index] = content;
    _readableChapterText.remove(index);
    _paragraphActions.remove(index);
    _pagedLayouts.remove(index);
    _verticalLayouts.remove(index);
    _persistedOnlinePagination.remove(index);
    await _loadChapter(
      index,
      restoreTextOffset: offset,
      restoreProgress: progress,
      saveCurrent: false,
    );
  }
}
