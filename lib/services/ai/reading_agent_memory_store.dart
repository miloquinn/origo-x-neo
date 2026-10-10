import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, device-local preferences. Reading facts remain in the existing SQLite
/// tables and are queried afresh; they are never copied into this store.
class ReadingAgentPermissions {
  const ReadingAgentPermissions({
    this.enabled = false,
    this.readingStats = true,
    this.library = true,
    this.bookSources = true,
    this.proactive = false,
  });

  final bool enabled;
  final bool readingStats;
  final bool library;
  final bool bookSources;
  final bool proactive;

  ReadingAgentPermissions copyWith({
    bool? enabled,
    bool? readingStats,
    bool? library,
    bool? bookSources,
    bool? proactive,
  }) => ReadingAgentPermissions(
    enabled: enabled ?? this.enabled,
    readingStats: readingStats ?? this.readingStats,
    library: library ?? this.library,
    bookSources: bookSources ?? this.bookSources,
    proactive: proactive ?? this.proactive,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'readingStats': readingStats,
    'library': library,
    'bookSources': bookSources,
    'proactive': proactive,
  };

  static ReadingAgentPermissions fromJson(Object? value) {
    final json = value is Map ? value : const <String, dynamic>{};
    return ReadingAgentPermissions(
      enabled: json['enabled'] == true,
      readingStats: json['readingStats'] != false,
      library: json['library'] != false,
      bookSources: json['bookSources'] != false,
      proactive: json['proactive'] == true,
    );
  }
}

class ReadingAgentMemory {
  const ReadingAgentMemory({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.origin = 'user',
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Agent suggestions enter durable memory only after the user saves them.
  final String origin;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'origin': origin,
    'confirmedByUser': true,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  static ReadingAgentMemory? fromJson(Object? value) {
    if (value is! Map || value['confirmedByUser'] != true) return null;
    final id = value['id'];
    final text = value['text'];
    final created = DateTime.tryParse('${value['createdAt']}');
    final updated = DateTime.tryParse('${value['updatedAt']}');
    if (id is! String ||
        id.isEmpty ||
        text is! String ||
        text.trim().isEmpty ||
        text.length > 500 ||
        created == null ||
        updated == null) {
      return null;
    }
    return ReadingAgentMemory(
      id: id,
      text: text,
      createdAt: created.toLocal(),
      updatedAt: updated.toLocal(),
      origin: value['origin'] == 'agent_suggestion'
          ? 'agent_suggestion'
          : 'user',
    );
  }
}

class ReadingAgentMemoryStore extends ChangeNotifier {
  ReadingAgentMemoryStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const prefsKey = 'ai_reading_agent_v1';
  static const maxMemories = 50;
  static const maxFeedback = 50;
  final Future<SharedPreferences> Function() _preferences;
  ReadingAgentPermissions _permissions = const ReadingAgentPermissions();
  List<ReadingAgentMemory> _memories = const [];
  List<Map<String, String>> _feedback = const [];
  DateTime? _lastProactiveAt;
  Future<void>? _loading;
  Future<void> _mutations = Future<void>.value();
  bool _loaded = false;
  bool _disposed = false;

  ReadingAgentPermissions get permissions => _permissions;
  List<ReadingAgentMemory> get memories => _memories;
  List<Map<String, String>> get feedback => _feedback;
  DateTime? get lastProactiveAt => _lastProactiveAt;

  Future<void> ensureLoaded() {
    if (_disposed) throw StateError('ReadingAgentMemoryStore is disposed');
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final prefs = await _preferences();
    final raw = prefs.getString(prefsKey);
    try {
      final json = raw == null ? null : jsonDecode(raw);
      if (json is Map && json['version'] == 1) {
        _permissions = ReadingAgentPermissions.fromJson(json['permissions']);
        final memories = json['memories'];
        if (memories is List) {
          _memories = List.unmodifiable(
            memories
                .map(ReadingAgentMemory.fromJson)
                .whereType<ReadingAgentMemory>()
                .take(maxMemories),
          );
        }
        final feedback = json['feedback'];
        if (feedback is List) {
          _feedback = List.unmodifiable(
            feedback
                .whereType<Map>()
                .where((entry) {
                  return entry['title'] is String &&
                      entry['author'] is String &&
                      const [
                        'interested',
                        'not_interested',
                      ].contains(entry['value']);
                })
                .take(maxFeedback)
                .map(
                  (entry) => Map<String, String>.unmodifiable({
                    'title': _bounded(entry['title'] as String, 200),
                    'author': _bounded(entry['author'] as String, 200),
                    'value': entry['value'] as String,
                  }),
                ),
          );
        }
        _lastProactiveAt = DateTime.tryParse('${json['lastProactiveAt']}');
      }
    } on FormatException {
      // Corrupt or future data never enables data sharing or proactive calls.
    }
    _loaded = true;
    if (!_disposed) notifyListeners();
  }

  Future<void> setPermissions(ReadingAgentPermissions value) =>
      _mutate(() => _permissions = value);

  Future<void> saveMemory({
    required String text,
    String? id,
    String origin = 'user',
  }) => _mutate(() {
    final normalized = text.trim();
    if (normalized.isEmpty || normalized.length > 500) {
      throw ArgumentError('Memory must contain 1–500 characters');
    }
    final now = DateTime.now();
    final existing = _memories.where((entry) => entry.id == id).firstOrNull;
    final item = ReadingAgentMemory(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      text: normalized,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      origin: origin == 'agent_suggestion' ? 'agent_suggestion' : 'user',
    );
    _memories = List.unmodifiable(
      [
        item,
        ..._memories.where(
          (entry) => entry.id != item.id && entry.text != item.text,
        ),
      ].take(maxMemories),
    );
  });

  Future<void> deleteMemory(String id) => _mutate(() {
    _memories = List.unmodifiable(_memories.where((entry) => entry.id != id));
  });

  Future<void> recordFeedback({
    required String title,
    required String author,
    required bool interested,
  }) => _mutate(() {
    final item = Map<String, String>.unmodifiable({
      'title': _bounded(title, 200),
      'author': _bounded(author, 200),
      'value': interested ? 'interested' : 'not_interested',
    });
    _feedback = List.unmodifiable(
      [
        item,
        ..._feedback.where(
          (entry) => entry['title'] != title || entry['author'] != author,
        ),
      ].take(maxFeedback),
    );
  });

  Future<void> markProactiveDelivered(DateTime at) =>
      _mutate(() => _lastProactiveAt = at);

  Future<void> clearMemories() => _mutate(() {
    _memories = const [];
    _feedback = const [];
  });

  /// A readable view, not another source of truth.
  String toMarkdown() => [
    '# Reading preferences',
    ..._memories.map((entry) => '- ${entry.text}'),
    if (_feedback.isNotEmpty) '\n# Recommendation feedback',
    ..._feedback.map(
      (entry) => '- ${entry['title']} · ${entry['author']}: ${entry['value']}',
    ),
  ].join('\n');

  Future<void> _mutate(void Function() change) {
    final result = _mutations.then((_) async {
      await ensureLoaded();
      final oldPermissions = _permissions;
      final oldMemories = _memories;
      final oldFeedback = _feedback;
      final oldProactive = _lastProactiveAt;
      try {
        change();
        final prefs = await _preferences();
        final saved = await prefs.setString(
          prefsKey,
          jsonEncode({
            'version': 1,
            'permissions': _permissions.toJson(),
            'memories': _memories.map((entry) => entry.toJson()).toList(),
            'feedback': _feedback,
            'lastProactiveAt': _lastProactiveAt?.toUtc().toIso8601String(),
          }),
        );
        if (!saved) {
          throw StateError('Reading Agent preferences were not saved');
        }
      } catch (_) {
        _permissions = oldPermissions;
        _memories = oldMemories;
        _feedback = oldFeedback;
        _lastProactiveAt = oldProactive;
        rethrow;
      }
      if (!_disposed) notifyListeners();
    });
    _mutations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  static String _bounded(String value, int limit) =>
      value.length <= limit ? value : value.substring(0, limit);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
