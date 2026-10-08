import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_rule_engine.dart';
import 'package:xxread/book_sources/source_engine/source_script_engine.dart';

void main() {
  test(
    'metadata templates pass text to trailing JS and retain selector context',
    () async {
      final evaluator = QuickJsSourceScriptEvaluator();
      addTearDown(evaluator.dispose);
      final engine = SourceRuleEngine(scriptEvaluatorProvider: () => evaluator);
      final source = ReadingSourceConfig.fromJson(const {
        'bookSourceName': 'Metadata template contract',
        'bookSourceUrl': 'https://books.test',
      });
      final item = {'category': '悬疑', 'score': '9.5', 'creation_status': 1};
      final document = SourceRuleDocument.fromValue(
        item,
        source.baseUri,
        scriptContext: SourceScriptContext(source: source),
      );
      const rule = '''{{\$.category}}
{{\$.score}}分
连载{{\$.creation_status}}完结
@js:result.replace(/连载1完结/g,'连载') + ':' + java.getString('category')''';
      expect(engine.evaluateString(document, item, rule), '悬疑\n9.5分\n连载:悬疑');
      expect(
        await engine.evaluateStringAsync(document, item, rule),
        '悬疑\n9.5分\n连载:悬疑',
      );
      expect(engine.evaluateList(document, item, rule), ['悬疑\n9.5分\n连载:悬疑']);
      expect(await engine.evaluateListAsync(document, item, rule), [
        '悬疑\n9.5分\n连载:悬疑',
      ]);
    },
  );
}
