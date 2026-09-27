import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/account/membership_redemption_page.dart';
import 'package:xxread/services/account/account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screenshotDirectory = Platform.environment['REDEMPTION_SCREENSHOT_DIR'];
  final previewFontPath =
      Platform.environment['REDEMPTION_PREVIEW_FONT'] ??
      Platform.environment['PREMIUM_PREVIEW_FONT'] ??
      (File('/System/Library/Fonts/Hiragino Sans GB.ttc').existsSync()
          ? '/System/Library/Fonts/Hiragino Sans GB.ttc'
          : null);

  setUpAll(() async {
    if (screenshotDirectory == null) return;
    if (previewFontPath != null) {
      final text = FontLoader('RedemptionPreview');
      text.addFont(
        File(previewFontPath).readAsBytes().then(ByteData.sublistView),
      );
      await text.load();
    }
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('shows the current Origo account and disables blank codes', (
    tester,
  ) async {
    final account = _RedemptionAccount();
    addTearDown(account.dispose);

    await _pumpPage(tester, account);

    expect(find.text('阅读者'), findsOneWidget);
    expect(find.text('reader@example.com'), findsOneWidget);
    expect(_redeemButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('account-redemption-code')),
      '   ',
    );
    await tester.pump();

    expect(_redeemButton(tester).onPressed, isNull);
    expect(account.submittedCodes, isEmpty);
  });

  testWidgets('trims the code and disables repeated submission while pending', (
    tester,
  ) async {
    final pending = Completer<void>();
    final account = _RedemptionAccount(pending: pending);
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    final field = find.byKey(const ValueKey('account-redemption-code'));
    final submit = find.byKey(const ValueKey('account-redeem-premium'));
    await tester.enterText(field, '  ORIGO-TEST-CODE  ');
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(account.submittedCodes, ['ORIGO-TEST-CODE']);
    expect(_redeemButton(tester).onPressed, isNull);

    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the code after failure and exposes the server message', (
    tester,
  ) async {
    final account = _RedemptionAccount(
      failure: const MemberAccountException('兑换码无效或已使用'),
    );
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    final field = find.byKey(const ValueKey('account-redemption-code'));
    await tester.enterText(field, 'ORIGO-FAILED-CODE');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-redeem-premium')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(field).controller?.text,
      'ORIGO-FAILED-CODE',
    );
    expect(
      find.byKey(const ValueKey('membership-redemption-status')),
      findsOneWidget,
    );
    expect(find.text('兑换码无效或已使用'), findsOneWidget);
    expect(_redeemButton(tester).onPressed, isNotNull);
  });

  testWidgets('clears the code and refreshes the entitlement after success', (
    tester,
  ) async {
    final account = _RedemptionAccount();
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    final field = find.byKey(const ValueKey('account-redemption-code'));
    await tester.enterText(field, 'ORIGO-SUCCESS-CODE');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-redeem-premium')));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    expect(account.hasPremiumAccess, isTrue);
    expect(account.submittedCodes, ['ORIGO-SUCCESS-CODE']);
    expect(find.text('兑换成功，权益已更新'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('membership-redemption-status')),
      findsOneWidget,
    );
    expect(_redeemButton(tester).onPressed, isNull);
  });

  testWidgets('clears a pending code when the signed-in account changes', (
    tester,
  ) async {
    final account = _RedemptionAccount();
    addTearDown(account.dispose);
    await _pumpPage(tester, account);

    final field = find.byKey(const ValueKey('account-redemption-code'));
    await tester.enterText(field, 'DO-NOT-CARRY-TO-NEXT-ACCOUNT');
    account.signOut();
    await tester.pump();

    expect(field, findsNothing);

    account.switchAccount();
    await tester.pump();

    expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    expect(find.text('另一位阅读者'), findsOneWidget);
    expect(find.text('second@example.com'), findsOneWidget);
  });

  testWidgets(
    'keeps the code field and submit action reachable above keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      final account = _RedemptionAccount();
      addTearDown(account.dispose);
      await _pumpPage(tester, account);

      final field = find.byKey(const ValueKey('account-redemption-code'));
      await tester.ensureVisible(field);
      await tester.enterText(field, 'ORIGO-KEYBOARD-CODE');
      final submit = find.byKey(const ValueKey('account-redeem-premium'));
      await tester.ensureVisible(submit);
      await tester.pump();

      expect(field.hitTestable(), findsOneWidget);
      expect(submit.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'exports the redemption page in ${mode.name} when requested',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final account = _RedemptionAccount();
        addTearDown(account.dispose);
        final previewKey = GlobalKey();

        await _pumpPage(
          tester,
          account,
          themeMode: mode,
          previewKey: previewKey,
          previewFont: previewFontPath != null,
        );
        await tester.enterText(
          find.byKey(const ValueKey('account-redemption-code')),
          'ORIGO-TEST-CODE',
        );
        await tester.pumpAndSettle();

        await _capture(
          tester,
          previewKey,
          '$screenshotDirectory/membership-redemption-${mode.name}.png',
        );
      },
      skip: screenshotDirectory == null,
    );
  }
}

Future<void> _pumpPage(
  WidgetTester tester,
  MemberAccountController account, {
  ThemeMode themeMode = ThemeMode.light,
  GlobalKey? previewKey,
  bool previewFont = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      themeMode: themeMode,
      theme: _theme(Brightness.light, previewFont: previewFont),
      darkTheme: _theme(Brightness.dark, previewFont: previewFont),
      home: RepaintBoundary(
        key: previewKey,
        child: MembershipRedemptionPage(account: account),
      ),
    ),
  );
  await tester.pump();
}

ThemeData _theme(Brightness brightness, {required bool previewFont}) {
  final theme = ThemeData(brightness: brightness);
  if (!previewFont) return theme;
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'RedemptionPreview'),
  );
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(File(path).parent.path).create(recursive: true);
    await File(path).writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

ButtonStyleButton _redeemButton(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('account-redeem-premium')),
    );

class _RedemptionAccount extends MemberAccountController {
  _RedemptionAccount({this.pending, this.failure});

  final Completer<void>? pending;
  final Object? failure;
  final List<String> submittedCodes = [];
  bool _premium = false;
  MemberUser? _user = _reader(
    id: 'reader-1',
    email: 'reader@example.com',
    name: '阅读者',
  );

  @override
  bool get isAuthenticated => _user != null;

  @override
  MemberUser? get user => _user;

  @override
  bool get hasPremiumAccess => _premium;

  @override
  Future<void> redeemMembership(String code) async {
    submittedCodes.add(code);
    if (failure case final error?) throw error;
    await pending?.future;
    _premium = true;
    notifyListeners();
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }

  void switchAccount() {
    _user = _reader(
      id: 'reader-2',
      email: 'second@example.com',
      name: '另一位阅读者',
    );
    notifyListeners();
  }
}

MemberUser _reader({
  required String id,
  required String email,
  required String name,
}) => MemberUser(
  id: id,
  email: email,
  emailVerified: true,
  username: id,
  effectiveName: name,
  authMethods: const ['google'],
  createdAt: DateTime.utc(2026, 1, 1),
);
