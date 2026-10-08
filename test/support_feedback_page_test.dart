@Tags(['isolated-process'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/support/feedback_page.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/services/diagnostics/diagnostics_controller.dart';

class _Account extends MemberAccountController {
  _Account(bool authenticated)
    : currentUser = authenticated ? _member('account-1') : null;

  MemberUser? currentUser;

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  MemberUser? get user => currentUser;

  void switchAccount() {
    currentUser = _member('account-2');
    notifyListeners();
  }
}

MemberUser _member(String id) => MemberUser(
  id: id,
  email: '$id@example.test',
  emailVerified: true,
  username: id,
  effectiveName: id,
  authMethods: const ['password'],
  createdAt: DateTime.utc(2026, 1, 1),
);

class _Diagnostics extends DiagnosticsController {
  _Diagnostics({required super.account, this.active = false});

  bool active;
  int snapshotCalls = 0;

  @override
  bool get enabled => active;

  @override
  bool get supported => true;

  @override
  Future<void> setEnabled(bool value) async {
    active = value;
    notifyListeners();
  }

  @override
  Map<String, dynamic>? snapshot() {
    snapshotCalls++;
    return active
        ? <String, dynamic>{'report_id': 'snapshot-1', 'memory_peak_mb': 128}
        : null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Origo X',
      packageName: 'com.niki.xxread',
      version: '2.7.0',
      buildNumber: '270001',
      buildSignature: '',
    );
  });

  testWidgets('signed-out user is sent to the existing account flow', (
    tester,
  ) async {
    await _pump(tester, authenticated: false, submitter: (_) async => {});

    expect(
      find.byKey(const ValueKey('feedback-sign-in-required')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feedback-submit')), findsNothing);
    expect(find.text('登录后提交反馈'), findsOneWidget);
  });

  testWidgets('successful feedback omits diagnostics by default', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    await _pump(
      tester,
      submitter: (payload) async {
        submitted = payload;
        return {'feedback_id': payload['feedback_id'], 'status': 'received'};
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('feedback-message')),
      '阅读页偶尔会卡顿',
    );
    await _tapSubmit(tester);

    expect(submitted, isNotNull);
    expect(submitted!['category'], 'bug');
    expect(submitted!['expected_user_id'], 'account-1');
    expect(submitted!['message'], '阅读页偶尔会卡顿');
    expect(submitted!['app_version'], '2.7.0');
    expect(submitted!['build_number'], '270001');
    expect(submitted!['platform'], 'ios');
    expect(submitted!.containsKey('diagnostics'), isFalse);
    expect(find.byKey(const ValueKey('feedback-success')), findsOneWidget);
  });

  testWidgets('diagnostics are attached only after explicit selection', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    await _pump(
      tester,
      diagnosticsEnabled: true,
      submitter: (payload) async {
        submitted = payload;
        return {'feedback_id': payload['feedback_id'], 'status': 'received'};
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('feedback-message')),
      '耗电速度异常',
    );
    await tester.tap(find.byKey(const ValueKey('feedback-attach-diagnostics')));
    await tester.pump();
    await _tapSubmit(tester);

    expect(submitted!['diagnostics'], {
      'report_id': 'snapshot-1',
      'memory_peak_mb': 128,
    });
  });

  testWidgets('failed retry keeps the message and feedback id', (tester) async {
    final attempts = <Map<String, dynamic>>[];
    final diagnostics = await _pump(
      tester,
      diagnosticsEnabled: true,
      submitter: (payload) async {
        attempts.add(Map<String, dynamic>.from(payload));
        if (attempts.length == 1) throw StateError('offline');
        return {'feedback_id': payload['feedback_id'], 'status': 'received'};
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('feedback-message')),
      '重试时请保留这段内容',
    );
    await tester.tap(find.byKey(const ValueKey('feedback-attach-diagnostics')));
    await tester.pump();
    await _tapSubmit(tester);

    expect(find.byKey(const ValueKey('feedback-error')), findsOneWidget);
    expect(find.text('重试时请保留这段内容'), findsOneWidget);
    await _tapSubmit(tester);

    expect(attempts, hasLength(2));
    expect(attempts[1], attempts[0]);
    expect(diagnostics.snapshotCalls, 1);
    expect(find.byKey(const ValueKey('feedback-success')), findsOneWidget);
  });

  testWidgets('account switch discards the old submission result and draft', (
    tester,
  ) async {
    late _Account account;
    await _pump(
      tester,
      onAccount: (value) => account = value,
      submitter: (payload) async {
        account.switchAccount();
        return {'feedback_id': payload['feedback_id'], 'status': 'received'};
      },
    );

    await tester.enterText(
      find.byKey(const ValueKey('feedback-message')),
      '旧账号正在提交的内容',
    );
    await _tapSubmit(tester);

    expect(find.byKey(const ValueKey('feedback-success')), findsNothing);
    expect(find.text('登录账号已变化，请重新填写后提交。'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('feedback-message')))
          .controller!
          .text,
      isEmpty,
    );
  });
}

Future<_Diagnostics> _pump(
  WidgetTester tester, {
  bool authenticated = true,
  bool diagnosticsEnabled = false,
  void Function(_Account account)? onAccount,
  required FeedbackSubmitter submitter,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 1050);
  addTearDown(tester.view.reset);
  final account = _Account(authenticated);
  onAccount?.call(account);
  final diagnostics = _Diagnostics(
    account: account,
    active: diagnosticsEnabled,
  );
  addTearDown(diagnostics.dispose);
  addTearDown(account.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MemberAccountController>.value(value: account),
        ChangeNotifierProvider<DiagnosticsController>.value(value: diagnostics),
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeedbackPage(submitter: submitter, platformName: 'ios'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return diagnostics;
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final submit = find.byKey(const ValueKey('feedback-submit'));
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pumpAndSettle();
}
