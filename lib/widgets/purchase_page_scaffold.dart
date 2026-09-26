import 'package:flutter/material.dart';

import 'floating_subpage_scaffold.dart';

/// A local art direction for the purchase flow; app-wide theme settings stay intact.
class PurchasePageTheme extends StatelessWidget {
  const PurchasePageTheme({
    super.key,
    this.premium = false,
    required this.child,
  });
  final bool premium;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = premium || base.brightness == Brightness.dark;
    final surface = dark ? const Color(0xff1d3029) : const Color(0xfff6f4ed);
    final ink = dark ? const Color(0xffe9e5d3) : const Color(0xff24392f);
    final muted = dark ? const Color(0xffb0bba7) : const Color(0xff657060);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xff2d493b),
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: muted,
          primary: dark ? const Color(0xffdfd4b2) : const Color(0xff2d493b),
          onPrimary: dark ? const Color(0xff263b2d) : const Color(0xfff6f4e8),
          outlineVariant: dark
              ? const Color(0xff405044)
              : const Color(0xffdedfd4),
        );
    return Theme(
      data: base.copyWith(
        brightness: scheme.brightness,
        colorScheme: scheme,
        scaffoldBackgroundColor: surface,
        textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
        iconTheme: base.iconTheme.copyWith(color: ink),
        dividerColor: scheme.outlineVariant,
        listTileTheme: base.listTileTheme.copyWith(
          textColor: ink,
          iconColor: ink,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
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
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    body: Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final top = FloatingSubpageScaffold.headerExtentOf(context) + 10;
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
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
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
