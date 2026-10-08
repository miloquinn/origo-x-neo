@Tags(['isolated-process'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/book_sources/services/book_download_cancellation.dart';
import 'package:xxread/book_sources/services/source_book_update_service.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/home_navigation_destination.dart';
import 'package:xxread/pages/home/widgets/home_page_wrappers.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/library/library_event_bus_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets(
    'adding to a hidden shelf only reloads data; visible shelf resumes checks',
    (tester) async {
      final activeTab = ValueNotifier(HomeNavigationDestination.discover);
      addTearDown(activeTab.dispose);
      final service = _TrackingUpdateService();
      var loads = 0;
      await tester.pumpWidget(
        _app(
          activeTab: activeTab,
          service: service,
          booksLoader: () async {
            loads++;
            return [_book];
          },
        ),
      );
      await _flushIdle(tester);
      expect(loads, 1);
      expect(service.tokens, isEmpty);

      LibraryEventBus().notifyLibraryChanged();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      await _flushIdle(tester);
      expect(loads, 2);
      expect(service.tokens, isEmpty);

      activeTab.value = HomeNavigationDestination.library;
      await tester.pump();
      await _flushIdle(tester);
      expect(service.tokens, hasLength(1));
      expect(service.tokens.single.isCancelled, isFalse);

      activeTab.value = HomeNavigationDestination.discover;
      await tester.pump();
      expect(service.tokens.single.isCancelled, isTrue);
      await _flushIdle(tester);
      activeTab.value = HomeNavigationDestination.library;
      await tester.pump();
      await _flushIdle(tester);
      expect(service.tokens, hasLength(2));
      expect(service.tokens.last.isCancelled, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await _flushIdle(tester);
      expect(service.tokens.last.isCancelled, isTrue);
    },
  );

  testWidgets(
    'a covering route cancels checks and resumes after its return animation',
    (tester) async {
      final activeTab = ValueNotifier(HomeNavigationDestination.library);
      addTearDown(activeTab.dispose);
      final service = _TrackingUpdateService();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _app(
          activeTab: activeTab,
          service: service,
          navigator: navigator,
          booksLoader: () async => [_book],
        ),
      );
      await _flushIdle(tester);
      expect(service.tokens, hasLength(1));

      unawaited(
        navigator.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('book detail')),
          ),
        ),
      );
      await tester.pump();
      expect(service.tokens.single.isCancelled, isTrue);
      await tester.pumpAndSettle();
      await _flushIdle(tester);
      expect(service.tokens, hasLength(1));

      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await _flushIdle(tester);
      expect(service.tokens, hasLength(1));
      await tester.pumpAndSettle();
      await _flushIdle(tester);
      expect(service.tokens, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      await _flushIdle(tester);
    },
  );

  testWidgets('backgrounding cancels the pass without checking hidden books', (
    tester,
  ) async {
    final activeTab = ValueNotifier(HomeNavigationDestination.library);
    addTearDown(activeTab.dispose);
    final service = _TrackingUpdateService();
    await tester.pumpWidget(
      _app(
        activeTab: activeTab,
        service: service,
        booksLoader: () async => [_book],
      ),
    );
    await _flushIdle(tester);
    expect(service.tokens, hasLength(1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(service.tokens.single.isCancelled, isTrue);
    await _flushIdle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _flushIdle(tester);
    expect(service.tokens, hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await _flushIdle(tester);
  });
}

Future<void> _flushIdle(WidgetTester tester) async {
  await tester.pump();
  // scheduleTask uses an event-loop timer, which is held by the widget test's
  // fake clock. Drive that queue while keeping the production priority check:
  // an active route animation still prevents the idle task from running.
  tester.binding.handleEventLoopCallback();
  await tester.runAsync(() => Future<void>(() {}));
  // A null-duration pump flushes microtasks only; zero explicitly drains the
  // scheduler's pending Timer.run without advancing any route animation.
  await tester.pump(Duration.zero);
}

Widget _app({
  required ValueNotifier<HomeNavigationDestination> activeTab,
  required SourceBookUpdateService service,
  required Future<List<Book>> Function() booksLoader,
  GlobalKey<NavigatorState>? navigator,
}) => ChangeNotifierProvider(
  create: (_) => AppSettingsNotifier(),
  child: MaterialApp(
    navigatorKey: navigator,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ValueListenableBuilder<HomeNavigationDestination>(
      valueListenable: activeTab,
      child: LibraryPage(
        booksLoader: booksLoader,
        foldersLoader: () async => const [],
        sourceUpdateService: service,
      ),
      builder: (_, destination, child) =>
          HomeTabFocusScope(activeDestination: destination, child: child!),
    ),
  ),
);

final _book = Book(
  id: 1,
  title: 'Online book',
  filePath: '/tmp/online.source',
  format: 'source',
  storageType: 'online',
  sourceId: 'source',
  sourceBookId: 'book',
  sourceJson: '{}',
  sourceBookJson: '{"id":"book"}',
);

class _TrackingUpdateService extends SourceBookUpdateService {
  final tokens = <BookDownloadCancellation>[];

  @override
  Future<Book> check(
    Book book, {
    bool force = true,
    BookDownloadCancellation? cancellation,
  }) async {
    expect(force, isFalse);
    final token = cancellation!;
    tokens.add(token);
    await token.whenCancelled;
    throw const BookDownloadCancelledException();
  }
}
