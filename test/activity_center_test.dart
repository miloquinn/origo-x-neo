import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
import 'package:xxread/pages/activities/activity_center_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/activities/activity.dart';
import 'package:xxread/services/core/app_distribution.dart';

import 'support/activity_fixture.dart';

Future<void> pumpActivityCenter(
  WidgetTester tester,
  ActivityTestAccount account, {
  Size size = const Size(390, 844),
  double scale = 1,
  Brightness brightness = Brightness.light,
  String locale = 'zh',
  Future<bool> Function(Uri)? openDetail,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    ChangeNotifierProvider<MemberAccountController>.value(
      value: account,
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1768B4),
            brightness: brightness,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: openDetail == null
            ? const ActivityCenterPage()
            : ActivityCenterPage(openDetail: openDetail),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(AppDistribution.debugReset);

  testWidgets(
    'renders server metadata and separates detail from native progress',
    (tester) async {
      final account = ActivityTestAccount();
      addTearDown(account.dispose);
      addTearDown(tester.view.reset);
      AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
      Uri? opened;
      await pumpActivityCenter(
        tester,
        account,
        openDetail: (uri) async {
          opened = uri;
          return true;
        },
      );
      expect(find.text('邀请好友，一起探元'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('activity-progress-referral')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('activity-detail-referral')));
      await tester.pumpAndSettle();
      expect(opened!.path, '/activities/referral');
      expect(opened!.queryParameters['v'], '3');
      expect(opened!.queryParameters.containsKey('token'), isFalse);
    },
  );

  testWidgets(
    'guest progress opens native sign-in and follows successful login',
    (tester) async {
      final account = ActivityTestAccount();
      addTearDown(account.dispose);
      addTearDown(tester.view.reset);
      AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
      await pumpActivityCenter(tester, account);
      await tester.tap(
        find.byKey(const ValueKey('activity-progress-referral')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
      account.signIn();
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsNothing);
      expect(
        find.byKey(const ValueKey('account-invite-retry')),
        findsOneWidget,
      );
      account.signOut();
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsOneWidget);
    },
  );

  testWidgets(
    'pending MFA stays in native authentication before showing progress',
    (tester) async {
      final account = ActivityTestAccount()..mfaPending = true;
      account.signIn();
      addTearDown(account.dispose);
      addTearDown(tester.view.reset);
      AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
      await pumpActivityCenter(tester, account);
      await tester.tap(
        find.byKey(const ValueKey('activity-progress-referral')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('account-mfa-verify')), findsOneWidget);
      expect(find.byKey(const ValueKey('account-invite-retry')), findsNothing);
      account.finishMfa();
      await tester.pumpAndSettle();
      expect(find.byType(AccountPage), findsNothing);
      expect(
        find.byKey(const ValueKey('account-invite-retry')),
        findsOneWidget,
      );
    },
  );

  for (final channel in [
    AppDistributionChannel.appleStore,
    AppDistributionChannel.googlePlay,
  ]) {
    testWidgets(
      '$channel only displays announcements, even with a bad referral response',
      (tester) async {
        final account = ActivityTestAccount();
        addTearDown(account.dispose);
        addTearDown(tester.view.reset);
        AppDistribution.debugOverride(channel: channel);
        await pumpActivityCenter(tester, account);
        expect(find.byKey(const ValueKey('activity-referral')), findsNothing);
        expect(
          find.byKey(const ValueKey('activity-autumn-reading')),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets(
    'failure clears old cards and retry loads new published content',
    (tester) async {
      final account = ActivityTestAccount();
      addTearDown(account.dispose);
      addTearDown(tester.view.reset);
      await pumpActivityCenter(tester, account);
      account.loader = () => Future.error(StateError('Offline'));
      await tester.tap(find.byKey(const ValueKey('activities-refresh')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('activities-retry')), findsOneWidget);
      expect(find.text('邀请好友，一起探元'), findsNothing);
      account.loader = () async => [];
      await tester.tap(find.byKey(const ValueKey('activities-retry')));
      await tester.pumpAndSettle();
      expect(find.text('暂时没有活动'), findsOneWidget);
    },
  );

  testWidgets('late catalogue response cannot replace a newer refresh', (
    tester,
  ) async {
    final older = Completer<List<AppActivity>>();
    final account = ActivityTestAccount()..loader = () => older.future;
    addTearDown(account.dispose);
    addTearDown(tester.view.reset);
    await pumpActivityCenter(tester, account);
    account.loader = () async => [];
    await tester.tap(find.byKey(const ValueKey('activities-refresh')));
    await tester.pumpAndSettle();
    older.complete(sampleActivities());
    await tester.pumpAndSettle();
    expect(find.text('暂时没有活动'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-referral')), findsNothing);
  });

  testWidgets('browser failure presents a retryable message', (tester) async {
    final account = ActivityTestAccount();
    addTearDown(account.dispose);
    addTearDown(tester.view.reset);
    AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
    await pumpActivityCenter(tester, account, openDetail: (_) async => false);
    await tester.tap(find.byKey(const ValueKey('activity-detail-referral')));
    await tester.pumpAndSettle();
    expect(find.text('无法打开活动详情，请稍后重试。'), findsOneWidget);
  });

  for (final scenario in [
    (320.0, 2.0, 'zh'),
    (390.0, 2.0, 'en'),
    (1024.0, 1.0, 'zh'),
  ]) {
    testWidgets(
      'activity layout ${scenario.$1}px ${scenario.$2}x ${scenario.$3}',
      (tester) async {
        final account = ActivityTestAccount();
        addTearDown(account.dispose);
        addTearDown(tester.view.reset);
        AppDistribution.debugOverride(channel: AppDistributionChannel.direct);
        await pumpActivityCenter(
          tester,
          account,
          size: Size(scenario.$1, 844),
          scale: scenario.$2,
          locale: scenario.$3,
          brightness: Brightness.dark,
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class ActivityTestAccount extends MemberAccountController {
  bool mfaPending = false;
  @override
  bool get mfaRequired => mfaPending;
  void finishMfa() {
    mfaPending = false;
    notifyListeners();
  }

  @override
  bool get initialized => true;
  @override
  bool get isAuthenticated => _signedIn;
  Future<List<AppActivity>> Function()? loader;
  bool _signedIn = false;
  @override
  Future<List<AppActivity>> loadActivities() =>
      loader?.call() ?? Future.value(sampleActivities());
  @override
  Future<void> initialize({bool force = false}) async {}
  @override
  Future<void> loadReferral() async {}
  @override
  Uri activityDetailUri(
    AppActivity activity, {
    required String locale,
    bool dark = false,
  }) => activity.detailUri(
    Uri.parse('https://example.test'),
    channel: AppDistribution.usesStoreBilling ? 'store' : 'official',
    locale: locale,
    dark: dark,
  );
  @override
  MemberUser? get user => _signedIn
      ? MemberUser.fromJson({
          'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
          'email': 'preview@example.test',
          'email_verified': true,
          'username': 'preview',
          'effective_name': 'Reader',
          'auth_methods': ['password'],
          'created_at': '2026-10-08T00:00:00Z',
        })
      : null;
  void signIn() {
    _signedIn = true;
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    notifyListeners();
  }
}
