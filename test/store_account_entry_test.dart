import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/widgets/settings_account_card.dart';

class _Account extends MemberAccountController {
  bool permanent = false;
  bool premium = false;

  @override
  bool get hasPermanentReaderAccess => permanent;
  @override
  bool get hasPremiumAccess => premium;
  @override
  bool get hasActiveReaderTrial => !permanent;

  void update({required bool ownsApp, required bool ownsPremium}) {
    permanent = ownsApp;
    premium = ownsPremium;
    notifyListeners();
  }
}

void main() {
  for (final channel in AppDistributionChannel.values) {
    testWidgets('$channel separates reader and Premium account entries', (
      tester,
    ) async {
      AppDistribution.debugOverride(channel: channel);
      addTearDown(AppDistribution.debugReset);
      final account = _Account();
      addTearDown(account.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsAccountCard(
                quiet: true,
                showMembershipSection: true,
              ),
            ),
          ),
        ),
      );
      final store = channel != AppDistributionChannel.direct;
      final reader = find.byKey(const ValueKey('settings-reader-license'));
      final upgrade = find.byKey(const ValueKey('settings-membership-entry'));
      final badge = find.byKey(
        const ValueKey('settings-account-premium-badge'),
      );
      expect(reader, store ? findsOneWidget : findsNothing);
      expect(upgrade, store ? findsNothing : findsOneWidget);

      // Merely syncing Premium during the reading trial cannot reveal it.
      account.update(ownsApp: false, ownsPremium: true);
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(badge, store ? findsNothing : findsOneWidget);

      account.update(ownsApp: true, ownsPremium: false);
      await tester.pump();
      expect(upgrade, findsOneWidget);
      expect(badge, findsNothing);

      account.update(ownsApp: true, ownsPremium: true);
      await tester.pump();
      expect(upgrade, findsNothing);
      expect(badge, findsOneWidget);
      expect(reader, store ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
