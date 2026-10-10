import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'replace_rule_executor.dart';
import 'replace_rule_semantics.dart';

class ReplaceRule {
  const ReplaceRule({
    required this.id,
    required this.name,
    required this.pattern,
    required this.replacement,
    this.group = '',
    this.scope = '',
    this.excludeScope = '',
    this.enabled = true,
    this.isRegex = true,
    this.scopeTitle = false,
    this.scopeContent = true,
    this.order = 0,
    this.timeoutMillisecond = 3000,
  });

  final String id;
  final String name;
  final String pattern;
  final String replacement;
  final String group;
  final String scope;
  final String excludeScope;
  final bool enabled;
  final bool isRegex;
  final bool scopeTitle;
  final bool scopeContent;
  final int order;
  final int timeoutMillisecond;
  int get validTimeoutMillisecond =>
      timeoutMillisecond > 0 ? timeoutMillisecond : 3000;

  ReplaceRule copyWith({
    String? id,
    String? name,
    String? pattern,
    String? replacement,
    String? group,
    String? scope,
    String? excludeScope,
    bool? enabled,
    bool? isRegex,
    bool? scopeTitle,
    bool? scopeContent,
    int? order,
    int? timeoutMillisecond,
  }) => ReplaceRule(
    id: id ?? this.id,
    name: name ?? this.name,
    pattern: pattern ?? this.pattern,
    replacement: replacement ?? this.replacement,
    group: group ?? this.group,
    scope: scope ?? this.scope,
    excludeScope: excludeScope ?? this.excludeScope,
    enabled: enabled ?? this.enabled,
    isRegex: isRegex ?? this.isRegex,
    scopeTitle: scopeTitle ?? this.scopeTitle,
    scopeContent: scopeContent ?? this.scopeContent,
    order: order ?? this.order,
    timeoutMillisecond: timeoutMillisecond ?? this.timeoutMillisecond,
  );

  Map<String, dynamic> toJson() => {
    'id': int.tryParse(id) ?? id,
    'name': name,
    'pattern': pattern,
    'replacement': replacement,
    'group': group,
    'scope': scope,
    'excludeScope': excludeScope,
    'isEnabled': enabled,
    'isRegex': isRegex,
    'scopeTitle': scopeTitle,
    'scopeContent': scopeContent,
    'order': order,
    'timeoutMillisecond': timeoutMillisecond,
  };

  factory ReplaceRule.fromJson(
    Map<String, dynamic> json,
    int index, {
    bool tolerateInvalid = false,
  }) {
    final pattern = '${json['pattern'] ?? json['regex'] ?? ''}';
    if (pattern.trim().isEmpty && !tolerateInvalid) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.emptyPattern,
      );
    }
    final legacyFormat =
        !json.containsKey('pattern') && json.containsKey('regex');
    final scopeTitle = _jsonBool(json['scopeTitle'], fallback: false);
    final scopeContent = _jsonBool(json['scopeContent'], fallback: true);
    final enabled = _jsonBool(
      json['enabled'] ?? json['isEnabled'] ?? json['enable'],
      fallback: true,
    );
    final replacement = '${json['replacement'] ?? ''}';
    return ReplaceRule(
      id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch + index}',
      name: '${json['name'] ?? json['replaceSummary'] ?? '导入规则'}',
      pattern: pattern,
      replacement: replacement,
      group: '${json['group'] ?? ''}',
      scope: '${json['scope'] ?? json['useTo'] ?? ''}',
      excludeScope: '${json['excludeScope'] ?? ''}',
      enabled:
          enabled &&
          pattern.trim().isNotEmpty &&
          (scopeTitle || scopeContent) &&
          !isUnsupportedReplaceRuleReplacement(
            replacement,
            isRegex: _jsonBool(json['isRegex'], fallback: !legacyFormat),
          ),
      isRegex: _jsonBool(json['isRegex'], fallback: !legacyFormat),
      scopeTitle: scopeTitle,
      scopeContent: scopeContent,
      order:
          _jsonInt(
            json['order'] ?? json['sortOrder'] ?? json['serialNumber'],
          ) ??
          index,
      timeoutMillisecond:
          _jsonInt(json['timeoutMillisecond'] ?? json['timeout']) ?? 3000,
    );
  }
}

enum ReplaceRuleValidationKind {
  emptyPattern,
  patternTooLong,
  invalidRegex,
  tooManyRules,
  missingTarget,
  unsupportedReplacement,
}

class ReplaceRuleValidationException extends FormatException {
  const ReplaceRuleValidationException(this.kind, [String detail = ''])
    : super(detail);

  final ReplaceRuleValidationKind kind;
}

bool _jsonBool(Object? value, {required bool fallback}) => switch (value) {
  final bool value => value,
  final num value => value != 0,
  final String value when value.toLowerCase() == 'true' || value == '1' => true,
  final String value when value.toLowerCase() == 'false' || value == '0' =>
    false,
  _ => fallback,
};

int? _jsonInt(Object? value) => switch (value) {
  final num value => value.toInt(),
  final String value => int.tryParse(value),
  _ => null,
};

class ReplaceRuleService extends ChangeNotifier {
  ReplaceRuleService({ReplaceRuleExecutor? executor})
    : _executor = executor ?? ReplaceRuleExecutor();

  static const preferenceKey = 'reader_replace_rules_v1';
  static const defaultEnabledPreferenceKey = 'reader_replace_rules_enabled_v1';
  static const bookEnabledPreferenceKey =
      'reader_replace_rules_book_enabled_v1';
  static const maxRules = 5000;
  static const maxPatternLength = 20000;
  static const maxImportBytes = 8 * 1024 * 1024;

  List<ReplaceRule> _rules = const [];
  bool _loaded = false;
  bool _defaultEnabled = true;
  Map<String, bool> _bookEnabled = const <String, bool>{};
  Future<void>? _loading;
  int _revision = 0;
  String? _rulesSignatureCache;
  final ReplaceRuleExecutor _executor;
  final List<ReplaceRuleDiagnostic> _recentDiagnostics =
      <ReplaceRuleDiagnostic>[];
  StreamSubscription<ReplaceRuleDiagnostic>? _diagnosticSubscription;
  Future<void>? _closing;
  bool _closed = false;
  bool _notifierDisposed = false;

  List<ReplaceRule> get rules => _rules;
  bool get isLoaded => _loaded;
  int get revision => _revision;
  bool get defaultEnabled => _defaultEnabled;
  String get rulesSignature => _rulesSignatureCache ??= _buildRulesSignature();

  String _buildRulesSignature() {
    final payload = <String>[
      'default=$_defaultEnabled',
      ...(_bookEnabled.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
          .map((entry) => 'book:${entry.key}=${entry.value}'),
      ...enabledRules.map(
        (rule) => jsonEncode(<Object?>[
          rule.id,
          rule.pattern,
          rule.replacement,
          rule.scope,
          rule.excludeScope,
          rule.isRegex,
          rule.scopeTitle,
          rule.scopeContent,
          rule.order,
          rule.validTimeoutMillisecond,
        ]),
      ),
    ].join('\u0000');
    return 'replace-rules-v2:${sha1.convert(utf8.encode(payload))}';
  }

  List<ReplaceRuleDiagnostic> get recentDiagnostics =>
      List<ReplaceRuleDiagnostic>.unmodifiable(_recentDiagnostics);
  List<ReplaceRule> get enabledRules =>
      _rules.where((rule) => rule.enabled).toList(growable: false);

  Future<void> load() {
    _ensureOpen();
    if (_loaded) return Future.value();
    _listenToExecutorDiagnostics();
    return _loading ??= _loadInternal();
  }

  void _listenToExecutorDiagnostics() {
    _diagnosticSubscription ??= _executor.diagnostics.listen((diagnostic) {
      if (_closed) return;
      _recentDiagnostics.add(diagnostic);
      if (_recentDiagnostics.length > 32) _recentDiagnostics.removeAt(0);
      debugPrint(
        'replacement rule ${diagnostic.kind.name}: '
        '${diagnostic.ruleName ?? diagnostic.ruleId ?? 'unknown'} '
        '${diagnostic.detail}',
      );
    });
  }

  Future<void> _loadInternal() async {
    var loadedRules = const <ReplaceRule>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_closed) return;
      final raw = prefs.getString(preferenceKey);
      _defaultEnabled = prefs.getBool(defaultEnabledPreferenceKey) ?? true;
      final rawBookEnabled = prefs.getString(bookEnabledPreferenceKey);
      if (rawBookEnabled != null) {
        try {
          final decodedOverrides = jsonDecode(rawBookEnabled);
          if (decodedOverrides is Map) {
            _bookEnabled = decodedOverrides.map(
              (key, value) => MapEntry('$key', value == true),
            );
          }
        } on FormatException catch (error) {
          debugPrint('replace rule book overrides load failed: $error');
        }
      }
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          loadedRules =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) => _sanitizePersistedRule(
                      ReplaceRule.fromJson(
                        Map<String, dynamic>.from(item),
                        0,
                        tolerateInvalid: true,
                      ),
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.order.compareTo(b.order));
        }
      }
    } catch (error) {
      debugPrint('replace rules load failed: $error');
    } finally {
      _loading = null;
      if (!_closed) {
        _rules = loadedRules;
        _loaded = true;
        _revision++;
        _rulesSignatureCache = null;
        notifyListeners();
      }
    }
  }

  Future<void> saveAll(List<ReplaceRule> rules) async {
    _ensureOpen();
    if (rules.length > maxRules) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.tooManyRules,
      );
    }
    final normalized = rules
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(order: entry.key))
        .toList(growable: false);
    for (final rule in normalized) {
      validate(
        rule,
        allowDisabledMissingTarget: true,
        allowDisabledUnsupportedReplacement: true,
        allowDisabledInvalid: true,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      preferenceKey,
      jsonEncode(normalized.map((rule) => rule.toJson()).toList()),
    );
    if (_closed) return;
    _rules = normalized;
    _loaded = true;
    _revision++;
    _rulesSignatureCache = null;
    notifyListeners();
  }

  /// Applies a WebDAV snapshot without renumbering its cross-device order.
  ///
  /// Normal UI edits intentionally compact order values. During sync, records
  /// arrive one at a time, so preserving their remote order until the whole
  /// batch has landed prevents intermediate writes from reversing two rules.
  Future<void> replaceFromSync(List<ReplaceRule> rules) async {
    _ensureOpen();
    if (rules.length > maxRules) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.tooManyRules,
      );
    }
    final ordered = rules.map(_sanitizePersistedRule).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    for (final rule in ordered) {
      validate(
        rule,
        allowDisabledMissingTarget: true,
        allowDisabledUnsupportedReplacement: true,
        allowDisabledInvalid: true,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      preferenceKey,
      jsonEncode(ordered.map((rule) => rule.toJson()).toList()),
    );
    if (_closed) return;
    _rules = ordered;
    _loaded = true;
    _revision++;
    _rulesSignatureCache = null;
    notifyListeners();
  }

  Future<void> upsert(ReplaceRule rule) async {
    validate(rule);
    final next = [..._rules];
    final index = next.indexWhere((item) => item.id == rule.id);
    if (index < 0) {
      next.add(rule.copyWith(order: next.length));
    } else {
      next[index] = rule.copyWith(order: next[index].order);
    }
    await saveAll(next);
  }

  Future<void> remove(String id) =>
      saveAll(_rules.where((rule) => rule.id != id).toList());

  Future<void> toggle(String id, bool enabled) async {
    await saveAll(
      _rules
          .map((rule) => rule.id == id ? rule.copyWith(enabled: enabled) : rule)
          .toList(),
    );
  }

  static void validate(
    ReplaceRule rule, {
    bool allowDisabledMissingTarget = false,
    bool allowDisabledUnsupportedReplacement = false,
    bool allowDisabledInvalid = false,
  }) {
    if (allowDisabledInvalid && !rule.enabled) return;
    if (rule.pattern.trim().isEmpty) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.emptyPattern,
      );
    }
    if (rule.pattern.length > maxPatternLength) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.patternTooLong,
      );
    }
    if (!rule.scopeTitle &&
        !rule.scopeContent &&
        !(allowDisabledMissingTarget && !rule.enabled)) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.missingTarget,
      );
    }
    if (isUnsupportedReplaceRuleReplacement(
          rule.replacement,
          isRegex: rule.isRegex,
        ) &&
        !(allowDisabledUnsupportedReplacement && !rule.enabled)) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.unsupportedReplacement,
      );
    }
    if (rule.isRegex) {
      try {
        compileReplaceRulePattern(rule.pattern);
      } on FormatException catch (error) {
        throw ReplaceRuleValidationException(
          ReplaceRuleValidationKind.invalidRegex,
          error.message,
        );
      }
    }
  }

  List<ReplaceRule> mergeImported(Iterable<ReplaceRule> imported) {
    final merged = [..._rules];
    for (final rule in imported) {
      validate(rule);
      final index = merged.indexWhere(
        (existing) =>
            existing.id == rule.id ||
            (existing.name == rule.name && existing.pattern == rule.pattern),
      );
      if (index < 0) {
        merged.add(rule);
      } else {
        merged[index] = rule.copyWith(order: merged[index].order);
      }
    }
    if (merged.length > maxRules) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.tooManyRules,
      );
    }
    return merged;
  }

  Future<ReplaceRuleExecutionResult> applyBatchAsync(
    List<String> inputs, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
    bool preserveNonEmpty = false,
    List<List<ReplaceRuleTextRange>>? ranges,
  }) async {
    if (ranges != null && ranges.length != inputs.length) {
      throw ArgumentError.value(
        ranges.length,
        'ranges',
        'Must contain one range list for each input.',
      );
    }
    await load();
    if (!isEnabledForBook(bookId ?? '', eligibleByDefault: eligibleByDefault)) {
      return ReplaceRuleExecutionResult(
        values: List<String>.from(inputs),
        mappedRanges: _copyReplaceRuleRanges(ranges),
      );
    }
    final signature = rulesSignature;
    final allExecutionRules = enabledRules
        .map(_executionRule)
        .toList(growable: false);
    final executionRules = allExecutionRules
        .where(
          (rule) =>
              (title ? rule.scopeTitle : rule.scopeContent) &&
              replaceRuleMatchesScope(rule, bookTitle, sourceName, sourceUrl),
        )
        .toList(growable: false);
    if (executionRules.isEmpty || inputs.isEmpty) {
      return ReplaceRuleExecutionResult(
        values: List<String>.from(inputs),
        mappedRanges: _copyReplaceRuleRanges(ranges),
      );
    }
    final normalizedInputs = <String>[];
    final normalizedRanges = ranges == null
        ? null
        : <List<ReplaceRuleTextRange>>[];
    for (var index = 0; index < inputs.length; index++) {
      if (title) {
        normalizedInputs.add(inputs[index]);
        normalizedRanges?.add(List<ReplaceRuleTextRange>.from(ranges![index]));
      } else if (ranges == null) {
        normalizedInputs.add(_normalizeReplaceRuleContent(inputs[index]));
      } else {
        final normalized = normalizeReplaceRuleContentWithRanges(
          inputs[index],
          ranges[index],
        );
        normalizedInputs.add(normalized.text);
        normalizedRanges!.add(normalized.ranges);
      }
    }
    // Literal-only pipelines have deterministic linear behavior and are
    // cheaper to execute directly than to copy chapter/catalog strings through
    // an isolate. Every regex pipeline still uses the killable worker below.
    if (executionRules.every((rule) => !rule.isRegex)) {
      final prepared = executionRules.map(PreparedReplaceRule.new).toList();
      final outputLimit = replaceRuleOutputCharacterLimit(normalizedInputs);
      final values = <String>[];
      final mappedRanges = normalizedRanges == null
          ? null
          : <List<ReplaceRuleTextRange>>[];
      final diagnostics = <ReplaceRuleDiagnostic>[];
      var degraded = false;
      final effectiveRuleIds = <String>{};
      for (
        var inputIndex = 0;
        inputIndex < normalizedInputs.length;
        inputIndex++
      ) {
        final input = normalizedInputs[inputIndex];
        var output = input;
        var outputRanges = normalizedRanges == null
            ? const <ReplaceRuleTextRange>[]
            : normalizedRanges[inputIndex];
        final inputEffectiveRuleIds = <String>{};
        var rolledBack = false;
        for (final rule in prepared) {
          final before = output;
          final mapped = normalizedRanges == null
              ? null
              : rule.applyWithRanges(output, outputRanges);
          final candidate = mapped?.text ?? rule.apply(output);
          if (title && before.trim().isNotEmpty && candidate.trim().isEmpty) {
            diagnostics.add(
              ReplaceRuleDiagnostic(
                kind: ReplaceRuleDiagnosticKind.emptyOutput,
                rulesSignature: signature,
                ruleId: rule.source.id,
                ruleName: rule.source.name,
                ruleFingerprint: rule.source.fingerprint,
              ),
            );
            degraded = true;
          } else {
            output = candidate;
            if (mapped != null) outputRanges = mapped.ranges;
            if (output != before) inputEffectiveRuleIds.add(rule.source.id);
          }
          if (output.length > outputLimit) {
            output = input;
            outputRanges = normalizedRanges == null
                ? const <ReplaceRuleTextRange>[]
                : normalizedRanges[inputIndex];
            diagnostics.add(
              ReplaceRuleDiagnostic(
                kind: ReplaceRuleDiagnosticKind.outputLimit,
                rulesSignature: signature,
                ruleId: rule.source.id,
                ruleName: rule.source.name,
                ruleFingerprint: rule.source.fingerprint,
                detail: 'Replacement output exceeded the safety limit.',
              ),
            );
            degraded = true;
            rolledBack = true;
            break;
          }
        }
        if (preserveNonEmpty &&
            input.trim().isNotEmpty &&
            output.trim().isEmpty) {
          output = input;
          outputRanges = normalizedRanges == null
              ? const <ReplaceRuleTextRange>[]
              : normalizedRanges[inputIndex];
          diagnostics.add(
            ReplaceRuleDiagnostic(
              kind: ReplaceRuleDiagnosticKind.emptyOutput,
              rulesSignature: signature,
              detail:
                  'Replacement rules removed all readable text; original retained.',
            ),
          );
          degraded = true;
          rolledBack = true;
        }
        if (!rolledBack) effectiveRuleIds.addAll(inputEffectiveRuleIds);
        values.add(output);
        mappedRanges?.add(outputRanges);
      }
      return ReplaceRuleExecutionResult(
        values: values,
        mappedRanges: mappedRanges ?? const <List<ReplaceRuleTextRange>>[],
        diagnostics: diagnostics,
        effectiveRuleIds: effectiveRuleIds.toList(growable: false),
        degraded: degraded,
      );
    }
    final executedValues = <String>[];
    final executedDiagnostics = <ReplaceRuleDiagnostic>[];
    final skippedRuleIds = <String>{};
    var executedDegraded = false;
    final effectiveRuleIds = <String>{};
    final executedRanges = normalizedRanges == null
        ? null
        : <List<ReplaceRuleTextRange>>[];
    for (final batch in _replaceRuleInputBatches(
      normalizedInputs,
      normalizedRanges,
    )) {
      final batchResult = await _executor.applyBatch(
        ReplaceRuleExecutionBatch(
          values: batch.values,
          ranges: batch.ranges,
          rules: allExecutionRules,
          rulesSignature: signature,
          bookTitle: bookTitle,
          sourceName: sourceName,
          sourceUrl: sourceUrl,
          target: title ? ReplaceRuleTarget.title : ReplaceRuleTarget.content,
        ),
      );
      executedValues.addAll(batchResult.values);
      executedRanges?.addAll(batchResult.mappedRanges);
      executedDiagnostics.addAll(batchResult.diagnostics);
      skippedRuleIds.addAll(batchResult.skippedRuleIds);
      effectiveRuleIds.addAll(batchResult.effectiveRuleIds);
      executedDegraded = executedDegraded || batchResult.degraded;
    }
    final result = ReplaceRuleExecutionResult(
      values: executedValues,
      mappedRanges: executedRanges ?? const <List<ReplaceRuleTextRange>>[],
      diagnostics: executedDiagnostics,
      skippedRuleIds: skippedRuleIds.toList(growable: false),
      effectiveRuleIds: effectiveRuleIds.toList(growable: false),
      degraded: executedDegraded,
    );
    await _disableTimedOutRules(result.diagnostics);
    if (!preserveNonEmpty) return result;
    final values = <String>[];
    final mappedRanges = normalizedRanges == null
        ? null
        : <List<ReplaceRuleTextRange>>[];
    final diagnostics = <ReplaceRuleDiagnostic>[...result.diagnostics];
    var degraded = result.degraded;
    for (var index = 0; index < normalizedInputs.length; index++) {
      final original = normalizedInputs[index];
      final cleaned = result.values[index];
      if (original.trim().isNotEmpty && cleaned.trim().isEmpty) {
        values.add(original);
        mappedRanges?.add(normalizedRanges![index]);
        diagnostics.add(
          ReplaceRuleDiagnostic(
            kind: ReplaceRuleDiagnosticKind.emptyOutput,
            rulesSignature: signature,
            detail:
                'Replacement rules removed all readable text; original retained.',
          ),
        );
        degraded = true;
      } else {
        values.add(cleaned);
        mappedRanges?.add(result.mappedRanges[index]);
      }
    }
    return ReplaceRuleExecutionResult(
      values: values,
      mappedRanges: mappedRanges ?? const <List<ReplaceRuleTextRange>>[],
      diagnostics: diagnostics,
      skippedRuleIds: result.skippedRuleIds,
      effectiveRuleIds: result.effectiveRuleIds,
      degraded: degraded,
    );
  }

  Iterable<({List<String> values, List<List<ReplaceRuleTextRange>>? ranges})>
  _replaceRuleInputBatches(
    List<String> inputs,
    List<List<ReplaceRuleTextRange>>? ranges,
  ) sync* {
    const maximumBatchCharacters = 512 * 1024;
    var batch = <String>[];
    var batchRanges = ranges == null ? null : <List<ReplaceRuleTextRange>>[];
    var characters = 0;
    for (var inputIndex = 0; inputIndex < inputs.length; inputIndex++) {
      final input = inputs[inputIndex];
      if (batch.isNotEmpty &&
          characters + input.length > maximumBatchCharacters) {
        yield (values: batch, ranges: batchRanges);
        batch = <String>[];
        batchRanges = ranges == null ? null : <List<ReplaceRuleTextRange>>[];
        characters = 0;
      }
      batch.add(input);
      batchRanges?.add(ranges![inputIndex]);
      characters += input.length;
    }
    if (batch.isNotEmpty) yield (values: batch, ranges: batchRanges);
  }

  Future<String> applyAsync(
    String input, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
    bool preserveNonEmpty = false,
  }) async {
    final result = await applyBatchAsync(
      <String>[input],
      bookTitle: bookTitle,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      bookId: bookId,
      eligibleByDefault: eligibleByDefault,
      title: title,
      preserveNonEmpty: preserveNonEmpty,
    );
    return result.values.single;
  }

  String apply(
    String input, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
  }) {
    if (!isEnabledForBook(bookId ?? '', eligibleByDefault: eligibleByDefault)) {
      return input;
    }
    return applyRules(
      enabledRules,
      input,
      bookTitle: bookTitle,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      bookId: bookId,
      eligibleByDefault: eligibleByDefault,
      title: title,
    );
  }

  String applyRules(
    Iterable<ReplaceRule> rules,
    String input, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
  }) {
    if (!isEnabledForBook(bookId ?? '', eligibleByDefault: eligibleByDefault)) {
      return input;
    }
    final applicable = rules
        .where((rule) => rule.enabled)
        .where((rule) => title ? rule.scopeTitle : rule.scopeContent)
        .where((rule) => _matchesScope(rule, bookTitle, sourceName, sourceUrl))
        .toList(growable: false);
    if (applicable.isEmpty) return input;
    var output = title ? input : _normalizeReplaceRuleContent(input);
    for (final rule in applicable) {
      if (isUnsupportedReplaceRuleReplacement(
        rule.replacement,
        isRegex: rule.isRegex,
      )) {
        continue;
      }
      try {
        final before = output;
        if (rule.isRegex) {
          output = output.replaceAllMapped(
            compileReplaceRulePattern(rule.pattern),
            (match) => expandReplaceRuleReplacement(rule.replacement, match),
          );
        } else {
          output = output.replaceAll(rule.pattern, rule.replacement);
        }
        if (title && before.trim().isNotEmpty && output.trim().isEmpty) {
          output = before;
        }
      } on FormatException {
        // Invalid rules are rejected on save/import; a corrupt legacy entry
        // must not prevent the reader from opening the book.
      }
    }
    return output;
  }

  bool _matchesScope(
    ReplaceRule rule,
    String title,
    String? source,
    String? sourceUrl,
  ) {
    return replaceRuleScopeMatches(
      scope: rule.scope,
      excludeScope: rule.excludeScope,
      title: title,
      sourceName: source,
      sourceUrl: sourceUrl,
    );
  }

  static String _normalizeReplaceRuleContent(String input) =>
      input.split(RegExp(r'\r?\n')).map((line) => line.trim()).join('\n');

  static List<List<ReplaceRuleTextRange>> _copyReplaceRuleRanges(
    List<List<ReplaceRuleTextRange>>? ranges,
  ) => ranges == null
      ? const <List<ReplaceRuleTextRange>>[]
      : <List<ReplaceRuleTextRange>>[
          for (final inputRanges in ranges)
            List<ReplaceRuleTextRange>.from(inputRanges),
        ];

  static List<ReplaceRule> decodeImport(String text) {
    final decoded = jsonDecode(text.replaceFirst('\ufeff', '').trim());
    final items = decoded is List
        ? decoded
        : decoded is Map && decoded['rules'] is List
        ? decoded['rules'] as List
        : decoded is Map
        ? [decoded]
        : const [];
    if (items.length > maxRules) {
      throw const ReplaceRuleValidationException(
        ReplaceRuleValidationKind.tooManyRules,
      );
    }
    return items
        .asMap()
        .entries
        .map((entry) {
          final value = entry.value;
          if (value is! Map) {
            throw const FormatException('Rule entry must be an object');
          }
          final rule = ReplaceRule.fromJson(
            Map<String, dynamic>.from(value),
            entry.key,
          );
          validate(rule);
          return rule;
        })
        .toList(growable: false);
  }

  ReplaceRuleExecutionRule _executionRule(ReplaceRule rule) =>
      ReplaceRuleExecutionRule(
        id: rule.id,
        name: rule.name,
        pattern: rule.pattern,
        replacement: rule.replacement,
        group: rule.group,
        scope: rule.scope,
        excludeScope: rule.excludeScope,
        enabled: rule.enabled,
        isRegex: rule.isRegex,
        scopeTitle: rule.scopeTitle,
        scopeContent: rule.scopeContent,
        order: rule.order,
        timeoutMillisecond: rule.validTimeoutMillisecond,
      );

  String fingerprintForRule(ReplaceRule rule) =>
      _executionRule(rule).fingerprint;

  Future<void> _disableTimedOutRules(
    Iterable<ReplaceRuleDiagnostic> diagnostics,
  ) async {
    if (_closed) return;
    final timedOutFingerprints = diagnostics
        .where((item) => item.kind == ReplaceRuleDiagnosticKind.timeout)
        .map((item) => item.ruleFingerprint)
        .whereType<String>()
        .toSet();
    if (timedOutFingerprints.isEmpty) return;
    var changed = false;
    final next = _rules
        .map((rule) {
          if (!rule.enabled ||
              !timedOutFingerprints.contains(fingerprintForRule(rule))) {
            return rule;
          }
          changed = true;
          return rule.copyWith(enabled: false);
        })
        .toList(growable: false);
    if (!changed) return;
    try {
      await saveAll(next);
    } catch (error) {
      debugPrint('timed-out replacement rule disable failed: $error');
    }
  }

  static ReplaceRule _sanitizePersistedRule(ReplaceRule rule) {
    try {
      validate(rule);
      return rule;
    } on ReplaceRuleValidationException {
      return rule.copyWith(enabled: false);
    }
  }

  bool isEnabledForBook(String bookId, {bool eligibleByDefault = true}) {
    final override = bookId.isEmpty ? null : _bookEnabled[bookId];
    return override ?? (_defaultEnabled && eligibleByDefault);
  }

  Future<void> setDefaultEnabled(bool enabled) async {
    await load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(defaultEnabledPreferenceKey, enabled);
    if (_closed || _defaultEnabled == enabled) return;
    _defaultEnabled = enabled;
    _revision++;
    _rulesSignatureCache = null;
    notifyListeners();
  }

  Future<void> setBookEnabled(String bookId, bool enabled) async {
    await load();
    if (bookId.isEmpty) return;
    final next = <String, bool>{..._bookEnabled, bookId: enabled};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(bookEnabledPreferenceKey, jsonEncode(next));
    if (_closed) return;
    _bookEnabled = next;
    _revision++;
    _rulesSignatureCache = null;
    notifyListeners();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('ReplaceRuleService is closed.');
    }
  }

  Future<void> close() {
    if (!_notifierDisposed) dispose();
    return _closing!;
  }

  Future<void> _closeResources(
    StreamSubscription<ReplaceRuleDiagnostic>? subscription,
  ) async {
    try {
      await subscription?.cancel();
    } finally {
      await _executor.dispose();
    }
  }

  @override
  void dispose() {
    if (_notifierDisposed) return;
    _notifierDisposed = true;
    _closed = true;
    final subscription = _diagnosticSubscription;
    _diagnosticSubscription = null;
    _closing = _closeResources(subscription);
    super.dispose();
  }
}
