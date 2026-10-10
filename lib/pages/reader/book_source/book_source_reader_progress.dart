part of 'book_source_reader_page.dart';

extension _BookSourceReaderProgress on _BookSourceReaderPageState {
  Widget? _buildProgressPill() {
    if (!_progressBarEnabled ||
        _chapters.isEmpty ||
        _content == null ||
        isImageOnlyBookSourceChapter(_content!)) {
      return null;
    }
    return ValueListenableBuilder<double>(
      valueListenable: _scrollProgress,
      builder: (context, _, _) {
        final chapterProgress = _currentReadingProgress;
        final position = ReaderProgressPosition(
          chapterIndex: _chapterIndex,
          chapterCount: _chapters.length,
          chapterProgress: chapterProgress,
        );
        final busy = _loadingCatalog || _loadingContent;
        return ReaderProgressPill(
          palette: _readerTheme,
          position: position,
          scope: _progressBarScope,
          onSeekStart: busy ? null : _beginBookSourceProgressPreview,
          onSeek: busy
              ? null
              : (target) => unawaited(_seekBookSourceProgress(target)),
          onPreviousChapter: !busy && position.hasPreviousChapter
              ? () => unawaited(
                  _seekBookSourceProgress(
                    ReaderProgressTarget(_chapterIndex - 1, 0),
                  ),
                )
              : null,
          onNextChapter: !busy && position.hasNextChapter
              ? () => unawaited(
                  _seekBookSourceProgress(
                    ReaderProgressTarget(_chapterIndex + 1, 0),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _beginBookSourceProgressPreview() {
    _pauseAutoPageTurn();
    _controlsTimer?.cancel();
    if (mounted && !_controlsVisible) {
      _updateReaderState(() => _controlsVisible = true);
    }
  }

  void _commitBookSourceProgressNavigation() {
    _beginBookSourceProgressPreview();
    _markReaderAloudForManualPageTurn();
  }

  Future<void> _seekBookSourceProgress(ReaderProgressTarget target) async {
    if (!mounted || _loadingCatalog || _loadingContent || _content == null) {
      return;
    }
    _commitBookSourceProgressNavigation();
    await _loadChapter(
      target.chapterIndex.clamp(0, _chapters.length - 1),
      restoreProgress: target.chapterProgress.clamp(0.0, 1.0),
    );
    if (mounted) _showControlsTemporarily();
  }
}
