import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';
import '../utils/reader_themes.dart';

/// The shelf decision shown when leaving a book opened directly from a source.
class ReaderExitShelfDialog extends StatelessWidget {
  const ReaderExitShelfDialog({
    super.key,
    required this.bookTitle,
    required this.palette,
  });

  final String bookTitle;
  final ReaderThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).textTheme;
    final stackActions =
        MediaQuery.sizeOf(context).width < 340 ||
        MediaQuery.textScalerOf(context).scale(14) > 18;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final dismiss = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: palette.secondaryText,
        backgroundColor: palette.controlFill,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: shape,
      ),
      onPressed: () => Navigator.pop(context, false),
      child: Text(context.l10n.bookSourceNotNow, textAlign: TextAlign.center),
    );
    final add = FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: shape,
      ),
      onPressed: () => Navigator.pop(context, true),
      child: Text(
        context.l10n.bookSourceAddToShelf,
        textAlign: TextAlign.center,
      ),
    );

    return AlertDialog(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: const BoxConstraints(minWidth: 0, maxWidth: 360),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: palette.border.withValues(alpha: 0.5)),
      ),
      scrollable: true,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.controlFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bookmark_add_outlined,
              color: palette.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.bookSourceExitAddTitle,
              style: typography.titleLarge?.copyWith(
                color: palette.text,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      content: Text(
        context.l10n.bookSourceExitAddMessage(bookTitle),
        style: typography.bodyMedium?.copyWith(
          color: palette.secondaryText,
          height: 1.6,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        if (stackActions)
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [add, const SizedBox(height: 10), dismiss],
            ),
          )
        else
          Row(
            children: [
              Expanded(child: dismiss),
              const SizedBox(width: 10),
              Expanded(child: add),
            ],
          ),
      ],
    );
  }
}
