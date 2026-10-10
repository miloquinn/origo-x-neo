import 'package:flutter/material.dart';

/// Bundled provider artwork stays available offline and never contacts a logo CDN.
class AiProviderLogo extends StatelessWidget {
  const AiProviderLogo({super.key, this.asset, this.size = 32});

  final String? asset;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size + 12,
    height: size + 12,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: asset == null
        ? Icon(Icons.hub_outlined, size: size)
        : Image.asset(
            asset!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(Icons.hub_outlined, size: size),
          ),
  );
}
