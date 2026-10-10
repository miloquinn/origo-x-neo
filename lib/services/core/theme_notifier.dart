// 文件说明：应用主题状态服务，负责主题模式、UI 风格、强调色持久化与旧设置迁移。
// 技术要点：ChangeNotifier、SharedPreferences、Material 3 配色、玻璃效果配置。

import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/models/app_skin.dart';
import 'package:xxread/models/theme_package.dart';
import 'package:xxread/services/themes/theme_package_store.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/app_skin_theme.dart';
import 'package:xxread/utils/glass_config.dart';
import 'package:xxread/utils/ui_style.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themeModePrefKey = 'isDarkMode';
  static const String _uiStylePrefKey = 'ui_style_mode';
  static const String _glassStylePrefKey = 'glass_style_mode';
  static const String _liquidGlassOpacityPrefKey = 'liquid_glass_opacity';
  static const String _accentColorPrefKey = 'appAccentColorV2';
  static const String _colorPresetPrefKey = 'appColorPresetIdV1';
  static const String _skinPrefKey = 'appSkinIdV1';
  static const String _packageSelectionPrefKey = 'appThemePackageSelectionV1';

  // 仅用于从旧版“双层主题 + 强调色”设置迁移。
  static const String _appThemePrefKey = 'appTheme';
  static const String _customAccentPrefKey = 'customAccentColor';
  static const String _globalAccentPrefKey = 'globalAccentColor';
  static const String _lastPresetThemePrefKey = 'last_preset_app_theme';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  Color _accentColor = AppThemes.defaultAccentColor;
  AppTheme _currentAppTheme = AppThemes.fromAccentColor(
    AppThemes.defaultAccentColor,
  );
  AppColorPreset? _currentColorPreset;
  AppUiStyle _uiStyle = AppUiStyle.glass;
  GlassStyle _glassStyle = defaultGlassStyle;
  double _liquidGlassOpacity = defaultLiquidGlassOpacity;
  final AppSkinCatalog _skinCatalog;
  AppSkin _currentSkin = AppSkin.original;
  final ThemePackageStore packageStore;
  List<ThemePackage> _installedThemes = const [];
  ThemePackage? _skinPackage;
  ThemePackage? _colorPackage;
  Future<void> _appearancePersistenceTail = Future.value();

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  Color get accentColor => _accentColor;
  AppTheme get currentAppTheme => _currentAppTheme;
  AppColorPreset? get currentColorPreset => _currentColorPreset;
  AppUiStyle get uiStyle => _uiStyle;
  GlassStyle get glassStyle => _glassStyle;
  double get liquidGlassOpacity => _liquidGlassOpacity;
  bool get isGlassEffectsEnabled => _uiStyle == AppUiStyle.glass;
  bool get shouldDisableGlassEffects => _uiStyle == AppUiStyle.material3;
  AppSkin get currentSkin => _currentSkin;
  List<AppSkin> get availableSkins => _skinCatalog.skins;
  List<ThemePackage> get installedThemes => List.unmodifiable(_installedThemes);
  ThemePackage? get currentSkinPackage => _skinPackage;
  ThemePackage? get currentColorPackage => _colorPackage;
  AppSkinTheme get skinTheme => AppSkinTheme(skin: _currentSkin);

  ThemeNotifier({AppSkinCatalog? skinCatalog, ThemePackageStore? packageStore})
    : _skinCatalog = skinCatalog ?? AppSkinCatalog.builtIn,
      packageStore = packageStore ?? ThemePackageStore() {
    _loadTheme();
  }

  Future<void> reloadFromPreferences() => _loadTheme();

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString(_packageSelectionPrefKey);
      if (saved != null) {
        final selection = jsonDecode(saved) as Map<String, dynamic>;
        _skinPackage = await _resolveSavedPackage(selection['skin']);
        _colorPackage = await _resolveSavedPackage(selection['palette']);
        _installedThemes = {
          for (final package in <ThemePackage>[?_skinPackage, ?_colorPackage])
            '${package.id}@${package.version}': package,
        }.values.toList(growable: false);
      }
    } catch (error, stackTrace) {
      developer.log(
        'Ignoring invalid theme selection',
        name: 'app.theme',
        error: error,
        stackTrace: stackTrace,
      );
    }
    final isDarkMode = prefs.getBool(_themeModePrefKey);
    _uiStyle = appUiStyleFromStorage(prefs.getString(_uiStylePrefKey));
    _glassStyle = GlassStyle.fromStorage(prefs.getString(_glassStylePrefKey));
    final storedOpacity = prefs.get(_liquidGlassOpacityPrefKey);
    _liquidGlassOpacity = normalizeLiquidGlassOpacity(
      storedOpacity is num
          ? storedOpacity.toDouble()
          : defaultLiquidGlassOpacity,
    );
    await prefs.remove('disable_glass_effects');
    final storedAccentColor = prefs.getInt(_accentColorPrefKey);
    final storedColorPresetId = prefs.getString(_colorPresetPrefKey);
    _currentColorPreset = AppThemes.findColorPreset(storedColorPresetId);
    if (storedColorPresetId != null && _currentColorPreset == null) {
      await prefs.remove(_colorPresetPrefKey);
    }
    final storedSkinId = prefs.getString(_skinPrefKey);
    _currentSkin = _skinPackage?.skin ?? _skinCatalog.resolve(storedSkinId);
    if (storedSkinId != null &&
        _skinPackage == null &&
        (storedSkinId != _currentSkin.id ||
            _currentSkin.id == AppSkin.originalId)) {
      await prefs.remove(_skinPrefKey);
    }

    _syncGlassEffectState();
    if (prefs.getBool('enableAnimations') != true) {
      await prefs.setBool('enableAnimations', true);
    }

    if (isDarkMode == null) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    }

    if (_currentColorPreset != null) {
      _accentColor = _currentColorPreset!.theme.seedColor;
      _currentAppTheme = _currentColorPreset!.theme;
    } else if (storedAccentColor != null) {
      _accentColor = Color(storedAccentColor);
    } else {
      _accentColor = _migrateLegacyAccentColor(prefs);
      await prefs.setInt(_accentColorPrefKey, _accentColor.toARGB32());
    }
    if (_currentColorPreset == null &&
        _accentColor.toARGB32() == AppThemes.defaultAccentColor.toARGB32()) {
      _currentColorPreset = AppThemes.findColorPreset('blue');
      await prefs.setString(_colorPresetPrefKey, _currentColorPreset!.id);
    }
    await _removeLegacyThemePreferences(prefs);
    _currentAppTheme =
        _currentColorPreset?.theme ?? AppThemes.fromAccentColor(_accentColor);
    if (_colorPackage?.palette case final palette?) {
      _currentColorPreset = null;
      _currentAppTheme = _packagePalette(palette);
      _accentColor = _currentAppTheme.seedColor;
    }

    _isInitialized = true;
    notifyListeners();
  }

  void toggleTheme(bool isDarkMode) async {
    final newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == newThemeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModePrefKey, isDarkMode);
  }

  /// 保留任意强调色兼容；调用后会退出已选中的协调色套餐。
  Future<void> setAccentColor(Color color) async {
    final hadPackagePalette = _colorPackage != null;
    _colorPackage = null;
    if (_accentColor.toARGB32() != color.toARGB32() ||
        _currentColorPreset != null ||
        hadPackagePalette) {
      _currentColorPreset = null;
      _accentColor = color;
      _currentAppTheme = AppThemes.fromAccentColor(color);
      notifyListeners();
    }

    await _queueColorPersistence(() => _persistCustomAccent(color));
  }

  /// 应用一整套协调的浅色/深色 Material 3 配色。
  Future<void> setColorPreset(String id) async {
    final preset = AppThemes.findColorPreset(id);
    if (preset == null) {
      throw ArgumentError.value(id, 'id', 'is not a known color preset');
    }
    _colorPackage = null;
    if (_currentColorPreset?.id != preset.id) {
      _currentColorPreset = preset;
      _accentColor = preset.theme.seedColor;
      _currentAppTheme = preset.theme;
      notifyListeners();
    }

    await _queueColorPersistence(() => _persistColorPreset(preset));
  }

  Future<void> _queueColorPersistence(Future<void> Function() persist) async {
    await _queueAppearancePersistence(persist);
  }

  Future<void> _queueAppearancePersistence(
    Future<void> Function() persist,
  ) async {
    final packageSnapshot = _packageSelectionJson();
    final operation = _appearancePersistenceTail.then((_) async {
      await persist();
      await _persistPackageSelection(packageSnapshot);
    });
    _appearancePersistenceTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await operation;
  }

  Future<void> _persistColorPreset(AppColorPreset preset) async {
    final prefs = await SharedPreferences.getInstance();
    final accentPersisted = await prefs.setInt(
      _accentColorPrefKey,
      preset.theme.seedColor.toARGB32(),
    );
    if (!accentPersisted) {
      throw StateError('Failed to persist color preset accent ${preset.id}.');
    }
    final presetPersisted = await prefs.setString(
      _colorPresetPrefKey,
      preset.id,
    );
    if (!presetPersisted) {
      throw StateError('Failed to persist color preset ${preset.id}.');
    }
    await _removeLegacyThemePreferences(prefs);
  }

  Future<void> _persistCustomAccent(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final accentPersisted = await prefs.setInt(
      _accentColorPrefKey,
      color.toARGB32(),
    );
    if (!accentPersisted) {
      throw StateError('Failed to persist custom accent color.');
    }
    final presetRemoved = await prefs.remove(_colorPresetPrefKey);
    if (!presetRemoved) {
      throw StateError('Failed to clear the selected color preset.');
    }
    await _removeLegacyThemePreferences(prefs);
  }

  Future<void> setSkin(String id) async {
    final skin = _skinCatalog.find(id);
    if (skin == null) {
      throw ArgumentError.value(id, 'id', 'is not present in the skin catalog');
    }
    _skinPackage = null;
    if (_currentSkin.id != skin.id) {
      _currentSkin = skin;
      notifyListeners();
    }

    await _queueAppearancePersistence(() => _persistSkin(skin));
  }

  Future<void> reloadInstalledThemes({bool notify = true}) async {
    try {
      _installedThemes = await packageStore.loadInstalled();
    } catch (error, stackTrace) {
      developer.log(
        'Loading local themes failed',
        name: 'app.theme',
        error: error,
        stackTrace: stackTrace,
      );
      _installedThemes = const [];
    }
    if (notify) notifyListeners();
  }

  Future<void> applyInstalledTheme(ThemePackage package) async {
    final installed = await packageStore.findInstalled(
      package.id,
      version: package.version,
      allowVersionFallback: false,
    );
    if (installed == null) throw StateError('Theme is not installed');
    final hasSkin =
        installed.skin.icons.isNotEmpty || installed.skin.artwork.isNotEmpty;
    if (hasSkin) {
      _skinPackage = installed;
      _currentSkin = installed.skin;
    }
    if (installed.palette case final palette?) {
      _colorPackage = installed;
      _currentColorPreset = null;
      _currentAppTheme = _packagePalette(palette);
      _accentColor = _currentAppTheme.seedColor;
    }
    notifyListeners();
    final skin = _currentSkin;
    final color = _accentColor;
    await _queueAppearancePersistence(() async {
      if (hasSkin) await _persistSkin(skin);
      if (installed.palette != null) await _persistCustomAccent(color);
    });
  }

  Future<void> removeInstalledTheme(ThemePackage package) async {
    if (_skinPackage?.id == package.id &&
        _skinPackage?.version == package.version) {
      await setSkin(AppSkin.originalId);
    }
    if (_colorPackage?.id == package.id &&
        _colorPackage?.version == package.version) {
      await setColorPreset('blue');
    }
    await packageStore.remove(package);
    await reloadInstalledThemes();
  }

  Future<ThemePackage?> _resolveSavedPackage(Object? value) async {
    if (value is! Map || value['id'] is! String || value['version'] is! int) {
      return null;
    }
    return packageStore.findInstalled(
      value['id'] as String,
      version: value['version'] as int,
      allowVersionFallback: false,
    );
  }

  String? _packageSelectionJson() {
    if (_skinPackage == null && _colorPackage == null) return null;
    Map<String, dynamic>? reference(ThemePackage? package) =>
        package == null ? null : {'id': package.id, 'version': package.version};
    return jsonEncode({
      'skin': reference(_skinPackage),
      'palette': reference(_colorPackage),
    });
  }

  Future<void> _persistPackageSelection(String? snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    if (snapshot == null && !prefs.containsKey(_packageSelectionPrefKey)) {
      return;
    }
    final saved = snapshot == null
        ? await prefs.remove(_packageSelectionPrefKey)
        : await prefs.setString(_packageSelectionPrefKey, snapshot);
    if (!saved) throw StateError('Failed to persist theme package selection');
  }

  static AppTheme _packagePalette(ThemePackagePalette palette) {
    Color color(String value) =>
        Color(int.parse(value.substring(1), radix: 16) | 0xff000000);
    return AppThemes.coordinated(
      primary: color(palette.primary),
      secondary: color(palette.secondary),
      tertiary: color(palette.tertiary),
    );
  }

  Future<void> _persistSkin(AppSkin skin) async {
    final prefs = await SharedPreferences.getInstance();
    final bool didPersist;
    if (skin.id == AppSkin.originalId) {
      didPersist = await prefs.remove(_skinPrefKey);
    } else {
      didPersist = await prefs.setString(_skinPrefKey, skin.id);
    }
    if (!didPersist) {
      throw StateError('Failed to persist app skin ${skin.id}.');
    }
  }

  Color _migrateLegacyAccentColor(SharedPreferences prefs) {
    final globalAccent = prefs.getInt(_globalAccentPrefKey);
    if (globalAccent != null) return Color(globalAccent);

    final appThemeName = prefs.getString(_appThemePrefKey);
    final customAccent = prefs.getInt(_customAccentPrefKey);
    if (appThemeName == 'custom' && customAccent != null) {
      return Color(customAccent);
    }
    return AppThemes.accentColorForLegacyTheme(appThemeName);
  }

  Future<void> _removeLegacyThemePreferences(SharedPreferences prefs) async {
    await prefs.remove(_appThemePrefKey);
    await prefs.remove(_customAccentPrefKey);
    await prefs.remove(_globalAccentPrefKey);
    await prefs.remove(_lastPresetThemePrefKey);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();
    _saveThemeMode(mode);
  }

  void _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_themeModePrefKey);
    } else {
      await prefs.setBool(_themeModePrefKey, mode == ThemeMode.dark);
    }
  }

  Future<void> setUiStyle(AppUiStyle style) async {
    if (_uiStyle == style) return;
    _uiStyle = style;
    _syncGlassEffectState();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uiStylePrefKey, style.storageValue);
  }

  Future<void> setGlassEffectsEnabled(bool enabled) {
    return setUiStyle(enabled ? AppUiStyle.glass : AppUiStyle.material3);
  }

  Future<void> setGlassStyle(GlassStyle style) async {
    if (_glassStyle == style) return;
    _glassStyle = style;
    _syncGlassEffectState();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_glassStylePrefKey, style.storageValue);
  }

  Future<void> setLiquidGlassOpacity(
    double value, {
    bool persist = true,
  }) async {
    final opacity = normalizeLiquidGlassOpacity(value);
    if (_liquidGlassOpacity != opacity) {
      _liquidGlassOpacity = opacity;
      _syncGlassEffectState();
      notifyListeners();
    }
    if (!persist) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_liquidGlassOpacityPrefKey, _liquidGlassOpacity);
  }

  void _syncGlassEffectState() {
    GlassEffectConfig.setDisableAllGlassEffects(shouldDisableGlassEffects);
    GlassEffectConfig.setGlassStyle(_glassStyle);
    GlassEffectConfig.setLiquidGlassOpacity(_liquidGlassOpacity);
    GlassEffectConfig.applyPerformanceMode(
      reduceEffects: shouldDisableGlassEffects,
    );
  }
}
