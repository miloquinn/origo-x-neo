import 'package:flutter/material.dart';

import '../models/app_skin.dart';
import '../utils/app_skin_theme.dart';

/// Layout-neutral artwork inside an existing surface. It never owns filters,
/// material parameters, hit targets or semantics.
class AppSkinArtwork extends StatelessWidget {
  const AppSkinArtwork({
    super.key,
    required this.slot,
    required this.child,
    required this.shape,
  });

  final AppSkinArtworkSlot slot;
  final Widget child;
  final OutlinedBorder shape;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.highContrast ?? false) return child;
    final asset = AppSkinTheme.of(context).skin.artwork[slot];
    if (asset == null) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: Image.asset(
                asset.pathFor(Theme.of(context).brightness),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  FlutterError.reportError(
                    FlutterErrorDetails(
                      exception: error,
                      stack: stackTrace,
                      library: 'app skin',
                      context: ErrorDescription(
                        'loading skin artwork ${asset.asset}',
                      ),
                    ),
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
