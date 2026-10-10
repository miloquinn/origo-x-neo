import 'package:flutter/material.dart';

import 'app_menu.dart';
import 'pill_input_surface.dart';

/// A field-like dropdown that uses the app's shared anchored menu instead of
/// the platform Material popup. [DropdownMenuItem] remains the data adapter so
/// existing selector rendering and enabled states can be reused unchanged.
class PillDropdown<T> extends StatefulWidget {
  const PillDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.selectedItemBuilder,
    this.semanticLabel,
    this.focusNode,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final DropdownButtonBuilder? selectedItemBuilder;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<PillDropdown<T>> createState() => _PillDropdownState<T>();
}

class _PillDropdownState<T> extends State<PillDropdown<T>> {
  final _anchorKey = GlobalKey();
  FocusNode? _ownedFocusNode;
  bool _open = false;
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  bool get _enabled => widget.onChanged != null && widget.items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PillDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(
      _handleFocusChanged,
    );
    _ownedFocusNode?.dispose();
    _ownedFocusNode = null;
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted && _focused != _focusNode.hasFocus) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  Future<void> _show() async {
    if (!_enabled || _open) return;
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    setState(() => _open = true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final result = await showAppMenu<T>(
        context: context,
        anchor: anchor,
        initialValue: widget.value,
        presentation: AppMenuPresentation.adaptivePanel,
        constraints: BoxConstraints.tightFor(width: anchor.width),
        anchorRadius: 22,
        items: [
          for (final item in widget.items)
            PopupMenuItem<T>(
              key: item.key,
              value: item.value,
              enabled: item.enabled,
              onTap: item.onTap,
              child: item.child,
            ),
        ],
      );
      if (!mounted) return;
      if (result != null) widget.onChanged?.call(result);
    } finally {
      if (mounted) {
        setState(() => _open = false);
        if (_enabled) _focusNode.requestFocus();
      }
    }
  }

  Widget _selectedChild(BuildContext context) {
    final selectedIndex = widget.value == null
        ? -1
        : widget.items.indexWhere((item) => item.value == widget.value);
    if (selectedIndex < 0) return const SizedBox.shrink();
    final selectedItems = widget.selectedItemBuilder?.call(context);
    if (selectedItems != null && selectedIndex < selectedItems.length) {
      return selectedItems[selectedIndex];
    }
    return widget.items[selectedIndex].child;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final trigger = PillInputSurface(
      key: _anchorKey,
      enabled: _enabled,
      focusColor: _focused ? scheme.primary : null,
      child: InkWell(
        focusNode: _focusNode,
        canRequestFocus: _enabled,
        excludeFromSemantics: true,
        onTap: _enabled ? _show : null,
        customBorder: PillInputSurface.shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 14, 4),
            child: Row(
              children: [
                Expanded(child: _selectedChild(context)),
                const SizedBox(width: 8),
                ExcludeSemantics(
                  child: AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        enabled: _enabled,
        expanded: _open,
        label: widget.semanticLabel,
        onTap: _enabled ? _show : null,
        child: trigger,
      ),
    );
  }
}
