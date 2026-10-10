import 'package:flutter/material.dart';
import 'app_skin_icon.dart';

import 'pill_input_surface.dart';

/// Shared search chrome. Querying, debouncing and cancellation stay with callers.
class PillSearchField extends StatefulWidget {
  const PillSearchField({
    super.key,
    this.textFieldKey,
    this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.clearButtonKey,
    this.clearTooltip,
    this.showClearButton = true,
    this.trailing,
    this.leadingIcon = Icons.search_rounded,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.search,
    this.fillColor,
    this.foregroundColor,
    this.hintColor,
    this.accentColor,
    this.borderColor,
    this.brightness,
    this.blurBackground = true,
  });

  // Native-field keys preserve editing, focus and existing page test contracts.
  final Key? textFieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// When supplied, the caller owns clearing and its associated side effects.
  /// Otherwise the field clears its controller and calls onChanged once.
  final VoidCallback? onClear;
  final Key? clearButtonKey;
  final String? clearTooltip;
  final bool showClearButton;
  final Widget? trailing;
  final IconData leadingIcon;
  final bool autofocus;
  final bool enabled;
  final TextInputAction textInputAction;
  final Color? fillColor;
  final Color? foregroundColor;
  final Color? hintColor;
  final Color? accentColor;
  final Color? borderColor;
  final Brightness? brightness;
  final bool blurBackground;

  @override
  State<PillSearchField> createState() => _PillSearchFieldState();
}

class _PillSearchFieldState extends State<PillSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _hasText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_editingChanged);
    _focusNode.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(covariant PillSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final value = _controller.value;
      _controller.removeListener(_editingChanged);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController.fromValue(value);
      _hasText = _controller.text.isNotEmpty;
      _controller.addListener(_editingChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_focusChanged);
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_focusChanged);
    }
  }

  void _editingChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) setState(() => _hasText = hasText);
  }

  void _focusChanged() => setState(() {});

  void _clear() {
    if (widget.onClear case final onClear?) {
      onClear();
    } else {
      _controller.clear();
      widget.onChanged?.call('');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_editingChanged);
    _focusNode.removeListener(_focusChanged);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = widget.foregroundColor ?? scheme.onSurface;
    final muted = widget.hintColor ?? scheme.onSurfaceVariant;
    final accent = widget.accentColor ?? scheme.primary;
    final focused = widget.enabled && _focusNode.hasFocus;
    final clearVisible = widget.showClearButton && _hasText;
    return PillInputSurface(
      fillColor: widget.fillColor,
      borderColor: widget.borderColor,
      brightness: widget.brightness,
      enabled: widget.enabled,
      blurBackground: widget.blurBackground,
      focusColor: focused ? accent : null,
      child: TextField(
        key: widget.textFieldKey,
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 15,
          height: 1.4,
          color: foreground.withValues(alpha: widget.enabled ? 1 : .58),
        ),
        cursorColor: accent,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: muted),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          constraints: const BoxConstraints(minHeight: 52),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          prefixIcon: AppSkinIcon.adapt(
            Icon(widget.leadingIcon, size: 20, color: muted),
          ),
          suffixIconConstraints: const BoxConstraints(minHeight: 48),
          suffixIcon: widget.trailing == null && !clearVisible
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.trailing case final trailing?)
                        DefaultTextStyle.merge(
                          style: TextStyle(color: muted),
                          child: IconButtonTheme(
                            data: IconButtonThemeData(
                              style: IconButton.styleFrom(
                                foregroundColor: muted,
                                disabledForegroundColor: muted.withValues(
                                  alpha: .38,
                                ),
                              ),
                            ),
                            child: trailing,
                          ),
                        ),
                      if (clearVisible)
                        IconButton(
                          key: widget.clearButtonKey,
                          tooltip:
                              widget.clearTooltip ??
                              MaterialLocalizations.of(
                                context,
                              ).clearButtonTooltip,
                          onPressed: widget.enabled ? _clear : null,
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(44),
                            maximumSize: const Size.square(44),
                            padding: const EdgeInsets.all(10),
                            foregroundColor: muted,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
