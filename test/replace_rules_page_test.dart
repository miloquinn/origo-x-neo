import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/replace_rules_page.dart';
import 'package:xxread/services/reader/replace_rule_execution.dart';
import 'package:xxread/services/reader/replace_rule_service.dart';
import 'package:xxread/widgets/glass_bottom_sheet.dart';

late ReplaceRuleService _service;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _service = ReplaceRuleService();
  });
  tearDown(() => _service.close());

  testWidgets(
    'rule editor keeps its handle and actions inside the usable screen',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 900);
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 24);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReplaceRulesPage(service: _service),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final handle = find.byKey(GlassBottomSheetSurface.dragHandleKey);
      final save = find.byKey(const ValueKey('replace-rule-editor-save'));
      expect(tester.getRect(handle).top, greaterThanOrEqualTo(44));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(900));

      final editorFields = find.byKey(
        const ValueKey('replace-rule-editor-fields'),
      );
      await tester.tap(
        find
            .descendant(of: editorFields, matching: find.byType(TextField))
            .first,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pumpAndSettle();

      expect(tester.getRect(handle).top, greaterThanOrEqualTo(44));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(580));
    },
  );

  testWidgets('uses one shared glass tools menu and a compact search field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: _service),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('replaceRulesToolButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('replaceRulesSearchField')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.file_upload_outlined), findsNothing);
    expect(find.byIcon(Icons.file_download_outlined), findsNothing);

    await tester.tap(find.byKey(const ValueKey('replaceRulesToolButton')));
    await tester.pumpAndSettle();

    expect(find.text('导入规则'), findsOneWidget);
    expect(find.text('导出规则'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
  });

  testWidgets('deletes rules from the injected service instance', (
    tester,
  ) async {
    await _service.saveAll(const [
      ReplaceRule(
        id: 'injected-rule',
        name: 'Injected rule',
        pattern: 'ad',
        replacement: '',
        isRegex: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: _service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('injected-rule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replace-rule-editor-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(_service.rules, isEmpty);
    expect(find.byKey(const ValueKey('injected-rule')), findsNothing);
  });

  testWidgets('shared editor requires a target and preserves timeout', (
    tester,
  ) async {
    ReplaceRule? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showReplaceRuleEditor(
                  context,
                  service: _service,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-scope-content')),
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('replace-rule-scope-content')),
          )
          .value,
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-timeout')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('replace-rule-timeout')))
          .controller!
          .text,
      '3000',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-pattern')),
      -200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    await tester.enterText(
      find.byKey(const ValueKey('replace-rule-pattern')),
      'advertisement',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-scope-content')),
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('replace-rule-scope-content')));
    await tester.tap(find.byKey(const ValueKey('replace-rule-editor-save')));
    await tester.pumpAndSettle();
    expect(find.text('请至少选择章节标题或正文'), findsOneWidget);
    expect(result, isNull);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-scope-content')),
      -200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('replace-rule-scope-content')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('replace-rule-timeout')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('replace-rule-editor-fields')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('replace-rule-timeout')),
      '1250',
    );
    await tester.tap(find.byKey(const ValueKey('replace-rule-editor-save')));
    await tester.pumpAndSettle();
    expect(result?.scopeContent, isTrue);
    expect(result?.timeoutMillisecond, 1250);
    expect(_service.rules, isEmpty);
  });

  testWidgets('book context controls enablement and marks effective rules', (
    tester,
  ) async {
    await _service.saveAll(const [
      ReplaceRule(
        id: 'effective-rule',
        name: 'Effective',
        pattern: 'ad',
        replacement: '',
        isRegex: false,
      ),
      ReplaceRule(
        id: 'other-rule',
        name: 'Other',
        pattern: 'promo',
        replacement: '',
        isRegex: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(
          service: _service,
          bookId: 'book-1',
          bookTitle: '示例书',
          sourceName: '示例源',
          sourceUrl: 'https://example.com',
          eligibleByDefault: false,
          effectiveRuleIds: const ['effective-rule'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('replaceRulesBookEnabled')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('effective-rule')),
        matching: find.text('当前生效'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('other-rule')),
        matching: find.text('当前生效'),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('replaceRulesBookEnabled')));
    await tester.pumpAndSettle();
    expect(_service.isEnabledForBook('book-1'), isTrue);
    expect(find.text('当前生效'), findsOneWidget);

    await _service.toggle('effective-rule', false);
    await tester.pumpAndSettle();
    expect(find.text('当前生效'), findsNothing);

    await _service.toggle('effective-rule', true);
    await tester.pumpAndSettle();
    expect(find.text('当前生效'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('replaceRulesBookEnabled')));
    await tester.pumpAndSettle();
    expect(find.text('当前生效'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('replaceRulesBookEnabled')));
    await tester.pumpAndSettle();
    await _service.upsert(
      _service.rules.first.copyWith(pattern: 'different advertisement'),
    );
    await tester.pumpAndSettle();
    expect(find.text('当前生效'), findsNothing);
  });

  testWidgets('only regex JavaScript replacements show unsupported warning', (
    tester,
  ) async {
    await _service.saveAll(const [
      ReplaceRule(
        id: 'literal-js',
        name: 'Literal prefix',
        pattern: 'one',
        replacement: '@js:literal',
        isRegex: false,
      ),
      ReplaceRule(
        id: 'regex-js',
        name: 'Unsupported script',
        pattern: 'two',
        replacement: '@js:result',
        enabled: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: _service),
      ),
    );
    await tester.pumpAndSettle();

    final literalSubtitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('literal-js')),
        matching: find.textContaining('one →'),
      ),
    );
    final scriptSubtitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('regex-js')),
        matching: find.textContaining('two →'),
      ),
    );
    expect(literalSubtitle.data, 'one → @js:literal');
    expect(scriptSubtitle.data, contains('\n'));
  });

  testWidgets('editing a timed out rule removes its stale diagnostic', (
    tester,
  ) async {
    await _service.close();
    final service = _DiagnosticReplaceRuleService();
    _service = service;
    const rule = ReplaceRule(
      id: 'timeout-rule',
      name: 'Timed out',
      pattern: 'one',
      replacement: '',
      enabled: false,
    );
    await service.saveAll(const [rule]);
    service.diagnosticValues = [
      ReplaceRuleDiagnostic(
        kind: ReplaceRuleDiagnosticKind.timeout,
        rulesSignature: service.rulesSignature,
        ruleId: rule.id,
        ruleFingerprint: service.fingerprintForRule(rule),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: service),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('此规则执行超时'), findsOneWidget);

    await service.upsert(rule.copyWith(pattern: 'two'));
    await tester.pumpAndSettle();
    expect(find.textContaining('此规则执行超时'), findsNothing);
  });

  testWidgets('effective rule labels fit a narrow English screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await _service.saveAll(const [
      ReplaceRule(
        id: 'effective-rule',
        name: 'An advertisement replacement rule',
        pattern: 'advertisement',
        replacement: '',
        isRegex: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(
          service: _service,
          bookId: 'book-1',
          bookTitle: 'Example book',
          effectiveRuleIds: const ['effective-rule'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('effective-rule')),
        matching: find.byType(Chip),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection mode batches enable and disable through saveAll', (
    tester,
  ) async {
    await _service.saveAll(const [
      ReplaceRule(
        id: 'first-rule',
        name: 'First',
        pattern: 'one',
        replacement: '',
        isRegex: false,
      ),
      ReplaceRule(
        id: 'second-rule',
        name: 'Second',
        pattern: 'two',
        replacement: '',
        isRegex: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: _service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('replaceRulesToolButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('replaceRulesSelectionMode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('first-rule')));
    await tester.tap(find.byKey(const ValueKey('second-rule')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('replaceRulesDisableSelected')));
    await tester.pumpAndSettle();

    expect(_service.rules.every((rule) => !rule.enabled), isTrue);
  });

  testWidgets('group filter splits compatible multi-group separators', (
    tester,
  ) async {
    await _service.saveAll(const [
      ReplaceRule(
        id: 'multi-group-rule',
        name: 'Multi group',
        pattern: 'one',
        replacement: '',
        group: '广告; 通用，推荐',
        isRegex: false,
      ),
      ReplaceRule(
        id: 'other-group-rule',
        name: 'Other group',
        pattern: 'two',
        replacement: '',
        group: '脚注',
        isRegex: false,
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReplaceRulesPage(service: _service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '通用'));
    await tester.pump();

    expect(find.byKey(const ValueKey('multi-group-rule')), findsOneWidget);
    expect(find.byKey(const ValueKey('other-group-rule')), findsNothing);
  });
}

class _DiagnosticReplaceRuleService extends ReplaceRuleService {
  List<ReplaceRuleDiagnostic> diagnosticValues = const [];

  @override
  List<ReplaceRuleDiagnostic> get recentDiagnostics => diagnosticValues;
}
