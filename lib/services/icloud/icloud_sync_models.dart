import 'dart:convert';

/// Stable JSON makes record comparisons independent of map insertion order.
String syncCanonicalJson(Object? value) => jsonEncode(_ordered(value));
Object? _ordered(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {for (final key in keys) key: _ordered(value[key])};
  }
  if (value is List) return value.map(_ordered).toList();
  return value;
}

class ICloudRecord {
  const ICloudRecord({
    required this.key,
    required this.value,
    required this.clock,
    required this.device,
    required this.modifiedAt,
    this.writer,
  });
  final String key;

  /// Null is a durable deletion, not a missing remote record.
  final Map<String, Object?>? value;
  final Map<String, int> clock;
  final String device;
  final int modifiedAt;
  final String? writer;
  String get writerId => writer ?? device;

  bool dominates(ICloudRecord other) =>
      other.clock.entries.every((e) => (clock[e.key] ?? 0) >= e.value) &&
      clock.entries.any((e) => e.value > (other.clock[e.key] ?? 0));
  bool sameValue(ICloudRecord other) =>
      syncCanonicalJson(value) == syncCanonicalJson(other.value);

  Map<String, Object?> toJson() => {
    'key': key,
    'value': value,
    'clock': clock,
    'device': device,
    'modifiedAt': modifiedAt,
    if (writer != null) 'writer': writer,
  };
  factory ICloudRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['clock'];
    final key = json['key'];
    final device = json['device'];
    final modifiedAt = json['modifiedAt'];
    final value = json['value'];
    final writer = json['writer'];
    if (key is! String ||
        key.isEmpty ||
        key.length > 4096 ||
        device is! String ||
        device.isEmpty ||
        device.length > 256 ||
        modifiedAt is! int ||
        modifiedAt < 0 ||
        (writer != null &&
            (writer is! String || writer.isEmpty || writer.length > 256)) ||
        raw is! Map ||
        raw.isEmpty ||
        raw.length > 256 ||
        raw.entries.any(
          (e) =>
              e.key is! String ||
              (e.key as String).isEmpty ||
              (e.key as String).length > 256 ||
              e.value is! int ||
              (e.value as int) <= 0,
        ) ||
        (value != null && (value is! Map || !_validJson(value, 0)))) {
      throw const FormatException('Invalid iCloud record');
    }
    return ICloudRecord(
      key: key,
      value: value == null ? null : Map<String, Object?>.from(value),
      clock: Map<String, int>.from(raw),
      device: device,
      modifiedAt: modifiedAt,
      writer: writer as String?,
    );
  }
}

bool _validJson(Object? value, int depth) {
  if (depth > 64) return false;
  if (value == null || value is bool || value is String || value is int) {
    return true;
  }
  if (value is double) return value.isFinite;
  if (value is List) return value.every((item) => _validJson(item, depth + 1));
  if (value is Map) {
    return value.length <= 100000 &&
        value.entries.every(
          (entry) =>
              entry.key is String &&
              (entry.key as String).length <= 4096 &&
              _validJson(entry.value, depth + 1),
        );
  }
  return false;
}

Map<String, int> joinSyncClocks(Iterable<ICloudRecord> records) {
  final result = <String, int>{};
  for (final record in records) {
    for (final entry in record.clock.entries) {
      if (entry.value > (result[entry.key] ?? 0)) {
        result[entry.key] = entry.value;
      }
    }
  }
  return result;
}

/// Keep concurrent values; never choose a device by wall-clock time.
List<ICloudRecord> syncFrontier(Iterable<ICloudRecord> records) {
  final result = <ICloudRecord>[];
  for (final record in records) {
    if (result.any((r) => r.dominates(record))) continue;
    result.removeWhere(record.dominates);
    if (!result.any(
      (r) =>
          syncCanonicalJson(r.toJson()) == syncCanonicalJson(record.toJson()),
    )) {
      result.add(record);
    }
  }
  return result;
}

class ICloudLocalSnapshot {
  const ICloudLocalSnapshot(this.values, this.assets);
  final Map<String, Map<String, Object?>> values;

  /// SHA-256 => a local file path; paths never enter cloud records.
  final Map<String, String> assets;
}

abstract class ICloudSyncStore {
  Future<ICloudLocalSnapshot> capture();
  Future<bool> apply(
    Map<String, ICloudRecord> records,
    Map<String, String> assets,
  );
}

class ICloudConflict {
  const ICloudConflict(this.key, this.versions);
  final String key;
  final List<ICloudRecord> versions;
  String get label =>
      versions.map((r) => r.value?['label']).whereType<String>().firstOrNull ??
      key;
}
