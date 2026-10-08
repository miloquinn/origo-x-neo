import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/source_engine/source_script_bootstrap.dart';

void main() {
  setUp(SourceScriptBootstrap.debugClearSharedScriptPreparations);

  test('reuses shared script preparation by exact library content', () {
    const sharedScript = '''
function token() {
  try { return java.ajax('/token'); } catch (error) { return ''; }
}
''';

    final first = SourceScriptBootstrap.build(
      _payload(
        script: 'token() + variables.suffix',
        sharedScript: sharedScript,
        variables: const {'suffix': 'one'},
      ),
    );
    final second = SourceScriptBootstrap.build(
      _payload(
        script: 'token() + variables.suffix',
        sharedScript: sharedScript,
        variables: const {'suffix': 'two'},
      ),
    );

    expect(SourceScriptBootstrap.debugSharedScriptPreparationCount, 1);
    expect(first, contains('"suffix":"one"'));
    expect(second, contains('"suffix":"two"'));
    expect(first, isNot(second));
    expect(
      second,
      contains("catch (error) {if(error&&typeof error.message==='string'"),
    );
  });

  test('changed shared library content gets a fresh preparation', () {
    final first = SourceScriptBootstrap.build(
      _payload(sharedScript: 'function value(){ return 1; }'),
    );
    final changed = SourceScriptBootstrap.build(
      _payload(sharedScript: 'function value(){ return 2; }'),
    );

    expect(SourceScriptBootstrap.debugSharedScriptPreparationCount, 2);
    expect(first, contains('function value(){ return 1; }'));
    expect(changed, contains('function value(){ return 2; }'));
  });

  test('shared preparation cache stays bounded', () {
    for (var index = 0; index < 20; index++) {
      SourceScriptBootstrap.build(
        _payload(sharedScript: 'function value$index(){ return $index; }'),
      );
    }
    expect(SourceScriptBootstrap.debugSharedScriptPreparationCount, 20);

    SourceScriptBootstrap.build(
      _payload(sharedScript: 'function value0(){ return 0; }'),
    );
    expect(SourceScriptBootstrap.debugSharedScriptPreparationCount, 21);
  });
}

Map<String, Object?> _payload({
  String script = 'value()',
  String sharedScript = '',
  Map<String, Object?> variables = const {},
}) => <String, Object?>{
  'script': script,
  'sharedScript': sharedScript,
  'variables': variables,
};
