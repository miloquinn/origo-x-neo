import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/main.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/pages/legal/user_agreement_page.dart';
import 'package:xxread/services/account/member_account_controller.dart';
import 'package:xxread/services/core/core_services.dart';
import 'package:xxread/services/diagnostics/diagnostics_controller.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';
import 'package:xxread/services/reading/reading_cloud_controller.dart';

import 'support/legal_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'cold start keeps account and reading cloud gated through a material update',
    (tester) async {
      final fixture = await _mountAcceptedApp(tester);

      expect(fixture.repository.refreshCalls, 1);
      expect(fixture.account.synchronizeCalls, 0);
      expect(fixture.cloud.initializeCalls, 0);
      expect(fixture.cloud.networkAllowed, isFalse);
      expect(fixture.account.networkAllowed, isFalse);
      expect(fixture.diagnostics.networkAllowed, isFalse);

      fixture.repository.complete(
        LegalCatalogSnapshot(
          catalog: legalFixtureCatalog(revision: '2026-10-08.2'),
          source: LegalContentSource.network,
        ),
      );
      await _pumpFrames(tester);

      expect(fixture.account.synchronizeCalls, 0);
      expect(fixture.cloud.initializeCalls, 0);
      expect(fixture.cloud.networkAllowed, isFalse);
      expect(fixture.account.networkAllowed, isFalse);
      expect(fixture.diagnostics.networkAllowed, isFalse);
      expect(find.byKey(const Key('welcomeAgreements')), findsOneWidget);
      await fixture.dispose(tester);
    },
  );

  testWidgets('accepted current publication starts authorized services', (
    tester,
  ) async {
    final fixture = await _mountAcceptedApp(tester);
    fixture.repository.complete(
      LegalCatalogSnapshot(
        catalog: legalFixtureCatalog(),
        source: LegalContentSource.network,
      ),
    );

    await _pumpUntil(tester, () => fixture.cloud.initializeCalls == 1);
    expect(fixture.account.synchronizeCalls, 1);
    expect(fixture.cloud.initializeCalls, 1);
    expect(fixture.cloud.networkAllowed, isTrue);
    expect(fixture.account.networkAllowed, isTrue);
    expect(fixture.diagnostics.networkAllowed, isTrue);
    await fixture.dispose(tester);
  });

  testWidgets('editorial revision with the accepted consent version starts', (
    tester,
  ) async {
    final fixture = await _mountAcceptedApp(tester);
    fixture.repository.complete(
      LegalCatalogSnapshot(
        catalog: legalFixtureCatalog(
          revision: '2026-10-08.2',
          consentVersion: '2026-10-08.1',
        ),
        source: LegalContentSource.network,
      ),
    );

    await _pumpUntil(tester, () => fixture.cloud.initializeCalls == 1);
    expect(fixture.account.synchronizeCalls, 1);
    expect(fixture.cloud.initializeCalls, 1);
    expect(fixture.cloud.networkAllowed, isTrue);
    expect(fixture.account.networkAllowed, isTrue);
    expect(fixture.diagnostics.networkAllowed, isTrue);
    await fixture.dispose(tester);
  });

  testWidgets('offline refresh fallback starts from the accepted local copy', (
    tester,
  ) async {
    final fixture = await _mountAcceptedApp(tester);
    fixture.repository.complete(
      LegalCatalogSnapshot(
        catalog: legalFixtureCatalog(),
        source: LegalContentSource.bundled,
        refreshError: true,
      ),
    );

    await _pumpUntil(tester, () => fixture.cloud.initializeCalls == 1);
    expect(fixture.account.synchronizeCalls, 1);
    expect(fixture.cloud.initializeCalls, 1);
    expect(fixture.cloud.networkAllowed, isTrue);
    expect(fixture.account.networkAllowed, isTrue);
    expect(fixture.diagnostics.networkAllowed, isTrue);
    await fixture.dispose(tester);
  });
}

Future<_Fixture> _mountAcceptedApp(WidgetTester tester) async {
  final accepted = legalFixtureCatalog();
  await UserAgreementService.acceptAgreement(locale: 'en', catalog: accepted);
  final repository = _ControlledLegalRepository(accepted);
  final account = _CountingAccount();
  final cloud = _CountingCloud(account);
  final diagnostics = _CountingDiagnostics(account);
  final theme = ThemeNotifier();
  final settings = AppSettingsNotifier(account: account);

  await tester.pumpWidget(
    provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider<ThemeNotifier>.value(value: theme),
        provider.ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
        ),
        provider.ChangeNotifierProvider<ReadingCloudController>.value(
          value: cloud,
        ),
        provider.ChangeNotifierProvider<DiagnosticsController>.value(
          value: diagnostics,
        ),
        provider.ChangeNotifierProvider<AppSettingsNotifier>.value(
          value: settings,
        ),
      ],
      child: XxReadApp(legalRepository: repository),
    ),
  );
  await _pumpUntil(tester, () => repository.refreshCalls == 1);
  return _Fixture(
    repository: repository,
    account: account,
    cloud: cloud,
    diagnostics: diagnostics,
    theme: theme,
    settings: settings,
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() predicate) async {
  for (var attempt = 0; attempt < 40 && !predicate(); attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(predicate(), isTrue);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

class _ControlledLegalRepository extends LegalDocumentRepository {
  _ControlledLegalRepository(this.localCatalog);

  final LegalCatalog localCatalog;
  final Completer<LegalCatalogSnapshot> _refresh = Completer();
  int refreshCalls = 0;

  @override
  Future<LegalCatalogSnapshot> load({required String locale}) async =>
      LegalCatalogSnapshot(
        catalog: localCatalog,
        source: LegalContentSource.bundled,
      );

  @override
  Future<LegalCatalogSnapshot> refresh({
    required String locale,
    bool force = false,
  }) {
    refreshCalls++;
    return _refresh.future;
  }

  void complete(LegalCatalogSnapshot snapshot) => _refresh.complete(snapshot);
}

class _CountingAccount extends MemberAccountController {
  _CountingAccount() : super(networkAllowed: false);
  int synchronizeCalls = 0;

  @override
  Future<void> synchronize() async {
    synchronizeCalls++;
  }
}

class _CountingCloud extends ReadingCloudController {
  _CountingCloud(MemberAccountController account)
    : super(account: account, automatic: false, networkAllowed: false);

  int initializeCalls = 0;

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }
}

class _Fixture {
  const _Fixture({
    required this.repository,
    required this.account,
    required this.cloud,
    required this.diagnostics,
    required this.theme,
    required this.settings,
  });

  final _ControlledLegalRepository repository;
  final _CountingAccount account;
  final _CountingCloud cloud;
  final _CountingDiagnostics diagnostics;
  final ThemeNotifier theme;
  final AppSettingsNotifier settings;

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    settings.dispose();
    theme.dispose();
    cloud.dispose();
    diagnostics.dispose();
    account.dispose();
  }
}

class _CountingDiagnostics extends DiagnosticsController {
  _CountingDiagnostics(MemberAccountController account)
    : super(account: account);

  bool networkAllowed = false;

  @override
  void setNetworkAllowed(bool allowed) {
    networkAllowed = allowed;
  }
}
