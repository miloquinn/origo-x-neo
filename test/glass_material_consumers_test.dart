import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_dialog.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/glass_top_bar.dart';
import 'package:xxread/widgets/gradient_top_backdrop.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';
import 'package:xxread/widgets/side_toast.dart';

void main() {
  setUp(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
  });
  tearDown(() {
    GlassEffectConfig.setDisableAllGlassEffects(false);
    GlassEffectConfig.setGlassStyle(defaultGlassStyle);
  });

  testWidgets(
    'top chrome uses a solid accessible background and keeps actions',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          GlassTopBar(
            title: '阅读',
            systemTopInset: 0,
            trailing: IconButton(
              onPressed: () => taps++,
              icon: const Icon(Icons.add),
            ),
          ),
          style: GlassStyle.liquid,
          media: const MediaQueryData(highContrast: true),
        ),
      );
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(LiquidGlassSurface), findsNothing);
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GradientTopBackdrop),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color.a, 1);
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    },
  );

  testWidgets(
    'top chrome peak sigma follows theme in both stale-state directions',
    (tester) async {
      final peaks = <GlassStyle, double>{};
      for (final themeStyle in GlassStyle.values) {
        GlassEffectConfig.setGlassStyle(themeStyle);
        await tester.pumpWidget(
          _app(
            const GlassTopBar(
              title: '阅读',
              systemTopInset: 0,
              contentHeight: 180,
            ),
            style: themeStyle,
          ),
        );
        await tester.pumpAndSettle();
        peaks[themeStyle] = tester
            .widget<GradientTopBackdrop>(find.byType(GradientTopBackdrop))
            .maxSigma!;
        GlassEffectConfig.setGlassStyle(
          themeStyle == GlassStyle.liquid
              ? GlassStyle.frosted
              : GlassStyle.liquid,
        );
        await tester.pumpWidget(
          _app(
            GlassTopBar(
              key: ValueKey(themeStyle),
              title: '阅读',
              systemTopInset: 0,
              contentHeight: 180,
            ),
            style: themeStyle,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<GradientTopBackdrop>(find.byType(GradientTopBackdrop))
              .maxSigma,
          peaks[themeStyle],
        );
      }
      expect(peaks[GlassStyle.frosted], greaterThan(peaks[GlassStyle.liquid]!));
    },
  );

  testWidgets('dialog filters its bounded panel and preserves action hits', (
    tester,
  ) async {
    var hits = 0;
    await tester.pumpWidget(
      _app(
        GlassDialog(
          title: const Text('确认操作'),
          content: const Text('只处理这本书。'),
          actions: [
            TextButton(onPressed: () => hits++, child: const Text('取消')),
          ],
        ),
      ),
    );
    final rect = tester.getRect(find.byType(GlassSurface));
    expect(rect.width, lessThan(800));
    expect(rect.height, lessThan(600));
    expect(tester.getRect(find.byType(BackdropFilter)), rect);
    await tester.tap(find.text('取消'));
    expect(hits, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text dialog scrolls above keyboard while actions remain visible',
    (tester) async {
      await tester.pumpWidget(
        _app(
          GlassDialog(
            title: const Text('较长的书籍删除确认标题'),
            content: Text(List.filled(80, '较长书名和正文说明').join('\n')),
            actions: [
              TextButton(onPressed: () {}, child: const Text('取消')),
              TextButton(onPressed: () {}, child: const Text('确认')),
            ],
          ),
          media: const MediaQueryData(
            size: Size(800, 600),
            viewInsets: EdgeInsets.only(bottom: 180),
            textScaler: TextScaler.linear(2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byType(GlassSurface));
      expect(rect.bottom, lessThanOrEqualTo(420));
      expect(
        tester.getRect(find.text('确认')).bottom,
        lessThanOrEqualTo(rect.bottom),
      );
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
      await tester.tap(find.text('取消'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toast fades foreground separately from liquid material', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showSideToast(
              context,
              '已保存',
              duration: const Duration(seconds: 10),
            ),
            child: const Text('提示'),
          ),
        ),
        style: GlassStyle.liquid,
      ),
    );
    await tester.tap(find.text('提示'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final liquid = find.byType(LiquidGlassSurface);
    expect(liquid, findsOneWidget);
    expect(
      tester.widget<LiquidGlassSurface>(liquid).visibility,
      inExclusiveRange(0, 1),
    );
    expect(
      find.ancestor(of: liquid, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(
      find.ancestor(of: liquid, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(find.text('已保存'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    expect(find.text('已保存'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('progressive tint follows theme style over stale global style', (
    tester,
  ) async {
    const tint = ValueKey('gradient-top-backdrop-liquid-tint');
    GlassEffectConfig.setGlassStyle(GlassStyle.frosted);
    await tester.pumpWidget(
      _app(const GradientTopBackdrop(height: 120), style: GlassStyle.liquid),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(tint), findsOneWidget);
    expect(tester.getSize(find.byKey(tint)).height, 104);
    GlassEffectConfig.setGlassStyle(GlassStyle.liquid);
    await tester.pumpWidget(
      _app(const GradientTopBackdrop(height: 120), style: GlassStyle.frosted),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(tint), findsNothing);
    expect(find.byType(BackdropFilter), findsWidgets);
    GlassEffectConfig.setDisableAllGlassEffects(true);
    await tester.pumpWidget(
      _app(const GradientTopBackdrop(height: 120), style: GlassStyle.liquid),
    );
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(tint), findsNothing);
  });
}

Widget _app(
  Widget child, {
  GlassStyle style = GlassStyle.frosted,
  MediaQueryData? media,
}) => MaterialApp(
  theme: ThemeData(
    extensions: [
      UiStyleThemeExtension(
        style: AppUiStyle.glass,
        glassStyle: style,
        liquidGlassOpacity: .5,
      ),
    ],
  ),
  builder: media == null
      ? null
      : (context, child) => MediaQuery(data: media, child: child!),
  home: Scaffold(body: child),
);
