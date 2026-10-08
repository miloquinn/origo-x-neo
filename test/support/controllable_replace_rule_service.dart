import 'dart:async';

import 'package:xxread/services/reader/replace_rule_execution.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';

class PendingReplacementBatch {
  PendingReplacementBatch(this.values);

  final List<String> values;
  final _completion = Completer<void>();

  void complete() => _completion.complete();
}

class ControllableReplaceRuleService extends ReplaceRuleService {
  bool delayBodies = false;
  bool delayNextTitle = false;
  final pendingTitles = <PendingReplacementBatch>[];
  final pendingBodies = <PendingReplacementBatch>[];

  @override
  Future<ReplaceRuleExecutionResult> applyBatchAsync(
    List<String> inputs, {
    required String bookTitle,
    String? sourceName,
    String? sourceUrl,
    String? bookId,
    bool eligibleByDefault = true,
    bool title = false,
    bool preserveNonEmpty = false,
  }) async {
    final result = await super.applyBatchAsync(
      inputs,
      bookTitle: bookTitle,
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      bookId: bookId,
      eligibleByDefault: eligibleByDefault,
      title: title,
      preserveNonEmpty: preserveNonEmpty,
    );
    if (title && delayNextTitle) {
      delayNextTitle = false;
      final pending = PendingReplacementBatch(result.values);
      pendingTitles.add(pending);
      await pending._completion.future;
    }
    if (!title && delayBodies) {
      final pending = PendingReplacementBatch(result.values);
      pendingBodies.add(pending);
      await pending._completion.future;
    }
    return result;
  }
}
