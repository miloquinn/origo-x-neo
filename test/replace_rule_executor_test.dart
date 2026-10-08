import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/services/reader/replace_rule_executor.dart';

ReplaceRuleExecutionRule _rule({
  required String id,
  required String pattern,
  String replacement = '',
  bool isRegex = true,
  int order = 0,
  bool scopeTitle = false,
  bool scopeContent = true,
  int timeoutMillisecond = 3000,
}) => ReplaceRuleExecutionRule(
  id: id,
  name: id,
  pattern: pattern,
  replacement: replacement,
  group: '',
  scope: '',
  excludeScope: '',
  enabled: true,
  isRegex: isRegex,
  scopeTitle: scopeTitle,
  scopeContent: scopeContent,
  order: order,
  timeoutMillisecond: timeoutMillisecond,
);

ReplaceRuleExecutionBatch _batch({
  required String signature,
  required List<String> values,
  required List<ReplaceRuleExecutionRule> rules,
  ReplaceRuleTarget target = ReplaceRuleTarget.content,
}) => ReplaceRuleExecutionBatch(
  values: values,
  rules: rules,
  rulesSignature: signature,
  bookTitle: 'Book',
  target: target,
);

void main() {
  test('non-positive rule timeout is normalized to the default', () {
    expect(
      _rule(
        id: 'timeout',
        pattern: 'x',
        timeoutMillisecond: 0,
      ).toMessage()['timeoutMillisecond'],
      3000,
    );
  });

  test('worker applies a batch with sequential rule semantics', () async {
    final executor = ReplaceRuleExecutor();
    addTearDown(executor.dispose);

    final result = await executor.applyBatch(
      _batch(
        signature: 'normal',
        values: const ['ad one', 'ad two'],
        rules: [
          _rule(id: 'regex', pattern: r'ad (\w+)', replacement: r'$1'),
          _rule(
            id: 'literal',
            pattern: 'two',
            replacement: '2',
            isRegex: false,
            order: 1,
          ),
        ],
      ),
    );

    expect(result.values, ['one', '2']);
    expect(result.effectiveRuleIds, ['regex', 'literal']);
    expect(result.degraded, isFalse);
  });

  test(
    'signature cache keeps full rules across title and content jobs',
    () async {
      final executor = ReplaceRuleExecutor();
      addTearDown(executor.dispose);
      final rules = [
        _rule(
          id: 'title',
          pattern: 'T',
          replacement: 'title',
          isRegex: false,
          scopeTitle: true,
          scopeContent: false,
        ),
        _rule(
          id: 'content',
          pattern: 'C',
          replacement: 'content',
          isRegex: false,
        ),
      ];
      final title = await executor.applyBatch(
        _batch(
          signature: 'shared',
          values: const ['T'],
          rules: rules,
          target: ReplaceRuleTarget.title,
        ),
      );
      final content = await executor.applyBatch(
        _batch(signature: 'shared', values: const ['C'], rules: rules),
      );
      expect(title.values, ['title']);
      expect(content.values, ['content']);
    },
  );

  test('title rolls back an individual rule that erases all text', () async {
    final executor = ReplaceRuleExecutor();
    addTearDown(executor.dispose);
    final result = await executor.applyBatch(
      _batch(
        signature: 'title-empty',
        values: const ['Chapter'],
        target: ReplaceRuleTarget.title,
        rules: [
          _rule(
            id: 'erase',
            pattern: r'.*',
            scopeTitle: true,
            scopeContent: false,
          ),
          _rule(
            id: 'rename',
            pattern: 'Chapter',
            replacement: 'Named',
            isRegex: false,
            scopeTitle: true,
            scopeContent: false,
          ),
        ],
      ),
    );
    expect(result.values, ['Named']);
    expect(result.effectiveRuleIds, ['rename']);
  });

  test('resends a signature after the worker cache evicts it', () async {
    final executor = ReplaceRuleExecutor();
    addTearDown(executor.dispose);
    for (var index = 1; index <= 5; index++) {
      final result = await executor.applyBatch(
        _batch(
          signature: 'signature-$index',
          values: ['v$index'],
          rules: [
            _rule(
              id: 'rule-$index',
              pattern: 'v$index',
              replacement: 'done-$index',
              isRegex: false,
            ),
          ],
        ),
      );
      expect(result.values, ['done-$index']);
    }
    final restored = await executor.applyBatch(
      _batch(
        signature: 'signature-1',
        values: const ['v1'],
        rules: [
          _rule(
            id: 'rule-1',
            pattern: 'v1',
            replacement: 'done-1',
            isRegex: false,
          ),
        ],
      ),
    );
    expect(restored.values, ['done-1']);
  });

  test(
    'timeout kills worker, quarantines rule, and replays atomically',
    () async {
      final executor = ReplaceRuleExecutor(
        timeout: const Duration(milliseconds: 80),
        maximumTimeoutRetries: 1,
      );
      addTearDown(executor.dispose);
      final diagnostics = <ReplaceRuleDiagnostic>[];
      final subscription = executor.diagnostics.listen(diagnostics.add);
      addTearDown(subscription.cancel);

      // The near-match forces exponential backtracking on a valid expression.
      final pathologicalInput = '${'a' * 30000}b';
      final stopwatch = Stopwatch()..start();
      final result = await executor
          .applyBatch(
            _batch(
              signature: 'pathological',
              values: [pathologicalInput],
              rules: [
                _rule(id: 'danger', pattern: r'^(a+)+$'),
                _rule(
                  id: 'safe',
                  pattern: 'b',
                  replacement: 'B',
                  isRegex: false,
                  order: 1,
                ),
              ],
            ),
          )
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 3)));
      expect(result.values.single, '${'a' * 30000}B');
      expect(result.degraded, isTrue);
      expect(result.skippedRuleIds, contains('danger'));
      expect(
        diagnostics,
        contains(
          isA<ReplaceRuleDiagnostic>()
              .having(
                (diagnostic) => diagnostic.kind,
                'kind',
                ReplaceRuleDiagnosticKind.timeout,
              )
              .having((diagnostic) => diagnostic.ruleId, 'rule id', 'danger'),
        ),
      );

      // The executor must remain usable after the timed-out isolate is killed.
      final next = await executor.applyBatch(
        _batch(
          signature: 'after-restart',
          values: const ['foo'],
          rules: [
            _rule(
              id: 'literal',
              pattern: 'foo',
              replacement: 'bar',
              isRegex: false,
            ),
          ],
        ),
      );
      expect(next.values, ['bar']);
    },
  );

  test('serializes concurrent batches without mixing responses', () async {
    final executor = ReplaceRuleExecutor();
    addTearDown(executor.dispose);

    final results = await Future.wait([
      executor.applyBatch(
        _batch(
          signature: 'first',
          values: const ['one'],
          rules: [
            _rule(
              id: 'first',
              pattern: 'one',
              replacement: '1',
              isRegex: false,
            ),
          ],
        ),
      ),
      executor.applyBatch(
        _batch(
          signature: 'second',
          values: const ['two'],
          rules: [
            _rule(
              id: 'second',
              pattern: 'two',
              replacement: '2',
              isRegex: false,
            ),
          ],
        ),
      ),
    ]);

    expect(results[0].values, ['1']);
    expect(results[1].values, ['2']);
  });
}
