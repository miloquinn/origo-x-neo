import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'glass_buttons.dart';
import 'glass_control_surface.dart';

/// Discrete adjustment with shared glass, native slider input and step buttons.
/// Dragging previews through onChanged; a button previews and commits once.
class GlassAdjustmentSlider extends StatelessWidget {
  const GlassAdjustmentSlider({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.onChangeEnd,
    this.sliderKey,
    this.valueFormatter,
    this.preview,
    this.footer,
  }) : assert(max > min),
       assert(divisions > 0);

  final String label;
  final double value;
  final String valueLabel;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Key? sliderKey;
  final String Function(double)? valueFormatter;
  final Widget? preview;
  final Widget? footer;

  double get _step => (max - min) / divisions;
  double get _boundedValue => value.clamp(min, max);

  void _adjust(int direction) {
    // Remove floating-point drift without snapping saved values to a tick.
    final next = double.parse(
      (_boundedValue + direction * _step).clamp(min, max).toStringAsFixed(10),
    );
    if (next == _boundedValue) return;
    onChanged?.call(next);
    onChangeEnd?.call(next);
  }

  String _formatValue(double next) {
    if (valueFormatter != null) return valueFormatter!(next);
    if (next == _boundedValue) return valueLabel;
    var scale = 1.0;
    for (var digits = 0; digits < 7; digits++, scale *= 10) {
      if ((_step * scale - (_step * scale).round()).abs() < 0.000001 &&
          (min * scale - (min * scale).round()).abs() < 0.000001) {
        return next.toStringAsFixed(digits);
      }
    }
    return next.toStringAsFixed(6);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final enabled = onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: GlassControlSurface(
                role: GlassSurfaceRole.selection,
                color: colors.primaryContainer,
                emphasized: true,
                enabled: enabled,
                blurBackground: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: Text(
                    valueLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (preview != null) ...[const SizedBox(height: 8), preview!],
        const SizedBox(height: 8),
        Row(
          children: [
            GlassIconButton(
              key: const ValueKey('glass-adjustment-decrease'),
              icon: const Icon(Icons.remove_rounded),
              dimension: 48,
              iconSize: 22,
              tooltip: l10n?.adjustmentDecrease(label) ?? '$label −',
              color: colors.surfaceContainerHigh,
              foregroundColor: colors.primary,
              onPressed: enabled && _boundedValue > min
                  ? () => _adjust(-1)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassControlSurface(
                color: colors.surfaceContainerHigh,
                enabled: enabled,
                child: SizedBox(
                  height: 48,
                  child: SliderTheme(
                    data: theme.sliderTheme.copyWith(
                      trackHeight: 4,
                      activeTrackColor: colors.primary,
                      inactiveTrackColor: colors.outlineVariant,
                      thumbColor: colors.primary,
                      overlayColor: colors.primary.withValues(alpha: 0.12),
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 12,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 22,
                      ),
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      key: sliderKey,
                      label: label,
                      value: _boundedValue,
                      min: min,
                      max: max,
                      divisions: divisions,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      semanticFormatterCallback: _formatValue,
                      onChanged: onChanged,
                      onChangeEnd: onChangeEnd,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              key: const ValueKey('glass-adjustment-increase'),
              icon: const Icon(Icons.add_rounded),
              dimension: 48,
              iconSize: 22,
              tooltip: l10n?.adjustmentIncrease(label) ?? '$label +',
              color: colors.surfaceContainerHigh,
              foregroundColor: colors.primary,
              onPressed: enabled && _boundedValue < max
                  ? () => _adjust(1)
                  : null,
            ),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 8), footer!],
      ],
    );
  }
}
