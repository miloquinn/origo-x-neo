import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/sync/icloud_sync_page.dart';
import 'package:xxread/services/icloud/icloud_sync_controller.dart';
import 'package:xxread/services/icloud/icloud_sync_models.dart';
import 'package:xxread/services/icloud/icloud_sync_navigation_observer.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/glass_material.dart';
import 'package:xxread/utils/ui_style.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/settings_panel.dart';

class _Sync extends ChangeNotifier implements ICloudSyncController {
  @override
  bool enabled = false;
  @override
  bool busy = false;
  @override
  String status = 'disabled';
  @override
  DateTime? lastSync;
  @override
  List<ICloudConflict> conflicts = [];
  int enableCalls = 0;
  int syncCalls = 0;
  ICloudRecord? chosen;
  @override
  Future<void> setEnabled(bool value) async {
    enableCalls++;
    enabled = value;
    status = value ? 'idle' : 'disabled';
    notifyListeners();
  }

  @override
  Future<void> synchronize() async {
    syncCalls++;
  }

  @override
  Future<void> resolveConflict(String key, ICloudRecord record) async {
    chosen = record;
    conflicts = [];
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_Sync sync, {double scale = 1, ThemeData? theme}) =>
    ChangeNotifierProvider<ICloudSyncController>.value(
      value: sync,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const ICloudSyncPage(),
      ),
    );

void main() {
  if (const bool.fromEnvironment('ORIGO_ICLOUD_CAPTURE')) {
    testWidgets(
      'capture iCloud sync page',
      (tester) async {
        await tester.runAsync(() async {
          final bytes = await File(
            '/System/Library/Fonts/Hiragino Sans GB.ttc',
          ).readAsBytes();
          await (FontLoader(
            'ICloudPreview',
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          final flutterRoot = Platform.resolvedExecutable
              .split('/bin/cache')
              .first;
          final icons = await File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes();
          await (FontLoader(
            'MaterialIcons',
          )..addFont(Future.value(ByteData.sublistView(icons)))).load();
        });
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        addTearDown(() {
          GlassEffectConfig.setDisableAllGlassEffects(false);
          GlassEffectConfig.setGlassStyle(defaultGlassStyle);
        });
        for (final brightness in Brightness.values) {
          for (final mode in GlassMaterialMode.values) {
            GlassEffectConfig.setDisableAllGlassEffects(
              mode == GlassMaterialMode.solid,
            );
            final style = mode == GlassMaterialMode.liquid
                ? GlassStyle.liquid
                : GlassStyle.frosted;
            final sync = _Sync()
              ..enabled = true
              ..status = 'idle';
            addTearDown(sync.dispose);
            final key = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: _app(
                  sync,
                  theme: ThemeData(
                    fontFamily: 'ICloudPreview',
                    brightness: brightness,
                    colorScheme: ColorScheme.fromSeed(
                      seedColor: Colors.teal,
                      brightness: brightness,
                    ),
                    extensions: [
                      UiStyleThemeExtension(
                        style: AppUiStyle.glass,
                        glassStyle: style,
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.runAsync(() async {
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final picture = await boundary.toImage(pixelRatio: 2);
              final bytes = await picture.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/icloud-sync/preview-${mode.name}-${brightness.name}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              picture.dispose();
            });
          }
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
  for (final platform in TargetPlatform.values) {
    test('iCloud platform visibility: $platform', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(
        ICloudSyncPage.isSupported,
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS,
      );
    });
  }
  testWidgets(
    'opening does not enable or upload; switch is explicit',
    (tester) async {
      final sync = _Sync();
      addTearDown(sync.dispose);
      await tester.pumpWidget(_app(sync));
      await tester.pumpAndSettle();
      expect(sync.enableCalls, 0);
      expect(sync.syncCalls, 0);
      expect(find.text('尚未开启，不会上传阅读数据。'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('icloud-sync-switch')));
      await tester.pumpAndSettle();
      expect(sync.enabled, isTrue);
      await tester.tap(find.text('立即同步'));
      await tester.pumpAndSettle();
      expect(sync.syncCalls, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'conflict choice shows device, progress, and selects that revision',
    (tester) async {
      const a = ICloudRecord(
        key: 'progress:book',
        value: {
          'kind': 'progress',
          'label': '测试书',
          'row': {'reading_progress': 0.21},
        },
        clock: {'a': 1},
        device: '我的 iPhone',
        modifiedAt: 1000,
      );
      const b = ICloudRecord(
        key: 'progress:book',
        value: {
          'kind': 'progress',
          'label': '测试书',
          'row': {'reading_progress': 0.38},
        },
        clock: {'b': 1},
        device: '我的 Mac',
        modifiedAt: 2000,
      );
      final sync = _Sync()
        ..enabled = true
        ..status = 'conflicts'
        ..conflicts = [
          const ICloudConflict('progress:book', [a, b]),
        ];
      addTearDown(sync.dispose);
      await tester.pumpWidget(_app(sync));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('我的 Mac'), 220);
      expect(find.text('阅读进度 · 38.0%'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('保留此版本').last, 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保留此版本').last);
      await tester.pumpAndSettle();
      expect(sync.chosen, same(b));
      expect(sync.conflicts, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
  testWidgets(
    'narrow large text remains scrollable without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final sync = _Sync()
        ..enabled = true
        ..status = 'accountChanged';
      addTearDown(sync.dispose);
      await tester.pumpWidget(_app(sync, scale: 1.6));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'shared panels preserve actions and layout across glass and solid themes',
    (tester) async {
      addTearDown(() {
        GlassEffectConfig.setDisableAllGlassEffects(false);
        GlassEffectConfig.setGlassStyle(defaultGlassStyle);
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Size? size;
      for (final brightness in Brightness.values) {
        for (final mode in GlassMaterialMode.values) {
          GlassEffectConfig.setDisableAllGlassEffects(
            mode == GlassMaterialMode.solid,
          );
          final style = mode == GlassMaterialMode.liquid
              ? GlassStyle.liquid
              : GlassStyle.frosted;
          final sync = _Sync()
            ..enabled = true
            ..status = 'idle';
          addTearDown(sync.dispose);
          await tester.pumpWidget(
            _app(
              sync,
              theme: ThemeData(
                brightness: brightness,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.teal,
                  brightness: brightness,
                ),
                extensions: [
                  UiStyleThemeExtension(
                    style: AppUiStyle.glass,
                    glassStyle: style,
                  ),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();
          final panel = find.byKey(const ValueKey('icloud-sync-panel'));
          expect(tester.widget(panel), isA<SettingsPanel>());
          final surface = find
              .descendant(of: panel, matching: find.byType(GlassSurface))
              .first;
          final context = tester.element(surface);
          expect(GlassMaterial.modeOf(context), mode);
          size ??= tester.getSize(panel);
          expect(tester.getSize(panel), size, reason: '$brightness $mode');
          await tester.tap(find.byKey(const ValueKey('icloud-sync-now')));
          await tester.pumpAndSettle();
          expect(sync.syncCalls, 1);
          expect(tester.takeException(), isNull, reason: '$brightness $mode');
        }
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets('reader and dialogs defer remote application until popped', (
    tester,
  ) async {
    final observer = ICloudSyncNavigationObserver();
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        navigatorObservers: [observer],
        home: const SizedBox(),
      ),
    );
    expect(observer.canApply, isTrue);
    key.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('reader')),
    );
    await tester.pumpAndSettle();
    expect(observer.canApply, isFalse);
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(observer.canApply, isTrue);
    key.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: ICloudSyncPage.routeName),
        builder: (_) => const Text('sync'),
      ),
    );
    await tester.pumpAndSettle();
    expect(observer.canApply, isTrue);
  });
}
