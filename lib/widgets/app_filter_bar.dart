import 'package:flutter/material.dart';

import 'app_selection_pill.dart';
import 'glass_control_surface.dart';
import 'glass_surface.dart';

/// One option in a horizontally scrollable, single-selection filter bar.
class AppFilterOption<T> {
  const AppFilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Key? key;
}

/// Shared filter rail. The rail samples glass once; selection only adds tint.
/// Height follows text size, and off-screen selections reveal horizontally.
class AppFilterBar<T> extends StatefulWidget {
  const AppFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final List<AppFilterOption<T>> options;
  final T selected;
  final ValueChanged<T>? onSelected;
  final Widget? trailing;

  @override
  State<AppFilterBar<T>> createState() => _AppFilterBarState<T>();
}

class _AppFilterBarState<T> extends State<AppFilterBar<T>> {
  final _controller = ScrollController();
  final _viewportKey = GlobalKey();
  final _optionKeys = <T, GlobalKey>{};
  bool _revealScheduled = false;
  bool _needsReveal = true;
  double? _viewportWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _needsReveal = true;
  }

  @override
  void didUpdateWidget(covariant AppFilterBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.options.length != widget.options.length) {
      _needsReveal = true;
    } else {
      for (var i = 0; i < widget.options.length; i++) {
        if (oldWidget.options[i].value != widget.options[i].value ||
            oldWidget.options[i].label != widget.options[i].label ||
            oldWidget.options[i].icon != widget.options[i].icon) {
          _needsReveal = true;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scheduleReveal() {
    if (_revealScheduled) return;
    _revealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealScheduled = false;
      if (!mounted || !_controller.hasClients) return;
      final target = _optionKeys[widget.selected]?.currentContext
          ?.findRenderObject();
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (target is! RenderBox || viewport is! RenderBox) return;
      final left = target.localToGlobal(Offset.zero, ancestor: viewport).dx;
      if (left >= 0 && left + target.size.width <= viewport.size.width) return;
      _controller.position.ensureVisible(
        target,
        alignment: .5,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppSelectionPill.selectionDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = GlassControlSurface.usesGlass(context);
    final values = widget.options.map((option) => option.value).toSet();
    _optionKeys.removeWhere((value, _) => !values.contains(value));
    assert(
      values.length == widget.options.length,
      'Filter values must be unique',
    );

    return GlassSurface(
      color: scheme.surfaceContainerLow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (_viewportWidth != constraints.maxWidth) {
            _viewportWidth = constraints.maxWidth;
            _needsReveal = true;
          }
          if (_needsReveal) {
            _needsReveal = false;
            _scheduleReveal();
          }
          return SingleChildScrollView(
            key: _viewportKey,
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (var index = 0; index < widget.options.length; index++) ...[
                  if (index != 0) const SizedBox(width: 2),
                  _buildOption(context, widget.options[index], glass),
                ],
                if (widget.trailing case final trailing?) ...[
                  if (widget.options.isNotEmpty) const SizedBox(width: 6),
                  trailing,
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    AppFilterOption<T> option,
    bool glass,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final selected = option.value == widget.selected;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppSelectionPill.selectionDuration;
    final pill = AppSelectionPill(
      key: option.key,
      label: option.label,
      icon: option.icon,
      selected: selected,
      onPressed: widget.onSelected == null
          ? null
          : () => widget.onSelected!(option.value),
      enableSurface: false,
      maxLabelWidth: null,
      foregroundColor: scheme.onSurfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    );
    return KeyedSubtree(
      key: _optionKeys.putIfAbsent(option.value, GlobalKey.new),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: GlassSurface(
                role: GlassSurfaceRole.selection,
                color: glass ? scheme.primaryContainer : scheme.primary,
                emphasized: true,
                filterBackground: false,
                enabled: widget.onSelected != null,
                duration: duration,
                curve: Curves.easeOutCubic,
                visibility: selected ? 1 : 0,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          pill,
        ],
      ),
    );
  }
}
