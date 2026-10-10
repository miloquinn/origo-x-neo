import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/widgets/side_toast.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/liquid_glass_surface.dart';

void main() {
  setUp(() => GlassEffectConfig.setDisableAllGlassEffects(false));
  tearDown(() {
    hideSideToast();
    GlassEffectConfig.setDisableAllGlassEffects(false);
  });
  testWidgets('side toast appears and dismisses automatically', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const Scaffold();
          },
        ),
      ),
    );

    showSideToast(
      context,
      'Saved',
      kind: SideToastKind.success,
      duration: const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('new side toast replaces the previous message', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const Scaffold();
          },
        ),
      ),
    );

    showSideToast(context, 'First', duration: const Duration(seconds: 5));
    await tester.pump();
    showSideToast(
      context,
      'Second',
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  });

  testWidgets('side toast leaves interaction outside the card available', (
    tester,
  ) async {
    late BuildContext context;
    var taps = 0;
    const buttonKey = Key('underlying-button');
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: FilledButton(
                  key: buttonKey,
                  onPressed: () => taps += 1,
                  child: const Text('Continue'),
                ),
              ),
            );
          },
        ),
      ),
    );

    showSideToast(
      context,
      'Background task started',
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    await tester.tap(find.byKey(buttonKey));

    expect(taps, 1);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  });

  testWidgets('side toast can be swiped away', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const Scaffold();
          },
        ),
      ),
    );

    showSideToast(context, 'Swipe me', duration: const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Swipe me'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Swipe me'), findsNothing);
  });

  testWidgets('side toast action runs and dismisses the toast', (tester) async {
    late BuildContext context;
    var actionRuns = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const Scaffold();
          },
        ),
      ),
    );

    showSideToast(
      context,
      'Changed',
      actionLabel: 'Undo',
      onAction: () => actionRuns += 1,
      duration: const Duration(seconds: 5),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(actionRuns, 1);
    expect(find.text('Changed'), findsNothing);
  });
  testWidgets('short feedback fits its content and respects safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.reset);
    final context = await _pumpHost(tester);
    showSideToast(context, '已记录推荐反馈');
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(GlassSurface));
    expect(rect.top, 52);
    expect(rect.width, lessThan(358));
    expect(rect.center.dx, 195);
    expect(rect.height, greaterThanOrEqualTo(52));
    hideSideToast();
    await tester.pump();
  });

  testWidgets('material modes retain the same layout and action', (
    tester,
  ) async {
    Size? size;
    for (final mode in ['solid', 'frosted', 'liquid', 'contrast']) {
      GlassEffectConfig.setDisableAllGlassEffects(mode == 'solid');
      final context = await _pumpHost(
        tester,
        style: mode == 'frosted' ? GlassStyle.frosted : GlassStyle.liquid,
        highContrast: mode == 'contrast',
      );
      var runs = 0;
      showSideToast(context, '已更新', actionLabel: '撤销', onAction: () => runs++);
      await tester.pumpAndSettle();
      final actual = tester.getSize(find.byType(GlassSurface));
      size ??= actual;
      expect(actual, size, reason: mode);
      expect(
        find.byType(LiquidGlassSurface),
        mode == 'liquid' ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(BackdropFilter),
        mode == 'frosted' || mode == 'liquid' ? findsOneWidget : findsNothing,
      );
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(runs, 1);
    }
  });

  testWidgets('long feedback and actions receive enough reading time', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    final message = '反馈说明' * 20;
    showSideToast(context, message);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(message), findsOneWidget);
    hideSideToast();
    await tester.pump();
    showSideToast(context, '已更新', actionLabel: '撤销', onAction: () {});
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('撤销'), findsNothing);
  });

  testWidgets(
    'action can replace feedback without an old callback dismissing it',
    (tester) async {
      final context = await _pumpHost(tester);
      var runs = 0;
      showSideToast(
        context,
        '已更新',
        actionLabel: '撤销',
        onAction: () {
          runs++;
          showSideToast(context, '已撤销');
        },
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('撤销'));
      await tester.pumpAndSettle();
      expect(runs, 1);
      expect(find.text('已撤销'), findsOneWidget);
      hideSideToast();
      await tester.pump();
    },
  );

  testWidgets('root overlay preserves local reader palette', (tester) async {
    final local = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.amber,
        brightness: Brightness.dark,
      ),
    );
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Theme(
          data: local,
          child: Builder(
            builder: (ctx) {
              context = ctx;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    showSideToast(context, '阅读配色');
    await tester.pumpAndSettle();
    expect(
      tester.widget<GlassSurface>(find.byType(GlassSurface)).color,
      local.colorScheme.surfaceContainerHigh,
    );
    expect(
      tester.widget<Text>(find.text('阅读配色')).style?.color,
      local.colorScheme.onSurface,
    );
    hideSideToast();
    await tester.pump();
  });

  testWidgets('narrow large-text feedback wraps completely and keeps action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final context = await _pumpHost(tester, textScale: 2);
    const message = '推荐反馈暂时未保存，请检查网络后重试。你的阅读记录仍然保留。';
    showSideToast(context, message, actionLabel: '重试', onAction: () {});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<Text>(find.text(message)).maxLines, isNull);
    final rect = tester.getRect(find.byType(GlassSurface));
    expect(rect.left, greaterThanOrEqualTo(16));
    expect(rect.right, lessThanOrEqualTo(304));
    expect(
      tester.getRect(find.text('重试')).top,
      greaterThan(tester.getRect(find.text(message)).bottom),
    );
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'accessible action does not time out and supports semantic dismiss',
    (tester) async {
      final context = await _pumpHost(tester, accessible: true);
      showSideToast(
        context,
        '未保存',
        actionLabel: '重试',
        onAction: () {},
        duration: const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('重试'), findsOneWidget);
      final semantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.liveRegion == true)
          .single;
      expect(semantics.properties.onDismiss, isNotNull);
      semantics.properties.onDismiss!();
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsNothing);
    },
  );

  testWidgets('replacement while exiting keeps the newer toast alive', (
    tester,
  ) async {
    final context = await _pumpHost(tester);
    showSideToast(context, '旧消息', duration: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 80));
    showSideToast(context, '新消息', duration: const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('旧消息'), findsNothing);
    expect(find.text('新消息'), findsOneWidget);
    expect(tester.takeException(), isNull);
    hideSideToast();
    hideSideToast();
    await tester.pump();
  });

  testWidgets('reduced motion appears immediately', (tester) async {
    final context = await _pumpHost(tester, reduceMotion: true);
    showSideToast(context, '完成');
    await tester.pump();
    expect(
      tester.widget<GlassSurface>(find.byType(GlassSurface)).visibility,
      1,
    );
    expect(
      tester
          .widget<SlideTransition>(
            find
                .ancestor(
                  of: find.byType(GlassSurface),
                  matching: find.byType(SlideTransition),
                )
                .first,
          )
          .position
          .value,
      Offset.zero,
    );
    hideSideToast();
    await tester.pump();
  });
}

Future<BuildContext> _pumpHost(
  WidgetTester tester, {
  GlassStyle style = GlassStyle.frosted,
  bool highContrast = false,
  double textScale = 1,
  bool accessible = false,
  bool reduceMotion = false,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: [
          UiStyleThemeExtension(style: AppUiStyle.glass, glassStyle: style),
        ],
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          highContrast: highContrast,
          textScaler: TextScaler.linear(textScale),
          accessibleNavigation: accessible,
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: Builder(
        builder: (ctx) {
          context = ctx;
          return const Scaffold();
        },
      ),
    ),
  );
  return context;
}
