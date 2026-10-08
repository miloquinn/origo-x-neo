import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/utils/system_ui_helper.dart';
import 'package:xxread/widgets/page_system_ui.dart';

void main() {
  testWidgets(
    'system UI follows current route, brightness, and foreground ownership',
    (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('SystemChrome.')) calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      addTearDown(() {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      final brightness = ValueNotifier(Brightness.light);
      addTearDown(brightness.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<Brightness>(
            valueListenable: brightness,
            builder: (context, value, child) => PageSystemUi(
              brightness: value,
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiHelper.overlayStyleForBrightness(value),
                child: const Scaffold(body: Text('home')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_methodCount(calls, 'SystemChrome.setEnabledSystemUIMode'), 1);
      expect(_methodCount(calls, 'SystemChrome.setSystemUIOverlayStyle'), 1);
      expect(
        SystemChrome.latestStyle,
        SystemUiHelper.overlayStyleForBrightness(Brightness.light),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('cover')),
        ),
      );
      await tester.pumpAndSettle();
      calls.clear();

      brightness.value = Brightness.dark;
      await tester.pump();
      expect(calls, isEmpty);

      navigator.pop();
      await tester.pumpAndSettle();
      expect(_methodCount(calls, 'SystemChrome.setEnabledSystemUIMode'), 1);
      expect(_methodCount(calls, 'SystemChrome.setSystemUIOverlayStyle'), 1);
      expect(
        SystemChrome.latestStyle,
        SystemUiHelper.overlayStyleForBrightness(Brightness.dark),
      );

      calls.clear();
      brightness.value = Brightness.light;
      await tester.pump();
      expect(_methodCount(calls, 'SystemChrome.setEnabledSystemUIMode'), 0);
      expect(_methodCount(calls, 'SystemChrome.setSystemUIOverlayStyle'), 1);
      expect(
        SystemChrome.latestStyle,
        SystemUiHelper.overlayStyleForBrightness(Brightness.light),
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiHelper.overlayStyleForBrightness(Brightness.dark),
      );
      await tester.pump();
      calls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(_methodCount(calls, 'SystemChrome.setEnabledSystemUIMode'), 1);
      expect(_methodCount(calls, 'SystemChrome.setSystemUIOverlayStyle'), 1);
    },
  );
}

int _methodCount(List<MethodCall> calls, String method) =>
    calls.where((call) => call.method == method).length;
