import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_skin_icon.dart';
import 'package:flutter/rendering.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../core/reader/reader_aloud_controller.dart';
import '../utils/reader_themes.dart';
import 'glass_buttons.dart';

class ReaderAloudTranscript extends StatefulWidget {
  const ReaderAloudTranscript({
    super.key,
    required this.controller,
    required this.palette,
    this.onBrowse,
    this.framed = true,
  });

  final ReaderAloudController controller;
  final ReaderThemePalette palette;
  final VoidCallback? onBrowse;
  final bool framed;

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
      final alignment = index == 0 ? 0.0 : 0.35;
      if (jump || chapterChanged || MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(index: index, alignment: alignment);
      } else {
        unawaited(
          _scrollController.scrollTo(
            index: index,
            alignment: alignment,
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

  TextSpan _textSpanForSegment(ReaderAloudSegment segment, Color color) {
    final source = widget.controller.source;
    final ReaderAloudTextSource? typography = source is ReaderAloudTextSource
        ? source as ReaderAloudTextSource
        : null;
    final style =
        (typography?.textStyle ??
                const TextStyle(inherit: false, fontSize: 16, height: 1.7))
            .copyWith(inherit: false, color: color);
    final chapter = widget.controller.currentChapter;
    final builder = chapter?.buildTextSpan;
    if (chapter != null &&
        builder != null &&
        chapter.index == segment.chapterIndex &&
        chapter.id == segment.chapterId &&
        segment.startOffset >= 0 &&
        segment.endOffset <= chapter.text.length) {
      return builder(
        segment.startOffset,
        segment.endOffset,
        style,
        typography?.preserveDocumentFont ?? false,
      );
    }
    return TextSpan(text: segment.text, style: style);
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.controller.chapterSegments;
    final highlight = widget.controller.highlight;
    final showPreparing =
        widget.controller.isPreparing &&
        widget.controller.state != ReaderAloudPlaybackState.paused &&
        _followsPlayback;
    final returnLabel = _copy(
      context,
      '回到正在朗读',
      'Back to reading',
      '読み上げ位置に戻る',
    );
    final returnLabelStyle =
        (Theme.of(context).textTheme.labelLarge ??
                const TextStyle(fontSize: 14))
            .copyWith(color: widget.palette.text, fontWeight: FontWeight.w600);
    final returnLabelPainter = TextPainter(
      text: TextSpan(text: returnLabel, style: returnLabelStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final returnLabelHeight = returnLabelPainter.height;
    returnLabelPainter.dispose();
    final returnButtonHeight = math.max(
      44.0,
      math.max(18.0, returnLabelHeight) + 14,
    );
    final returnButtonAvoidanceHeight = 12.0 + returnButtonHeight + 8.0;
    return Stack(
      key: const ValueKey('reader-aloud-transcript'),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.framed
                ? widget.palette.surface.withValues(alpha: 0.56)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: widget.framed
                ? Border.all(
                    color: widget.palette.border.withValues(alpha: 0.56),
                  )
                : null,
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
                          if (notification.direction != ScrollDirection.idle) {
                            if (_followsPlayback) {
                              setState(() => _followsPlayback = false);
                            }
                            widget.onBrowse?.call();
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
                                    child: Text.rich(
                                      _textSpanForSegment(
                                        segment,
                                        selected
                                            ? widget.palette.accent
                                            : widget.palette.text,
                                      ),
                                      // Even an unspecified reader family must
                                      // not inherit the app's decorative font.
                                      style: const TextStyle(inherit: false),
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
                      SizedBox(
                        key: const ValueKey('reader-aloud-return-avoidance'),
                        height: returnButtonAvoidanceHeight,
                      ),
                  ],
                ),
        ),
        if (!_followsPlayback)
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 12,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: GlassTextButton(
                key: const ValueKey('reader-aloud-return-to-reading'),
                onPressed: _resumeFollowing,
                tooltip: returnLabel,
                minimumHeight: returnButtonHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                color: widget.palette.controlBar.withValues(alpha: 0.88),
                foregroundColor: widget.palette.text,
                outlineColor: widget.palette.border.withValues(alpha: 0.72),
                highlighted: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSkinIcon.adapt(
                      Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: widget.palette.accent,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        returnLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: returnLabelStyle,
                      ),
                    ),
                  ],
                ),
              ),
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
