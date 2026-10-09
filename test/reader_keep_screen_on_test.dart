import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_keep_screen_on.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.niki.xxread/fullscreen');
  final calls = <bool>[];

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setKeepScreenOn') {
            calls.add(
              (call.arguments as Map<Object?, Object?>)['enabled']! as bool,
            );
          }
          return null;
        });
    calls.clear();
    await ReaderKeepScreenOnController.resetForTesting();
  });

  tearDown(() async {
    await ReaderKeepScreenOnController.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    group(platform.name, () {
      setUp(() => debugDefaultTargetPlatformOverride = platform);
      test('applies the saved preference while a reader is active', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ReaderKeepScreenOnController.preferenceKey: true,
        });
        final reader = Object();

        await ReaderKeepScreenOnController.activate(reader);
        await ReaderKeepScreenOnController.deactivate(reader);

        expect(calls, <bool>[true, false]);
      });

      test('preference changes update an active reader immediately', () async {
        final reader = Object();
        await ReaderKeepScreenOnController.activate(reader);

        await ReaderKeepScreenOnController.setPreference(true);
        await ReaderKeepScreenOnController.setPreference(false);

        expect(calls, <bool>[true, false]);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getBool(ReaderKeepScreenOnController.preferenceKey),
          isFalse,
        );
      });

      test('releases the flag only after the last reader exits', () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          ReaderKeepScreenOnController.preferenceKey: true,
        });
        final firstReader = Object();
        final secondReader = Object();

        await ReaderKeepScreenOnController.activate(firstReader);
        await ReaderKeepScreenOnController.activate(secondReader);
        await ReaderKeepScreenOnController.deactivate(firstReader);
        await ReaderKeepScreenOnController.deactivate(secondReader);

        expect(calls, <bool>[true, false]);
      });

      test(
        'reapplies on resume even when the desired state is unchanged',
        () async {
          SharedPreferences.setMockInitialValues(<String, Object>{
            ReaderKeepScreenOnController.preferenceKey: true,
          });
          final reader = Object();
          await ReaderKeepScreenOnController.activate(reader);
          await ReaderKeepScreenOnController.reapply(reader);
          await ReaderKeepScreenOnController.deactivate(reader);
          await ReaderKeepScreenOnController.reapply(reader);

          expect(calls, <bool>[true, true, false]);
        },
      );

      test(
        'enabling outside a reader saves without keeping the screen awake',
        () async {
          await ReaderKeepScreenOnController.setPreference(true);
          expect(calls, isEmpty);
          final prefs = await SharedPreferences.getInstance();
          expect(
            prefs.getBool(ReaderKeepScreenOnController.preferenceKey),
            isTrue,
          );

          final reader = Object();
          await ReaderKeepScreenOnController.activate(reader);
          await ReaderKeepScreenOnController.deactivate(reader);
          expect(calls, <bool>[true, false]);
        },
      );

      test('failed native update is retried on resume', () async {
        var attempts = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'setKeepScreenOn') {
                attempts++;
                if (attempts == 1) {
                  throw PlatformException(code: 'temporarily_unavailable');
                }
                calls.add(
                  (call.arguments as Map<Object?, Object?>)['enabled']! as bool,
                );
              }
              return null;
            });
        SharedPreferences.setMockInitialValues(<String, Object>{
          ReaderKeepScreenOnController.preferenceKey: true,
        });
        final reader = Object();
        await ReaderKeepScreenOnController.activate(reader);
        await ReaderKeepScreenOnController.reapply(reader);
        await ReaderKeepScreenOnController.deactivate(reader);
        expect(attempts, 3);
        expect(calls, <bool>[true, false]);
      });
    });
  }
}
