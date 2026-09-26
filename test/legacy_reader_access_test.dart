import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/services/core/legacy_reader_access.dart';

void main() {
  setUp(() {
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
    LegacyReaderAccess.debugReset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(AppDistribution.debugReset);

  test(
    'existing store agreement preserves reading even with an old version',
    () async {
      SharedPreferences.setMockInitialValues({
        'userAgreementAccepted': true,
        'agreementAcceptedVersion': 'old-version',
      });
      await LegacyReaderAccess.initialize();
      expect(LegacyReaderAccess.allowed, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          LegacyReaderAccess.storageKey,
        ),
        isTrue,
      );
    },
  );

  test(
    'new installation cannot become legacy after accepting its agreement',
    () async {
      await LegacyReaderAccess.initialize();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('userAgreementAccepted', true);
      LegacyReaderAccess.debugReset();
      await LegacyReaderAccess.initialize();
      expect(LegacyReaderAccess.allowed, isFalse);
      expect(preferences.getBool(LegacyReaderAccess.storageKey), isFalse);
    },
  );

  test('website free use is not a transferable store reader grant', () async {
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    SharedPreferences.setMockInitialValues({'userAgreementAccepted': true});
    await LegacyReaderAccess.initialize();
    AppDistribution.debugOverride(channel: AppDistributionChannel.googlePlay);
    await LegacyReaderAccess.initialize();
    expect(LegacyReaderAccess.allowed, isFalse);
  });
}
