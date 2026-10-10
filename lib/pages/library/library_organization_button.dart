import 'dart:async';

import 'package:flutter/material.dart';

import '../../utils/localization_extension.dart';
import '../../widgets/glass_buttons.dart';

class LibraryOrganizationButton extends StatelessWidget {
  const LibraryOrganizationButton({
    super.key,
    required this.active,
    required this.reordering,
    required this.onOrganize,
    required this.onDone,
  });

  final bool active;
  final bool reordering;
  final Future<void> Function() onOrganize;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => GlassToolbarButton(
    key: const ValueKey('library-organize-button'),
    icon: reordering ? Icons.check_rounded : Icons.sort_rounded,
    tooltip: reordering
        ? context.l10n.settingsDone
        : context.l10n.libraryOrganize,
    highlighted: active || reordering,
    blurBackground: false,
    onPressed: reordering ? onDone : () => unawaited(onOrganize()),
  );
}
