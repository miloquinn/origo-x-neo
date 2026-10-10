// 文件说明：应用主题定义文件，提供协调色套餐与旧版任意强调色兼容。
// 技术要点：Material 3 色板、稳定套餐 ID、历史主题配置迁移。

import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme({
    required this.seedColor,
    required this.lightColorScheme,
    required this.darkColorScheme,
  });

  final Color seedColor;
  final ColorScheme lightColorScheme;
  final ColorScheme darkColorScheme;
}

/// 一套可持久化的完整应用配色。
///
/// [id] 是存储契约，不应随展示文案或本地化变化。
class AppColorPreset {
  const AppColorPreset({required this.id, required this.theme});

  final String id;
  final AppTheme theme;
}

class AppThemes {
  static const Color defaultAccentColor = Color(0xFF1976D2);

  /// 设置页按此稳定顺序展示配色套餐。
  static final List<AppColorPreset> colorPresets = List.unmodifiable([
    AppColorPreset(
      id: 'blue',
      // 保持升级前的默认蓝色完全一致。
      theme: fromAccentColor(defaultAccentColor),
    ),
    AppColorPreset(
      id: 'forest',
      theme: _coordinatedTheme(
        primary: Color(0xFF2E6B4F),
        secondary: Color(0xFF647C43),
        tertiary: Color(0xFF356876),
      ),
    ),
    AppColorPreset(
      id: 'amber',
      theme: _coordinatedTheme(
        primary: Color(0xFFA65A00),
        secondary: Color(0xFF7C621B),
        tertiary: Color(0xFF8A4E55),
      ),
    ),
    AppColorPreset(
      id: 'rose',
      theme: _coordinatedTheme(
        primary: Color(0xFFA63A63),
        secondary: Color(0xFF75565F),
        tertiary: Color(0xFF79536B),
      ),
    ),
    AppColorPreset(
      id: 'violet',
      theme: _coordinatedTheme(
        primary: Color(0xFF6E53A3),
        secondary: Color(0xFF775A80),
        tertiary: Color(0xFF855343),
      ),
    ),
    AppColorPreset(
      id: 'graphite',
      theme: _coordinatedTheme(
        primary: Color(0xFF50616F),
        secondary: Color(0xFF5F5E6A),
        tertiary: Color(0xFF565F55),
      ),
    ),
  ]);

  static AppColorPreset? findColorPreset(String? id) {
    if (id == null) return null;
    for (final preset in colorPresets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static AppTheme fromAccentColor(Color seedColor) {
    return AppTheme(
      seedColor: seedColor,
      lightColorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      darkColorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );
  }

  /// Shared palette contract for validated community theme packages.
  static AppTheme coordinated({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) => _coordinatedTheme(
    primary: primary,
    secondary: secondary,
    tertiary: tertiary,
  );

  static AppTheme _coordinatedTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    return AppTheme(
      seedColor: primary,
      lightColorScheme: _coordinatedScheme(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        brightness: Brightness.light,
      ),
      darkColorScheme: _coordinatedScheme(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        brightness: Brightness.dark,
      ),
    );
  }

  static ColorScheme _coordinatedScheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
    required Brightness brightness,
  }) {
    final primaryScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    final secondaryScheme = ColorScheme.fromSeed(
      seedColor: secondary,
      brightness: brightness,
    );
    final tertiaryScheme = ColorScheme.fromSeed(
      seedColor: tertiary,
      brightness: brightness,
    );
    return primaryScheme.copyWith(
      secondary: secondaryScheme.primary,
      onSecondary: secondaryScheme.onPrimary,
      secondaryContainer: secondaryScheme.primaryContainer,
      onSecondaryContainer: secondaryScheme.onPrimaryContainer,
      secondaryFixed: secondaryScheme.primaryFixed,
      secondaryFixedDim: secondaryScheme.primaryFixedDim,
      onSecondaryFixed: secondaryScheme.onPrimaryFixed,
      onSecondaryFixedVariant: secondaryScheme.onPrimaryFixedVariant,
      tertiary: tertiaryScheme.primary,
      onTertiary: tertiaryScheme.onPrimary,
      tertiaryContainer: tertiaryScheme.primaryContainer,
      onTertiaryContainer: tertiaryScheme.onPrimaryContainer,
      tertiaryFixed: tertiaryScheme.primaryFixed,
      tertiaryFixedDim: tertiaryScheme.primaryFixedDim,
      onTertiaryFixed: tertiaryScheme.onPrimaryFixed,
      onTertiaryFixedVariant: tertiaryScheme.onPrimaryFixedVariant,
    );
  }

  /// 保留旧方法名，避免一次性破坏仍在使用的调用方。
  static AppTheme createCustomTheme(Color seedColor) =>
      fromAccentColor(seedColor);

  /// 将旧版“应用主题”名称折叠为统一强调色，用于首次升级迁移。
  static Color accentColorForLegacyTheme(String? name) {
    return switch (name) {
      'purple' => const Color(0xFF6A4C93),
      'green' => const Color(0xFF2E7D32),
      'orange' => const Color(0xFFFF6F00),
      'red' => const Color(0xFFD32F2F),
      _ => defaultAccentColor,
    };
  }
}
