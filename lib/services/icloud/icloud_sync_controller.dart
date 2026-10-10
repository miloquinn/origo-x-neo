import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/database_service.dart';
import 'icloud_sync_models.dart';
import 'icloud_sync_store.dart';
import 'icloud_sync_transport.dart';

typedef ICloudCanApply = bool Function();
typedef ICloudDataChanged = Future<void> Function();

class ICloudSyncController extends ChangeNotifier {
  ICloudSyncController({
    ICloudSyncStore? store,
    ICloudSyncTransport? transport,
    Directory? documents,
    SharedPreferences? preferences,
    ICloudCanApply? canApply,
    ICloudDataChanged? onDataChanged,
    bool networkAllowed = true,
    bool? supported,
    DateTime Function()? now,
  }) : _transport = transport ?? MethodChannelICloudSyncTransport(),
       _canApplyCallback = canApply ?? _alwaysApply,
       _supportedOverride = supported,
       _now = now ?? DateTime.now {
    _onDataChanged = onDataChanged;
    _networkAllowed = networkAllowed;
    if (store != null && documents != null && preferences != null) {
      _store = store;
      _documents = documents;
      _preferences = preferences;
      _dependenciesReady = true;
    } else if (store != null || documents != null || preferences != null) {
      throw ArgumentError(
        'store, documents, and preferences must be supplied together',
      );
    }
  }

  static Future<ICloudSyncController> create({
    required ICloudSyncStore store,
    ICloudSyncTransport? transport,
    ICloudCanApply? canApply,
    ICloudDataChanged? onDataChanged,
  }) async => ICloudSyncController(
    store: store,
    transport: transport ?? MethodChannelICloudSyncTransport(),
    documents: await getApplicationDocumentsDirectory(),
    preferences: await SharedPreferences.getInstance(),
    canApply: canApply,
    onDataChanged: onDataChanged,
  );

  static const _enabledKey = 'icloud_sync_enabled_v1';
  static const _accountKey = 'icloud_sync_account_v1';
  static const _deviceKey = 'icloud_sync_device_v1';
  static const _installationKey = 'icloud_sync_installation_v1';
  static const _manifestLimit = 16 * 1024 * 1024;
  static const _recordLimit = 100000;
  static final _hashPattern = RegExp(r'^[a-f0-9]{64}$');

  late ICloudSyncStore _store;
  final ICloudSyncTransport _transport;
  late Directory _documents;
  late SharedPreferences _preferences;
  ICloudCanApply _canApplyCallback;
  ICloudDataChanged? _onDataChanged;
  final bool? _supportedOverride;
  final DateTime Function() _now;

  bool _initialized = false;
  bool _disposed = false;
  bool _enabled = false;
  bool _available = false;
  bool _busy = false;
  bool _networkAllowed = true;
  bool _foreground = true;
  int _generation = 0;
  String _status = 'disabled';
  String? _error;
  DateTime? _lastSync;
  String? _accountId;
  String? _deviceName;
  String? _deviceId;
  _Replica? _replica;
  Directory? _accountDirectory;
  Timer? _timer;
  List<ICloudConflict> _conflicts = const [];
  final Map<String, _AggregateResolution> _aggregateResolutions = {};
  int _dataRevision = 0;
  bool _dependenciesReady = false;

  bool get supported =>
      _supportedOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS));
  bool get enabled => _enabled;
  bool get available => _available;
  bool get busy => _busy;
  String get status => _status;
  String? get error => _error;
  DateTime? get lastSync => _lastSync;
  List<ICloudConflict> get conflicts => List.unmodifiable(_conflicts);
  bool get canApply => _canApplyCallback();
  set canApply(ICloudCanApply value) => _canApplyCallback = value;
  set onDataChanged(ICloudDataChanged? value) => _onDataChanged = value;
  int get dataRevision => _dataRevision;

  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    if (!supported) {
      _status = 'unsupported';
      _changed();
      return;
    }
    try {
      if (!_dependenciesReady) {
        _documents = await getApplicationDocumentsDirectory();
        _preferences = await SharedPreferences.getInstance();
        _store = DefaultICloudSyncStore(
          database: await DatabaseService().database,
          documents: _documents,
          preferences: _preferences,
        );
        _dependenciesReady = true;
      }
      _enabled = _preferences.getBool(_enabledKey) ?? false;
      _deviceId = _preferences.getString(_deviceKey);
      if (_deviceId == null || _deviceId!.isEmpty) {
        _deviceId = const Uuid().v4();
        await _preferences.setString(_deviceKey, _deviceId!);
      }
      await _refreshStatus();
      if (_enabled && _available) {
        final pinned = _preferences.getString(_accountKey);
        if (pinned == null || pinned != _accountId) {
          if (pinned == null) {
            await _preferences.setString(_accountKey, _accountId!);
            await _loadReplica(_accountId!);
            await _recoverPendingApply();
            _schedule();
            unawaited(synchronize());
          } else {
            await _pauseForAccountChange();
          }
        } else {
          await _loadReplica(_accountId!);
          await _recoverPendingApply();
          _schedule();
          unawaited(synchronize());
        }
      } else {
        _status = _enabled ? 'unavailable' : 'disabled';
        if (_enabled) _schedule();
      }
    } on FormatException {
      _status = 'error';
      _error = 'invalidData';
    } catch (_) {
      _status = 'error';
      _error = 'initialization';
    }
    _changed();
  }

  Future<void> setEnabled(bool value) async {
    if (_disposed || !supported || value == _enabled) return;
    _generation++;
    if (!value) {
      _enabled = false;
      _timer?.cancel();
      _timer = null;
      _status = 'disabled';
      _error = null;
      _conflicts = const [];
      _aggregateResolutions.clear();
      await _preferences.setBool(_enabledKey, false);
      _changed();
      return;
    }
    await _refreshStatus();
    if (!_available || _accountId == null) {
      _enabled = true;
      _status = 'unavailable';
      _error = 'unavailable';
      await _preferences.setBool(_enabledKey, true);
      _schedule();
      _changed();
      return;
    }
    _enabled = true;
    _error = null;
    _status = 'idle';
    await _preferences.setBool(_enabledKey, true);
    await _preferences.setString(_accountKey, _accountId!);
    await _loadReplica(_accountId!);
    await _recoverPendingApply();
    _schedule();
    _changed();
    await synchronize();
  }

  void setNetworkAllowed(bool value) {
    if (_networkAllowed == value || _disposed) return;
    _networkAllowed = value;
    _generation++;
    if (value && _enabled) unawaited(synchronize());
  }

  void setForeground(bool value) {
    if (_foreground == value || _disposed) return;
    _foreground = value;
    _generation++;
    if (value) {
      _schedule();
      if (_enabled) unawaited(synchronize());
    } else {
      _timer?.cancel();
      _timer = null;
      if (_enabled) unawaited(_synchronize(publishOnly: true));
    }
  }

  Future<void> synchronize() => _synchronize(publishOnly: false);

  Future<void> _synchronize({required bool publishOnly}) async {
    if (_disposed || _busy || !_enabled || !supported) return;
    if (!_networkAllowed) {
      _status = 'offline';
      _changed();
      return;
    }
    _busy = true;
    _status = 'syncing';
    _error = null;
    _changed();
    final generation = _generation;
    try {
      await _refreshStatus();
      if (!_active(generation)) return;
      if (!_available || _accountId == null) {
        _status = 'unavailable';
        _error = 'unavailable';
        return;
      }
      final pinned = _preferences.getString(_accountKey);
      if (pinned == null) {
        await _preferences.setString(_accountKey, _accountId!);
      } else if (pinned != _accountId) {
        await _pauseForAccountChange();
        return;
      }
      await _loadReplica(_accountId!);
      final recovered = await _recoverPendingApply();
      if (!_active(generation)) return;

      if (!recovered) {
        final entries = await _transport.list(accountId: _accountId!);
        if (_active(generation)) await _publish(entries, generation);
        return;
      }

      final snapshot = await _store.capture();
      await _captureLocalChanges(snapshot);
      if (!_active(generation)) return;

      final entries = await _transport.list(accountId: _accountId!);
      if (!_active(generation)) return;
      if (publishOnly || !canApply) {
        await _publish(entries, generation);
        return;
      }
      final remote = await _readRemoteRecords(entries, generation);
      if (!_active(generation)) return;

      if (!publishOnly) {
        await _mergeAndApply(remote, entries, generation);
        if (!_active(generation)) return;
      }
      await _publish(entries, generation);
    } on FormatException {
      _status = 'error';
      _error = 'invalidData';
    } catch (_) {
      if (_active(generation)) {
        _status = 'error';
        _error = 'transport';
      }
    } finally {
      _busy = false;
      _changed();
    }
  }

  Future<void> resolveConflict(String key, ICloudRecord chosen) async {
    if (_disposed || !_enabled || _replica == null || _busy) return;
    final conflict = _conflicts.where((item) => item.key == key).firstOrNull;
    if (conflict == null ||
        !conflict.versions.any(
          (record) =>
              syncCanonicalJson(record.toJson()) ==
              syncCanonicalJson(chosen.toJson()),
        )) {
      throw ArgumentError.value(key, 'key', 'Unknown iCloud conflict');
    }
    _busy = true;
    _status = 'syncing';
    _error = null;
    _changed();
    final generation = _generation;
    try {
      await _refreshStatus();
      if (!_active(generation) ||
          _accountId != _preferences.getString(_accountKey)) {
        if (_accountId != _preferences.getString(_accountKey)) {
          await _pauseForAccountChange();
        }
        return;
      }
      final entries = await _transport.list(accountId: _accountId!);
      final assets = await _downloadAssets([chosen], entries, generation);
      if (!_active(generation) || !canApply) return;

      final beforeApply = await _store.capture();
      final locallyChanged = await _captureLocalChanges(beforeApply);
      final aggregate = _aggregateResolutions[key];
      if (locallyChanged ||
          (!_replica!.conflicts.containsKey(key) && aggregate == null)) {
        _status = _conflicts.isEmpty ? 'idle' : 'conflicts';
        return;
      }
      if (aggregate != null) {
        await _resolveAggregate(aggregate, chosen, entries, generation);
        return;
      }
      final replica = _replica!;
      replica.counter++;
      final clock = joinSyncClocks(conflict.versions);
      clock[_deviceId!] = replica.counter;
      final resolved = ICloudRecord(
        key: key,
        value: chosen.value,
        clock: clock,
        device: _deviceName ?? 'This device',
        modifiedAt: _now().toUtc().millisecondsSinceEpoch,
        writer: _deviceId,
      );
      if (!await _applyRecords({key: resolved}, assets)) return;
      replica.records[key] = resolved;
      replica.baseline[key] = resolved.value;
      replica.conflicts.remove(key);
      _refreshConflicts();
      await _persistReplica();
      _dataRevision++;
      await _onDataChanged?.call();
      await _publish(entries, generation);
    } on FormatException {
      _status = 'error';
      _error = 'invalidData';
    } catch (_) {
      _status = 'error';
      _error = 'transport';
    } finally {
      _busy = false;
      _changed();
    }
  }

  Future<void> _mergeAndApply(
    List<ICloudRecord> remote,
    List<ICloudRemoteFile> entries,
    int generation,
  ) async {
    final replica = _replica!;
    final byKey = <String, List<ICloudRecord>>{};
    for (final record in [...replica.records.values, ...remote]) {
      byKey.putIfAbsent(record.key, () => []).add(record);
    }
    final winners = <String, ICloudRecord>{};
    final conflicts = <String, List<ICloudRecord>>{};
    for (final entry in byKey.entries) {
      final frontier = syncFrontier(entry.value);
      final values = <String>{
        for (final item in frontier) syncCanonicalJson(item.value),
      };
      if (values.length > 1) {
        conflicts[entry.key] = frontier;
        continue;
      }
      final joined = ICloudRecord(
        key: entry.key,
        value: frontier.first.value,
        clock: joinSyncClocks(frontier),
        device: frontier.first.device,
        modifiedAt: frontier
            .map((e) => e.modifiedAt)
            .reduce((a, b) => a > b ? a : b),
        writer: frontier.first.writer,
      );
      winners[entry.key] = joined;
    }
    _aggregateResolutions
      ..clear()
      ..addAll(_dependentDeletionConflicts(byKey, conflicts));
    replica.conflicts = conflicts;
    _refreshConflicts();
    final blockedKeys = <String>{
      for (final aggregate in _aggregateResolutions.values) ...[
        aggregate.parentKey,
        ...aggregate.dependents.keys,
      ],
    };
    final safeWinners = <String, ICloudRecord>{
      for (final entry in winners.entries)
        if (!blockedKeys.contains(entry.key)) entry.key: entry.value,
    };
    if (_aggregateResolutions.isNotEmpty) {
      _error = 'dependentConflict';
    }
    if (!canApply || safeWinners.isEmpty) {
      await _persistReplica();
      _status = conflicts.isEmpty && _aggregateResolutions.isEmpty
          ? 'idle'
          : 'conflicts';
      return;
    }

    final needed = <String, ICloudRecord>{};
    for (final entry in safeWinners.entries) {
      if (!replica.baseline.containsKey(entry.key) ||
          syncCanonicalJson(replica.baseline[entry.key]) !=
              syncCanonicalJson(entry.value.value)) {
        needed[entry.key] = entry.value;
      }
    }
    final assets = await _downloadAssets(needed.values, entries, generation);
    if (!_active(generation) || !canApply) return;

    // A user edit made while iCloud was downloading becomes a local revision;
    // recalculate the merge instead of applying over it.
    final beforeApply = await _store.capture();
    final changed = await _captureLocalChanges(beforeApply);
    if (changed) {
      await _mergeAndApply(remote, entries, generation);
      return;
    }
    if (needed.isNotEmpty) {
      if (!await _applyRecords(needed, assets)) return;
      for (final entry in needed.entries) {
        replica.records[entry.key] = entry.value;
        replica.baseline[entry.key] = entry.value.value;
      }
      await _persistReplica();
      _dataRevision++;
      await _onDataChanged?.call();
    }
    for (final entry in safeWinners.entries) {
      replica.records[entry.key] = entry.value;
    }
    await _persistReplica();
    _status = conflicts.isEmpty && _aggregateResolutions.isEmpty
        ? 'idle'
        : 'conflicts';
  }

  Future<bool> _applyRecords(
    Map<String, ICloudRecord> records,
    Map<String, String> assets,
  ) async {
    final replica = _replica!;
    replica.pendingApply = _PendingApply(records, assets);
    await _persistReplica();
    if (!canApply) return false;
    await _store.apply(records, assets);
    replica.pendingApply = null;
    await _persistReplica();
    return true;
  }

  Future<bool> _recoverPendingApply() async {
    final pending = _replica?.pendingApply;
    if (pending == null) return true;
    if (!canApply) {
      _status = 'waitingToApply';
      return false;
    }
    await _store.apply(pending.records, pending.assets);
    for (final entry in pending.records.entries) {
      _replica!.records[entry.key] = entry.value;
      _replica!.baseline[entry.key] = entry.value.value;
    }
    _replica!.pendingApply = null;
    await _persistReplica();
    _dataRevision++;
    await _onDataChanged?.call();
    return true;
  }

  Future<bool> _captureLocalChanges(ICloudLocalSnapshot snapshot) async {
    final replica = _replica!;
    final keys = <String>{...snapshot.values.keys, ...replica.baseline.keys};
    var changed = false;
    for (final key in keys) {
      final known = replica.baseline.containsKey(key);
      final current = snapshot.values[key];
      if (!known && current == null) continue;
      if (known &&
          syncCanonicalJson(replica.baseline[key]) ==
              syncCanonicalJson(current)) {
        continue;
      }
      replica.counter++;
      final clock = <String, int>{...?replica.records[key]?.clock};
      clock[_deviceId!] = replica.counter;
      final record = ICloudRecord(
        key: key,
        value: current,
        clock: clock,
        device: _deviceName ?? 'This device',
        modifiedAt: _now().toUtc().millisecondsSinceEpoch,
        writer: _deviceId,
      );
      replica.records[key] = record;
      replica.baseline[key] = current;
      replica.conflicts.remove(key);
      changed = true;
    }
    replica.assets = Map<String, String>.from(snapshot.assets);
    if (changed) {
      _refreshConflicts();
      await _persistReplica();
    }
    return changed;
  }

  Future<List<ICloudRecord>> _readRemoteRecords(
    List<ICloudRemoteFile> entries,
    int generation,
  ) async {
    final result = <ICloudRecord>[];
    final paths = entries
        .where(
          (e) => RegExp(
            r'^sync-v1/devices/[A-Za-z0-9_-]+\.json$',
          ).hasMatch(e.path),
        )
        .where((e) => e.uploaded != false)
        .where((e) => e.bytes == null || e.bytes! <= _manifestLimit)
        .map((e) => e.path)
        .toSet();
    for (final path in paths) {
      if (!_active(generation)) break;
      final temporary = File(
        p.join(
          _accountDirectory!.path,
          'incoming',
          '${sha256.convert(utf8.encode(path))}.json',
        ),
      );
      await temporary.parent.create(recursive: true);
      final local = File(
        await _transport.read(
          path: path,
          destinationPath: temporary.path,
          accountId: _accountId!,
        ),
      );
      if (await local.length() > _manifestLimit) {
        throw const FormatException('Manifest too large');
      }
      final decoded = jsonDecode(await local.readAsString());
      if (decoded is! Map ||
          decoded['version'] != 1 ||
          decoded['records'] is! List) {
        throw const FormatException('Invalid iCloud manifest');
      }
      final list = decoded['records'] as List;
      if (list.length > _recordLimit) {
        throw const FormatException('Too many iCloud records');
      }
      for (final item in list) {
        if (item is! Map) throw const FormatException('Invalid iCloud record');
        result.add(ICloudRecord.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return result;
  }

  Future<Map<String, String>> _downloadAssets(
    Iterable<ICloudRecord> records,
    List<ICloudRemoteFile> entries,
    int generation,
  ) async {
    final referenced = <String>{};
    for (final record in records) {
      _collectAssetHashes(record, referenced);
    }
    final remote = {for (final e in entries) e.path: e};
    final result = <String, String>{};
    for (final hash in referenced) {
      if (_replica!.assets[hash] case final existing?
          when await File(existing).exists()) {
        if ((await sha256.bind(File(existing).openRead()).first).toString() ==
            hash) {
          result[hash] = existing;
          continue;
        }
      }
      final path = 'sync-v1/assets/$hash';
      final remoteFile = remote[path];
      if (remoteFile == null ||
          remoteFile.uploaded == false ||
          remoteFile.uploadError != null) {
        throw const FormatException('Missing iCloud asset');
      }
      final destination = File(p.join(_accountDirectory!.path, 'assets', hash));
      await destination.parent.create(recursive: true);
      final localPath = await _transport.read(
        path: path,
        destinationPath: '${destination.path}.partial',
        accountId: _accountId!,
      );
      if (!_active(generation)) return result;
      final partial = File(localPath);
      if ((await sha256.bind(partial.openRead()).first).toString() != hash) {
        throw const FormatException('Invalid iCloud asset hash');
      }
      if (partial.path != destination.path) {
        if (await destination.exists()) await destination.delete();
        await partial.rename(destination.path);
      }
      result[hash] = destination.path;
    }
    return result;
  }

  Future<void> _publish(List<ICloudRemoteFile> entries, int generation) async {
    final replica = _replica!;
    final listed = {for (final entry in entries) entry.path: entry};
    final confirmed = {
      for (final entry in entries.where(
        (e) => e.uploaded == true && e.uploadError == null,
      ))
        entry.path,
    };
    var pendingAssets = false;
    final referenced = <String>{};
    for (final record in replica.records.values) {
      _collectAssetHashes(record, referenced);
    }
    for (final hash in referenced) {
      if (!_hashPattern.hasMatch(hash)) {
        throw const FormatException('Invalid local asset hash');
      }
      final path = 'sync-v1/assets/$hash';
      if (confirmed.contains(path)) continue;
      final remote = listed[path];
      final localPath = replica.assets[hash];
      if (remote != null && remote.uploadError == null) {
        pendingAssets = true;
        continue;
      }
      if (localPath == null) {
        _status = 'error';
        _error = remote?.uploadError == null
            ? 'missingAsset'
            : 'assetUploadFailed';
        return;
      }
      final file = File(localPath);
      if (!await file.exists() ||
          (await sha256.bind(file.openRead()).first).toString() != hash) {
        throw const FormatException('Invalid local asset');
      }
      if (!_active(generation)) return;
      final accepted = await _transport.write(
        path: path,
        sourcePath: file.path,
        accountId: _accountId!,
      );
      if (!accepted.uploaded) {
        if (accepted.uploadError != null) {
          _status = 'error';
          _error = 'assetUploadFailed';
          return;
        }
        pendingAssets = true;
      }
    }
    if (pendingAssets) {
      _status = 'pendingUpload';
      return;
    }
    if (!_active(generation)) return;
    final manifest = File(
      p.join(_accountDirectory!.path, 'outgoing-manifest.json'),
    );
    await _atomicWrite(
      manifest,
      jsonEncode({
        'version': 1,
        'deviceId': _deviceId,
        'deviceName': _deviceName,
        'records': replica.records.values.map((e) => e.toJson()).toList(),
      }),
    );
    final write = await _transport.write(
      path: 'sync-v1/devices/${_deviceId!}.json',
      sourcePath: manifest.path,
      accountId: _accountId!,
    );
    if (!_active(generation)) return;
    if (!write.uploaded) {
      if (write.uploadError != null) {
        _status = 'error';
        _error = 'manifestUploadFailed';
        return;
      }
      _status = 'pendingUpload';
      return;
    }
    _lastSync = _now();
    _status = _conflicts.isEmpty ? 'idle' : 'conflicts';
  }

  Future<void> _refreshStatus() async {
    if (!_networkAllowed) return;
    final result = await _transport.status();
    _available = result.available && result.accountId != null;
    _accountId = result.accountId;
    _deviceName = result.deviceName;
    final binding = result.installationIdentity;
    if (binding != null) {
      final saved = _preferences.getString(_installationKey);
      if (saved != null && saved != binding) {
        _deviceId = const Uuid().v4();
        await _preferences.setString(_deviceKey, _deviceId!);
      }
      await _preferences.setString(_installationKey, binding);
    }
  }

  Future<void> _pauseForAccountChange() async {
    _generation++;
    _enabled = false;
    _status = 'accountChanged';
    _error = 'accountChanged';
    _timer?.cancel();
    _timer = null;
    _aggregateResolutions.clear();
    await _preferences.setBool(_enabledKey, false);
    _changed();
  }

  Future<void> _loadReplica(String accountId) async {
    final hash = sha256
        .convert(utf8.encode(accountId))
        .toString()
        .substring(0, 24);
    final directory = Directory(p.join(_documents.path, 'icloud-sync', hash));
    if (_accountDirectory?.path == directory.path && _replica != null) return;
    await directory.create(recursive: true);
    _accountDirectory = directory;
    _aggregateResolutions.clear();
    final file = File(p.join(directory.path, 'replica.json'));
    if (!await file.exists()) {
      _replica = _Replica.empty();
      await _persistReplica();
      return;
    }
    final decoded = jsonDecode(await file.readAsString());
    _replica = _Replica.fromJson(decoded);
    _refreshConflicts();
  }

  Future<void> _persistReplica() async {
    final directory = _accountDirectory;
    final replica = _replica;
    if (directory == null || replica == null) return;
    await _atomicWrite(
      File(p.join(directory.path, 'replica.json')),
      jsonEncode(replica.toJson()),
    );
  }

  static Future<void> _atomicWrite(File target, String contents) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');
    await temporary.writeAsString(contents, flush: true);
    if (await backup.exists()) await backup.delete();
    final hadTarget = await target.exists();
    if (hadTarget) await target.rename(backup.path);
    try {
      await temporary.rename(target.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await target.exists() && await backup.exists()) {
        await backup.rename(target.path);
      }
      rethrow;
    }
  }

  void _refreshConflicts() {
    final ordinary =
        _replica?.conflicts.entries
            .map(
              (entry) =>
                  ICloudConflict(entry.key, List.unmodifiable(entry.value)),
            )
            .toList(growable: false) ??
        const [];
    _conflicts = [
      ...ordinary,
      ..._aggregateResolutions.entries.map(
        (entry) => ICloudConflict(entry.key, entry.value.options),
      ),
    ];
  }

  Map<String, _AggregateResolution> _dependentDeletionConflicts(
    Map<String, List<ICloudRecord>> byKey,
    Map<String, List<ICloudRecord>> conflicts,
  ) {
    final result = <String, _AggregateResolution>{};
    for (final parent in byKey.entries.where(
      (entry) => entry.key.startsWith('book:'),
    )) {
      final parentFrontier = syncFrontier(parent.value);
      final tombstones = parentFrontier
          .where((record) => record.value == null)
          .toList();
      if (tombstones.isEmpty) continue;
      final uid = parent.key.substring('book:'.length);
      final dependent = <String, List<ICloudRecord>>{};
      var hasUnsafeLive = parentFrontier.any((record) => record.value != null);
      for (final entry in byKey.entries) {
        if (_belongsToBook(entry.key, entry.value, uid)) {
          dependent[entry.key] = entry.value;
          hasUnsafeLive =
              hasUnsafeLive ||
              syncFrontier(entry.value).any((record) => record.value != null);
        }
      }
      if (dependent.isEmpty || !hasUnsafeLive) continue;
      final liveParent = byKey[parent.key]
          ?.where((record) => record.value != null)
          .toList();
      if (liveParent == null || liveParent.isEmpty) continue;
      final liveChildren = dependent.values
          .expand((records) => syncFrontier(records))
          .where((record) => record.value != null)
          .toList();
      result[parent.key] = _AggregateResolution(
        parentKey: parent.key,
        parentCandidates: byKey[parent.key]!,
        dependents: dependent,
        options: _parentOptions(
          parentFrontier,
          liveParent,
          liveChildren.isEmpty ? [liveParent.first] : liveChildren,
        ),
        deleteParentValue: _deleteParentValue(tombstones, liveParent),
        deleteDependents: true,
      );
      conflicts.remove(parent.key);
      conflicts.removeWhere((key, _) => dependent.containsKey(key));
    }
    for (final parent in byKey.entries.where(
      (entry) => entry.key.startsWith('folder:'),
    )) {
      final parentFrontier = syncFrontier(parent.value);
      final tombstones = parentFrontier
          .where((record) => record.value == null)
          .toList();
      if (tombstones.isEmpty) continue;
      final id = parent.key.substring('folder:'.length);
      final dependent = <String, List<ICloudRecord>>{};
      var hasUnsafeLive = parentFrontier.any((record) => record.value != null);
      for (final entry in byKey.entries) {
        final frontier = syncFrontier(entry.value);
        final belongs = entry.value.any((record) {
          final row = record.value?['row'];
          if (row is! Map) return false;
          return (entry.key.startsWith('folder:') && row['parent_id'] == id) ||
              (entry.key.startsWith('book:') && row['shelf_folder_id'] == id);
        });
        if (belongs) {
          dependent[entry.key] = entry.value;
          hasUnsafeLive =
              hasUnsafeLive ||
              frontier.any((record) {
                final row = record.value?['row'];
                if (row is! Map) return false;
                return row['parent_id'] == id || row['shelf_folder_id'] == id;
              });
        }
      }
      if (dependent.isEmpty || !hasUnsafeLive) continue;
      final liveParent = byKey[parent.key]
          ?.where((record) => record.value != null)
          .toList();
      if (liveParent == null || liveParent.isEmpty) continue;
      final liveDependents = dependent.values
          .expand((records) => syncFrontier(records))
          .where((record) => record.value != null)
          .toList();
      result[parent.key] = _AggregateResolution(
        parentKey: parent.key,
        parentCandidates: byKey[parent.key]!,
        dependents: dependent,
        options: _parentOptions(
          parentFrontier,
          liveParent,
          liveDependents.isEmpty ? [liveParent.first] : liveDependents,
        ),
        deleteParentValue: _deleteParentValue(tombstones, liveParent),
        deleteDependents: false,
      );
      conflicts.remove(parent.key);
      conflicts.removeWhere((key, _) => dependent.containsKey(key));
    }
    return result;
  }

  static List<ICloudRecord> _parentOptions(
    List<ICloudRecord> frontier,
    List<ICloudRecord> historicalLive,
    List<ICloudRecord> representatives,
  ) {
    final candidates = [...frontier];
    if (!frontier.any((record) => record.value != null)) {
      for (final record in syncFrontier(historicalLive)) {
        for (final representative in representatives) {
          candidates.add(
            ICloudRecord(
              key: record.key,
              value: record.value,
              clock: record.clock,
              device: representative.device,
              modifiedAt: representative.modifiedAt,
              writer: representative.writer,
            ),
          );
        }
      }
    }
    final byChoice = <String, ICloudRecord>{};
    for (final candidate in candidates) {
      final value = syncCanonicalJson(candidate.value);
      final key = candidate.value == null
          ? value
          : '$value\u0000${candidate.writerId}';
      byChoice.putIfAbsent(key, () => candidate);
    }
    return byChoice.values.toList(growable: false);
  }

  static Map<String, Object?>? _deleteParentValue(
    List<ICloudRecord> tombstones,
    List<ICloudRecord> historicalLive,
  ) {
    for (final live in historicalLive) {
      if (tombstones.any((tombstone) => tombstone.dominates(live))) {
        return live.value;
      }
    }
    return historicalLive.first.value;
  }

  static bool _belongsToBook(
    String key,
    List<ICloudRecord> candidates,
    String uid,
  ) {
    if (key == 'progress:$uid' || key.startsWith('bookmark:$uid:')) return true;
    return candidates.any((record) => record.value?['uid'] == uid);
  }

  Future<void> _resolveAggregate(
    _AggregateResolution aggregate,
    ICloudRecord chosen,
    List<ICloudRemoteFile> entries,
    int generation,
  ) async {
    final delete = chosen.value == null;
    final selectedWriter = chosen.writerId;
    final records = <String, ICloudRecord>{};
    final localPromotions = <String, ICloudRecord>{};
    final remainingConflicts = <String, List<ICloudRecord>>{};
    final groups = <String, List<ICloudRecord>>{
      aggregate.parentKey: aggregate.parentCandidates,
      ...aggregate.dependents,
    };
    for (final entry in groups.entries) {
      final candidates = entry.value;
      Map<String, Object?>? value;
      if (!delete) {
        if (entry.key == aggregate.parentKey) {
          value = chosen.value;
        } else {
          final frontier = syncFrontier(candidates);
          final selected = frontier
              .where((record) => record.writerId == selectedWriter)
              .toList();
          final distinctValues = {
            for (final record in frontier) syncCanonicalJson(record.value),
          };
          if (selected.isNotEmpty) {
            value = selected.first.value;
          } else if (distinctValues.length == 1) {
            value = frontier.first.value;
          } else {
            remainingConflicts[entry.key] = frontier;
            continue;
          }
        }
      } else if (!aggregate.deleteDependents &&
          entry.key != aggregate.parentKey) {
        final promoted = syncFrontier(candidates)
            .map(
              (record) => ICloudRecord(
                key: record.key,
                value: _promoteFromDeletedFolder(
                  record.value,
                  aggregate.deleteParentValue,
                ),
                clock: record.clock,
                device: record.device,
                modifiedAt: record.modifiedAt,
                writer: record.writer,
              ),
            )
            .toList();
        final selected = promoted
            .where((record) => record.writerId == selectedWriter)
            .toList();
        final distinctValues = {
          for (final record in promoted) syncCanonicalJson(record.value),
        };
        if (selected.isNotEmpty) {
          value = selected.first.value;
        } else if (distinctValues.length == 1) {
          value = promoted.first.value;
        } else {
          remainingConflicts[entry.key] = promoted;
          final current = _replica!.records[entry.key];
          if (current != null) {
            localPromotions[entry.key] = ICloudRecord(
              key: current.key,
              value: _promoteFromDeletedFolder(
                current.value,
                aggregate.deleteParentValue,
              ),
              clock: current.clock,
              device: current.device,
              modifiedAt: current.modifiedAt,
              writer: current.writer,
            );
          }
          continue;
        }
      }
      final replica = _replica!;
      replica.counter++;
      final clock = joinSyncClocks(candidates);
      clock[_deviceId!] = replica.counter;
      records[entry.key] = ICloudRecord(
        key: entry.key,
        value: value,
        clock: clock,
        device: _deviceName ?? 'This device',
        modifiedAt: _now().toUtc().millisecondsSinceEpoch,
        writer: _deviceId,
      );
    }
    final recordsToApply = {...records, ...localPromotions};
    final assets = await _downloadAssets(
      recordsToApply.values,
      entries,
      generation,
    );
    if (!_active(generation) || !canApply) return;
    if (!await _applyRecords(recordsToApply, assets)) return;
    for (final entry in records.entries) {
      _replica!.records[entry.key] = entry.value;
      _replica!.baseline[entry.key] = entry.value.value;
      _replica!.conflicts.remove(entry.key);
    }
    for (final entry in localPromotions.entries) {
      _replica!.records[entry.key] = entry.value;
      _replica!.baseline[entry.key] = entry.value.value;
    }
    _replica!.conflicts.addAll(remainingConflicts);
    _aggregateResolutions.remove(aggregate.parentKey);
    _refreshConflicts();
    await _persistReplica();
    _dataRevision++;
    await _onDataChanged?.call();
    await _publish(entries, generation);
  }

  static Map<String, Object?>? _promoteFromDeletedFolder(
    Map<String, Object?>? value,
    Map<String, Object?>? deletedFolder,
  ) {
    if (value == null) return null;
    final rawRow = value['row'];
    if (rawRow is! Map) return value;
    final row = Map<String, Object?>.from(rawRow);
    final deletedRow = deletedFolder?['row'];
    final parent = deletedRow is Map ? deletedRow['parent_id'] : null;
    if (value['kind'] == 'folder') row['parent_id'] = parent;
    if (value['kind'] == 'book') row['shelf_folder_id'] = parent;
    return Map<String, Object?>.from(value)..['row'] = row;
  }

  void _schedule() {
    _timer?.cancel();
    if (!_foreground || !_enabled || _disposed) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_busy) unawaited(synchronize());
    });
  }

  bool _active(int generation) =>
      !_disposed && _enabled && _networkAllowed && generation == _generation;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  static bool _alwaysApply() => true;

  static void _collectAssetHashes(ICloudRecord record, Set<String> result) {
    final value = record.value;
    if (!record.key.startsWith('book:') ||
        value == null ||
        value['kind'] != 'book') {
      return;
    }
    for (final role in const ['file', 'cover', 'sidecar']) {
      final candidate = value[role];
      if (candidate is String &&
          _hashPattern.hasMatch(candidate.toLowerCase())) {
        result.add(candidate.toLowerCase());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}

class _PendingApply {
  const _PendingApply(this.records, this.assets);
  final Map<String, ICloudRecord> records;
  final Map<String, String> assets;

  Map<String, Object?> toJson() => {
    'records': records.map((key, value) => MapEntry(key, value.toJson())),
    'assets': assets,
  };

  factory _PendingApply.fromJson(Object? value) {
    if (value is! Map || value['records'] is! Map || value['assets'] is! Map) {
      throw const FormatException('Invalid pending iCloud apply');
    }
    return _PendingApply(
      (value['records'] as Map).map(
        (key, record) => MapEntry(
          key as String,
          ICloudRecord.fromJson(Map<String, dynamic>.from(record as Map)),
        ),
      ),
      Map<String, String>.from(value['assets'] as Map),
    );
  }
}

class _AggregateResolution {
  const _AggregateResolution({
    required this.parentKey,
    required this.parentCandidates,
    required this.dependents,
    required this.options,
    required this.deleteParentValue,
    required this.deleteDependents,
  });

  final String parentKey;
  final List<ICloudRecord> parentCandidates;
  final Map<String, List<ICloudRecord>> dependents;
  final List<ICloudRecord> options;
  final Map<String, Object?>? deleteParentValue;
  final bool deleteDependents;
}

class _Replica {
  _Replica({
    required this.counter,
    required this.records,
    required this.baseline,
    required this.assets,
    required this.conflicts,
    this.pendingApply,
  });

  factory _Replica.empty() => _Replica(
    counter: 0,
    records: {},
    baseline: {},
    assets: {},
    conflicts: {},
  );

  int counter;
  final Map<String, ICloudRecord> records;
  final Map<String, Map<String, Object?>?> baseline;
  Map<String, String> assets;
  Map<String, List<ICloudRecord>> conflicts;
  _PendingApply? pendingApply;

  Map<String, Object?> toJson() => {
    'version': 1,
    'counter': counter,
    'records': records.map((key, value) => MapEntry(key, value.toJson())),
    'baseline': baseline,
    'assets': assets,
    'conflicts': conflicts.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    ),
    if (pendingApply != null) 'pendingApply': pendingApply!.toJson(),
  };

  factory _Replica.fromJson(Object? value) {
    if (value is! Map ||
        value['version'] != 1 ||
        value['counter'] is! int ||
        value['records'] is! Map ||
        value['baseline'] is! Map ||
        value['assets'] is! Map ||
        value['conflicts'] is! Map) {
      throw const FormatException('Invalid iCloud replica');
    }
    return _Replica(
      counter: value['counter'] as int,
      records: (value['records'] as Map).map(
        (key, record) => MapEntry(
          key as String,
          ICloudRecord.fromJson(Map<String, dynamic>.from(record as Map)),
        ),
      ),
      baseline: (value['baseline'] as Map).map(
        (key, item) => MapEntry(
          key as String,
          item == null ? null : Map<String, Object?>.from(item as Map),
        ),
      ),
      assets: Map<String, String>.from(value['assets'] as Map),
      conflicts: (value['conflicts'] as Map).map(
        (key, records) => MapEntry(
          key as String,
          (records as List)
              .map(
                (record) => ICloudRecord.fromJson(
                  Map<String, dynamic>.from(record as Map),
                ),
              )
              .toList(),
        ),
      ),
      pendingApply: value['pendingApply'] == null
          ? null
          : _PendingApply.fromJson(value['pendingApply']),
    );
  }
}
