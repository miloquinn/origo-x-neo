import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/settings/about/open_source_licenses_page.dart';
import 'package:xxread/utils/app_skin_licenses.dart';
import 'package:xxread/widgets/glass_surface.dart';
import 'package:xxread/widgets/pill_search_field.dart';

import 'support/license_registry_fixture.dart';

void main() {
  registerLicenseFixture();
  testWidgets('shows project, font, and dependency license entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OpenSourceLicensesPage(appVersion: '1.1.1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('开源与字体许可'), findsOneWidget);
    expect(find.text('Origo X'), findsOneWidget);
    expect(find.text('GNU Affero General Public License v3.0'), findsOneWidget);
    expect(find.text('Noto Serif SC / Source Han Serif'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('flutter-package-licenses')),
      300,
    );

    expect(find.text('JetBrains Mono'), findsOneWidget);
    expect(find.text('HarmonyOS Sans'), findsOneWidget);
    expect(find.text('Flutter 与 Dart 依赖'), findsOneWidget);
  });

  testWidgets('opens bundled font license text offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OpenSourceLicensesPage(appVersion: '1.1.1'),
      ),
    );
    await tester.pumpAndSettle();

    final fontEntry = find.byKey(
      const ValueKey('font-license-Noto Serif SC / Source Han Serif'),
    );
    await tester.ensureVisible(fontEntry);
    await tester.tap(fontEntry);
    await tester.pumpAndSettle();

    expect(find.text('Noto Serif SC / Source Han Serif'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.data?.contains('SIL OPEN FONT LICENSE') == true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('opens the bundled project license text offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OpenSourceLicensesPage(appVersion: '1.1.1'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('origo-x-agpl-license')));
    await tester.pumpAndSettle();

    expect(find.text('Origo X · AGPL-3.0'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.data?.contains('GNU AFFERO GENERAL PUBLIC LICENSE') == true,
      ),
      findsOneWidget,
    );
  });
  testWidgets(
    'full MIT and brand rights are accessible offline in shared surfaces',
    (tester) async {
      await _pumpCredits(tester);
      for (final item in [
        ('bundled-code-license-Lobe Icons', 'Copyright (c) 2023 LobeHub'),
        ('provider-brand-notice', 'does not grant blanket permission'),
        ('skin-artwork-credits', 'Origo X'),
        ('iconpark-license', 'Apache License'),
      ]) {
        final row = find.byKey(ValueKey(item.$1));
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(row);
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(find.byType(GlassSurface), findsWidgets);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SelectableText &&
                widget.data?.contains(item.$2) == true,
          ),
          findsOneWidget,
        );
        expect(find.byType(LicensePage), findsNothing);
        await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'registry search preserves multi-package and multi-notice license formatting',
    (tester) async {
      await _pumpCredits(tester);
      final row = find.byKey(const ValueKey('flutter-package-licenses'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      // Asset-backed collectors need real asynchronous I/O in widget tests.
      await tester.runAsync(() async {
        await tester.tap(row);
        await tester.pump();
        await LicenseRegistry.licenses.toList();
      });
      await tester.pumpAndSettle();
      expect(find.byType(PillSearchField), findsOneWidget);
      expect(find.byType(LicensePage), findsNothing);
      for (final package in ['zz_fixture_a', 'zz_fixture_b']) {
        await tester.enterText(
          find.byKey(const ValueKey('license-search-field')),
          package.toUpperCase(),
        );
        await tester.pumpAndSettle();
        final item = find.byKey(ValueKey('license-registry-entry-$package'));
        await tester.ensureVisible(item);
        await tester.pumpAndSettle();
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(find.text('Shared notice heading'), findsOneWidget);
        expect(find.text('Indented license clause'), findsOneWidget);
        expect(find.text('Final shared warranty clause'), findsOneWidget);
        final heading = tester.widget<SelectableText>(
          find.byKey(const ValueKey('license-paragraph-0-0')),
        );
        expect(heading.textAlign, TextAlign.center);
        expect(
          find.text('Second independent notice retained'),
          package == 'zz_fixture_a' ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('floating-subpage-back')));
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byKey(const ValueKey('license-search-field')),
        'package-does-not-exist',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('license-registry-entry-zz_fixture_a')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpCredits(WidgetTester tester) async {
  await tester.runAsync(() async {
    registerAppSkinLicenses();
    await LicenseRegistry.licenses.toList();
  });
  await tester.pumpWidget(
    const MaterialApp(
      locale: Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OpenSourceLicensesPage(title: '素材与开源致谢', prioritizeAssets: true),
    ),
  );
  await tester.pumpAndSettle();
}
