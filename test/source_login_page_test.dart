import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/book_sources/models/registered_book_source.dart';
import 'package:xxread/book_sources/services/book_source_client.dart';
import 'package:xxread/book_sources/source_engine/source_browser_session.dart';
import 'package:xxread/book_sources/source_engine/source_login_ui.dart';
import 'package:xxread/book_sources/source_engine/source_transport.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/book_sources/source_login_page.dart';

void main() {
  testWidgets('source response is shown in full without a success claim', (
    tester,
  ) async {
    final client = _LoginClient(
      message: 'Credentials rejected by source',
      fields: const [SourceLoginField(name: 'email', type: 'text')],
      reloadedFields: const [
        SourceLoginField(
          name: 'email',
          type: 'text',
          defaultValue: 'returned@example.test',
        ),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);
    await tester.tap(find.text('Sign in and save session'));
    await tester.pumpAndSettle();
    expect(find.text('Credentials rejected by source'), findsOneWidget);
    expect(find.text('Source sign-in session updated'), findsNothing);
    expect(client.loadCount, 2);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('source-login-field-email')),
          )
          .controller!
          .text,
      'returned@example.test',
    );
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Sign in and save session'),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('web login shows resolved website and saves browser session', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _LoginClient();
    await _pumpPage(tester, source: _webSource, client: client);

    expect(find.text('Sign in on the original website'), findsOneWidget);
    expect(
      find.text('https://reader.example.test/account/login'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Cookies and website local storage'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('source-login-clear')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('source-login-browser-open')));
    await tester.pumpAndSettle();

    expect(client.loginCount, 1);
    expect(client.lastValues, isEmpty);
    expect(find.text('Source sign-in session updated'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('unsupported platforms explain and disable website login', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final client = _LoginClient();
    await _pumpPage(tester, source: _webSource, client: client);

    expect(
      find.text(
        'Website sign-in is available on Android, iPhone, iPad, and Mac.',
      ),
      findsOneWidget,
    );
    final browserButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('source-login-browser-open')),
    );
    expect(browserButton.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('source-login-clear')));
    await tester.pumpAndSettle();
    expect(client.clearCount, 1);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('form login remains available and submits entered values', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _LoginClient(
      fields: const [
        SourceLoginField(name: 'account', type: 'text', viewName: 'Account'),
        SourceLoginField(
          name: 'password',
          type: 'password',
          viewName: 'Password',
        ),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);

    expect(
      find.byKey(const ValueKey('source-login-browser-open')),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const ValueKey('source-login-field-account')),
      'reader',
    );
    await tester.enterText(
      find.byKey(const ValueKey('source-login-field-password')),
      'secret',
    );
    await tester.tap(find.text('Sign in and save session'));
    await tester.pumpAndSettle();

    expect(client.lastValues, {'account': 'reader', 'password': 'secret'});
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('closing website login leaves the page without an error', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _LoginClient(cancelLogin: true);
    await _pumpPage(tester, source: _webSource, client: client);

    await tester.tap(find.byKey(const ValueKey('source-login-browser-open')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not update'), findsNothing);
    final browserButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('source-login-browser-open')),
    );
    expect(browserButton.onPressed, isNotNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'connection failure explains that the saved sign-in session is retained',
    (tester) async {
      final client = _LoginClient(
        fields: const [SourceLoginField(name: 'email', type: 'text')],
        loginError: SourceConnectionException(
          host: 'reader.example.test',
          reason: SourceConnectionFailureReason.unreachable,
          browserFallbackAttempted: true,
        ),
      );
      await _pumpPage(
        tester,
        source: _formSource,
        client: client,
        locale: const Locale('zh'),
      );

      await tester.tap(find.text('登录并保存会话'));
      await tester.pumpAndSettle();

      expect(find.text('无法连接书源服务器，请稍后重试。已有登录信息仍保留在本机，未被清除。'), findsOneWidget);
      expect(find.textContaining('Could not connect'), findsNothing);
      expect(client.clearCount, 0);
    },
  );

  testWidgets('form buttons execute their configured source action', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final client = _LoginClient(
      fields: const [
        SourceLoginField(name: 'email', type: 'text', viewName: 'Email'),
        SourceLoginField(
          name: 'Register',
          type: 'button',
          action: 'register()',
        ),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);

    await tester.enterText(
      find.byKey(const ValueKey('source-login-field-email')),
      'a@b.com',
    );
    await tester.tap(
      find.byKey(const ValueKey('source-login-action-Register')),
    );
    await tester.pumpAndSettle();

    expect(client.lastValues, {'email': 'a@b.com'});
    expect(client.lastAction, 'register()');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'declared login form keeps headings fields and actions in order',
    (tester) async {
      final client = _LoginClient(
        fields: const [
          SourceLoginField(name: 'Account section', type: 'button'),
          SourceLoginField(name: 'account', type: 'text', viewName: 'Account'),
          SourceLoginField(
            name: 'Get token',
            type: 'button',
            action: 'getToken()',
            flexBasisPercent: 0.5,
          ),
          SourceLoginField(
            name: 'Query token',
            type: 'button',
            action: 'queryToken()',
            flexBasisPercent: 0.5,
          ),
          SourceLoginField(name: 'token', type: 'text', viewName: 'Token'),
          SourceLoginField(
            name: 'Check token',
            type: 'button',
            action: 'checkToken()',
            flexBasisPercent: 0.5,
          ),
        ],
      );
      await _pumpPage(tester, source: _formSource, client: client);

      final heading = find.byKey(
        const ValueKey('source-login-heading-Account section'),
      );
      final account = find.byKey(const ValueKey('source-login-field-account'));
      final getToken = find.byKey(
        const ValueKey('source-login-action-Get token'),
      );
      final queryToken = find.byKey(
        const ValueKey('source-login-action-Query token'),
      );
      final token = find.byKey(const ValueKey('source-login-field-token'));
      final checkToken = find.byKey(
        const ValueKey('source-login-action-Check token'),
      );
      expect(heading, findsOneWidget);
      expect(
        find.byKey(const ValueKey('source-login-action-Account section')),
        findsNothing,
      );
      expect(
        tester.getTopLeft(account).dy,
        greaterThan(tester.getTopLeft(heading).dy),
      );
      expect(
        tester.getTopLeft(getToken).dy,
        greaterThan(tester.getTopLeft(account).dy),
      );
      expect(tester.getTopLeft(queryToken).dy, tester.getTopLeft(getToken).dy);
      expect(
        tester.getTopLeft(token).dy,
        greaterThan(tester.getTopLeft(getToken).dy),
      );
      expect(
        tester.getTopLeft(checkToken).dy,
        greaterThan(tester.getTopLeft(token).dy),
      );
    },
  );

  testWidgets('action refreshes saved fields without losing unchanged edits', (
    tester,
  ) async {
    final initialFields = const [
      SourceLoginField(name: 'account', type: 'text', defaultValue: 'saved'),
      SourceLoginField(
        name: 'Get token',
        type: 'button',
        action: 'getToken()',
        flexBasisPercent: 0.5,
      ),
      SourceLoginField(name: 'token', type: 'text', defaultValue: 'old-token'),
      SourceLoginField(
        name: 'Check token',
        type: 'button',
        action: 'checkToken()',
        flexBasisPercent: 0.5,
      ),
    ];
    final refreshedFields = const [
      SourceLoginField(name: 'account', type: 'text', defaultValue: 'saved'),
      SourceLoginField(
        name: 'Get token',
        type: 'button',
        action: 'getToken()',
        flexBasisPercent: 0.5,
      ),
      SourceLoginField(name: 'token', type: 'text', defaultValue: 'new-token'),
      SourceLoginField(
        name: 'Check token',
        type: 'button',
        action: 'checkToken()',
        flexBasisPercent: 0.5,
      ),
    ];
    final client = _LoginClient(
      fields: initialFields,
      reloadedFields: refreshedFields,
    );
    await _pumpPage(tester, source: _formSource, client: client);
    await tester.enterText(
      find.byKey(const ValueKey('source-login-field-account')),
      'draft-account',
    );
    await tester.tap(
      find.byKey(const ValueKey('source-login-action-Get token')),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('source-login-field-token')),
          )
          .controller!
          .text,
      'new-token',
    );
    await tester.tap(
      find.byKey(const ValueKey('source-login-action-Check token')),
    );
    await tester.pumpAndSettle();
    expect(client.lastValues, {
      'account': 'draft-account',
      'token': 'new-token',
    });
    expect(client.lastAction, 'checkToken()');
  });

  testWidgets('clearing reloads saved choices as well as text values', (
    tester,
  ) async {
    final client = _LoginClient(
      fields: const [
        SourceLoginField(
          name: 'server',
          type: 'select',
          chars: ['Primary', 'Backup'],
          defaultValue: 'Backup',
        ),
        SourceLoginField(
          name: 'remember',
          type: 'toggle',
          defaultValue: 'true',
        ),
      ],
      reloadedFields: const [
        SourceLoginField(
          name: 'server',
          type: 'select',
          chars: ['Primary', 'Backup'],
          defaultValue: 'Primary',
        ),
        SourceLoginField(
          name: 'remember',
          type: 'toggle',
          defaultValue: 'false',
        ),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);
    expect(
      tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('source-login-choice-server-Backup')),
      ),
      isNotNull,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('source-login-clear')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('source-login-choice-server-Primary')),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('clearing discards drafts when declared defaults are unchanged', (
    tester,
  ) async {
    final client = _LoginClient(
      fields: const [
        SourceLoginField(name: 'account', type: 'text'),
        SourceLoginField(
          name: 'server',
          type: 'select',
          chars: ['Primary', 'Backup'],
          defaultValue: 'Primary',
        ),
        SourceLoginField(
          name: 'remember',
          type: 'toggle',
          defaultValue: 'false',
        ),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);
    await tester.enterText(
      find.byKey(const ValueKey('source-login-field-account')),
      'unsaved-account',
    );
    await tester.tap(
      find.byKey(const ValueKey('source-login-choice-server-Primary')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('source-login-clear')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('source-login-field-account')),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(
      find.byKey(const ValueKey('source-login-choice-server-Primary')),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(client.clearCount, 1);
  });

  testWidgets('heading-only buttons do not replace the generic save action', (
    tester,
  ) async {
    final client = _LoginClient(
      fields: const [
        SourceLoginField(name: 'Account settings', type: 'button'),
        SourceLoginField(name: 'account', type: 'text'),
      ],
    );
    await _pumpPage(tester, source: _formSource, client: client);

    expect(
      find.byKey(const ValueKey('source-login-heading-Account settings')),
      findsOneWidget,
    );
    expect(find.text('Sign in and save session'), findsOneWidget);
    await tester.tap(find.text('Sign in and save session'));
    await tester.pumpAndSettle();
    expect(client.loginCount, 1);
    expect(client.lastAction, isNull);
  });

  testWidgets('declared form fits a narrow screen with 2x text', (
    tester,
  ) async {
    final client = _LoginClient(
      fields: const [
        SourceLoginField(name: '  Token settings  ', type: 'button'),
        SourceLoginField(
          name: '  Get a temporary account token  ',
          type: 'button',
          action: 'getToken()',
          flexBasisPercent: 0.5,
        ),
        SourceLoginField(
          name: ' token ',
          type: 'text',
          viewName: '  Token value  ',
        ),
      ],
    );
    await _pumpPage(
      tester,
      source: _formSource,
      client: client,
      size: const Size(320, 900),
      textScale: 2,
      devicePixelRatio: 3,
    );
    expect(
      find.byKey(
        const ValueKey('source-login-action-  Get a temporary account token  '),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('source-login-heading-  Token settings  ')),
      findsOneWidget,
    );
    expect(find.text('Token settings'), findsOneWidget);
    expect(find.text('Get a temporary account token'), findsOneWidget);
    expect(find.text('Token value'), findsOneWidget);
    expect(find.text('  Token settings  '), findsNothing);
    expect(find.text('  Get a temporary account token  '), findsNothing);
    final tokenField = find.byKey(const ValueKey('source-login-field- token '));
    await tester.ensureVisible(tokenField);
    await tester.pumpAndSettle();
    final tokenSemantics = find
        .ancestor(of: tokenField, matching: find.byType(Semantics))
        .first;
    expect(
      tester.widget<Semantics>(tokenSemantics).properties.label,
      'Token value',
    );
    await tester.tap(find.text('Get a temporary account token'));
    await tester.pumpAndSettle();
    expect(client.lastValues, {' token ': ''});
    expect(client.lastAction, 'getToken()');
    expect(tester.takeException(), isNull);
  });

  for (final layout in [
    (width: 430.0, scale: 1.0, dpr: 1.0, columns: 2),
    (width: 346.0, scale: 1.0, dpr: 3.5, columns: 2),
    (width: 390.0, scale: 1.5, dpr: 3.0, columns: 2),
    (width: 320.0, scale: 2.0, dpr: 3.0, columns: 2),
    (width: 280.0, scale: 1.0, dpr: 1.0, columns: 1),
  ]) {
    testWidgets(
      'source actions and extra values survive responsive layout ($layout)',
      (tester) async {
        final client = _LoginClient(
          fields: [
            const SourceLoginField(name: 'account', type: 'text'),
            for (var i = 0; i < 8; i++)
              SourceLoginField(
                name: 'Action $i',
                type: 'button',
                action: 'action$i()',
              ),
            const SourceLoginField(
              name: 'extra',
              type: 'text',
              viewName:
                  'An optional setting with a very long label that must wrap',
              defaultValue: 'saved',
            ),
          ],
        );
        await _pumpPage(
          tester,
          source: _formSource,
          client: client,
          size: Size(layout.width, 900),
          textScale: layout.scale,
          devicePixelRatio: layout.dpr,
        );
        final first = find.byKey(
          const ValueKey('source-login-action-Action 0'),
        );
        final second = find.byKey(
          const ValueKey('source-login-action-Action 1'),
        );
        final scrollable = find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(first, 200, scrollable: scrollable);
        if (layout.columns == 1) {
          expect(
            tester.getTopLeft(second).dy,
            greaterThan(tester.getTopLeft(first).dy),
          );
        } else {
          expect(tester.getTopLeft(second).dy, tester.getTopLeft(first).dy);
        }
        expect(
          find.byKey(const ValueKey('source-login-field-extra')),
          findsNothing,
        );
        final settings = find.byKey(
          const ValueKey('source-login-extra-settings'),
        );
        await tester.scrollUntilVisible(settings, 200, scrollable: scrollable);
        await tester.tap(settings);
        await tester.pumpAndSettle();
        final extra = find.byKey(const ValueKey('source-login-field-extra'));
        await tester.ensureVisible(extra);
        await tester.enterText(extra, 'custom');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(first, -200, scrollable: scrollable);
        await Scrollable.ensureVisible(tester.element(first), alignment: 0.4);
        await tester.pumpAndSettle();
        await tester.tap(first);
        await tester.pumpAndSettle();
        expect(client.lastAction, 'action0()');
        expect(client.lastValues, {'account': '', 'extra': 'custom'});
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required RegisteredBookSource source,
  required BookSourceClient client,
  Size size = const Size(430, 900),
  double textScale = 1,
  double devicePixelRatio = 1,
  Locale? locale,
}) async {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = size * devicePixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: SourceLoginPage(source: source, client: client),
    ),
  );
  await tester.pumpAndSettle();
}

class _LoginClient extends BookSourceClient {
  _LoginClient({
    this.fields = const [],
    this.reloadedFields,
    this.cancelLogin = false,
    this.message,
    this.loginError,
  });
  final String? message;

  final List<SourceLoginField> fields;
  final List<SourceLoginField>? reloadedFields;
  final bool cancelLogin;
  final Object? loginError;
  int loginCount = 0;
  int clearCount = 0;
  int loadCount = 0;
  Map<String, String>? lastValues;
  String? lastAction;

  @override
  Future<List<SourceLoginField>> loadLoginFields(
    RegisteredBookSource source,
  ) async {
    loadCount++;
    return loadCount > 1 && reloadedFields != null ? reloadedFields! : fields;
  }

  @override
  Future<String?> loginSource(
    RegisteredBookSource source,
    Map<String, String> values, {
    String? action,
  }) async {
    loginCount++;
    if (cancelLogin) throw const SourceBrowserCancelled();
    if (loginError case final error?) throw error;
    lastValues = Map.of(values);
    lastAction = action;
    return message;
  }

  @override
  Future<void> clearSourceLogin(RegisteredBookSource source) async {
    clearCount++;
  }
}

final _webSource = _source({
  'bookSourceUrl': 'https://reader.example.test/base/',
  'loginUrl': '/account/login',
});

final _formSource = _source({
  'bookSourceUrl': 'https://reader.example.test',
  'loginUrl': 'function login() { return true; }',
});

RegisteredBookSource _source(Map<String, dynamic> config) =>
    RegisteredBookSource(
      id: 'login-source',
      name: 'Login source',
      description: '',
      manifestUrl: Uri.parse('https://reader.example.test/source.json'),
      apiBaseUrl: Uri.parse('https://reader.example.test'),
      protocolVersion: '1',
      languages: const ['en'],
      capabilities: const {},
      enabled: true,
      addedAt: DateTime(2026),
      sourceProtocol: BookSourceProtocolKind.readingSource,
      sourceConfig: config,
    );
