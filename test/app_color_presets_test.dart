import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/app_themes.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectReadable(Color foreground, Color background, String role) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(4.5),
    reason: '$role must retain normal-text contrast',
  );
}

const _coordinatedRoleSeeds = <String, (Color, Color)>{
  'forest': (Color(0xFF647C43), Color(0xFF356876)),
  'amber': (Color(0xFF7C621B), Color(0xFF8A4E55)),
  'rose': (Color(0xFF75565F), Color(0xFF79536B)),
  'violet': (Color(0xFF775A80), Color(0xFF855343)),
  'graphite': (Color(0xFF5F5E6A), Color(0xFF565F55)),
};

void main() {
  test('color preset IDs and display order are a stable storage contract', () {
    expect(AppThemes.colorPresets.map((preset) => preset.id), [
      'blue',
      'forest',
      'amber',
      'rose',
      'violet',
      'graphite',
    ]);
    expect(
      AppThemes.colorPresets.map((preset) => preset.id).toSet().length,
      AppThemes.colorPresets.length,
    );
    expect(() => AppThemes.colorPresets.clear(), throwsUnsupportedError);
    expect(AppThemes.findColorPreset('forest')?.id, 'forest');
    expect(AppThemes.findColorPreset('missing'), isNull);
    expect(AppThemes.findColorPreset(null), isNull);
  });

  test('blue preset preserves the previous generated default theme', () {
    final original = AppThemes.fromAccentColor(AppThemes.defaultAccentColor);
    final blue = AppThemes.findColorPreset('blue')!;

    expect(blue.theme.seedColor, AppThemes.defaultAccentColor);
    expect(blue.theme.lightColorScheme, original.lightColorScheme);
    expect(blue.theme.darkColorScheme, original.darkColorScheme);
  });

  test('every preset supplies readable coordinated light and dark roles', () {
    for (final preset in AppThemes.colorPresets) {
      for (final scheme in [
        preset.theme.lightColorScheme,
        preset.theme.darkColorScheme,
      ]) {
        final description = '${preset.id}/${scheme.brightness.name}';
        _expectReadable(
          scheme.onPrimary,
          scheme.primary,
          '$description primary',
        );
        _expectReadable(
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
          '$description primaryContainer',
        );
        _expectReadable(
          scheme.onSecondary,
          scheme.secondary,
          '$description secondary',
        );
        _expectReadable(
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
          '$description secondaryContainer',
        );
        _expectReadable(
          scheme.onSecondaryFixed,
          scheme.secondaryFixed,
          '$description secondaryFixed',
        );
        _expectReadable(
          scheme.onSecondaryFixedVariant,
          scheme.secondaryFixedDim,
          '$description secondaryFixedDim',
        );
        _expectReadable(
          scheme.onTertiary,
          scheme.tertiary,
          '$description tertiary',
        );
        _expectReadable(
          scheme.onTertiaryContainer,
          scheme.tertiaryContainer,
          '$description tertiaryContainer',
        );
        _expectReadable(
          scheme.onTertiaryFixed,
          scheme.tertiaryFixed,
          '$description tertiaryFixed',
        );
        _expectReadable(
          scheme.onTertiaryFixedVariant,
          scheme.tertiaryFixedDim,
          '$description tertiaryFixedDim',
        );
        _expectReadable(
          scheme.onSurface,
          scheme.surface,
          '$description surface',
        );
      }
    }
  });

  test('non-default presets coordinate three intentionally distinct roles', () {
    for (final preset in AppThemes.colorPresets.skip(1)) {
      for (final scheme in [
        preset.theme.lightColorScheme,
        preset.theme.darkColorScheme,
      ]) {
        expect(
          {scheme.primary, scheme.secondary, scheme.tertiary}.length,
          3,
          reason: '${preset.id}/${scheme.brightness.name}',
        );
      }
    }
  });

  test('fixed secondary and tertiary families use their coordinated seeds', () {
    for (final preset in AppThemes.colorPresets.skip(1)) {
      final (secondarySeed, tertiarySeed) = _coordinatedRoleSeeds[preset.id]!;
      for (final scheme in [
        preset.theme.lightColorScheme,
        preset.theme.darkColorScheme,
      ]) {
        final secondaryScheme = ColorScheme.fromSeed(
          seedColor: secondarySeed,
          brightness: scheme.brightness,
        );
        final tertiaryScheme = ColorScheme.fromSeed(
          seedColor: tertiarySeed,
          brightness: scheme.brightness,
        );

        expect(scheme.secondaryFixed, secondaryScheme.primaryFixed);
        expect(scheme.secondaryFixedDim, secondaryScheme.primaryFixedDim);
        expect(scheme.onSecondaryFixed, secondaryScheme.onPrimaryFixed);
        expect(
          scheme.onSecondaryFixedVariant,
          secondaryScheme.onPrimaryFixedVariant,
        );
        expect(scheme.tertiaryFixed, tertiaryScheme.primaryFixed);
        expect(scheme.tertiaryFixedDim, tertiaryScheme.primaryFixedDim);
        expect(scheme.onTertiaryFixed, tertiaryScheme.onPrimaryFixed);
        expect(
          scheme.onTertiaryFixedVariant,
          tertiaryScheme.onPrimaryFixedVariant,
        );
      }
    }
  });
}
