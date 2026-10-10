import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/pages/settings/app_theme_page.dart';
import 'package:xxread/pages/settings/about/open_source_licenses_page.dart';
import 'package:xxread/widgets/glass_buttons.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/ui_style.dart';

Future<ThemeNotifier> _loadNotifier() async {
  final notifier = ThemeNotifier();
  if (notifier.isInitialized) return notifier;

  final initialized = Completer<void>();
  void listener() {
    if (notifier.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  notifier.addListener(listener);
  listener();
  await initialized.future;
  notifier.removeListener(listener);
  return notifier;
}

ThemeData _themeData(ThemeNotifier notifier, Brightness brightness) {
  final scheme = brightness == Brightness.dark
      ? notifier.currentAppTheme.darkColorScheme
      : notifier.currentAppTheme.lightColorScheme;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [
      notifier.skinTheme,
      UiStyleThemeExtension(
        style: notifier.uiStyle,
        glassStyle: notifier.glassStyle,
        liquidGlassOpacity: notifier.liquidGlassOpacity,
      ),
    ],
  );
}

Future<ThemeNotifier> _pumpGallery(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size logicalSize = const Size(390, 844),
  double devicePixelRatio = 1,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool disableAnimations = true,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = logicalSize * devicePixelRatio;
  addTearDown(tester.view.reset);

  final notifier = await _loadNotifier();
  addTearDown(notifier.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<ThemeNotifier>.value(
      value: notifier,
      child: AnimatedBuilder(
        animation: notifier,
        builder: (context, _) => MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: _themeData(notifier, Brightness.light),
          darkTheme: _themeData(notifier, Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              highContrast: highContrast,
              disableAnimations: disableAnimations,
            ),
            child: child!,
          ),
          home: const AppThemePage(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return notifier;
}

Future<void> _tapChoice(WidgetTester tester, String key) async {
  final choice = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    choice,
    280,
    scrollable: _galleryScrollable(),
  );
  await tester.pump();
  await tester.tap(choice.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _showArtworkThemes(WidgetTester tester) async {
  final context = tester.element(find.byType(AppThemePage));
  final label = AppLocalizations.of(context).settingsThemeSkinCategory;
  final category = find.text(label);
  await tester.scrollUntilVisible(
    category,
    280,
    scrollable: _galleryScrollable(),
  );
  await tester.pump();
  await tester.tap(category.hitTestable());
  await tester.pump();
}

Finder _galleryScrollable() => find.descendant(
  of: find.descendant(
    of: find.byType(AppThemePage),
    matching: find.byType(SingleChildScrollView),
  ),
  matching: find.byType(Scrollable),
);

final class _FailFirstPresetStore extends InMemorySharedPreferencesStore {
  _FailFirstPresetStore() : super.empty();

  var presetWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.appColorPresetIdV1') {
      presetWrites += 1;
      if (presetWrites == 1) return false;
    }
    return super.setValue(valueType, key, value);
  }
}

final class _DelayedFirstPresetStore extends InMemorySharedPreferencesStore {
  _DelayedFirstPresetStore() : super.empty();

  final firstPresetResult = Completer<bool>();
  var presetWrites = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.appColorPresetIdV1') {
      presetWrites += 1;
      if (presetWrites == 1 && !await firstPresetResult.future) return false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final preset in AppThemes.colorPresets) {
    testWidgets(
      'selecting ${preset.id} applies and persists its complete scheme only',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'appSkinIdV1': 'tidal',
          'ui_style_mode': 'glass',
          'glass_style_mode': 'frosted',
          'readerTheme': 'paper',
        });
        final notifier = await _pumpGallery(tester);

        await _tapChoice(tester, 'palette-${preset.id}');

        final prefs = await SharedPreferences.getInstance();
        expect(notifier.currentColorPreset, same(preset));
        expect(notifier.currentAppTheme, same(preset.theme));
        expect(
          Theme.of(tester.element(find.byType(AppThemePage))).colorScheme,
          preset.theme.lightColorScheme,
        );
        expect(prefs.getString('appColorPresetIdV1'), preset.id);
        expect(
          prefs.getInt('appAccentColorV2'),
          preset.theme.seedColor.toARGB32(),
        );
        expect(notifier.currentSkin.id, 'tidal');
        expect(notifier.glassStyle, GlassStyle.frosted);
        expect(prefs.getString('readerTheme'), 'paper');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final skinId in const [
    AppSkin.originalId,
    'tidal',
    'botanical',
    'celestial',
  ]) {
    testWidgets('selecting $skinId changes only the artwork theme', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'appColorPresetIdV1': 'violet',
        if (skinId == AppSkin.originalId) 'appSkinIdV1': 'tidal',
        'ui_style_mode': 'glass',
        'glass_style_mode': 'frosted',
        'readerTheme': 'paper',
      });
      final notifier = await _pumpGallery(tester);
      final expectedTheme = AppThemes.findColorPreset('violet')!.theme;

      await _showArtworkThemes(tester);
      await _tapChoice(tester, 'skin-$skinId');

      final prefs = await SharedPreferences.getInstance();
      expect(notifier.currentSkin.id, skinId);
      expect(
        prefs.getString('appSkinIdV1'),
        skinId == AppSkin.originalId ? isNull : skinId,
      );
      expect(notifier.currentColorPreset?.id, 'violet');
      expect(notifier.currentAppTheme, same(expectedTheme));
      expect(notifier.glassStyle, GlassStyle.frosted);
      expect(prefs.getString('readerTheme'), 'paper');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('legacy arbitrary color is shown read-only and preserved', (
    tester,
  ) async {
    const legacyAccent = Color(0xFF315A76);
    SharedPreferences.setMockInitialValues({
      'appAccentColorV2': legacyAccent.toARGB32(),
    });
    final notifier = await _pumpGallery(tester);

    final legacy = find.byKey(const ValueKey('palette-legacy'));
    expect(legacy, findsOneWidget);
    expect(tester.widget<InkWell>(legacy).onTap, isNull);
    expect(notifier.currentColorPreset, isNull);
    expect(notifier.accentColor, legacyAccent);
    expect(
      (await SharedPreferences.getInstance()).getInt('appAccentColorV2'),
      legacyAccent.toARGB32(),
    );
  });

  testWidgets('failed preset save offers a retry that persists the choice', (
    tester,
  ) async {
    final notifier = await _pumpGallery(tester);
    final previousStore = SharedPreferencesStorePlatform.instance;
    final store = _FailFirstPresetStore();
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = previousStore);

    await _tapChoice(tester, 'palette-forest');
    await tester.pump(const Duration(milliseconds: 300));

    final l10n = AppLocalizations.of(tester.element(find.byType(AppThemePage)));
    expect(find.text(l10n.settingsThemeSaveFailed), findsOneWidget);
    expect(notifier.currentColorPreset?.id, 'forest');

    await tester.tap(find.text(l10n.settingsThemeRetry));
    await tester.pumpAndSettle();

    expect(store.presetWrites, 2);
    expect((await store.getAll())['flutter.appColorPresetIdV1'], 'forest');
    expect(find.text(l10n.settingsThemeSaveFailed), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stale failed selection cannot offer retry after a newer choice',
    (tester) async {
      final notifier = await _pumpGallery(tester);
      final previousStore = SharedPreferencesStorePlatform.instance;
      final store = _DelayedFirstPresetStore();
      SharedPreferencesStorePlatform.instance = store;
      addTearDown(
        () => SharedPreferencesStorePlatform.instance = previousStore,
      );

      final forest = find.byKey(const ValueKey('palette-forest'));
      await tester.tap(forest.hitTestable());
      await tester.pump();
      expect(store.presetWrites, 1);

      final amber = find.byKey(const ValueKey('palette-amber'));
      await tester.ensureVisible(amber);
      await tester.pump();
      await tester.tap(amber.hitTestable());
      await tester.pump();
      expect(notifier.currentColorPreset?.id, 'amber');

      store.firstPresetResult.complete(false);
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(AppThemePage)),
      );
      expect(find.text(l10n.settingsThemeSaveFailed), findsNothing);
      expect(find.text(l10n.settingsThemeRetry), findsNothing);
      expect(notifier.currentColorPreset?.id, 'amber');
      expect(store.presetWrites, 2);
      expect((await store.getAll())['flutter.appColorPresetIdV1'], 'amber');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a newer choice dismisses an already shown retry', (
    tester,
  ) async {
    final notifier = await _pumpGallery(tester);
    final previousStore = SharedPreferencesStorePlatform.instance;
    final store = _FailFirstPresetStore();
    SharedPreferencesStorePlatform.instance = store;
    addTearDown(() => SharedPreferencesStorePlatform.instance = previousStore);

    await _tapChoice(tester, 'palette-forest');
    final l10n = AppLocalizations.of(tester.element(find.byType(AppThemePage)));
    expect(find.text(l10n.settingsThemeSaveFailed), findsOneWidget);
    expect(find.text(l10n.settingsThemeRetry), findsOneWidget);

    await _tapChoice(tester, 'palette-amber');

    expect(find.text(l10n.settingsThemeSaveFailed), findsNothing);
    expect(find.text(l10n.settingsThemeRetry), findsNothing);
    expect(notifier.currentColorPreset?.id, 'amber');
    expect(store.presetWrites, 2);
    expect((await store.getAll())['flutter.appColorPresetIdV1'], 'amber');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected cards expose selection and usable tap targets', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'appColorPresetIdV1': 'blue'});
    await _pumpGallery(tester);

    final selected = find.byKey(const ValueKey('palette-blue'));
    final other = find.byKey(const ValueKey('palette-forest'));
    Semantics choiceSemantics(Finder choice) => find
        .ancestor(of: choice, matching: find.byType(Semantics))
        .evaluate()
        .map((element) => element.widget)
        .whereType<Semantics>()
        .firstWhere((widget) => widget.properties.selected != null);
    expect(choiceSemantics(selected).properties.selected, isTrue);
    expect(choiceSemantics(other).properties.selected, isFalse);
    for (final target in [selected, other]) {
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('all gallery artwork resolves from the bundled assets', (
    tester,
  ) async {
    await _pumpGallery(tester);
    await _showArtworkThemes(tester);
    await tester.pump(const Duration(milliseconds: 500));

    final catalogPaths = <String>{
      for (final skin in AppSkinCatalog.builtIn.skins) ...[
        for (final image in skin.artwork.values) image.asset,
        for (final icon in skin.icons.values) icon.normal.asset,
      ],
    };
    final previewPaths = <String>{
      for (final skin in AppSkinCatalog.builtIn.skins) ...[
        for (final image in skin.artwork.values) image.asset,
        for (final slot in const [
          AppSkinIconSlot.home,
          AppSkinIconSlot.library,
          AppSkinIconSlot.discover,
        ])
          if (skin.icons[slot] case final icon?)
            icon.resolve(slot == AppSkinIconSlot.library).asset,
      ],
    };
    final renderedPaths = find
        .byType(Image)
        .evaluate()
        .map((element) => (element.widget as Image).image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toSet();

    expect(renderedPaths, containsAll(previewPaths));
    final bytes = await tester.runAsync(
      () => Future.wait(catalogPaths.map(rootBundle.load)),
    );
    expect(bytes, isNotNull);
    expect(bytes!.every((asset) => asset.lengthInBytes > 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  final layoutCases =
      <
        ({
          String name,
          Size size,
          double dpr,
          Locale locale,
          double scale,
          Brightness brightness,
          bool highContrast,
          bool reducedMotion,
        })
      >[
        (
          name: '390 light English',
          size: const Size(390, 844),
          dpr: 1,
          locale: const Locale('en'),
          scale: 1,
          brightness: Brightness.light,
          highContrast: false,
          reducedMotion: false,
        ),
        (
          name: '360 at 2x German long labels',
          size: const Size(360, 800),
          dpr: 2,
          locale: const Locale('de'),
          scale: 1.35,
          brightness: Brightness.light,
          highContrast: false,
          reducedMotion: false,
        ),
        (
          name: '1024 dark high contrast reduced motion',
          size: const Size(1024, 768),
          dpr: 1,
          locale: const Locale('en'),
          scale: 1,
          brightness: Brightness.dark,
          highContrast: true,
          reducedMotion: true,
        ),
      ];
  for (final layout in layoutCases) {
    testWidgets('${layout.name} gallery has no layout exception', (
      tester,
    ) async {
      await _pumpGallery(
        tester,
        locale: layout.locale,
        logicalSize: layout.size,
        devicePixelRatio: layout.dpr,
        textScale: layout.scale,
        brightness: layout.brightness,
        highContrast: layout.highContrast,
        disableAnimations: layout.reducedMotion,
      );
      await _showArtworkThemes(tester);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1200),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AppThemePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'artwork credits route uses shared UI and shows offline notices',
    (tester) async {
      await _pumpGallery(tester, locale: const Locale('zh'));
      final credits = find.byKey(const ValueKey('theme-asset-credits'));
      await tester.ensureVisible(credits);
      await tester.pumpAndSettle();
      expect(tester.widget(credits), isA<GlassTextButton>());
      await tester.tap(credits);
      await tester.pumpAndSettle();
      final page = tester.widget<OpenSourceLicensesPage>(
        find.byType(OpenSourceLicensesPage),
      );
      expect(page.prioritizeAssets, isTrue);
      expect(page.title, '素材与开源致谢');
      expect(find.byType(LicensePage), findsNothing);
      expect(
        find.byKey(const ValueKey('skin-artwork-credits')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('provider-brand-notice')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
