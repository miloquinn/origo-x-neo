import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  test('trial is not a permanent or promotional premium entitlement', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final membership = MemberMembership.fromJson({
      'premium': false,
      'user_id': 'owner',
      'entitlements': [],
      'store_trial': {
        'started_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'expires_at': now.add(const Duration(days: 13)).toIso8601String(),
        'channel': 'google_play',
      },
    });
    expect(membership.premium, isFalse);
    expect(membership.storeTrial!.isActiveAt(now), isTrue);
    const cache = MemberMembershipCache();
    await cache.save('owner', membership);
    final restored = await cache.load();
    expect(restored!.membership.premium, isFalse);
    expect(
      restored.membership.storeTrial!.expiresAt,
      membership.storeTrial!.expiresAt,
    );
  });

  test('malformed timeline, unknown channel and expiry cannot grant trial', () {
    final now = DateTime.now();
    for (final trial in [
      MemberStoreTrial(
        startedAt: now.add(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 14)),
        channel: 'apple',
      ),
      MemberStoreTrial(
        startedAt: now.subtract(const Duration(days: 14)),
        expiresAt: now,
        channel: 'google_play',
      ),
      MemberStoreTrial(
        startedAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 1)),
        channel: 'direct',
      ),
    ]) {
      expect(trial.isActiveAt(now), isFalse);
    }
  });

  test('legacy reader grant does not imply premium source access', () {
    final membership = MemberMembership.fromJson({
      'premium': false,
      'entitlements': [
        {
          'feature_key': 'store_reader',
          'source': 'legacy_store_reader',
          'status': 'active',
          'granted_at': DateTime.now().toIso8601String(),
        },
      ],
    });
    expect(membership.hasStoreReaderEntitlement, isTrue);
    expect(membership.premium, isFalse);
  });
}
