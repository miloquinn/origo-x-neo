import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/account_page.dart';
import 'package:xxread/services/account/account.dart';

// Captures the production referral widgets with sample server data, not a mock UI.
void main() {
  testWidgets('render invitation progress across themes and sizes', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final font = await File(
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ).readAsBytes();
      await (FontLoader(
        'ReferralPreview',
      )..addFont(Future.value(ByteData.sublistView(font)))).load();
      final mono = await File('/System/Library/Fonts/Menlo.ttc').readAsBytes();
      await (FontLoader(
        'monospace',
      )..addFont(Future.value(ByteData.sublistView(mono)))).load();
      final root = Platform.resolvedExecutable.split('/bin/cache').first;
      final icons = await File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
    for (final scenario in [
      (
        name: 'mobile-light',
        size: const Size(390, 844),
        dark: false,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'mobile-dark',
        size: const Size(390, 844),
        dark: true,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'wide-light',
        size: const Size(1024, 768),
        dark: false,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'wide-dark',
        size: const Size(1024, 768),
        dark: true,
        scale: 1.0,
        locale: 'zh',
      ),
      (
        name: 'narrow-large',
        size: const Size(320, 568),
        dark: false,
        scale: 2.0,
        locale: 'zh',
      ),
      (
        name: 'english-large',
        size: const Size(390, 844),
        dark: true,
        scale: 2.0,
        locale: 'en',
      ),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      final account = _PreviewAccount();
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: MaterialApp(
            locale: Locale(scenario.locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'ReferralPreview',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1768B4),
                brightness: scenario.dark ? Brightness.dark : Brightness.light,
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scenario.scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: const Key('capture-referral'),
                child: child!,
              ),
            ),
            home: const AccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-referral')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-referral')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario.name);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture-referral')),
      );
      await tester.runAsync(() async {
        final output = Directory('docs/previews/referral-campaign-20261007');
        await output.create(recursive: true);
        final rendered = await boundary.toImage(pixelRatio: 2);
        final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${scenario.name}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        rendered.dispose();
      });
      await tester.ensureVisible(
        find.byKey(const ValueKey('account-invite-records')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('account-invite-records')));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.name} records',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      account.dispose();
    }
  });
}

class _PreviewAccount extends MemberAccountController {
  @override
  bool get initialized => true;
  @override
  bool get isAuthenticated => true;
  @override
  MemberUser get user => MemberUser.fromJson({
    'id': '6e29be31-ffeb-4699-bf69-8b37afe15504',
    'email': 'preview@example.test',
    'email_verified': true,
    'username': 'preview',
    'display_name': 'Reader',
    'effective_name': 'Reader',
    'auth_methods': ['password'],
    'created_at': '2026-10-07T00:00:00Z',
  });
  @override
  Future<void> initialize({bool force = false}) async {}
  @override
  Future<void> loadReferral() async {}
  @override
  MemberReferral get referral => MemberReferral.fromJson({
    'invite_code': 'OR-READER',
    'invite_url': 'https://example.test/invite/OR-READER',
    'stats': {'invited': 4, 'active': 3, 'paid': 1},
    'enrolled': true,
    'can_enroll': false,
    'campaign': {
      'id': 'preview-campaign',
      'revision': 2,
      'enabled': true,
      'state': 'active',
      'title': '邀请好友，一起探元',
      'description': 'Sample campaign terms belong on the rules page.',
      'active_days': 3,
      'min_daily_seconds': 60,
      'bind_window_days': 7,
      'tiers': [
        {
          'id': 'active-entry',
          'metric': 'active',
          'target': 2,
          'reward_days': 30,
          'enabled': true,
        },
        {
          'id': 'active-main',
          'metric': 'active',
          'target': 5,
          'reward_days': 90,
          'enabled': true,
        },
        {
          'id': 'active-lifetime',
          'metric': 'active',
          'target': 12,
          'reward_days': null,
          'enabled': false,
        },
        {
          'id': 'paid-lifetime',
          'metric': 'paid',
          'target': 2,
          'reward_days': null,
          'enabled': true,
        },
      ],
      'rules': ['有效新用户须在三个不同日期阅读。', '五位有效好友累计赠送90天，已经领取30天时补发60天。'],
      'payment_channels': {
        'apple': 'automatic',
        'ldxp': 'verified_order',
        'google_play': 'manual_review',
      },
    },
    'rewards': [
      {
        'tier_id': 'active-entry',
        'metric': 'active',
        'target': 2,
        'reward_days': 30,
        'granted_at': '2026-10-07T00:00:00Z',
        'expires_at': '2026-11-06T00:00:00Z',
        'revoked_at': null,
      },
    ],
    'recent_invites': [
      {'name': 'Friend', 'status': 'bound', 'bound_at': '2026-10-07T00:00:00Z'},
    ],
  });
}
