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

  BoxDecoration _paperDecoration({
    Color color = const Color(0xfffffdf5),
    double radius = 5,
  }) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xffe6e5d9)),
    boxShadow: const [
      BoxShadow(
        color: Color(0x29404935),
        blurRadius: 22,
        offset: Offset(3, 13),
      ),
    ],
  );

  Widget _book(
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
          color: Color(0x5027352f),
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
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xffbcc3ab)),
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
    decoration: _paperDecoration(),
    child: DefaultTextStyle.merge(
      style: const TextStyle(
        color: Color(0xff475347),
        fontSize: 10,
        height: 1.8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ORIGO READING',
            style: TextStyle(
              fontSize: 7,
              letterSpacing: 1.2,
              color: Color(0xff889180),
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
            color: const Color(0xffdce2c9),
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
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '24 / 168',
              style: TextStyle(fontSize: 7, color: Color(0xff8a9183)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _reading(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      _layer(left: 30, top: 26, angle: -12, child: _book(imageAssets[0])),
      _layer(left: 153, top: 9, angle: 8, child: _paper(context)),
      _layer(
        left: 15,
        top: 161,
        angle: -4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: _paperDecoration(radius: 12),
          child: Row(
            children: [
              const Icon(
                PurchaseIcons.textAa,
                size: 27,
                color: Color(0xff475347),
              ),
              const SizedBox(width: 13),
              for (final color in [
                const Color(0xffd7ddc1),
                const Color(0xffd8c29e),
                const Color(0xff294039),
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
        child: _book(imageAssets[1], width: 136, height: 178),
      ),
      _layer(
        left: 232,
        top: 16,
        angle: 7,
        child: Container(
          width: 93,
          padding: const EdgeInsets.all(11),
          decoration: _paperDecoration(
            color: const Color(0xffeceddf),
            radius: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                PurchaseIcons.sparkle,
                size: 19,
                color: Color(0xff475347),
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.basicAiTitle,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Color(0xff475347),
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
          decoration: _paperDecoration(radius: 15),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xff36523f),
                child: Icon(
                  PurchaseIcons.play,
                  size: 15,
                  color: Color(0xfff6f4ed),
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
                            color: const Color(0xff748d6d),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '1.0×',
                style: TextStyle(fontSize: 9, color: Color(0xff6c7c68)),
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
          decoration: _paperDecoration(color: const Color(0xffdce4cf)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                PurchaseIcons.quotes,
                size: 19,
                color: Color(0xff81906f),
              ),
              const SizedBox(height: 9),
              Text(
                context.l10n.basicNotesHeadline,
                style: const TextStyle(
                  color: Color(0xff475347),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              const Icon(
                PurchaseIcons.cloudArrowUp,
                size: 17,
                color: Color(0xff81906f),
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
          color: const Color(0xff354d3d),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xff71866b)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44102019),
              blurRadius: 18,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 23, color: const Color(0xffd5dfc8)),
            const Spacer(),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xffe1e7d5),
                fontSize: 9,
                height: 1.3,
              ),
            ),
          ],
        ),
      );

  Widget _extensions(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: const _Orbits())),
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
            color: const Color(0xff3c5744),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xff92a484)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66102019),
                blurRadius: 24,
                offset: Offset(0, 13),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'O',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: Color(0xffece8d1),
            ),
          ),
        ),
      ),
      _layer(
        left: 44,
        top: 164,
        angle: -7,
        child: _networkCaption(
          PurchaseIcons.graph,
          context.l10n.basicSourcesTitle,
        ),
      ),
      _layer(
        left: 208,
        top: 179,
        angle: 7,
        child: _networkCaption(
          PurchaseIcons.cloudArrowUp,
          context.l10n.settingsPrivateBookSourceNetworkTitle,
        ),
      ),
    ],
  );

  Widget _networkCaption(IconData icon, String label) => Container(
    constraints: const BoxConstraints(maxWidth: 126),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xff435b43),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xff6a7c60)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xffdde6ce)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xffdde6ce)),
          ),
        ),
      ],
    ),
  );
}

class _Orbits extends CustomPainter {
  const _Orbits();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x339aaf85)
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
  bool shouldRepaint(_Orbits oldDelegate) => false;
}
