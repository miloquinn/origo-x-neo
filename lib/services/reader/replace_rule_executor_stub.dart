import 'dart:async';

import 'replace_rule_execution.dart';
import 'replace_rule_semantics.dart';

/// Safe fallback for runtimes without killable Dart isolates.
///
/// Untrusted regular expressions are deliberately skipped: executing them on
/// the browser/UI event loop would reintroduce the freeze this subsystem is
/// designed to prevent. Literal rules remain deterministic and inexpensive.
class ReplaceRuleExecutor {
  ReplaceRuleExecutor({Duration? timeout, int maximumTimeoutRetries = 0});

  final StreamController<ReplaceRuleDiagnostic> _diagnostics =
      StreamController<ReplaceRuleDiagnostic>.broadcast(sync: true);
  final Set<String> _reportedRegexSignatures = <String>{};

  Stream<ReplaceRuleDiagnostic> get diagnostics => _diagnostics.stream;

  Future<ReplaceRuleExecutionResult> applyBatch(
    ReplaceRuleExecutionBatch batch,
  ) async {
    bool applies(ReplaceRuleExecutionRule rule) =>
        rule.enabled &&
        (batch.target == ReplaceRuleTarget.title
            ? rule.scopeTitle
            : rule.scopeContent) &&
        replaceRuleMatchesScope(
          rule,
          batch.bookTitle,
          batch.sourceName,
          batch.sourceUrl,
        );
    final applicable = batch.rules
        .where(
          (rule) =>
              !rule.isRegex &&
              !isUnsupportedReplaceRuleReplacement(
                rule.replacement,
                isRegex: rule.isRegex,
              ) &&
              applies(rule),
        )
        .map(PreparedReplaceRule.new)
        .toList(growable: false);
    final skipped = batch.rules
        .where(
          (rule) =>
              (rule.isRegex ||
                  isUnsupportedReplaceRuleReplacement(
                    rule.replacement,
                    isRegex: rule.isRegex,
                  )) &&
              applies(rule),
        )
        .toList(growable: false);
    final outputLimit = replaceRuleOutputCharacterLimit(batch.values);
    final values = <String>[];
    final effectiveRuleIds = <String>{};
    for (final input in batch.values) {
      var output = input;
      final inputEffectiveRuleIds = <String>{};
      var rolledBack = false;
      for (final rule in applicable) {
        final before = output;
        final candidate = rule.apply(before);
        if (batch.target == ReplaceRuleTarget.title &&
            before.trim().isNotEmpty &&
            candidate.trim().isEmpty) {
          continue;
        }
        output = candidate;
        if (candidate != before) inputEffectiveRuleIds.add(rule.source.id);
        if (output.length > outputLimit) {
          output = input;
          rolledBack = true;
          break;
        }
      }
      if (!rolledBack) effectiveRuleIds.addAll(inputEffectiveRuleIds);
      values.add(output);
    }
    final diagnostics = <ReplaceRuleDiagnostic>[];
    if (skipped.isNotEmpty &&
        _reportedRegexSignatures.add(batch.rulesSignature)) {
      final diagnostic = ReplaceRuleDiagnostic(
        kind:
            isUnsupportedReplaceRuleReplacement(
              skipped.first.replacement,
              isRegex: skipped.first.isRegex,
            )
            ? ReplaceRuleDiagnosticKind.unsupportedReplacement
            : ReplaceRuleDiagnosticKind.regexUnavailable,
        rulesSignature: batch.rulesSignature,
        ruleId: skipped.first.id,
        ruleName: skipped.first.name,
        ruleFingerprint: skipped.first.fingerprint,
        detail: 'Killable replacement-regex workers are unavailable.',
      );
      diagnostics.add(diagnostic);
      _diagnostics.add(diagnostic);
    }
    return ReplaceRuleExecutionResult(
      values: values,
      diagnostics: diagnostics,
      skippedRuleIds: skipped.map((rule) => rule.id).toList(growable: false),
      effectiveRuleIds: effectiveRuleIds.toList(growable: false),
      degraded: skipped.isNotEmpty,
    );
  }

  Future<void> dispose() async {
    await _diagnostics.close();
  }
}
