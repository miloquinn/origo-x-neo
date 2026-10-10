import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xxread/services/account/account_api_client.dart';
import 'package:xxread/services/core/advanced_feature_access.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
  });

  tearDown(() {
    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: false);
  });

  test('premium implies reader access and snapshot updates atomically', () {
    final changes = <AdvancedFeatureAccessSnapshot>[];
    void listener() => changes.add(AdvancedFeatureAccess.accessChanges.value);
    AdvancedFeatureAccess.accessChanges.addListener(listener);
    addTearDown(
      () => AdvancedFeatureAccess.accessChanges.removeListener(listener),
    );

    AdvancedFeatureAccess.update(readerUnlocked: false, premiumUnlocked: true);

    expect(AdvancedFeatureAccess.readerFeaturesUnlocked, isTrue);
    expect(AdvancedFeatureAccess.premiumUnlocked, isTrue);
    expect(changes, [
      const AdvancedFeatureAccessSnapshot(
        readerFeaturesUnlocked: true,
        premiumUnlocked: true,
      ),
    ]);
  });

  test('legacy premium listener remains a premium-only projection', () {
    var notifications = 0;
    void listener() => notifications++;
    AdvancedFeatureAccess.premiumAccessChanges.addListener(listener);
    addTearDown(
      () => AdvancedFeatureAccess.premiumAccessChanges.removeListener(listener),
    );

    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: false);
    expect(notifications, 0);
    AdvancedFeatureAccess.premiumUnlocked = true;
    expect(notifications, 1);
  });

  test('reader feature guard uses the shared entitlement error', () {
    expect(
      AdvancedFeatureAccess.requireReaderFeatures,
      throwsA(
        isA<MemberAccountException>().having(
          (error) => error.message,
          'message',
          '此功能需要 Origo 开卷或 Origo 探元权益',
        ),
      ),
    );

    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: false);
    expect(AdvancedFeatureAccess.requireReaderFeatures, returnsNormally);
  });

  test('compatibility opt-in is independent from both entitlements', () async {
    expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isTrue);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(additionalSourceProtocolsPreferenceKey, false);
    AdvancedFeatureAccess.update(readerUnlocked: true, premiumUnlocked: true);
    expect(await AdvancedFeatureAccess.additionalProtocolsEnabled(), isFalse);
  });
}
