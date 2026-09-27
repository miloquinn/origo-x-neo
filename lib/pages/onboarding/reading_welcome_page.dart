import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xxread/widgets/app_brand_icon.dart';
import 'package:xxread/utils/localization_extension.dart';

/// A continuous welcome journey using the host app theme. Completion hands control back to the host;
/// this page neither accepts agreements nor writes onboarding preferences.
class ReadingWelcomePage extends StatefulWidget {
  const ReadingWelcomePage({
    super.key,
    required this.onComplete,
    this.initialPage = 0,
    this.finalContent,
    this.completionLabel,
    this.isCompleting = false,
    this.onDeclined,
  }) : assert(
         initialPage >= 0 && initialPage <= (finalContent == null ? 2 : 3),
       );

  final VoidCallback onComplete;
  final int initialPage;
  final Widget? finalContent;
  final String? completionLabel;
  final bool isCompleting;
  final VoidCallback? onDeclined;

  @override
  State<ReadingWelcomePage> createState() => _ReadingWelcomePageState();
}

class _ReadingWelcomePageState extends State<ReadingWelcomePage> {
  late final PageController _controller;
  late int _page;

  ColorScheme get _colors => Theme.of(context).colorScheme;

  int get _lastPage => widget.finalContent == null ? 2 : 3;
  bool get _isAgreementPage =>
      widget.finalContent != null && _page == _lastPage;

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (widget.isCompleting || page < 0 || page > _lastPage) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
    } else {
      _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 850),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _next() => _page == _lastPage ? widget.onComplete() : _goTo(_page + 1);

  Widget _nextButton() => FilledButton(
    key: const Key('welcomeNext'),
    onPressed: widget.isCompleting ? null : _next,
    style: FilledButton.styleFrom(
      backgroundColor: _colors.primary,
      foregroundColor: _colors.onPrimary,
      minimumSize: const Size(114, 54),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    child: widget.isCompleting
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _colors.onSurfaceVariant,
            ),
          )
        : Text(
            _page == _lastPage
                ? widget.completionLabel ?? context.l10n.welcomeStartReading
                : context.l10n.agreementFlowNext,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final colors = _colors;
    final type = Theme.of(context).textTheme;
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (colors.brightness == Brightness.dark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
      child: Scaffold(
        backgroundColor: colors.surface,
        body: CallbackShortcuts(
          bindings: {
            // Navigation keys must never imply agreement.
            const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                _goTo(_page + 1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                _goTo(_page - 1),
          },
          child: Focus(
            autofocus: true,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 16, 16, 0),
                        child: Row(
                          children: [
                            const AppBrandIcon(size: 32, borderRadius: 8),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Origo X',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type.titleMedium?.copyWith(
                                  fontSize: 18,
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            if (_isAgreementPage)
                              const SizedBox(width: 80, height: 48)
                            else
                              Flexible(
                                child: TextButton(
                                  key: const Key('welcomeSkip'),
                                  onPressed: widget.finalContent == null
                                      ? widget.onComplete
                                      : () => _goTo(_lastPage),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.onSurfaceVariant,
                                  ),
                                  child: Text(
                                    l10n.welcomeSkipIntroduction,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale =
                                MediaQuery.textScalerOf(context).scale(16) / 16;
                            final artHeight = math.max(
                              120.0,
                              constraints.maxHeight - 200 * textScale,
                            );
                            return Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: artHeight,
                                  child: ExcludeSemantics(
                                    child: RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, _) => CustomPaint(
                                          painter: _BookJourneyPainter(
                                            colors: colors,
                                            progress: reduced
                                                ? _page.toDouble()
                                                : _controller.hasClients
                                                ? (_controller.page ??
                                                      _page.toDouble())
                                                : _page.toDouble(),
                                            fontFamily: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.fontFamily,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ScrollConfiguration(
                                  behavior: const _WelcomeScrollBehavior(),
                                  child: PageView(
                                    key: const Key('welcomePager'),
                                    controller: _controller,
                                    onPageChanged: (page) =>
                                        setState(() => _page = page),
                                    children: [
                                      for (final (index, title, body) in [
                                        (
                                          0,
                                          l10n.welcomeChapterOneTitle,
                                          l10n.welcomeChapterOneBody,
                                        ),
                                        (
                                          1,
                                          l10n.welcomeChapterTwoTitle,
                                          l10n.welcomeChapterTwoBody,
                                        ),
                                        (
                                          2,
                                          l10n.welcomeChapterThreeTitle,
                                          l10n.welcomeChapterThreeBody,
                                        ),
                                      ])
                                        ExcludeSemantics(
                                          excluding: _page != index,
                                          child: SingleChildScrollView(
                                            padding: EdgeInsets.fromLTRB(
                                              32,
                                              artHeight,
                                              32,
                                              12,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: type.headlineLarge
                                                      ?.copyWith(
                                                        fontSize:
                                                            constraints
                                                                    .maxWidth <
                                                                360
                                                            ? 30
                                                            : 34,
                                                        height: 1.25,
                                                        letterSpacing: 0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colors.onSurface,
                                                      ),
                                                ),
                                                const SizedBox(height: 17),
                                                Text(
                                                  body,
                                                  style: type.bodyLarge
                                                      ?.copyWith(
                                                        fontSize: 15,
                                                        height: 1.65,
                                                        color: colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (widget.finalContent != null)
                                        ExcludeSemantics(
                                          excluding: !_isAgreementPage,
                                          child: SingleChildScrollView(
                                            key: const Key('welcomeAgreements'),
                                            padding: const EdgeInsets.fromLTRB(
                                              28,
                                              104,
                                              28,
                                              20,
                                            ),
                                            child: ColoredBox(
                                              color: colors.surface,
                                              child: widget.finalContent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
                        child: Row(
                          children: [
                            if (!_isAgreementPage)
                              Semantics(
                                label: MaterialLocalizations.of(context)
                                    .tabLabel(
                                      tabIndex: _page + 1,
                                      tabCount: _lastPage + 1,
                                    ),
                                liveRegion: true,
                                child: Row(
                                  children: List.generate(
                                    _lastPage + 1,
                                    (index) => AnimatedContainer(
                                      duration: reduced
                                          ? Duration.zero
                                          : const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.only(right: 6),
                                      width: _page == index ? 24 : 6,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: _page == index
                                            ? colors.primary
                                            : colors.outlineVariant,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!_isAgreementPage) const Spacer(),
                            if (_page > 0)
                              IconButton(
                                key: const Key('welcomeBack'),
                                tooltip: l10n.previous,
                                onPressed: () => _goTo(_page - 1),
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                  color: colors.onSurface,
                                ),
                              ),
                            const SizedBox(width: 6),
                            if (_isAgreementPage)
                              Expanded(child: _nextButton())
                            else
                              _nextButton(),
                          ],
                        ),
                      ),
                      if (_isAgreementPage && widget.onDeclined != null)
                        TextButton(
                          key: const Key('welcomeDecline'),
                          onPressed: widget.isCompleting
                              ? null
                              : widget.onDeclined,
                          child: Text(l10n.agreementV2ExitLabel),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            l10n.welcomeTagline,
                            style: type.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeScrollBehavior extends MaterialScrollBehavior {
  const _WelcomeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

/// One persistent drawing, controlled by fractional scroll position. The cover,
/// spine and page block keep their identity through both reversible transitions.
class _BookJourneyPainter extends CustomPainter {
  const _BookJourneyPainter({
    required this.progress,
    required this.colors,
    this.fontFamily,
  });

  final double progress;
  final ColorScheme colors;
  Color get _ink => colors.primary;
  Color get _paper => colors.surface;
  Color get _gold => colors.onPrimary;
  final String? fontFamily;

  double _ease(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 2.0);
    final settle = _ease((progress - 2) * 2);
    final open = p <= 1 ? _ease(p) : 1 - _ease(p - 1);
    final shelf = _ease(p - 1);
    final unit = math.min(size.width / 420, size.height / 340);
    canvas.save();
    canvas.translate(
      size.width / 2,
      ui.lerpDouble(size.height / 2 + 4 * unit, 50, settle)!,
    );
    canvas.scale(unit * ui.lerpDouble(1, .32, settle)!);

    // A quiet paper disc provides depth without enclosing the illustration.
    canvas.drawCircle(
      const Offset(0, 1),
      146,
      Paint()..color = colors.surfaceContainer.withValues(alpha: 1 - settle),
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: 162),
      -1.25 + p * .15,
      1.9,
      false,
      Paint()
        ..color = colors.outlineVariant.withValues(alpha: 1 - settle)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.drawCircle(
      Offset(157 * math.cos(.65 + p * .15), 157 * math.sin(.65 + p * .15)),
      3,
      Paint()..color = _ink.withValues(alpha: .4 * (1 - settle)),
    );

    if (shelf > 0) {
      canvas.saveLayer(
        const Rect.fromLTRB(-210, -180, 210, 180),
        Paint()..color = Colors.white.withValues(alpha: shelf * (1 - settle)),
      );
      for (final (x, tilt, color, title) in [
        (-112.0, -.12, colors.primaryContainer, '远山'),
        (112.0, .09, colors.secondaryContainer, '慢慢生活'),
      ]) {
        canvas.save();
        canvas.translate(x * shelf, 28 + 65 * (1 - shelf));
        canvas.rotate(tilt * shelf);
        canvas.scale(.58);
        _closedBook(canvas, color, title);
        canvas.restore();
      }
      canvas.drawLine(
        const Offset(-176, 121),
        const Offset(176, 121),
        Paint()
          ..color = colors.outline
          ..strokeWidth = 1.2,
      );
      canvas.drawLine(
        const Offset(-157, 126),
        const Offset(157, 126),
        Paint()
          ..color = colors.outlineVariant
          ..strokeWidth = 1,
      );
      canvas.restore();
    }

    canvas.save();
    canvas.translate(0, shelf * 28);
    canvas.scale(1 - .12 * open - .28 * shelf);
    canvas.rotate(-.085 * (1 - open) * (1 - shelf));
    canvas.translate(-82 * (1 - open), 0);
    final pageRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, -120, 164, 240),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(pageRect),
      Colors.black.withValues(alpha: .22),
      16,
      true,
    );
    canvas.drawRRect(pageRect, Paint()..color = colors.surfaceContainerHighest);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, -123, 160, 238),
        const Radius.circular(4),
      ),
      Paint()..color = colors.surfaceContainerLowest,
    );
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(8, 116.0 + i),
        Offset(159, 116.0 + i),
        Paint()
          ..color = colors.outlineVariant
          ..strokeWidth = .45,
      );
    }
    _pageContent(canvas, left: false, opacity: open);

    // Lift the front cover TOWARD the reader, then open right-to-left around
    // the left spine. Positive depth enlarges the free edge under perspective;
    // shrinking that edge would incorrectly fold the cover into the page block.
    final angle = open * math.pi;
    final perspective = 1 / (1 - math.sin(angle) * 164 / 700);
    final width = math.cos(angle) * 164 * perspective;
    final leaf = Path()
      ..moveTo(0, -123)
      ..lineTo(width, -123 * perspective)
      ..lineTo(width, 117 * perspective)
      ..lineTo(0, 117)
      ..close();
    canvas.drawShadow(leaf, Colors.black.withValues(alpha: .18), 8, true);
    canvas.drawPath(
      leaf,
      Paint()..color = open < .5 ? _ink : colors.surfaceContainerLow,
    );
    canvas.save();
    canvas.clipPath(leaf);
    if (width.abs() > .5) {
      final transform = Matrix4.identity()
        ..setEntry(3, 2, -1 / 700)
        ..rotateY(-angle);
      canvas.transform(transform.storage);
      if (width < 0) {
        // We now see the inside of the cover, so restore readable orientation.
        canvas.translate(164, 0);
        canvas.scale(-1, 1);
        _pageContent(canvas, left: true, opacity: 1);
      } else {
        _coverContent(canvas);
      }
    }
    canvas.restore();
    // Fold shading is anchored to the spine, not to a screen transition.
    canvas.drawRect(
      const Rect.fromLTWH(0, -122, 14, 238),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(14, 0), [
          Colors.black.withValues(alpha: .13),
          Colors.transparent,
        ]),
    );
    canvas.restore();
    canvas.restore();
  }

  void _closedBook(Canvas canvas, Color color, String title) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-82, -120, 164, 240),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(rect),
      Colors.black.withValues(alpha: .18),
      8,
      true,
    );
    canvas.drawRRect(rect, Paint()..color = color);
    canvas.drawLine(
      const Offset(-71, -117),
      const Offset(-71, 117),
      Paint()
        ..color = _ink.withValues(alpha: .16)
        ..strokeWidth = 1,
    );
    _text(
      canvas,
      title,
      const Offset(-49, -65),
      22,
      colors.onSecondaryContainer,
    );
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: const Offset(17, 29),
          width: 82 + i * 12,
          height: 70 + i * 17,
        ),
        .3,
        math.pi * 1.3,
        false,
        Paint()
          ..color = _paper.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _coverContent(Canvas canvas) {
    canvas.drawLine(
      const Offset(10, -119),
      const Offset(10, 115),
      Paint()
        ..color = _gold.withValues(alpha: .3)
        ..strokeWidth = .6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, -102, 120, 200),
        const Radius.circular(1),
      ),
      Paint()
        ..color = _gold.withValues(alpha: .48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    _text(canvas, '山海之间', const Offset(40, -80), 21, _gold);
    _text(
      canvas,
      'A field of quiet',
      const Offset(45, -46),
      9,
      _gold.withValues(alpha: .7),
    );
    canvas.drawCircle(
      const Offset(84, 13),
      39,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.save();
    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(84, 13), radius: 39)),
    );
    final mountain = Path()
      ..moveTo(39, 43)
      ..lineTo(70, -4)
      ..lineTo(87, 17)
      ..lineTo(101, -10)
      ..lineTo(134, 43)
      ..close();
    canvas.drawPath(mountain, Paint()..color = _gold.withValues(alpha: .9));
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(39, 28.0 + i * 6),
        Offset(129, 28.0 + i * 6),
        Paint()
          ..color = _ink
          ..strokeWidth = 1.8,
      );
    }
    canvas.restore();
    canvas.drawCircle(const Offset(96, -8), 4, Paint()..color = _gold);
    _text(
      canvas,
      '给每一个热爱阅读的你',
      const Offset(37, 76),
      8,
      _gold.withValues(alpha: .85),
    );
  }

  void _pageContent(
    Canvas canvas, {
    required bool left,
    required double opacity,
  }) {
    final color = colors.onSurface.withValues(alpha: opacity * .7);
    _text(
      canvas,
      left ? '山海之间' : '第一章  风起时',
      const Offset(24, -83),
      left ? 16 : 12,
      color,
    );
    if (left) {
      canvas.drawCircle(
        const Offset(79, -5),
        29,
        Paint()..color = colors.primaryContainer.withValues(alpha: opacity),
      );
      final hill = Path()
        ..moveTo(25, 45)
        ..quadraticBezierTo(70, -35, 98, 19)
        ..quadraticBezierTo(119, -7, 142, 45)
        ..close();
      canvas.drawPath(
        hill,
        Paint()..color = colors.secondary.withValues(alpha: opacity),
      );
      _text(canvas, '在字里行间，遇见远方。', const Offset(27, 73), 8, color);
    } else {
      const lines = [
        '清晨，风从山的那一边吹来。',
        '窗外的树影轻轻晃动，',
        '像一封还没有拆开的信。',
        '',
        '我翻开书，把世界的声音',
        '留在门外。此刻，只有文字',
        '带着我，走向更远的地方。',
      ];
      for (var i = 0; i < lines.length; i++) {
        _text(canvas, lines[i], Offset(23, -47.0 + i * 16), 8.2, color);
      }
      _text(canvas, '01', const Offset(78, 94), 7, color);
    }
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontFamily: fontFamily,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
    painter.dispose();
  }

  @override
  bool shouldRepaint(_BookJourneyPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.fontFamily != fontFamily ||
      oldDelegate.colors != colors;
}
