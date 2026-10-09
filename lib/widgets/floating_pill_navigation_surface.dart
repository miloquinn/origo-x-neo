import 'package:flutter/material.dart';

import 'elastic_press.dart';
import 'glass_surface.dart';

/// Visual surface shared by home navigation and page-level floating tabs.
class FloatingPillNavigationSurface extends StatelessWidget {
  const FloatingPillNavigationSurface({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => ElasticPress(
    edgePullOnly: true,
    child: GlassSurface(
      role: GlassSurfaceRole.floating,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(padding: const EdgeInsets.all(4), child: child),
      ),
    ),
  );
}
