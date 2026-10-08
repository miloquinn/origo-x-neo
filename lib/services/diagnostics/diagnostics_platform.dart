import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'diagnostics_models.dart';

abstract interface class DiagnosticsResourceSampler {
  bool get supported;
  Future<DiagnosticsResourceSnapshot?> sample(DateTime capturedAt);
}

class MethodChannelDiagnosticsResourceSampler
    implements DiagnosticsResourceSampler {
  MethodChannelDiagnosticsResourceSampler({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.niki.xxread/diagnostics';
  final MethodChannel _channel;

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<DiagnosticsResourceSnapshot?> sample(DateTime capturedAt) async {
    if (!supported) return null;
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'getResourceSnapshot',
      );
      return map == null
          ? null
          : DiagnosticsResourceSnapshot.fromMap(map, capturedAt: capturedAt);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

typedef DiagnosticsFrameCallback = void Function(DiagnosticsFrameSample frame);

abstract interface class DiagnosticsFrameTimingSource {
  void addListener(DiagnosticsFrameCallback listener);
  void removeListener(DiagnosticsFrameCallback listener);
}

class FlutterDiagnosticsFrameTimingSource
    implements DiagnosticsFrameTimingSource {
  final Map<DiagnosticsFrameCallback, TimingsCallback> _callbacks = {};

  @override
  void addListener(DiagnosticsFrameCallback listener) {
    if (_callbacks.containsKey(listener)) return;
    void callback(List<FrameTiming> timings) {
      for (final timing in timings) {
        listener(
          DiagnosticsFrameSample(
            buildDuration: timing.buildDuration,
            rasterDuration: timing.rasterDuration,
          ),
        );
      }
    }

    _callbacks[listener] = callback;
    SchedulerBinding.instance.addTimingsCallback(callback);
  }

  @override
  void removeListener(DiagnosticsFrameCallback listener) {
    final callback = _callbacks.remove(listener);
    if (callback != null) {
      SchedulerBinding.instance.removeTimingsCallback(callback);
    }
  }
}
