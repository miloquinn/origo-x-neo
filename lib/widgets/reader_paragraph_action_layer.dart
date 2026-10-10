import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/reader/reader_text_pagination.dart';
import '../models/app_skin.dart';
import '../utils/reader_themes.dart';
import '../utils/localization_extension.dart';
import 'glass_buttons.dart';
import 'app_skin_icon.dart';
import 'glass_bottom_sheet.dart';
import 'reader_tap_observer.dart';

/// A separate display action. It never becomes a character in reader text.
class ReaderParagraphAction {
  const ReaderParagraphAction({
    required this.id,
    required this.endOffset,
    required this.label,
    required this.onPressed,
    this.excerpt = '',
  });

  final String id;
  final int endOffset;
  final String label;
  final VoidCallback onPressed;
  final String excerpt;
}

/// Shared by paged and continuous readers. The paginator reserves this gutter
/// before measuring text; the layer uses the actual painted glyph positions.
class ReaderParagraphActionLayer extends StatelessWidget {
  const ReaderParagraphActionLayer({
    super.key,
    required this.child,
    required this.textKey,
    required this.page,
    required this.palette,
    required this.actions,
    this.gutterWidth = gutter,
  });

  static const double gutter = 36;
  static const double buttonSize = 32;

  final Widget child;
  final GlobalKey textKey;
  final ReaderTextPage page;
  final ReaderThemePalette palette;
  final List<ReaderParagraphAction> actions;
  final double gutterWidth;

  @override
  Widget build(BuildContext context) {
    if (gutterWidth == 0 || page.isChapterTitle) return child;
    final visible = actions
        .where(
          (action) =>
              action.endOffset > page.startOffset &&
              action.endOffset <= page.endOffset,
        )
        .toList(growable: false);
    final groups = _ParagraphActionGroups();
    return _ParagraphActionsLayout(
      textKey: textKey,
      page: page,
      actions: visible,
      gutterWidth: gutterWidth,
      groups: groups,
      children: [
        child,
        for (final action in visible)
          Builder(
            builder: (context) => GlassIconButton(
              key: ValueKey('reader-paragraph-action:${action.id}'),
              tooltip: action.label,
              dimension: buttonSize,
              iconSize: 17,
              color: palette.controlBar,
              foregroundColor: palette.accent,
              outlineColor: palette.border,
              brightness: palette.brightness,
              icon: const AppSkinIcon(
                slot: AppSkinIconSlot.note,
                fallback: Icon(Icons.chat_bubble_outline_rounded),
              ),
              onPressed: () {
                ReaderTextTapHandledNotification().dispatch(context);
                unawaited(_openAction(context, action, groups));
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openAction(
    BuildContext context,
    ReaderParagraphAction action,
    _ParagraphActionGroups groups,
  ) async {
    final grouped = groups.forAction(action);
    if (grouped.length == 1) {
      action.onPressed();
      return;
    }
    // Purification can merge original paragraphs onto one painted line. Keep
    // every source action accessible through the shared selection panel.
    final selected = await showGlassBottomSheet<ReaderParagraphAction>(
      context: context,
      backgroundColor: palette.surface,
      theme: palette.toThemeData(parentTheme: Theme.of(context)),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              context.l10n.readerParagraphReviews,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (var index = 0; index < grouped.length; index++)
            ListTile(
              key: ValueKey('reader-paragraph-choice:${grouped[index].id}'),
              leading: const AppSkinIcon(
                slot: AppSkinIconSlot.note,
                fallback: Icon(Icons.chat_bubble_outline_rounded),
              ),
              title: Text(
                '${context.l10n.readerParagraphReviews} ${index + 1}',
              ),
              subtitle: grouped[index].excerpt.isEmpty
                  ? null
                  : Text(
                      grouped[index].excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => Navigator.of(context).pop(grouped[index]),
            ),
        ],
      ),
    );
    if (context.mounted) selected?.onPressed();
  }
}

class _ParagraphActionGroups {
  final Map<String, List<ReaderParagraphAction>> values = {};

  List<ReaderParagraphAction> forAction(ReaderParagraphAction action) =>
      values[action.id] ?? [action];
}

class _ParagraphActionsLayout extends MultiChildRenderObjectWidget {
  const _ParagraphActionsLayout({
    required this.textKey,
    required this.page,
    required this.actions,
    required this.gutterWidth,
    required this.groups,
    required super.children,
  });

  final GlobalKey textKey;
  final ReaderTextPage page;
  final List<ReaderParagraphAction> actions;
  final double gutterWidth;
  final _ParagraphActionGroups groups;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ParagraphActionsRenderBox(textKey, page, actions, gutterWidth, groups);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _ParagraphActionsRenderBox renderObject,
  ) => renderObject.update(textKey, page, actions, gutterWidth, groups);
}

class _ParagraphActionParentData extends ContainerBoxParentData<RenderBox> {
  bool hidden = false;
}

class _ParagraphActionsRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParagraphActionParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParagraphActionParentData> {
  _ParagraphActionsRenderBox(
    this._textKey,
    this._page,
    this._actions,
    this._gutter,
    this._groups,
  );

  GlobalKey _textKey;
  ReaderTextPage _page;
  List<ReaderParagraphAction> _actions;
  double _gutter;
  _ParagraphActionGroups _groups;

  void update(
    GlobalKey key,
    ReaderTextPage page,
    List<ReaderParagraphAction> actions,
    double gutter,
    _ParagraphActionGroups groups,
  ) {
    _textKey = key;
    _page = page;
    _actions = actions;
    _gutter = gutter;
    _groups = groups;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ParagraphActionParentData) {
      child.parentData = _ParagraphActionParentData();
    }
  }

  BoxConstraints _bodyConstraints(BoxConstraints constraints) => BoxConstraints(
    minWidth: (constraints.maxWidth - _gutter).clamp(1, double.infinity),
    maxWidth: (constraints.maxWidth - _gutter).clamp(1, double.infinity),
    minHeight: constraints.minHeight,
    maxHeight: constraints.maxHeight,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final body = firstChild;
    if (body == null) return constraints.smallest;
    final bodySize = body.getDryLayout(_bodyConstraints(constraints));
    return constraints.constrain(
      Size(bodySize.width + _gutter, bodySize.height),
    );
  }

  @override
  void performLayout() {
    final body = firstChild;
    if (body == null) {
      size = constraints.smallest;
      return;
    }
    body.layout(_bodyConstraints(constraints), parentUsesSize: true);
    size = constraints.constrain(
      Size(body.size.width + _gutter, body.size.height),
    );
    (body.parentData! as ContainerBoxParentData<RenderBox>).offset =
        Offset.zero;
    final paragraph = _textKey.currentContext?.findRenderObject();
    final origin = paragraph is RenderParagraph
        ? paragraph.localToGlobal(Offset.zero, ancestor: this)
        : Offset.zero;
    var button = childAfter(body);
    var index = 0;
    final positions =
        <({RenderBox button, double top, ReaderParagraphAction action})>[];
    _groups.values.clear();
    while (button != null) {
      button.layout(
        const BoxConstraints.tightFor(
          width: ReaderParagraphActionLayer.buttonSize,
          height: ReaderParagraphActionLayer.buttonSize,
        ),
        parentUsesSize: true,
      );
      var top = 0.0;
      if (paragraph is RenderParagraph && index < _actions.length) {
        final offset = _page.textOffsetForSourceOffset(
          _actions[index].endOffset - 1,
        );
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: offset, extentOffset: offset + 1),
        );
        if (boxes.isNotEmpty) {
          top =
              origin.dy +
              boxes.last.toRect().center.dy -
              button.size.height / 2;
        }
      }
      final data = button.parentData! as _ParagraphActionParentData;
      data.hidden = false;
      data.offset = Offset(
        body.size.width + (_gutter - button.size.width) / 2,
        top.clamp(
          0,
          (size.height - button.size.height).clamp(0, double.infinity),
        ),
      );
      if (index < _actions.length) {
        positions.add((
          button: button,
          top: data.offset.dy,
          action: _actions[index],
        ));
      }
      index++;
      button = childAfter(button);
    }
    positions.sort((a, b) => a.top.compareTo(b.top));
    double? groupTop;
    List<ReaderParagraphAction>? group;
    for (final position in positions) {
      if (groupTop == null ||
          position.top - groupTop >= ReaderParagraphActionLayer.buttonSize) {
        groupTop = position.top;
        group = <ReaderParagraphAction>[];
      } else {
        (position.button.parentData! as _ParagraphActionParentData).hidden =
            true;
      }
      group!.add(position.action);
      _groups.values[position.action.id] = group;
    }
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _ParagraphActionParentData;
      if (!data.hidden) context.paintChild(child, offset + data.offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final target = child;
      final data = target.parentData! as _ParagraphActionParentData;
      if (!data.hidden &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (result, position) =>
                target.hitTest(result, position: position),
          )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    var child = firstChild;
    while (child != null) {
      if (!(child.parentData! as _ParagraphActionParentData).hidden) {
        visitor(child);
      }
      child = childAfter(child);
    }
  }
}
