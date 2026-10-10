import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/services/core/theme_notifier.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/ui_style.dart';

Future<ThemeNotifier> _loadNotifier({AppSkinCatalog? catalog}) async {
  final notifier = ThemeNotifier(skinCatalog: catalog);
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

typedef _SetBehavior =
    Future<bool> Function(int call, String valueType, String key, Object value);
typedef _RemoveBehavior = Future<bool> Function(int call, String key);

final class _ControlledPreferencesStore extends InMemorySharedPreferencesStore {
  _ControlledPreferencesStore({
    Map<String, Object> initialValues = const {},
    this.onSet,
    this.onRemove,
  }) : super.withData(initialValues);

  final _SetBehavior? onSet;
  final _RemoveBehavior? onRemove;
  int setCalls = 0;
  int removeCalls = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    setCalls += 1;
    final accepted = await onSet?.call(setCalls, valueType, key, value) ?? true;
    if (!accepted) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    removeCalls += 1;
    final accepted = await onRemove?.call(removeCalls, key) ?? true;
    if (!accepted) return false;
    return super.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('fresh installs start on and persist the default blue preset', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);
    final blue = AppThemes.findColorPreset('blue')!;
    final prefs = await SharedPreferences.getInstance();

    expect(notifier.currentColorPreset, same(blue));
    expect(notifier.currentAppTheme, same(blue.theme));
    expect(notifier.accentColor, AppThemes.defaultAccentColor);
    expect(prefs.getString('appColorPresetIdV1'), 'blue');
  });

  test('stored default accent migrates to the identical blue preset', () async {
    SharedPreferences.setMockInitialValues({
      'appAccentColorV2': AppThemes.defaultAccentColor.toARGB32(),
    });

    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);
    final original = AppThemes.fromAccentColor(AppThemes.defaultAccentColor);
    final prefs = await SharedPreferences.getInstance();

    expect(notifier.currentColorPreset?.id, 'blue');
    expect(
      notifier.currentAppTheme.lightColorScheme,
      original.lightColorScheme,
    );
    expect(notifier.currentAppTheme.darkColorScheme, original.darkColorScheme);
    expect(prefs.getString('appColorPresetIdV1'), 'blue');
  });

  test(
    'legacy arbitrary accent remains custom until a preset is chosen',
    () async {
      const legacyAccent = Color(0xFF315A76);
      SharedPreferences.setMockInitialValues({
        'appAccentColorV2': legacyAccent.toARGB32(),
      });

      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.currentColorPreset, isNull);
      expect(notifier.accentColor, legacyAccent);
      expect(
        notifier.currentAppTheme.lightColorScheme,
        AppThemes.fromAccentColor(legacyAccent).lightColorScheme,
      );
    },
  );

  test(
    'valid preset restores its complete theme and remains independent',
    () async {
      final ocean = AppSkin(id: 'ocean');
      SharedPreferences.setMockInitialValues({
        'appColorPresetIdV1': 'forest',
        'appAccentColorV2': const Color(0xFF112233).toARGB32(),
        'appSkinIdV1': 'ocean',
        'ui_style_mode': 'glass',
        'glass_style_mode': 'frosted',
        'readerTheme': 'paper',
      });

      final notifier = await _loadNotifier(catalog: AppSkinCatalog([ocean]));
      addTearDown(notifier.dispose);
      final forest = AppThemes.findColorPreset('forest')!;

      expect(notifier.currentColorPreset, same(forest));
      expect(notifier.currentAppTheme, same(forest.theme));
      expect(notifier.accentColor, forest.theme.seedColor);
      expect(notifier.currentSkin, same(ocean));
      expect(notifier.uiStyle, AppUiStyle.glass);
      expect(notifier.glassStyle, GlassStyle.frosted);
      expect(
        (await SharedPreferences.getInstance()).getString('readerTheme'),
        'paper',
      );
    },
  );

  test(
    'stale preset ID is removed without replacing the stored accent',
    () async {
      const storedAccent = Color(0xFF4C6072);
      SharedPreferences.setMockInitialValues({
        'appColorPresetIdV1': 'removed-preset',
        'appAccentColorV2': storedAccent.toARGB32(),
      });

      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);
      final prefs = await SharedPreferences.getInstance();

      expect(notifier.currentColorPreset, isNull);
      expect(notifier.accentColor, storedAccent);
      expect(prefs.containsKey('appColorPresetIdV1'), isFalse);
      expect(prefs.getInt('appAccentColorV2'), storedAccent.toARGB32());
    },
  );

  test('selecting and restoring a preset persists its stable ID', () async {
    final notifier = await _loadNotifier();
    await notifier.setColorPreset('violet');
    final violet = AppThemes.findColorPreset('violet')!;
    expect(notifier.currentColorPreset, same(violet));
    expect(notifier.currentAppTheme, same(violet.theme));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appColorPresetIdV1'), 'violet');
    expect(prefs.getInt('appAccentColorV2'), violet.theme.seedColor.toARGB32());
    notifier.dispose();

    final restored = await _loadNotifier();
    addTearDown(restored.dispose);
    expect(restored.currentColorPreset?.id, 'violet');
    expect(restored.currentAppTheme, same(violet.theme));
  });

  test(
    'setting an arbitrary accent exits and clears a selected preset',
    () async {
      final notifier = await _loadNotifier();
      await notifier.setColorPreset('blue');
      const custom = Color(0xFF6C4F3D);

      await notifier.setAccentColor(custom);

      expect(notifier.currentColorPreset, isNull);
      expect(notifier.accentColor, custom);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('appColorPresetIdV1'), isFalse);
      expect(prefs.getInt('appAccentColorV2'), custom.toARGB32());
    },
  );

  test('unknown preset rejects without changing state or storage', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);
    final initialPreset = notifier.currentColorPreset;
    final initialStoredId = (await SharedPreferences.getInstance()).getString(
      'appColorPresetIdV1',
    );
    var notifications = 0;
    notifier.addListener(() => notifications += 1);

    await expectLater(notifier.setColorPreset('missing'), throwsArgumentError);

    expect(notifier.currentColorPreset, same(initialPreset));
    expect(notifications, 0);
    expect(
      (await SharedPreferences.getInstance()).getString('appColorPresetIdV1'),
      initialStoredId,
    );
  });

  test(
    'rapid concurrent selections persist the final requested preset',
    () async {
      final notifier = await _loadNotifier();

      await Future.wait([
        notifier.setColorPreset('forest'),
        notifier.setColorPreset('amber'),
        notifier.setColorPreset('rose'),
        notifier.setColorPreset('graphite'),
      ]);

      expect(notifier.currentColorPreset?.id, 'graphite');
      expect(
        (await SharedPreferences.getInstance()).getString('appColorPresetIdV1'),
        'graphite',
      );
      notifier.dispose();

      final restored = await _loadNotifier();
      addTearDown(restored.dispose);
      expect(restored.currentColorPreset?.id, 'graphite');
    },
  );

  test(
    'thrown preset write reaches caller without poisoning later writes',
    () async {
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);
      var presetWrites = 0;
      final store = _ControlledPreferencesStore(
        onSet: (call, valueType, key, value) async {
          if (key == 'flutter.appColorPresetIdV1') {
            presetWrites += 1;
            if (presetWrites == 1) throw StateError('simulated failure');
          }
          return true;
        },
      );
      SharedPreferencesStorePlatform.instance = store;

      await expectLater(
        notifier.setColorPreset('forest'),
        throwsA(isA<StateError>()),
      );
      await notifier.setColorPreset('rose');

      expect(notifier.currentColorPreset?.id, 'rose');
      expect(presetWrites, 2);
      expect((await store.getAll())['flutter.appColorPresetIdV1'], 'rose');
    },
  );

  test('false preset result fails and the same ID retries its write', () async {
    final notifier = await _loadNotifier();
    addTearDown(notifier.dispose);
    var presetWrites = 0;
    final store = _ControlledPreferencesStore(
      onSet: (call, valueType, key, value) async {
        if (key != 'flutter.appColorPresetIdV1') return true;
        presetWrites += 1;
        return presetWrites != 1;
      },
    );
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(
      notifier.setColorPreset('forest'),
      throwsA(isA<StateError>()),
    );
    await notifier.setColorPreset('forest');

    expect(presetWrites, 2);
    expect((await store.getAll())['flutter.appColorPresetIdV1'], 'forest');
  });

  test(
    'same-ID concurrent call waits for its own ordered persistence',
    () async {
      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);
      final firstGate = Completer<bool>();
      final secondGate = Completer<bool>();
      var presetWrites = 0;
      final store = _ControlledPreferencesStore(
        onSet: (call, valueType, key, value) {
          if (key != 'flutter.appColorPresetIdV1') return Future.value(true);
          presetWrites += 1;
          return presetWrites == 1 ? firstGate.future : secondGate.future;
        },
      );
      SharedPreferencesStorePlatform.instance = store;

      var firstCompleted = false;
      var secondCompleted = false;
      final first = notifier
          .setColorPreset('amber')
          .whenComplete(() => firstCompleted = true);
      final second = notifier
          .setColorPreset('amber')
          .whenComplete(() => secondCompleted = true);
      await Future<void>.delayed(Duration.zero);

      expect(presetWrites, 1);
      expect(firstCompleted, isFalse);
      expect(secondCompleted, isFalse);

      firstGate.complete(true);
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(presetWrites, 2);
      expect(firstCompleted, isTrue);
      expect(secondCompleted, isFalse);

      secondGate.complete(true);
      await second;
      expect(secondCompleted, isTrue);
    },
  );

  test(
    'failed preset removal is reported and a custom retry succeeds',
    () async {
      final notifier = await _loadNotifier();
      await notifier.setColorPreset('blue');
      addTearDown(notifier.dispose);
      final blue = AppThemes.findColorPreset('blue')!;
      var presetRemovals = 0;
      final store = _ControlledPreferencesStore(
        initialValues: {
          'flutter.appColorPresetIdV1': 'blue',
          'flutter.appAccentColorV2': blue.theme.seedColor.toARGB32(),
        },
        onRemove: (call, key) async {
          if (key != 'flutter.appColorPresetIdV1') return true;
          presetRemovals += 1;
          return presetRemovals != 1;
        },
      );
      SharedPreferencesStorePlatform.instance = store;

      await expectLater(
        notifier.setAccentColor(blue.theme.seedColor),
        throwsA(isA<StateError>()),
      );
      await notifier.setAccentColor(blue.theme.seedColor);

      expect(notifier.currentColorPreset, isNull);
      expect(presetRemovals, 2);
      expect(
        (await store.getAll()),
        isNot(contains('flutter.appColorPresetIdV1')),
      );
    },
  );
}
