import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_aloud_controller.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/cloud_tts_settings_page.dart';
import 'package:xxread/services/reader_aloud_service.dart';
import 'package:xxread/widgets/pill_input_surface.dart';
import 'package:xxread/widgets/pill_dropdown.dart';
import 'package:xxread/widgets/glass_dialog.dart';
import 'package:xxread/widgets/cloud_tts_provider_logo.dart';
import 'package:xxread/widgets/ai_provider_logo.dart';
import 'package:xxread/utils/app_themes.dart';
import 'package:xxread/utils/ui_style.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (Platform.environment['CLOUD_TTS_PREVIEW'] == '1') {
      final font = FontLoader('CloudTtsPreview');
      font.addFont(
        File(
          Platform.environment['CLOUD_TTS_PREVIEW_FONT']!,
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  testWidgets(
    'add, preview and select a named voice without overwriting the old voice',
    (tester) async {
      final secrets = _Secrets();
      final store = PreferencesReaderAloudCloudSettingsStore(
        secretStorage: secrets,
      );
      await store.writeApiKey('legacy-key');
      final client = _FakeCloudClient();
      final fixture = await _openSettings(
        tester,
        persistentStore: store,
        cloudClient: client,
      );
      addTearDown(fixture.dispose);
      expect(find.byKey(const ValueKey('cloud-tts-key')), findsNothing);
      expect(find.text('豆包'), findsOneWidget);
      expect(find.text('MiniMax'), findsOneWidget);
      await tester.tap(find.text('OpenAI'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cloud-tts-model')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('cloud-tts-voice-selector')));
      await tester.pumpAndSettle();
      expect(find.byType(GlassDialog), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(GlassDialog),
          matching: find.byType(TextField),
        ),
        'nova',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Advanced customization'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('Advanced customization')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Advanced customization'));
      await tester.pumpAndSettle();
      await _scrollTo(tester, const ValueKey('cloud-tts-name'));
      await tester.enterText(
        find.byKey(const ValueKey('cloud-tts-name')),
        'Bedtime voice',
      );
      await _scrollTo(tester, const ValueKey('cloud-tts-key'));
      await tester.enterText(
        find.byKey(const ValueKey('cloud-tts-key')),
        'new-key',
      );

      await _scrollTo(tester, const ValueKey('cloud-tts-preview'));
      await tester.tap(find.byKey(const ValueKey('cloud-tts-preview')));
      await tester.pumpAndSettle();
      expect(client.lastVoice, 'nova');
      expect(client.lastKey, 'new-key');
      expect(fixture.service.cloudProfiles, hasLength(1));
      expect(await store.readApiKey(), 'legacy-key');
      await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
      await tester.pumpAndSettle();
      expect(fixture.service.cloudProfiles, hasLength(2));
      expect(fixture.service.cloudSettings.voice, 'nova');
      expect(fixture.service.engineType, ReaderAloudEngineType.cloud);
      expect(await store.readApiKey(), 'new-key');
      expect(await store.readProfileKey('default'), 'legacy-key');
      expect(find.text('Open cloud settings'), findsOneWidget);
    },
  );

  for (final name in ['豆包', 'MiniMax', '小米 MiMo']) {
    testWidgets('$name preset can save with only a key', (tester) async {
      final store = PreferencesReaderAloudCloudSettingsStore(
        secretStorage: _Secrets(),
      );
      final fixture = await _openSettings(tester, persistentStore: store);
      addTearDown(fixture.dispose);
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cloud-tts-url')), findsNothing);
      expect(find.byKey(const ValueKey('cloud-tts-model')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('cloud-tts-key')),
        'provider-key',
      );
      await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
      await tester.pumpAndSettle();
      final preset = readerAloudProviderPresets.firstWhere(
        (p) => p.name == name,
      );
      expect(fixture.service.cloudSettings.provider, preset.provider);
      expect(fixture.service.cloudSettings.model, preset.settings.model);
      expect(fixture.service.cloudSettings.voice, preset.settings.voice);
      expect(
        fixture.service.cloudSettings.responseFormat,
        preset.settings.responseFormat,
      );
      expect(await store.readApiKey(), 'provider-key');
      expect(fixture.service.cloudProfiles, hasLength(2));
      expect(find.text('Open cloud settings'), findsOneWidget);
    });
  }

  testWidgets('blank API key keeps the saved key when settings are saved', (
    tester,
  ) async {
    final fixture = await _openSettings(
      tester,
      store: _MemorySettingsStore(apiKey: 'saved-key'),
    );
    addTearDown(fixture.dispose);

    await _scrollTo(tester, const ValueKey('cloud-tts-voice'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-voice')),
      'nova',
    );
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();

    expect(fixture.store.apiKey, 'saved-key');
    expect(fixture.store.writeApiKeyCalls, 0);
    expect(fixture.store.clearApiKeyCalls, 0);
    expect(fixture.store.settings.voice, 'nova');
    expect(find.text('Open cloud settings'), findsOneWidget);
  });

  testWidgets('removing a saved key is deferred until save', (tester) async {
    final fixture = await _openSettings(
      tester,
      store: _MemorySettingsStore(apiKey: 'saved-key'),
    );
    addTearDown(fixture.dispose);

    final remove = find.text('Remove saved key');
    await tester.ensureVisible(remove);
    await tester.pumpAndSettle();
    await tester.tap(remove);
    await tester.pump();

    expect(fixture.store.apiKey, 'saved-key');
    expect(fixture.store.clearApiKeyCalls, 0);

    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();

    expect(fixture.store.apiKey, isNull);
    expect(fixture.store.clearApiKeyCalls, 1);
  });

  testWidgets(
    'cancelling a pending key removal leaves the saved key unchanged',
    (tester) async {
      final fixture = await _openSettings(
        tester,
        store: _MemorySettingsStore(apiKey: 'saved-key'),
      );
      addTearDown(fixture.dispose);

      final remove = find.text('Remove saved key');
      await tester.ensureVisible(remove);
      await tester.pumpAndSettle();
      await tester.tap(remove);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
      await tester.pumpAndSettle();

      expect(fixture.store.apiKey, 'saved-key');
      expect(fixture.store.clearApiKeyCalls, 0);
      expect(fixture.store.saveSettingsCalls, 0);
    },
  );

  testWidgets('save failure keeps edits in the form and permits retry', (
    tester,
  ) async {
    final store = _MemorySettingsStore(
      apiKey: 'saved-key',
      settingsFailuresRemaining: 1,
    );
    final fixture = await _openSettings(tester, store: store);
    addTearDown(fixture.dispose);

    await _scrollTo(tester, const ValueKey('cloud-tts-model'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-model')),
      'voice-model-next',
    );
    await _scrollTo(tester, const ValueKey('cloud-tts-voice'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-voice')),
      'coral',
    );
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not finish saving'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('cloud-tts-model')))
          .controller!
          .text,
      'voice-model-next',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('cloud-tts-voice')))
          .controller!
          .text,
      'coral',
    );
    expect(
      find.byKey(const ValueKey('cloud-tts-save')).hitTestable(),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();

    expect(store.saveSettingsCalls, 2);
    expect(store.settings.model, 'voice-model-next');
    expect(store.settings.voice, 'coral');
    expect(find.text('Open cloud settings'), findsOneWidget);
  });

  testWidgets('invalid service URL shows validation and performs no writes', (
    tester,
  ) async {
    final fixture = await _openSettings(tester);
    addTearDown(fixture.dispose);

    await _scrollTo(tester, const ValueKey('cloud-tts-url'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-url')),
      'http://tts.example.com/v1',
    );
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pump();

    expect(find.textContaining('Use a valid HTTPS URL'), findsOneWidget);
    expect(fixture.store.saveSettingsCalls, 0);
    expect(fixture.store.writeApiKeyCalls, 0);
    expect(fixture.store.clearApiKeyCalls, 0);
  });

  testWidgets('collapsed advanced fields still validate and reveal errors', (
    tester,
  ) async {
    final fixture = await _openSettings(tester);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-url'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-url')),
      'http://tts.example.com/v1',
    );
    await tester.ensureVisible(find.text('Advanced customization'));
    await tester.tap(find.text('Advanced customization'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use a valid HTTPS URL'), findsOneWidget);
    expect(find.textContaining('Could not finish saving'), findsNothing);
    expect(fixture.store.saveSettingsCalls, 0);
    expect(fixture.store.writeApiKeyCalls, 0);
    expect(fixture.store.clearApiKeyCalls, 0);
  });

  testWidgets('save stays hit-testable above the keyboard on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final fixture = await _openSettings(tester, textScale: 1.4);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-url'));
    await tester.showKeyboard(find.byKey(const ValueKey('cloud-tts-url')));
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey('cloud-tts-save'));
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(568 - 240));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom service opens directly and saves its endpoint and IDs', (
    tester,
  ) async {
    final store = PreferencesReaderAloudCloudSettingsStore(
      secretStorage: _Secrets(),
    );
    final fixture = await _openSettings(tester, persistentStore: store);
    addTearDown(fixture.dispose);
    await tester.ensureVisible(find.byKey(const ValueKey('cloud-tts-add')));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cloud-tts-url')), findsOneWidget);
    for (final entry in {
      'cloud-tts-name': 'My speech service',
      'cloud-tts-url': 'https://tts.example.com/v1',
      'cloud-tts-model': 'custom-model',
      'cloud-tts-voice': 'custom-voice',
      'cloud-tts-key': 'custom-key',
    }.entries) {
      await _scrollTo(tester, ValueKey(entry.key));
      await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
    }
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();
    expect(fixture.service.cloudSettings.baseUrl, 'https://tts.example.com/v1');
    expect(fixture.service.cloudSettings.model, 'custom-model');
    expect(fixture.service.cloudSettings.voice, 'custom-voice');
    expect(fixture.service.cloudProfiles.last.name, 'My speech service');
    expect(await store.readApiKey(), 'custom-key');
  });

  testWidgets('custom IDs immediately update the model and voice selectors', (
    tester,
  ) async {
    final fixture = await _openSettings(tester);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-model'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-model')),
      'custom-next',
    );
    await tester.pump();
    var selector = tester.widget<PillDropdown<String>>(
      find.byKey(const ValueKey('cloud-tts-model-selector')),
    );
    expect(selector.value, 'custom-next');
    expect(
      selector.items.where((item) => item.value == 'custom-next'),
      hasLength(1),
    );
    await _scrollTo(tester, const ValueKey('cloud-tts-voice'));
    await tester.enterText(
      find.byKey(const ValueKey('cloud-tts-voice')),
      'my-next-voice',
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('cloud-tts-voice-selector')),
        matching: find.text('my-next-voice'),
      ),
      findsOneWidget,
    );
    await _scrollTo(tester, const ValueKey('cloud-tts-model-selector'));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-model-selector')));
    await tester.pumpAndSettle();
    expect(find.text('custom-next').hitTestable(), findsWidgets);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    selector = tester.widget<PillDropdown<String>>(
      find.byKey(const ValueKey('cloud-tts-model-selector')),
    );
    expect(selector.value, 'custom-next');
    expect(fixture.store.saveSettingsCalls, 0);
  });

  testWidgets('model and format use the shared menu and save selected values', (
    tester,
  ) async {
    final store = _MemorySettingsStore()
      ..settings = readerAloudProviderPresets
          .firstWhere(
            (preset) => preset.provider == ReaderAloudCloudProvider.minimax,
          )
          .settings;
    final fixture = await _openSettings(tester, store: store);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-model-selector'));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-model-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speech 2.8 Turbo').last);
    await tester.pumpAndSettle();
    await _scrollTo(tester, const ValueKey('cloud-tts-format-selector'));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-format-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WAV').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cloud-tts-save')));
    await tester.pumpAndSettle();
    expect(fixture.store.settings.model, 'speech-2.8-turbo');
    expect(fixture.store.settings.responseFormat, 'wav');
  });

  testWidgets('voice search remains usable with a keyboard on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final fixture = await _openSettings(tester);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-voice-selector'));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-voice-selector')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    final search = find.descendant(
      of: find.byType(GlassDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'nova');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nova'));
    await tester.pumpAndSettle();
    expect(find.text('Nova').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting one saved voice retains the other profile and key', (
    tester,
  ) async {
    final store = PreferencesReaderAloudCloudSettingsStore(
      secretStorage: _Secrets(),
    );
    await store.saveProfiles(const [
      ReaderAloudCloudProfile(
        id: 'first',
        name: 'First voice',
        settings: ReaderAloudCloudSettings(),
      ),
      ReaderAloudCloudProfile(
        id: 'second',
        name: 'Second voice',
        settings: ReaderAloudCloudSettings(voice: 'nova'),
      ),
    ], 'first');
    await store.writeProfileKey('first', 'first-key');
    await store.writeProfileKey('second', 'second-key');
    final fixture = await _openSettings(tester, persistentStore: store);
    addTearDown(fixture.dispose);
    await _scrollTo(tester, const ValueKey('cloud-tts-profile-second'));
    await tester.tap(find.byKey(const ValueKey('cloud-tts-profile-second')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Advanced customization'));
    await tester.tap(find.text('Advanced customization'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete voice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Delete voice'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fixture.service.cloudProfiles, hasLength(2));
    expect(await store.readProfileKey('second'), 'second-key');
    await tester.tap(find.text('Delete voice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(fixture.service.cloudProfiles.map((profile) => profile.id), [
      'first',
    ]);
    expect(await store.readProfileKey('first'), 'first-key');
    expect(await store.readProfileKey('second'), isNull);
  });

  for (final style in [AppUiStyle.glass, AppUiStyle.material3]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'provider artwork and shared inputs render in $style $brightness',
        (tester) async {
          final fixture = await _openSettings(
            tester,
            openCurrentSettings: false,
            uiStyle: style,
            brightness: brightness,
          );
          addTearDown(fixture.dispose);
          expect(find.byType(CloudTtsProviderLogo), findsNWidgets(4));
          expect(find.byType(AiProviderLogo), findsNWidgets(4));
          await tester.tap(
            find.byKey(const ValueKey('cloud-tts-preset-doubao')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(PillDropdown<String>), findsOneWidget);
          expect(find.byType(PillInputSurface), findsNWidgets(3));
          expect(find.byType(DropdownButton<String>), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  if (Platform.environment['CLOUD_TTS_PREVIEW'] == '1') {
    for (final style in [AppUiStyle.glass, AppUiStyle.material3]) {
      for (final brightness in Brightness.values) {
        testWidgets('capture $style $brightness cloud configuration', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(402, 874);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = PreferencesReaderAloudCloudSettingsStore(
            secretStorage: _Secrets(),
          );
          await store.saveProfiles([
            ReaderAloudCloudProfile(
              id: 'bedtime',
              name: '睡前女声',
              settings: readerAloudProviderPresets.first.settings,
            ),
          ], 'bedtime');
          final fixture = await _openSettings(
            tester,
            persistentStore: store,
            openCurrentSettings: false,
            locale: const Locale('zh'),
            uiStyle: style,
            brightness: brightness,
          );
          addTearDown(fixture.dispose);
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await tester.runAsync(
              () => precacheImage(
                image.image,
                tester.element(find.byType(CloudTtsSettingsPage)),
              ),
            );
          }
          await tester.pumpAndSettle();
          final name =
              '${style == AppUiStyle.glass ? 'glass' : 'solid'}-${brightness.name}';
          await _capture(tester, 'directory-$name');
          await tester.tap(
            find.byKey(const ValueKey('cloud-tts-preset-doubao')),
          );
          await tester.pumpAndSettle();
          await _capture(tester, 'editor-$name');
          await tester.tap(
            find.byKey(const ValueKey('cloud-tts-model-selector')),
          );
          await tester.pumpAndSettle();
          await _capture(tester, 'model-$name');
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('cloud-tts-voice-selector')),
          );
          await tester.pumpAndSettle();
          await _capture(tester, 'voice-$name');
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('cloud-tts-preview-root')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'build/cloud-tts-ui-20261010/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _scrollTo(WidgetTester tester, Key key) async {
  final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
  state.position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(key),
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(
    tester.element(find.byKey(key)),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
}

class _SettingsFixture {
  const _SettingsFixture({
    required this.store,
    required this.service,
    required this.system,
  });

  final _MemorySettingsStore store;
  final ReaderAloudService service;
  final _FakeAdjustableEngine system;

  void dispose() {
    service.dispose();
    system.dispose();
  }
}

Future<_SettingsFixture> _openSettings(
  WidgetTester tester, {
  _MemorySettingsStore? store,
  double textScale = 1,
  ReaderAloudCloudSettingsStore? persistentStore,
  _FakeCloudClient? cloudClient,
  bool openCurrentSettings = true,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
  AppUiStyle uiStyle = AppUiStyle.glass,
}) async {
  final actualStore = store ?? _MemorySettingsStore();
  final system = _FakeAdjustableEngine();
  final service = ReaderAloudService(
    systemEngine: system,
    settingsStore: persistentStore ?? actualStore,
    cloudClient: cloudClient ?? _FakeCloudClient(),
    bytesPlayer: _FakeBytesPlayer(),
    previewPlayerFactory: _FakeBytesPlayer.new,
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: ThemeData(
        colorScheme: brightness == Brightness.dark
            ? AppThemes.colorPresets.first.theme.darkColorScheme
            : AppThemes.colorPresets.first.theme.lightColorScheme,
        fontFamily: Platform.environment['CLOUD_TTS_PREVIEW'] == '1'
            ? 'CloudTtsPreview'
            : null,
        extensions: [
          UiStyleThemeExtension(style: uiStyle, glassStyle: GlassStyle.frosted),
        ],
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('cloud-tts-preview-root'),
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CloudTtsSettingsPage(service: service),
                ),
              ),
              child: const Text('Open cloud settings'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open cloud settings'));
  await tester.pumpAndSettle();
  if (persistentStore == null && openCurrentSettings) {
    await tester.scrollUntilVisible(
      find.text('Current settings'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Current settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Advanced customization'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Advanced customization')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Advanced customization'));
    await tester.pumpAndSettle();
  }
  return _SettingsFixture(store: actualStore, service: service, system: system);
}

class _MemorySettingsStore implements ReaderAloudCloudSettingsStore {
  _MemorySettingsStore({this.apiKey, this.settingsFailuresRemaining = 0});

  ReaderAloudEngineType engineType = ReaderAloudEngineType.system;
  ReaderAloudCloudSettings settings = const ReaderAloudCloudSettings();
  String? apiKey;
  int settingsFailuresRemaining;
  int saveSettingsCalls = 0;
  int writeApiKeyCalls = 0;
  int clearApiKeyCalls = 0;

  @override
  Future<void> clearApiKey() async {
    clearApiKeyCalls++;
    apiKey = null;
  }

  @override
  Future<ReaderAloudEngineType> loadEngineType() async => engineType;

  @override
  Future<ReaderAloudCloudSettings> loadSettings() async => settings;

  @override
  Future<String?> readApiKey() async => apiKey;

  @override
  Future<void> saveEngineType(ReaderAloudEngineType type) async {
    engineType = type;
  }

  @override
  Future<void> saveSettings(ReaderAloudCloudSettings settings) async {
    saveSettingsCalls++;
    if (settingsFailuresRemaining > 0) {
      settingsFailuresRemaining--;
      throw StateError('settings write failed');
    }
    this.settings = settings;
  }

  @override
  Future<void> writeApiKey(String apiKey) async {
    writeApiKeyCalls++;
    this.apiKey = apiKey;
  }
}

class _FakeAdjustableEngine extends ChangeNotifier
    implements ReaderAloudAdjustableEngine {
  @override
  int get currentPosition => 0;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  double get speechRate => 0.5;

  @override
  double get speechVolume => 1;

  @override
  Future<void> pause() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _FakeCloudClient implements ReaderAloudCloudClient {
  String? lastKey;
  String? lastVoice;
  @override
  Future<Uint8List> synthesize({
    required ReaderAloudCloudSettings settings,
    required String apiKey,
    required String text,
    required double speed,
  }) async {
    lastKey = apiKey;
    lastVoice = settings.voice;
    return Uint8List.fromList([1]);
  }
}

class _FakeBytesPlayer extends ChangeNotifier
    implements ReaderAloudBytesPlayer {
  @override
  Duration get duration => Duration.zero;

  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  @override
  Duration get position => Duration.zero;

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(
    Uint8List bytes, {
    required String mimeType,
    required double volume,
  }) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}

class _Secrets implements ReaderAloudSecretStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}
