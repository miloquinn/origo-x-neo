import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/reader/reader_aloud_controller.dart';
import '../utils/reader_themes.dart';

class ReaderAloudTranscript extends StatefulWidget {
  const ReaderAloudTranscript({
    super.key,
    required this.controller,
    required this.palette,
  });

  final ReaderAloudController controller;
  final ReaderThemePalette palette;

  @override
  State<ReaderAloudTranscript> createState() => _ReaderAloudTranscriptState();
}

class _ReaderAloudTranscriptState extends State<ReaderAloudTranscript> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();
  bool _followsPlayback = true;
  int? _lastChapterIndex;
  int? _lastSegmentOffset;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handlePlaybackChanged);
    _scheduleFollow(jump: true);
  }

  @override
  void didUpdateWidget(covariant ReaderAloudTranscript oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handlePlaybackChanged);
    widget.controller.addListener(_handlePlaybackChanged);
    _lastChapterIndex = null;
    _lastSegmentOffset = null;
    _scheduleFollow(jump: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handlePlaybackChanged);
    super.dispose();
  }

  void _handlePlaybackChanged() {
    if (!mounted) return;
    setState(() {});
    if (_followsPlayback) _scheduleFollow();
  }

  void _scheduleFollow({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_followsPlayback || !_scrollController.isAttached) {
        return;
      }
      final index = _currentSegmentIndex();
      if (index < 0) return;
      final segment = widget.controller.chapterSegments[index];
      final chapterChanged = _lastChapterIndex != segment.chapterIndex;
      final segmentChanged = _lastSegmentOffset != segment.startOffset;
      if (!chapterChanged && !segmentChanged) return;
      _lastChapterIndex = segment.chapterIndex;
      _lastSegmentOffset = segment.startOffset;
      if (jump || chapterChanged) {
        _scrollController.jumpTo(index: index, alignment: 0.35);
      } else {
        unawaited(
          _scrollController.scrollTo(
            index: index,
            alignment: 0.35,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  int _currentSegmentIndex() {
    final segments = widget.controller.chapterSegments;
    final current = widget.controller.currentSegment;
    if (current == null) return segments.isEmpty ? -1 : 0;
    return segments.indexWhere(
      (segment) =>
          segment.chapterIndex == current.chapterIndex &&
          segment.startOffset == current.startOffset,
    );
  }

  void _resumeFollowing() {
    setState(() => _followsPlayback = true);
    _lastChapterIndex = null;
    _lastSegmentOffset = null;
    _scheduleFollow(jump: true);
  }

  Future<void> _playSegment(ReaderAloudSegment segment) async {
    setState(() => _followsPlayback = true);
    _lastChapterIndex = null;
    _lastSegmentOffset = null;
    await widget.controller.playFromOffset(
      ReaderAloudPosition(
        chapterIndex: segment.chapterIndex,
        offset: segment.startOffset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.controller.chapterSegments;
    final highlight = widget.controller.highlight;
    final showPreparing =
        widget.controller.isPreparing &&
        widget.controller.state != ReaderAloudPlaybackState.paused &&
        _followsPlayback;
    return Stack(
      key: const ValueKey('reader-aloud-transcript'),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.palette.surface.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.palette.border.withValues(alpha: 0.56),
            ),
          ),
          child: segments.isEmpty
              ? Center(
                  child: Text(
                    _copy(context, '正在载入正文…', 'Loading text…', '本文を読み込み中…'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: widget.palette.secondaryText,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          if (notification.direction != ScrollDirection.idle &&
                              _followsPlayback) {
                            setState(() => _followsPlayback = false);
                          }
                          return false;
                        },
                        child: ScrollablePositionedList.builder(
                          key: ValueKey(
                            'reader-aloud-transcript-list-${widget.controller.currentChapter?.index}',
                          ),
                          itemScrollController: _scrollController,
                          itemPositionsListener: _positionsListener,
                          padding: EdgeInsets.fromLTRB(
                            12,
                            showPreparing ? 58 : 14,
                            12,
                            14,
                          ),
                          itemCount: segments.length,
                          itemBuilder: (context, index) {
                            final segment = segments[index];
                            final selected = highlight != null
                                ? highlight.chapterIndex ==
                                          segment.chapterIndex &&
                                      highlight.startOffset ==
                                          segment.startOffset
                                : widget.controller.isPreparing &&
                                      widget
                                              .controller
                                              .currentSegment
                                              ?.chapterIndex ==
                                          segment.chapterIndex &&
                                      widget
                                              .controller
                                              .currentSegment
                                              ?.startOffset ==
                                          segment.startOffset;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                key: ValueKey(
                                  'reader-aloud-transcript-segment-${segment.chapterIndex}-${segment.startOffset}',
                                ),
                                color: selected
                                    ? widget.palette.accent.withValues(
                                        alpha: 0.13,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => unawaited(_playSegment(segment)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      segment.text,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: selected
                                                ? widget.palette.accent
                                                : widget.palette.text,
                                            height: 1.7,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!_followsPlayback)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: FilledButton.tonalIcon(
                          key: const ValueKey('reader-aloud-return-to-reading'),
                          onPressed: _resumeFollowing,
                          icon: const Icon(Icons.my_location_rounded, size: 18),
                          label: Text(
                            _copy(
                              context,
                              '回到正在朗读',
                              'Back to reading',
                              '読み上げ位置に戻る',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (showPreparing)
          Positioned(
            top: 10,
            right: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.palette.controlBar.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: widget.palette.shadow.withValues(alpha: 0.14),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.palette.accent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _copy(context, '正在准备', 'Preparing', '準備中'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: widget.palette.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _copy(BuildContext context, String zh, String en, String ja) =>
      switch (Localizations.localeOf(context).languageCode) {
        'en' => en,
        'ja' => ja,
        _ => zh,
      };
}
