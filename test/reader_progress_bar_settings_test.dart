import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/core/reader/reader_settings.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/widgets/reader_progress_bar_setting_tile.dart';

void main() {
  test('progress bar defaults to enabled full-book progress', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await const ReaderSettingsStore().load();

    expect(settings.progressBarEnabled, isTrue);
    expect(settings.progressBarScope, ReaderProgressScope.book);
  });

  test('progress bar preferences copy and persist independently', () async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.chapterProgressStyleKey: 'remaining',
      'unrelated_reader_value': 17,
    });
    const store = ReaderSettingsStore();
    final defaults = await store.load();
    final updated = defaults.copyWith(
      progressBarEnabled: false,
      progressBarScope: ReaderProgressScope.chapter,
    );

    await store.saveProgressBarPreferences(
      enabled: updated.progressBarEnabled,
      scope: updated.progressBarScope,
    );

    final restored = await store.load();
    final prefs = await SharedPreferences.getInstance();
    expect(restored.progressBarEnabled, isFalse);
    expect(restored.progressBarScope, ReaderProgressScope.chapter);
    expect(restored.chapterProgressStyle, ReaderChapterProgressStyle.remaining);
    expect(prefs.getInt('unrelated_reader_value'), 17);
  });

  test('full reader settings save includes progress bar preferences', () async {
    SharedPreferences.setMockInitialValues({});
    const store = ReaderSettingsStore();
    final settings = (await store.load()).copyWith(
      progressBarEnabled: false,
      progressBarScope: ReaderProgressScope.chapter,
    );

    await store.save(settings);

    final restored = await store.load();
    expect(restored.progressBarEnabled, isFalse);
    expect(restored.progressBarScope, ReaderProgressScope.chapter);
  });

  test('invalid stored scope falls back to full-book progress', () async {
    SharedPreferences.setMockInitialValues({
      ReaderSettingsStore.progressBarScopeKey: 'invalid',
    });

    final settings = await const ReaderSettingsStore().load();

    expect(settings.progressBarScope, ReaderProgressScope.book);
  });

  testWidgets('scope choice is hidden while the progress bar is off', (
    tester,
  ) async {
    var enabled = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ReaderProgressBarSettingTile(
              enabled: enabled,
              scope: ReaderProgressScope.book,
              onEnabledChanged: (value) => setState(() => enabled = value),
              onScopeChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('reader-progress-bar-scope')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('reader-progress-bar-switch')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('reader-progress-bar-scope')),
      findsOneWidget,
    );
  });

  testWidgets('scope choice reports chapter progress selection', (
    tester,
  ) async {
    var scope = ReaderProgressScope.book;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ReaderProgressBarSettingTile(
              enabled: true,
              scope: scope,
              onEnabledChanged: (_) {},
              onScopeChanged: (value) => setState(() => scope = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Current chapter'));
    await tester.pump();
    expect(scope, ReaderProgressScope.chapter);
  });

  testWidgets('narrow large-text layout does not overflow', (tester) async {
    var scope = ReaderProgressScope.book;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(276, 600),
              textScaler: TextScaler.linear(3.2),
            ),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 276,
                  child: StatefulBuilder(
                    builder: (context, setState) =>
                        ReaderProgressBarSettingTile(
                          enabled: true,
                          scope: scope,
                          onEnabledChanged: (_) {},
                          onScopeChanged: (value) =>
                              setState(() => scope = value),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(
      find.byKey(const ValueKey('reader-progress-bar-scope')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Current chapter'));
    await tester.pump();
    await tester.tap(find.text('Current chapter'));
    await tester.pump();
    expect(scope, ReaderProgressScope.chapter);
    expect(tester.takeException(), isNull);
  });
}
