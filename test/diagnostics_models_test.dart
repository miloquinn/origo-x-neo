import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/diagnostics/diagnostics_models.dart';

void main() {
  DiagnosticsSession session(DateTime start) => DiagnosticsSession(
    reportId: 'report-1',
    startedAt: start,
    platform: 'ios',
    appVersion: '2.7.3',
    buildNumber: '1',
  );

  test('uses weighted samples and refresh-rate-aware frame budgets', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start);
    value
      ..addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start,
          memoryBytes: 100,
          cpuTimeMs: 1000,
          displayRefreshRateHz: 120,
          thermalState: 'nominal',
        ),
      )
      ..addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start.add(const Duration(seconds: 30)),
          memoryBytes: 300,
          cpuTimeMs: 1600,
          thermalState: 'serious',
        ),
      )
      ..addFrame(
        const DiagnosticsFrameSample(
          buildDuration: Duration(milliseconds: 9),
          rasterDuration: Duration(milliseconds: 3),
        ),
      )
      ..addFrame(
        const DiagnosticsFrameSample(
          buildDuration: Duration(milliseconds: 2),
          rasterDuration: Duration(milliseconds: 35),
        ),
      );

    final report = value.report(start.add(const Duration(minutes: 1)));
    expect(report['memory_avg_bytes'], 200);
    expect(report['memory_peak_bytes'], 300);
    expect(report['memory_samples'], 2);
    expect(report['cpu_time_ms'], 600);
    expect(report['frame_count'], 2);
    expect(report['slow_frames'], 2);
    expect(report['severe_frames'], 1);
    expect(report['frame_build_p95_ms'], 9.0);
    expect(report['frame_raster_p95_ms'], 35.0);
    expect(report['thermal_state'], 'serious');
  });

  test('requires two time-separated CPU samples', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start)
      ..addResource(
        DiagnosticsResourceSnapshot(capturedAt: start, cpuTimeMs: 1000),
      );
    expect(value.report(start)['cpu_time_ms'], isNull);
  });

  test('only reports a continuous unplugged battery segment of 20 minutes', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start);
    for (var minute = 0; minute <= 20; minute++) {
      value.addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start.add(Duration(minutes: minute)),
          batteryLevel: minute == 20 ? 79 : 80,
          charging: false,
        ),
      );
    }

    final first = value.report(start.add(const Duration(minutes: 20)));
    final second = value.report(start.add(const Duration(minutes: 20)));
    expect(first['battery_drop_points'], 1);
    expect(
      first['battery_duration_ms'],
      const Duration(minutes: 20).inMilliseconds,
    );
    expect(second, first, reason: 'snapshot must not reset the live segment');
  });

  test('plugged power rejects battery attribution for the whole session', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start);
    for (var minute = 0; minute <= 20; minute++) {
      value.addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start.add(Duration(minutes: minute)),
          batteryLevel: minute == 20 ? 79 : 80,
          charging: minute == 10,
        ),
      );
    }

    final report = value.report(
      start.add(const Duration(minutes: 20)),
      finalize: true,
    );
    expect(report['battery_drop_points'], isNull);
    expect(report['battery_duration_ms'], isNull);
  });

  test('a long sampling gap cuts the battery segment', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start)
      ..addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start,
          batteryLevel: 80,
          charging: false,
        ),
      )
      ..addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start.add(const Duration(minutes: 20)),
          batteryLevel: 79,
          charging: false,
        ),
      );

    final report = value.report(
      start.add(const Duration(minutes: 20)),
      finalize: true,
    );
    expect(report['battery_drop_points'], isNull);
    expect(report['battery_duration_ms'], isNull);
  });

  test('an implausible single-sample battery drop cuts the segment', () {
    final start = DateTime.utc(2026, 10, 8);
    final value = session(start);
    for (var minute = 0; minute <= 20; minute++) {
      value.addResource(
        DiagnosticsResourceSnapshot(
          capturedAt: start.add(Duration(minutes: minute)),
          batteryLevel: minute == 10 ? 70 : (minute < 10 ? 80 : 70),
          charging: false,
        ),
      );
    }
    final report = value.report(
      start.add(const Duration(minutes: 20)),
      finalize: true,
    );
    expect(report['battery_drop_points'], isNull);
    expect(report['battery_duration_ms'], isNull);
  });
}
