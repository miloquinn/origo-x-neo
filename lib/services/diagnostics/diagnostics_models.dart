import 'dart:math' as math;

class DiagnosticsResourceSnapshot {
  const DiagnosticsResourceSnapshot({
    required this.capturedAt,
    this.memoryBytes,
    this.cpuTimeMs,
    this.batteryLevel,
    this.charging,
    this.thermalState = 'unknown',
    this.deviceModel,
    this.osVersion,
    this.displayRefreshRateHz,
  });

  factory DiagnosticsResourceSnapshot.fromMap(
    Map<Object?, Object?> map, {
    required DateTime capturedAt,
  }) {
    int? integer(String key) => switch (map[key]) {
      final int value => value,
      final num value => value.toInt(),
      _ => null,
    };
    double? decimal(String key) => switch (map[key]) {
      final num value => value.toDouble(),
      _ => null,
    };

    final battery = integer('battery_level');
    final thermal = map['thermal_state']?.toString();
    return DiagnosticsResourceSnapshot(
      capturedAt: capturedAt,
      memoryBytes: integer('memory_bytes'),
      cpuTimeMs: integer('cpu_time_ms'),
      batteryLevel: battery?.clamp(0, 100),
      charging: map['charging'] as bool?,
      thermalState: DiagnosticsSession.validThermalStates.contains(thermal)
          ? thermal!
          : 'unknown',
      deviceModel: map['device_model']?.toString(),
      osVersion: map['os_version']?.toString(),
      displayRefreshRateHz: decimal('display_refresh_rate_hz'),
    );
  }

  final DateTime capturedAt;
  final int? memoryBytes;
  final int? cpuTimeMs;
  final int? batteryLevel;
  final bool? charging;
  final String thermalState;
  final String? deviceModel;
  final String? osVersion;
  final double? displayRefreshRateHz;
}

class DiagnosticsFrameSample {
  const DiagnosticsFrameSample({
    required this.buildDuration,
    required this.rasterDuration,
  });

  final Duration buildDuration;
  final Duration rasterDuration;
}

class DiagnosticsSession {
  DiagnosticsSession({
    required this.reportId,
    required this.startedAt,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
  });

  static const validThermalStates = <String>{
    'unknown',
    'nominal',
    'fair',
    'serious',
    'critical',
  };
  static const _thermalRanks = <String, int>{
    'unknown': 0,
    'nominal': 1,
    'fair': 2,
    'serious': 3,
    'critical': 4,
  };
  static const minimumBatterySegment = Duration(minutes: 20);
  static const maximumBatterySampleGap = Duration(seconds: 90);
  static const maximumFrameSamples = 2048;
  static const maximumBatteryStepDrop = 2;

  final String reportId;
  final DateTime startedAt;
  final String platform;
  final String appVersion;
  final String buildNumber;

  String deviceModel = '';
  String osVersion = '';
  int frameCount = 0;
  int slowFrames = 0;
  int severeFrames = 0;
  final List<double> _buildTimesMs = <double>[];
  final List<double> _rasterTimesMs = <double>[];
  int _memoryTotal = 0;
  int memorySamples = 0;
  int? memoryPeakBytes;
  int? _cpuStartMs;
  int? _cpuLatestMs;
  DateTime? _cpuStartAt;
  DateTime? _cpuLatestAt;
  int _cpuSamples = 0;
  double _refreshRateHz = 60;
  String thermalState = 'unknown';

  DateTime? _batterySegmentStart;
  DateTime? _batteryLastAt;
  int? _batteryStartLevel;
  int? _batteryLastLevel;
  int _batteryDropPoints = 0;
  int _batteryDurationMs = 0;
  bool _batteryDisqualified = false;

  void addResource(DiagnosticsResourceSnapshot sample) {
    final memory = sample.memoryBytes;
    if (memory != null && memory >= 0) {
      _memoryTotal += memory;
      memorySamples++;
      memoryPeakBytes = math.max(memoryPeakBytes ?? memory, memory);
    }
    final cpu = sample.cpuTimeMs;
    if (cpu != null && cpu >= 0) {
      if (_cpuStartMs == null) {
        _cpuStartMs = cpu;
        _cpuStartAt = sample.capturedAt;
        _cpuLatestMs = cpu;
        _cpuLatestAt = sample.capturedAt;
        _cpuSamples = 1;
      } else if (cpu >= _cpuStartMs!) {
        _cpuLatestMs = cpu;
        _cpuLatestAt = sample.capturedAt;
        _cpuSamples++;
      }
    }
    final refreshRate = sample.displayRefreshRateHz;
    if (refreshRate != null && refreshRate >= 30 && refreshRate <= 240) {
      _refreshRateHz = refreshRate;
    }
    if ((sample.deviceModel ?? '').isNotEmpty) {
      deviceModel = sample.deviceModel!;
    }
    if ((sample.osVersion ?? '').isNotEmpty) osVersion = sample.osVersion!;
    final thermal = validThermalStates.contains(sample.thermalState)
        ? sample.thermalState
        : 'unknown';
    if ((_thermalRanks[thermal] ?? 0) > (_thermalRanks[thermalState] ?? 0)) {
      thermalState = thermal;
    }
    _addBattery(sample);
  }

  void addFrame(DiagnosticsFrameSample sample) {
    final buildMs = sample.buildDuration.inMicroseconds / 1000;
    final rasterMs = sample.rasterDuration.inMicroseconds / 1000;
    frameCount++;
    if (_buildTimesMs.length < maximumFrameSamples) {
      _buildTimesMs.add(buildMs);
      _rasterTimesMs.add(rasterMs);
    } else {
      final candidate =
          ((frameCount * 1103515245 + 12345) & 0x7fffffff) % frameCount;
      if (candidate < maximumFrameSamples) {
        _buildTimesMs[candidate] = buildMs;
        _rasterTimesMs[candidate] = rasterMs;
      }
    }
    final budgetMs = 1000 / _refreshRateHz;
    final worstStageMs = math.max(buildMs, rasterMs);
    if (worstStageMs > budgetMs) slowFrames++;
    if (worstStageMs > budgetMs * 4) severeFrames++;
  }

  Map<String, dynamic> report(DateTime endedAt, {bool finalize = false}) {
    if (finalize) _finishBatterySegment();
    var batteryDropPoints = _batteryDropPoints;
    var batteryDurationMs = _batteryDurationMs;
    if (!finalize &&
        _batterySegmentStart != null &&
        _batteryLastAt != null &&
        _batteryStartLevel != null &&
        _batteryLastLevel != null) {
      final duration = _batteryLastAt!.difference(_batterySegmentStart!);
      final drop = _batteryStartLevel! - _batteryLastLevel!;
      if (duration >= minimumBatterySegment && drop >= 1) {
        batteryDropPoints += drop;
        batteryDurationMs += duration.inMilliseconds;
      }
    }
    final elapsed = endedAt.difference(startedAt).inMilliseconds;
    final durationMs = elapsed.clamp(1, const Duration(days: 1).inMilliseconds);
    final cpu =
        _cpuSamples < 2 ||
            _cpuStartMs == null ||
            _cpuLatestMs == null ||
            _cpuStartAt == null ||
            _cpuLatestAt == null ||
            !_cpuLatestAt!.isAfter(_cpuStartAt!)
        ? null
        : _cpuLatestMs! - _cpuStartMs!;
    return <String, dynamic>{
      'report_id': reportId,
      'platform': platform,
      'app_version': appVersion,
      'build_number': buildNumber,
      'os_version': osVersion.isEmpty ? 'unknown' : osVersion,
      'device_model': deviceModel.isEmpty ? 'unknown' : deviceModel,
      'duration_ms': durationMs,
      'frame_count': frameCount,
      'slow_frames': slowFrames,
      'severe_frames': severeFrames,
      'frame_build_p95_ms': _percentile95(_buildTimesMs),
      'frame_raster_p95_ms': _percentile95(_rasterTimesMs),
      'memory_avg_bytes': memorySamples == 0
          ? null
          : (_memoryTotal / memorySamples).round(),
      'memory_peak_bytes': memoryPeakBytes,
      'memory_samples': memorySamples,
      'cpu_time_ms': cpu != null && cpu >= 0 ? cpu : null,
      'battery_drop_points': !_batteryDisqualified && batteryDurationMs > 0
          ? batteryDropPoints
          : null,
      'battery_duration_ms': !_batteryDisqualified && batteryDurationMs > 0
          ? batteryDurationMs
          : null,
      'thermal_state': thermalState,
    };
  }

  void _addBattery(DiagnosticsResourceSnapshot sample) {
    final level = sample.batteryLevel;
    final charging = sample.charging;
    if (level == null || charging == null) {
      _finishBatterySegment();
      return;
    }
    if (charging) {
      _batteryDisqualified = true;
      _clearBatterySegment();
      return;
    }
    final lastAt = _batteryLastAt;
    final lastLevel = _batteryLastLevel;
    final gap = lastAt == null ? null : sample.capturedAt.difference(lastAt);
    final invalidStep =
        lastLevel != null &&
        (level > lastLevel || lastLevel - level > maximumBatteryStepDrop);
    if (lastAt == null ||
        lastLevel == null ||
        gap! > maximumBatterySampleGap ||
        invalidStep) {
      _finishBatterySegment();
      _batterySegmentStart = sample.capturedAt;
      _batteryStartLevel = level;
    }
    _batteryLastAt = sample.capturedAt;
    _batteryLastLevel = level;
  }

  void recordSamplingGap() => _finishBatterySegment();

  void _finishBatterySegment() {
    final startAt = _batterySegmentStart;
    final endAt = _batteryLastAt;
    final startLevel = _batteryStartLevel;
    final endLevel = _batteryLastLevel;
    if (startAt != null &&
        endAt != null &&
        startLevel != null &&
        endLevel != null) {
      final duration = endAt.difference(startAt);
      final drop = startLevel - endLevel;
      if (duration >= minimumBatterySegment && drop >= 1) {
        _batteryDropPoints += drop;
        _batteryDurationMs += duration.inMilliseconds;
      }
    }
    _clearBatterySegment();
  }

  void _clearBatterySegment() {
    _batterySegmentStart = null;
    _batteryLastAt = null;
    _batteryStartLevel = null;
    _batteryLastLevel = null;
  }

  static double? _percentile95(List<double> values) {
    if (values.isEmpty) return null;
    final sorted = List<double>.of(values)..sort();
    return sorted[(sorted.length * .95).ceil() - 1];
  }
}
