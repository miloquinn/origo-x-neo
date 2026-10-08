@Tags(['isolated-process'])
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:xxread/services/account/member_account_controller.dart';
import 'package:xxread/services/diagnostics/diagnostics_controller.dart';
import 'package:xxread/services/diagnostics/diagnostics_models.dart';
import 'package:xxread/services/diagnostics/diagnostics_platform.dart';
import 'package:xxread/services/diagnostics/diagnostics_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemberAccountController account;
  late _MemoryStore store;
  late _Sampler sampler;
  late _Frames frames;
  late _Scheduler scheduler;
  late DateTime now;
  String? owner;
  bool accountReady = true;

  DiagnosticsController controller({DiagnosticsUploader? uploader}) {
    return DiagnosticsController(
      account: account,
      store: store,
      resourceSampler: sampler,
      frameTimingSource: frames,
      periodicSchedule: scheduler.schedule,
      now: () => now,
      idFactory: () => '00000000-0000-4000-8000-000000000001',
      accountId: () => owner,
      accountReady: () => accountReady,
      uploader: uploader ?? (_, _) async => <String>[],
      packageInfo: () async => PackageInfo(
        appName: 'Origo X',
        packageName: 'com.niki.xxread',
        version: '2.7.3',
        buildNumber: '1',
      ),
    );
  }

  setUp(() {
    account = MemberAccountController(networkAllowed: true);
    store = _MemoryStore(enabled: true);
    sampler = _Sampler();
    frames = _Frames();
    scheduler = _Scheduler();
    now = DateTime.utc(2026, 10, 8);
    owner = 'account-a';
    accountReady = true;
  });

  tearDown(() => account.dispose());

  test('opt out stops collection and clears pending data', () async {
    store.pending.add(
      const PendingDiagnosticsReport(
        owner: 'account-a',
        report: <String, dynamic>{'report_id': 'old'},
      ),
    );
    final value = controller();
    await value.initialize();
    await _settleAsyncWork();
    expect(value.snapshot(), isNotNull);
    final samplesBefore = sampler.calls;

    value.setNetworkAllowed(false);
    scheduler.fire();
    frames.emit(
      const DiagnosticsFrameSample(
        buildDuration: Duration(milliseconds: 50),
        rasterDuration: Duration.zero,
      ),
    );
    await _settleAsyncWork();

    expect(value.snapshot(), isNull);
    expect(sampler.calls, samplesBefore);
    expect(store.pending, isEmpty);
    value.dispose();
  });

  test('initial legal gate suspends without deleting retry queue', () async {
    account.dispose();
    account = MemberAccountController(networkAllowed: false);
    store.pending.add(
      const PendingDiagnosticsReport(
        owner: 'account-a',
        report: <String, dynamic>{'report_id': 'retry'},
      ),
    );
    final value = controller();
    await value.initialize();
    value.setNetworkAllowed(false);
    await _settleAsyncWork();

    expect(store.pending.single.report['report_id'], 'retry');
    expect(value.snapshot(), isNull);
    value.dispose();
  });

  test(
    'concurrent initialization is shared with a preference change',
    () async {
      store.readGate = Completer<void>();
      final value = controller();

      final first = value.initialize();
      final second = value.initialize();
      final disable = value.setEnabled(false);
      expect(identical(first, second), isTrue);
      expect(store.enabledReads, 1);

      store.readGate!.complete();
      await Future.wait<void>([first, second, disable]);

      expect(value.enabled, isFalse);
      expect(store.enabled, isFalse);
      value.dispose();
    },
  );

  test(
    'legal gate opening during initialization still starts collection',
    () async {
      account.dispose();
      account = MemberAccountController(networkAllowed: false);
      store.readGate = Completer<void>();
      final value = controller();

      final initialization = value.initialize();
      account.setNetworkAllowed(true);
      value.setNetworkAllowed(true);
      store.readGate!.complete();
      await initialization;
      await _settleAsyncWork();

      expect(value.enabled, isTrue);
      expect(value.snapshot(), isNotNull);
      value.dispose();
    },
  );

  test(
    'snapshot freezes and queues one immutable report before rotating',
    () async {
      final value = controller();
      await value.initialize();
      await _settleAsyncWork();
      now = now.add(const Duration(minutes: 2));

      final report = value.snapshot()!;
      await _settleAsyncWork();

      expect(report['report_id'], '00000000-0000-4000-8000-000000000001');
      expect(store.pending.single.report, report);
      expect(scheduler.task?.cancelled, isFalse);
      value.dispose();
    },
  );

  test('background persists and the next foreground uploads once', () async {
    final uploads = <List<Map<String, dynamic>>>[];
    final uploadOwners = <String>[];
    final value = controller(
      uploader: (uploadOwner, reports) async {
        uploadOwners.add(uploadOwner);
        uploads.add(reports);
        return reports.map((report) => report['report_id']! as String).toList();
      },
    );
    await value.initialize();
    await _settleAsyncWork();
    now = now.add(const Duration(minutes: 1));
    value.didChangeAppLifecycleState(AppLifecycleState.paused);
    await _settleAsyncWork();

    expect(uploads, isEmpty);
    expect(store.pending, hasLength(1));
    value.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _settleAsyncWork();

    expect(uploads, hasLength(1));
    expect(uploadOwners, <String>['account-a']);
    expect(
      uploads.single.single['duration_ms'],
      const Duration(minutes: 1).inMilliseconds,
    );
    expect(value.snapshot(), isNotNull);
    expect(store.pending, isEmpty);
    value.dispose();
  });

  test(
    'account change removes the old owner queue before any upload',
    () async {
      store.pending.add(
        const PendingDiagnosticsReport(
          owner: 'account-a',
          report: <String, dynamic>{'report_id': 'old'},
        ),
      );
      final uploaded = <Map<String, dynamic>>[];
      final value = controller(
        uploader: (_, reports) async {
          uploaded.addAll(reports);
          throw StateError('offline');
        },
      );
      await value.initialize();
      await _settleAsyncWork();
      expect(store.pending, hasLength(1));

      owner = 'account-b';
      value.reconcileAccountForTesting();
      await _settleAsyncWork();

      expect(store.pending, isEmpty);
      expect(value.snapshot(), isNotNull);
      expect(
        uploaded.where((report) => report['report_id'] == 'old'),
        hasLength(1),
      );
      value.dispose();
    },
  );

  test('failed uploads remain bounded for a later foreground retry', () async {
    final value = controller(
      uploader: (_, _) async => throw StateError('offline'),
    );
    await value.initialize();
    await _settleAsyncWork();
    for (var index = 0; index < 23; index++) {
      now = now.add(const Duration(seconds: 1));
      await value.flush();
    }

    expect(
      store.pending,
      hasLength(DiagnosticsController.maximumPendingReports),
    );
    expect(store.pending.first.report['report_id'], isNotNull);
    value.dispose();
  });

  test('account initialization keeps retries for the restored owner', () async {
    accountReady = false;
    owner = null;
    store.pending.add(
      const PendingDiagnosticsReport(
        owner: 'account-a',
        report: <String, dynamic>{'report_id': 'retry'},
      ),
    );
    final value = controller(
      uploader: (_, _) async => throw StateError('offline'),
    );
    await value.initialize();
    await _settleAsyncWork();

    accountReady = true;
    owner = 'account-a';
    value.reconcileAccountForTesting();
    await _settleAsyncWork();

    expect(store.pending.single.report['report_id'], 'retry');
    value.dispose();
  });

  test(
    'an hour-long foreground session rotates on its sampling tick',
    () async {
      final uploaded = <Map<String, dynamic>>[];
      final value = controller(
        uploader: (_, reports) async {
          uploaded.addAll(reports);
          return reports
              .map((report) => report['report_id']! as String)
              .toList();
        },
      );
      await value.initialize();
      await _settleAsyncWork();
      now = now.add(DiagnosticsController.maximumSessionDuration);

      scheduler.fire();
      await _settleAsyncWork();

      expect(store.pending, isEmpty);
      expect(uploaded, hasLength(1));
      expect(
        uploaded.single['duration_ms'],
        DiagnosticsController.maximumSessionDuration.inMilliseconds,
      );
      expect(scheduler.task?.cancelled, isFalse);
      value.dispose();
    },
  );
}

Future<void> _settleAsyncWork() async {
  for (var index = 0; index < 5; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _MemoryStore implements DiagnosticsStore {
  _MemoryStore({required this.enabled});

  bool enabled;
  int enabledReads = 0;
  Completer<void>? readGate;
  List<PendingDiagnosticsReport> pending = <PendingDiagnosticsReport>[];

  @override
  Future<void> clearPending() async => pending = <PendingDiagnosticsReport>[];

  @override
  Future<bool> readEnabled() async {
    enabledReads++;
    await readGate?.future;
    return enabled;
  }

  @override
  Future<List<PendingDiagnosticsReport>> readPending() async =>
      List<PendingDiagnosticsReport>.of(pending);

  @override
  Future<void> writeEnabled(bool enabled) async => this.enabled = enabled;

  @override
  Future<void> writePending(List<PendingDiagnosticsReport> reports) async =>
      pending = List<PendingDiagnosticsReport>.of(reports);
}

class _Sampler implements DiagnosticsResourceSampler {
  int calls = 0;

  @override
  bool get supported => true;

  @override
  Future<DiagnosticsResourceSnapshot?> sample(DateTime capturedAt) async {
    calls++;
    return DiagnosticsResourceSnapshot(
      capturedAt: capturedAt,
      memoryBytes: 100 + calls,
      cpuTimeMs: calls * 10,
      batteryLevel: 80,
      charging: false,
      deviceModel: 'test-device',
      osVersion: 'test-os',
    );
  }
}

class _Frames implements DiagnosticsFrameTimingSource {
  DiagnosticsFrameCallback? callback;

  void emit(DiagnosticsFrameSample frame) => callback?.call(frame);

  @override
  void addListener(DiagnosticsFrameCallback listener) => callback = listener;

  @override
  void removeListener(DiagnosticsFrameCallback listener) {
    if (callback == listener) callback = null;
  }
}

class _Scheduler {
  _Task? task;

  DiagnosticsScheduledTask schedule(
    Duration interval,
    void Function() callback,
  ) => task = _Task(callback);

  void fire() => task?.fire();
}

class _Task implements DiagnosticsScheduledTask {
  _Task(this.callback);
  final void Function() callback;
  bool cancelled = false;

  void fire() {
    if (!cancelled) callback();
  }

  @override
  void cancel() => cancelled = true;
}
