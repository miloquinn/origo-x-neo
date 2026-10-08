@Tags(['isolated-process'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xxread/l10n/app_localizations.dart';
import 'package:xxread/models/book.dart';
import 'package:xxread/models/shelf_folder.dart';
import 'package:xxread/pages/library/library_page.dart';
import 'package:xxread/pages/library/library_shelf_transition.dart';
import 'package:xxread/services/core/app_settings_service.dart';
import 'package:xxread/services/library/library_event_bus_service.dart';
import 'package:xxread/widgets/glass_buttons.dart';

const _parentId = 'motion-parent';
const _childId = 'motion-child';
const _backKey = ValueKey('library-back-to-parent');
const _switcherKey = ValueKey('library-parent-button-switcher');
const _transformKey = ValueKey('library-shelf-content-transform');
const _opacityKey = ValueKey('library-shelf-content-opacity');
const _snapshotKey = ValueKey('library-shelf-snapshot');

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Directory supportDirectory;
  const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'library_shelf_motion_',
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (_) async => supportDirectory.path,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'library_layout_mode_v1': 'grid',
    });
  });

  tearDownAll(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(pathChannel, null);
    await supportDirectory.delete(recursive: true);
  });

  testWidgets('opening expands a shelf and return shrinks the outgoing image', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester);
    expect(_scale(tester), 1);
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    final initialClip = _clipBounds(tester);
    final initialScale = _scale(tester);
    expect(initialScale, lessThan(1));
    expect(_opacity(tester), lessThan(1));
    _expectOneCollection(tester);

    await tester.pump(const Duration(milliseconds: 100));
    final middleClip = _clipBounds(tester);
    expect(middleClip.width, greaterThan(initialClip.width));
    expect(_scale(tester), greaterThan(initialScale));
    expect(_scale(tester), lessThan(1));
    expect(_opacity(tester), inExclusiveRange(0, 1));
    _expectOneCollection(tester);

    await _finish(tester, fixture);
    expect(fixture.controller.folderName.value, 'Parent Shelf');
    expect(_scale(tester), 1);
    expect(_opacity(tester), 1);
    expect(_clipBounds(tester).width, greaterThan(middleClip.width));
    expect(find.byKey(_snapshotKey), findsNothing);

    fixture.controller.goUp();
    await _pumpReturnStart(tester);
    expect(fixture.transition(tester).isAnimating, isTrue);
    expect(fixture.controller.folderName.value, isNull);
    expect(find.byKey(_snapshotKey), findsOneWidget);
    final outgoingStart = _snapshotRect(tester);
    final returnScale = _scale(tester);
    await tester.pump(const Duration(milliseconds: 80));
    final outgoingMiddle = _snapshotRect(tester);
    expect(outgoingMiddle.width, lessThan(outgoingStart.width));
    expect(outgoingMiddle.height, lessThan(outgoingStart.height));
    expect(_scale(tester), lessThan(returnScale));
    expect(_scale(tester), greaterThan(1));
    _expectOneCollection(tester);

    await _finish(tester, fixture);
    expect(fixture.controller.folderName.value, isNull);
    expect(_scale(tester), 1);
    expect(find.byKey(_snapshotKey), findsNothing);
    expect(find.byKey(_backKey), findsNothing);
    expect(
      find.byKey(const ValueKey('library-folder-$_parentId')),
      findsOneWidget,
    );
  });

  testWidgets('parent button animates in, responds to press, and exits inert', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester);
    expect(find.byKey(_switcherKey), findsOneWidget);
    expect(find.byKey(_backKey), findsNothing);
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.widget(find.byKey(_backKey)), isA<GlassTextButton>());
    expect(_buttonFade(tester), inExclusiveRange(0, 1));
    await _finish(tester, fixture);
    expect(_buttonFade(tester), 1);

    final paintFinder = find.descendant(
      of: find.byKey(_backKey),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_PressPaint',
      ),
    );
    final dynamic paint = tester.renderObject(paintFinder);
    expect(paint.lift, 0);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_backKey)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(paint.lift, greaterThan(0));
    expect(fixture.controller.folderName.value, 'Parent Shelf');
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(paint.lift, 0);
    expect(fixture.controller.folderName.value, 'Parent Shelf');

    await tester.tap(find.byKey(_backKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(fixture.controller.folderName.value, isNull);
    expect(find.byKey(_backKey), findsOneWidget);
    expect(_buttonFade(tester), inExclusiveRange(0, 1));
    expect(find.byKey(_backKey).hitTestable(), findsNothing);
    expect(
      tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.byKey(_backKey),
              matching: find.byType(IgnorePointer),
            ),
          )
          .any((widget) => widget.ignoring),
      isTrue,
    );
    expect(
      tester
          .widgetList<ExcludeSemantics>(
            find.ancestor(
              of: find.byKey(_backKey),
              matching: find.byType(ExcludeSemantics),
            ),
          )
          .any((widget) => widget.excluding),
      isTrue,
    );

    await _finish(tester, fixture);
    expect(find.byKey(_switcherKey), findsOneWidget);
    expect(find.byKey(_backKey), findsNothing);
  });

  testWidgets('same-frame and in-flight repeated back never skip a level', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester);
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    fixture.controller.goUp();
    fixture.controller.goUp();
    await tester.pump(const Duration(milliseconds: 60));
    expect(fixture.controller.folderName.value, 'Parent Shelf');
    await _finish(tester, fixture);

    await _startEnter(tester, fixture, _childId, 'Child Shelf');
    fixture.controller.goUp();
    await tester.pump(const Duration(milliseconds: 60));
    expect(fixture.controller.folderName.value, 'Child Shelf');
    await _finish(tester, fixture);

    // Both calls occur before didUpdateWidget starts the next ticker.
    fixture.controller.goUp();
    fixture.controller.goUp();
    expect(fixture.controller.folderName.value, 'Parent Shelf');
    await tester.pump();
    expect(fixture.transition(tester).isAnimating, isTrue);
    fixture.controller.goUp();
    await tester.pump(const Duration(milliseconds: 60));
    expect(fixture.controller.folderName.value, 'Parent Shelf');
    await _finish(tester, fixture);

    fixture.controller.goUp();
    await tester.pump();
    await _finish(tester, fixture);
    expect(fixture.controller.folderName.value, isNull);
  });

  testWidgets('directory motion restores scroll with one active position', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester);
    final scroll = _grid(tester).controller!;
    scroll.jumpTo(96);
    await tester.pump();
    final rootOffset = scroll.offset;
    expect(rootOffset, greaterThan(0));

    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    expect(_grid(tester).controller, same(scroll));
    _expectOneCollection(tester);
    expect(scroll.offset, 0);
    await _finish(tester, fixture);
    scroll.jumpTo(96);
    await tester.pump();
    final parentOffset = scroll.offset;

    await _startEnter(tester, fixture, _childId, 'Child Shelf');
    _expectOneCollection(tester);
    expect(_grid(tester).controller, same(scroll));
    expect(scroll.offset, 0);
    await _finish(tester, fixture);
    fixture.controller.goUp();
    await tester.pump();
    _expectOneCollection(tester);
    expect(scroll.offset, closeTo(parentOffset, 0.01));
    await _finish(tester, fixture);

    fixture.controller.goUp();
    await tester.pump();
    _expectOneCollection(tester);
    expect(scroll.offset, closeTo(rootOffset, 0.01));
    await _finish(tester, fixture);
    expect(scroll.positions.length, 1);
  });

  testWidgets('return targets the current parent tile after window resize', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester);
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    await _finish(tester, fixture);
    tester.view.physicalSize = const Size(834, 1194);
    await tester.pumpAndSettle();
    expect(fixture.controller.folderName.value, 'Parent Shelf');

    fixture.controller.goUp();
    await _pumpReturnStart(tester);
    await tester.pump(const Duration(milliseconds: 270));
    expect(fixture.transition(tester).isAnimating, isTrue);
    expect(fixture.controller.folderName.value, isNull);
    final transition = tester.widget<LibraryShelfTransition>(
      find.byType(LibraryShelfTransition),
    );
    final viewport = tester.renderObject<RenderBox>(
      find.byType(LibraryShelfTransition),
    );
    final origin =
        transition.originKey!.currentContext!.findRenderObject()! as RenderBox;
    final target =
        viewport.globalToLocal(origin.localToGlobal(Offset.zero)) & origin.size;
    final snapshot = _snapshotRect(tester);
    final reason = '390px to 834px return: target=$target, snapshot=$snapshot';
    expect(
      (snapshot.center - target.center).distance,
      lessThan(4),
      reason: reason,
    );
    expect(snapshot.width, closeTo(target.width, 4), reason: reason);
    expect(snapshot.height, closeTo(target.height, 4), reason: reason);
    _expectOneCollection(tester);
    await _finish(tester, fixture);
    expect(fixture.controller.folderName.value, isNull);
    expect(find.byKey(_snapshotKey), findsNothing);
  });

  testWidgets('missing parent anchor fades without shrinking the snapshot', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(
      tester,
      rootBookMatchesParentName: true,
    );
    fixture.controller.toggleSearch();
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'parent shelf');
    await tester.pump(const Duration(milliseconds: 150));
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    await _finish(tester, fixture);

    final parent = fixture.folders.first;
    fixture.folders[0] = ShelfFolder(
      id: parent.id,
      name: 'Renamed Shelf',
      parentId: parent.parentId,
      createdAt: parent.createdAt,
    );
    LibraryEventBus().notifyLibraryChanged();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    expect(fixture.controller.folderName.value, 'Renamed Shelf');

    fixture.controller.goUp();
    await _pumpReturnStart(tester);
    final transitionFinder = find.byType(LibraryShelfTransition);
    final transition = tester.widget<LibraryShelfTransition>(transitionFinder);
    expect(transition.originKey, isNotNull);
    expect(transition.originKey!.currentContext, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'parent shelf',
    );
    expect(
      find.byKey(const ValueKey('library-folder-$_parentId')),
      findsNothing,
    );
    final viewport = Offset.zero & tester.getSize(transitionFinder);
    expect(_snapshotRect(tester), viewport);
    expect(_scale(tester), 1);
    _expectOneCollection(tester);

    await tester.pump(const Duration(milliseconds: 100));
    expect(fixture.transition(tester).isAnimating, isTrue);
    expect(_snapshotRect(tester), viewport);
    expect(_scale(tester), 1);
    expect(_opacity(tester), inExclusiveRange(0, 1));
    final snapshotOpacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byKey(_snapshotKey),
        matching: find.byType(Opacity),
      ),
    );
    expect(snapshotOpacity.opacity, inExclusiveRange(0, 1));
    _expectOneCollection(tester);
    await _finish(tester, fixture);
    expect(fixture.controller.folderName.value, isNull);
    expect(find.byKey(_snapshotKey), findsNothing);
  });

  testWidgets('reduced motion fades without shelf or button displacement', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester, reduceMotion: true);
    await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
    await tester.pump(const Duration(milliseconds: 20));
    final matrix = tester
        .widget<Transform>(find.byKey(_transformKey))
        .transform;
    expect(matrix.storage[0], 1);
    expect(matrix.storage[5], 1);
    expect(matrix.storage[12], 0);
    expect(matrix.storage[13], 0);
    expect(_opacity(tester), inExclusiveRange(0, 1));
    expect(_buttonFade(tester), inExclusiveRange(0, 1));
    expect(find.byKey(_snapshotKey), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(_switcherKey),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(_switcherKey),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(fixture.transition(tester).isAnimating, isFalse);
    expect(fixture.controller.folderName.value, 'Parent Shelf');

    final paintFinder = find.descendant(
      of: find.byKey(_backKey),
      matching: find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_PressPaint',
      ),
    );
    final dynamic paint = tester.renderObject(paintFinder);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_backKey)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(paint.lift, 0);
    expect(paint.pull, Offset.zero);
    await gesture.cancel();
    await tester.pumpAndSettle();

    fixture.controller.goUp();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(_scale(tester), 1);
    expect(_opacity(tester), inExclusiveRange(0, 1));
    expect(find.byKey(_snapshotKey), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fixture.transition(tester).isAnimating, isFalse);
    expect(fixture.controller.folderName.value, isNull);
    expect(find.byKey(_backKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation settles immediately while tickers are muted', (
    tester,
  ) async {
    final fixture = await _MotionFixture.mount(tester, tickerEnabled: false);

    await tester.tap(find.byKey(const ValueKey('library-folder-$_parentId')));
    await tester.pump();

    expect(fixture.controller.folderName.value, 'Parent Shelf');
    expect(fixture.transition(tester).isAnimating, isFalse);
    expect(find.text('Parent Book 0').hitTestable(), findsWidgets);

    fixture.tickerEnabled.value = true;
    await tester.pump();
    fixture.controller.goUp();
    await _pumpReturnStart(tester);
    await _finish(tester, fixture);
    expect(
      find.byKey(const ValueKey('library-folder-$_parentId')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets(
    'muting tickers during return preparation finishes and navigation recovers',
    (tester) async {
      final fixture = await _MotionFixture.mount(tester);
      await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
      await _finish(tester, fixture);

      fixture.controller.goUp();
      await tester.pump();
      expect(fixture.transition(tester).isAnimating, isTrue);
      fixture.tickerEnabled.value = false;
      await tester.pump();

      expect(fixture.controller.folderName.value, isNull);
      expect(fixture.transition(tester).isAnimating, isFalse);
      expect(find.byKey(_snapshotKey), findsNothing);
      expect(
        find.byKey(const ValueKey('library-folder-$_parentId')).hitTestable(),
        findsOneWidget,
      );

      fixture.tickerEnabled.value = true;
      await tester.pump();
      await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
      await _finish(tester, fixture);
      fixture.controller.goUp();
      await _pumpReturnStart(tester);
      await _finish(tester, fixture);
    },
  );

  testWidgets(
    'muting tickers during return animation finishes and navigation recovers',
    (tester) async {
      final fixture = await _MotionFixture.mount(tester);
      await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
      await _finish(tester, fixture);

      fixture.controller.goUp();
      await _pumpReturnStart(tester);
      await tester.pump(const Duration(milliseconds: 80));
      expect(fixture.transition(tester).isAnimating, isTrue);
      fixture.tickerEnabled.value = false;
      await tester.pump();

      expect(fixture.controller.folderName.value, isNull);
      expect(fixture.transition(tester).isAnimating, isFalse);
      expect(find.byKey(_snapshotKey), findsNothing);
      expect(
        find.byKey(const ValueKey('library-folder-$_parentId')).hitTestable(),
        findsOneWidget,
      );

      fixture.tickerEnabled.value = true;
      await tester.pump();
      await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
      await _finish(tester, fixture);
      fixture.controller.goUp();
      await _pumpReturnStart(tester);
      await _finish(tester, fixture);
    },
  );

  testWidgets(
    'disposing during shelf motion releases ticker and image safely',
    (tester) async {
      final fixture = await _MotionFixture.mount(tester);
      await _startEnter(tester, fixture, _parentId, 'Parent Shelf');
      await tester.pump(const Duration(milliseconds: 80));
      expect(fixture.transition(tester).isAnimating, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LibraryShelfTransition), findsNothing);
      expect(tester.takeException(), isNull);

      final returningFixture = await _MotionFixture.mount(tester);
      await _startEnter(tester, returningFixture, _parentId, 'Parent Shelf');
      await _finish(tester, returningFixture);
      returningFixture.controller.goUp();
      // Dispose after the first preparation frame, before its layout callback.
      await tester.pump();
      expect(returningFixture.transition(tester).isAnimating, isTrue);
      expect(find.byKey(_snapshotKey), findsOneWidget);
      expect(_scale(tester), 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LibraryShelfTransition), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _startEnter(
  WidgetTester tester,
  _MotionFixture fixture,
  String id,
  String name,
) async {
  await tester.tap(find.byKey(ValueKey('library-folder-$id')));
  await tester.pump();
  expect(fixture.controller.folderName.value, name);
  expect(fixture.transition(tester).isAnimating, isTrue);
}

Future<void> _finish(WidgetTester tester, _MotionFixture fixture) async {
  await tester.pumpAndSettle();
  expect(fixture.transition(tester).isAnimating, isFalse);
  _expectOneCollection(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _pumpReturnStart(WidgetTester tester) async {
  // Restore the parent, lay out its lazy tile, then render the return's t=0.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

GridView _grid(WidgetTester tester) =>
    tester.widget<GridView>(find.byKey(const ValueKey('library-cover-grid')));

void _expectOneCollection(WidgetTester tester) {
  expect(find.byType(GridView), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(GridView),
      matching: find.byType(Scrollable),
    ),
    findsOneWidget,
  );
  expect(_grid(tester).controller!.positions.length, 1);
}

double _scale(WidgetTester tester) =>
    tester.widget<Transform>(find.byKey(_transformKey)).transform.storage[0];

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byKey(_opacityKey)).opacity;

Rect _clipBounds(WidgetTester tester) {
  final clipped = find
      .ancestor(of: find.byKey(_transformKey), matching: find.byType(ClipPath))
      .first;
  return tester
      .widget<ClipPath>(clipped)
      .clipper!
      .getClip(tester.getSize(clipped))
      .getBounds();
}

Rect _snapshotRect(WidgetTester tester) {
  final snapshot = tester.widget<Positioned>(find.byKey(_snapshotKey));
  return Rect.fromLTWH(
    snapshot.left!,
    snapshot.top!,
    snapshot.width!,
    snapshot.height!,
  );
}

double _buttonFade(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_backKey),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

class _MotionFixture {
  _MotionFixture(this.settings, {required bool tickerEnabled})
    : tickerEnabled = ValueNotifier(tickerEnabled);

  final AppSettingsNotifier settings;
  final controller = LibraryPageController();
  final ValueNotifier<bool> tickerEnabled;
  late final List<ShelfFolder> folders;

  LibraryShelfTransitionState transition(WidgetTester tester) => tester
      .state<LibraryShelfTransitionState>(find.byType(LibraryShelfTransition));

  static Future<_MotionFixture> mount(
    WidgetTester tester, {
    bool reduceMotion = false,
    bool rootBookMatchesParentName = false,
    bool tickerEnabled = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    final settings = (await tester.runAsync(() async {
      final settings = AppSettingsNotifier();
      if (!settings.isInitialized) {
        final initialized = Completer<void>();
        void changed() {
          if (settings.isInitialized && !initialized.isCompleted) {
            initialized.complete();
          }
        }

        settings.addListener(changed);
        changed();
        await initialized.future;
        settings.removeListener(changed);
      }
      return settings;
    }))!;
    final fixture = _MotionFixture(settings, tickerEnabled: tickerEnabled);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      fixture.controller.dispose();
      fixture.tickerEnabled.dispose();
      settings.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final books = <Book>[
      for (var index = 0; index < 32; index++)
        Book(
          id: index + 1,
          title: rootBookMatchesParentName && index == 0
              ? 'Parent Shelf Root'
              : 'Root Book $index',
          filePath: '/motion-root-$index.epub',
          format: 'epub',
          readingProgress: 0.25,
        ),
      for (var index = 0; index < 32; index++)
        Book(
          id: index + 101,
          title: 'Parent Book $index',
          filePath: '/motion-parent-$index.epub',
          format: 'epub',
          shelfFolderId: _parentId,
          readingProgress: 0.5,
        ),
      for (var index = 0; index < 4; index++)
        Book(
          id: index + 201,
          title: 'Child Book $index',
          filePath: '/motion-child-$index.epub',
          format: 'epub',
          shelfFolderId: _childId,
          readingProgress: 0.75,
        ),
    ];
    fixture.folders = [
      ShelfFolder(
        id: _parentId,
        name: 'Parent Shelf',
        parentId: null,
        createdAt: DateTime.utc(2026, 10, 8),
      ),
      ShelfFolder(
        id: _childId,
        name: 'Child Shelf',
        parentId: _parentId,
        createdAt: DateTime.utc(2026, 10, 8),
      ),
    ];
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(useMaterial3: true),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: ValueListenableBuilder<bool>(
            valueListenable: fixture.tickerEnabled,
            builder: (context, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
            child: LibraryPage(
              controller: fixture.controller,
              booksLoader: () async => books,
              foldersLoader: () async => fixture.folders,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('library-folder-$_parentId')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    return fixture;
  }
}
