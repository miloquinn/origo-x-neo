import 'package:flutter/material.dart';

import 'glass_surface.dart';

/// A bounded dialog shell whose material is resolved by the shared glass layer.
///
/// Callers own dialog content and actions; this widget owns only dialog geometry
/// and layout so blur never expands to the full route viewport.
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 560,
  });

  final Widget? title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    shape: _shape,
    child: Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: GlassSurface(
        role: GlassSurfaceRole.panel,
        shape: _shape,
        child: IntrinsicWidth(
          stepWidth: 56,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 280, maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (title != null) ...[
                            DefaultTextStyle(
                              style: Theme.of(context).textTheme.headlineSmall!,
                              child: Semantics(
                                namesRoute: true,
                                header: true,
                                child: title!,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodyMedium!,
                            child: content,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
