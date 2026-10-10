import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/services/reader/replace_rule_executor.dart';
import 'package:xxread/services/reader/replace_rule_semantics.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';

void main() {
  late ReplaceRuleService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = ReplaceRuleService();
  });

  tearDown(() async {
    service.dispose();
    await service.close();
  });

  test('applies enabled regex rules in order and supports deletion', () {
    final rules = [
      const ReplaceRule(
        id: 'ad',
        name: '广告',
        pattern: r'\[广告].*?\n',
        replacement: '',
      ),
      const ReplaceRule(
        id: 'name',
        name: '称呼',
        pattern: '小编',
        replacement: '作者',
        isRegex: false,
      ),
    ];
    expect(
      service.applyRules(rules, '[广告]下载APP\n正文 小编', bookTitle: '书'),
      '正文 作者',
    );
  });

  test('decodes current and legacy reading source fields', () {
    final current = ReplaceRuleService.decodeImport('''[
      {
        "pattern":"广告.*",
        "name":"清理广告",
        "isEnabled":0,
        "scopeContent":1,
        "sortOrder":"9"
      }
    ]''').single;
    expect(current.enabled, isFalse);
    expect(current.scopeContent, isTrue);
    expect(current.order, 9);
    expect(current.isRegex, isTrue);

    final legacy = ReplaceRuleService.decodeImport('''[
      {
        "regex":"广告.*",
        "replacement":"",
        "replaceSummary":"旧版规则",
        "enable":true,
        "serialNumber":3
      }
    ]''').single;
    expect(legacy.name, '旧版规则');
    expect(legacy.pattern, '广告.*');
    expect(legacy.enabled, isTrue);
    expect(legacy.order, 3);
    expect(legacy.isRegex, isFalse);
  });

  test('expands numbered capture groups in replacement text', () {
    const rule = ReplaceRule(
      id: 'capture',
      name: 'capture',
      pattern: r'(广告)[:：]?([^\n]+)',
      replacement: r'$1已移除',
    );
    expect(service.applyRules([rule], '广告：下载应用', bookTitle: '书'), '广告已移除');
  });

  test('uses standard regular expression dot behavior across lines', () {
    const rule = ReplaceRule(
      id: 'dot',
      name: 'dot',
      pattern: r'a.*b',
      replacement: 'removed',
    );
    expect(service.applyRules([rule], 'a\nb', bookTitle: '书'), 'a\nb');
    expect(
      service.applyRules(
        [rule.copyWith(pattern: r'(?s)a.*b')],
        'a\nb',
        bookTitle: '书',
      ),
      'removed',
    );
  });

  test('adapts compatible inline flags and horizontal whitespace', () {
    const rule = ReplaceRule(
      id: 'reading-compatible',
      name: 'reading-compatible',
      pattern: r'广告|(?i)APP\h+下载',
      replacement: '',
    );
    expect(service.applyRules([rule], '广告 APP  下载', bookTitle: '书'), ' ');

    const classRule = ReplaceRule(
      id: 'reading-compatible-class',
      name: 'reading-compatible-class',
      pattern: r'字[\h\-]数',
      replacement: '',
    );
    expect(service.applyRules([classRule], '字-数 字 数', bookTitle: '书'), ' ');

    expect(
      service.applyRules(
        [classRule.copyWith(pattern: r'字\H数')],
        '字A数 字 数',
        bookTitle: '书',
      ),
      ' 字 数',
    );
  });

  test('uses Java replacement escaping, longest valid groups, and names', () {
    const rule = ReplaceRule(
      id: 'java-replacement',
      name: 'java-replacement',
      pattern: r'(?<word>[a-z]+)-(\d)',
      replacement: r'${word}:$12:\$1',
    );
    expect(
      service.applyRules([rule], 'abc-7', bookTitle: 'Book'),
      r'abc:abc2:$1',
    );
  });

  test(
    'supports common JVM Unicode, quoted literal, and mixed class syntax',
    () {
      const rule = ReplaceRule(
        id: 'jvm-patterns',
        name: 'jvm-patterns',
        pattern: r'\p{Punct}+|\Qliteral.*\E|[x\H]',
        replacement: '',
      );
      expect(
        service.applyRules([rule], '! literal.* A x', bookTitle: 'Book'),
        '   ',
      );
      expect(
        () => ReplaceRuleService.validate(
          rule.copyWith(pattern: r'\p{NotAProperty}'),
        ),
        throwsA(isA<ReplaceRuleValidationException>()),
      );
      final mixed = compileReplaceRulePattern(r'[x\H]');
      final complement = compileReplaceRulePattern(r'[\H]');
      expect(mixed.hasMatch('A'), isTrue);
      expect(mixed.hasMatch('x'), isTrue);
      expect(mixed.hasMatch(' '), isFalse);
      expect(complement.hasMatch('A'), isTrue);
      expect(complement.hasMatch(' '), isFalse);
      final javaPunct = compileReplaceRulePattern(r'\p{Punct}');
      final unicodePunctuation = compileReplaceRulePattern(r'\p{P}');
      final notJavaPunct = compileReplaceRulePattern(r'\P{Punct}');
      expect(javaPunct.hasMatch('!'), isTrue);
      expect(javaPunct.hasMatch('！'), isFalse);
      expect(unicodePunctuation.hasMatch('！'), isTrue);
      expect(notJavaPunct.hasMatch('A'), isTrue);
      expect(notJavaPunct.hasMatch('!'), isFalse);
    },
  );

  test('content trims every line before applicable replacements', () {
    const rule = ReplaceRule(
      id: 'line-ad',
      name: 'line-ad',
      pattern: r'(?m)^广告.*$',
      replacement: '',
    );
    expect(
      service.applyRules(
        [rule],
        '  正文  \n   广告下载   \n 下一行 ',
        bookTitle: 'Book',
      ),
      '正文\n\n下一行',
    );
    expect(
      service.applyRules(
        [rule.copyWith(scope: 'Other Novel')],
        '  正文  \n   广告下载   ',
        bookTitle: 'Book',
      ),
      '  正文  \n   广告下载   ',
    );
  });

  test('separates title and content rules', () {
    const titleRule = ReplaceRule(
      id: 'title',
      name: 'title',
      pattern: '[广告]',
      replacement: '',
      isRegex: false,
      scopeTitle: true,
      scopeContent: false,
    );
    expect(
      service.applyRules([titleRule], '[广告] 第一章', bookTitle: '书', title: true),
      ' 第一章',
    );
    expect(
      service.applyRules([titleRule], '[广告] 正文', bookTitle: '书'),
      '[广告] 正文',
    );
  });

  test('matches semicolon and newline scopes without splitting letter n', () {
    const scoped = ReplaceRule(
      id: 'scope',
      name: 'scope',
      pattern: '广告',
      replacement: '',
      isRegex: false,
      scope: 'Origin Name\nAnother Source',
      excludeScope: 'Blocked Book',
    );
    expect(
      service.applyRules(
        [scoped],
        '正文广告',
        bookTitle: 'Novel',
        sourceName: 'Origin Name',
      ),
      '正文',
    );
    expect(
      service.applyRules(
        [scoped],
        '正文广告',
        bookTitle: 'Blocked Book',
        sourceName: 'Origin Name',
      ),
      '正文广告',
    );
  });

  test('scope and exclude also match the complete source URL', () {
    const scoped = ReplaceRule(
      id: 'url-scope',
      name: 'url-scope',
      pattern: '广告',
      replacement: '',
      isRegex: false,
      scope: '限定:https://example.com/books/42?full=true（附注）',
    );
    expect(
      service.applyRules(
        [scoped],
        '正文广告',
        bookTitle: 'Novel',
        sourceUrl: 'https://example.com/books/42?full=true',
      ),
      '正文',
    );
    expect(
      service.applyRules(
        [
          scoped.copyWith(
            scope: '限定:完整书名（附注）',
            excludeScope: '排除:https://example.com/books/42?full=true（附注）',
          ),
        ],
        '正文广告',
        bookTitle: '完整书名',
        sourceUrl: 'https://example.com/books/42?full=true',
      ),
      '正文广告',
    );
  });

  test('persists rule timeout and rejects a targetless new rule', () {
    final decoded = ReplaceRuleService.decodeImport(
      '''[{"pattern":"ad","timeoutMillisecond":4321}]''',
    ).single;
    expect(decoded.timeoutMillisecond, 4321);
    expect(decoded.toJson()['timeoutMillisecond'], 4321);
    expect(
      () => ReplaceRuleService.validate(
        const ReplaceRule(
          id: 'none',
          name: 'none',
          pattern: 'ad',
          replacement: '',
          scopeTitle: false,
          scopeContent: false,
        ),
      ),
      throwsA(
        isA<ReplaceRuleValidationException>().having(
          (error) => error.kind,
          'kind',
          ReplaceRuleValidationKind.missingTarget,
        ),
      ),
    );
  });

  test('rejects regex JavaScript replacement and preserves literal prefix', () {
    const imported = ReplaceRule(
      id: 'js',
      name: 'js',
      pattern: 'ad',
      replacement: "@js:result = 'oops'",
      enabled: false,
    );
    expect(
      () => ReplaceRuleService.decodeImport(
        '''[{"id":"js","pattern":"ad","replacement":"@js:result = 'oops'"}]''',
      ),
      throwsA(isA<ReplaceRuleValidationException>()),
    );
    expect(
      service.applyRules(
        [imported.copyWith(enabled: true)],
        'ad',
        bookTitle: 'Book',
      ),
      'ad',
    );
    expect(
      service.applyRules(
        [
          imported.copyWith(
            enabled: true,
            isRegex: false,
            replacement: '@js:literal',
          ),
        ],
        'ad',
        bookTitle: 'Book',
      ),
      '@js:literal',
    );
    expect(
      () => ReplaceRuleService.validate(imported.copyWith(enabled: true)),
      throwsA(
        isA<ReplaceRuleValidationException>().having(
          (error) => error.kind,
          'kind',
          ReplaceRuleValidationKind.unsupportedReplacement,
        ),
      ),
    );
  });

  test(
    'loads persisted targetless rules without discarding valid rules',
    () async {
      service.dispose();
      await service.close();
      SharedPreferences.setMockInitialValues({
        ReplaceRuleService.preferenceKey: '''[
        {"id":"bad","name":"bad","pattern":"x","scopeTitle":false,"scopeContent":false},
        {"id":"good","name":"good","pattern":"y","scopeContent":true}
      ]''',
      });
      service = ReplaceRuleService();
      await service.load();
      expect(service.rules, hasLength(2));
      expect(service.rules.first.enabled, isFalse);
      expect(service.rules.last.enabled, isTrue);
    },
  );

  test('loads valid rules around an invalid persisted rule', () async {
    service.dispose();
    await service.close();
    SharedPreferences.setMockInitialValues({
      ReplaceRuleService.preferenceKey: '''[
        {"id":"first","name":"first","pattern":"a","scopeContent":true},
        {"id":"bad","name":"bad","pattern":"","scopeContent":true},
        {"id":"last","name":"last","pattern":"z","scopeContent":true}
      ]''',
    });
    service = ReplaceRuleService();
    await service.load();
    expect(service.rules.map((rule) => rule.id), ['first', 'bad', 'last']);
    expect(service.rules[1].enabled, isFalse);
    await service.toggle('first', false);
    expect(service.rules, hasLength(3));
  });

  test(
    'global and per-book switches bypass cleaning and affect signature',
    () async {
      await service.load();
      await service.saveAll(const [
        ReplaceRule(
          id: 'one',
          name: 'one',
          pattern: 'ad',
          replacement: '',
          isRegex: false,
        ),
      ]);
      final enabledSignature = service.rulesSignature;
      await service.setDefaultEnabled(false);
      expect(service.defaultEnabled, isFalse);
      expect(service.rulesSignature, isNot(enabledSignature));
      expect(
        await service.applyAsync('ad', bookTitle: 'Book', bookId: 'book'),
        'ad',
      );
      await service.setBookEnabled('book', true);
      expect(service.isEnabledForBook('book'), isTrue);
      expect(
        await service.applyAsync('ad', bookTitle: 'Book', bookId: 'book'),
        '',
      );
      expect(service.apply('ad', bookTitle: 'Book', bookId: 'book'), '');
    },
  );

  test('loads rules when persisted book overrides are malformed', () async {
    service.dispose();
    await service.close();
    SharedPreferences.setMockInitialValues({
      ReplaceRuleService.preferenceKey:
          '''[{"id":"good","name":"good","pattern":"y","scopeContent":true}]''',
      ReplaceRuleService.bookEnabledPreferenceKey: '{broken',
    });
    service = ReplaceRuleService();
    await service.load();
    expect(service.rules.single.id, 'good');
  });

  test('merges imports and persists normalized order', () async {
    await service.load();
    await service.saveAll(const [
      ReplaceRule(
        id: 'original',
        name: '广告',
        pattern: 'ad',
        replacement: '',
        isRegex: false,
      ),
    ]);
    final merged = service.mergeImported(const [
      ReplaceRule(
        id: 'different-id',
        name: '广告',
        pattern: 'ad',
        replacement: 'clean',
        isRegex: false,
        order: 99,
      ),
      ReplaceRule(
        id: 'second',
        name: '推广',
        pattern: 'promo',
        replacement: '',
        isRegex: false,
      ),
    ]);
    await service.saveAll(merged);

    final reloadedService = ReplaceRuleService();
    await reloadedService.load();
    expect(reloadedService.rules, hasLength(2));
    expect(reloadedService.rules.first.id, 'different-id');
    expect(reloadedService.rules.first.replacement, 'clean');
    expect(reloadedService.rules.first.order, 0);
    expect(reloadedService.rules.last.order, 1);
    reloadedService.dispose();
    await reloadedService.close();
  });

  test('keeps state isolated between service instances', () async {
    final otherService = ReplaceRuleService();
    await service.load();
    await otherService.load();

    await service.saveAll(const [
      ReplaceRule(
        id: 'local',
        name: 'local',
        pattern: 'ad',
        replacement: '',
        isRegex: false,
      ),
    ]);

    expect(service.rules.map((rule) => rule.id), ['local']);
    expect(otherService.rules, isEmpty);
    otherService.dispose();
    await otherService.close();
  });

  test('closes an injected executor exactly once', () async {
    final executor = _TrackingReplaceRuleExecutor();
    final disposableService = ReplaceRuleService(executor: executor);

    await disposableService.close();
    await disposableService.close();

    expect(executor.disposeCalls, 1);
    expect(disposableService.load, throwsStateError);
  });

  testWidgets('provider disposal closes its owned service', (tester) async {
    final executor = _TrackingReplaceRuleExecutor();
    await tester.pumpWidget(
      ChangeNotifierProvider<ReplaceRuleService>(
        create: (_) => ReplaceRuleService(executor: executor),
        child: Builder(
          builder: (context) {
            context.read<ReplaceRuleService>();
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(executor.disposeCalls, 1);
  });

  test(
    'does not notify when an in-flight load finishes after dispose',
    () async {
      var notifications = 0;
      service.addListener(() => notifications++);

      final loading = service.load();
      service.dispose();
      await loading;

      expect(notifications, 0);
    },
  );

  test(
    'does not notify when an in-flight save finishes after dispose',
    () async {
      await service.load();
      var notifications = 0;
      service.addListener(() => notifications++);

      final saving = service.saveAll(const [
        ReplaceRule(
          id: 'pending',
          name: 'pending',
          pattern: 'ad',
          replacement: '',
          isRegex: false,
        ),
      ]);
      service.dispose();
      await saving;

      expect(notifications, 0);
    },
  );

  test('rejects invalid regular expressions', () {
    expect(
      () => ReplaceRuleService.validate(
        const ReplaceRule(
          id: 'bad',
          name: 'bad',
          pattern: '(',
          replacement: '',
        ),
      ),
      throwsA(isA<ReplaceRuleValidationException>()),
    );
  });

  test('async batch preserves order, scopes, and capture expansion', () async {
    await service.load();
    await service.saveAll(const [
      ReplaceRule(
        id: 'one',
        name: 'one',
        pattern: r'(广告)(\d+)',
        replacement: r'$2-$1',
        scope: 'Target Source',
        order: 0,
      ),
      ReplaceRule(
        id: 'two',
        name: 'two',
        pattern: '2-广告',
        replacement: 'clean',
        isRegex: false,
        order: 1,
      ),
    ]);

    final result = await service.applyBatchAsync(
      const ['广告1', '广告2'],
      bookTitle: 'Book',
      sourceName: 'Target Source',
    );

    expect(result.values, ['1-广告', 'clean']);
    expect(result.degraded, isFalse);
  });

  test(
    'persists timeout disable and does not disable an edited fingerprint',
    () async {
      service.dispose();
      await service.close();
      final executor = _ControlledTimeoutReplaceRuleExecutor();
      service = ReplaceRuleService(executor: executor);
      await service.load();
      const original = ReplaceRule(
        id: 'slow',
        name: 'slow',
        pattern: r'(a+)+$',
        replacement: '',
      );
      await service.saveAll(const [original]);
      final applying = service.applyAsync('aaaa!', bookTitle: 'Book');
      await executor.started.future;
      await service.upsert(original.copyWith(pattern: r'a+'));
      executor.release.complete();
      await applying;
      expect(service.rules.single.enabled, isTrue);

      final secondExecutor = _ControlledTimeoutReplaceRuleExecutor();
      final second = ReplaceRuleService(executor: secondExecutor);
      await second.load();
      await second.upsert(original);
      final secondApplying = second.applyAsync('aaaa!', bookTitle: 'Book');
      await secondExecutor.started.future;
      secondExecutor.release.complete();
      await secondApplying;
      expect(second.rules.single.enabled, isFalse);
      final reloaded = ReplaceRuleService();
      await reloaded.load();
      expect(reloaded.rules.single.enabled, isFalse);
      reloaded.dispose();
      await reloaded.close();
      second.dispose();
      await second.close();
    },
  );

  test(
    'content may be erased while title rejects each empty-producing rule',
    () async {
      await service.load();
      await service.saveAll(const [
        ReplaceRule(
          id: 'erase',
          name: 'erase',
          pattern: r'(?s).*',
          replacement: '',
          scopeTitle: true,
        ),
      ]);

      final result = await service.applyBatchAsync(const [
        'meaningful chapter',
      ], bookTitle: 'Book');
      expect(result.values.single, '');
      expect(result.effectiveRuleIds, ['erase']);

      final title = await service.applyBatchAsync(
        const ['meaningful chapter'],
        bookTitle: 'Book',
        title: true,
      );
      expect(title.values.single, 'meaningful chapter');
    },
  );

  test('maps ranges through line trim and sequential mixed rules', () async {
    await service.load();
    await service.saveAll(const [
      ReplaceRule(
        id: 'literal',
        name: 'literal',
        pattern: 'one',
        replacement: '1',
        isRegex: false,
        order: 0,
      ),
      ReplaceRule(
        id: 'regex',
        name: 'regex',
        pattern: r'1\ntwo',
        replacement: 'joined',
        order: 1,
      ),
    ]);

    final result = await service.applyBatchAsync(
      const ['  😀one  \r\n  two  '],
      bookTitle: 'Book',
      ranges: const [
        [
          ReplaceRuleTextRange(id: 'one', startOffset: 2, endOffset: 7),
          ReplaceRuleTextRange(id: 'two', startOffset: 13, endOffset: 16),
        ],
      ],
    );

    expect(result.values.single, '😀joined');
    expect(
      result.mappedRanges.single.map(
        (range) => (range.id, range.startOffset, range.endOffset),
      ),
      [('one', 0, 8), ('two', 2, 8)],
    );
  });

  test(
    'disabled purification preserves original text and ranges exactly',
    () async {
      await service.load();
      await service.saveAll(const [
        ReplaceRule(
          id: 'trim',
          name: 'trim',
          pattern: 'text',
          replacement: '',
          isRegex: false,
        ),
      ]);
      await service.setBookEnabled('disabled-book', false);
      const ranges = [
        [ReplaceRuleTextRange(id: 'action', startOffset: 2, endOffset: 6)],
      ];

      final result = await service.applyBatchAsync(
        const ['  text  '],
        bookTitle: 'Book',
        bookId: 'disabled-book',
        ranges: ranges,
      );

      expect(result.values, const ['  text  ']);
      expect(result.mappedRanges.single.single.startOffset, 2);
      expect(result.mappedRanges.single.single.endOffset, 6);
    },
  );
}

class _TrackingReplaceRuleExecutor extends ReplaceRuleExecutor {
  var disposeCalls = 0;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await super.dispose();
  }
}

class _ControlledTimeoutReplaceRuleExecutor extends ReplaceRuleExecutor {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<ReplaceRuleExecutionResult> applyBatch(
    ReplaceRuleExecutionBatch batch,
  ) async {
    final rule = batch.rules.firstWhere((item) => item.id == 'slow');
    if (!started.isCompleted) started.complete();
    await release.future;
    return ReplaceRuleExecutionResult(
      values: batch.values,
      diagnostics: [
        ReplaceRuleDiagnostic(
          kind: ReplaceRuleDiagnosticKind.timeout,
          rulesSignature: batch.rulesSignature,
          ruleId: rule.id,
          ruleName: rule.name,
          ruleFingerprint: rule.fingerprint,
        ),
      ],
      skippedRuleIds: [rule.id],
      degraded: true,
    );
  }
}
