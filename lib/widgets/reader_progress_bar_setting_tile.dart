import 'package:flutter/material.dart';

import '../core/reader/reader_settings.dart';
import '../utils/localization_extension.dart';

class ReaderProgressBarSettingTile extends StatelessWidget {
  const ReaderProgressBarSettingTile({
    super.key,
    required this.enabled,
    required this.scope,
    required this.onEnabledChanged,
    required this.onScopeChanged,
  });

  final bool enabled;
  final ReaderProgressScope scope;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<ReaderProgressScope> onScopeChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final useVerticalScopePicker =
          constraints.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.8;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('reader-progress-bar-switch'),
            contentPadding: EdgeInsets.zero,
            secondary: useVerticalScopePicker
                ? null
                : const Icon(Icons.linear_scale_rounded),
            title: Text(context.l10n.readerProgressBarTitle),
            subtitle: Text(context.l10n.readerProgressBarHint),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          if (enabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: KeyedSubtree(
                key: const ValueKey('reader-progress-bar-scope'),
                child: useVerticalScopePicker
                    ? RadioGroup<ReaderProgressScope>(
                        groupValue: scope,
                        onChanged: (value) {
                          if (value != null) onScopeChanged(value);
                        },
                        child: Column(
                          children: [
                            RadioListTile<ReaderProgressScope>(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: ReaderProgressScope.book,
                              title: Text(context.l10n.readerProgressBook),
                            ),
                            RadioListTile<ReaderProgressScope>(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: ReaderProgressScope.chapter,
                              title: Text(context.l10n.readerProgressChapter),
                            ),
                          ],
                        ),
                      )
                    : SegmentedButton<ReaderProgressScope>(
                        showSelectedIcon: false,
                        expandedInsets: EdgeInsets.zero,
                        segments: [
                          ButtonSegment(
                            value: ReaderProgressScope.book,
                            label: Text(context.l10n.readerProgressBook),
                          ),
                          ButtonSegment(
                            value: ReaderProgressScope.chapter,
                            label: Text(context.l10n.readerProgressChapter),
                          ),
                        ],
                        selected: {scope},
                        onSelectionChanged: (selection) {
                          if (selection.isNotEmpty) {
                            onScopeChanged(selection.first);
                          }
                        },
                      ),
              ),
            ),
        ],
      );
    },
  );
}
