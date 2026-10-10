import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/core/app_settings_service.dart';

Future<AppSettingsNotifier> _loadSettings() async {
  final settings = AppSettingsNotifier();
  addTearDown(settings.dispose);
  if (settings.isInitialized) return settings;

  final initialized = Completer<void>();
  void listener() {
    if (settings.isInitialized && !initialized.isCompleted) {
      initialized.complete();
    }
  }

  settings.addListener(listener);
  listener();
  await initialized.future;
  settings.removeListener(listener);
  return settings;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory supportDirectory;

  setUpAll(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'library_organization_settings_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, (
      call,
    ) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return supportDirectory.path;
      }
      throw MissingPluginException(
        'Unexpected path_provider method: ${call.method}',
      );
    });
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'library organization preserves recent additions as the default',
    () async {
      final settings = await _loadSettings();

      expect(settings.librarySortMode, LibrarySortMode.recentAdded);
      expect(settings.librarySortDescending, isTrue);
    },
  );

  for (final invalidMode in ['unknown-mode', '', 'RECENTREAD']) {
    test(
      'invalid saved mode "$invalidMode" falls back to recent additions',
      () async {
        SharedPreferences.setMockInitialValues({
          'library_sort_mode_v1': invalidMode,
        });
        final settings = await _loadSettings();

        expect(settings.librarySortMode, LibrarySortMode.recentAdded);
        expect(settings.librarySortDescending, isTrue);
      },
    );
  }

  test(
    'invalid mode fallback retains a valid saved ascending direction',
    () async {
      SharedPreferences.setMockInitialValues({
        'library_sort_mode_v1': 'removed-mode',
        'library_sort_descending_v1': false,
      });
      final settings = await _loadSettings();

      expect(settings.librarySortMode, LibrarySortMode.recentAdded);
      expect(settings.librarySortDescending, isFalse);
    },
  );

  for (final mode in LibrarySortMode.values) {
    for (final descending in [true, false]) {
      test(
        '${mode.name} direction $descending persists across new instances',
        () async {
          final settings = await _loadSettings();
          // Move away from the default first, so every case verifies a save.
          await settings.setLibrarySort(
            LibrarySortMode.progress,
            descending: !descending,
          );

          await settings.setLibrarySort(mode, descending: descending);

          expect(settings.librarySortMode, mode);
          expect(settings.librarySortDescending, descending);
          final preferences = await SharedPreferences.getInstance();
          expect(preferences.getString('library_sort_mode_v1'), mode.name);
          expect(preferences.getBool('library_sort_descending_v1'), descending);

          final restored = await _loadSettings();
          expect(restored.librarySortMode, mode);
          expect(restored.librarySortDescending, descending);
        },
      );
    }
  }

  test(
    'changing direction updates listeners and reselecting is idempotent',
    () async {
      final settings = await _loadSettings();
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setLibrarySort(
        LibrarySortMode.recentAdded,
        descending: false,
      );
      expect(notifications, 1);
      await settings.setLibrarySort(
        LibrarySortMode.recentAdded,
        descending: false,
      );
      expect(notifications, 1);

      final restored = await _loadSettings();
      expect(restored.librarySortMode, LibrarySortMode.recentAdded);
      expect(restored.librarySortDescending, isFalse);
    },
  );
}
