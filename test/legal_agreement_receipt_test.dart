import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/pages/legal/user_agreement_page.dart';
import 'package:xxread/services/backup/backup_archive.dart';

import 'support/legal_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'device consent cannot be exported or restored through settings backup',
    () {
      expect(
        BackupArchive.includesPreference(UserAgreementService.receiptKey),
        isFalse,
      );
    },
  );

  test(
    'legacy boolean alone does not accept newly published policies',
    () async {
      SharedPreferences.setMockInitialValues({
        'userAgreementAccepted': true,
        'agreementAcceptedVersion': '2026-07-19.2',
        'thirdPartySourceBoundaryAccepted': true,
      });
      expect(
        await UserAgreementService.hasUserAcceptedAgreement(
          catalog: legalFixtureCatalog(),
        ),
        isFalse,
      );
    },
  );

  test(
    'receipt records exactly the displayed versions, hashes, language and dates',
    () async {
      final shown = legalFixtureCatalog(revision: '2026-10-08.2');
      await UserAgreementService.acceptAgreement(
        locale: 'en-GB',
        catalog: shown,
      );
      final prefs = await SharedPreferences.getInstance();
      final receipt =
          jsonDecode(prefs.getString(UserAgreementService.receiptKey)!) as Map;
      expect(receipt['contentLocale'], 'en');
      expect(receipt['locale'], 'en-GB');
      expect(DateTime.parse(receipt['acceptedAt'] as String).isUtc, isTrue);
      for (final doc in shown.acceptanceDocuments) {
        expect(receipt['documents'][doc.id]['revision'], doc.revision);
        expect(receipt['documents'][doc.id]['hash'], doc.contentHash);
        expect(
          receipt['documents'][doc.id]['effectiveDate'],
          doc.effectiveDate,
        );
        expect(receipt['documents'][doc.id]['updatedAt'], doc.updatedAt);
      }
      expect(
        await UserAgreementService.hasUserAcceptedAgreement(catalog: shown),
        isTrue,
      );
      expect(
        await UserAgreementService.hasUserAcceptedAgreement(
          catalog: legalFixtureCatalog(revision: '2026-10-08.3'),
        ),
        isFalse,
      );
      expect(receipt['documents'].length, 3);
    },
  );

  test(
    'editorial revision and display language do not fabricate another consent',
    () async {
      await UserAgreementService.acceptAgreement(
        locale: 'en',
        catalog: legalFixtureCatalog(),
      );
      final editorial = legalFixtureCatalog(
        revision: '2026-10-08.2',
        consentVersion: '2026-10-08.1',
      );
      expect(
        await UserAgreementService.hasUserAcceptedAgreement(catalog: editorial),
        isTrue,
      );
      expect(
        await UserAgreementService.hasUserAcceptedAgreement(
          catalog: legalFixtureCatalog(locale: 'zh-CN'),
        ),
        isTrue,
      );
      final receipt =
          jsonDecode(
                (await SharedPreferences.getInstance()).getString(
                  UserAgreementService.receiptKey,
                )!,
              )
              as Map;
      expect(receipt['documents']['privacy']['revision'], '2026-10-08.1');
    },
  );

  test('reset clears receipts without changing cached legal content', () async {
    await UserAgreementService.acceptAgreement(
      locale: 'en',
      catalog: legalFixtureCatalog(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('legal.catalog.fixture', 'preserve');
    await UserAgreementService.resetAgreementStatus();
    expect(prefs.getString(UserAgreementService.receiptKey), isNull);
    expect(prefs.getString('legal.catalog.fixture'), 'preserve');
    expect(
      await UserAgreementService.hasUserAcceptedAgreement(
        catalog: legalFixtureCatalog(),
      ),
      isFalse,
    );
  });
}
