import 'dart:async';
import 'dart:ffi';

import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_js/quickjs/ffi.dart' show JSRuntime, runtimeOpaques;

import '../../protocol/book_source_protocol.dart';

typedef _InterruptNative = Int32 Function(Pointer<JSRuntime>, Pointer<Void>);
typedef _SetInterruptNative =
    Void Function(
      Pointer<JSRuntime>,
      Pointer<NativeFunction<_InterruptNative>>,
      Pointer<Void>,
    );
typedef _SetInterrupt =
    void Function(
      Pointer<JSRuntime>,
      Pointer<NativeFunction<_InterruptNative>>,
      Pointer<Void>,
    );

class SourceScriptExecutionTimeout extends BookSourceProtocolException {
  const SourceScriptExecutionTimeout()
    : super('Reading source JavaScript exceeded the execution time limit.');
}

/// Arms QuickJS's interrupt at every synchronous native execution boundary.
///
/// flutter_js 0.8.7's native timeout never sets its start time. A Dart timer
/// cannot interrupt FFI either. This handler checks a monotonic deadline from
/// inside QuickJS, including pending jobs and nested host calls.
class SourceQuickJsRuntime extends QuickJsRuntime2 {
  factory SourceQuickJsRuntime() {
    // Runtime construction is synchronous. flutter_js exposes its runtime
    // registry but not the handle on QuickJsRuntime2. Compare opaque identities
    // as native allocators can reuse an address retained by the plugin registry.
    final previous = Map<Pointer<JSRuntime>, Object>.from(runtimeOpaques);
    final runtime = SourceQuickJsRuntime._();
    try {
      final entry = runtimeOpaques.entries.singleWhere(
        (entry) => !identical(previous[entry.key], entry.value),
      );
      runtime._nativeRuntime = entry.key;
      runtime._nativeOpaque = entry.value;
      runtime._interrupt = NativeCallable<_InterruptNative>.isolateLocal(
        runtime._checkDeadline,
        exceptionalReturn: 1,
      );
      _setInterrupt(entry.key, runtime._interrupt!.nativeFunction, nullptr);
      runtime._ready = true;
      runtime.enableHandlePromises();
      return runtime;
    } catch (_) {
      runtime.dispose();
      rethrow;
    }
  }

  SourceQuickJsRuntime._();

  static const executionBudget = Duration(milliseconds: 500);
  static final _SetInterrupt _setInterrupt = _library
      .lookupFunction<_SetInterruptNative, _SetInterrupt>(
        'JS_SetInterruptHandler',
      );
  static final DynamicLibrary _library = DynamicLibrary.open(
    'libfastdev_quickjs_runtime.so',
  );

  Pointer<JSRuntime>? _nativeRuntime;
  Object? _nativeOpaque;
  NativeCallable<_InterruptNative>? _interrupt;
  final Set<Timer> _timers = {};
  Stopwatch? _execution;
  bool _ready = false;
  bool _closed = false;
  bool _interrupted = false;

  int _checkDeadline(Pointer<JSRuntime> runtime, Pointer<Void> opaque) {
    if (_interrupted) return 1;
    if ((_execution?.elapsed ?? Duration.zero) >= executionBudget) {
      _interrupted = true;
      return 1;
    }
    return 0;
  }

  T _bounded<T>(T Function() action) {
    if (_closed) throw StateError('The source QuickJS runtime is disposed.');
    if (_interrupted) throw const SourceScriptExecutionTimeout();
    // Superclass construction installs only trusted bridge helpers before the
    // native handle is available. Nested entries share their caller's deadline.
    if (!_ready || _execution != null) return action();
    _interrupted = false;
    _execution = Stopwatch()..start();
    try {
      final result = action();
      // The plugin swallows pending-job errors, so inspect the interrupt flag
      // even when dispatch returns successfully.
      if (_interrupted) throw const SourceScriptExecutionTimeout();
      return result;
    } finally {
      _execution = null;
    }
  }

  @override
  JsEvalResult evaluate(
    String command, {
    String? name,
    int? evalFlags,
    String? sourceUrl,
  }) => _bounded(
    () => super.evaluate(
      command,
      name: name,
      evalFlags: evalFlags,
      sourceUrl: sourceUrl,
    ),
  );

  @override
  Future<void> dispatch() => _bounded(() => super.dispatch());

  @override
  int executePendingJob() => _bounded(() => super.executePendingJob());

  @override
  bool setupBridge(String channelName, void Function(dynamic args) fn) =>
      super.setupBridge(
        channelName,
        channelName == 'SetTimeout' ? _scheduleTimer : fn,
      );

  void _scheduleTimer(dynamic args) {
    if (_closed) return;
    final int duration = args['timeout'] ?? 0;
    final String index = args['timeoutIndex'];
    late final Timer timer;
    timer = Timer(Duration(milliseconds: duration), () {
      _timers.remove(timer);
      if (_closed) return;
      try {
        evaluate('''
          __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$index].call();
          delete __NATIVE_FLUTTER_JS__setTimeoutCallbacks[$index];
        ''');
      } on SourceScriptExecutionTimeout {
        // Keep the interrupt latched. The owning evaluator observes it on its
        // next promise poll and replaces the runtime; no uncaught Timer error.
      }
    });
    _timers.add(timer);
  }

  @override
  void dispose() {
    if (_closed) return;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    try {
      super.dispose();
    } finally {
      _closed = true;
      // Keep the callback alive through native disposal, then release its Dart
      // closure and the plugin's stale registry entry owned by this instance.
      final pointer = _nativeRuntime;
      if (pointer != null &&
          identical(runtimeOpaques[pointer], _nativeOpaque)) {
        runtimeOpaques.remove(pointer);
      }
      JavascriptRuntime.channelFunctionsRegistered.remove(getEngineInstanceId());
      _interrupt?.close();
      _interrupt = null;
    }
  }
}
