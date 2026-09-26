import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xxread/services/account/account.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/services/core/app_distribution.dart';
import 'package:xxread/utils/book_open_transition.dart';
import 'package:xxread/widgets/store_reader_access_gate.dart';

void main() {
  setUp(AppDistribution.debugReset);
  tearDown(AppDistribution.debugReset);

  testWidgets(
    'account initialization and access changes safely mount and remove reader',
    (tester) async {
      AppDistribution.debugOverride(
        channel: AppDistributionChannel.googlePlay,
        readerLicenseRequired: true,
      );
      final account = _GateAccount();
      addTearDown(account.dispose);
      var constructions = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider<MemberAccountController>.value(
          value: account,
          child: _TestApp(
            child: StoreReaderAccessGate(
              pageBuilder: (_) {
                constructions++;
                return const Text('reader-content');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(account.initialized, isTrue);
      expect(constructions, 0);
      expect(tester.takeException(), isNull);
      account.setAccess(true);
      await tester.pumpAndSettle();
      expect(find.text('reader-content'), findsOneWidget);
      expect(constructions, 1);
      account.setAccess(false);
      await tester.pumpAndSettle();
      expect(find.text('reader-content'), findsNothing);
      account.setAccess(true);
      await tester.pumpAndSettle();
      expect(constructions, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('direct builds create reader content without an account', (
    tester,
  ) async {
    var readerBuilds = 0;
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.direct,
      readerLicenseRequired: true,
    );

    await tester.pumpWidget(
      _TestApp(
        child: StoreReaderAccessGate(
          pageBuilder: (_) {
            readerBuilds += 1;
            return const Text('reader-content');
          },
        ),
      ),
    );

    expect(readerBuilds, 1);
    expect(find.text('reader-content'), findsOneWidget);
  });

  testWidgets('licensed store build refuses to create reader without account', (
    tester,
  ) async {
    var readerBuilds = 0;
    var blockedReady = 0;
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );

    await tester.pumpWidget(
      _TestApp(
        child: StoreReaderAccessGate(
          pageBuilder: (_) {
            readerBuilds += 1;
            return const Text('reader-content');
          },
          onBlockedContentReady: () => blockedReady += 1,
        ),
      ),
    );
    await tester.pump();

    expect(readerBuilds, 0);
    expect(blockedReady, 1);
    expect(find.text('reader-content'), findsNothing);
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);
  });

  testWidgets('locked guest opens the app license page without signing in', (
    tester,
  ) async {
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );
    final account = _GateAccount();
    addTearDown(account.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<MemberAccountController>.value(
        value: account,
        child: _TestApp(
          child: StoreReaderAccessGate(
            pageBuilder: (_) => const Text('reader-content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('store-reader-open-unlock')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('store-reader-license-page')),
      findsOneWidget,
    );
    expect(find.text('登录'), findsNothing);
  });

  testWidgets('book route keeps denied reader construction lazy', (
    tester,
  ) async {
    var readerBuilds = 0;
    late BuildContext libraryContext;
    AppDistribution.debugOverride(
      channel: AppDistributionChannel.googlePlay,
      readerLicenseRequired: true,
    );
    await tester.pumpWidget(
      _TestApp(
        child: Builder(
          builder: (context) {
            libraryContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final route = BookOpenTransition.createRoute<void>((_) {
      readerBuilds += 1;
      return const Text('reader-content');
    });
    expect(readerBuilds, 0);

    Navigator.of(libraryContext).push<void>(route);
    await tester.pumpAndSettle();
    expect(readerBuilds, 0);
    expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);

    Navigator.of(libraryContext).pop();
    await tester.pumpAndSettle();
  });
}

class _GateAccount extends MemberAccountController {
  bool _ready = false;
  bool _access = false;
  @override
  bool get initialized => _ready;
  @override
  bool get hasReaderAccess => _access;
  @override
  Future<void> initialize({bool force = false}) async {
    _ready = true;
    notifyListeners();
  }

  void setAccess(bool allowed) {
    _access = allowed;
    notifyListeners();
  }
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
