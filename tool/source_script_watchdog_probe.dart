// Run inside a disposable Android app that path-depends on this repository.
// The probe has no account, registry, network or persistent reader data.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:xxread/book_sources/protocol/book_source_protocol.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/scripting/source_script_engine.dart';

const _infinite = bool.fromEnvironment('ORIGO_PROBE_INFINITE');

void main() {
  runApp(const MaterialApp(home: _Probe()));
}

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _results = <String>[];
  var _taps = 0;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.delayed(const Duration(seconds: 1), _run));
  }

  void _record(String message) {
    // ignore: avoid_print
    print('ORIGO_WATCHDOG_PROBE $message');
    if (mounted) setState(() => _results.add(message));
  }

  Future<void> _run() async {
    final source = ReadingSourceConfig.fromJson({
      'bookSourceName': 'Native watchdog probe',
      'bookSourceUrl': 'https://probe.invalid',
    });
    final evaluator = QuickJsSourceScriptEvaluator();
    try {
      final unguarded = QuickJsSourceScriptEvaluator(
        runtime: QuickJsRuntime2(timeout: 500),
      );
      final baseline = Stopwatch()..start();
      try {
        unguarded.evaluate(
          'const start = Date.now(); while (Date.now() - start < 1500) {}',
          SourceScriptContext(source: source),
        );
        _record('upstream baseline: ${baseline.elapsedMilliseconds}ms');
      } finally {
        unguarded.dispose();
      }
      final expectedHosts = JavascriptRuntime.channelFunctionsRegistered.length;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      for (final promise in [false, true]) {
        final context = SourceScriptContext(
          source: source,
          htmlBridge: promise,
        );
        final script = _infinite
            ? 'while (true) {}'
            : 'const start = Date.now(); while (Date.now() - start < 1500) {}';
        final stopwatch = Stopwatch()..start();
        var interrupted = false;
        try {
          if (promise) {
            await evaluator.evaluateAsync(
              'Promise.resolve().then(() => { $script })',
              context,
            );
          } else {
            evaluator.evaluate(script, context);
          }
        } on BookSourceProtocolException catch (error) {
          interrupted = error.message.contains('execution time limit');
        }
        stopwatch.stop();
        _record(
          '${promise ? "promise" : "sync"}: '
          '${interrupted ? "PASS" : "FAIL"} ${stopwatch.elapsedMilliseconds}ms',
        );
        final recovery = await evaluator.evaluateAsync('6 * 7', context);
        _record('recovery: ${recovery == 42 ? "PASS" : "FAIL"}');
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      // The plugin's job dispatcher drains a queue synchronously. A chain of
      // individually tiny jobs must share one deadline for the whole drain.
      if (_infinite) {
        final stopwatch = Stopwatch()..start();
        try {
          await evaluator.evaluateAsync(
            'new Promise(() => { function spin() { Promise.resolve().then(spin); } spin(); })',
            SourceScriptContext(source: source, htmlBridge: true),
          );
          _record('microtask chain: FAIL');
        } on BookSourceProtocolException catch (error) {
          _record(
            'microtask chain: ${error.message.contains("execution time limit") ? "PASS" : "FAIL"} '
            '${stopwatch.elapsedMilliseconds}ms',
          );
        }
        _record(
          'chain recovery: ${await evaluator.evaluateAsync("40 + 2", SourceScriptContext(source: source)) == 42 ? "PASS" : "FAIL"}',
        );
        final timerWatch = Stopwatch()..start();
        try {
          await evaluator.evaluateAsync(
            'new Promise(() => setTimeout(() => { while (true) {} }, 0))',
            SourceScriptContext(source: source, htmlBridge: true),
          );
          _record('timer: FAIL');
        } on BookSourceProtocolException catch (error) {
          _record(
            'timer: ${error.message.contains("execution time limit") ? "PASS" : "FAIL"} '
            '${timerWatch.elapsedMilliseconds}ms',
          );
        }
        _record(
          'timer recovery: ${await evaluator.evaluateAsync("42", SourceScriptContext(source: source)) == 42 ? "PASS" : "FAIL"}',
        );
        try {
          evaluator.evaluate(
            "setTimeout(() => java.put('staleTimer', 'written'), 1000); while (true) {}",
            SourceScriptContext(source: source),
          );
        } on BookSourceProtocolException {
          // Replacement must cancel the old timer before it can call FFI.
        }
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        _record(
          'stale timer: ${await evaluator.evaluateAsync("java.get('staleTimer')", SourceScriptContext(source: source)) == '' ? "PASS" : "FAIL"}',
        );
      }
      _record(
        'host callbacks: ${JavascriptRuntime.channelFunctionsRegistered.length == expectedHosts ? "PASS" : "FAIL"}',
      );
      _record('DONE');
    } catch (error, stack) {
      _record('ERROR $error\n$stack');
    } finally {
      evaluator.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Source watchdog probe')),
    body: Column(
      children: [
        for (final message in _results) Text(message),
        FilledButton(
          onPressed: () => setState(() => _taps++),
          child: Text('Touch response $_taps'),
        ),
      ],
    ),
  );
}
