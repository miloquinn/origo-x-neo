import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/legal_document.dart';
import 'package:xxread/pages/legal/legal_documents_page.dart';
import 'package:xxread/services/legal/legal_document_repository.dart';
import 'package:xxread/widgets/floating_subpage_scaffold.dart';

void main() {
  testWidgets('locale switch owns an independent refresh generation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final repository = _ControlledRepository();
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LegalDocumentsPage(repository: repository),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('EN terms'), findsOneWidget);
    expect(repository.enRefresh.isCompleted, isFalse);

    locale.value = const Locale('zh');
    await tester.pump();
    await tester.pump();
    expect(find.text('中文条款'), findsOneWidget);
    expect(repository.zhRefresh.isCompleted, isFalse);

    repository.enRefresh.complete(_snapshot('en', title: 'STALE EN'));
    await tester.pump();
    expect(find.text('STALE EN'), findsNothing);
    expect(find.text('中文条款'), findsOneWidget);
    expect(
      tester
          .widget<FloatingSubpageAction>(
            find.byKey(const ValueKey('legal-documents-refresh')),
          )
          .onPressed,
      isNull,
      reason: 'the active zh refresh must still own the busy state',
    );

    repository.zhRefresh.complete(_snapshot('zh-CN', title: '中文已更新'));
    await tester.pump();
    expect(find.text('中文已更新'), findsOneWidget);
    expect(
      tester
          .widget<FloatingSubpageAction>(
            find.byKey(const ValueKey('legal-documents-refresh')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}

class _ControlledRepository extends LegalDocumentRepository {
  final enRefresh = Completer<LegalCatalogSnapshot>();
  final zhRefresh = Completer<LegalCatalogSnapshot>();

  @override
  Future<LegalCatalogSnapshot> load({required String locale}) async =>
      _snapshot(locale, title: locale.startsWith('zh') ? '中文条款' : 'EN terms');

  @override
  Future<LegalCatalogSnapshot> refresh({
    required String locale,
    bool force = false,
  }) => locale.startsWith('zh') ? zhRefresh.future : enRefresh.future;
}

LegalCatalogSnapshot _snapshot(String locale, {required String title}) =>
    LegalCatalogSnapshot(
      catalog: LegalCatalog(
        schemaVersion: 1,
        bundleVersion: '2026-10-08.1',
        locale: locale,
        documents: [
          for (final id in const ['terms', 'privacy', 'sources'])
            LegalDocument(
              id: id,
              locale: locale,
              title: id == 'terms' ? title : '$title $id',
              summary: 'Summary for $id',
              revision: '2026-10-08.1',
              consentVersion: '2026-10-08.1',
              effectiveDate: '2026-10-08',
              updatedAt: '2026-10-08',
              changeSummary: const ['Published.'],
              canonicalUrl: Uri.parse('https://open.xxread.top/legal/$id'),
              requiresAcceptance: true,
              sections: const [
                LegalSection(id: 'scope', title: 'Scope', paragraphs: ['Body']),
              ],
            ),
        ],
      ),
      source: LegalContentSource.bundled,
    );
