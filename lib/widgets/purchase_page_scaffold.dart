import 'package:flutter/material.dart';

import 'floating_subpage_scaffold.dart';

/// Keeps the decision and its action together, with a scrolling fallback when
/// the keyboard, a short window or large text needs more space.
class PurchasePageScaffold extends StatelessWidget {
  const PurchasePageScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
  });

  final String title;
  final Widget body;
  final Widget footer;

  Widget _bounded(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) => FloatingSubpageScaffold(
    title: title,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final top = FloatingSubpageScaffold.headerExtentOf(context) + 16;
        final bottom = MediaQuery.viewPaddingOf(context).bottom + 12;
        final needsScrolling =
            constraints.maxHeight < 620 ||
            MediaQuery.textScalerOf(context).scale(14) > 14 * 1.35 ||
            MediaQuery.viewInsetsOf(context).bottom > 0;
        if (needsScrolling) {
          return SingleChildScrollView(
            key: const ValueKey('purchase-adaptive-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
            child: _bounded(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [body, const SizedBox(height: 24), footer],
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('purchase-summary-scroll'),
                padding: EdgeInsets.fromLTRB(24, top, 24, 20),
                child: _bounded(body),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
              ),
              child: Padding(
                key: const ValueKey('purchase-fixed-footer'),
                padding: EdgeInsets.fromLTRB(24, 18, 24, bottom),
                child: _bounded(footer),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class PurchaseDetailsPage extends StatelessWidget {
  const PurchaseDetailsPage({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => FloatingSubpageScaffold(
    title: title,
    body: SingleChildScrollView(
      padding: floatingSubpagePadding(context, left: 24, right: 24, bottom: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}
