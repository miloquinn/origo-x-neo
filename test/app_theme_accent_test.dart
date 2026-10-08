import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'defaults to one accent seed that generates both color schemes',
    () async {
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.accentColor, AppThemes.defaultAccentColor);
      expect(notifier.liquidGlassOpacity, 0.5);
      expect(
        notifier.currentAppTheme.lightColorScheme,
        ColorScheme.fromSeed(
          seedColor: AppThemes.defaultAccentColor,
          brightness: Brightness.light,
        ),
      );
      expect(
        notifier.currentAppTheme.darkColorScheme,
        ColorScheme.fromSeed(
          seedColor: AppThemes.defaultAccentColor,
          brightness: Brightness.dark,
        ),
      );
    },
  );

  test(
    'setting an accent persists the unified value and clears legacy keys',
    () async {
      SharedPreferences.setMockInitialValues({
        'appTheme': 'green',
        'globalAccentColor': const Color(0xFF445566).toARGB32(),
        'customAccentColor': const Color(0xFF112233).toARGB32(),
        'last_preset_app_theme': 'green',
      });
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      const selected = Color(0xFF8A3FFC);
      await notifier.setAccentColor(selected);

      final prefs = await SharedPreferences.getInstance();
      expect(notifier.accentColor, selected);
      expect(prefs.getInt('appAccentColorV2'), selected.toARGB32());
      expect(prefs.containsKey('appTheme'), isFalse);
      expect(prefs.containsKey('globalAccentColor'), isFalse);
      expect(prefs.containsKey('customAccentColor'), isFalse);
      expect(prefs.containsKey('last_preset_app_theme'), isFalse);
    },
  );

  test(
    'migration prefers the old global accent over the old app theme',
    () async {
      const legacyAccent = Color(0xFF123456);
      SharedPreferences.setMockInitialValues({
        'appTheme': 'red',
        'globalAccentColor': legacyAccent.toARGB32(),
      });

      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      final prefs = await SharedPreferences.getInstance();
      expect(notifier.accentColor, legacyAccent);
      expect(prefs.getInt('appAccentColorV2'), legacyAccent.toARGB32());
      expect(prefs.containsKey('appTheme'), isFalse);
      expect(prefs.containsKey('globalAccentColor'), isFalse);
    },
  );

  test('migration keeps custom theme colors and maps named themes', () async {
    const legacyCustom = Color(0xFF654321);
    SharedPreferences.setMockInitialValues({
      'appTheme': 'custom',
      'customAccentColor': legacyCustom.toARGB32(),
    });
    final customNotifier = await _loadNotifier();
    expect(customNotifier.accentColor, legacyCustom);
    customNotifier.dispose();

    SharedPreferences.setMockInitialValues({'appTheme': 'purple'});
    final namedNotifier = await _loadNotifier();
    addTearDown(namedNotifier.dispose);
    expect(
      namedNotifier.accentColor,
      AppThemes.accentColorForLegacyTheme('purple'),
    );
  });

  test('missing glass style keeps the existing glass UI style', () async {
    SharedPreferences.setMockInitialValues({'ui_style_mode': 'glass'});

    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    expect(notifier.uiStyle, AppUiStyle.glass);
    expect(notifier.glassStyle, GlassStyle.liquid);
    expect(GlassStyle.fromStorage('unknown'), GlassStyle.liquid);
  });

  test('glass style persists across notifier recreation', () async {
    SharedPreferences.setMockInitialValues({'glass_style_mode': 'frosted'});
    final notifier = await _loadNotifier();
    await notifier.setGlassStyle(GlassStyle.liquid);
    notifier.dispose();

    final restored = await _loadNotifier();
    addTearDown(restored.dispose);

    expect(restored.glassStyle, GlassStyle.liquid);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('glass_style_mode'), 'liquid');
  });

  test('disabling and re-enabling glass remembers its style', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    await notifier.setGlassStyle(GlassStyle.liquid);
    await notifier.setLiquidGlassOpacity(0.64);
    await notifier.setGlassEffectsEnabled(false);
    expect(notifier.uiStyle, AppUiStyle.material3);
    expect(notifier.glassStyle, GlassStyle.liquid);
    expect(notifier.liquidGlassOpacity, 0.64);

    await notifier.setGlassEffectsEnabled(true);
    expect(notifier.uiStyle, AppUiStyle.glass);
    expect(notifier.glassStyle, GlassStyle.liquid);
    expect(notifier.liquidGlassOpacity, 0.64);
  });

  test('liquid opacity persists across notifier recreation', () async {
    final notifier = await _loadNotifier();
    await notifier.setLiquidGlassOpacity(0.57);
    notifier.dispose();

    final restored = await _loadNotifier();
    addTearDown(restored.dispose);

    expect(restored.liquidGlassOpacity, 0.57);
  });

  test('invalid stored liquid opacity normalizes to a safe value', () async {
    final cases = <Object?, double>{
      null: 0.5,
      'invalid': 0.5,
      double.nan: 0,
      -0.4: 0,
      1.4: 1,
    };

    for (final entry in cases.entries) {
      SharedPreferences.setMockInitialValues({
        if (entry.key != null) 'liquid_glass_opacity': entry.key!,
      });
      final notifier = await _loadNotifier();
      expect(
        notifier.liquidGlassOpacity,
        entry.value,
        reason: 'stored value ${entry.key}',
      );
      notifier.dispose();
    }
  });

  test(
    'preview updates immediately and the matching final value persists',
    () async {
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      await notifier.setLiquidGlassOpacity(0.62, persist: false);
      var prefs = await SharedPreferences.getInstance();
      expect(notifier.liquidGlassOpacity, 0.62);
      expect(prefs.containsKey('liquid_glass_opacity'), isFalse);

      await notifier.setLiquidGlassOpacity(0.62);
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('liquid_glass_opacity'), 0.62);
    },
  );

  test('rapid concurrent opacity setters persist the final value', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);

    await Future.wait([
      notifier.setLiquidGlassOpacity(0.2),
      notifier.setLiquidGlassOpacity(0.7),
      notifier.setLiquidGlassOpacity(0.91),
    ]);

    final prefs = await SharedPreferences.getInstance();
    expect(notifier.liquidGlassOpacity, 0.91);
    expect(prefs.getDouble('liquid_glass_opacity'), 0.91);
  });
}
