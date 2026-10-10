import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:xxread/models/app_skin.dart';
import 'package:xxread/services/core/theme_notifier.dart';
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

  late AppSkin ocean;
  late AppSkinCatalog catalog;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ocean = AppSkin(id: 'ocean');
    catalog = AppSkinCatalog([ocean]);
  });

  test('defaults to original and exposes the injected catalog', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    addTearDown(notifier.dispose);

    expect(notifier.currentSkin, same(AppSkin.original));
    expect(notifier.skinTheme.skin, same(AppSkin.original));
    expect(notifier.availableSkins, [AppSkin.original, ocean]);
  });

  test('selected skin persists and restores from the same catalog', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    await notifier.setSkin('ocean');
    expect(notifier.currentSkin, same(ocean));
    expect(
      (await SharedPreferences.getInstance()).getString('appSkinIdV1'),
      'ocean',
    );
    notifier.dispose();

    final restored = await _loadNotifier(catalog: catalog);
    addTearDown(restored.dispose);
    expect(restored.currentSkin, same(ocean));

    await restored.setSkin(AppSkin.originalId);
    expect(restored.currentSkin, same(AppSkin.original));
    expect(
      (await SharedPreferences.getInstance()).containsKey('appSkinIdV1'),
      isFalse,
    );
  });

  test(
    'removed saved skin falls back and clears its stale preference',
    () async {
      SharedPreferences.setMockInitialValues({'appSkinIdV1': 'removed'});

      final notifier = await _loadNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.currentSkin, same(AppSkin.original));
      expect(
        (await SharedPreferences.getInstance()).containsKey('appSkinIdV1'),
        isFalse,
      );
    },
  );

  test(
    'switching skin preserves all existing appearance and reader state',
    () async {
      const accent = Color(0xFF7B2CBF);
      SharedPreferences.setMockInitialValues({
        'isDarkMode': true,
        'appAccentColorV2': accent.toARGB32(),
        'ui_style_mode': 'glass',
        'glass_style_mode': 'frosted',
        'liquid_glass_opacity': 0.73,
        'readerTheme': 'paper',
      });
      final notifier = await _loadNotifier(catalog: catalog);
      addTearDown(notifier.dispose);

      await notifier.setSkin('ocean');

      expect(notifier.themeMode, ThemeMode.dark);
      expect(notifier.accentColor, accent);
      expect(notifier.uiStyle, AppUiStyle.glass);
      expect(notifier.glassStyle, GlassStyle.frosted);
      expect(notifier.liquidGlassOpacity, 0.73);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('readerTheme'), 'paper');
      expect(prefs.getString('appSkinIdV1'), 'ocean');
      expect(prefs.getString('ui_style_mode'), 'glass');
      expect(prefs.getString('glass_style_mode'), 'frosted');
      expect(prefs.getDouble('liquid_glass_opacity'), 0.73);
    },
  );

  test('unknown requested skin rejects without changing state', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    addTearDown(notifier.dispose);
    var notificationCount = 0;
    notifier.addListener(() => notificationCount++);

    await expectLater(notifier.setSkin('missing'), throwsArgumentError);

    expect(notifier.currentSkin, same(AppSkin.original));
    expect(notificationCount, 0);
    expect(
      (await SharedPreferences.getInstance()).containsKey('appSkinIdV1'),
      isFalse,
    );
  });

  test('rapid concurrent switches persist the last requested skin', () async {
    final forest = AppSkin(id: 'forest');
    final concurrentCatalog = AppSkinCatalog([ocean, forest]);
    final notifier = await _loadNotifier(catalog: concurrentCatalog);

    await Future.wait([
      notifier.setSkin('ocean'),
      notifier.setSkin('forest'),
      notifier.setSkin(AppSkin.originalId),
      notifier.setSkin('ocean'),
    ]);

    expect(notifier.currentSkin, same(ocean));
    expect(
      (await SharedPreferences.getInstance()).getString('appSkinIdV1'),
      'ocean',
    );
    notifier.dispose();

    final restored = await _loadNotifier(catalog: concurrentCatalog);
    addTearDown(restored.dispose);
    expect(restored.currentSkin.id, 'ocean');
  });

  test(
    'a thrown write reaches its caller but does not poison later writes',
    () async {
      final forest = AppSkin(id: 'forest');
      final recoveryCatalog = AppSkinCatalog([ocean, forest]);
      final notifier = await _loadNotifier(catalog: recoveryCatalog);
      addTearDown(notifier.dispose);
      final store = _ControlledPreferencesStore(
        onSet: (call, valueType, key, value) async {
          if (call == 1) throw StateError('simulated write failure');
          return true;
        },
      );
      SharedPreferencesStorePlatform.instance = store;

      await expectLater(notifier.setSkin('ocean'), throwsA(isA<StateError>()));
      await notifier.setSkin('forest');

      expect(notifier.currentSkin, same(forest));
      expect(store.setCalls, 2);
      expect((await store.getAll())['flutter.appSkinIdV1'], 'forest');
    },
  );

  test('a false result fails and a same-id retry writes again', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    addTearDown(notifier.dispose);
    final store = _ControlledPreferencesStore(
      onSet: (call, valueType, key, value) async => call != 1,
    );
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(notifier.setSkin('ocean'), throwsA(isA<StateError>()));
    await notifier.setSkin('ocean');

    expect(notifier.currentSkin, same(ocean));
    expect(store.setCalls, 2);
    expect((await store.getAll())['flutter.appSkinIdV1'], 'ocean');
  });

  test('same-id concurrent call waits for its queued persistence', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    addTearDown(notifier.dispose);
    final firstGate = Completer<bool>();
    final secondGate = Completer<bool>();
    final store = _ControlledPreferencesStore(
      onSet: (call, valueType, key, value) =>
          call == 1 ? firstGate.future : secondGate.future,
    );
    SharedPreferencesStorePlatform.instance = store;

    var firstCompleted = false;
    var secondCompleted = false;
    final first = notifier
        .setSkin('ocean')
        .whenComplete(() => firstCompleted = true);
    final second = notifier
        .setSkin('ocean')
        .whenComplete(() => secondCompleted = true);
    await Future<void>.delayed(Duration.zero);

    expect(store.setCalls, 1);
    expect(firstCompleted, isFalse);
    expect(secondCompleted, isFalse);

    firstGate.complete(true);
    await first;
    await Future<void>.delayed(Duration.zero);
    expect(store.setCalls, 2);
    expect(firstCompleted, isTrue);
    expect(secondCompleted, isFalse);

    secondGate.complete(true);
    await second;
    expect(secondCompleted, isTrue);
    expect((await store.getAll())['flutter.appSkinIdV1'], 'ocean');
  });

  test('a false original removal is reported and can be retried', () async {
    final notifier = await _loadNotifier(catalog: catalog);
    await notifier.setSkin('ocean');
    addTearDown(notifier.dispose);
    final store = _ControlledPreferencesStore(
      initialValues: const {'flutter.appSkinIdV1': 'ocean'},
      onRemove: (call, key) async => call != 1,
    );
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(
      notifier.setSkin(AppSkin.originalId),
      throwsA(isA<StateError>()),
    );
    await notifier.setSkin(AppSkin.originalId);

    expect(notifier.currentSkin, same(AppSkin.original));
    expect(store.removeCalls, 2);
    expect((await store.getAll()), isNot(contains('flutter.appSkinIdV1')));
  });
}
