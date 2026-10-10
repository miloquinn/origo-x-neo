import 'package:flutter/material.dart';

import 'elastic_press.dart';
import 'glass_surface.dart';
import '../models/app_skin.dart';
import 'app_skin_artwork.dart';

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
  Widget build(BuildContext context) {
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(height / 2),
    );
    return ElasticPress(
      edgePullOnly: true,
      child: AppSkinArtwork(
        slot: AppSkinArtworkSlot.navigation,
        shape: shape,
        child: GlassSurface(
          role: GlassSurfaceRole.floating,
          shape: shape,
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(padding: const EdgeInsets.all(4), child: child),
          ),
        ),
      ),
    );
  }
}
