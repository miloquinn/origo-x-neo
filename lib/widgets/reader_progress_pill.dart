import 'package:flutter/material.dart';

import '../core/reader/reader_progress_position.dart';
import '../core/reader/reader_settings.dart';
import '../utils/localization_extension.dart';
import '../utils/reader_themes.dart';
import 'app_skin_icon.dart';
import 'glass_surface.dart';

/// A thick, native-accessible seek control with a shared glass bottle shell.
class ReaderProgressPill extends StatefulWidget {
  const ReaderProgressPill({
    super.key,
    required this.palette,
    required this.position,
    required this.scope,
    required this.onSeek,
    this.onSeekStart,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  final ReaderThemePalette palette;
  final ReaderProgressPosition position;
  final ReaderProgressScope scope;
  final ValueChanged<ReaderProgressTarget>? onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  @override
  State<ReaderProgressPill> createState() => _ReaderProgressPillState();
}

class _ReaderProgressPillState extends State<ReaderProgressPill> {
  double? _preview;
  bool _focused = false;

  @override
  void didUpdateWidget(ReaderProgressPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope ||
        oldWidget.position.chapterIndex != widget.position.chapterIndex ||
        oldWidget.position.chapterCount != widget.position.chapterCount ||
        widget.onSeek == null) {
      _preview = null;
    }
  }

  String _scopeLabel(BuildContext context) {
    return widget.scope == ReaderProgressScope.book
        ? context.l10n.readerProgressBookShort
        : context.l10n.readerProgressChapterShort;
  }

  void _commit(double value) {
    final target = widget.position.targetFor(widget.scope, value);
    setState(() => _preview = null);
    if (target != null) widget.onSeek?.call(target);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final theme = Theme.of(context);
    final value = _preview ?? widget.position.valueFor(widget.scope);
    final enabled = widget.position.available && widget.onSeek != null;
    final label = _scopeLabel(context);
    final percent = '${(value * 100).round()}%';
    final duration = MediaQuery.disableAnimationsOf(context) || _preview != null
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return GlassSurface(
      key: const ValueKey('reader-progress-pill-surface'),
      role: GlassSurfaceRole.floating,
      color: palette.controlBar,
      outlineColor: palette.border,
      shadowColor: palette.shadow,
      brightness: palette.brightness,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            _chapterButton(
              key: const ValueKey('reader-progress-previous'),
              icon: Icons.skip_previous_rounded,
              tooltip: context.l10n.tapZonePreviousChapter,
              onPressed: widget.position.hasPreviousChapter
                  ? widget.onPreviousChapter
                  : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Focus(
                canRequestFocus: false,
                onFocusChange: (focused) => setState(() => _focused = focused),
                child: GlassSurface(
                  role: GlassSurfaceRole.control,
                  color: palette.surface,
                  outlineColor: palette.border,
                  brightness: palette.brightness,
                  enabled: enabled,
                  emphasized: _focused,
                  filterBackground: false,
                  child: SizedBox(
                    height: 44,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: value),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      builder: (context, paintedValue, _) => Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  key: const ValueKey('reader-progress-fill'),
                                  widthFactor: paintedValue,
                                  heightFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color.lerp(
                                            palette.accent,
                                            palette.surface,
                                            0.24,
                                          )!,
                                          palette.accent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            child: IgnorePointer(
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: _progressLabel(
                                      '$label · $percent',
                                      paintedValue,
                                      theme,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: SliderTheme(
                              data: theme.sliderTheme.copyWith(
                                trackHeight: 0,
                                activeTrackColor: Colors.transparent,
                                inactiveTrackColor: Colors.transparent,
                                thumbShape: SliderComponentShape.noThumb,
                                overlayShape: SliderComponentShape.noOverlay,
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                key: const ValueKey('reader-progress-slider'),
                                value: value,
                                padding: EdgeInsets.zero,
                                label: '$label · $percent',
                                semanticFormatterCallback: (next) =>
                                    '$label · ${(next * 100).round()}%',
                                onChangeStart: enabled
                                    ? (_) => widget.onSeekStart?.call()
                                    : null,
                                onChanged: enabled
                                    ? (next) => setState(() => _preview = next)
                                    : null,
                                onChangeEnd: enabled ? _commit : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _chapterButton(
              key: const ValueKey('reader-progress-next'),
              icon: Icons.skip_next_rounded,
              tooltip: context.l10n.tapZoneNextChapter,
              onPressed: widget.position.hasNextChapter
                  ? widget.onNextChapter
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressLabel(String label, double progress, ThemeData theme) {
    // A solid reader-themed chip keeps the value legible over either fill.
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: widget.palette.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: widget.palette.text,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Widget _chapterButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) => SizedBox.square(
    dimension: 44,
    child: IconButton(
      key: key,
      onPressed: onPressed,
      tooltip: tooltip,
      color: widget.palette.text,
      disabledColor: widget.palette.secondaryText,
      icon: AppSkinIcon.adapt(Icon(icon, size: 25)),
    ),
  );
}
