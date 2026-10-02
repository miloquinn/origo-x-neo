import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_rule_engine.dart';
import 'package:xxread/book_sources/source_engine/source_script_engine.dart';

void main() {
  final source = ReadingSourceConfig.fromJson(const {
    'bookSourceName': 'Compatibility fixture',
    'bookSourceUrl': 'https://books.test',
  });

  SourceRuleDocument document(String body) => SourceRuleDocument.parse(
    body,
    source.baseUri,
    scriptContext: SourceScriptContext(source: source),
  );

  test('script-produced HTML fragments continue through explicit CSS', () {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document('<p>response</p>');

    final books = engine.evaluateList(
      page,
      null,
      '<js>table</js>\n@css:#content > table td > div',
    );

    expect(books, hasLength(2));
    expect(
      engine.evaluateString(page, books.first, '@xpath://b/a/@title'),
      'A',
    );
    expect(engine.evaluateString(page, books.last, '//p[1]/text()'), '作者:B');
  });

  test('QuickJS identity output continues through explicit CSS', () async {
    final evaluator = QuickJsSourceScriptEvaluator();
    addTearDown(evaluator.dispose);
    final engine = SourceRuleEngine(scriptEvaluatorProvider: () => evaluator);
    final page = document('''
      <div id="content"><table><tbody><tr><td>
        <div><b><a title="A"></a></b></div>
      </td></tr></tbody></table></div>
    ''');

    expect(
      await evaluator.evaluateAsync(
        'result',
        SourceScriptContext(source: source, result: page.scriptResultValue),
      ),
      contains('id="content"'),
    );
    final scripted = await engine.evaluateListAsync(
      page,
      null,
      '<js>result</js>',
    );
    expect(scripted.single, contains('id="content"'));
    final reparsed = document(scripted.single as String);
    expect(
      await engine.evaluateListAsync(
        reparsed,
        null,
        '@css:#content > table td > div',
      ),
      hasLength(1),
    );

    expect(
      await engine.evaluateListAsync(
        page,
        null,
        '<js>result</js>@css:#content > table td > div',
      ),
      hasLength(1),
    );
  });

  test('script list results remain individual list contexts', () async {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document('<p>response</p>');

    expect(engine.evaluateList(page, null, '<js>list</js>'), ['A', 'B']);
    expect(await engine.evaluateListAsync(page, null, '<js>list</js>'), [
      'A',
      'B',
    ]);
    expect(
      engine
          .evaluateList(page, null, '<js>htmlList</js>@css:article > span')
          .map((item) => engine.evaluateString(page, item, 'text')),
      ['A', 'B'],
    );
  });

  test('list transforms apply per item before a list-consuming script', () {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document('''
      <div><p><span>作品Tags：奇幻 冒险</span></p><p>更新:今天</p></div>
    ''');

    expect(
      engine.evaluateList(
        page,
        null,
        '//p[1]/span/text()&&//p[2]/text()##作品Tags：|更新:\n@js:flatten',
      ),
      ['奇幻', '冒险', '今天'],
    );
  });

  test(
    'script and JSON suffixes keep a script list as one structured value',
    () {
      final engine = SourceRuleEngine(
        scriptEvaluatorProvider: () => _FixtureEvaluator(),
      );
      final page = document('<p>response</p>');

      expect(
        engine.evaluateList(page, null, '<js>numbers</js>@js:result.length'),
        [2],
      );
      expect(
        engine.evaluateList(page, null, r'<js>objects</js>@json:$[*].name'),
        ['A', 'B'],
      );
    },
  );

  test('script table-row fragments preserve their HTML context', () {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document(
      '<!-- response marker --><section>response</section>',
    );

    final cells = engine.evaluateList(
      page,
      null,
      '<js>rowHtml</js>@css:tr > td',
    );
    expect(cells, hasLength(2));
    expect(engine.evaluateString(page, cells.last, 'text'), 'B');
  });

  test('script-produced JSON strings continue through XPath selectors', () {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document(
      '{"content":"<section><div class=book_piece>Book</div></section>"}',
    );

    expect(
      engine.evaluateString(
        page,
        null,
        '<js>jsonHtml</js>//div[@class="book_piece"]/text()',
      ),
      'Book',
    );
  });

  test('script-fetched fragments continue through legacy child selectors', () {
    final engine = SourceRuleEngine(
      scriptEvaluatorProvider: () => _FixtureEvaluator(),
    );
    final page = document('<p>response</p>');

    expect(
      engine.evaluateString(page, null, '<js>ajaxHtml</js>class.intro.0@html'),
      '<div class="intro"><p>first</p><p>second</p></div>',
    );
  });

  test('legacy empty selectors walk direct children at every chain step', () {
    const engine = SourceRuleEngine();
    final page = document('''
      <div id="content">
        <section><i>skip</i><div><span>first</span><span>second</span></div></section>
        <section><div><span>target</span></div></section>
      </div>
    ''');

    expect(
      engine.evaluateString(page, null, 'id.content@.1@.0@.0@text'),
      'target',
    );
    expect(
      engine.evaluateString(
        page,
        null,
        'id.content@children.1@children.0@text',
      ),
      'target',
    );
  });

  test('wenku-shaped XPath keeps parent-local positions and terminal text', () {
    const engine = SourceRuleEngine();
    final page = document('''
      <div id="content">
        <table><tbody><tr><td>first</td><td><span>1</span><span>2</span><span>3</span><span><a>latest</a></span></td></tr></tbody></table>
        <span>a</span><span>b</span><span>c</span><span>d</span><span>e</span><span>intro</span>
      </div>
    ''');

    expect(engine.evaluateString(page, null, '//span[6]'), 'intro');
    expect(
      engine.evaluateString(page, null, '//td[2]/span[4]/a/text()'),
      'latest',
    );
  });
}

class _FixtureEvaluator implements SourceScriptEvaluator {
  @override
  Object? evaluate(String script, SourceScriptContext context) =>
      switch (script.trim()) {
        'table' =>
          '''
      <div id="content"><table><tbody><tr><td>
        <div><b><a title="A"></a></b><p>作者:A</p></div>
        <div><b><a title="B"></a></b><p>作者:B</p></div>
      </td></tr></tbody></table></div>
    ''',
        'list' => const ['A', 'B'],
        'htmlList' => const [
          '<article><span>A</span></article>',
          '<article><span>B</span></article>',
        ],
        'rowHtml' => '<tr><td>A</td><td>B</td></tr>',
        'numbers' => const [1, 2],
        'result.length' when context.result is List =>
          (context.result as List).length,
        'objects' => const [
          {'name': 'A'},
          {'name': 'B'},
        ],
        'flatten' when context.result is List => [
          for (final value in context.result as List)
            ...'$value'.split(' ').where((part) => part.isNotEmpty),
        ],
        'jsonHtml' => '<section><div class="book_piece">Book</div></section>',
        'ajaxHtml' => '<div class="intro"><p>first</p><p>second</p></div>',
        _ => context.result,
      };

  @override
  Future<Object?> evaluateAsync(
    String script,
    SourceScriptContext context,
  ) async => evaluate(script, context);

  @override
  void dispose() {}
}
