import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/localization_extension.dart';
import 'purchase_icons.dart';

enum PurchaseArtworkScene { reading, listening, notes, extensions }

/// Decorative, local-only compositions. Functional copy lives outside the art,
/// where it participates in accessibility scaling and screen-reader navigation.
class PurchaseArtwork extends StatelessWidget {
  const PurchaseArtwork({super.key, required this.scene, this.height = 220});

  final PurchaseArtworkScene scene;
  final double height;
  static const imageAssets = [
    'assets/purchase/wave.jpg',
    'assets/purchase/irises.jpg',
  ];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 342,
              height: 220,
              child: switch (scene) {
                PurchaseArtworkScene.reading => _reading(context),
                PurchaseArtworkScene.listening => _listening(context),
                PurchaseArtworkScene.notes => _notes(context),
                PurchaseArtworkScene.extensions => _extensions(context),
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _layer({
    required double left,
    required double top,
    required Widget child,
    double angle = 0,
  }) => Positioned(
    left: left,
    top: top,
    child: Transform.rotate(angle: angle * math.pi / 180, child: child),
  );

  BoxDecoration _paperDecoration(
    BuildContext context, {
    Color? color,
    double radius = 5,
  }) => BoxDecoration(
    color: color ?? Theme.of(context).colorScheme.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    boxShadow: const [
      BoxShadow(
        color: Color(0x29000000),
        blurRadius: 22,
        offset: Offset(3, 13),
      ),
    ],
  );

  Widget _book(
    BuildContext context,
    String image, {
    double width = 122,
    double height = 169,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x50000000),
          blurRadius: 17,
          offset: Offset(9, 13),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            cacheWidth: 420,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x99203939),
                  Color(0x001b3434),
                  Color(0x001b3434),
                ],
                stops: [0, .1, 1],
              ),
            ),
          ),
          const Positioned(
            top: 13,
            left: 15,
            child: Text(
              'ORIGO',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xff193f45),
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Positioned(
            bottom: 12,
            left: 15,
            child: Text(
              'READING COLLECTION',
              style: TextStyle(
                fontSize: 6,
                color: Color(0xfff6f4ed),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _paper(BuildContext context, {double width = 158}) => Container(
    width: width,
    height: 192,
    padding: const EdgeInsets.all(17),
    decoration: _paperDecoration(context),
    child: DefaultTextStyle.merge(
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 10,
        height: 1.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORIGO READING',
            style: TextStyle(
              fontSize: 7,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            context.l10n.basicEditorialTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 9),
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              context.l10n.basicEditorialSubtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              context.l10n.basicAppearanceBody,
              overflow: TextOverflow.fade,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '24 / 168',
              style: TextStyle(
                fontSize: 7,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reading(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _layer(
        left: 30,
        top: 26,
        angle: -12,
        child: _book(context, imageAssets[0]),
      ),
      _layer(left: 153, top: 9, angle: 8, child: _paper(context)),
      _layer(
        left: 15,
        top: 161,
        angle: -4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: _paperDecoration(context, radius: 12),
          child: Row(
            children: [
              Icon(
                PurchaseIcons.textAa,
                size: 27,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 13),
              for (final color in [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
                Theme.of(context).colorScheme.primary,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _listening(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _layer(
        left: 100,
        top: 13,
        angle: -7,
        child: _book(context, imageAssets[1], width: 136, height: 178),
      ),
      _layer(
        left: 232,
        top: 16,
        angle: 7,
        child: Container(
          width: 93,
          padding: const EdgeInsets.all(11),
          decoration: _paperDecoration(
            context,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            radius: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                PurchaseIcons.sparkle,
                size: 19,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.basicAiTitle,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
      _layer(
        left: 18,
        top: 163,
        child: Container(
          width: 306,
          padding: const EdgeInsets.all(13),
          decoration: _paperDecoration(context, radius: 15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  PurchaseIcons.play,
                  size: 15,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 27,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final h in [
                        7,
                        12,
                        18,
                        24,
                        16,
                        10,
                        19,
                        26,
                        16,
                        9,
                        13,
                        22,
                        27,
                        18,
                        11,
                        6,
                        17,
                        24,
                        14,
                        9,
                        18,
                        22,
                        12,
                        6,
                      ])
                        Container(
                          width: 3,
                          height: h.toDouble(),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '1.0×',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _notes(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _layer(left: 40, top: 10, angle: -7, child: _paper(context, width: 199)),
      _layer(
        left: 174,
        top: 98,
        angle: 8,
        child: Container(
          width: 155,
          padding: const EdgeInsets.all(16),
          decoration: _paperDecoration(
            context,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PurchaseIcons.quotes,
                size: 19,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 9),
              Text(
                context.l10n.basicNotesHeadline,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                PurchaseIcons.cloudArrowUp,
                size: 17,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _protocol(BuildContext context, IconData icon, String label) =>
      Container(
        width: 79,
        height: 83,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 18,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 23, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ],
        ),
      );

  Widget _extensions(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(
          painter: _Orbits(
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
          ),
        ),
      ),
      _layer(
        left: 14,
        top: 23,
        angle: -9,
        child: _protocol(context, PurchaseIcons.bookOpenText, 'ORSP'),
      ),
      _layer(
        left: 251,
        top: 40,
        angle: 10,
        child: _protocol(
          context,
          PurchaseIcons.stack,
          context.l10n.settingsAdditionalSourceProtocolsTitle,
        ),
      ),
      _layer(
        left: 127,
        top: 83,
        angle: -9,
        child: Container(
          width: 83,
          height: 83,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 24,
                offset: Offset(0, 13),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'O',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
      _layer(
        left: 44,
        top: 164,
        angle: -7,
        child: _networkCaption(
          context,
          PurchaseIcons.graph,
          context.l10n.basicSourcesTitle,
        ),
      ),
      _layer(
        left: 208,
        top: 179,
        angle: 7,
        child: _networkCaption(
          context,
          PurchaseIcons.cloudArrowUp,
          context.l10n.settingsPrivateBookSourceNetworkTitle,
        ),
      ),
    ],
  );

  Widget _networkCaption(BuildContext context, IconData icon, String label) =>
      Container(
        constraints: const BoxConstraints(maxWidth: 126),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Orbits extends CustomPainter {
  const _Orbits(this.color);

  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 274, height: 170),
      paint,
    );
    canvas.rotate(.8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 270, height: 147),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Orbits oldDelegate) => oldDelegate.color != color;
}
