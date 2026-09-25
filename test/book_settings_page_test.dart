import 'package:xxread/widgets/reader_control_chrome.dart';
import 'package:xxread/utils/reader_themes.dart';
import 'package:xxread/book_sources/source_engine/source_config.dart';
import 'package:xxread/book_sources/source_engine/source_login_session.dart';
import 'package:xxread/book_sources/source_engine/source_browser_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/pages/reader/book_settings_page.dart';
import 'package:xxread/models/book.dart';

void main() {
  testWidgets('reader more button opens book settings directly', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderChromeOverlay(
            palette: ReaderThemes.day,
            visible: true,
            title: 'Book',
            statusBottom: 0,
            statusBuilder: (_, _, _) => const SizedBox(),
            onBack: () {},
            onBookmark: null,
            onTableOfContents: null,
            onSettings: () {},
            backTooltip: 'Back',
            bookmarkTooltip: 'Bookmark',
            tableOfContentsTooltip: 'Contents',
            settingsTooltip: 'Settings',
            bookmarked: false,
            onBookSettings: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-more-menu')));
    expect(opened, isTrue);
    expect(find.byType(PopupMenuItem<String>), findsNothing);
  });

  for (final session in [
    const SourceLoginSession(),
    const SourceLoginSession(loginHeaders: {'Authorization': 'test'}),
    const SourceLoginSession(
      browserSession: SourceBrowserSession(active: true),
    ),
  ]) {
    testWidgets('source login reflects saved session ${session.toJson()}', (
      tester,
    ) async {
      final config = ReadingSourceConfig.fromJson({
        'bookSourceName': '测试书源',
        'bookSourceUrl': 'https://example.test',
      });
      final store = _SessionStore(session);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSettingsPage(
            title: '书籍',
            author: '作者',
            format: 'online',
            cover: const SizedBox(),
            source: config.toRegisteredSource(),
            loginSessionStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(store.readId, config.stableId);
      expect(find.text('书源登录'), findsOneWidget);
      expect(
        find.text('已登录'),
        session.loginHeaders.isNotEmpty || session.browserSession.active
            ? findsOneWidget
            : findsNothing,
      );
      final loginInkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('book-settings-login-action')),
          matching: find.byType(InkWell),
        ),
      );
      expect(loginInkWell.onTap, isNotNull);
    });
  }

  Widget app({bool editable = false, bool online = false}) => MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BookSettingsPage(
      title: '测试书籍',
      author: '测试作者',
      format: 'epub',
      cover: const SizedBox(),
      canEditText: editable,
      canChangeSource: online,
      description: '书籍简介',
    ),
  );

  testWidgets(
    'book settings shows identity and disables editing for other formats',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('书籍设置'), findsOneWidget);
      expect(find.text('测试书籍'), findsOneWidget);
      expect(find.text('测试作者'), findsOneWidget);
      expect(find.text('书籍简介'), findsOneWidget);
      final editInkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const Key('book-settings-edit-action')),
          matching: find.byType(InkWell),
        ),
      );
      expect(editInkWell.onTap, isNull);
      expect(find.text('书源登录'), findsNothing);
    },
  );

  testWidgets('local TXT editor action returns to its reader', (tester) async {
    BookSettingsAction? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await Navigator.of(context).push<BookSettingsAction>(
                MaterialPageRoute(
                  builder: (_) => const BookSettingsPage(
                    title: 'TXT',
                    author: '作者',
                    format: 'txt',
                    cover: SizedBox(),
                    canEditText: true,
                  ),
                ),
              );
            },
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑正文'));
    await tester.pumpAndSettle();
    expect(selected, BookSettingsAction.editText);
    expect(find.text('打开'), findsOneWidget);
  });

  testWidgets(
    'downloaded book in online reader keeps one reader-owned source switch',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSettingsPage(
            title: 'Book',
            author: 'Author',
            format: 'online',
            cover: const SizedBox(),
            canChangeSource: true,
            shelfBook: Book(
              id: 7,
              title: 'Book',
              filePath: '/tmp/book.txt',
              format: 'txt',
              sourceId: 's',
              sourceBookId: 'b',
              sourceJson: '{}',
              sourceBookJson: '{}',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('换源'), findsOneWidget);
      expect(
        find.byKey(const Key('book-settings-change-source-action')),
        findsOneWidget,
      );
      expect(find.text('检查更新'), findsOneWidget);
    },
  );

  testWidgets('online books offer source switching', (tester) async {
    await tester.pumpWidget(app(online: true));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
  });

  for (final actionCase in [
    (
      key: const Key('book-settings-change-source-action'),
      action: BookSettingsAction.changeSource,
      online: true,
    ),
    (
      key: const Key('book-settings-reading-action'),
      action: BookSettingsAction.readingSettings,
      online: false,
    ),
  ]) {
    testWidgets('${actionCase.action.name} action returns to reader', (
      tester,
    ) async {
      BookSettingsAction? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await Navigator.of(context).push<BookSettingsAction>(
                  MaterialPageRoute(
                    builder: (_) => BookSettingsPage(
                      title: 'Book',
                      author: 'Author',
                      format: actionCase.online ? 'online' : 'epub',
                      cover: const SizedBox(),
                      canChangeSource: actionCase.online,
                    ),
                  ),
                );
              },
              child: const Text('打开'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(actionCase.key));
      await tester.pumpAndSettle();
      expect(selected, actionCase.action);
    });
  }

  testWidgets('long description starts collapsed and actions stay reachable', (
    tester,
  ) async {
    final description = List.filled(
      18,
      '这是一段较长的书籍简介，用来确认页面不会把书籍功能推到不可控的位置。',
    ).join();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSettingsPage(
          title: '长篇小说',
          author: '作者',
          format: 'epub',
          cover: const ColoredBox(color: Colors.blue),
          description: description,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Text descriptionText = tester.widget(
      find.byKey(const Key('book-settings-description')),
    );
    expect(descriptionText.maxLines, 4);
    expect(descriptionText.overflow, TextOverflow.ellipsis);
    expect(
      find.byKey(const Key('book-settings-reading-action')),
      findsOneWidget,
    );
    expect(find.text('展开'), findsOneWidget);

    await tester.tap(find.byKey(const Key('book-settings-description-toggle')));
    await tester.pumpAndSettle();
    descriptionText = tester.widget(
      find.byKey(const Key('book-settings-description')),
    );
    expect(descriptionText.maxLines, isNull);
    expect(descriptionText.overflow, TextOverflow.visible);
    expect(find.text('收起'), findsOneWidget);
  });

  testWidgets('wide action grid keeps rows and columns aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final config = ReadingSourceConfig.fromJson({
      'bookSourceName': '测试书源',
      'bookSourceUrl': 'https://example.test',
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BookSettingsPage(
          title: '书籍',
          author: '作者',
          format: 'online',
          cover: const SizedBox(),
          canChangeSource: true,
          source: config.toRegisteredSource(),
          loginSessionStore: _SessionStore(const SourceLoginSession()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final edit = tester.getRect(
      find.byKey(const Key('book-settings-edit-action')),
    );
    final change = tester.getRect(
      find.byKey(const Key('book-settings-change-source-action')),
    );
    final login = tester.getRect(
      find.byKey(const Key('book-settings-login-action')),
    );
    final reading = tester.getRect(
      find.byKey(const Key('book-settings-reading-action')),
    );
    expect(edit.top, change.top);
    expect(login.top, reading.top);
    expect(edit.left, login.left);
    expect(change.left, reading.left);
    expect(edit.width, change.width);
    expect(login.width, reading.width);
    expect(edit.height, change.height);
    expect(login.height, reading.height);
  });

  testWidgets(
    'expanded description stays scrollable at 320px with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BookSettingsPage(
            title: '一本标题非常非常长的测试书籍',
            author: '一位名字也比较长的测试作者',
            format: 'epub',
            cover: const ColoredBox(color: Colors.blue),
            description: List.filled(12, '很长的简介内容').join(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final descriptionToggle = find.byKey(
        const Key('book-settings-description-toggle'),
      );
      await tester.ensureVisible(descriptionToggle);
      await tester.pumpAndSettle();
      await tester.tap(descriptionToggle);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('book-settings-description')))
            .maxLines,
        isNull,
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const Key('book-settings-reading-action')),
      );
      await tester.pumpAndSettle();
      final readingRect = tester.getRect(
        find.byKey(const Key('book-settings-reading-action')),
      );
      expect(readingRect.top, greaterThanOrEqualTo(0));
      expect(readingRect.bottom, lessThanOrEqualTo(568));
      expect(tester.takeException(), isNull);
    },
  );
}

class _SessionStore implements SourceLoginSessionStore {
  _SessionStore(this.session);
  final SourceLoginSession session;
  String? readId;
  @override
  Future<SourceLoginSession> read(String sourceId) async {
    readId = sourceId;
    return session;
  }

  @override
  Future<void> write(String sourceId, SourceLoginSession session) async {}
  @override
  Future<void> clear(String sourceId) async {}
}
