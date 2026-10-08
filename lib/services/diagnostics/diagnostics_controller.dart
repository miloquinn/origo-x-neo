import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../account/member_account_controller.dart';
import 'diagnostics_models.dart';
import 'diagnostics_platform.dart';
import 'diagnostics_store.dart';

typedef DiagnosticsNow = DateTime Function();
typedef DiagnosticsIdFactory = String Function();
typedef DiagnosticsUploader =
    Future<List<String>> Function(
      String owner,
      List<Map<String, dynamic>> reports,
    );
typedef DiagnosticsAccountId = String? Function();
typedef DiagnosticsAccountReady = bool Function();
typedef DiagnosticsPeriodicSchedule =
    DiagnosticsScheduledTask Function(
      Duration interval,
      void Function() callback,
    );

abstract interface class DiagnosticsScheduledTask {
  void cancel();
}

class _TimerDiagnosticsTask implements DiagnosticsScheduledTask {
  _TimerDiagnosticsTask(this.timer);
  final Timer timer;

  @override
  void cancel() => timer.cancel();
}

class DiagnosticsController extends ChangeNotifier with WidgetsBindingObserver {
  DiagnosticsController({
    required this.account,
    DiagnosticsResourceSampler? resourceSampler,
    DiagnosticsFrameTimingSource? frameTimingSource,
    DiagnosticsStore? store,
    DiagnosticsNow? now,
    DiagnosticsIdFactory? idFactory,
    DiagnosticsPeriodicSchedule? periodicSchedule,
    Future<PackageInfo> Function()? packageInfo,
    DiagnosticsUploader? uploader,
    DiagnosticsAccountId? accountId,
    DiagnosticsAccountReady? accountReady,
  }) : _resourceSampler =
           resourceSampler ?? MethodChannelDiagnosticsResourceSampler(),
       _frameTimingSource =
           frameTimingSource ?? FlutterDiagnosticsFrameTimingSource(),
       _store = store ?? SharedPreferencesDiagnosticsStore(),
       _now = now ?? DateTime.now,
       _idFactory = idFactory ?? _newUuid,
       _periodicSchedule = periodicSchedule ?? _scheduleTimer,
       _packageInfo = packageInfo ?? PackageInfo.fromPlatform,
       _accountId = accountId ?? (() => account.user?.id),
       _accountReadyProvider = accountReady ?? (() => account.initialized),
       _uploader =
           uploader ??
           ((owner, reports) => account.readingApi.uploadDiagnostics(
             reports,
             expectedUserId: owner,
           ));

  static const sampleInterval = Duration(seconds: 30);
  static const maximumSessionDuration = Duration(hours: 1);
  static const maximumPendingReports = 20;

  final MemberAccountController account;
  final DiagnosticsResourceSampler _resourceSampler;
  final DiagnosticsFrameTimingSource _frameTimingSource;
  final DiagnosticsStore _store;
  final DiagnosticsNow _now;
  final DiagnosticsIdFactory _idFactory;
  final DiagnosticsPeriodicSchedule _periodicSchedule;
  final Future<PackageInfo> Function() _packageInfo;
  final DiagnosticsAccountId _accountId;
  final DiagnosticsAccountReady _accountReadyProvider;
  final DiagnosticsUploader _uploader;

  bool _initialized = false;
  Future<void>? _initializing;
  bool _disposed = false;
  bool _enabled = false;
  bool _consentAnswered = false;
  bool _foreground = true;
  bool? _networkAllowedOverride;
  bool _sampling = false;
  bool _flushing = false;
  bool _clearForNetworkRevocation = false;
  int _generation = 0;
  Future<void> _storeBarrier = Future<void>.value();
  String? _owner;
  bool _accountReady = false;
  String _appVersion = '';
  String _buildNumber = '';
  DiagnosticsSession? _session;
  DiagnosticsScheduledTask? _sampleTask;
  List<PendingDiagnosticsReport> _pending = <PendingDiagnosticsReport>[];

  bool get enabled => _enabled;
  bool get supported => _resourceSampler.supported;
  bool get shouldOfferConsent =>
      !_disposed &&
      _initialized &&
      supported &&
      _networkAllowed &&
      !_enabled &&
      !_consentAnswered;

  bool get _networkAllowed =>
      (_networkAllowedOverride ?? account.networkAllowed) &&
      account.networkAllowed;
  bool get _mayCollect =>
      !_disposed && _initialized && _enabled && _networkAllowed && supported;

  Future<void> initialize() {
    if (_initialized || _disposed) return Future<void>.value();
    final active = _initializing;
    if (active != null) return active;
    late final Future<void> operation;
    operation = _initialize().whenComplete(() {
      if (identical(_initializing, operation)) _initializing = null;
    });
    _initializing = operation;
    return operation;
  }

  Future<void> _initialize() async {
    try {
      final results = await Future.wait<Object?>([
        _store.readEnabled(),
        _store.readConsentChoice(),
        _store.readPending(),
        _packageInfo(),
      ]);
      final storedEnabled = results[0] as bool;
      final consentChoice = results[1] as bool?;
      _enabled = consentChoice ?? storedEnabled;
      _consentAnswered = consentChoice != null || storedEnabled;
      _pending = results[2] as List<PendingDiagnosticsReport>;
      final info = results[3] as PackageInfo;
      _appVersion = info.version.trim().isEmpty
          ? 'unknown'
          : info.version.trim();
      _buildNumber = info.buildNumber.trim().isEmpty
          ? 'unknown'
          : info.buildNumber.trim();
    } catch (_) {
      if (_disposed) return;
      _enabled = false;
      _consentAnswered = false;
      _pending = <PendingDiagnosticsReport>[];
    }
    if (_disposed) return;
    _owner = _accountId();
    _accountReady = _accountReadyProvider();
    _initialized = true;
    account.addListener(_handleAccountChange);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;

    if (!_enabled) {
      _pending = <PendingDiagnosticsReport>[];
      await _clearPendingStore();
    } else {
      if (_accountReady) _dropPendingForAnotherOwner();
      await _persistPending();
      if (_networkAllowed) {
        if (_foreground) _startSession();
        if (_owner != null) unawaited(_flushPending());
      }
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> setEnabled(bool value) =>
      _setEnabled(value, reportPersistenceFailure: false);

  Future<void> answerConsentPrompt(bool enable) =>
      _setEnabled(enable, reportPersistenceFailure: true);

  Future<void> _setEnabled(
    bool value, {
    required bool reportPersistenceFailure,
  }) async {
    if (_disposed) return;
    if (!_initialized) await initialize();
    if (_disposed) return;
    _consentAnswered = true;
    final changed = value != _enabled;
    if (changed) _generation++;

    Object? consentFailure;
    StackTrace? consentFailureStack;
    if (value) {
      try {
        await _store.writeConsentChoice(true);
        _enabled = true;
        try {
          await _store.writeEnabled(true);
        } catch (_) {
          // The consent choice is authoritative; this is a legacy marker.
        }
      } catch (error, stack) {
        consentFailure = error;
        consentFailureStack = stack;
        _enabled = false;
        try {
          await _store.writeEnabled(false);
        } catch (_) {
          // Keep the legacy marker off when a new consent choice fails.
        }
      }
    } else {
      _enabled = false;
      try {
        await _store.writeConsentChoice(false);
      } catch (error, stack) {
        consentFailure = error;
        consentFailureStack = stack;
      }
      try {
        await _store.writeEnabled(false);
      } catch (_) {
        // Runtime opt-out and the consent choice remain authoritative.
      }
    }
    if (!_enabled) {
      _stopSession();
      _pending = <PendingDiagnosticsReport>[];
      await _clearPendingStore();
    } else if (_networkAllowed && _foreground && supported) {
      _startSession();
    }
    if (!_disposed) notifyListeners();
    if (reportPersistenceFailure && consentFailure != null) {
      Error.throwWithStackTrace(consentFailure, consentFailureStack!);
    }
  }

  /// Mirrors the legal-consent gate immediately. The account controller does
  /// not currently notify listeners when this value changes.
  void setNetworkAllowed(bool allowed) {
    if (_disposed || _networkAllowedOverride == allowed) return;
    final wasAllowed = _networkAllowed;
    _networkAllowedOverride = allowed;
    _clearForNetworkRevocation = !allowed && wasAllowed;
    _generation++;
    if (!_networkAllowed) {
      _stopSession();
      if (wasAllowed) {
        _pending = <PendingDiagnosticsReport>[];
        unawaited(_clearPendingStore());
      }
    } else if (_mayCollect && _foreground) {
      _clearForNetworkRevocation = false;
      _startSession();
      if (_owner != null) unawaited(_flushPending());
    }
    notifyListeners();
  }

  Map<String, dynamic>? snapshot() {
    final session = _session;
    if (!_mayCollect || session == null) return null;
    _sampleTask?.cancel();
    _sampleTask = null;
    _frameTimingSource.removeListener(_recordFrame);
    _session = null;
    _sampling = false;
    final report = Map<String, dynamic>.unmodifiable(
      session.report(_now(), finalize: true),
    );
    final owner = _owner;
    if (owner != null) {
      _pending.add(PendingDiagnosticsReport(owner: owner, report: report));
      if (_pending.length > maximumPendingReports) {
        _pending = _pending.sublist(_pending.length - maximumPendingReports);
      }
      unawaited(_persistPending());
    }
    if (_mayCollect && _foreground) _startSession();
    return report;
  }

  Future<void> flush() async {
    if (!_initialized || _disposed) return;
    if (!_enabled) {
      _stopSession();
      _pending = <PendingDiagnosticsReport>[];
      await _clearPendingStore();
      return;
    }
    if (!_networkAllowed) {
      _stopSession();
      return;
    }
    await _finishSessionAndQueue();
    await _flushPending();
    if (_mayCollect && _foreground) _startSession();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialized || _disposed) return;
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_mayCollect) _startSession();
      unawaited(_flushPending());
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (!_foreground) return;
      _foreground = false;
      unawaited(_finishSessionAndQueue());
    }
  }

  void _handleAccountChange() {
    if (_disposed) return;
    final nextReady = _accountReadyProvider();
    if (!_networkAllowed) {
      _generation++;
      _owner = _accountId();
      _accountReady = nextReady;
      _stopSession();
      if (_clearForNetworkRevocation) {
        _pending = <PendingDiagnosticsReport>[];
        unawaited(_clearPendingStore());
      }
      notifyListeners();
      return;
    }
    final nextOwner = _accountId();
    if (nextOwner == _owner && nextReady == _accountReady) return;
    if (!nextReady) return;
    final becomingReady = !_accountReady;
    _generation++;
    _owner = nextOwner;
    _accountReady = true;
    _stopSession();
    if (becomingReady) {
      _dropPendingForAnotherOwner();
      unawaited(_persistPending());
    } else {
      _pending = <PendingDiagnosticsReport>[];
      unawaited(_clearPendingStore());
    }
    if (_mayCollect && _foreground) _startSession();
    if (_owner != null) unawaited(_flushPending());
    notifyListeners();
  }

  void _startSession() {
    if (!_mayCollect || !_foreground || _session != null) return;
    _session = DiagnosticsSession(
      reportId: _idFactory(),
      startedAt: _now(),
      platform: defaultTargetPlatform == TargetPlatform.android
          ? 'android'
          : 'ios',
      appVersion: _appVersion,
      buildNumber: _buildNumber,
    );
    _frameTimingSource.addListener(_recordFrame);
    _sampleTask = _periodicSchedule(sampleInterval, () => unawaited(_sample()));
    unawaited(_sample());
  }

  void _stopSession() {
    _sampleTask?.cancel();
    _sampleTask = null;
    _frameTimingSource.removeListener(_recordFrame);
    _session = null;
    _sampling = false;
  }

  Future<void> _finishSessionAndQueue() async {
    final session = _session;
    if (session == null) return;
    final owner = _owner;
    _sampleTask?.cancel();
    _sampleTask = null;
    _frameTimingSource.removeListener(_recordFrame);
    _session = null;
    _sampling = false;
    if (!_enabled || !_networkAllowed || owner == null) return;
    final report = Map<String, dynamic>.unmodifiable(
      session.report(_now(), finalize: true),
    );
    _pending.add(PendingDiagnosticsReport(owner: owner, report: report));
    if (_pending.length > maximumPendingReports) {
      _pending = _pending.sublist(_pending.length - maximumPendingReports);
    }
    await _persistPending();
  }

  Future<void> _sample() async {
    if (_sampling || !_mayCollect || !_foreground || _session == null) return;
    if (!account.networkAllowed) {
      setNetworkAllowed(false);
      return;
    }
    _sampling = true;
    final generation = _generation;
    final session = _session;
    var rotate = false;
    try {
      final sample = await _resourceSampler.sample(_now());
      if (_disposed ||
          generation != _generation ||
          session == null ||
          !identical(session, _session) ||
          !_mayCollect ||
          !_foreground) {
        return;
      }
      if (sample == null) {
        session.recordSamplingGap();
      } else {
        session.addResource(sample);
      }
      rotate = _now().difference(session.startedAt) >= maximumSessionDuration;
      notifyListeners();
    } catch (_) {
      if (identical(session, _session)) session?.recordSamplingGap();
    } finally {
      _sampling = false;
    }
    if (rotate && identical(session, _session)) {
      await _finishSessionAndQueue();
      await _flushPending();
      if (_mayCollect && _foreground) _startSession();
    }
  }

  void _recordFrame(DiagnosticsFrameSample frame) {
    if (!_mayCollect || !_foreground) return;
    _session?.addFrame(frame);
  }

  Future<void> _flushPending() async {
    if (_flushing ||
        _disposed ||
        !_initialized ||
        !_enabled ||
        !_networkAllowed) {
      return;
    }
    final owner = _owner;
    if (owner == null) return;
    final reports = _pending
        .where((entry) => entry.owner == owner)
        .map((entry) => entry.report)
        .toList(growable: false);
    if (reports.isEmpty) return;
    final generation = _generation;
    _flushing = true;
    try {
      final acceptedIds = await _uploader(owner, reports);
      if (_disposed ||
          generation != _generation ||
          owner != _owner ||
          !_enabled ||
          !_networkAllowed) {
        return;
      }
      final accepted = acceptedIds.toSet();
      _pending.removeWhere(
        (entry) =>
            entry.owner == owner &&
            accepted.contains(entry.report['report_id']),
      );
      await _persistPending();
    } catch (_) {
      // A later foreground transition retries the bounded local queue.
    } finally {
      _flushing = false;
    }
  }

  void _dropPendingForAnotherOwner() {
    final owner = _owner;
    if (owner == null) {
      _pending.clear();
      return;
    }
    _pending.removeWhere((entry) => entry.owner != owner);
  }

  @visibleForTesting
  void reconcileAccountForTesting() => _handleAccountChange();

  Future<void> _persistPending() {
    final snapshot = List<PendingDiagnosticsReport>.of(_pending);
    return _queueStoreWrite(
      () => snapshot.isEmpty
          ? _store.clearPending()
          : _store.writePending(snapshot),
    );
  }

  Future<void> _clearPendingStore() => _queueStoreWrite(_store.clearPending);

  Future<void> _queueStoreWrite(Future<void> Function() operation) {
    final next = _storeBarrier.then((_) => operation());
    _storeBarrier = next.catchError((_) {});
    return _storeBarrier;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _sampleTask?.cancel();
    _sampleTask = null;
    _frameTimingSource.removeListener(_recordFrame);
    if (_initialized) {
      WidgetsBinding.instance.removeObserver(this);
      account.removeListener(_handleAccountChange);
    }
    _session = null;
    super.dispose();
  }

  static DiagnosticsScheduledTask _scheduleTimer(
    Duration interval,
    void Function() callback,
  ) => _TimerDiagnosticsTask(Timer.periodic(interval, (_) => callback()));

  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
