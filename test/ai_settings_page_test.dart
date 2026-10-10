import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/ai_model_editor_page.dart';
import 'package:xxread/pages/settings/ai_settings_page.dart';
import 'package:xxread/reader_core/ai/ai_service.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';
import 'package:xxread/widgets/glass_dialog.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';
import 'package:xxread/utils/app_themes.dart';

class _FakeAiService extends ReaderHttpAIService {
  _FakeAiService({this.saveError, this.models, this.modelsError});

  final Object? saveError;
  final Object? modelsError;
  final Future<List<String>>? models;
  AIProviderSettings? modelRequest;

  @override
  Future<List<String>> fetchAvailableModels(AIProviderSettings settings) async {
    modelRequest = settings;
    if (modelsError != null) throw modelsError!;
    return models ?? Future.value(['glm-5.3', 'glm-5.3-flash']);
  }

  AIProviderSettings active = AIProviderSettings.defaults(
    AIProviderType.openai,
  );

  @override
  Future<AIProviderSettings> loadSettings([AIProviderType? provider]) async {
    if (provider == null || provider == active.provider) return active;
    return AIProviderSettings.defaults(provider);
  }

  @override
  Future<void> saveSettings(AIProviderSettings settings) async {
    if (saveError != null) throw saveError!;
    active = settings.normalized();
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FakeAiService service, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: ThemeData(
        colorScheme: brightness == Brightness.dark
            ? AppThemes.colorPresets.first.theme.darkColorScheme
            : AppThemes.colorPresets.first.theme.lightColorScheme,
        fontFamily: Platform.environment['AI_SETTINGS_PREVIEW'] == '1'
            ? 'AiSettingsPreview'
            : null,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RepaintBoundary(
        key: const ValueKey('ai-settings-preview'),
        child: AiSettingsPage(aiService: service),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openAddModel(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Add model'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add model'));
  await tester.pumpAndSettle();
}

Future<void> _pumpEditor(
  WidgetTester tester,
  _FakeAiService service, {
  EdgeInsets viewInsets = EdgeInsets.zero,
  double textScale = 1,
  AIProviderSettings? initialSettings,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: ThemeData(
        colorScheme: brightness == Brightness.dark
            ? AppThemes.colorPresets.first.theme.darkColorScheme
            : AppThemes.colorPresets.first.theme.lightColorScheme,
        fontFamily: Platform.environment['AI_SETTINGS_PREVIEW'] == '1'
            ? 'AiSettingsPreview'
            : null,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: const ValueKey('ai-editor-preview'),
        child: AiModelEditorPage(
          initialSettings:
              initialSettings ??
              AIProviderSettings.defaults(AIProviderType.openai),
          initialIsCustom: false,
          isEditing: false,
          aiService: service,
          knownApiKey: (_, _, _) => '',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _decodeLogos(WidgetTester tester) async {
  final context = tester.element(find.byType(AiProviderLogo).first);
  await tester.runAsync(() async {
    for (final asset
        in AIModelPresets.all.map((preset) => preset.logoAsset).toSet()) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.environment['AI_SETTINGS_PREVIEW'] == '1') {
      final font = FontLoader('AiSettingsPreview');
      font.addFont(
        File(
          Platform.environment['AI_SETTINGS_PREVIEW_FONT']!,
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('custom provider exposes protocol selector and v1 guidance', (
    tester,
  ) async {
    await _pumpPage(tester, _FakeAiService());
    await _openAddModel(tester);

    expect(find.byKey(const ValueKey('floating-subpage-back')), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);

    expect(find.text('API protocol'), findsOneWidget);
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.textContaining('usually needs to include /v1'), findsOneWidget);

    await tester.tap(find.text('Automatic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anthropic').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('may include /v1 or omit it'), findsOneWidget);
  });

  testWidgets('preset fields stay editable and save from the full page', (
    tester,
  ) async {
    final service = _FakeAiService();
    await _pumpPage(tester, service);
    await _openAddModel(tester);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(3));
    for (final field in tester.widgetList<TextFormField>(fields)) {
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byWidget(field),
                matching: find.byType(TextField),
              ),
            )
            .decoration
            ?.border,
        InputBorder.none,
      );
      expect(
        find.ancestor(
          of: find.byWidget(field),
          matching: find.byType(PillInputSurface),
        ),
        findsOneWidget,
      );
    }
    await tester.enterText(fields.at(0), 'https://gateway.example/v1');
    await tester.enterText(fields.at(1), 'test-key');
    await tester.enterText(fields.at(2), 'reading-model');
    await tester.tap(find.text('Add and enable'));
    await tester.pumpAndSettle();

    expect(service.active.baseUrl, 'https://gateway.example/v1');
    expect(service.active.model, 'reading-model');
    expect(service.active.apiKey, 'test-key');
    expect(find.text('AI Reading Assistant'), findsOneWidget);
  });

  testWidgets('save errors remain inline without dismissing the editor', (
    tester,
  ) async {
    final service = _FakeAiService(saveError: StateError('save unavailable'));
    await _pumpPage(tester, service);
    await _openAddModel(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://gateway.example/v1',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'test-key');
    await tester.enterText(find.byType(TextFormField).at(2), 'reading-model');
    await tester.tap(find.text('Add and enable'));
    await tester.pumpAndSettle();

    expect(find.textContaining('save unavailable'), findsOneWidget);
    expect(find.text('Add model'), findsOneWidget);
    expect(find.byKey(const ValueKey('floating-subpage-back')), findsOneWidget);
  });

  testWidgets('switching presets on the same endpoint retains the typed key', (
    tester,
  ) async {
    final service = _FakeAiService();
    await _pumpEditor(tester, service);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'typed-key');
    final presets = AIModelPresets.byProvider(AIProviderType.openai);
    expect(presets.length, greaterThan(1));
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is DropdownButton<AIModelPreset>,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.text('${presets[1].vendor} · ${presets[1].label}').last,
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      'typed-key',
    );
  });

  testWidgets('save error stays visible above a compact keyboard viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FakeAiService(saveError: StateError('save unavailable'));
    await _pumpEditor(
      tester,
      service,
      viewInsets: const EdgeInsets.only(bottom: 240),
      textScale: 1.4,
    );

    await tester.enterText(find.byType(TextFormField).at(1), 'test-key');
    expect(find.text('Add and enable').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Add and enable'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('save unavailable').hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Add and enable').hitTestable(), findsOneWidget);
  });
  testWidgets(
    'GLM URL automatically selects Anthropic and manual choice retains key',
    (tester) async {
      final service = _FakeAiService();
      await _pumpEditor(
        tester,
        service,
        initialSettings: const AIProviderSettings(
          provider: AIProviderType.glm,
          apiKey: 'typed-key',
          baseUrl: 'https://open.bigmodel.cn/api/anthropic',
          model: 'glm-5.3',
          temperature: 0.7,
        ),
      );
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.text('Detected from URL: Anthropic'), findsOneWidget);
      await tester.tap(find.text('Automatic'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OpenAI Compatible').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        'typed-key',
      );
      await tester.tap(find.text('Add and enable'));
      await tester.pumpAndSettle();
      expect(service.active.protocol, AIProtocolType.openai);
    },
  );

  testWidgets(
    'fetch uses detected protocol and searchable list populates model ID',
    (tester) async {
      final service = _FakeAiService();
      await _pumpEditor(
        tester,
        service,
        initialSettings: const AIProviderSettings(
          provider: AIProviderType.glm,
          apiKey: 'test-key',
          baseUrl: 'https://open.bigmodel.cn/api/anthropic',
          model: 'glm-5.3',
          temperature: 0.7,
        ),
      );
      await tester.ensureVisible(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      expect(service.modelRequest!.effectiveProtocol, AIProtocolType.anthropic);
      expect(service.modelRequest!.protocol, isNull);
      await tester.ensureVisible(find.text('Choose model (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Choose model (2)').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Choose model (2)'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      expect(find.byType(PillSearchField), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'flash');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'glm-5.3'), findsNothing);
      await tester.tap(find.widgetWithText(ListTile, 'glm-5.3-flash'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(2))
            .controller!
            .text,
        'glm-5.3-flash',
      );
    },
  );

  testWidgets('changing connection rejects stale model list results', (
    tester,
  ) async {
    final pending = Completer<List<String>>();
    final service = _FakeAiService(models: pending.future);
    await _pumpEditor(tester, service);
    await tester.enterText(find.byType(TextFormField).at(1), 'typed-key');
    await tester.ensureVisible(find.byKey(const ValueKey('fetch-ai-models')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fetch-ai-models')));
    await tester.pump();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://other.example/v1',
    );
    pending.complete(['stale-model']);
    await tester.pumpAndSettle();
    expect(find.textContaining('Choose model'), findsNothing);
  });

  testWidgets(
    'unsupported list gives manual-entry guidance without blocking save',
    (tester) async {
      final service = _FakeAiService(
        modelsError: const AIServiceException(
          code: 'model_list_unsupported_manual_entry',
        ),
      );
      await _pumpEditor(tester, service);
      await tester.enterText(find.byType(TextFormField).at(1), 'typed-key');
      await tester.ensureVisible(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Enter a model ID or choose a preset'),
        findsOneWidget,
      );
      await tester.tap(find.text('Add and enable'));
      await tester.pumpAndSettle();
      expect(service.active.apiKey, 'typed-key');
    },
  );

  testWidgets('automatic mode survives quick-model persistence and reopening', (
    tester,
  ) async {
    final service = _FakeAiService();
    await _pumpPage(tester, service);
    await _openAddModel(tester);
    await tester.enterText(find.byType(TextFormField).at(1), 'typed-key');
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'https://open.bigmodel.cn/api/anthropic',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'glm-5.3');
    await tester.tap(find.text('Add and enable'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('reader_ai_quick_models_v1'),
      contains('"protocol":null'),
    );
    await tester.pumpWidget(const SizedBox());
    await _pumpPage(tester, service);
    final savedModels =
        jsonDecode(prefs.getString('reader_ai_quick_models_v1')!) as List;
    final savedModel = savedModels.cast<Map>().firstWhere(
      (item) => item['model'] == 'glm-5.3',
    );
    final editButton = find.byKey(
      ValueKey('edit-ai-model-${savedModel['id']}'),
    );
    await tester.ensureVisible(editButton);
    await tester.pumpAndSettle();
    await tester.tap(editButton);
    await tester.pumpAndSettle();
    expect(find.text('Automatic'), findsOneWidget);
    expect(find.text('Detected from URL: Anthropic'), findsOneWidget);
  });

  for (final configured in [false, true]) {
    testWidgets('old starter refresh preserves configured=$configured', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'reader_ai_quick_models_v1': jsonEncode([
          {
            'id': 'preset-openai_gpt_4_1_mini',
            'provider': 'openai',
            'protocol': 'openai',
            'apiKey': configured ? 'saved-key' : '',
            'baseUrl': 'https://api.openai.com/v1',
            'model': 'gpt-4.1-mini',
            'temperature': 0.7,
            'isCustom': false,
          },
        ]),
      });
      await _pumpPage(tester, _FakeAiService());
      await _openAddModel(tester);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'https://gateway.example/v1',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'custom-key');
      await tester.enterText(find.byType(TextFormField).at(2), 'custom-model');
      await tester.tap(find.text('Add and enable'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final saved =
          jsonDecode(prefs.getString('reader_ai_quick_models_v1')!) as List;
      final oldStarter = saved.cast<Map>().singleWhere(
        (item) => item['id'] == 'preset-openai_gpt_4_1_mini',
      );
      expect(oldStarter['model'], configured ? 'gpt-4.1-mini' : 'gpt-6-luna');
      expect(oldStarter['apiKey'], configured ? 'saved-key' : '');
    });
  }

  testWidgets('provider directory opens the saved Coding Plan connection', (
    tester,
  ) async {
    final service = _FakeAiService()
      ..active = const AIProviderSettings(
        provider: AIProviderType.glm,
        protocol: AIProtocolType.anthropic,
        apiKey: 'saved-key',
        baseUrl: 'https://open.bigmodel.cn/api/anthropic',
        model: 'glm-5.3-flash',
        temperature: 1,
      );
    await _pumpPage(tester, service);
    await tester.ensureVisible(
      find.byKey(const ValueKey('provider-directory-zhipu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('provider-directory-zhipu')));
    await tester.pumpAndSettle();
    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields[0].controller!.text, service.active.baseUrl);
    expect(fields[1].controller!.text, 'saved-key');
    expect(fields[2].controller!.text, 'glm-5.3-flash');
    expect(find.text('Anthropic'), findsOneWidget);
  });

  testWidgets('unconfigured starters appear once in the provider directory', (
    tester,
  ) async {
    await _pumpPage(tester, _FakeAiService());
    expect(find.text('Added models'), findsNothing);
    expect(find.byType(AiProviderLogo), findsNWidgets(10));
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Claude'), findsOneWidget);
  });

  testWidgets(
    'compatible services retain their own brand while fields stay editable',
    (tester) async {
      await _pumpEditor(
        tester,
        _FakeAiService(),
        initialSettings: AIModelPresets.all
            .firstWhere((preset) => preset.brand == 'deepseek')
            .toSettings()
            .copyWith(model: 'deepseek-custom'),
      );
      expect(find.text('DeepSeek'), findsOneWidget);
      expect(find.byKey(const ValueKey('provider-deepseek')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('provider-deepseek')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Qwen').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('provider-qwen')), findsOneWidget);
      final fields = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .toList();
      expect(fields[0].controller!.text, contains('dashscope.aliyuncs.com'));
      expect(fields[1].controller!.text, isEmpty);
      expect(fields[2].controller!.text, startsWith('qwen'));
    },
  );

  testWidgets(
    'saving a hand-edited compatible model retains its brand in Added models',
    (tester) async {
      await _pumpPage(tester, _FakeAiService());
      await tester.ensureVisible(find.text('DeepSeek'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DeepSeek'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'saved-key');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'deepseek-custom',
      );
      await tester.tap(find.text('Add and enable'));
      await tester.pumpAndSettle();
      final row = find
          .ancestor(of: find.byTooltip('Edit'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: row, matching: find.text('DeepSeek')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('OpenAI')),
        findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.text('deepseek-custom')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'model search remains usable above a compact keyboard with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpEditor(
        tester,
        _FakeAiService(),
        viewInsets: const EdgeInsets.only(bottom: 240),
        textScale: 1.4,
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'typed-key');
      await tester.ensureVisible(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('fetch-ai-models')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose model (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Choose model (2)').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Choose model (2)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).last, 'flash');
      await tester.pumpAndSettle();
      final choice = find.widgetWithText(ListTile, 'glm-5.3-flash');
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(2))
            .controller!
            .text,
        'glm-5.3-flash',
      );
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'provider directory renders at phone width in ${brightness.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await _pumpPage(
          tester,
          _FakeAiService(),
          locale: const Locale('zh'),
          brightness: brightness,
        );
        expect(tester.takeException(), isNull);
        if (Platform.environment['AI_SETTINGS_PREVIEW'] == '1') {
          await _decodeLogos(tester);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('ai-settings-preview')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'build/ai-settings-ui-20261010/providers-${brightness.name}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
    testWidgets('GLM editor renders at phone width in ${brightness.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _pumpEditor(
        tester,
        _FakeAiService(),
        locale: const Locale('zh'),
        brightness: brightness,
        initialSettings: const AIProviderSettings(
          provider: AIProviderType.glm,
          apiKey: '',
          baseUrl: 'https://open.bigmodel.cn/api/anthropic',
          model: 'glm-5.3',
          temperature: 0.7,
        ),
      );
      expect(tester.takeException(), isNull);
      if (Platform.environment['AI_SETTINGS_PREVIEW'] == '1') {
        await _decodeLogos(tester);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('ai-editor-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/ai-settings-ui-20261010/editor-${brightness.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
