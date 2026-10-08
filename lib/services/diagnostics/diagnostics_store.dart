import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingDiagnosticsReport {
  const PendingDiagnosticsReport({required this.owner, required this.report});

  final String owner;
  final Map<String, dynamic> report;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'owner': owner,
    'report': report,
  };

  static PendingDiagnosticsReport? fromJson(Object? value) {
    if (value is! Map) return null;
    final owner = value['owner'];
    final report = value['report'];
    if (owner is! String || owner.isEmpty || report is! Map) return null;
    return PendingDiagnosticsReport(
      owner: owner,
      report: Map<String, dynamic>.from(report),
    );
  }
}

abstract interface class DiagnosticsStore {
  Future<bool> readEnabled();
  Future<void> writeEnabled(bool enabled);
  Future<bool?> readConsentChoice();
  Future<void> writeConsentChoice(bool enabled);
  Future<List<PendingDiagnosticsReport>> readPending();
  Future<void> writePending(List<PendingDiagnosticsReport> reports);
  Future<void> clearPending();
}

class SharedPreferencesDiagnosticsStore implements DiagnosticsStore {
  SharedPreferencesDiagnosticsStore({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  // member_ records are device-local and excluded from WebDAV app backups.
  static const enabledKey = 'member_diagnostics_enabled_v1';
  static const consentChoiceKey = 'member_diagnostics_consent_choice_v1';
  static const pendingKey = 'member_diagnostics_pending_v1';
  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<bool> readEnabled() async =>
      (await _preferences()).getBool(enabledKey) ?? false;

  @override
  Future<void> writeEnabled(bool enabled) async {
    final saved = await (await _preferences()).setBool(enabledKey, enabled);
    if (!saved) throw StateError('Failed to save diagnostics setting.');
  }

  @override
  Future<bool?> readConsentChoice() async =>
      (await _preferences()).getBool(consentChoiceKey);

  @override
  Future<void> writeConsentChoice(bool enabled) async {
    final saved = await (await _preferences()).setBool(
      consentChoiceKey,
      enabled,
    );
    if (!saved) throw StateError('Failed to save diagnostics consent.');
  }

  @override
  Future<List<PendingDiagnosticsReport>> readPending() async {
    final source = (await _preferences()).getString(pendingKey);
    if (source == null || source.isEmpty) return <PendingDiagnosticsReport>[];
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) return <PendingDiagnosticsReport>[];
      final reports = decoded
          .map(PendingDiagnosticsReport.fromJson)
          .whereType<PendingDiagnosticsReport>()
          .toList();
      return reports.length <= 20
          ? reports
          : reports.sublist(reports.length - 20);
    } catch (_) {
      return <PendingDiagnosticsReport>[];
    }
  }

  @override
  Future<void> writePending(List<PendingDiagnosticsReport> reports) async {
    final bounded = reports.length <= 20
        ? reports
        : reports.sublist(reports.length - 20);
    await (await _preferences()).setString(
      pendingKey,
      jsonEncode(bounded.map((report) => report.toJson()).toList()),
    );
  }

  @override
  Future<void> clearPending() async {
    await (await _preferences()).remove(pendingKey);
  }
}
