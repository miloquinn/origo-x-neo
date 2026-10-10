import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';
import '../utils/reader_themes.dart';
import 'app_skin_icon.dart';
import 'glass_control_surface.dart';

/// Reader-owned selection actions, with one material and one overflow panel.
/// Selection snapshots and action lifetimes remain owned by the text leaf.
class ReaderSelectionToolbar extends StatefulWidget {
  const ReaderSelectionToolbar({
    super.key,
    required this.palette,
    required this.anchors,
    required this.onHighlight,
    required this.onNote,
    required this.onCopy,
    this.onAskAi,
    this.onSearch,
    this.onPurify,
  });

  final ReaderThemePalette palette;
  final TextSelectionToolbarAnchors anchors;
  final VoidCallback onHighlight;
  final VoidCallback onNote;
  final VoidCallback? onCopy;
  final VoidCallback? onAskAi;
  final VoidCallback? onSearch;
  final VoidCallback? onPurify;

  @override
  State<ReaderSelectionToolbar> createState() => _ReaderSelectionToolbarState();
}

class _ReaderSelectionToolbarState extends State<ReaderSelectionToolbar> {
  static const _surfaceBorder = 1.0;
  static const _inset = 4.0;
  static const _moreWidth = 44.0;
  bool _moreOpen = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final material = MaterialLocalizations.of(context);
    final style = Theme.of(context).textTheme.labelLarge!.copyWith(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: palette.text,
    );
    final primary = [
      _SelectionAction('copy', material.copyButtonLabel, widget.onCopy),
      _SelectionAction(
        'highlight',
        context.l10n.highlights,
        widget.onHighlight,
      ),
      _SelectionAction('note', context.l10n.notes, widget.onNote),
    ];
    final secondary = [
      if (widget.onSearch != null)
        _SelectionAction(
          'search',
          context.l10n.search,
          widget.onSearch,
          icon: Icons.search_rounded,
        ),
      if (widget.onPurify != null)
        _SelectionAction(
          'purify',
          context.l10n.readerPurifySelection,
          widget.onPurify,
          icon: Icons.auto_fix_high_rounded,
        ),
      if (widget.onAskAi != null)
        _SelectionAction(
          'ask-ai',
          context.l10n.readerAskAi,
          widget.onAskAi,
          icon: Icons.auto_awesome_outlined,
        ),
    ];
    final safePadding = MediaQuery.paddingOf(context);
    final origin = Offset(safePadding.left + 8, safePadding.top + 8);
    return Padding(
      padding: safePadding + const EdgeInsets.all(8),
      child: CustomSingleChildLayout(
        delegate: _SelectionToolbarLayout(
          anchorAbove:
              widget.anchors.primaryAnchor - origin - const Offset(0, 8),
          anchorBelow:
              (widget.anchors.secondaryAnchor ?? widget.anchors.primaryAnchor) -
              origin +
              const Offset(0, 20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = primary.map(
              (action) => _measure(action.label, style),
            );
            final widths = metrics
                .map((size) => math.max(60.0, size.width + 20))
                .toList();
            final rowHeight = math.max(
              44.0,
              metrics.map((size) => size.height + 20).reduce(math.max),
            );
            final surfaceShape = RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(
                (rowHeight + 4 + _surfaceBorder * 2) / 2,
              ),
            );
            final availableWidth = constraints.maxWidth;
            var visibleCount = primary.length;
            double rowWidth(int count) =>
                _inset * 2 +
                _surfaceBorder * 2 +
                widths
                    .take(count)
                    .fold<double>(0, (sum, width) => sum + width) +
                count +
                _moreWidth;
            while (visibleCount > 1 &&
                rowWidth(visibleCount) > availableWidth) {
              visibleCount--;
            }
            final overflow = [...primary.skip(visibleCount), ...secondary];
            final open = _moreOpen && overflow.isNotEmpty;
            final width = math.min(
              availableWidth,
              open
                  ? math.max(
                      rowWidth(visibleCount),
                      overflow
                          .map(
                            (action) =>
                                _measure(action.label, style).width + 64,
                          )
                          .reduce(math.max),
                    )
                  : rowWidth(visibleCount),
            );
            final mainRow = SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < visibleCount; i++) ...[
                            SizedBox(
                              width: widths[i],
                              height: rowHeight,
                              child: _button(primary[i], style),
                            ),
                            _separator(palette),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _moreWidth,
                    height: rowHeight,
                    child: Semantics(
                      expanded: open,
                      child: IconButton(
                        key: const ValueKey('reader-selection-more'),
                        tooltip: open
                            ? material.closeButtonTooltip
                            : material.moreButtonTooltip,
                        onPressed: overflow.isEmpty
                            ? null
                            : () {
                                setState(() => _moreOpen = !_moreOpen);
                              },
                        style: IconButton.styleFrom(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.circular(rowHeight / 2),
                          ),
                          foregroundColor: palette.text,
                          disabledForegroundColor: palette.text.withValues(
                            alpha: 0.38,
                          ),
                        ),
                        icon: AppSkinIcon.adapt(
                          Icon(
                            open
                                ? Icons.expand_less_rounded
                                : Icons.more_horiz_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            return SizedBox(
              width: width,
              child: GlassControlSurface(
                shape: surfaceShape,
                color: palette.controlBar,
                brightness: palette.brightness,
                outlineColor: palette.border,
                shadowColor: palette.shadow,
                role: GlassSurfaceRole.floating,
                emphasized: true,
                child: Material(
                  key: const ValueKey('reader-selection-toolbar'),
                  color: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: surfaceShape,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _inset,
                      vertical: 2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        mainRow,
                        if (open) ...[
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: palette.border,
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final action in overflow)
                                    _button(action, style, expanded: true),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Size _measure(String label, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.localeOf(context),
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }

  Widget _button(
    _SelectionAction action,
    TextStyle style, {
    bool expanded = false,
  }) {
    return TextButton(
      key: ValueKey('reader-selection-${action.id}'),
      onPressed: action.onPressed == null
          ? null
          : () {
              if (_moreOpen) setState(() => _moreOpen = false);
              action.onPressed!();
            },
      style: TextButton.styleFrom(
        foregroundColor: widget.palette.text,
        disabledForegroundColor: widget.palette.text.withValues(alpha: 0.38),
        textStyle: style,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        alignment: expanded
            ? AlignmentDirectional.centerStart
            : Alignment.center,
      ),
      child: expanded
          ? Row(
              children: [
                AppSkinIcon.adapt(
                  Icon(
                    action.icon ??
                        switch (action.id) {
                          'note' => Icons.mode_comment_outlined,
                          'highlight' => Icons.highlight_outlined,
                          _ => Icons.content_copy_rounded,
                        },
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(action.label)),
              ],
            )
          : Text(action.label),
    );
  }

  Widget _separator(ReaderThemePalette palette) => SizedBox(
    width: 1,
    height: 16,
    child: ColoredBox(color: palette.text.withValues(alpha: 0.16)),
  );
}

class _SelectionAction {
  const _SelectionAction(this.id, this.label, this.onPressed, {this.icon});
  final String id;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
}

class _SelectionToolbarLayout extends TextSelectionToolbarLayoutDelegate {
  _SelectionToolbarLayout({
    required super.anchorAbove,
    required super.anchorBelow,
  });

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final position = super.getPositionForChild(size, childSize);
    return Offset(
      position.dx,
      position.dy.clamp(0.0, math.max(0, size.height - childSize.height)),
    );
  }
}
