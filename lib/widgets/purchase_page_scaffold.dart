import 'package:flutter/material.dart';

import 'floating_subpage_scaffold.dart';
import 'glass_surface.dart';

/// Purchase-specific button sizing; colors and brightness belong to the app.
class PurchasePageTheme extends StatelessWidget {
  const PurchasePageTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: (base.filledButtonTheme.style ?? const ButtonStyle()).merge(
            FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Keeps the decision and its action together, with a scrolling fallback when
/// the keyboard, a short window or large text needs more space.
class PurchasePageScaffold extends StatelessWidget {
  const PurchasePageScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.footer,
    this.pinFooter = true,
    this.actions = const [],
  });

  final String title;
  final Widget body;
  final Widget footer;
  final bool pinFooter;
  final List<Widget> actions;

  Widget _bounded(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) => FloatingSubpageScaffold(
    title: title,
    actions: actions,
    body: Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final top = FloatingSubpageScaffold.headerExtentOf(context) + 8;
          final bottom = MediaQuery.viewPaddingOf(context).bottom + 8;
          final needsScrolling =
              constraints.maxHeight < 620 ||
              MediaQuery.textScalerOf(context).scale(14) > 14 * 1.35 ||
              MediaQuery.viewInsetsOf(context).bottom > 0;
          if (needsScrolling || !pinFooter) {
            return SingleChildScrollView(
              key: const ValueKey('purchase-adaptive-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, top, 24, bottom),
              child: _bounded(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [body, const SizedBox(height: 8), footer],
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
              GlassSurface(
                role: GlassSurfaceRole.floating,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  key: const ValueKey('purchase-fixed-footer'),
                  padding: EdgeInsets.fromLTRB(24, 8, 24, bottom),
                  child: _bounded(footer),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Equal-width secondary actions share one baseline and keep full tap targets.
class PurchaseActionRow extends StatelessWidget {
  const PurchaseActionRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => TextButtonTheme(
    data: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      ),
    ),
    child: Row(
      children: [for (final child in children) Expanded(child: child)],
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
    body: Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: floatingSubpagePadding(
          context,
          left: 24,
          right: 24,
          bottom: 32,
        ),
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
    ),
  );
}
