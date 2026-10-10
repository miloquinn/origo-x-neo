import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/app_theme_page.dart';
import 'package:xxread/pages/settings/settings_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/services/core/core_services.dart';
import 'package:xxread/utils/app_skin_licenses.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAppSkinLicenses();
  runApp(const _Preview());
}

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  final _boundary = GlobalKey();
  final _theme = ThemeNotifier();
  final _settings = AppSettingsNotifier();
  static const _cases = [
    (
      name: 'palette-phone',
      size: Size(390, 844),
      color: 'forest',
      skin: 'original',
      dark: false,
      scale: 1.0,
      artwork: false,
    ),
    (
      name: 'artwork-phone',
      size: Size(390, 844),
      color: 'blue',
      skin: 'tidal',
      dark: false,
      scale: 1.0,
      artwork: true,
    ),
    (
      name: 'artwork-dark',
      size: Size(390, 844),
      color: 'violet',
      skin: 'celestial',
      dark: true,
      scale: 1.0,
      artwork: true,
    ),
    (
      name: 'palette-tablet',
      size: Size(1024, 820),
      color: 'amber',
      skin: 'botanical',
      dark: false,
      scale: 1.0,
      artwork: false,
    ),
    (
      name: 'artwork-large-text',
      size: Size(360, 900),
      color: 'rose',
      skin: 'botanical',
      dark: false,
      scale: 2.0,
      artwork: true,
    ),
    (
      name: 'settings-phone',
      size: Size(390, 844),
      color: 'forest',
      skin: 'original',
      dark: false,
      scale: 1.0,
      artwork: false,
    ),
  ];
  var _index = 0;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_capture()));
  }

  @override
  void dispose() {
    _theme.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _cases[_index];
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _theme),
        ChangeNotifierProvider.value(value: _settings),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (_, notifier, _) {
          final scheme = item.dark
              ? notifier.currentAppTheme.darkColorScheme
              : notifier.currentAppTheme.lightColorScheme;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: scheme,
              extensions: [
                notifier.skinTheme,
                UiStyleThemeExtension(
                  style: notifier.uiStyle,
                  glassStyle: notifier.glassStyle,
                  liquidGlassOpacity: notifier.liquidGlassOpacity,
                ),
              ],
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: FittedBox(
                  child: RepaintBoundary(
                    key: _boundary,
                    child: SizedBox(
                      width: item.size.width,
                      height: item.size.height,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: item.size,
                          padding: const EdgeInsets.only(top: 44, bottom: 24),
                          viewPadding: const EdgeInsets.only(
                            top: 44,
                            bottom: 24,
                          ),
                          textScaler: TextScaler.linear(item.scale),
                          disableAnimations: true,
                        ),
                        child: !_ready
                            ? const SizedBox.shrink()
                            : _index == _cases.length - 1
                            ? SettingsPage(
                                key: ValueKey(item.name),
                                category: SettingsCategory.preferences,
                                cacheManager: _PreviewCache(),
                                preferencesStore: _PreviewPreferences(),
                                aiService: MockAIService(),
                              )
                            : AppThemePage(
                                key: ValueKey(item.name),
                                initialCategory: item.artwork
                                    ? AppThemeCategory.artwork
                                    : AppThemeCategory.color,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _capture() async {
    while (!_theme.isInitialized) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final output = Directory(
      '${Directory.systemTemp.path}/theme-gallery-preview',
    );
    await output.create(recursive: true);
    for (var index = 0; index < _cases.length; index++) {
      final item = _cases[index];
      await _theme.setColorPreset(item.color);
      await _theme.setSkin(item.skin);
      await _theme.setGlassStyle(GlassStyle.liquid);
      await _theme.setGlassEffectsEnabled(true);
      setState(() {
        _index = index;
        _ready = true;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      await WidgetsBinding.instance.endOfFrame;
      final image =
          await (_boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${output.path}/${item.name}.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }
    debugPrint('Theme gallery captures: ${output.path}');
  }
}

class _PreviewCache extends AppCacheManager {
  @override
  Future<AppCacheUsage> usage() async => AppCacheUsage({
    for (final category in AppCacheCategory.values) category: 0,
  });
}

class _PreviewPreferences implements SettingsPagePreferencesStore {
  @override
  Future<SettingsPagePreferences> load() async =>
      const SettingsPagePreferences();
  @override
  Future<void> save(SettingsPagePreferences preferences) async {}
}
