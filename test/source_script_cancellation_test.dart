import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/scripting/source_script_engine.dart';

void main() {
  final source = ReadingSourceConfig.fromJson({
    'bookSourceName': 'Cancellation regression',
    'bookSourceUrl': 'https://cancel.test',
  });

  test('cancelled synchronous scripts never run or mutate source state', () {
    final evaluator = QuickJsSourceScriptEvaluator();
    addTearDown(evaluator.dispose);
    final cancelled = StateError('cancelled before evaluation');
    expect(
      () => evaluator.evaluate(
        "java.put('stale', 'written'); 1",
        SourceScriptContext(
          source: source,
          cancellationCheck: () => throw cancelled,
        ),
      ),
      throwsA(same(cancelled)),
    );
    expect(
      evaluator.evaluate(
        "java.get('stale')",
        SourceScriptContext(source: source),
      ),
      '',
    );
  });

  test(
    'cancellation after network prevents replay and releases the queue',
    () async {
      final evaluator = QuickJsSourceScriptEvaluator();
      addTearDown(evaluator.dispose);
      final cancelled = StateError('cancelled during network');
      var stopped = false;
      await expectLater(
        evaluator.evaluateAsync(
          "java.ajax('https://cancel.test/data'); java.put('stale', 'written'); 1",
          SourceScriptContext(
            source: source,
            cancellationCheck: () {
              if (stopped) throw cancelled;
            },
            networkHandler: (request) async {
              stopped = true;
              return SourceScriptNetworkResult(
                body: 'ready',
                finalUrl: request.url,
              );
            },
          ),
        ),
        throwsA(same(cancelled)),
      );
      expect(
        await evaluator.evaluateAsync(
          "java.get('stale')",
          SourceScriptContext(source: source),
        ),
        '',
      );
    },
  );
}
